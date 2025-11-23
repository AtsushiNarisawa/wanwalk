-- ============================================================
-- バッジテーブル エイリアス/ビュー作成
-- ============================================================
-- 問題: badge_definitions テーブルが存在するが、Flutterコードは badges を期待
-- 解決策: badges ビューを作成して badge_definitions にマッピング
-- ============================================================

BEGIN;

-- ステップ1: badges ビューを作成
-- FlutterアプリのRestAPIリクエストで badges テーブルにアクセスできるようにする
DROP VIEW IF EXISTS badges CASCADE;

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

-- ステップ2: ビューに対してRLSポリシーを設定することはできないので
-- 代わりに badge_definitions のポリシーを使用

-- ステップ3: 既存の get_user_badges 関数を修正して badge_id を正しく返す
-- 関数内で bd.id を badge_id として返しているので、問題なし

-- ステップ4: 検証用にバッジ数をカウント
SELECT 'badge_definitions count:' as info, COUNT(*) as count FROM badge_definitions;
SELECT 'badges view count:' as info, COUNT(*) as count FROM badges;

COMMIT;

-- ============================================================
-- 追加: バッジデータが存在しない場合の対策
-- ============================================================

-- バッジデータが0件の場合、初期データを再投入
DO $$
DECLARE
    badge_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO badge_count FROM badge_definitions;
    
    IF badge_count = 0 THEN
        RAISE NOTICE 'バッジデータが存在しないため、初期データを投入します';
        
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
        
        RAISE NOTICE '17個のバッジデータを投入しました';
    ELSE
        RAISE NOTICE 'バッジデータは既に % 件存在します', badge_count;
    END IF;
END $$;

-- 最終確認
SELECT 'Final badge count:' as info, COUNT(*) as count FROM badges;
