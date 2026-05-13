-- B1: FCM プッシュ通知基盤 4 テーブル + RLS
-- 設計書: docs/mvp_specs/B1_fcm_push_base.md v0.5 §4.1
-- MVP は iOS only（platform CHECK 制約で 'ios' のみ許可）

-- ============================================================
-- 1) device_tokens: 端末ごとの FCM トークン保持（1 ユーザー複数端末対応）
-- ============================================================
CREATE TABLE IF NOT EXISTS public.device_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  fcm_token text NOT NULL,
  platform text NOT NULL CHECK (platform IN ('ios')),
  app_version text,
  device_model text,
  locale text DEFAULT 'ja',
  timezone text DEFAULT 'Asia/Tokyo',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  revoked_at timestamptz,
  CONSTRAINT device_tokens_user_token_unique UNIQUE (user_id, fcm_token)
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user_active
  ON public.device_tokens(user_id) WHERE revoked_at IS NULL;

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS device_tokens_owner_select ON public.device_tokens;
CREATE POLICY device_tokens_owner_select
  ON public.device_tokens FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS device_tokens_owner_insert ON public.device_tokens;
CREATE POLICY device_tokens_owner_insert
  ON public.device_tokens FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS device_tokens_owner_update ON public.device_tokens;
CREATE POLICY device_tokens_owner_update
  ON public.device_tokens FOR UPDATE
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS device_tokens_owner_delete ON public.device_tokens;
CREATE POLICY device_tokens_owner_delete
  ON public.device_tokens FOR DELETE
  USING ((SELECT auth.uid()) = user_id);

DROP TRIGGER IF EXISTS trg_device_tokens_updated_at ON public.device_tokens;
CREATE TRIGGER trg_device_tokens_updated_at
  BEFORE UPDATE ON public.device_tokens
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================
-- 2) notification_permissions: ユーザー単位の許可状態 + prompt 履歴
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notification_permissions (
  user_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  granted boolean,
  granted_at timestamptz,
  denied_at timestamptz,
  last_prompted_at timestamptz,
  prompt_count int NOT NULL DEFAULT 0,
  os_setting_check_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.notification_permissions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS notification_permissions_owner_select ON public.notification_permissions;
CREATE POLICY notification_permissions_owner_select
  ON public.notification_permissions FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS notification_permissions_owner_insert ON public.notification_permissions;
CREATE POLICY notification_permissions_owner_insert
  ON public.notification_permissions FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS notification_permissions_owner_update ON public.notification_permissions;
CREATE POLICY notification_permissions_owner_update
  ON public.notification_permissions FOR UPDATE
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP TRIGGER IF EXISTS trg_notification_permissions_updated_at ON public.notification_permissions;
CREATE TRIGGER trg_notification_permissions_updated_at
  BEFORE UPDATE ON public.notification_permissions
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================
-- 3) notification_preferences: 種別ごとの ON/OFF + 時刻設定
-- B2 で ALTER 追加（morning_reminder_mode / morning_reminder_frequency）
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notification_preferences (
  user_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  morning_reminder_enabled boolean NOT NULL DEFAULT true,
  morning_reminder_time time NOT NULL DEFAULT '06:00:00',
  community_enabled boolean NOT NULL DEFAULT true,
  official_announcement_enabled boolean NOT NULL DEFAULT true,
  quiet_hours_start time,
  quiet_hours_end time,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS notification_preferences_owner_select ON public.notification_preferences;
CREATE POLICY notification_preferences_owner_select
  ON public.notification_preferences FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS notification_preferences_owner_insert ON public.notification_preferences;
CREATE POLICY notification_preferences_owner_insert
  ON public.notification_preferences FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS notification_preferences_owner_update ON public.notification_preferences;
CREATE POLICY notification_preferences_owner_update
  ON public.notification_preferences FOR UPDATE
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP TRIGGER IF EXISTS trg_notification_preferences_updated_at ON public.notification_preferences;
CREATE TRIGGER trg_notification_preferences_updated_at
  BEFORE UPDATE ON public.notification_preferences
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================
-- 4) notification_log: 送信履歴（到達率分析 + 重複送信防止）
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notification_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  category text NOT NULL,
  title text NOT NULL,
  body text NOT NULL,
  data jsonb,
  fcm_message_id text,
  status text NOT NULL,
  error text,
  sent_at timestamptz,
  opened_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notif_log_user_cat_date
  ON public.notification_log(user_id, category, created_at DESC);

ALTER TABLE public.notification_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS notification_log_owner_select ON public.notification_log;
CREATE POLICY notification_log_owner_select
  ON public.notification_log FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

-- INSERT/UPDATE は service_role からのみ（クライアントは log_notification_opened RPC 経由）

COMMENT ON TABLE public.device_tokens IS 'B1: FCM device tokens (iOS only MVP). Soft-delete via revoked_at.';
COMMENT ON TABLE public.notification_permissions IS 'B1: Per-user OS notification permission state + prompt history.';
COMMENT ON TABLE public.notification_preferences IS 'B1+B2: Per-user notification category preferences. B2 adds morning_reminder_mode/frequency.';
COMMENT ON TABLE public.notification_log IS 'B1: Push delivery log for analytics and dedup.';
