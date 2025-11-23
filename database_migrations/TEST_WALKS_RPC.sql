-- ============================================================================
-- walksテーブルとRPC関数のテスト
-- ============================================================================

-- 1. テストユーザーのIDを取得
SELECT id, email FROM auth.users LIMIT 3;

-- 2. walksテーブルのデータを確認
SELECT 
  id,
  user_id,
  walk_type,
  start_time,
  distance_meters,
  duration_seconds,
  comment
FROM walks
ORDER BY start_time DESC
LIMIT 5;

-- 3. get_user_walk_statistics関数のテスト
-- 注意: 下記の 'USER_ID_HERE' を実際のユーザーIDに置き換えてください
-- SELECT * FROM get_user_walk_statistics('USER_ID_HERE');

-- 4. get_daily_walk_history関数のテスト
-- 注意: 下記の 'USER_ID_HERE' を実際のユーザーIDに置き換えてください
-- SELECT * FROM get_daily_walk_history('USER_ID_HERE', 10, 0);

-- 5. get_outing_walk_history関数のテスト
-- 注意: 下記の 'USER_ID_HERE' を実際のユーザーIDに置き換えてください
-- SELECT * FROM get_outing_walk_history('USER_ID_HERE', 10, 0);
