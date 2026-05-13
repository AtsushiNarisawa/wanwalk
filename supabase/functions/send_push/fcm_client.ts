// FCM HTTP v1 client for Deno Edge Runtime.
// Web Crypto API (RSASSA-PKCS1-v1_5) で SA JSON の private_key を読んで JWT を署名し
// Google OAuth2 endpoint で access_token を交換 → /v1/projects/{id}/messages:send へ POST。
// 教訓: google-auth-library は Deno 互換性が不安定なため自前実装に倒す。
//
// 設計書: docs/mvp_specs/B1_fcm_push_base.md v0.5 §5.2 / §5.3

export type ServiceAccountJson = {
  type: string;
  project_id: string;
  private_key_id: string;
  private_key: string;
  client_email: string;
  token_uri: string;
};

export type FcmSendResult =
  | { ok: true; messageId: string }
  | { ok: false; status: number; error: string; errorCode?: string; isInvalidToken: boolean };

const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const TOKEN_URI_FALLBACK = 'https://oauth2.googleapis.com/token';

// In-memory access token cache (per EF invocation lifetime / cold start).
let cachedToken: { token: string; expiresAt: number } | null = null;

function b64urlEncode(input: Uint8Array | string): string {
  const bytes =
    typeof input === 'string' ? new TextEncoder().encode(input) : input;
  let bin = '';
  for (let i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
  return btoa(bin).replace(/=+$/, '').replace(/\+/g, '-').replace(/\//g, '_');
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const stripped = pem
    .replace(/-----BEGIN [^-]+-----/g, '')
    .replace(/-----END [^-]+-----/g, '')
    .replace(/\s+/g, '');
  const bin = atob(stripped);
  const buf = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) buf[i] = bin.charCodeAt(i);
  return buf.buffer;
}

async function signJwt(sa: ServiceAccountJson): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT', kid: sa.private_key_id };
  const payload = {
    iss: sa.client_email,
    scope: SCOPE,
    aud: sa.token_uri || TOKEN_URI_FALLBACK,
    iat: now,
    exp: now + 3600,
  };

  const headerB64 = b64urlEncode(JSON.stringify(header));
  const payloadB64 = b64urlEncode(JSON.stringify(payload));
  const signingInput = `${headerB64}.${payloadB64}`;

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(sa.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(signingInput),
  );
  const sigB64 = b64urlEncode(new Uint8Array(signature));
  return `${signingInput}.${sigB64}`;
}

export async function getAccessToken(sa: ServiceAccountJson): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt - 60 > now) {
    return cachedToken.token;
  }

  const assertion = await signJwt(sa);
  const body = new URLSearchParams({
    grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    assertion,
  });
  const res = await fetch(sa.token_uri || TOKEN_URI_FALLBACK, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: body.toString(),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`OAuth2 token exchange failed: ${res.status} ${text}`);
  }
  const data = (await res.json()) as { access_token: string; expires_in: number };
  cachedToken = {
    token: data.access_token,
    expiresAt: now + (data.expires_in ?? 3600),
  };
  return data.access_token;
}

export type FcmNotificationPayload = {
  title: string;
  body: string;
};

export async function sendMessageToToken(args: {
  accessToken: string;
  projectId: string;
  fcmToken: string;
  notification: FcmNotificationPayload;
  data?: Record<string, string>;
}): Promise<FcmSendResult> {
  const url = `https://fcm.googleapis.com/v1/projects/${args.projectId}/messages:send`;
  const payload = {
    message: {
      token: args.fcmToken,
      notification: args.notification,
      data: args.data,
      apns: {
        headers: {
          'apns-priority': '10',
          // MVP: 24h で諦める（B2 §2.2 機内モード問題）
          'apns-expiration': String(Math.floor(Date.now() / 1000) + 86400),
        },
        payload: {
          aps: {
            sound: 'default',
            'mutable-content': 1,
            alert: { title: args.notification.title, body: args.notification.body },
          },
        },
      },
    },
  };
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${args.accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });
  const text = await res.text();
  if (res.ok) {
    try {
      const parsed = JSON.parse(text) as { name: string };
      // name = "projects/{id}/messages/{messageId}"
      const messageId = parsed.name.split('/').pop() ?? parsed.name;
      return { ok: true, messageId };
    } catch (_) {
      return { ok: true, messageId: text };
    }
  }
  let errorCode: string | undefined;
  try {
    const parsed = JSON.parse(text) as { error?: { details?: Array<{ errorCode?: string }> } };
    errorCode = parsed.error?.details?.find((d) => d.errorCode)?.errorCode;
  } catch (_) {
    // ignore
  }
  const isInvalidToken =
    res.status === 404 ||
    errorCode === 'UNREGISTERED' ||
    errorCode === 'INVALID_ARGUMENT';
  return {
    ok: false,
    status: res.status,
    error: text.slice(0, 500),
    errorCode,
    isInvalidToken,
  };
}

export function parseServiceAccount(rawJson: string): ServiceAccountJson {
  const sa = JSON.parse(rawJson) as ServiceAccountJson;
  if (!sa.project_id || !sa.client_email || !sa.private_key) {
    throw new Error('FCM_SERVICE_ACCOUNT_JSON missing required fields');
  }
  return sa;
}
