-- =====================================================
-- WanWalk: 今月の人気ルート用ダミーデータ挿入
-- =====================================================
-- 実行日: 2025-12-08
-- 目的: route_walks テーブルに過去1ヶ月のダミーデータを追加

-- =====================================================
-- Step 1: 既存のルートIDとユーザーIDを確認
-- =====================================================
-- 実行前に以下のクエリで確認してください：
-- SELECT id, name FROM official_routes LIMIT 5;
-- SELECT id FROM auth.users LIMIT 1;

-- =====================================================
-- Step 2: ダミーデータ挿入
-- =====================================================
-- 注意: 以下の値は実際の環境に合わせて変更してください
-- - route_id: official_routes テーブルの実際のルートID
-- - user_id: auth.users テーブルの実際のユーザーID

-- ルート1: 過去1ヶ月で最も人気（20回）
DO $$
DECLARE
  v_route_id UUID;
  v_user_id UUID;
  i INT;
BEGIN
  -- 最初のルートIDを取得
  SELECT id INTO v_route_id FROM official_routes ORDER BY created_at LIMIT 1;
  -- 最初のユーザーIDを取得
  SELECT id INTO v_user_id FROM auth.users LIMIT 1;
  
  IF v_route_id IS NOT NULL AND v_user_id IS NOT NULL THEN
    FOR i IN 1..20 LOOP
      INSERT INTO route_walks (
        route_id,
        user_id,
        started_at,
        ended_at,
        distance_meters,
        duration_seconds,
        created_at
      ) VALUES (
        v_route_id,
        v_user_id,
        NOW() - (INTERVAL '1 day' * (i - 1)) - INTERVAL '1 hour',
        NOW() - (INTERVAL '1 day' * (i - 1)),
        (SELECT distance_meters FROM official_routes WHERE id = v_route_id),
        (SELECT estimated_minutes FROM official_routes WHERE id = v_route_id) * 60,
        NOW() - (INTERVAL '1 day' * (i - 1))
      );
    END LOOP;
    RAISE NOTICE 'ルート1に20回の散歩データを追加しました';
  END IF;
END $$;

-- ルート2: 過去1ヶ月で2番目に人気（15回）
DO $$
DECLARE
  v_route_id UUID;
  v_user_id UUID;
  i INT;
BEGIN
  -- 2番目のルートIDを取得
  SELECT id INTO v_route_id FROM official_routes ORDER BY created_at LIMIT 1 OFFSET 1;
  -- 最初のユーザーIDを取得
  SELECT id INTO v_user_id FROM auth.users LIMIT 1;
  
  IF v_route_id IS NOT NULL AND v_user_id IS NOT NULL THEN
    FOR i IN 1..15 LOOP
      INSERT INTO route_walks (
        route_id,
        user_id,
        started_at,
        ended_at,
        distance_meters,
        duration_seconds,
        created_at
      ) VALUES (
        v_route_id,
        v_user_id,
        NOW() - (INTERVAL '1 day' * (i - 1)) - INTERVAL '1 hour',
        NOW() - (INTERVAL '1 day' * (i - 1)),
        (SELECT distance_meters FROM official_routes WHERE id = v_route_id),
        (SELECT estimated_minutes FROM official_routes WHERE id = v_route_id) * 60,
        NOW() - (INTERVAL '1 day' * (i - 1))
      );
    END LOOP;
    RAISE NOTICE 'ルート2に15回の散歩データを追加しました';
  END IF;
END $$;

-- ルート3: 過去1ヶ月で3番目に人気（10回）
DO $$
DECLARE
  v_route_id UUID;
  v_user_id UUID;
  i INT;
BEGIN
  -- 3番目のルートIDを取得
  SELECT id INTO v_route_id FROM official_routes ORDER BY created_at LIMIT 1 OFFSET 2;
  -- 最初のユーザーIDを取得
  SELECT id INTO v_user_id FROM auth.users LIMIT 1;
  
  IF v_route_id IS NOT NULL AND v_user_id IS NOT NULL THEN
    FOR i IN 1..10 LOOP
      INSERT INTO route_walks (
        route_id,
        user_id,
        started_at,
        ended_at,
        distance_meters,
        duration_seconds,
        created_at
      ) VALUES (
        v_route_id,
        v_user_id,
        NOW() - (INTERVAL '1 day' * (i - 1)) - INTERVAL '1 hour',
        NOW() - (INTERVAL '1 day' * (i - 1)),
        (SELECT distance_meters FROM official_routes WHERE id = v_route_id),
        (SELECT estimated_minutes FROM official_routes WHERE id = v_route_id) * 60,
        NOW() - (INTERVAL '1 day' * (i - 1))
      );
    END LOOP;
    RAISE NOTICE 'ルート3に10回の散歩データを追加しました';
  END IF;
END $$;

-- =====================================================
-- Step 3: 確認クエリ
-- =====================================================
-- 今月の人気ルートランキングを確認
SELECT * FROM get_monthly_popular_official_routes(10, 0);

-- 完了メッセージ
SELECT '今月の人気ルート用ダミーデータを追加しました' AS status;
