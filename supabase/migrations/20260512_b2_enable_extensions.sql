-- B2: 朝散歩リマインドの cron 起動 + EF 呼び出しに必要な拡張
-- 設計書: docs/mvp_specs/B2_morning_reminder.md v0.5 §6.2
-- pg_cron 1.6.4 (毎時起動) / pg_net 0.19.5 (Edge Function http_post)

CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;
