-- =====================================================
-- WanWalk: 今月の人気ルート用ダミーデータ挿入（最終版）
-- =====================================================
-- 実行日: 2025-12-08
-- 目的: route_walksテーブルに過去1ヶ月の散歩データを挿入
-- 対応: route_walks テーブルの実際の列名に合わせて修正
--   - walked_at, duration_minutes, dog_id, time_slot, season を使用

-- ルート1: 過去1ヶ月で最も人気（20回）
DO $$
DECLARE
  v_route_id UUID;
  v_user_id UUID;
  v_dog_id UUID;
  v_duration INT;
  i INT;
  v_hour INT;
  v_month INT;
BEGIN
  -- 最も古いルートを取得（ルート1）
  SELECT id INTO v_route_id FROM official_routes ORDER BY created_at LIMIT 1;
  
  -- ユーザーと犬のIDを取得
  SELECT id INTO v_user_id FROM auth.users LIMIT 1;
  SELECT id INTO v_dog_id FROM dogs WHERE user_id = v_user_id LIMIT 1;
  
  -- ルートの所要時間を取得
  SELECT estimated_minutes INTO v_duration FROM official_routes WHERE id = v_route_id;
  
  IF v_route_id IS NOT NULL AND v_user_id IS NOT NULL AND v_dog_id IS NOT NULL THEN
    FOR i IN 1..20 LOOP
      -- 時間帯と季節を決定
      v_hour := (i % 24);
      v_month := EXTRACT(MONTH FROM NOW() - (INTERVAL '1 day' * (i - 1)));
      
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
        NOW() - (INTERVAL '1 day' * (i - 1)),
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
        NOW() - (INTERVAL '1 day' * (i - 1))
      );
    END LOOP;
    RAISE NOTICE 'ルート1に20回の散歩データを追加しました';
  ELSE
    RAISE NOTICE '警告: ルート、ユーザー、または犬が見つかりません';
  END IF;
END $$;

-- ルート2: 2番目に人気（15回）
DO $$
DECLARE
  v_route_id UUID;
  v_user_id UUID;
  v_dog_id UUID;
  v_duration INT;
  i INT;
  v_hour INT;
  v_month INT;
BEGIN
  -- 2番目に古いルートを取得（ルート2）
  SELECT id INTO v_route_id FROM official_routes ORDER BY created_at OFFSET 1 LIMIT 1;
  
  SELECT id INTO v_user_id FROM auth.users LIMIT 1;
  SELECT id INTO v_dog_id FROM dogs WHERE user_id = v_user_id LIMIT 1;
  SELECT estimated_minutes INTO v_duration FROM official_routes WHERE id = v_route_id;
  
  IF v_route_id IS NOT NULL AND v_user_id IS NOT NULL AND v_dog_id IS NOT NULL THEN
    FOR i IN 1..15 LOOP
      v_hour := (i % 24);
      v_month := EXTRACT(MONTH FROM NOW() - (INTERVAL '1 day' * (i - 1)));
      
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
        NOW() - (INTERVAL '1 day' * (i - 1)),
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
        NOW() - (INTERVAL '1 day' * (i - 1))
      );
    END LOOP;
    RAISE NOTICE 'ルート2に15回の散歩データを追加しました';
  ELSE
    RAISE NOTICE '警告: ルート、ユーザー、または犬が見つかりません';
  END IF;
END $$;

-- ルート3: 3番目に人気（10回）
DO $$
DECLARE
  v_route_id UUID;
  v_user_id UUID;
  v_dog_id UUID;
  v_duration INT;
  i INT;
  v_hour INT;
  v_month INT;
BEGIN
  -- 3番目に古いルートを取得（ルート3）
  SELECT id INTO v_route_id FROM official_routes ORDER BY created_at OFFSET 2 LIMIT 1;
  
  SELECT id INTO v_user_id FROM auth.users LIMIT 1;
  SELECT id INTO v_dog_id FROM dogs WHERE user_id = v_user_id LIMIT 1;
  SELECT estimated_minutes INTO v_duration FROM official_routes WHERE id = v_route_id;
  
  IF v_route_id IS NOT NULL AND v_user_id IS NOT NULL AND v_dog_id IS NOT NULL THEN
    FOR i IN 1..10 LOOP
      v_hour := (i % 24);
      v_month := EXTRACT(MONTH FROM NOW() - (INTERVAL '1 day' * (i - 1)));
      
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
        NOW() - (INTERVAL '1 day' * (i - 1)),
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
        NOW() - (INTERVAL '1 day' * (i - 1))
      );
    END LOOP;
    RAISE NOTICE 'ルート3に10回の散歩データを追加しました';
  ELSE
    RAISE NOTICE '警告: ルート、ユーザー、または犬が見つかりません';
  END IF;
END $$;

-- 最終確認クエリ
SELECT 
  route_name,
  area_name,
  monthly_walks,
  created_at
FROM get_monthly_popular_official_routes(10, 0)
ORDER BY monthly_walks DESC;

-- 完了メッセージ
SELECT 'ダミーデータの挿入が完了しました（ルート1: 20回、ルート2: 15回、ルート3: 10回）' AS status;
