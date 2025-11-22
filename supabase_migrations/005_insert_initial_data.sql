-- WanMap リニューアル Phase 1a: 初期データ投入
-- DogHub箱根エリアとテストルートの作成

-- ============================================================
-- 1. エリアマスタの初期データ
-- ============================================================

-- 箱根エリア（DogHub所在地）
INSERT INTO areas (id, name, description, center_latitude, center_longitude, created_at)
VALUES (
  '00000000-0000-0000-0000-000000000001'::UUID,
  '箱根',
  '神奈川県足柄下郡箱根町。温泉と自然に恵まれた観光地。DogHubの拠点エリア。',
  35.2328,
  139.1071,
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- 横浜エリア（将来の拡張用）
INSERT INTO areas (id, name, description, center_latitude, center_longitude, created_at)
VALUES (
  '00000000-0000-0000-0000-000000000002'::UUID,
  '横浜',
  '神奈川県横浜市。港町の雰囲気と都市の利便性を兼ね備えた人気エリア。',
  35.4437,
  139.6380,
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- 鎌倉エリア（将来の拡張用）
INSERT INTO areas (id, name, description, center_latitude, center_longitude, created_at)
VALUES (
  '00000000-0000-0000-0000-000000000003'::UUID,
  '鎌倉',
  '神奈川県鎌倉市。歴史的な寺社仏閣と海辺の散歩道が魅力。',
  35.3193,
  139.5465,
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 2. DogHub周辺の公式ルート
-- ============================================================

-- ルート1: DogHub周辺の軽めコース（初心者向け）
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
  ST_SetSRID(ST_MakePoint(139.1071, 35.2328), 4326)::geography, -- DogHub付近
  ST_SetSRID(ST_MakePoint(139.1071, 35.2328), 4326)::geography, -- 同じ地点に戻る
  NULL, -- route_lineは後で追加可能
  1200.0, -- 約1.2km
  20, -- 約20分
  'easy',
  NOW()
) ON CONFLICT (id) DO NOTHING;

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
) ON CONFLICT (id) DO NOTHING;

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
  ST_SetSRID(ST_MakePoint(139.0264, 35.2044), 4326)::geography, -- 芦ノ湖付近
  ST_SetSRID(ST_MakePoint(139.0350, 35.2100), 4326)::geography,
  NULL,
  6800.0, -- 約6.8km
  120, -- 約120分
  'hard',
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 3. 公式ルートの経路ポイント（サンプル）
-- ============================================================

-- DogHub周遊コースの経路ポイント（簡略版）
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
ON CONFLICT (route_id, sequence_number) DO NOTHING;

-- ============================================================
-- 4. テスト用のピン（開発・デモ用）
-- ============================================================

-- 注意: 実際のuser_idは認証後に取得する必要があるため、
-- このスクリプトでは投入しません。
-- アプリ側でテストユーザーを作成後、手動で投入するか、
-- Supabase SQLエディタから以下のようなクエリを実行します：

/*
-- テストピンの投入例（実際のuser_idに置き換えてください）
INSERT INTO route_pins (
  route_id,
  user_id,
  location,
  pin_type,
  title,
  comment
)
VALUES (
  '10000000-0000-0000-0000-000000000001'::UUID,
  'your-test-user-uuid'::UUID, -- 実際のユーザーUUIDに置き換え
  ST_SetSRID(ST_MakePoint(139.1080, 35.2335), 4326)::geography,
  'scenery',
  '美しい紅葉スポット',
  '秋は特に綺麗です！愛犬も喜んでいました。'
);
*/

-- ============================================================
-- 初期データ投入完了
-- ============================================================
-- 投入されたデータ：
-- 1. エリアマスタ: 箱根、横浜、鎌倉
-- 2. 公式ルート: DogHub周遊コース、箱根旧街道散歩道、芦ノ湖畔ロングウォーク
-- 3. 経路ポイント: DogHub周遊コースの4ポイント
-- 
-- 次のステップ:
-- - Supabase管理画面でマイグレーション実行
-- - テストユーザー作成後、ピンやプロファイルのテストデータ投入
