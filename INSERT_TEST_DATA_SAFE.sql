-- ============================================================
-- WanMap v2 テストデータ投入（安全版）
-- ============================================================
-- このSQLを実行する前に、VERIFY_DATABASE_STRUCTURE.sql を実行して
-- 現在のデータベース状態を確認してください
-- ============================================================
-- 実行方法:
-- 1. Supabase管理画面 → SQL Editor を開く
-- 2. このSQLをコピー&ペースト
-- 3. 「Run」ボタンをクリック
-- ============================================================

-- ■■■ ステップ1: 既存データの確認 ■■■
DO $$
DECLARE
    area_count INTEGER;
    route_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO area_count FROM areas;
    SELECT COUNT(*) INTO route_count FROM official_routes;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE '現在のデータ状況:';
    RAISE NOTICE '  - areas: % 件', area_count;
    RAISE NOTICE '  - official_routes: % 件', route_count;
    RAISE NOTICE '========================================';
END $$;

-- ■■■ ステップ2: エリアデータの投入 ■■■
-- 箱根エリア（DogHub所在地）
INSERT INTO areas (id, name, description, center_latitude, center_longitude, created_at)
VALUES (
  '00000000-0000-0000-0000-000000000001'::UUID,
  '箱根',
  '神奈川県足柄下郡箱根町。温泉と自然に恵まれた観光地。DogHubの拠点エリア。',
  35.2328,
  139.1071,
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  center_latitude = EXCLUDED.center_latitude,
  center_longitude = EXCLUDED.center_longitude;

-- 横浜エリア（将来の拡張用）
INSERT INTO areas (id, name, description, center_latitude, center_longitude, created_at)
VALUES (
  '00000000-0000-0000-0000-000000000002'::UUID,
  '横浜',
  '神奈川県横浜市。港町の雰囲気と都市の利便性を兼ね備えた人気エリア。',
  35.4437,
  139.6380,
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  center_latitude = EXCLUDED.center_latitude,
  center_longitude = EXCLUDED.center_longitude;

-- 鎌倉エリア（将来の拡張用）
INSERT INTO areas (id, name, description, center_latitude, center_longitude, created_at)
VALUES (
  '00000000-0000-0000-0000-000000000003'::UUID,
  '鎌倉',
  '神奈川県鎌倉市。歴史的な寺社仏閣と海辺の散歩道が魅力。',
  35.3193,
  139.5465,
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  center_latitude = EXCLUDED.center_latitude,
  center_longitude = EXCLUDED.center_longitude;

-- ■■■ ステップ3: 公式ルートの投入 ■■■
-- ルート1: DogHub周遊コース（初心者向け）
INSERT INTO official_routes (
  id,
  area_id,
  name,
  description,
  start_location,
  end_location,
  route_line,
  distance_meters,
  estimated_minutes,
  difficulty_level,
  created_at
)
VALUES (
  '10000000-0000-0000-0000-000000000001'::UUID,
  '00000000-0000-0000-0000-000000000001'::UUID, -- 箱根エリア
  'DogHub周遊コース',
  'DogHubを起点とした短距離の散歩コース。初めての方や小型犬におすすめ。途中、箱根の自然を感じられる緑道を通ります。',
  ST_SetSRID(ST_MakePoint(139.1071, 35.2328), 4326)::geography,
  ST_SetSRID(ST_MakePoint(139.1071, 35.2328), 4326)::geography,
  NULL,
  1200.0, -- 約1.2km
  20, -- 約20分
  'easy',
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  distance_meters = EXCLUDED.distance_meters,
  estimated_minutes = EXCLUDED.estimated_minutes;

-- ルート2: 箱根旧街道コース（中級者向け）
INSERT INTO official_routes (
  id,
  area_id,
  name,
  description,
  start_location,
  end_location,
  route_line,
  distance_meters,
  estimated_minutes,
  difficulty_level,
  created_at
)
VALUES (
  '10000000-0000-0000-0000-000000000002'::UUID,
  '00000000-0000-0000-0000-000000000001'::UUID, -- 箱根エリア
  '箱根旧街道散歩道',
  '歴史ある箱根旧街道の一部を歩くコース。石畳の道と杉並木が美しい。坂道あり。',
  ST_SetSRID(ST_MakePoint(139.1071, 35.2328), 4326)::geography,
  ST_SetSRID(ST_MakePoint(139.1100, 35.2380), 4326)::geography,
  NULL,
  3500.0, -- 約3.5km
  60, -- 約60分
  'moderate',
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  distance_meters = EXCLUDED.distance_meters,
  estimated_minutes = EXCLUDED.estimated_minutes;

-- ルート3: 芦ノ湖畔コース（上級者向け）
INSERT INTO official_routes (
  id,
  area_id,
  name,
  description,
  start_location,
  end_location,
  route_line,
  distance_meters,
  estimated_minutes,
  difficulty_level,
  created_at
)
VALUES (
  '10000000-0000-0000-0000-000000000003'::UUID,
  '00000000-0000-0000-0000-000000000001'::UUID, -- 箱根エリア
  '芦ノ湖畔ロングウォーク',
  '芦ノ湖の美しい景色を楽しみながら歩く長距離コース。体力のある犬と飼い主向け。',
  ST_SetSRID(ST_MakePoint(139.0264, 35.2044), 4326)::geography,
  ST_SetSRID(ST_MakePoint(139.0350, 35.2100), 4326)::geography,
  NULL,
  6800.0, -- 約6.8km
  120, -- 約120分
  'hard',
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  distance_meters = EXCLUDED.distance_meters,
  estimated_minutes = EXCLUDED.estimated_minutes;

-- ■■■ ステップ4: 経路ポイントの投入 ■■■
-- DogHub周遊コースの経路ポイント
INSERT INTO official_route_points (route_id, sequence_number, location, point_name)
VALUES
  (
    '10000000-0000-0000-0000-000000000001'::UUID,
    1,
    ST_SetSRID(ST_MakePoint(139.1071, 35.2328), 4326)::geography,
    'DogHub スタート'
  ),
  (
    '10000000-0000-0000-0000-000000000001'::UUID,
    2,
    ST_SetSRID(ST_MakePoint(139.1080, 35.2335), 4326)::geography,
    '緑道入口'
  ),
  (
    '10000000-0000-0000-0000-000000000001'::UUID,
    3,
    ST_SetSRID(ST_MakePoint(139.1075, 35.2340), 4326)::geography,
    '見晴らしポイント'
  ),
  (
    '10000000-0000-0000-0000-000000000001'::UUID,
    4,
    ST_SetSRID(ST_MakePoint(139.1071, 35.2328), 4326)::geography,
    'DogHub ゴール'
  )
ON CONFLICT (route_id, sequence_number) DO UPDATE SET
  point_name = EXCLUDED.point_name,
  location = EXCLUDED.location;

-- ■■■ ステップ5: 結果確認 ■■■
DO $$
DECLARE
    area_count INTEGER;
    route_count INTEGER;
    point_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO area_count FROM areas;
    SELECT COUNT(*) INTO route_count FROM official_routes;
    SELECT COUNT(*) INTO point_count FROM official_route_points;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ データ投入完了！';
    RAISE NOTICE '========================================';
    RAISE NOTICE '投入後のデータ状況:';
    RAISE NOTICE '  - areas: % 件', area_count;
    RAISE NOTICE '  - official_routes: % 件', route_count;
    RAISE NOTICE '  - official_route_points: % 件', point_count;
    RAISE NOTICE '========================================';
    RAISE NOTICE '次のステップ:';
    RAISE NOTICE '1. アプリを起動';
    RAISE NOTICE '2. ホーム画面で「エリアを探す」をタップ';
    RAISE NOTICE '3. 「箱根」エリアが表示されることを確認';
    RAISE NOTICE '4. 「DogHub周遊コース」を選択して散歩開始';
    RAISE NOTICE '========================================';
END $$;
