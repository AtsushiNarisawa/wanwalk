-- =====================================================
-- WanMap Phase 5: オールインワン統合SQL (修正版)
-- =====================================================
-- 
-- このSQLファイルは以下を全て実行します:
-- 1. Phase 5マイグレーション（検索・ソーシャル）
-- 2. Phase 5マイグレーション（バッジシステム）
-- 3. テストデータ投入（自動）
--
-- 実行方法:
-- 1. Supabase Dashboard → SQL Editor を開く
-- 2. このファイルの内容を全てコピー
-- 3. 貼り付けて「Run」をクリック
-- 4. 完了を待つ（約30秒）
--
-- 注意事項:
-- - 事前にテストアカウント3つを作成してください
--   - test1@example.com
--   - test2@example.com
--   - test3@example.com
-- - このスクリプトが自動的にUUIDを取得します
--
-- =====================================================

-- トランザクション開始
BEGIN;

-- =====================================================
-- PART 1: Phase 5マイグレーション（検索・ソーシャル）
-- =====================================================

-- お気に入りルート
CREATE TABLE IF NOT EXISTS route_favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  route_id UUID REFERENCES official_routes NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, route_id)
);

CREATE INDEX IF NOT EXISTS route_favorites_user_idx ON route_favorites (user_id);
CREATE INDEX IF NOT EXISTS route_favorites_route_idx ON route_favorites (route_id);
CREATE INDEX IF NOT EXISTS route_favorites_created_at_idx ON route_favorites (created_at DESC);

COMMENT ON TABLE route_favorites IS 'ユーザーがお気に入り登録した公式ルート';

-- ピンブックマーク
CREATE TABLE IF NOT EXISTS pin_bookmarks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  pin_id UUID REFERENCES pins NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, pin_id)
);

CREATE INDEX IF NOT EXISTS pin_bookmarks_user_idx ON pin_bookmarks (user_id);
CREATE INDEX IF NOT EXISTS pin_bookmarks_pin_idx ON pin_bookmarks (pin_id);
CREATE INDEX IF NOT EXISTS pin_bookmarks_created_at_idx ON pin_bookmarks (created_at DESC);

COMMENT ON TABLE pin_bookmarks IS 'ユーザーが保存したピン';

-- ユーザーフォロー
CREATE TABLE IF NOT EXISTS user_follows (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  follower_id UUID REFERENCES auth.users NOT NULL,
  following_id UUID REFERENCES auth.users NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (follower_id, following_id),
  CHECK (follower_id != following_id)
);

CREATE INDEX IF NOT EXISTS user_follows_follower_idx ON user_follows (follower_id);
CREATE INDEX IF NOT EXISTS user_follows_following_idx ON user_follows (following_id);
CREATE INDEX IF NOT EXISTS user_follows_created_at_idx ON user_follows (created_at DESC);

COMMENT ON TABLE user_follows IS 'ユーザー間のフォロー関係';

-- 通知
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT,
  related_user_id UUID REFERENCES auth.users,
  related_pin_id UUID REFERENCES pins,
  related_route_id UUID REFERENCES official_routes,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS notifications_user_idx ON notifications (user_id);
CREATE INDEX IF NOT EXISTS notifications_created_at_idx ON notifications (created_at DESC);
CREATE INDEX IF NOT EXISTS notifications_is_read_idx ON notifications (is_read);
CREATE INDEX IF NOT EXISTS notifications_type_idx ON notifications (type);

COMMENT ON TABLE notifications IS 'ユーザー通知';

-- RLS有効化
ALTER TABLE route_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE pin_bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- RLSポリシー: route_favorites
DROP POLICY IF EXISTS "Users can view their own favorites" ON route_favorites;
CREATE POLICY "Users can view their own favorites" ON route_favorites FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own favorites" ON route_favorites;
CREATE POLICY "Users can insert their own favorites" ON route_favorites FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own favorites" ON route_favorites;
CREATE POLICY "Users can delete their own favorites" ON route_favorites FOR DELETE USING (auth.uid() = user_id);

-- RLSポリシー: pin_bookmarks
DROP POLICY IF EXISTS "Users can view their own bookmarks" ON pin_bookmarks;
CREATE POLICY "Users can view their own bookmarks" ON pin_bookmarks FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own bookmarks" ON pin_bookmarks;
CREATE POLICY "Users can insert their own bookmarks" ON pin_bookmarks FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own bookmarks" ON pin_bookmarks;
CREATE POLICY "Users can delete their own bookmarks" ON pin_bookmarks FOR DELETE USING (auth.uid() = user_id);

-- RLSポリシー: user_follows
DROP POLICY IF EXISTS "Users can view all follows" ON user_follows;
CREATE POLICY "Users can view all follows" ON user_follows FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can follow others" ON user_follows;
CREATE POLICY "Users can follow others" ON user_follows FOR INSERT WITH CHECK (auth.uid() = follower_id);

DROP POLICY IF EXISTS "Users can unfollow" ON user_follows;
CREATE POLICY "Users can unfollow" ON user_follows FOR DELETE USING (auth.uid() = follower_id);

