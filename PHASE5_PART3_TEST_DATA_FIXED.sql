-- =====================================================
-- Phase 5 Test Data Insertion - Part 3/3 (FIXED)
-- =====================================================
-- This script inserts test data for Phase 5 features
-- Prerequisite: Parts 1 & 2 must be executed successfully
-- =====================================================

-- Start transaction
BEGIN;

-- =====================================================
-- Step 1: Create test user profiles
-- =====================================================
DO $$
DECLARE
  user1_id UUID := 'a0000000-0000-0000-0000-000000000001'::UUID;
  user2_id UUID := 'a0000000-0000-0000-0000-000000000002'::UUID;
  user3_id UUID := 'a0000000-0000-0000-0000-000000000003'::UUID;
BEGIN
  -- Insert user profiles (using fixed UUIDs for test users)
  INSERT INTO users (id, email, display_name, created_at, updated_at)
  VALUES 
    (user1_id, 'test1@example.com', 'テストユーザー1', NOW(), NOW()),
    (user2_id, 'test2@example.com', 'テストユーザー2', NOW(), NOW()),
    (user3_id, 'test3@example.com', 'テストユーザー3', NOW(), NOW())
  ON CONFLICT (id) DO UPDATE 
  SET display_name = EXCLUDED.display_name, 
      updated_at = NOW();

  RAISE NOTICE 'Created 3 test user profiles';
END $$;

-- =====================================================
-- Step 2: Insert daily_walks test data
-- =====================================================
DO $$
DECLARE
  user1_id UUID := 'a0000000-0000-0000-0000-000000000001'::UUID;
  user2_id UUID := 'a0000000-0000-0000-0000-000000000002'::UUID;
  user3_id UUID := 'a0000000-0000-0000-0000-000000000003'::UUID;
  i INTEGER;
BEGIN
  -- User1: 10 walks with varying distances (1-10km)
  FOR i IN 1..10 LOOP
    INSERT INTO daily_walks (id, user_id, distance_meters, duration, walked_at, created_at)
    VALUES (
      gen_random_uuid(),
      user1_id,
      (1000 + i * 500)::double precision, -- 1.5km to 6km
      (1800 + i * 300), -- 30 to 80 minutes
      NOW() - (i || ' days')::INTERVAL,
      NOW() - (i || ' days')::INTERVAL
    );
  END LOOP;

  -- User2: 7 walks with moderate distances
  FOR i IN 1..7 LOOP
    INSERT INTO daily_walks (id, user_id, distance_meters, duration, walked_at, created_at)
    VALUES (
      gen_random_uuid(),
      user2_id,
      (800 + i * 400)::double precision, -- 1.2km to 4km
      (1500 + i * 200), -- 25 to 39 minutes
      NOW() - (i || ' days')::INTERVAL,
      NOW() - (i || ' days')::INTERVAL
    );
  END LOOP;

  -- User3: 5 walks with short distances
  FOR i IN 1..5 LOOP
    INSERT INTO daily_walks (id, user_id, distance_meters, duration, walked_at, created_at)
    VALUES (
      gen_random_uuid(),
      user3_id,
      (500 + i * 300)::double precision, -- 0.8km to 2km
      (1200 + i * 150), -- 20 to 30 minutes
      NOW() - (i || ' days')::INTERVAL,
      NOW() - (i || ' days')::INTERVAL
    );
  END LOOP;

  RAISE NOTICE 'Inserted 22 daily_walks records (10+7+5)';
END $$;

-- =====================================================
-- Step 3: Insert route_pins test data (FIXED pin_types)
-- =====================================================
DO $$
DECLARE
  user1_id UUID := 'a0000000-0000-0000-0000-000000000001'::UUID;
  user2_id UUID := 'a0000000-0000-0000-0000-000000000002'::UUID;
  user3_id UUID := 'a0000000-0000-0000-0000-000000000003'::UUID;
  route1_id UUID;
  route2_id UUID;
  i INTEGER;
  current_pin_type TEXT;
