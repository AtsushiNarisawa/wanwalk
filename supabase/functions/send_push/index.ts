// supabase/functions/send_push/index.ts
//
// 設計書: docs/mvp_specs/B1_fcm_push_base.md v0.5 §5.2 / §6.2
// 役割: 1 ユーザー or 一括 ユーザー宛に FCM HTTP v1 で push 配信し、notification_log に記録、
//       invalid_registration トークンは revoked_at で論理削除する。
// 認証: verify_jwt: true（service_role JWT 必須・cron_morning_reminder から内部呼び）
// 入力: { user_id? | user_ids?, category, title, body, data?, override_preferences? }

// deno-lint-ignore-file no-explicit-any
import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'jsr:@supabase/supabase-js@2';
import {
  getAccessToken,
  parseServiceAccount,
  sendMessageToToken,
} from './fcm_client.ts';

type Category = 'morning_reminder' | 'community' | 'official';

type Body = {
  user_id?: string;
  user_ids?: string[];
  category: Category;
  title: string;
  body: string;
  data?: Record<string, string>;
  override_preferences?: boolean;
};

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});

const ALLOWED_CATEGORIES: Category[] = ['morning_reminder', 'community', 'official'];

function jsonResp(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

function nowJstHourMin(): { hour: number; minute: number } {
  // Asia/Tokyo（UTC+9・DST なし）固定。new Date() は UTC。
  const utc = new Date();
  const jst = new Date(utc.getTime() + 9 * 60 * 60 * 1000);
  return { hour: jst.getUTCHours(), minute: jst.getUTCMinutes() };
}

function isWithinQuietHours(
  start: string | null,
  end: string | null,
): boolean {
  if (!start || !end) return false;
  const [sh, sm] = start.split(':').map(Number);
  const [eh, em] = end.split(':').map(Number);
  const { hour, minute } = nowJstHourMin();
  const cur = hour * 60 + minute;
  const s = sh * 60 + sm;
  const e = eh * 60 + em;
  if (s === e) return false;
  if (s < e) {
    return cur >= s && cur < e; // 同日内範囲（例 13:00-15:00）
  }
  // 跨日（例 22:00-07:00）
  return cur >= s || cur < e;
}

function categoryEnabledColumn(category: Category): string {
  switch (category) {
    case 'morning_reminder':
      return 'morning_reminder_enabled';
    case 'community':
      return 'community_enabled';
    case 'official':
      return 'official_announcement_enabled';
  }
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return jsonResp(405, { error: 'method_not_allowed' });
  }

  let payload: Body;
  try {
    payload = (await req.json()) as Body;
  } catch (_) {
    return jsonResp(400, { error: 'invalid_json_body' });
  }

  if (!payload.category || !ALLOWED_CATEGORIES.includes(payload.category)) {
    return jsonResp(400, { error: 'invalid_category' });
  }
  if (!payload.title || !payload.body) {
    return jsonResp(400, { error: 'title_and_body_required' });
  }

  const userIds: string[] = [];
  if (payload.user_id) userIds.push(payload.user_id);
  if (payload.user_ids?.length) userIds.push(...payload.user_ids);
  const uniqueUserIds = [...new Set(userIds)];
  if (uniqueUserIds.length === 0) {
    return jsonResp(400, { error: 'user_id_or_user_ids_required' });
  }
  if (uniqueUserIds.length > 500) {
    return jsonResp(400, { error: 'too_many_users_max_500_per_call' });
  }

  // 1. FCM service account 読み込み
  const saRaw = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON');
  if (!saRaw) {
    return jsonResp(500, { error: 'fcm_service_account_unset' });
  }
  let sa;
  try {
    sa = parseServiceAccount(saRaw);
  } catch (e) {
    return jsonResp(500, { error: 'fcm_sa_parse_failed', detail: String(e) });
  }

  let accessToken: string;
  try {
    accessToken = await getAccessToken(sa);
  } catch (e) {
    return jsonResp(500, { error: 'fcm_oauth_failed', detail: String(e) });
  }

  // 2. preferences 取得（category ON + quiet_hours）
  const prefCol = categoryEnabledColumn(payload.category);
  const { data: prefs, error: prefErr } = await supabase
    .from('notification_preferences')
    .select(
      `user_id, ${prefCol}, quiet_hours_start, quiet_hours_end`,
    )
    .in('user_id', uniqueUserIds);
  if (prefErr) {
    return jsonResp(500, { error: 'prefs_query_failed', detail: prefErr.message });
  }

  const prefMap = new Map<string, any>();
  for (const p of prefs ?? []) prefMap.set(p.user_id, p);

  // 3. quiet_hours / preference フィルタリング
  const eligibleUserIds: string[] = [];
  const skipped: Array<{ user_id: string; reason: string }> = [];
  for (const uid of uniqueUserIds) {
    const p = prefMap.get(uid);
    if (!p) {
      // preferences 行未作成 → デフォルト ON 扱い（既定値 true）
      eligibleUserIds.push(uid);
      continue;
    }
    if (!payload.override_preferences && !p[prefCol]) {
      skipped.push({ user_id: uid, reason: 'category_off' });
      continue;
    }
    if (
      !payload.override_preferences &&
      isWithinQuietHours(p.quiet_hours_start, p.quiet_hours_end)
    ) {
      skipped.push({ user_id: uid, reason: 'quiet_hours' });
      continue;
    }
    eligibleUserIds.push(uid);
  }

  if (eligibleUserIds.length === 0) {
    return jsonResp(200, {
      sent: 0,
      failed: 0,
      skipped: skipped.length,
      detail: { skipped },
    });
  }

  // 4. device_tokens 取得
  const { data: tokens, error: tokErr } = await supabase
    .from('device_tokens')
    .select('id, user_id, fcm_token')
    .in('user_id', eligibleUserIds)
    .is('revoked_at', null);
  if (tokErr) {
    return jsonResp(500, { error: 'tokens_query_failed', detail: tokErr.message });
  }
  if (!tokens || tokens.length === 0) {
    return jsonResp(200, {
      sent: 0,
      failed: 0,
      skipped: skipped.length,
      detail: { reason: 'no_active_tokens', skipped },
    });
  }

  // 5. FCM 送信（並列だが小規模配信前提・MVP）
  let sent = 0;
  let failed = 0;
  const invalidTokenIds: string[] = [];
  const logRows: any[] = [];
  // A27: 開封計測のため配信1件ごとに notification_log の行 id を先に採番し、
  // その uuid を FCM data(notification_log_id) に載せて端末へ渡す。端末は通知タップ時に
  // この id で log_notification_opened RPC を叩く（採番しないと端末に id が届かず計測不能）。
  const baseData: Record<string, string> = {
    category: payload.category,
    ...(payload.data ?? {}),
  };

  const results = await Promise.all(
    tokens.map((t) => {
      const logId = crypto.randomUUID();
      const messageData: Record<string, string> = {
        ...baseData,
        notification_log_id: logId,
      };
      return sendMessageToToken({
        accessToken,
        projectId: sa.project_id,
        fcmToken: t.fcm_token,
        notification: { title: payload.title, body: payload.body },
        data: messageData,
      }).then((r) => ({ row: t, result: r, logId, messageData }));
    }),
  );

  for (const { row, result, logId, messageData } of results) {
    if (result.ok) {
      sent++;
      logRows.push({
        id: logId,
        user_id: row.user_id,
        category: payload.category,
        title: payload.title,
        body: payload.body,
        data: messageData,
        fcm_message_id: result.messageId,
        status: 'sent',
        sent_at: new Date().toISOString(),
      });
    } else {
      failed++;
      logRows.push({
        id: logId,
        user_id: row.user_id,
        category: payload.category,
        title: payload.title,
        body: payload.body,
        data: messageData,
        status: 'failed',
        error: `${result.status}:${result.errorCode ?? ''}:${result.error}`.slice(0, 1000),
      });
      if (result.isInvalidToken) invalidTokenIds.push(row.id);
    }
  }

  // 6. notification_log 記録
  if (logRows.length > 0) {
    const { error: logErr } = await supabase
      .from('notification_log')
      .insert(logRows);
    if (logErr) {
      console.error('notification_log_insert_failed', logErr);
    }
  }

  // 7. invalid_registration トークン revoke
  if (invalidTokenIds.length > 0) {
    const { error: revErr } = await supabase
      .from('device_tokens')
      .update({ revoked_at: new Date().toISOString() })
      .in('id', invalidTokenIds);
    if (revErr) {
      console.error('revoke_invalid_tokens_failed', revErr);
    }
  }

  return jsonResp(200, {
    sent,
    failed,
    skipped: skipped.length,
    revoked: invalidTokenIds.length,
  });
});