-- RLSポリシー: notifications
DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
CREATE POLICY "Users can view their own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own notifications" ON notifications;
CREATE POLICY "Users can update their own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own notifications" ON notifications;
CREATE POLICY "Users can delete their own notifications" ON notifications FOR DELETE USING (auth.uid() = user_id);

-- RPC関数: search_routes (簡易版 - official_routesの構造に依存しない)
CREATE OR REPLACE FUNCTION search_routes(
  p_user_id UUID,
  p_query TEXT DEFAULT NULL,
  p_area_ids UUID[] DEFAULT NULL,
  p_difficulties TEXT[] DEFAULT NULL,
  p_min_distance_km DECIMAL DEFAULT NULL,
  p_max_distance_km DECIMAL DEFAULT NULL,
  p_features TEXT[] DEFAULT NULL,
  p_best_seasons TEXT[] DEFAULT NULL,
  p_sort_by TEXT DEFAULT 'popularity',
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  route_id UUID,
  route_name TEXT,
  route_description TEXT,
  area_id UUID,
  area_name TEXT,
  distance_km DECIMAL,
  estimated_minutes INT,
  difficulty_level TEXT,
  total_pins INT,
  favorites_count INT,
  is_favorited BOOLEAN
) AS $$
BEGIN
  -- official_routesテーブルが存在しない場合は空の結果を返す
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'official_routes') THEN
    RETURN;
  END IF;
  
  RETURN QUERY
  SELECT 
    r.id AS route_id,
    r.title AS route_name,
    r.description AS route_description,
    r.area_id,
    a.name AS area_name,
    r.distance_km,
    r.estimated_duration_minutes AS estimated_minutes,
    r.difficulty AS difficulty_level,
    COALESCE(r.total_pins, 0)::INT AS total_pins,
    COALESCE(fav.favorites_count, 0)::INT AS favorites_count,
    EXISTS(SELECT 1 FROM route_favorites rf WHERE rf.route_id = r.id AND rf.user_id = p_user_id) AS is_favorited
  FROM official_routes r
  INNER JOIN areas a ON r.area_id = a.id
  LEFT JOIN (
    SELECT route_id, COUNT(*) AS favorites_count
    FROM route_favorites
    GROUP BY route_id
  ) fav ON r.id = fav.route_id
  WHERE r.is_active = true
    AND (p_query IS NULL OR r.title ILIKE '%' || p_query || '%' OR r.description ILIKE '%' || p_query || '%')
    AND (p_area_ids IS NULL OR r.area_id = ANY(p_area_ids))
    AND (p_difficulties IS NULL OR r.difficulty = ANY(p_difficulties))
    AND (p_min_distance_km IS NULL OR r.distance_km >= p_min_distance_km)
    AND (p_max_distance_km IS NULL OR r.distance_km <= p_max_distance_km)
  ORDER BY
    CASE WHEN p_sort_by = 'popularity' THEN COALESCE(fav.favorites_count, 0) END DESC,
    CASE WHEN p_sort_by = 'distance_asc' THEN r.distance_km END ASC,
    CASE WHEN p_sort_by = 'distance_desc' THEN r.distance_km END DESC,
    CASE WHEN p_sort_by = 'newest' THEN r.created_at END DESC,
    r.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;

-- RPC関数: get_favorite_routes
CREATE OR REPLACE FUNCTION get_favorite_routes(
  p_user_id UUID,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  route_id UUID,
  route_name TEXT,
  route_description TEXT,
  area_id UUID,
  area_name TEXT,
  distance_km DECIMAL,
  estimated_minutes INT,
  difficulty_level TEXT,
  total_pins INT,
  favorited_at TIMESTAMPTZ
) AS $$
BEGIN
  -- official_routesテーブルが存在しない場合は空の結果を返す
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'official_routes') THEN
    RETURN;
  END IF;
  
  RETURN QUERY
  SELECT 
    r.id AS route_id,
    r.title AS route_name,
    r.description AS route_description,
    r.area_id,
    a.name AS area_name,
    r.distance_km,
    r.estimated_duration_minutes AS estimated_minutes,
    r.difficulty AS difficulty_level,
    COALESCE(r.total_pins, 0)::INT AS total_pins,
    rf.created_at AS favorited_at
  FROM route_favorites rf
  INNER JOIN official_routes r ON rf.route_id = r.id
  INNER JOIN areas a ON r.area_id = a.id
  WHERE rf.user_id = p_user_id
  ORDER BY rf.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;