BEGIN
  -- Get first two official routes
  SELECT id INTO route1_id FROM official_routes ORDER BY created_at LIMIT 1;
  SELECT id INTO route2_id FROM official_routes ORDER BY created_at OFFSET 1 LIMIT 1;

  IF route1_id IS NULL OR route2_id IS NULL THEN
    RAISE NOTICE 'Warning: No official routes found. Skipping route_pins insertion.';
    RETURN;
  END IF;

  -- User1: 5 pins on route1 (FIXED: using 'scenery', 'shop', 'encounter', 'other')
  FOR i IN 1..5 LOOP
    current_pin_type := CASE 
      WHEN i = 1 THEN 'scenery'
      WHEN i = 2 THEN 'shop'
      WHEN i = 3 THEN 'encounter'
      WHEN i = 4 THEN 'scenery'
      ELSE 'other'
    END;

    INSERT INTO route_pins (id, user_id, route_id, title, comment, pin_type, location, created_at)
    VALUES (
      gen_random_uuid(),
      user1_id,
      route1_id,
      'User1 Pin ' || i,
      'Test pin by user1 - ' || current_pin_type,
      current_pin_type,
      ST_GeogFromText('POINT(139.7' || i || ' 35.6' || i || ')'),
      NOW() - (i || ' days')::INTERVAL
    );
  END LOOP;

  -- User2: 4 pins on route2
  FOR i IN 1..4 LOOP
    current_pin_type := CASE 
      WHEN i = 1 THEN 'shop'
      WHEN i = 2 THEN 'encounter'
      WHEN i = 3 THEN 'other'
      ELSE 'scenery'
    END;

    INSERT INTO route_pins (id, user_id, route_id, title, comment, pin_type, location, created_at)
    VALUES (
      gen_random_uuid(),
      user2_id,
      route2_id,
      'User2 Pin ' || i,
      'Test pin by user2 - ' || current_pin_type,
      current_pin_type,
      ST_GeogFromText('POINT(139.8' || i || ' 35.7' || i || ')'),
      NOW() - (i || ' days')::INTERVAL
    );
  END LOOP;

  -- User3: 3 pins on route1
  FOR i IN 1..3 LOOP
    current_pin_type := CASE 
      WHEN i = 1 THEN 'encounter'
      WHEN i = 2 THEN 'scenery'
      ELSE 'shop'
    END;

    INSERT INTO route_pins (id, user_id, route_id, title, comment, pin_type, location, created_at)
    VALUES (
      gen_random_uuid(),
      user3_id,
      route1_id,
      'User3 Pin ' || i,
      'Test pin by user3 - ' || current_pin_type,
      current_pin_type,
      ST_GeogFromText('POINT(139.9' || i || ' 35.8' || i || ')'),
      NOW() - (i || ' days')::INTERVAL
    );
  END LOOP;

  RAISE NOTICE 'Inserted 12 route_pins records (5+4+3)';
END $$;

-- =====================================================
-- Step 4: Insert route_favorites test data
-- =====================================================
DO $$
DECLARE
  user1_id UUID := 'a0000000-0000-0000-0000-000000000001'::UUID;
  user2_id UUID := 'a0000000-0000-0000-0000-000000000002'::UUID;
  user3_id UUID := 'a0000000-0000-0000-0000-000000000003'::UUID;
  route1_id UUID;
  route2_id UUID;
  route3_id UUID;
BEGIN
  -- Get first three official routes
  SELECT id INTO route1_id FROM official_routes ORDER BY created_at LIMIT 1;
  SELECT id INTO route2_id FROM official_routes ORDER BY created_at OFFSET 1 LIMIT 1;
  SELECT id INTO route3_id FROM official_routes ORDER BY created_at OFFSET 2 LIMIT 1;

  IF route1_id IS NULL THEN
    RAISE NOTICE 'Warning: No official routes found. Skipping route_favorites insertion.';
    RETURN;
  END IF;

  -- User1 favorites routes 1 and 2
  INSERT INTO route_favorites (user_id, route_id, created_at)
  VALUES 
    (user1_id, route1_id, NOW() - '2 days'::INTERVAL),
    (user1_id, route2_id, NOW() - '1 day'::INTERVAL)
  ON CONFLICT (user_id, route_id) DO NOTHING;

  -- User2 favorites route 1 and 3
  IF route3_id IS NOT NULL THEN
    INSERT INTO route_favorites (user_id, route_id, created_at)
    VALUES 
      (user2_id, route1_id, NOW() - '3 days'::INTERVAL),
      (user2_id, route3_id, NOW() - '1 day'::INTERVAL)
    ON CONFLICT (user_id, route_id) DO NOTHING;
  ELSE
    INSERT INTO route_favorites (user_id, route_id, created_at)
    VALUES (user2_id, route1_id, NOW() - '3 days'::INTERVAL)
    ON CONFLICT (user_id, route_id) DO NOTHING;
  END IF;

  RAISE NOTICE 'Inserted route_favorites records';
