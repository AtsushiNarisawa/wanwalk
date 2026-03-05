-- =====================================================
-- WanWalk: 今月の人気ルート用ダミーデータ挿入（修正版）
-- =====================================================
-- 実行日: 2025-12-08
-- 目的: route_walks テーブルに過去1ヶ月のダミーデータを追加

-- ルート1: 過去1ヶ月で最も人気（20回）
DO $$
DECLARE
  v_route_id UUID;
  v_user_id UUID;
  v_dog_id UUID;
  i INT;
BEGIN
  -- 最初のルートIDを取得
  SELECT id INTO v_route_id FROM official_routes ORDER BY created_at LIMIT 1;
  -- 最初のユーザーIDを取得
  SELECT id INTO v_user_id FROM auth.users LIMIT 1;
  -- 最初の犬IDを取得（ユーザーの犬）
  SELECT id INTO v_dog_id FROM dogs WHERE user_id = v_user_id LIMIT 1;
  
  -- 犬が存在しない場合はスキップ
  IF v_route_id IS NOT NULL AND v_user_id IS NOT NULL AND v_dog_id IS NOT NULL THEN
    FOR i IN 1..20 LOOP
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
        (SELECT estimated_minutes FROM official_routes WHERE id = v_route_id),
        CASE 
          WHEN EXTRACT(HOUR FROM NOW()) BETWEEN 5 AND 11 THEN 'morning'
          WHEN EXTRACT(HOUR FROM NOW()) BETWEEN 12 AND 16 THEN 'midday'
          WHEN EXTRACT(HOUR FROM NOW()) BETWEEN 17 AND 20 THEN 'evening'
          ELSE 'night'
        END,
        CASE 
          WHEN EXTRACT(MONTH FROM NOW()) IN (3, 4, 5) THEN 'spring'
          WHEN EXTRACT(MONTH FROM NOW()) IN (6, 7, 8) THEN 'summer'
          WHEN EXTRACT(MONTH FROM NOW()) IN (9, 10, 11) THEN 'autumn'
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

-- ルート2: 過去1ヶ月で2番目に人気（15回）
DO $$
DECLARE
  v_route_id UUID;
  v_user_id UUID;
  v_dog_id UUID;
  i INT;
BEGIN
  SELECT id INTO v_route_id FROM official_routes ORDER BY created_at LIMIT 1 OFFSET 1;
  SELECT id INTO v_user_id FROM auth.users LIMIT 1;
  SELECT id INTO v_dog_id FROM dogs WHERE user_id = v_user_id LIMIT 1;
  
  IF v_route_id IS NOT NULL AND v_user_id IS NOT NULL AND v_dog_id IS NOT NULL THEN
    FOR i IN 1..15 LOOP
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
        (SELECT estimated_minutes FROM official_routes WHERE id = v_route_id),
        CASE 
          WHEN EXTRACT(HOUR FROM NOW()) BETWEEN 5 AND 11 THEN 'morning'
          WHEN EXTRACT(HOUR FROM NOW()) BETWEEN 12 AND 16 THEN 'midday'
          WHEN EXTRACT(HOUR FROM NOW()) BETWEEN 17 AND 20 THEN 'evening'
          ELSE 'night'
        END,
        CASE 
          WHEN EXTRACT(MONTH FROM NOW()) IN (3, 4, 5) THEN 'spring'
          WHEN EXTRACT(MONTH FROM NOW()) IN (6, 7, 8) THEN 'summer'
          WHEN EXTRACT(MONTH FROM NOW()) IN (9, 10, 11) THEN 'autumn'
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

-- ルート3: 過去1ヶ月で3番目に人気（10回）
DO $$
DECLARE
  v_route_id UUID;
  v_user_id UUID;
  v_dog_id UUID;
  i INT;
BEGIN
  SELECT id INTO v_route_id FROM official_routes ORDER BY created_at LIMIT 1 OFFSET 2;
  SELECT id INTO v_user_id FROM auth.users LIMIT 1;
  SELECT id INTO v_dog_id FROM dogs WHERE user_id = v_user_id LIMIT 1;
  
  IF v_route_id IS NOT NULL AND v_user_id IS NOT NULL AND v_dog_id IS NOT NULL THEN
    FOR i IN 1..10 LOOP
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
        (SELECT estimated_minutes FROM official_routes WHERE id = v_route_id),
        CASE 
          WHEN EXTRACT(HOUR FROM NOW()) BETWEEN 5 AND 11 THEN 'morning'
          WHEN EXTRACT(HOUR FROM NOW()) BETWEEN 12 AND 16 THEN 'midday'
          WHEN EXTRACT(HOUR FROM NOW()) BETWEEN 17 AND 20 THEN 'evening'
          ELSE 'night'
        END,
        CASE 
          WHEN EXTRACT(MONTH FROM NOW()) IN (3, 4, 5) THEN 'spring'
          WHEN EXTRACT(MONTH FROM NOW()) IN (6, 7, 8) THEN 'summer'
          WHEN EXTRACT(MONTH FROM NOW()) IN (9, 10, 11) THEN 'autumn'
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

-- 確認クエリ
SELECT * FROM get_monthly_popular_official_routes(10, 0);
