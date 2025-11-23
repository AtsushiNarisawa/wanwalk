-- =====================================================
-- WanMap Phase 5-5: バッジシステム
-- =====================================================
-- 実行日: 2025-11-22
-- 目的: ユーザーのモチベーション向上のためのバッジ・実績システム

-- =====================================================
-- バッジ定義マスタ
-- =====================================================
CREATE TABLE IF NOT EXISTS badge_definitions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  badge_code TEXT UNIQUE NOT NULL,
  name_ja TEXT NOT NULL,
  name_en TEXT NOT NULL,
  description TEXT NOT NULL,
  icon_name TEXT NOT NULL, -- アイコン名（Flutter Icons）
  category TEXT CHECK (category IN ('distance', 'area', 'pins', 'social', 'special')) NOT NULL,
  tier TEXT CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum')) NOT NULL,
  requirement_type TEXT NOT NULL, -- 'total_distance_km', 'areas_visited', 'pins_created', etc.
  requirement_value INT NOT NULL,
  display_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX badge_definitions_category_idx ON badge_definitions (category);
CREATE INDEX badge_definitions_display_order_idx ON badge_definitions (display_order);

COMMENT ON TABLE badge_definitions IS 'バッジ定義マスタ';

-- =====================================================
-- ユーザーバッジ獲得記録
-- =====================================================
CREATE TABLE IF NOT EXISTS user_badges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  badge_id UUID REFERENCES badge_definitions NOT NULL,
  unlocked_at TIMESTAMPTZ DEFAULT NOW(),
  is_new BOOLEAN DEFAULT TRUE, -- 新規バッジ通知用
  UNIQUE (user_id, badge_id)
);

CREATE INDEX user_badges_user_idx ON user_badges (user_id);
CREATE INDEX user_badges_unlocked_at_idx ON user_badges (unlocked_at DESC);

COMMENT ON TABLE user_badges IS 'ユーザーが獲得したバッジ';

-- =====================================================
-- 初期バッジデータ投入
-- =====================================================

-- 距離系バッジ
INSERT INTO badge_definitions (badge_code, name_ja, name_en, description, icon_name, category, tier, requirement_type, requirement_value, display_order) VALUES
('distance_10km', '初心者ウォーカー', 'Beginner Walker', '総距離10km達成！散歩の第一歩です', 'directions_walk', 'distance', 'bronze', 'total_distance_km', 10, 1),
('distance_50km', '散歩マスター', 'Walk Master', '総距離50km達成！素晴らしい実績です', 'emoji_events', 'distance', 'silver', 'total_distance_km', 50, 2),
('distance_100km', '百キロの道', 'Century Walker', '総距離100km達成！驚異的な記録です', 'workspace_premium', 'distance', 'gold', 'total_distance_km', 100, 3),
('distance_500km', '超長距離ウォーカー', 'Ultra Walker', '総距離500km達成！伝説の域に到達しました', 'military_tech', 'distance', 'platinum', 'total_distance_km', 500, 4);

-- エリア探索系バッジ
INSERT INTO badge_definitions (badge_code, name_ja, name_en, description, icon_name, category, tier, requirement_type, requirement_value, display_order) VALUES
('area_3', 'エリアエクスプローラー', 'Area Explorer', '3つのエリアを訪問しました', 'explore', 'area', 'bronze', 'areas_visited', 3, 11),
('area_5', 'エリアマスター', 'Area Master', '5つのエリアを訪問しました', 'public', 'area', 'silver', 'areas_visited', 5, 12),
('area_10', 'エリアコンプリート', 'Area Complete', '10のエリアを訪問しました', 'travel_explore', 'area', 'gold', 'areas_visited', 10, 13);

-- ピン投稿系バッジ
INSERT INTO badge_definitions (badge_code, name_ja, name_en, description, icon_name, category, tier, requirement_type, requirement_value, display_order) VALUES
('pins_5', 'ピン投稿ビギナー', 'Pin Beginner', '5つのピンを投稿しました', 'push_pin', 'pins', 'bronze', 'pins_created', 5, 21),
('pins_20', 'ピン投稿マスター', 'Pin Master', '20のピンを投稿しました', 'location_on', 'pins', 'silver', 'pins_created', 20, 22),
('pins_50', 'ピン投稿エキスパート', 'Pin Expert', '50のピンを投稿しました', 'add_location', 'pins', 'gold', 'pins_created', 50, 23),
('pins_100', 'ピン投稿レジェンド', 'Pin Legend', '100のピンを投稿しました', 'place', 'pins', 'platinum', 'pins_created', 100, 24);

-- ソーシャル系バッジ
INSERT INTO badge_definitions (badge_code, name_ja, name_en, description, icon_name, category, tier, requirement_type, requirement_value, display_order) VALUES
('followers_10', '人気ユーザー', 'Popular User', '10人のフォロワーを獲得しました', 'people', 'social', 'bronze', 'followers_count', 10, 31),
('followers_50', 'インフルエンサー', 'Influencer', '50人のフォロワーを獲得しました', 'groups', 'social', 'silver', 'followers_count', 50, 32),
('followers_100', 'コミュニティリーダー', 'Community Leader', '100人のフォロワーを獲得しました', 'supervisor_account', 'social', 'gold', 'followers_count', 100, 33);

