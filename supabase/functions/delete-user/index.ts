// supabase/functions/delete-user/index.ts
//
// 設計書: docs/mvp_specs/F0_account_deletion_design.md v1.0
// 役割: 認証済みユーザーが自身のアカウントを完全削除する。
//        ① NO ACTION テーブル 4 種を明示削除（route_pins / pin_bookmarks / user_badges / route_favorites）
//        ② Storage バケット 4 種から uid 配下を再帰削除（profile-avatars / walk-photos / pin_photos / dog-photos）
//        ③ auth.admin.deleteUser(uid) で CASCADE 連鎖削除
// 認証: verify_jwt: true（ユーザー自身の JWT 必須）
// 入力: なし（uid は JWT から抽出）
// 出力: { ok: true, uid } or { ok: false, error }
// 根拠: App Store Review Guideline 5.1.1(v)

// deno-lint-ignore-file no-explicit-any
import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient, type SupabaseClient } from 'jsr:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? '';

// admin client（CASCADE 削除と Storage 削除に Service Role 必須）
const admin: SupabaseClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});

function jsonResp(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
  });
}

// NO ACTION テーブル一覧（順序: 子 → 親 → 単独）
const NO_ACTION_TABLES = [
  'pin_bookmarks',
  'user_badges',
  'route_favorites',
  'route_pins', // 子（route_pin_likes/comments/bookmarks/photos/spot_reviews）は CASCADE
] as const;

// Storage バケットとプレフィックス規約
// バケット名はアプリの SupabaseBuckets（lib/config/supabase_config.dart）と一致させること。
// アバターは profile-avatars（旧コードの 'user-avatars' は実在せず削除漏れの原因だった）。
const STORAGE_TARGETS: { bucket: string; prefix: (uid: string) => string }[] = [
  { bucket: 'profile-avatars', prefix: (uid) => uid },
  { bucket: 'walk-photos', prefix: (uid) => uid },
  { bucket: 'pin_photos', prefix: (uid) => uid },
  { bucket: 'dog-photos', prefix: (uid) => `dogs/${uid}` },
];

// Storage 再帰削除: list -> ファイルは remove / フォルダ（id=null）は再帰
async function deleteStorageRecursive(
  client: SupabaseClient,
  bucket: string,
  prefix: string,
  errors: { stage: string; error: string }[],
): Promise<number> {
  let deleted = 0;
  try {
    const { data, error } = await client.storage.from(bucket).list(prefix, {
      limit: 1000,
      offset: 0,
    });
    if (error) {
      errors.push({ stage: `storage.list:${bucket}:${prefix}`, error: error.message });
      return 0;
    }
    if (!data || data.length === 0) return 0;

    const filePaths: string[] = [];
    for (const item of data) {
      // Supabase Storage: id !== null ならファイル / null ならフォルダ
      if (item.id !== null) {
        filePaths.push(`${prefix}/${item.name}`);
      } else {
        // 再帰
        deleted += await deleteStorageRecursive(
          client,
          bucket,
          `${prefix}/${item.name}`,
          errors,
        );
      }
    }

    if (filePaths.length > 0) {
      const { error: removeError } = await client.storage
        .from(bucket)
        .remove(filePaths);
      if (removeError) {
        errors.push({
          stage: `storage.remove:${bucket}`,
          error: removeError.message,
        });
      } else {
        deleted += filePaths.length;
      }
    }
  } catch (e) {
    errors.push({
      stage: `storage.recursive:${bucket}:${prefix}`,
      error: e instanceof Error ? e.message : String(e),
    });
  }
  return deleted;
}

Deno.serve(async (req: Request) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    });
  }

  if (req.method !== 'POST') {
    return jsonResp(405, { ok: false, error: 'Method Not Allowed' });
  }

  // 1. JWT から uid 抽出（自分自身の削除のみ許可）
  const authHeader = req.headers.get('Authorization') ?? '';
  if (!authHeader.startsWith('Bearer ')) {
    return jsonResp(401, { ok: false, error: 'Missing Authorization header' });
  }
  const jwt = authHeader.replace('Bearer ', '');

  // anon client で getUser（JWT 検証）
  const anonClient = createClient(SUPABASE_URL, ANON_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: `Bearer ${jwt}` } },
  });
  const { data: userData, error: getUserError } = await anonClient.auth.getUser(jwt);
  if (getUserError || !userData?.user) {
    return jsonResp(401, { ok: false, error: 'Invalid or expired token' });
  }
  const uid = userData.user.id;

  const errors: { stage: string; error: string }[] = [];
  const summary = {
    no_action_deleted: {} as Record<string, number>,
    storage_deleted: {} as Record<string, number>,
    auth_deleted: false,
  };

  // 2. device_tokens を最優先 revoke（通知中削除でクラッシュ回避）
  // device_tokens は profiles CASCADE で消えるが、push 経路を即座に止めるため明示 revoke
  try {
    await admin
      .from('device_tokens')
      .update({ revoked_at: new Date().toISOString() })
      .eq('user_id', uid)
      .is('revoked_at', null);
  } catch (e) {
    errors.push({
      stage: 'device_tokens.revoke',
      error: e instanceof Error ? e.message : String(e),
    });
  }

  // 3. NO ACTION テーブルを明示削除（順序: 子 → 親）
  for (const table of NO_ACTION_TABLES) {
    try {
      const { count, error } = await admin
        .from(table)
        .delete({ count: 'exact' })
        .eq('user_id', uid);
      if (error) {
        errors.push({ stage: `delete:${table}`, error: error.message });
        summary.no_action_deleted[table] = -1;
      } else {
        summary.no_action_deleted[table] = count ?? 0;
      }
    } catch (e) {
      errors.push({
        stage: `delete:${table}`,
        error: e instanceof Error ? e.message : String(e),
      });
      summary.no_action_deleted[table] = -1;
    }
  }

  // 4. Storage 削除（バケット 4 種・prefix 配下を再帰）
  for (const target of STORAGE_TARGETS) {
    const deleted = await deleteStorageRecursive(
      admin,
      target.bucket,
      target.prefix(uid),
      errors,
    );
    summary.storage_deleted[target.bucket] = deleted;
  }

  // 5. auth.users 削除（CASCADE で残り全部消える）
  // この削除が失敗すると「アカウント削除完了」と言えないので 500 返却
  const { error: deleteAuthError } = await admin.auth.admin.deleteUser(uid);
  if (deleteAuthError) {
    errors.push({
      stage: 'auth.admin.deleteUser',
      error: deleteAuthError.message,
    });
    return jsonResp(500, {
      ok: false,
      error: 'Failed to delete auth user',
      uid,
      summary,
      errors,
    });
  }
  summary.auth_deleted = true;

  // 部分失敗（Storage/NO ACTION 削除エラー）は Edge Function ログに残し、後追い監査できるようにする。
  // auth 削除自体は成功しているため UI には成功を返す（A19）。
  if (errors.length > 0) {
    console.error(
      `delete-user partial failure uid=${uid} errors_count=${errors.length}`,
      JSON.stringify(errors),
    );
  }

  // 中間エラーがあっても auth 削除さえ成功すれば成功扱い（部分削除も復元不可能・Apple Review 要件は満たす）
  return jsonResp(200, {
    ok: true,
    uid,
    summary,
    errors_count: errors.length,
    // 中間エラーはレスポンスに含めない（クライアントには成功のみ通知・Sentry/log で追跡）
  });
});
