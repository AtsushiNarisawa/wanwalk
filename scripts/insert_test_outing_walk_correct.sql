-- お出かけ散歩のテストデータ投入スクリプト（正しいテーブル構造版）
-- 
-- 使用テーブル:
-- - walks (walk_type='outing')
-- - walk_photos
-- - pins
-- - official_routes
-- 
-- 使用方法: Supabase SQLエディタで実行

DO $$
DECLARE
  v_area_id UUID;
  v_route_id UUID;
  v_user_id UUID;
  v_walk_id UUID;
BEGIN
  -- 1. 必要なIDを取得
  -- 箱根エリアのIDを取得
  SELECT id INTO v_area_id FROM areas WHERE name = '箱根' LIMIT 1;
  
  -- 認証ユーザーIDを取得（最初のユーザー）
  SELECT id INTO v_user_id FROM auth.users ORDER BY created_at LIMIT 1;
  
  -- エラーチェック
  IF v_area_id IS NULL THEN
    RAISE EXCEPTION 'エリア「箱根」が見つかりません。先にエリアを作成してください。';
  END IF;
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'ユーザーが見つかりません。先にユーザーを作成してください。';
  END IF;
  
  RAISE NOTICE '✅ ユーザーID: %', v_user_id;
  RAISE NOTICE '✅ エリアID（箱根）: %', v_area_id;
  
  -- 2. テスト用公式ルートの作成（既存チェック）
  SELECT id INTO v_route_id 
  FROM official_routes 
  WHERE title = '芦ノ湖スカイラインコース' AND area_id = v_area_id
  LIMIT 1;
  
  IF v_route_id IS NULL THEN
    INSERT INTO official_routes (
      title,
      description,
      area_id,
      distance_meters,
      estimated_minutes,
      difficulty,
      route_geojson,
      thumbnail_url,
      is_public
    ) VALUES (
      '芦ノ湖スカイラインコース',
      '芦ノ湖を一望できる絶景ルート。愛犬と一緒に箱根の自然を満喫できます。',
      v_area_id,
      5200,
      85,
      'medium',
      '{"type":"LineString","coordinates":[[139.0315,35.2034],[139.0325,35.2044],[139.0335,35.2054]]}',
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
      true
    )
    RETURNING id INTO v_route_id;
    
    RAISE NOTICE '✅ ルート作成: %', v_route_id;
  ELSE
    RAISE NOTICE '✅ 既存ルート使用: %', v_route_id;
  END IF;
  
  -- 3. テスト用散歩記録の作成（walksテーブル、walk_type='outing'）
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
    NOW() - INTERVAL '2 days',
    NOW() - INTERVAL '2 days' + INTERVAL '85 minutes',
    5150,
    5100,
    '{"type":"LineString","coordinates":[[139.0315,35.2034],[139.0325,35.2044],[139.0335,35.2054]]}'
  )
  RETURNING id INTO v_walk_id;
  
  RAISE NOTICE '✅ 散歩記録作成: %', v_walk_id;
  
  -- 4. テスト用写真の作成（walk_photosテーブル）
  INSERT INTO walk_photos (
    walk_id,
    user_id,
    photo_url,
    caption,
    display_order
  ) VALUES
    (v_walk_id, v_user_id, 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800', '芦ノ湖の絶景', 1),
    (v_walk_id, v_user_id, 'https://images.unsplash.com/photo-1454391304352-2bf4678b1a7a?w=800', '山道散策中', 2),
    (v_walk_id, v_user_id, 'https://images.unsplash.com/photo-1472214103451-9374bd1c798e?w=800', 'ランチ休憩', 3);
  
  RAISE NOTICE '✅ 写真3枚を追加';
  
  -- 5. テスト用ピンの作成（pinsテーブル）
  INSERT INTO pins (
    walk_id,
    user_id,
    latitude,
    longitude,
    title,
    description,
    photo_url,
    area_id
  ) VALUES
    (v_walk_id, v_user_id, 35.2034, 139.0315, '芦ノ湖ビューポイント', '絶景スポット！愛犬も大喜び', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800', v_area_id),
    (v_walk_id, v_user_id, 35.2044, 139.0325, 'ランチ休憩', 'お弁当を食べました', 'https://images.unsplash.com/photo-1454391304352-2bf4678b1a7a?w=800', v_area_id);
  
  RAISE NOTICE '✅ ピン2個を追加';
  
  -- 6. 確認
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🎉 テストデータの投入が完了しました！';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  RAISE NOTICE '📊 作成されたデータ:';
  RAISE NOTICE '  - ユーザーID: %', v_user_id;
  RAISE NOTICE '  - エリアID: %', v_area_id;
  RAISE NOTICE '  - ルートID: %', v_route_id;
  RAISE NOTICE '  - 散歩記録ID: %', v_walk_id;
  RAISE NOTICE '  - 写真: 3枚';
  RAISE NOTICE '  - ピン: 2個';
  RAISE NOTICE '';
  
END $$;

-- 確認用クエリ: 作成されたお出かけ散歩を表示
SELECT 
  w.id as walk_id,
  w.start_time as walked_at,
  w.distance_meters,
  w.duration_seconds,
  r.title as route_name,
  a.name as area_name,
  COUNT(DISTINCT wp.id) as photo_count,
  COUNT(DISTINCT p.id) as pin_count,
  ARRAY_AGG(DISTINCT wp.photo_url) FILTER (WHERE wp.photo_url IS NOT NULL) as photo_urls
FROM walks w
JOIN official_routes r ON w.route_id = r.id
JOIN areas a ON r.area_id = a.id
LEFT JOIN walk_photos wp ON w.id = wp.walk_id
LEFT JOIN pins p ON w.id = p.walk_id
WHERE w.walk_type = 'outing'
GROUP BY w.id, w.start_time, w.distance_meters, w.duration_seconds, r.title, a.name
ORDER BY w.start_time DESC
LIMIT 5;
