-- ==========================================
-- Phase 5 Test Data
-- ==========================================
-- 
-- このSQLスクリプトは、Phase 5の全機能をテストするための
-- 包括的なサンプルデータを作成します。
--
-- 含まれるデータ:
-- 1. テストユーザー (3名)
-- 2. 散歩履歴 (各ユーザー5~10件)
-- 3. ピン (各ユーザー3~5件)
-- 4. ルートお気に入り
-- 5. ピンブックマーク
-- 6. ユーザーフォロー関係
-- 7. 通知
-- 8. バッジ解除
--
-- 使用方法:
-- psql -h <host> -U <user> -d <database> -f test_data_phase5.sql
-- または Supabase Dashboard の SQL Editor で実行
--
-- ==========================================

BEGIN;

-- ==========================================
-- 1. テストユーザーの作成
-- ==========================================
-- 注意: auth.users テーブルは Supabase Auth で管理されているため、
-- 手動で作成することはできません。
-- 実際のテストでは、アプリから3つのアカウントを作成してください。
--
-- テストユーザー例:
-- User 1: test1@example.com (散歩マスター - 最も活発)
-- User 2: test2@example.com (バッジコレクター)
-- User 3: test3@example.com (ソーシャルユーザー)
--
-- このスクリプトでは、既存のユーザーIDを使用します。
-- 実行前に以下のコメントを解除し、実際のユーザーIDに置き換えてください:

-- \set user1_id 'REPLACE_WITH_REAL_USER_ID_1'
-- \set user2_id 'REPLACE_WITH_REAL_USER_ID_2'
-- \set user3_id 'REPLACE_WITH_REAL_USER_ID_3'

-- 一時的なテストIDを設定（実際には置き換える必要があります）
-- このままでは動作しません
DO $$
DECLARE
  user1_id UUID := '00000000-0000-0000-0000-000000000001'; -- 仮のID
  user2_id UUID := '00000000-0000-0000-0000-000000000002'; -- 仮のID
  user3_id UUID := '00000000-0000-0000-0000-000000000003'; -- 仮のID
  
  -- エリアID（既存のエリアから選択）
  area1_id UUID;
  area2_id UUID;
  area3_id UUID;
  
  -- ルートID（既存のルートから選択）
  route1_id UUID;
  route2_id UUID;
  
  walk1_id UUID;
  walk2_id UUID;
  walk3_id UUID;
  
  pin1_id UUID;
  pin2_id UUID;
  pin3_id UUID;
