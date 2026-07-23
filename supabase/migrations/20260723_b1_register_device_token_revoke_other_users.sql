-- B1 修正: register_device_token — 同一 FCM トークンの他ユーザー行を失効させてから UPSERT
-- 背景（2026-07-23 Build 48 実装前レビューで確認・major）:
--   UNIQUE (user_id, fcm_token) のため、同じ端末トークンが複数ユーザーで active 共存できる。
--   ログアウト時の revoke_device_token がオフライン等で失敗した端末で別ユーザーがログインすると、
--   send_push は user_id ごとに revoked_at IS NULL の全トークンへ送るため、
--   旧ユーザー宛の個人向けプッシュ（投稿審査結果など）が新ユーザーの端末に着弾し得る。
-- 対応: FCM トークンは端末（アプリインスタンス）一意なので、登録時に
--   「同一トークンを持つ他ユーザーの active 行」を DB 側で失効させ、1トークン=1ユーザーを保証する。

CREATE OR REPLACE FUNCTION public.register_device_token(
  p_fcm_token text,
  p_platform text DEFAULT 'ios',
  p_app_version text DEFAULT NULL,
  p_device_model text DEFAULT NULL,
  p_timezone text DEFAULT 'Asia/Tokyo'
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_id uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'auth.uid() is null; authentication required';
  END IF;

  -- 同一トークンの他ユーザー active 行を失効（端末の持ち主交代に追従）
  UPDATE public.device_tokens
  SET revoked_at = now(), updated_at = now()
  WHERE fcm_token = p_fcm_token AND user_id <> v_uid AND revoked_at IS NULL;

  INSERT INTO public.device_tokens (user_id, fcm_token, platform, app_version, device_model, timezone, last_seen_at, revoked_at)
  VALUES (v_uid, p_fcm_token, p_platform, p_app_version, p_device_model, p_timezone, now(), NULL)
  ON CONFLICT (user_id, fcm_token)
  DO UPDATE SET
    platform = EXCLUDED.platform,
    app_version = EXCLUDED.app_version,
    device_model = EXCLUDED.device_model,
    timezone = EXCLUDED.timezone,
    last_seen_at = now(),
    revoked_at = NULL,
    updated_at = now()
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.register_device_token(text, text, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.register_device_token(text, text, text, text, text) TO authenticated;