-- 特別バッジ
INSERT INTO badge_definitions (badge_code, name_ja, name_en, description, icon_name, category, tier, requirement_type, requirement_value, display_order) VALUES
('first_walk', '初めての散歩', 'First Walk', '初めてのお出かけ散歩を完了しました', 'celebration', 'special', 'bronze', 'total_walks', 1, 41),
('first_pin', '初めてのピン', 'First Pin', '初めてのピンを投稿しました', 'new_releases', 'special', 'bronze', 'pins_created', 1, 42),
('early_adopter', 'アーリーアダプター', 'Early Adopter', 'WanMapの初期メンバーです', 'star', 'special', 'platinum', 'special', 0, 43);

-- =====================================================
-- RPC: バッジ解除チェック関数
-- =====================================================
CREATE OR REPLACE FUNCTION check_and_unlock_badges(
  p_user_id UUID
)
RETURNS TABLE (
  newly_unlocked_badges UUID[]
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_statistics RECORD;
  v_badge RECORD;
  v_newly_unlocked UUID[];
BEGIN
  -- ユーザー統計を取得
  SELECT * INTO v_statistics FROM get_user_statistics(p_user_id);
  
  v_newly_unlocked := ARRAY[]::UUID[];
  
  -- 全バッジ定義をループ
  FOR v_badge IN 
    SELECT * FROM badge_definitions WHERE is_active = TRUE
  LOOP
    -- 既に解除済みかチェック
    IF NOT EXISTS(
      SELECT 1 FROM user_badges 
      WHERE user_id = p_user_id AND badge_id = v_badge.id
    ) THEN
      -- バッジ条件チェック
      IF (
        (v_badge.requirement_type = 'total_distance_km' AND v_statistics.total_distance_km >= v_badge.requirement_value) OR
        (v_badge.requirement_type = 'areas_visited' AND v_statistics.areas_visited >= v_badge.requirement_value) OR
        (v_badge.requirement_type = 'pins_created' AND v_statistics.pins_created >= v_badge.requirement_value) OR
        (v_badge.requirement_type = 'total_walks' AND v_statistics.total_walks >= v_badge.requirement_value) OR
        (v_badge.requirement_type = 'followers_count' AND v_statistics.followers_count >= v_badge.requirement_value) OR
        (v_badge.requirement_type = 'special' AND v_badge.badge_code = 'early_adopter')
      ) THEN
        -- バッジ解除
        INSERT INTO user_badges (user_id, badge_id, is_new)
        VALUES (p_user_id, v_badge.id, TRUE);
        
        v_newly_unlocked := array_append(v_newly_unlocked, v_badge.id);
        
        -- 通知作成
        INSERT INTO notifications (user_id, type, title, body, target_id)
        VALUES (
          p_user_id,
          'badge_unlocked',
          'バッジ獲得！',
          v_badge.name_ja || 'を獲得しました！',
          v_badge.id::TEXT
        );
      END IF;
    END IF;
  END LOOP;
  
  RETURN QUERY SELECT v_newly_unlocked;
END;
$$;

COMMENT ON FUNCTION check_and_unlock_badges IS 'ユーザーのバッジ解除条件をチェックし、新規バッジを解除';

-- =====================================================
-- RPC: ユーザーのバッジ一覧取得
-- =====================================================
CREATE OR REPLACE FUNCTION get_user_badges(
  p_user_id UUID
)
RETURNS TABLE (
  badge_id UUID,
  badge_code TEXT,
  name_ja TEXT,
  name_en TEXT,
  description TEXT,
  icon_name TEXT,
  category TEXT,
  tier TEXT,
  unlocked_at TIMESTAMPTZ,
  is_new BOOLEAN,
  is_unlocked BOOLEAN
)
LANGUAGE plpgsql
AS $$
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
    ub.unlocked_at,
    COALESCE(ub.is_new, FALSE) AS is_new,
    (ub.id IS NOT NULL) AS is_unlocked
  FROM badge_definitions bd
  LEFT JOIN user_badges ub ON ub.badge_id = bd.id AND ub.user_id = p_user_id
  WHERE bd.is_active = TRUE
  ORDER BY bd.display_order;
END;
$$;

COMMENT ON FUNCTION get_user_badges IS 'ユーザーの全バッジ（解除済み・未解除）を取得';

-- =====================================================
-- RPC: 新規バッジを既読にする
-- =====================================================
CREATE OR REPLACE FUNCTION mark_badges_as_seen(
  p_user_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE user_badges
  SET is_new = FALSE
  WHERE user_id = p_user_id AND is_new = TRUE;
END;
$$;

COMMENT ON FUNCTION mark_badges_as_seen IS '新規バッジを既読状態に更新';

-- =====================================================
-- RLS Policies
-- =====================================================

-- badge_definitions (全ユーザー閲覧可能)
ALTER TABLE badge_definitions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view badge definitions"
  ON badge_definitions FOR SELECT
  USING (true);

-- user_badges (自分のバッジのみ閲覧可能)
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own badges"
  ON user_badges FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "System can insert user badges"
  ON user_badges FOR INSERT
  WITH CHECK (true); -- RPC関数から挿入可能

CREATE POLICY "Users can update their badge status"
  ON user_badges FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
