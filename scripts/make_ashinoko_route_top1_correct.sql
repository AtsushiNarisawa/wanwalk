-- =====================================================
-- WanWalk: 芦ノ湖畔ロングウォークを今月の人気1位にする（正しいテーブル構造版）
-- =====================================================
-- 実行日: 2025-12-10
-- 目的: 芦ノ湖畔ロングウォークに30回の散歩データを追加して1位にする
-- 対象ルート: 芦ノ湖畔ロングウォーク (route_id: 6ae42d51-4221-4075-a2c7-cb8572e17cf7)
-- 使用テーブル: walks (walk_type='outing')

-- =====================================================
-- 前提確認: ルートとユーザーの存在チェック
-- =====================================================
DO $$
DECLARE
  v_route_id UUID := '6ae42d51-4221-4075-a2c7-cb8572e17cf7';
  v_route_name TEXT;
  v_user_id UUID;
  v_area_id UUID;
BEGIN
  -- ルートの存在確認
  SELECT title, area_id INTO v_route_name, v_area_id 
  FROM official_routes 
  WHERE id = v_route_id;
  
  IF v_route_name IS NULL THEN
    RAISE EXCEPTION 'ルートID % が見つかりません', v_route_id;
  END IF;
  
  -- ユーザーの存在確認
  SELECT id INTO v_user_id FROM auth.users ORDER BY created_at LIMIT 1;
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'ユーザーが見つかりません。先にユーザーを作成してください。';
  END IF;
  
  RAISE NOTICE '✅ ルート確認: % (area_id: %)', v_route_name, v_area_id;
  RAISE NOTICE '✅ ユーザー確認: %', v_user_id;
END $$;

-- =====================================================
-- 芦ノ湖畔ロングウォークに30回の散歩データを追加
-- =====================================================
DO $$
DECLARE
  v_route_id UUID := '6ae42d51-4221-4075-a2c7-cb8572e17cf7';
  v_user_id UUID;
  v_area_id UUID;
  v_distance_meters NUMERIC;
  v_estimated_minutes INT;
  v_duration_seconds INT;
  i INT;
  v_days_ago INT;
  v_start_time TIMESTAMPTZ;
  v_end_time TIMESTAMPTZ;
BEGIN
  -- ユーザーIDを取得
  SELECT id INTO v_user_id FROM auth.users ORDER BY created_at LIMIT 1;
  
  -- ルート情報を取得
  SELECT area_id, distance_meters, estimated_minutes 
  INTO v_area_id, v_distance_meters, v_estimated_minutes
  FROM official_routes 
  WHERE id = v_route_id;
  
  -- 所要時間（秒）を計算
  v_duration_seconds := v_estimated_minutes * 60;
  
  IF v_user_id IS NOT NULL AND v_area_id IS NOT NULL THEN
    -- 30回の散歩データを追加（過去30日間に分散）
    FOR i IN 1..30 LOOP
      v_days_ago := (i - 1);
      v_start_time := NOW() - (INTERVAL '1 day' * v_days_ago) + (INTERVAL '1 hour' * ((i % 12) + 8));
      v_end_time := v_start_time + (INTERVAL '1 second' * v_duration_seconds);
      
      INSERT INTO walks (
        user_id,
        walk_type,
        route_id,
        start_time,
        end_time,
        distance_meters,
        duration_seconds,
        path_geojson
      ) VALUES (
        v_user_id,
        'outing',
        v_route_id,
        v_start_time,
        v_end_time,
        v_distance_meters + (RANDOM() * 100)::INT - 50, -- 少しランダム化
        v_duration_seconds + (RANDOM() * 600)::INT - 300, -- ±5分のランダム化
        '{"type":"LineString","coordinates":[[139.0315,35.2034],[139.0325,35.2044]]}'
      );
    END LOOP;
    
    RAISE NOTICE '✅ 芦ノ湖畔ロングウォークに30回の散歩データを追加しました';
  ELSE
    RAISE EXCEPTION 'ユーザーまたはルートが見つかりません (user_id: %, area_id: %)', v_user_id, v_area_id;
  END IF;
END $$;

-- =====================================================
-- 確認クエリ1: 今月の人気ルートランキング（walksテーブル使用）
-- =====================================================
SELECT 
  r.title AS route_name,
  a.name AS area_name,
  COUNT(w.id) FILTER (WHERE w.start_time >= NOW() - INTERVAL '1 month') AS monthly_walks,
  r.distance_meters / 1000.0 AS distance_km,
  r.estimated_minutes,
  r.created_at
FROM official_routes r
JOIN areas a ON a.id = r.area_id
LEFT JOIN walks w ON w.route_id = r.id AND w.walk_type = 'outing'
GROUP BY r.id, r.title, a.name, r.distance_meters, r.estimated_minutes, r.created_at
ORDER BY monthly_walks DESC, r.created_at DESC
LIMIT 10;

-- =====================================================
-- 確認クエリ2: 芦ノ湖畔ロングウォークの詳細統計
-- =====================================================
SELECT 
  r.title AS route_name,
  COUNT(w.id) AS total_walks,
  COUNT(w.id) FILTER (WHERE w.start_time >= NOW() - INTERVAL '1 month') AS monthly_walks,
  COUNT(w.id) FILTER (WHERE w.start_time >= NOW() - INTERVAL '7 days') AS weekly_walks,
  MIN(w.start_time) AS first_walk,
  MAX(w.start_time) AS last_walk
FROM official_routes r
LEFT JOIN walks w ON w.route_id = r.id AND w.walk_type = 'outing'
WHERE r.id = '6ae42d51-4221-4075-a2c7-cb8572e17cf7'
GROUP BY r.title;

-- =====================================================
-- 確認クエリ3: 最近の散歩記録（上位5件）
-- =====================================================
SELECT 
  w.id,
  w.start_time,
  w.distance_meters / 1000.0 AS distance_km,
  w.duration_seconds / 60 AS duration_minutes,
  r.title AS route_name
FROM walks w
JOIN official_routes r ON w.route_id = r.id
WHERE w.route_id = '6ae42d51-4221-4075-a2c7-cb8572e17cf7'
  AND w.walk_type = 'outing'
ORDER BY w.start_time DESC
LIMIT 5;

-- 完了メッセージ
SELECT '✅ 芦ノ湖畔ロングウォークを今月の人気1位にしました（30回の散歩データ追加 - walksテーブル使用）' AS status;