END $$;

-- =====================================================
-- Step 5: Insert pin_bookmarks test data
-- =====================================================
DO $$
DECLARE
  user1_id UUID := 'a0000000-0000-0000-0000-000000000001'::UUID;
  user2_id UUID := 'a0000000-0000-0000-0000-000000000002'::UUID;
  user3_id UUID := 'a0000000-0000-0000-0000-000000000003'::UUID;
  pin1_id UUID;
  pin2_id UUID;
  pin3_id UUID;
BEGIN
  -- Get some route_pins
  SELECT id INTO pin1_id FROM route_pins ORDER BY created_at LIMIT 1;
  SELECT id INTO pin2_id FROM route_pins ORDER BY created_at OFFSET 1 LIMIT 1;
  SELECT id INTO pin3_id FROM route_pins ORDER BY created_at OFFSET 2 LIMIT 1;

  IF pin1_id IS NULL THEN
    RAISE NOTICE 'Warning: No route_pins found. Skipping pin_bookmarks insertion.';
    RETURN;
  END IF;

  -- User1 bookmarks pins 1 and 2
  INSERT INTO pin_bookmarks (user_id, pin_id, created_at)
  VALUES 
    (user1_id, pin1_id, NOW() - '2 days'::INTERVAL),
    (user1_id, pin2_id, NOW() - '1 day'::INTERVAL)
  ON CONFLICT (user_id, pin_id) DO NOTHING;

  -- User2 bookmarks pins 1 and 3
  IF pin3_id IS NOT NULL THEN
    INSERT INTO pin_bookmarks (user_id, pin_id, created_at)
    VALUES 
      (user2_id, pin1_id, NOW() - '3 days'::INTERVAL),
      (user2_id, pin3_id, NOW() - '1 day'::INTERVAL)
    ON CONFLICT (user_id, pin_id) DO NOTHING;
  ELSE
    INSERT INTO pin_bookmarks (user_id, pin_id, created_at)
    VALUES (user2_id, pin1_id, NOW() - '3 days'::INTERVAL)
    ON CONFLICT (user_id, pin_id) DO NOTHING;
  END IF;

  -- User3 bookmarks pin 1
  INSERT INTO pin_bookmarks (user_id, pin_id, created_at)
  VALUES (user3_id, pin1_id, NOW() - '4 days'::INTERVAL)
  ON CONFLICT (user_id, pin_id) DO NOTHING;

  RAISE NOTICE 'Inserted pin_bookmarks records';
END $$;

-- =====================================================
-- Step 6: Insert user_follows test data
-- =====================================================
DO $$
DECLARE
  user1_id UUID := 'a0000000-0000-0000-0000-000000000001'::UUID;
  user2_id UUID := 'a0000000-0000-0000-0000-000000000002'::UUID;
  user3_id UUID := 'a0000000-0000-0000-0000-000000000003'::UUID;
BEGIN
  -- User1 follows User2 and User3
  INSERT INTO user_follows (follower_id, following_id, created_at)
  VALUES 
    (user1_id, user2_id, NOW() - '5 days'::INTERVAL),
    (user1_id, user3_id, NOW() - '3 days'::INTERVAL)
  ON CONFLICT (follower_id, following_id) DO NOTHING;

  -- User2 follows User1 and User3
  INSERT INTO user_follows (follower_id, following_id, created_at)
  VALUES 
    (user2_id, user1_id, NOW() - '4 days'::INTERVAL),
    (user2_id, user3_id, NOW() - '2 days'::INTERVAL)
  ON CONFLICT (follower_id, following_id) DO NOTHING;

  -- User3 follows User1
  INSERT INTO user_follows (follower_id, following_id, created_at)
  VALUES 
    (user3_id, user1_id, NOW() - '6 days'::INTERVAL)
  ON CONFLICT (follower_id, following_id) DO NOTHING;

  RAISE NOTICE 'Inserted 5 user_follows records';
END $$;

-- =====================================================
-- Step 7: Insert notifications test data
-- =====================================================
DO $$
DECLARE
  user1_id UUID := 'a0000000-0000-0000-0000-000000000001'::UUID;
  user2_id UUID := 'a0000000-0000-0000-0000-000000000002'::UUID;
  user3_id UUID := 'a0000000-0000-0000-0000-000000000003'::UUID;
