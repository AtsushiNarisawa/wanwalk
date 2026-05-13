-- B1: FCM プッシュ通知基盤 RPC 5 本
-- 設計書: docs/mvp_specs/B1_fcm_push_base.md v0.5 §5.1
-- すべて SECURITY DEFINER + 内部で auth.uid() 取得（クライアントは user_id を渡さない）

-- ============================================================
-- 1) register_device_token: ログイン端末の FCM トークン UPSERT
-- ============================================================
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

-- ============================================================
-- 2) revoke_device_token: ログアウト時のトークン論理削除
-- ============================================================
CREATE OR REPLACE FUNCTION public.revoke_device_token(
  p_fcm_token text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'auth.uid() is null; authentication required';
  END IF;

  UPDATE public.device_tokens
  SET revoked_at = now(), updated_at = now()
  WHERE user_id = v_uid AND fcm_token = p_fcm_token AND revoked_at IS NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.revoke_device_token(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.revoke_device_token(text) TO authenticated;

-- ============================================================
-- 3) update_notification_permission: OS 許可ダイアログ結果の保存
-- granted=true  → granted_at セット
-- granted=false → denied_at セット、prompt_count++
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_notification_permission(
  p_granted boolean
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'auth.uid() is null; authentication required';
  END IF;

  INSERT INTO public.notification_permissions (
    user_id, granted, granted_at, denied_at, last_prompted_at, prompt_count
  )
  VALUES (
    v_uid,
    p_granted,
    CASE WHEN p_granted THEN now() ELSE NULL END,
    CASE WHEN p_granted THEN NULL ELSE now() END,
    now(),
    1
  )
  ON CONFLICT (user_id) DO UPDATE SET
    granted = EXCLUDED.granted,
    granted_at = CASE WHEN p_granted THEN now() ELSE public.notification_permissions.granted_at END,
    denied_at = CASE WHEN p_granted THEN public.notification_permissions.denied_at ELSE now() END,
    last_prompted_at = now(),
    prompt_count = public.notification_permissions.prompt_count + 1,
    updated_at = now();
END;
$$;

REVOKE ALL ON FUNCTION public.update_notification_permission(boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_notification_permission(boolean) TO authenticated;

-- ============================================================
-- 4) update_notification_preferences: 種別ごとの ON/OFF + 時刻設定
-- 引数 NULL は「変更しない」扱い（部分更新）
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_notification_preferences(
  p_morning_reminder_enabled boolean DEFAULT NULL,
  p_morning_reminder_time time DEFAULT NULL,
  p_community_enabled boolean DEFAULT NULL,
  p_official_announcement_enabled boolean DEFAULT NULL,
  p_quiet_hours_start time DEFAULT NULL,
  p_quiet_hours_end time DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'auth.uid() is null; authentication required';
  END IF;

  INSERT INTO public.notification_preferences (
    user_id,
    morning_reminder_enabled,
    morning_reminder_time,
    community_enabled,
    official_announcement_enabled,
    quiet_hours_start,
    quiet_hours_end
  )
  VALUES (
    v_uid,
    COALESCE(p_morning_reminder_enabled, true),
    COALESCE(p_morning_reminder_time, '06:00:00'::time),
    COALESCE(p_community_enabled, true),
    COALESCE(p_official_announcement_enabled, true),
    p_quiet_hours_start,
    p_quiet_hours_end
  )
  ON CONFLICT (user_id) DO UPDATE SET
    morning_reminder_enabled = COALESCE(p_morning_reminder_enabled, public.notification_preferences.morning_reminder_enabled),
    morning_reminder_time = COALESCE(p_morning_reminder_time, public.notification_preferences.morning_reminder_time),
    community_enabled = COALESCE(p_community_enabled, public.notification_preferences.community_enabled),
    official_announcement_enabled = COALESCE(p_official_announcement_enabled, public.notification_preferences.official_announcement_enabled),
    quiet_hours_start = COALESCE(p_quiet_hours_start, public.notification_preferences.quiet_hours_start),
    quiet_hours_end = COALESCE(p_quiet_hours_end, public.notification_preferences.quiet_hours_end),
    updated_at = now();
END;
$$;

REVOKE ALL ON FUNCTION public.update_notification_preferences(boolean, time, boolean, boolean, time, time) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_notification_preferences(boolean, time, boolean, boolean, time, time) TO authenticated;

-- ============================================================
-- 5) log_notification_opened: 通知タップ時の opened 記録
-- ============================================================
CREATE OR REPLACE FUNCTION public.log_notification_opened(
  p_notification_log_id uuid
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'auth.uid() is null; authentication required';
  END IF;

  UPDATE public.notification_log
  SET status = 'opened', opened_at = now()
  WHERE id = p_notification_log_id AND user_id = v_uid;
END;
$$;

REVOKE ALL ON FUNCTION public.log_notification_opened(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.log_notification_opened(uuid) TO authenticated;
