-- B2: 朝散歩リマインド スキーマ拡張
-- 設計書: docs/mvp_specs/B2_morning_reminder.md v0.5 §4.1 / §4.2 / §4.3
-- ALTER notification_preferences (mode + frequency)
-- VIEW v_morning_reminder_targets
-- TABLE notification_templates / b2_scenery_flags / b2_weather_cache

-- ============================================================
-- 1) notification_preferences に mode + frequency 追加
-- ============================================================
ALTER TABLE public.notification_preferences
  ADD COLUMN IF NOT EXISTS morning_reminder_mode text NOT NULL DEFAULT 'auto'
    CHECK (morning_reminder_mode IN ('auto', 'fixed_time')),
  ADD COLUMN IF NOT EXISTS morning_reminder_frequency text NOT NULL DEFAULT 'daily'
    CHECK (morning_reminder_frequency IN ('daily', 'weekdays', 'weekends'));

COMMENT ON COLUMN public.notification_preferences.morning_reminder_mode IS 'B2: auto=日の出30分前 / fixed_time=morning_reminder_time';
COMMENT ON COLUMN public.notification_preferences.morning_reminder_frequency IS 'B2: 配信曜日 daily/weekdays/weekends';

-- ============================================================
-- 2) v_morning_reminder_targets: 配信対象ユーザービュー
-- ============================================================
DROP VIEW IF EXISTS public.v_morning_reminder_targets;
CREATE VIEW public.v_morning_reminder_targets AS
SELECT
  p.id AS user_id,
  pref.morning_reminder_enabled,
  pref.morning_reminder_mode,
  pref.morning_reminder_time,
  pref.morning_reminder_frequency,
  perm.granted AS notification_granted,
  COALESCE(dt.timezone, 'Asia/Tokyo') AS timezone,
  (SELECT MAX(walks.created_at) FROM public.walks WHERE walks.user_id = p.id) AS last_walk_at,
  (SELECT COUNT(*) FROM public.walks
     WHERE walks.user_id = p.id
       AND walks.created_at >= now() - interval '7 days') AS recent_walk_count
FROM public.profiles p
LEFT JOIN public.notification_preferences pref ON pref.user_id = p.id
LEFT JOIN public.notification_permissions perm ON perm.user_id = p.id
LEFT JOIN LATERAL (
  SELECT timezone FROM public.device_tokens
  WHERE user_id = p.id AND revoked_at IS NULL
  ORDER BY last_seen_at DESC LIMIT 1
) dt ON true
WHERE pref.morning_reminder_enabled = true
  AND perm.granted = true;

COMMENT ON VIEW public.v_morning_reminder_targets IS 'B2: cron_morning_reminder EF が毎時参照する配信対象ビュー';

-- View は service_role のみ参照（EF 内部呼び出し）
REVOKE ALL ON public.v_morning_reminder_targets FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.v_morning_reminder_targets TO service_role;

-- ============================================================
-- 3) notification_templates: 文言テンプレート（CMS 差替可）
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notification_templates (
  key text PRIMARY KEY,
  category text NOT NULL,
  season text CHECK (season IN ('spring', 'summer', 'autumn', 'winter', 'any')),
  scenario text CHECK (scenario IN ('sunny','rainy','cold','hot','scenery','weekend','weekday')),
  title text NOT NULL,
  body text NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.notification_templates IS 'B2: 通知文言テンプレート。key は notif.{category}.{season}.{scenario} 形式。is_active=false で論理停止可能';

ALTER TABLE public.notification_templates ENABLE ROW LEVEL SECURITY;

-- 認証ユーザーは活きてる文言の SELECT のみ可（管理画面プレビュー用途）
DROP POLICY IF EXISTS notification_templates_read_active ON public.notification_templates;
CREATE POLICY notification_templates_read_active
  ON public.notification_templates FOR SELECT
  TO authenticated
  USING (is_active = true);

DROP TRIGGER IF EXISTS trg_notification_templates_updated_at ON public.notification_templates;
CREATE TRIGGER trg_notification_templates_updated_at
  BEFORE UPDATE ON public.notification_templates
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================
-- 4) b2_scenery_flags: 月単位の桜・紅葉等フラグ（管理画面 ON/OFF）
-- ============================================================
CREATE TABLE IF NOT EXISTS public.b2_scenery_flags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  season text NOT NULL CHECK (season IN ('spring','summer','autumn','winter')),
  month int NOT NULL CHECK (month BETWEEN 1 AND 12),
  scenery_enabled boolean NOT NULL DEFAULT false,
  note text,
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT b2_scenery_flags_season_month_unique UNIQUE (season, month)
);

COMMENT ON TABLE public.b2_scenery_flags IS 'B2: 月別 scenery フラグ。MVP 初期 seed は 4月(桜)/11月(紅葉)のみ true';

ALTER TABLE public.b2_scenery_flags ENABLE ROW LEVEL SECURITY;

-- 認証ユーザーは SELECT のみ（管理画面読み取り）
DROP POLICY IF EXISTS b2_scenery_flags_read ON public.b2_scenery_flags;
CREATE POLICY b2_scenery_flags_read
  ON public.b2_scenery_flags FOR SELECT
  TO authenticated
  USING (true);

DROP TRIGGER IF EXISTS trg_b2_scenery_flags_updated_at ON public.b2_scenery_flags;
CREATE TRIGGER trg_b2_scenery_flags_updated_at
  BEFORE UPDATE ON public.b2_scenery_flags
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================
-- 5) b2_weather_cache: 当日天気キャッシュ（OpenWeatherMap 結果）
-- ============================================================
CREATE TABLE IF NOT EXISTS public.b2_weather_cache (
  observed_date date PRIMARY KEY,
  max_temp_c numeric NOT NULL,
  min_temp_c numeric NOT NULL,
  precip_probability numeric NOT NULL,
  raw_response jsonb,
  fetched_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.b2_weather_cache IS 'B2: OpenWeatherMap One Call 3.0 の当日結果キャッシュ。EF 内で 1 日 1 回 fetch';

ALTER TABLE public.b2_weather_cache ENABLE ROW LEVEL SECURITY;

-- 認証ユーザーは読み取り不可（service_role のみ）
-- ポリシー定義なし = アクセスなし
