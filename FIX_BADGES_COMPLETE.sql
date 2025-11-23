-- ============================================================
-- バッジシステム完全修正SQL
-- ============================================================
-- 問題: badge_definitionsテーブルが存在しないか、古い構造
-- 解決策: テーブルを完全に再作成
-- ============================================================

BEGIN;

-- ステップ1: 既存のテーブルとビューを削除（存在する場合）
DROP VIEW IF EXISTS badges CASCADE;
DROP TABLE IF EXISTS user_badges CASCADE;
DROP TABLE IF EXISTS badge_definitions CASCADE;

-- ステップ2: badge_definitionsテーブルを作成
CREATE TABLE badge_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  badge_code TEXT UNIQUE NOT NULL,
  name_ja TEXT NOT NULL,
  name_en TEXT NOT NULL,
  description TEXT NOT NULL,
  icon_name TEXT NOT NULL,
  category TEXT CHECK (category IN ('distance', 'area', 'pins', 'social', 'special')) NOT NULL,
  tier TEXT CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum')) NOT NULL,
  requirement_type TEXT NOT NULL,
  requirement_value INT NOT NULL,
  display_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX badge_definitions_category_idx ON badge_definitions (category);
CREATE INDEX badge_definitions_display_order_idx ON badge_definitions (display_order);

COMMENT ON TABLE badge_definitions IS 'バッジ定義マスタ';

-- ステップ3: user_badgesテーブルを作成
CREATE TABLE user_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL,
  badge_id UUID REFERENCES badge_definitions NOT NULL,
  unlocked_at TIMESTAMPTZ DEFAULT NOW(),
  is_new BOOLEAN DEFAULT TRUE,
  UNIQUE (user_id, badge_id)
);

CREATE INDEX user_badges_user_idx ON user_badges (user_id);
CREATE INDEX user_badges_unlocked_at_idx ON user_badges (unlocked_at DESC);

COMMENT ON TABLE user_badges IS 'ユーザーが獲得したバッジ';

-- ステップ4: RLSポリシー設定
ALTER TABLE badge_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view badge definitions"
  ON badge_definitions FOR SELECT
  USING (true);

CREATE POLICY "Users can view their own badges"
  ON user_badges FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "System can insert user badges"
  ON user_badges FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can update their badge status"
  ON user_badges FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ステップ5: badgesビューを作成
CREATE VIEW badges AS
SELECT 
    id as badge_id,
    badge_code,
    name_ja,
    name_en,
    description,
    icon_name,
    category,
    tier,
    requirement_type,
    requirement_value,
    display_order,
    is_active,
    created_at
FROM badge_definitions
WHERE is_active = TRUE;

COMMENT ON VIEW badges IS 'badge_definitions のビュー（Flutterアプリとの互換性のため）';

-- ステップ6: 17個のバッジデータを投入

-- 距離系バッジ (4個)
INSERT INTO badge_definitions (badge_code, name_ja, name_en, description, icon_name, category, tier, requirement_type, requirement_value, display_order) VALUES
('distance_10km', '初心者ウォーカー', 'Beginner Walker', '総距離10km達成！散歩の第一歩です', 'directions_walk', 'distance', 'bronze', 'total_distance_km', 10, 1),
('distance_50km', '散歩マスター', 'Walk Master', '総距離50km達成！素晴らしい実績です', 'emoji_events', 'distance', 'silver', 'total_distance_km', 50, 2),
('distance_100km', '百キロの道', 'Century Walker', '総距離100km達成！驚異的な記録です', 'workspace_premium', 'distance', 'gold', 'total_distance_km', 100, 3),
('distance_500km', '超長距離ウォーカー', 'Ultra Walker', '総距離500km達成！伝説の域に到達しました', 'military_tech', 'distance', 'platinum', 'total_distance_km', 500, 4);

-- エリア探索系バッジ (3個)
INSERT INTO badge_definitions (badge_code, name_ja, name_en, description, icon_name, category, tier, requirement_type, requirement_value, display_order) VALUES
('area_3', 'エリアエクスプローラー', 'Area Explorer', '3つのエリアを訪問しました', 'explore', 'area', 'bronze', 'areas_visited', 3, 11),
('area_5', 'エリアマスター', 'Area Master', '5つのエリアを訪問しました', 'public', 'area', 'silver', 'areas_visited', 5, 12),
('area_10', 'エリアコンプリート', 'Area Complete', '10のエリアを訪問しました', 'travel_explore', 'area', 'gold', 'areas_visited', 10, 13);

-- ピン投稿系バッジ (4個)
INSERT INTO badge_definitions (badge_code, name_ja, name_en, description, icon_name, category, tier, requirement_type, requirement_value, display_order) VALUES
('pins_5', 'ピン投稿ビギナー', 'Pin Beginner', '5つのピンを投稿しました', 'push_pin', 'pins', 'bronze', 'pins_created', 5, 21),
('pins_20', 'ピン投稿マスター', 'Pin Master', '20のピンを投稿しました', 'location_on', 'pins', 'silver', 'pins_created', 20, 22),
('pins_50', 'ピン投稿エキスパート', 'Pin Expert', '50のピンを投稿しました', 'add_location', 'pins', 'gold', 'pins_created', 50, 23),
('pins_100', 'ピン投稿レジェンド', 'Pin Legend', '100のピンを投稿しました', 'place', 'pins', 'platinum', 'pins_created', 100, 24);

-- ソーシャル系バッジ (3個)
INSERT INTO badge_definitions (badge_code, name_ja, name_en, description, icon_name, category, tier, requirement_type, requirement_value, display_order) VALUES
('followers_10', '人気ユーザー', 'Popular User', '10人のフォロワーを獲得しました', 'people', 'social', 'bronze', 'followers_count', 10, 31),
('followers_50', 'インフルエンサー', 'Influencer', '50人のフォロワーを獲得しました', 'groups', 'social', 'silver', 'followers_count', 50, 32),
('followers_100', 'コミュニティリーダー', 'Community Leader', '100人のフォロワーを獲得しました', 'supervisor_account', 'social', 'gold', 'followers_count', 100, 33);

-- 特別バッジ (3個)
INSERT INTO badge_definitions (badge_code, name_ja, name_en, description, icon_name, category, tier, requirement_type, requirement_value, display_order) VALUES
('first_walk', '初めての散歩', 'First Walk', '初めてのお出かけ散歩を完了しました', 'celebration', 'special', 'bronze', 'total_walks', 1, 41),
('first_pin', '初めてのピン', 'First Pin', '初めてのピンを投稿しました', 'new_releases', 'special', 'bronze', 'pins_created', 1, 42),
('early_adopter', 'アーリーアダプター', 'Early Adopter', 'WanMapの初期メンバーです', 'star', 'special', 'platinum', 'special', 0, 43);

-- ステップ7: 確認クエリ
SELECT 'badge_definitions count:' as info, COUNT(*) as count FROM badge_definitions;
SELECT 'badges view count:' as info, COUNT(*) as count FROM badges;
SELECT 'Badge categories:' as info, category, COUNT(*) as count FROM badge_definitions GROUP BY category ORDER BY category;

COMMIT;

-- 成功メッセージ
DO $$
BEGIN
    RAISE NOTICE 'バッジシステムが正常に作成されました！';
    RAISE NOTICE '- badge_definitions テーブル: 17件';
    RAISE NOTICE '- badges ビュー: 作成完了';
    RAISE NOTICE '- user_badges テーブル: 作成完了';
    RAISE NOTICE '- RLSポリシー: 設定完了';
END $$;