BEGIN

  -- ==========================================
  -- 2. エリアとルートのIDを取得
  -- ==========================================
  SELECT id INTO area1_id FROM areas LIMIT 1 OFFSET 0;
  SELECT id INTO area2_id FROM areas LIMIT 1 OFFSET 1;
  SELECT id INTO area3_id FROM areas LIMIT 1 OFFSET 2;
  
  SELECT id INTO route1_id FROM routes WHERE is_official = true LIMIT 1 OFFSET 0;
  SELECT id INTO route2_id FROM routes WHERE is_official = true LIMIT 1 OFFSET 1;

  -- ==========================================
  -- 3. 散歩履歴の作成
  -- ==========================================
  -- User 1: 散歩マスター (10件の散歩)
  FOR i IN 1..10 LOOP
    INSERT INTO walks (
      id, user_id, area_id, route_id,
      distance_meters, duration_seconds, completed_at,
      path_geom, start_location, end_location
    ) VALUES (
      gen_random_uuid(),
      user1_id,
      CASE WHEN i <= 4 THEN area1_id WHEN i <= 7 THEN area2_id ELSE area3_id END,
      CASE WHEN i % 2 = 0 THEN route1_id ELSE NULL END,
      1000 + (i * 500), -- 1.5km ~ 6km
      1800 + (i * 300), -- 30分 ~ 80分
      NOW() - (i || ' days')::INTERVAL,
      ST_GeomFromText('LINESTRING(139.6917 35.6895, 139.6920 35.6900)', 4326),
      ST_GeomFromText('POINT(139.6917 35.6895)', 4326),
      ST_GeomFromText('POINT(139.6920 35.6900)', 4326)
    );
  END LOOP;
  
  -- User 2: バッジコレクター (7件の散歩)
  FOR i IN 1..7 LOOP
    INSERT INTO walks (
      id, user_id, area_id,
      distance_meters, duration_seconds, completed_at,
      path_geom, start_location, end_location
    ) VALUES (
      gen_random_uuid(),
      user2_id,
      CASE WHEN i <= 3 THEN area1_id ELSE area2_id END,
      800 + (i * 400), -- 1.2km ~ 4km
      1500 + (i * 200), -- 25分 ~ 50分
      NOW() - (i || ' days')::INTERVAL,
      ST_GeomFromText('LINESTRING(139.6917 35.6895, 139.6918 35.6898)', 4326),
      ST_GeomFromText('POINT(139.6917 35.6895)', 4326),
      ST_GeomFromText('POINT(139.6918 35.6898)', 4326)
    );
  END LOOP;
  
  -- User 3: ソーシャルユーザー (5件の散歩)
  FOR i IN 1..5 LOOP
    INSERT INTO walks (
      id, user_id, area_id,
      distance_meters, duration_seconds, completed_at,
      path_geom, start_location, end_location
    ) VALUES (
      gen_random_uuid(),
      user3_id,
      area1_id,
      1200 + (i * 300), -- 1.5km ~ 3km
      2000 + (i * 250), -- 33分 ~ 53分
      NOW() - (i || ' days')::INTERVAL,
      ST_GeomFromText('LINESTRING(139.6917 35.6895, 139.6919 35.6897)', 4326),
      ST_GeomFromText('POINT(139.6917 35.6895)', 4326),
      ST_GeomFromText('POINT(139.6919 35.6897)', 4326)
    );
  END LOOP;

  -- ==========================================
  -- 4. ピンの作成
  -- ==========================================
  -- User 1: 5個のピン
  FOR i IN 1..5 LOOP
    INSERT INTO pins (
      id, user_id, area_id,
      name, description, pin_type,
      location, created_at
    ) VALUES (
      gen_random_uuid(),
      user1_id,
      CASE WHEN i <= 2 THEN area1_id ELSE area2_id END,
      'User1 Pin ' || i,
      'Test pin ' || i || ' by User 1',
      CASE 
        WHEN i = 1 THEN 'scenic_spot'
        WHEN i = 2 THEN 'dog_friendly_spot'
        WHEN i = 3 THEN 'water_fountain'
        WHEN i = 4 THEN 'rest_area'
        ELSE 'photo_spot'
      END,
      ST_GeomFromText('POINT(' || (139.6917 + i * 0.001)::text || ' ' || (35.6895 + i * 0.0005)::text || ')', 4326),
      NOW() - (i || ' days')::INTERVAL
    );
  END LOOP;
  
  -- User 2: 3個のピン
  FOR i IN 1..3 LOOP
    INSERT INTO pins (
      id, user_id, area_id,
      name, description, pin_type,
      location, created_at
    ) VALUES (
      gen_random_uuid(),
      user2_id,
      area1_id,
      'User2 Pin ' || i,
      'Test pin ' || i || ' by User 2',
      CASE 
        WHEN i = 1 THEN 'dog_park'
        WHEN i = 2 THEN 'scenic_spot'
        ELSE 'cafe'
      END,
      ST_GeomFromText('POINT(' || (139.6920 + i * 0.001)::text || ' ' || (35.6897 + i * 0.0005)::text || ')', 4326),
      NOW() - (i || ' days')::INTERVAL
    );
  END LOOP;
  
  -- User 3: 4個のピン
  FOR i IN 1..4 LOOP
    INSERT INTO pins (
      id, user_id, area_id,
      name, description, pin_type,
      location, created_at
    ) VALUES (
      gen_random_uuid(),
      user3_id,
      area1_id,
      'User3 Pin ' || i,
      'Test pin ' || i || ' by User 3',
      CASE 
        WHEN i = 1 THEN 'photo_spot'
        WHEN i = 2 THEN 'dog_friendly_shop'
        WHEN i = 3 THEN 'rest_area'
        ELSE 'scenic_spot'
      END,
      ST_GeomFromText('POINT(' || (139.6918 + i * 0.001)::text || ' ' || (35.6896 + i * 0.0005)::text || ')', 4326),
      NOW() - (i || ' days')::INTERVAL
    );
  END LOOP;

  -- ==========================================
  -- 5. ルートお気に入り
  -- ==========================================
  INSERT INTO route_favorites (user_id, route_id, created_at)
  VALUES 
    (user1_id, route1_id, NOW() - '2 days'::INTERVAL),
    (user1_id, route2_id, NOW() - '1 day'::INTERVAL),
    (user2_id, route1_id, NOW() - '3 days'::INTERVAL),
    (user3_id, route2_id, NOW() - '1 day'::INTERVAL);

  -- ==========================================
  -- 6. ピンブックマーク
  -- ==========================================
  -- User1がUser2とUser3のピンをブックマーク
  INSERT INTO pin_bookmarks (user_id, pin_id, created_at)
  SELECT user1_id, id, NOW() - '1 day'::INTERVAL
  FROM pins WHERE user_id IN (user2_id, user3_id)
  LIMIT 3;
  
  -- User2がUser1のピンをブックマーク
  INSERT INTO pin_bookmarks (user_id, pin_id, created_at)
  SELECT user2_id, id, NOW() - '2 days'::INTERVAL
  FROM pins WHERE user_id = user1_id
  LIMIT 2;

  -- ==========================================
  -- 7. ユーザーフォロー関係
  -- ==========================================
  -- User1 → User2, User3をフォロー
  INSERT INTO user_follows (follower_id, following_id, created_at)
  VALUES 
    (user1_id, user2_id, NOW() - '5 days'::INTERVAL),
    (user1_id, user3_id, NOW() - '4 days'::INTERVAL);
  
  -- User2 → User1をフォロー
  INSERT INTO user_follows (follower_id, following_id, created_at)
  VALUES 
    (user2_id, user1_id, NOW() - '3 days'::INTERVAL);
  
  -- User3 → User1, User2をフォロー
  INSERT INTO user_follows (follower_id, following_id, created_at)
  VALUES 
    (user3_id, user1_id, NOW() - '2 days'::INTERVAL),
    (user3_id, user2_id, NOW() - '1 day'::INTERVAL);

  -- ==========================================
  -- 8. 通知
  -- ==========================================
  -- User1への通知（フォロワー、ピンいいね）
  INSERT INTO notifications (user_id, type, title, body, related_user_id, is_read, created_at)
  VALUES 
    (user1_id, 'new_follower', '新しいフォロワー', 'User2があなたをフォローしました', user2_id, false, NOW() - '3 days'::INTERVAL),
    (user1_id, 'new_follower', '新しいフォロワー', 'User3があなたをフォローしました', user3_id, false, NOW() - '2 days'::INTERVAL),
    (user1_id, 'pin_liked', 'ピンがいいねされました', 'User2があなたのピンにいいねしました', user2_id, true, NOW() - '4 days'::INTERVAL);
  
  -- User2への通知
  INSERT INTO notifications (user_id, type, title, body, related_user_id, is_read, created_at)
  VALUES 
    (user2_id, 'new_follower', '新しいフォロワー', 'User1があなたをフォローしました', user1_id, false, NOW() - '5 days'::INTERVAL),
    (user2_id, 'new_follower', '新しいフォロワー', 'User3があなたをフォローしました', user3_id, false, NOW() - '1 day'::INTERVAL);
  
  -- User3への通知
  INSERT INTO notifications (user_id, type, title, body, related_user_id, is_read, created_at)
  VALUES 
    (user3_id, 'new_follower', '新しいフォロワー', 'User1があなたをフォローしました', user1_id, true, NOW() - '4 days'::INTERVAL);

  -- ==========================================
  -- 9. バッジ解除
  -- ==========================================
  -- User1のバッジ解除（最も活発なユーザー）
  -- 距離バッジ: 10km達成
  INSERT INTO user_badges (user_id, badge_id, unlocked_at, is_new)
  SELECT user1_id, id, NOW() - '3 days'::INTERVAL, false
  FROM badge_definitions WHERE badge_code = 'distance_10km';
  
  -- エリア探索バッジ: 3エリア訪問
  INSERT INTO user_badges (user_id, badge_id, unlocked_at, is_new)
  SELECT user1_id, id, NOW() - '2 days'::INTERVAL, false
  FROM badge_definitions WHERE badge_code = 'area_3';
  
  -- ピン作成バッジ: 5ピン作成
  INSERT INTO user_badges (user_id, badge_id, unlocked_at, is_new)
  SELECT user1_id, id, NOW() - '1 day'::INTERVAL, true
  FROM badge_definitions WHERE badge_code = 'pins_5';
  
  -- 特別バッジ: first_walk, first_pin
  INSERT INTO user_badges (user_id, badge_id, unlocked_at, is_new)
  SELECT user1_id, id, NOW() - '10 days'::INTERVAL, false
  FROM badge_definitions WHERE badge_code IN ('first_walk', 'first_pin');
  
  -- User2のバッジ解除
  -- 距離バッジ: 10km達成
  INSERT INTO user_badges (user_id, badge_id, unlocked_at, is_new)
  SELECT user2_id, id, NOW() - '2 days'::INTERVAL, false
  FROM badge_definitions WHERE badge_code = 'distance_10km';
  
  -- 特別バッジ: first_walk
  INSERT INTO user_badges (user_id, badge_id, unlocked_at, is_new)
  SELECT user2_id, id, NOW() - '7 days'::INTERVAL, false
  FROM badge_definitions WHERE badge_code = 'first_walk';
  
  -- User3のバッジ解除
  -- 特別バッジ: first_walk, first_pin
  INSERT INTO user_badges (user_id, badge_id, unlocked_at, is_new)
  SELECT user3_id, id, NOW() - '5 days'::INTERVAL, false
  FROM badge_definitions WHERE badge_code IN ('first_walk', 'first_pin');

  RAISE NOTICE 'Test data created successfully!';
  RAISE NOTICE 'テストユーザーID:';
  RAISE NOTICE '  User 1 (散歩マスター): %', user1_id;
  RAISE NOTICE '  User 2 (バッジコレクター): %', user2_id;
  RAISE NOTICE '  User 3 (ソーシャルユーザー): %', user3_id;
  
END $$;

COMMIT;

-- ==========================================
-- テストデータ確認用クエリ
-- ==========================================

-- 各ユーザーの統計を確認
-- SELECT 
--   user_id,
--   COUNT(*) as total_walks,
--   SUM(distance_meters) / 1000.0 as total_distance_km,
--   COUNT(DISTINCT area_id) as areas_visited
-- FROM walks
-- GROUP BY user_id
-- ORDER BY total_distance_km DESC;

-- 各ユーザーのピン数を確認
-- SELECT 
--   user_id,
--   COUNT(*) as total_pins
-- FROM pins
-- GROUP BY user_id
-- ORDER BY total_pins DESC;

-- 各ユーザーのバッジ解除数を確認
-- SELECT 
--   user_id,
--   COUNT(*) as unlocked_badges
-- FROM user_badges
-- GROUP BY user_id
-- ORDER BY unlocked_badges DESC;

-- フォロー関係を確認
-- SELECT 
--   follower_id,
--   COUNT(*) as following_count
-- FROM user_follows
-- GROUP BY follower_id;

-- 通知を確認
-- SELECT 
--   user_id,
--   type,
--   COUNT(*) as notification_count
-- FROM notifications
-- GROUP BY user_id, type
-- ORDER BY user_id, type;