BEGIN
  -- Notification 1: User2 followed User1
  INSERT INTO notifications (id, user_id, type, title, message, is_read, created_at)
  VALUES (
    gen_random_uuid(),
    user1_id,
    'follow',
    '新しいフォロワー',
    'テストユーザー2さんがあなたをフォローしました',
    false,
    NOW() - '4 days'::INTERVAL
  );

  -- Notification 2: User3 followed User1
  INSERT INTO notifications (id, user_id, type, title, message, is_read, created_at)
  VALUES (
    gen_random_uuid(),
    user1_id,
    'follow',
    '新しいフォロワー',
    'テストユーザー3さんがあなをフォローしました',
    true, -- Already read
    NOW() - '6 days'::INTERVAL
  );

  -- Notification 3: Badge unlock for User1
  INSERT INTO notifications (id, user_id, type, title, message, is_read, created_at)
  VALUES (
    gen_random_uuid(),
    user1_id,
    'badge_unlock',
    'バッジ獲得！',
    '「散歩デビュー（ブロンズ）」バッジを獲得しました',
    false,
    NOW() - '2 days'::INTERVAL
  );

  -- Notification 4: User1 followed User2
  INSERT INTO notifications (id, user_id, type, title, message, is_read, created_at)
  VALUES (
    gen_random_uuid(),
    user2_id,
    'follow',
    '新しいフォロワー',
    'テストユーザー1さんがあなたをフォローしました',
    false,
    NOW() - '5 days'::INTERVAL
  );

  -- Notification 5: Badge unlock for User2
  INSERT INTO notifications (id, user_id, type, title, message, is_read, created_at)
  VALUES (
    gen_random_uuid(),
    user2_id,
    'badge_unlock',
    'バッジ獲得！',
    '「散歩デビュー（ブロンズ）」バッジを獲得しました',
    true,
    NOW() - '3 days'::INTERVAL
  );

  RAISE NOTICE 'Inserted 5 notifications';
END $$;

-- =====================================================
-- Step 8: Trigger automatic badge unlocks
-- =====================================================
DO $$
DECLARE
  user1_id UUID := 'a0000000-0000-0000-0000-000000000001'::UUID;
  user2_id UUID := 'a0000000-0000-0000-0000-000000000002'::UUID;
  user3_id UUID := 'a0000000-0000-0000-0000-000000000003'::UUID;
BEGIN
  -- Check and unlock badges for all test users
  PERFORM check_and_unlock_badges(user1_id);
  PERFORM check_and_unlock_badges(user2_id);
  PERFORM check_and_unlock_badges(user3_id);

  RAISE NOTICE 'Triggered badge checks for all test users';
END $$;

-- Commit transaction
COMMIT;

-- =====================================================
-- Verification queries
-- =====================================================
SELECT 'Test users created:' AS status, COUNT(*) AS count FROM users WHERE email LIKE 'test%@example.com';
SELECT 'Daily walks inserted:' AS status, COUNT(*) AS count FROM daily_walks WHERE user_id IN (
  SELECT id FROM users WHERE email LIKE 'test%@example.com'
);
SELECT 'Route pins inserted:' AS status, COUNT(*) AS count FROM route_pins WHERE user_id IN (
  SELECT id FROM users WHERE email LIKE 'test%@example.com'
);
SELECT 'Route favorites:' AS status, COUNT(*) AS count FROM route_favorites WHERE user_id IN (
  SELECT id FROM users WHERE email LIKE 'test%@example.com'
);
SELECT 'Pin bookmarks:' AS status, COUNT(*) AS count FROM pin_bookmarks WHERE user_id IN (
  SELECT id FROM users WHERE email LIKE 'test%@example.com'
);
SELECT 'User follows:' AS status, COUNT(*) AS count FROM user_follows WHERE follower_id IN (
  SELECT id FROM users WHERE email LIKE 'test%@example.com'
);
SELECT 'Notifications:' AS status, COUNT(*) AS count FROM notifications WHERE user_id IN (
  SELECT id FROM users WHERE email LIKE 'test%@example.com'
);
SELECT 'Badges unlocked:' AS status, COUNT(*) AS count FROM user_badges WHERE user_id IN (
  SELECT id FROM users WHERE email LIKE 'test%@example.com'
);

RAISE NOTICE '========================================';
RAISE NOTICE 'Phase 5 Test Data - Part 3/3 Complete!';
RAISE NOTICE '========================================';
