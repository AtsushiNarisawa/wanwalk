-- =====================================================
-- WanWalk: 芦ノ湖畔ロングウォークを今月の人気1位にする
-- =====================================================
-- 実行日: 2025-12-10
-- 目的: 芦ノ湖畔ロングウォークに30回の散歩データを追加して1位にする
-- 対象ルート: 芦ノ湖畔ロングウォーク (route_id: 6ae42d51-4221-4075-a2c7-cb8572e17cf7)

-- =====================================================
-- 芦ノ湖畔ロングウォークに30回の散歩データを追加
-- =====================================================
DO $$
DECLARE
  v_route_id UUID := '6ae42d51-4221-4075-a2c7-cb8572e17cf7'; -- 芦ノ湖畔ロングウォーク
  v_user_id UUID;
  v_dog_id UUID;
  v_duration INT;
  i INT;
  v_hour INT;
  v_month INT;
  v_days_ago INT;
BEGIN
  -- ユーザーと犬のIDを取得
  SELECT id INTO v_user_id FROM auth.users LIMIT 1;
  SELECT id INTO v_dog_id FROM dogs WHERE user_id = v_user_id LIMIT 1;
  
  -- ルートの所要時間を取得
  SELECT estimated_minutes INTO v_duration FROM official_routes WHERE id = v_route_id;
  
  IF v_user_id IS NOT NULL AND v_dog_id IS NOT NULL AND v_duration IS NOT NULL THEN
    -- 30回の散歩データを追加（過去1ヶ月間に分散）
    FOR i IN 1..30 LOOP
      -- 過去30日間に分散させる
      v_days_ago := (i - 1);
      v_hour := (i % 12) + 8; -- 8時～19時の間で分散
      v_month := EXTRACT(MONTH FROM NOW() - (INTERVAL '1 day' * v_days_ago));
      
      INSERT INTO route_walks (
        route_id, 
        user_id, 
        dog_id, 
        walked_at, 
        duration_minutes,
        time_slot,
        season,
        created_at
      ) VALUES (
        v_route_id,
        v_user_id,
        v_dog_id,
        NOW() - (INTERVAL '1 day' * v_days_ago) + (INTERVAL '1 hour' * v_hour),
        v_duration,
        CASE 
          WHEN v_hour BETWEEN 6 AND 11 THEN 'morning'
          WHEN v_hour BETWEEN 12 AND 16 THEN 'midday'
          WHEN v_hour BETWEEN 17 AND 20 THEN 'evening'
          ELSE 'night'
        END,
        CASE 
          WHEN v_month IN (3, 4, 5) THEN 'spring'
          WHEN v_month IN (6, 7, 8) THEN 'summer'
          WHEN v_month IN (9, 10, 11) THEN 'autumn'
          ELSE 'winter'
        END,
        NOW() - (INTERVAL '1 day' * v_days_ago) + (INTERVAL '1 hour' * v_hour)
      );
    END LOOP;
    
    RAISE NOTICE '芦ノ湖畔ロングウォークに30回の散歩データを追加しました';
  ELSE
    RAISE NOTICE '警告: ユーザー、犬、またはルートが見つかりません';
    RAISE NOTICE 'user_id: %, dog_id: %, duration: %', v_user_id, v_dog_id, v_duration;
  END IF;
END $$;

-- =====================================================
-- 確認クエリ: 今月の人気ルートランキング
-- =====================================================
SELECT 
  route_name,
  area_name,
  monthly_walks,
  distance_meters / 1000.0 AS distance_km,
  estimated_minutes,
  created_at
FROM get_monthly_popular_official_routes(10, 0)
ORDER BY monthly_walks DESC;

-- =====================================================
-- 詳細確認: 芦ノ湖畔ロングウォークの散歩回数
-- =====================================================
SELECT 
  r.name AS route_name,
  COUNT(rw.id) AS total_walks,
  COUNT(CASE WHEN rw.walked_at >= NOW() - INTERVAL '1 month' THEN 1 END) AS monthly_walks,
  MIN(rw.walked_at) AS first_walk,
  MAX(rw.walked_at) AS last_walk
FROM official_routes r
LEFT JOIN route_walks rw ON rw.route_id = r.id
WHERE r.id = '6ae42d51-4221-4075-a2c7-cb8572e17cf7'
GROUP BY r.name;

-- 完了メッセージ
SELECT '✅ 芦ノ湖畔ロングウォークを今月の人気1位にしました（30回の散歩データ追加）' AS status;