-- RPC関数: get_user_statistics
CREATE OR REPLACE FUNCTION get_user_statistics(p_user_id UUID)
RETURNS TABLE (
  total_walks INT,
  total_distance_km DECIMAL,
  total_duration_minutes INT,
  areas_visited INT,
  pins_created INT,
  followers_count INT,
  following_count INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE(COUNT(DISTINCT w.id), 0)::INT AS total_walks,
    COALESCE(ROUND((SUM(w.distance_meters) / 1000.0)::NUMERIC, 2), 0) AS total_distance_km,
    COALESCE(ROUND((SUM(w.duration_seconds) / 60.0)::NUMERIC, 0), 0)::INT AS total_duration_minutes,
    COALESCE(COUNT(DISTINCT w.area_id), 0)::INT AS areas_visited,
    COALESCE((SELECT COUNT(*) FROM pins p WHERE p.user_id = p_user_id), 0)::INT AS pins_created,
    COALESCE((SELECT COUNT(*) FROM user_follows uf WHERE uf.following_id = p_user_id), 0)::INT AS followers_count,
    COALESCE((SELECT COUNT(*) FROM user_follows uf WHERE uf.follower_id = p_user_id), 0)::INT AS following_count
  FROM walks w
  WHERE w.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql STABLE;

-- =====================================================
-- PART 2: Phase 5マイグレーション（バッジシステム）
-- =====================================================

-- バッジ定義マスタ
CREATE TABLE IF NOT EXISTS badge_definitions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  badge_code TEXT UNIQUE NOT NULL,
  name_ja TEXT NOT NULL,
  name_en TEXT NOT NULL,
  description TEXT NOT NULL,
  icon_name TEXT NOT NULL,
  category TEXT NOT NULL,
  tier TEXT NOT NULL,
  sort_order INT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS badge_definitions_category_idx ON badge_definitions (category);
CREATE INDEX IF NOT EXISTS badge_definitions_tier_idx ON badge_definitions (tier);
CREATE INDEX IF NOT EXISTS badge_definitions_sort_order_idx ON badge_definitions (sort_order);

COMMENT ON TABLE badge_definitions IS 'バッジ定義マスタ';

-- ユーザーバッジ
CREATE TABLE IF NOT EXISTS user_badges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  badge_id UUID REFERENCES badge_definitions NOT NULL,
  unlocked_at TIMESTAMPTZ DEFAULT NOW(),
  is_new BOOLEAN DEFAULT TRUE,
  UNIQUE (user_id, badge_id)
);

CREATE INDEX IF NOT EXISTS user_badges_user_idx ON user_badges (user_id);
CREATE INDEX IF NOT EXISTS user_badges_badge_idx ON user_badges (badge_id);
CREATE INDEX IF NOT EXISTS user_badges_unlocked_at_idx ON user_badges (unlocked_at DESC);
CREATE INDEX IF NOT EXISTS user_badges_is_new_idx ON user_badges (is_new);

COMMENT ON TABLE user_badges IS 'ユーザーが獲得したバッジ';

-- RLS有効化
ALTER TABLE badge_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;

-- RLSポリシー: badge_definitions（全員閲覧可能）
DROP POLICY IF EXISTS "Anyone can view badge definitions" ON badge_definitions;
CREATE POLICY "Anyone can view badge definitions" ON badge_definitions FOR SELECT USING (true);

-- RLSポリシー: user_badges
DROP POLICY IF EXISTS "Users can view their own badges" ON user_badges;
CREATE POLICY "Users can view their own badges" ON user_badges FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own badges" ON user_badges;
CREATE POLICY "Users can update their own badges" ON user_badges FOR UPDATE USING (auth.uid() = user_id);

-- 初期バッジデータ投入
INSERT INTO badge_definitions (badge_code, name_ja, name_en, description, icon_name, category, tier, sort_order)
VALUES
  -- 距離バッジ
  ('distance_10km', '10km達成', '10km Walker', '累計10kmの散歩を達成', 'directions_walk', 'distance', 'bronze', 1),
  ('distance_50km', '50km達成', '50km Walker', '累計50kmの散歩を達成', 'emoji_events', 'distance', 'silver', 2),
  ('distance_100km', '100km達成', '100km Walker', '累計100kmの散歩を達成', 'workspace_premium', 'distance', 'gold', 3),
  ('distance_500km', '500km達成', '500km Walker', '累計500kmの散歩を達成', 'military_tech', 'distance', 'platinum', 4),
  
  -- エリア探索バッジ
  ('area_3', '3エリア探索', 'Area Explorer', '3つのエリアを訪問', 'explore', 'area', 'bronze', 5),
  ('area_5', '5エリア探索', 'Area Master', '5つのエリアを訪問', 'public', 'area', 'silver', 6),
  ('area_10', '10エリア探索', 'Area Champion', '10つのエリアを訪問', 'travel_explore', 'area', 'gold', 7),
  
  -- ピン作成バッジ
  ('pins_5', '5ピン作成', 'Pin Creator', '5つのピンを作成', 'push_pin', 'pins', 'bronze', 8),
  ('pins_20', '20ピン作成', 'Pin Master', '20つのピンを作成', 'location_on', 'pins', 'silver', 9),
  ('pins_50', '50ピン作成', 'Pin Expert', '50つのピンを作成', 'add_location', 'pins', 'gold', 10),
  ('pins_100', '100ピン作成', 'Pin Legend', '100つのピンを作成', 'place', 'pins', 'platinum', 11),
  
  -- ソーシャルバッジ
  ('followers_10', '10フォロワー', '10 Followers', '10人のフォロワーを獲得', 'people', 'social', 'bronze', 12),
  ('followers_50', '50フォロワー', '50 Followers', '50人のフォロワーを獲得', 'groups', 'social', 'silver', 13),
  ('followers_100', '100フォロワー', '100 Followers', '100人のフォロワーを獲得', 'supervisor_account', 'social', 'gold', 14),
  
  -- 特別バッジ
  ('first_walk', '初めての散歩', 'First Walk', '最初の散歩を完了', 'celebration', 'special', 'bronze', 15),
  ('first_pin', '初めてのピン', 'First Pin', '最初のピンを作成', 'new_releases', 'special', 'bronze', 16),
  ('early_adopter', '早期利用者', 'Early Adopter', 'WanMapの早期利用者', 'star', 'special', 'gold', 17)
