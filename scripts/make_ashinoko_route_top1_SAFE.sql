-- =====================================================
-- WanWalk: 芦ノ湖畔ロングウォークを今月の人気1位にする（安全版）
-- =====================================================
-- 実行日: 2025-12-10
-- 目的: デモ・プレゼン用の安全な散歩データ追加
-- 対象: テスト環境またはデモ環境のみ
-- 警告: ⚠️ 本番環境では実行しないでください ⚠️

-- =====================================================
-- 【重要】実行前チェックリスト
-- =====================================================
-- [ ] テスト環境で実行していますか？
-- [ ] 本番環境の場合、関係者に説明済みですか？
-- [ ] デモデータであることを明示しますか？
-- [ ] プレゼン後に削除する予定ですか？
-- [ ] バックアップを取得しましたか？

-- すべてチェックできない場合は実行を中止してください

-- =====================================================
-- ステップ1: is_demo_data カラムの追加（まだない場合）
-- =====================================================
ALTER TABLE walks ADD COLUMN IF NOT EXISTS is_demo_data BOOLEAN DEFAULT FALSE;

COMMENT ON COLUMN walks.is_demo_data IS 'デモ・テスト用のデータフラグ。本番では削除すべきデータ。';

-- =====================================================
-- ステップ2: 既存のデモデータ確認
-- =====================================================
DO $$
DECLARE
  v_route_id UUID := '6ae42d51-4221-4075-a2c7-cb8572e17cf7';
  v_existing_demo_count INT;
  v_existing_real_count INT;
BEGIN
  -- デモデータの数を確認
  SELECT COUNT(*) INTO v_existing_demo_count
  FROM walks
  WHERE route_id = v_route_id
    AND is_demo_data = TRUE
    AND start_time >= NOW() - INTERVAL '1 month';
  
  -- 実データの数を確認
  SELECT COUNT(*) INTO v_existing_real_count
  FROM walks
  WHERE route_id = v_route_id
    AND (is_demo_data = FALSE OR is_demo_data IS NULL)
    AND start_time >= NOW() - INTERVAL '1 month';
  
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '📊 既存データ確認';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '  実データ: % 回', v_existing_real_count;
  RAISE NOTICE '  デモデータ: % 回', v_existing_demo_count;
  RAISE NOTICE '';
  
  IF v_existing_demo_count > 0 THEN
    RAISE NOTICE '⚠️  警告: 既にデモデータが存在します';
    RAISE NOTICE '   先に削除することを推奨します:';
    RAISE NOTICE '   DELETE FROM walks WHERE route_id = ''%'' AND is_demo_data = TRUE;', v_route_id;
    RAISE EXCEPTION '既存のデモデータを先に削除してください';
  END IF;
END $$;

-- =====================================================
-- ステップ3: デモデータの追加（安全版）
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
  v_route_name TEXT;
  v_max_demo_count INT := 20; -- 30回ではなく20回に削減（より控えめ）
BEGIN
  -- ユーザーIDを取得
  SELECT id INTO v_user_id FROM auth.users ORDER BY created_at LIMIT 1;
  
  -- ルート情報を取得
  SELECT area_id, distance_meters, estimated_minutes, title
  INTO v_area_id, v_distance_meters, v_estimated_minutes, v_route_name
  FROM official_routes 
  WHERE id = v_route_id;
  
  -- 所要時間（秒）を計算
  v_duration_seconds := v_estimated_minutes * 60;
  
  IF v_user_id IS NOT NULL AND v_area_id IS NOT NULL THEN
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '🚀 デモデータ追加開始';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '  ルート: %', v_route_name;
    RAISE NOTICE '  追加数: % 回', v_max_demo_count;
    RAISE NOTICE '  ユーザー: %', v_user_id;
    RAISE NOTICE '  期間: 過去 % 日間', v_max_demo_count;
    RAISE NOTICE '';
    
    -- デモデータを追加（控えめな回数）
    FOR i IN 1..v_max_demo_count LOOP
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
        path_geojson,
        is_demo_data, -- デモフラグを明示
        created_at -- start_timeと一致させて整合性を保つ
      ) VALUES (
        v_user_id,
        'outing',
        v_route_id,
        v_start_time,
        v_end_time,
        v_distance_meters + (RANDOM() * 100)::INT - 50,
        v_duration_seconds + (RANDOM() * 600)::INT - 300,
        '{"type":"LineString","coordinates":[[139.0315,35.2034],[139.0325,35.2044]]}',
        TRUE, -- ⭐ デモデータであることを明示
        v_start_time -- created_atもstart_timeと同じにして整合性を保つ
      );
    END LOOP;
    
    RAISE NOTICE '✅ % 回のデモデータを追加しました', v_max_demo_count;
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '⚠️  重要な注意事項';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '  1. これはデモデータです';
    RAISE NOTICE '  2. プレゼンでは「デモデータ」と明示してください';
    RAISE NOTICE '  3. プレゼン後に必ず削除してください:';
    RAISE NOTICE '     DELETE FROM walks WHERE is_demo_data = TRUE;';
    RAISE NOTICE '';
  ELSE
    RAISE EXCEPTION 'ユーザーまたはルートが見つかりません (user_id: %, area_id: %)', v_user_id, v_area_id;
  END IF;
END $$;

-- =====================================================
-- ステップ4: 結果確認
-- =====================================================
SELECT 
  r.title AS route_name,
  a.name AS area_name,
  COUNT(w.id) FILTER (WHERE w.start_time >= NOW() - INTERVAL '1 month' AND w.is_demo_data = FALSE) AS real_walks,
  COUNT(w.id) FILTER (WHERE w.start_time >= NOW() - INTERVAL '1 month' AND w.is_demo_data = TRUE) AS demo_walks,
  COUNT(w.id) FILTER (WHERE w.start_time >= NOW() - INTERVAL '1 month') AS total_monthly_walks,
  r.distance_meters / 1000.0 AS distance_km
FROM official_routes r
JOIN areas a ON a.id = r.area_id
LEFT JOIN walks w ON w.route_id = r.id AND w.walk_type = 'outing'
WHERE r.id = '6ae42d51-4221-4075-a2c7-cb8572e17cf7'
GROUP BY r.id, r.title, a.name, r.distance_meters;

-- =====================================================
-- 完了メッセージ
-- =====================================================
SELECT '✅ デモデータ追加完了（is_demo_data=TRUE）- プレゼン後に必ず削除してください' AS status;
SELECT '⚠️ 削除コマンド: DELETE FROM walks WHERE is_demo_data = TRUE;' AS reminder;
