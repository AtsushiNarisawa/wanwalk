-- =====================================================
-- WanMap リニューアル Phase 1a: 既存テーブルのリネーム
-- =====================================================
-- 実行日: 2024-11-22
-- 目的: 既存の個人散歩記録テーブルを保持しつつ、新システムに対応

-- Step 1: 既存テーブルのリネーム
ALTER TABLE routes RENAME TO daily_walks;
ALTER TABLE route_points RENAME TO daily_walk_points;

-- Step 2: daily_walks のカラム調整
ALTER TABLE daily_walks 
  RENAME COLUMN start_time TO walked_at;

-- Step 3: is_public カラムを削除（日常記録は常に非公開）
ALTER TABLE daily_walks 
  DROP COLUMN IF EXISTS is_public;

-- Step 4: インデックスの再作成
DROP INDEX IF EXISTS idx_routes_user_id;
DROP INDEX IF EXISTS idx_routes_created_at;
DROP INDEX IF EXISTS idx_route_points_route_id;

CREATE INDEX idx_daily_walks_user_id ON daily_walks (user_id);
CREATE INDEX idx_daily_walks_walked_at ON daily_walks (walked_at DESC);
CREATE INDEX idx_daily_walk_points_walk_id ON daily_walk_points (route_id);

-- Step 5: 外部キー制約の確認（route_id は walk_id に論理的に変更されるが、カラム名は維持）
-- daily_walk_points.route_id は daily_walks.id を参照

COMMENT ON TABLE daily_walks IS '個人の日常散歩記録（いつもの散歩モード）';
COMMENT ON TABLE daily_walk_points IS '日常散歩のGPSポイント記録';
