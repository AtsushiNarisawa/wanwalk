// supabase/functions/notify_submission_status/index.ts
//
// 役割: 投稿プログラム v1。投稿(route_submissions)のステータス変更を投稿者へプッシュ通知する。
//       admin(narisawa@dog-hub.shop)のみ実行可。定型文はサーバ側で保持し(A-4トーン)、
//       既存の send_push Edge Function を service role で内部呼び出しして配信する。
// 認証: verify_jwt: true。加えて呼出元 JWT のメールで admin ゲート(delete-user と同じ getUser 方式)。
//       send_push を browser から任意本文で叩ける露出を広げないため、本 EF が定型文を独占する。
// 入力: { submission_id: string, override_preferences?: boolean }
//       - status は submission から読む(クライアントに status を委ねない)。
//       - published は本人への直接通知のため override 既定 true(quiet_hours も跨ぐ)。他は既定 false。
// 出力: { status, push } / エラー時 4xx,5xx
//
// アプリ側 deep link 規約: data.deep_link を lib/utils/notification_deep_link.dart が解釈する。
//       'submission_status' + submission_id をステータス画面への遷移に使う。

// deno-lint-ignore-file no-explicit-any
import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'jsr:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
const ADMIN_EMAIL = 'narisawa@dog-hub.shop';

const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS },
  });
}

type Tmpl = { title: string; body: string };

// 投稿者に見せる定型文(A-4トーン・「！」/絵文字なし・「愛犬」)。詳細な理由等は画面の editor_notes 側で伝える。
function templateFor(status: string): Tmpl | null {
  switch (status) {
    case 'question':
      return {
        title: 'WanWalkからのおうかがい',
        body: '投稿いただいた道について、確認したいことがあります。アプリでご確認ください。',
      };
    case 'approved':
      return {
        title: '掲載の準備を進めています',
        body: 'いただいた道の掲載準備を進めています。もう少しお待ちください。',
      };
    case 'published':
      return {
        title: 'あなたの道が掲載されました',
        body: '推薦いただいた道が、WanWalkに掲載されました。ご協力ありがとうございます。',
      };
    case 'declined':
      return {
        title: '投稿へのお返事をお送りしました',
        body: 'いただいた道について、編集部からお伝えしたいことがあります。アプリでご確認ください。',
      };
    default:
      // received / reviewing / withdrawn は通知しない(内部遷移・本人操作)。
      return null;
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: CORS });
  }
  if (req.method !== 'POST') {
    return json(405, { error: 'method_not_allowed' });
  }

  // 1. admin ゲート(呼出元 JWT のメール)
  const authHeader = req.headers.get('Authorization') ?? '';
  if (!authHeader.startsWith('Bearer ')) {
    return json(401, { error: 'missing_authorization' });
  }
  const jwt = authHeader.replace('Bearer ', '');
  const caller = createClient(SUPABASE_URL, ANON_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: `Bearer ${jwt}` } },
  });
  const { data: userData, error: userErr } = await caller.auth.getUser(jwt);
  if (userErr || !userData?.user) {
    return json(401, { error: 'invalid_token' });
  }
  if ((userData.user.email ?? '').toLowerCase() !== ADMIN_EMAIL) {
    return json(403, { error: 'admin_only' });
  }

  // 2. 入力
  let payload: { submission_id?: string; override_preferences?: boolean };
  try {
    payload = await req.json();
  } catch (_) {
    return json(400, { error: 'invalid_json' });
  }
  const submissionId = payload.submission_id;
  if (!submissionId || typeof submissionId !== 'string') {
    return json(400, { error: 'submission_id_required' });
  }

  // 3. submission を service role で読む(status はサーバ側の真実)
  const { data: sub, error: subErr } = await admin
    .from('route_submissions')
    .select('id, user_id, status, type')
    .eq('id', submissionId)
    .maybeSingle();
  if (subErr) {
    return json(500, { error: 'submission_query_failed', detail: subErr.message });
  }
  if (!sub) {
    return json(404, { error: 'submission_not_found' });
  }
  if (!sub.user_id) {
    return json(200, { status: sub.status, sent: 0, skipped: 'no_user' });
  }

  const tmpl = templateFor(sub.status);
  if (!tmpl) {
    return json(200, { status: sub.status, sent: 0, skipped: `no_notification_for_status:${sub.status}` });
  }

  // published は本人への直接通知 → 既定で preference/quiet_hours を跨ぐ。他 status は既定尊重。
  const doOverride =
    typeof payload.override_preferences === 'boolean'
      ? payload.override_preferences
      : sub.status === 'published';

  // 4. 既存 send_push を service role で内部呼び出し(preference/quiet_hours/ログは send_push 側が担う)
  const resp = await fetch(`${SUPABASE_URL}/functions/v1/send_push`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
    },
    body: JSON.stringify({
      user_id: sub.user_id,
      category: 'community',
      title: tmpl.title,
      body: tmpl.body,
      data: {
        deep_link: 'submission_status',
        submission_id: sub.id,
        status: sub.status,
      },
      override_preferences: doOverride,
    }),
  });
  const result = await resp.json().catch(() => ({}));
  return json(resp.ok ? 200 : 502, { status: sub.status, push: result });
});