ON CONFLICT (badge_code) DO NOTHING;

-- RPC関数: check_and_unlock_badges
CREATE OR REPLACE FUNCTION check_and_unlock_badges(p_user_id UUID)
RETURNS TABLE (newly_unlocked_badges UUID[]) AS $$
DECLARE
  v_stats RECORD;
  v_new_badges UUID[];
  v_badge_id UUID;
BEGIN
  -- ユーザー統計を取得
  SELECT * INTO v_stats FROM get_user_statistics(p_user_id);
  
  v_new_badges := ARRAY[]::UUID[];
  
  -- 距離バッジチェック
  IF v_stats.total_distance_km >= 10 THEN
    SELECT id INTO v_badge_id FROM badge_definitions WHERE badge_code = 'distance_10km';
    IF NOT EXISTS (SELECT 1 FROM user_badges WHERE user_id = p_user_id AND badge_id = v_badge_id) THEN
      INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge_id);
      v_new_badges := array_append(v_new_badges, v_badge_id);
    END IF;
  END IF;
  
  IF v_stats.total_distance_km >= 50 THEN
    SELECT id INTO v_badge_id FROM badge_definitions WHERE badge_code = 'distance_50km';
    IF NOT EXISTS (SELECT 1 FROM user_badges WHERE user_id = p_user_id AND badge_id = v_badge_id) THEN
      INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge_id);
      v_new_badges := array_append(v_new_badges, v_badge_id);
    END IF;
  END IF;
  
  IF v_stats.total_distance_km >= 100 THEN
    SELECT id INTO v_badge_id FROM badge_definitions WHERE badge_code = 'distance_100km';
    IF NOT EXISTS (SELECT 1 FROM user_badges WHERE user_id = p_user_id AND badge_id = v_badge_id) THEN
      INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge_id);
      v_new_badges := array_append(v_new_badges, v_badge_id);
    END IF;
  END IF;
  
  IF v_stats.total_distance_km >= 500 THEN
    SELECT id INTO v_badge_id FROM badge_definitions WHERE badge_code = 'distance_500km';
    IF NOT EXISTS (SELECT 1 FROM user_badges WHERE user_id = p_user_id AND badge_id = v_badge_id) THEN
      INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge_id);
      v_new_badges := array_append(v_new_badges, v_badge_id);
    END IF;
  END IF;
  
  -- エリアバッジチェック
  IF v_stats.areas_visited >= 3 THEN
    SELECT id INTO v_badge_id FROM badge_definitions WHERE badge_code = 'area_3';
    IF NOT EXISTS (SELECT 1 FROM user_badges WHERE user_id = p_user_id AND badge_id = v_badge_id) THEN
      INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge_id);
      v_new_badges := array_append(v_new_badges, v_badge_id);
    END IF;
  END IF;
  
  IF v_stats.areas_visited >= 5 THEN
    SELECT id INTO v_badge_id FROM badge_definitions WHERE badge_code = 'area_5';
    IF NOT EXISTS (SELECT 1 FROM user_badges WHERE user_id = p_user_id AND badge_id = v_badge_id) THEN
      INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge_id);
      v_new_badges := array_append(v_new_badges, v_badge_id);
    END IF;
  END IF;
  
  IF v_stats.areas_visited >= 10 THEN
    SELECT id INTO v_badge_id FROM badge_definitions WHERE badge_code = 'area_10';
    IF NOT EXISTS (SELECT 1 FROM user_badges WHERE user_id = p_user_id AND badge_id = v_badge_id) THEN
      INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge_id);
      v_new_badges := array_append(v_new_badges, v_badge_id);
    END IF;
  END IF;
  
  -- ピンバッジチェック
  IF v_stats.pins_created >= 5 THEN
    SELECT id INTO v_badge_id FROM badge_definitions WHERE badge_code = 'pins_5';
    IF NOT EXISTS (SELECT 1 FROM user_badges WHERE user_id = p_user_id AND badge_id = v_badge_id) THEN
      INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge_id);
      v_new_badges := array_append(v_new_badges, v_badge_id);
    END IF;
  END IF;
  
  IF v_stats.pins_created >= 20 THEN
    SELECT id INTO v_badge_id FROM badge_definitions WHERE badge_code = 'pins_20';
    IF NOT EXISTS (SELECT 1 FROM user_badges WHERE user_id = p_user_id AND badge_id = v_badge_id) THEN
      INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge_id);
      v_new_badges := array_append(v_new_badges, v_badge_id);
    END IF;
  END IF;
  
  IF v_stats.pins_created >= 50 THEN
    SELECT id INTO v_badge_id FROM badge_definitions WHERE badge_code = 'pins_50';
    IF NOT EXISTS (SELECT 1 FROM user_badges WHERE user_id = p_user_id AND badge_id = v_badge_id) THEN
      INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge_id);
      v_new_badges := array_append(v_new_badges, v_badge_id);
    END IF;
  END IF;
  
  IF v_stats.pins_created >= 100 THEN
    SELECT id INTO v_badge_id FROM badge_definitions WHERE badge_code = 'pins_100';
    IF NOT EXISTS (SELECT 1 FROM user_badges WHERE user_id = p_user_id AND badge_id = v_badge_id) THEN
      INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge_id);
      v_new_badges := array_append(v_new_badges, v_badge_id);
    END IF;
  END IF;
  
  -- ソーシャルバッジチェック
  IF v_stats.followers_count >= 10 THEN
    SELECT id INTO v_badge_id FROM badge_definitions WHERE badge_code = 'followers_10';
    IF NOT EXISTS (SELECT 1 FROM user_badges WHERE user_id = p_user_id AND badge_id = v_badge_id) THEN
      INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge_id);
      v_new_badges := array_append(v_new_badges, v_badge_id);
    END IF;
  END IF;
  
  IF v_stats.followers_count >= 50 THEN
    SELECT id INTO v_badge_id FROM badge_definitions WHERE badge_code = 'followers_50';
    IF NOT EXISTS (SELECT 1 FROM user_badges WHERE user_id = p_user_id AND badge_id = v_badge_id) THEN
      INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge_id);
      v_new_badges := array_append(v_new_badges, v_badge_id);
    END IF;
  END IF;
  
  IF v_stats.followers_count >= 100 THEN
    SELECT id INTO v_badge_id FROM badge_definitions WHERE badge_code = 'followers_100';
    IF NOT EXISTS (SELECT 1 FROM user_badges WHERE user_id = p_user_id AND badge_id = v_badge_id) THEN
      INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge_id);
      v_new_badges := array_append(v_new_badges, v_badge_id);
    END IF;
  END IF;
  
  -- 特別バッジ: 初めての散歩
  IF v_stats.total_walks >= 1 THEN
    SELECT id INTO v_badge_id FROM badge_definitions WHERE badge_code = 'first_walk';
    IF NOT EXISTS (SELECT 1 FROM user_badges WHERE user_id = p_user_id AND badge_id = v_badge_id) THEN
      INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge_id);
      v_new_badges := array_append(v_new_badges, v_badge_id);
    END IF;
  END IF;
  
  -- 特別バッジ: 初めてのピン
  IF v_stats.pins_created >= 1 THEN
    SELECT id INTO v_badge_id FROM badge_definitions WHERE badge_code = 'first_pin';
    IF NOT EXISTS (SELECT 1 FROM user_badges WHERE user_id = p_user_id AND badge_id = v_badge_id) THEN
      INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge_id);
      v_new_badges := array_append(v_new_badges, v_badge_id);
    END IF;
  END IF;
  
  -- 新規バッジの通知を作成
  IF array_length(v_new_badges, 1) > 0 THEN
    FOR v_badge_id IN SELECT unnest(v_new_badges) LOOP
      INSERT INTO notifications (user_id, type, title, body)
      SELECT 
        p_user_id,
        'badge_unlocked',
        '新しいバッジを獲得！',
        bd.name_ja || 'を獲得しました'
      FROM badge_definitions bd
      WHERE bd.id = v_badge_id;
    END LOOP;
  END IF;
  
  RETURN QUERY SELECT v_new_badges;
