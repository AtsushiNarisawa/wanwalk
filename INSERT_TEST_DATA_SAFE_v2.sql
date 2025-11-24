-- ============================================================
-- WanMap v2 テストデータ投入（正しいスキーマ版）
-- ============================================================
-- このSQLを実行する前に、VERIFY_DATABASE_STRUCTURE_v2.sql を実行して
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
INSERT INTO areas (
  id, 
  area_code, 
  display_name, 
  category, 
  prefecture, 
  description, 
  center_location,
  is_active,
  display_order,
  created_at
)
VALUES (
  '00000000-0000-0000-0000-000000000001'::UUID,
  'hakone',
  '箱根',
  'tourist',
  '神奈川県',
  '神奈川県足柄下郡箱根町。温泉と自然に恵まれた観光地。DogHubの拠点エリア。',
  ST_SetSRID(ST_MakePoint(139.1071, 35.2328), 4326)::geography,
  TRUE,
  1,
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  description = EXCLUDED.description,
  center_location = EXCLUDED.center_location;

-- 横浜エリア（将来の拡張用）
INSERT INTO areas (
  id, 
  area_code, 
  display_name, 
  category, 
  prefecture, 
  description, 
  center_location,
  is_active,
  display_order,
  created_at
)
VALUES (
  '00000000-0000-0000-0000-000000000002'::UUID,
  'yokohama',
  '横浜',
  'urban',
  '神奈川県',
  '神奈川県横浜市。港町の雰囲気と都市の利便性を兼ね備えた人気エリア。',
  ST_SetSRID(ST_MakePoint(139.6380, 35.4437), 4326)::geography,
  TRUE,
  2,
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  description = EXCLUDED.description,
  center_location = EXCLUDED.center_location;

-- 鎌倉エリア（将来の拡張用）
INSERT INTO areas (
  id, 
  area_code, 
  display_name, 
  category, 
  prefecture, 
  description, 
  center_location,
  is_active,
  display_order,
  created_at
)
VALUES (
  '00000000-0000-0000-0000-000000000003'::UUID,
  'kamakura',
  '鎌倉',
  'tourist',
  '神奈川県',
  '神奈川県鎌倉市。歴史的な寺社仏閣と海辺の散歩道が魅力。',
  ST_SetSRID(ST_MakePoint(139.5465, 35.3193), 4326)::geography,
  TRUE,
  3,
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  description = EXCLUDED.description,
  center_location = EXCLUDED.center_location;

-- ■■■ ステップ3: 公式ルートの投入 ■■■
-- ルート1: DogHub周遊コース（初心者向け）
INSERT INTO official_routes (
  id,
  area_id,
  title,
  description,
  difficulty,
  distance_km,
  estimated_duration_minutes,
  elevation_gain_m,
  features,
  best_seasons,
  best_time_slots,
  start_location,
  end_location,
  route_line,
  is_official,
  is_active,
  created_at
)
VALUES (
  '10000000-0000-0000-0000-000000000001'::UUID,
  '00000000-0000-0000-0000-000000000001'::UUID, -- 箱根エリア
  'DogHub周遊コース',
  'DogHubを起点とした短距離の散歩コース。初めての方や小型犬におすすめ。途中、箱根の自然を感じられる緑道を通ります。',
  'easy',
  1.2, -- 1.2km
  20, -- 20分
  50, -- 標高差50m
  ARRAY['shaded', 'scenic_view'],
  ARRAY['spring', 'autumn'],
  ARRAY['morning', 'evening'],
  ST_SetSRID(ST_MakePoint(139.1071, 35.2328), 4326)::geography,
  ST_SetSRID(ST_MakePoint(139.1071, 35.2328), 4326)::geography,
  NULL,
  TRUE,
  TRUE,
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  distance_km = EXCLUDED.distance_km,
  estimated_duration_minutes = EXCLUDED.estimated_duration_minutes;

-- ルート2: 箱根旧街道コース（中級者向け）
INSERT INTO official_routes (
  id,
  area_id,
  title,
  description,
  difficulty,
  distance_km,
  estimated_duration_minutes,
  elevation_gain_m,
  features,
  best_seasons,
  best_time_slots,
  start_location,
  end_location,
  route_line,
  is_official,
  is_active,
  created_at
)
VALUES (
  '10000000-0000-0000-0000-000000000002'::UUID,
  '00000000-0000-0000-0000-000000000001'::UUID, -- 箱根エリア
  '箱根旧街道散歩道',
  '歴史ある箱根旧街道の一部を歩くコース。石畳の道と杉並木が美しい。坂道あり。',
  'moderate',
  3.5, -- 3.5km
  60, -- 60分
  150, -- 標高差150m
  ARRAY['scenic_view', 'historical'],
  ARRAY['spring', 'summer', 'autumn'],
  ARRAY['morning', 'midday'],
  ST_SetSRID(ST_MakePoint(139.1071, 35.2328), 4326)::geography,
  ST_SetSRID(ST_MakePoint(139.1100, 35.2380), 4326)::geography,
  NULL,
  TRUE,
  TRUE,
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  distance_km = EXCLUDED.distance_km,
  estimated_duration_minutes = EXCLUDED.estimated_duration_minutes;

-- ルート3: 芦ノ湖畔コース（上級者向け）
INSERT INTO official_routes (
  id,
  area_id,
  title,
  description,
  difficulty,
  distance_km,
  estimated_duration_minutes,
  elevation_gain_m,
  features,
  best_seasons,
  best_time_slots,
  start_location,
  end_location,
  route_line,
  is_official,
  is_active,
  created_at
)
VALUES (
  '10000000-0000-0000-0000-000000000003'::UUID,
  '00000000-0000-0000-0000-000000000001'::UUID, -- 箱根エリア
  '芦ノ湖畔ロングウォーク',
  '芦ノ湖の美しい景色を楽しみながら歩く長距離コース。体力のある犬と飼い主向け。',
  'hard',
  6.8, -- 6.8km
  120, -- 120分
  200, -- 標高差200m
  ARRAY['scenic_view', 'lakeside'],
  ARRAY['spring', 'summer', 'autumn'],
  ARRAY['morning'],
  ST_SetSRID(ST_MakePoint(139.0264, 35.2044), 4326)::geography,
  ST_SetSRID(ST_MakePoint(139.0350, 35.2100), 4326)::geography,
  NULL,
  TRUE,
  TRUE,
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  distance_km = EXCLUDED.distance_km,
  estimated_duration_minutes = EXCLUDED.estimated_duration_minutes;

-- ■■■ ステップ4: 経路ポイントの投入 ■■■
-- DogHub周遊コースの経路ポイント
INSERT INTO official_route_points (id, route_id, point_order, location)
VALUES
  (
    uuid_generate_v4(),
    '10000000-0000-0000-0000-000000000001'::UUID,
    1,
    ST_SetSRID(ST_MakePoint(139.1071, 35.2328), 4326)::geography
  ),
  (
    uuid_generate_v4(),
    '10000000-0000-0000-0000-000000000001'::UUID,
    2,
    ST_SetSRID(ST_MakePoint(139.1080, 35.2335), 4326)::geography
  ),
  (
    uuid_generate_v4(),
    '10000000-0000-0000-0000-000000000001'::UUID,
    3,
    ST_SetSRID(ST_MakePoint(139.1075, 35.2340), 4326)::geography
  ),
  (
    uuid_generate_v4(),
    '10000000-0000-0000-0000-000000000001'::UUID,
    4,
    ST_SetSRID(ST_MakePoint(139.1071, 35.2328), 4326)::geography
  )
ON CONFLICT (route_id, point_order) DO UPDATE SET
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