END;
$$ LANGUAGE plpgsql;

-- RPC関数: get_user_badges
CREATE OR REPLACE FUNCTION get_user_badges(p_user_id UUID)
RETURNS TABLE (
  badge_id UUID,
  badge_code TEXT,
  name_ja TEXT,
  name_en TEXT,
  description TEXT,
  icon_name TEXT,
  category TEXT,
  tier TEXT,
  sort_order INT,
  is_unlocked BOOLEAN,
  unlocked_at TIMESTAMPTZ,
  is_new BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    bd.id AS badge_id,
    bd.badge_code,
    bd.name_ja,
    bd.name_en,
    bd.description,
    bd.icon_name,
    bd.category,
    bd.tier,
    bd.sort_order,
    CASE WHEN ub.id IS NOT NULL THEN TRUE ELSE FALSE END AS is_unlocked,
    ub.unlocked_at,
    COALESCE(ub.is_new, FALSE) AS is_new
  FROM badge_definitions bd
  LEFT JOIN user_badges ub ON bd.id = ub.badge_id AND ub.user_id = p_user_id
  ORDER BY bd.sort_order;
END;
$$ LANGUAGE plpgsql STABLE;

-- =====================================================
-- PART 3: テストデータ投入（自動UUID取得版・修正版）
-- =====================================================

DO $$
DECLARE
  user1_id UUID;
  user2_id UUID;
  user3_id UUID;
  area1_id UUID;
  area2_id UUID;
  area3_id UUID;
  route1_id UUID;
  route2_id UUID;
  v_has_areas BOOLEAN;
  v_has_routes BOOLEAN;
BEGIN
  -- =====================================================
  -- テストユーザーのUUID取得
  -- =====================================================
  
  -- test1@example.com のUUIDを取得
  SELECT id INTO user1_id 
  FROM auth.users 
  WHERE email = 'test1@example.com' 
  LIMIT 1;
  
  -- test2@example.com のUUIDを取得
  SELECT id INTO user2_id 
  FROM auth.users 
  WHERE email = 'test2@example.com' 
  LIMIT 1;
  
  -- test3@example.com のUUIDを取得
  SELECT id INTO user3_id 
  FROM auth.users 
  WHERE email = 'test3@example.com' 
  LIMIT 1;
  
  -- ユーザーが見つからない場合はエラー
  IF user1_id IS NULL OR user2_id IS NULL OR user3_id IS NULL THEN
    RAISE EXCEPTION 'テストアカウントが見つかりません。以下の3つのアカウントを作成してください: test1@example.com, test2@example.com, test3@example.com';
  END IF;
  
  RAISE NOTICE 'テストユーザーUUID取得成功:';
  RAISE NOTICE '  User 1 (test1@example.com): %', user1_id;
  RAISE NOTICE '  User 2 (test2@example.com): %', user2_id;
  RAISE NOTICE '  User 3 (test3@example.com): %', user3_id;
  
  -- =====================================================
  -- エリアとルートのIDを取得
  -- =====================================================
  
  -- エリアが存在するかチェック
  SELECT EXISTS(SELECT 1 FROM areas LIMIT 1) INTO v_has_areas;
  
  -- ルートが存在するかチェック (修正版 - is_official削除)
  SELECT EXISTS(SELECT 1 FROM official_routes LIMIT 1) INTO v_has_routes;
  
  IF NOT v_has_areas THEN
    RAISE NOTICE '警告: エリアデータが存在しません。基本マイグレーションを先に実行してください。';
    RAISE NOTICE 'テストデータの一部（散歩履歴、ピン）はスキップされます。';
  ELSE
    SELECT id INTO area1_id FROM areas LIMIT 1 OFFSET 0;
    SELECT id INTO area2_id FROM areas LIMIT 1 OFFSET 1;
    SELECT id INTO area3_id FROM areas LIMIT 1 OFFSET 2;
    
    -- area3が取得できない場合はarea1を使用
    IF area3_id IS NULL THEN
      area3_id := area1_id;
    END IF;
    
    RAISE NOTICE 'エリアID取得成功: %, %, %', area1_id, area2_id, area3_id;
  END IF;
  
  IF NOT v_has_routes THEN
    RAISE NOTICE '警告: 公式ルートデータが存在しません。';
    RAISE NOTICE 'ルートお気に入りのテストデータはスキップされます。';
  ELSE
    SELECT id INTO route1_id FROM official_routes LIMIT 1 OFFSET 0;
    SELECT id INTO route2_id FROM official_routes LIMIT 1 OFFSET 1;
    
    -- route2が取得できない場合はroute1を使用
    IF route2_id IS NULL THEN
      route2_id := route1_id;
    END IF;
    
    RAISE NOTICE 'ルートID取得成功: %, %', route1_id, route2_id;
  END IF;
  
  -- =====================================================
  -- 散歩履歴の作成
  -- =====================================================
  
  IF v_has_areas THEN
    -- User 1: 散歩マスター (10件の散歩)
    FOR i IN 1..10 LOOP
      INSERT INTO walks (
        id, user_id, area_id, route_id,
        distance_meters, duration_seconds, completed_at,
        path_geom, start_location, end_location
      ) VALUES (
        gen_random_uuid(),
        user1_id,
        CASE WHEN i <= 4 THEN area1_id WHEN i <= 7 THEN area2_id ELSE area3_id END,
        CASE WHEN i % 2 = 0 AND v_has_routes THEN route1_id ELSE NULL END,
        1000 + (i * 500),
        1800 + (i * 300),
        NOW() - (i || ' days')::INTERVAL,
        ST_GeomFromText('LINESTRING(139.6917 35.6895, 139.6920 35.6900)', 4326),
        ST_GeomFromText('POINT(139.6917 35.6895)', 4326),
        ST_GeomFromText('POINT(139.6920 35.6900)', 4326)
      )
      ON CONFLICT DO NOTHING;
    END LOOP;
    
    -- User 2: バッジコレクター (7件の散歩)
    FOR i IN 1..7 LOOP
      INSERT INTO walks (
        id, user_id, area_id,
        distance_meters, duration_seconds, completed_at,
        path_geom, start_location, end_location
      ) VALUES (
        gen_random_uuid(),
        user2_id,
        CASE WHEN i <= 3 THEN area1_id ELSE area2_id END,
        800 + (i * 400),
        1500 + (i * 200),
        NOW() - (i || ' days')::INTERVAL,
        ST_GeomFromText('LINESTRING(139.6917 35.6895, 139.6918 35.6898)', 4326),
        ST_GeomFromText('POINT(139.6917 35.6895)', 4326),
        ST_GeomFromText('POINT(139.6918 35.6898)', 4326)
      )
      ON CONFLICT DO NOTHING;
    END LOOP;
    
    -- User 3: ソーシャルユーザー (5件の散歩)
    FOR i IN 1..5 LOOP
      INSERT INTO walks (
        id, user_id, area_id,
        distance_meters, duration_seconds, completed_at,
        path_geom, start_location, end_location
      ) VALUES (
        gen_random_uuid(),
        user3_id,
        area1_id,
        1200 + (i * 300),
        2000 + (i * 250),
        NOW() - (i || ' days')::INTERVAL,
        ST_GeomFromText('LINESTRING(139.6917 35.6895, 139.6919 35.6897)', 4326),
        ST_GeomFromText('POINT(139.6917 35.6895)', 4326),
        ST_GeomFromText('POINT(139.6919 35.6897)', 4326)
      )
      ON CONFLICT DO NOTHING;
    END LOOP;
    
    RAISE NOTICE '散歩履歴作成完了: User1=10件, User2=7件, User3=5件';
  END IF;
  
  -- =====================================================
  -- ピンの作成
  -- =====================================================
  
  IF v_has_areas THEN
    -- User 1: 5個のピン
    FOR i IN 1..5 LOOP
      INSERT INTO pins (
        id, user_id, area_id,
        name, description, pin_type,
        location, created_at
      ) VALUES (
        gen_random_uuid(),
        user1_id,
        CASE WHEN i <= 2 THEN area1_id ELSE area2_id END,
        'User1 Pin ' || i,
        'Test pin ' || i || ' by User 1',
        CASE 
          WHEN i = 1 THEN 'scenic_spot'
          WHEN i = 2 THEN 'dog_friendly_spot'
          WHEN i = 3 THEN 'water_fountain'
          WHEN i = 4 THEN 'rest_area'
          ELSE 'photo_spot'
        END,
        ST_GeomFromText('POINT(' || (139.6917 + i * 0.001)::text || ' ' || (35.6895 + i * 0.0005)::text || ')', 4326),
        NOW() - (i || ' days')::INTERVAL
      )
      ON CONFLICT DO NOTHING;
    END LOOP;
    
    -- User 2: 3個のピン
    FOR i IN 1..3 LOOP
      INSERT INTO pins (
        id, user_id, area_id,
        name, description, pin_type,
        location, created_at
      ) VALUES (
        gen_random_uuid(),
        user2_id,
        area1_id,
        'User2 Pin ' || i,
        'Test pin ' || i || ' by User 2',
        CASE 
          WHEN i = 1 THEN 'dog_park'
          WHEN i = 2 THEN 'scenic_spot'
          ELSE 'cafe'
        END,
        ST_GeomFromText('POINT(' || (139.6920 + i * 0.001)::text || ' ' || (35.6897 + i * 0.0005)::text || ')', 4326),
        NOW() - (i || ' days')::INTERVAL
      )
      ON CONFLICT DO NOTHING;
    END LOOP;
    
    -- User 3: 4個のピン
    FOR i IN 1..4 LOOP
      INSERT INTO pins (
        id, user_id, area_id,
        name, description, pin_type,
        location, created_at
      ) VALUES (
        gen_random_uuid(),
        user3_id,
        area1_id,
        'User3 Pin ' || i,
        'Test pin ' || i || ' by User 3',
        CASE 
          WHEN i = 1 THEN 'photo_spot'
          WHEN i = 2 THEN 'dog_friendly_shop'
          WHEN i = 3 THEN 'rest_area'
          ELSE 'scenic_spot'
        END,
        ST_GeomFromText('POINT(' || (139.6918 + i * 0.001)::text || ' ' || (35.6896 + i * 0.0005)::text || ')', 4326),
        NOW() - (i || ' days')::INTERVAL
      )
      ON CONFLICT DO NOTHING;
    END LOOP;
    
    RAISE NOTICE 'ピン作成完了: User1=5個, User2=3個, User3=4個';
  END IF;
  
  -- =====================================================
  -- ルートお気に入り
  -- =====================================================
  
  IF v_has_routes THEN
    INSERT INTO route_favorites (user_id, route_id, created_at)
    VALUES 
      (user1_id, route1_id, NOW() - '2 days'::INTERVAL),
      (user1_id, route2_id, NOW() - '1 day'::INTERVAL),
      (user2_id, route1_id, NOW() - '3 days'::INTERVAL),
      (user3_id, route2_id, NOW() - '1 day'::INTERVAL)
    ON CONFLICT (user_id, route_id) DO NOTHING;
    
    RAISE NOTICE 'ルートお気に入り作成完了: 4件';
  END IF;
  
  -- =====================================================
  -- ピンブックマーク
  -- =====================================================
  
  IF v_has_areas THEN
    -- User1がUser2とUser3のピンをブックマーク
    INSERT INTO pin_bookmarks (user_id, pin_id, created_at)
    SELECT user1_id, id, NOW() - '1 day'::INTERVAL
    FROM pins WHERE user_id IN (user2_id, user3_id)
    LIMIT 3
    ON CONFLICT (user_id, pin_id) DO NOTHING;
    
    -- User2がUser1のピンをブックマーク
    INSERT INTO pin_bookmarks (user_id, pin_id, created_at)
    SELECT user2_id, id, NOW() - '2 days'::INTERVAL
    FROM pins WHERE user_id = user1_id
    LIMIT 2
    ON CONFLICT (user_id, pin_id) DO NOTHING;
    
    RAISE NOTICE 'ピンブックマーク作成完了: 約5件';
  END IF;
  
  -- =====================================================
  -- ユーザーフォロー関係
  -- =====================================================
  
  -- User1 → User2, User3をフォロー
  INSERT INTO user_follows (follower_id, following_id, created_at)
  VALUES 
    (user1_id, user2_id, NOW() - '5 days'::INTERVAL),
    (user1_id, user3_id, NOW() - '4 days'::INTERVAL)
  ON CONFLICT (follower_id, following_id) DO NOTHING;
  
  -- User2 → User1をフォロー
  INSERT INTO user_follows (follower_id, following_id, created_at)
  VALUES 
    (user2_id, user1_id, NOW() - '3 days'::INTERVAL)
  ON CONFLICT (follower_id, following_id) DO NOTHING;
  
  -- User3 → User1, User2をフォロー
  INSERT INTO user_follows (follower_id, following_id, created_at)
  VALUES 
    (user3_id, user1_id, NOW() - '2 days'::INTERVAL),
    (user3_id, user2_id, NOW() - '1 day'::INTERVAL)
  ON CONFLICT (follower_id, following_id) DO NOTHING;
  
  RAISE NOTICE 'フォロー関係作成完了: 5件';
  
  -- =====================================================
  -- 通知
  -- =====================================================
  
  -- User1への通知
  INSERT INTO notifications (user_id, type, title, body, related_user_id, is_read, created_at)
  VALUES 
    (user1_id, 'new_follower', '新しいフォロワー', 'があなたをフォローしました', user2_id, false, NOW() - '3 days'::INTERVAL),
    (user1_id, 'new_follower', '新しいフォロワー', 'があなたをフォローしました', user3_id, false, NOW() - '2 days'::INTERVAL),
    (user1_id, 'pin_liked', 'ピンがいいねされました', 'があなたのピンにいいねしました', user2_id, true, NOW() - '4 days'::INTERVAL);
  
  -- User2への通知
  INSERT INTO notifications (user_id, type, title, body, related_user_id, is_read, created_at)
  VALUES 
    (user2_id, 'new_follower', '新しいフォロワー', 'があなたをフォローしました', user1_id, false, NOW() - '5 days'::INTERVAL),
    (user2_id, 'new_follower', '新しいフォロワー', 'があなたをフォローしました', user3_id, false, NOW() - '1 day'::INTERVAL);
  
  -- User3への通知
  INSERT INTO notifications (user_id, type, title, body, related_user_id, is_read, created_at)
  VALUES 
    (user3_id, 'new_follower', '新しいフォロワー', 'があなたをフォローしました', user1_id, true, NOW() - '4 days'::INTERVAL);
  
  RAISE NOTICE '通知作成完了: 6件';
  
  -- =====================================================
  -- バッジ解除（自動チェック実行）
  -- =====================================================
  
  -- User1のバッジチェック
  PERFORM check_and_unlock_badges(user1_id);
  
  -- User2のバッジチェック
  PERFORM check_and_unlock_badges(user2_id);
  
  -- User3のバッジチェック
  PERFORM check_and_unlock_badges(user3_id);
  
  RAISE NOTICE 'バッジ解除チェック完了（自動）';
  
  -- =====================================================
  -- 完了メッセージ
  -- =====================================================
  
  RAISE NOTICE '';
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'テストデータ投入完了！';
  RAISE NOTICE '==============================================';
  RAISE NOTICE '';
  RAISE NOTICE '次のステップ:';
  RAISE NOTICE '1. 以下のSQLで統計を確認してください:';
  RAISE NOTICE '   SELECT * FROM get_user_statistics(''%'');', user1_id;
  RAISE NOTICE '';
  RAISE NOTICE '2. アプリを起動してテストを開始してください:';
  RAISE NOTICE '   cd /home/user/webapp/wanmap_v2';
  RAISE NOTICE '   flutter run';
  RAISE NOTICE '';
  RAISE NOTICE '3. ログイン情報:';
  RAISE NOTICE '   - test1@example.com / test123456';
  RAISE NOTICE '   - test2@example.com / test123456';
  RAISE NOTICE '   - test3@example.com / test123456';
  RAISE NOTICE '';
  
END $$;

-- トランザクション完了
COMMIT;

-- =====================================================
-- 確認クエリ（実行後に確認用）
-- =====================================================

-- テーブル数を確認
SELECT 
  'route_favorites' as table_name, COUNT(*) as count FROM route_favorites
UNION ALL
SELECT 'pin_bookmarks', COUNT(*) FROM pin_bookmarks
UNION ALL
SELECT 'user_follows', COUNT(*) FROM user_follows
UNION ALL
SELECT 'notifications', COUNT(*) FROM notifications
UNION ALL
SELECT 'badge_definitions', COUNT(*) FROM badge_definitions
UNION ALL
SELECT 'walks', COUNT(*) FROM walks
UNION ALL
SELECT 'pins', COUNT(*) FROM pins
UNION ALL
SELECT 'user_badges', COUNT(*) FROM user_badges;
