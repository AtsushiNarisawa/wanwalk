-- ============================================================================
-- データベース分析サマリー（1つのクエリで全て表示）
-- ============================================================================

SELECT 
  'follow_stats' AS table_name,
  COUNT(*) AS row_count
FROM follow_stats

UNION ALL

SELECT 
  'route_pins' AS table_name,
  COUNT(*) AS row_count
FROM route_pins

UNION ALL

SELECT 
  'routes' AS table_name,
  COUNT(*) AS row_count
FROM routes

UNION ALL

SELECT 
  'official_routes' AS table_name,
  COUNT(*) AS row_count
FROM official_routes

UNION ALL

SELECT 
  'follows' AS table_name,
  COUNT(*) AS row_count
FROM follows

UNION ALL

SELECT 
  'user_follows' AS table_name,
  COUNT(*) AS row_count
FROM user_follows

UNION ALL

SELECT 
  'likes' AS table_name,
  COUNT(*) AS row_count
FROM likes

UNION ALL

SELECT 
  'route_likes' AS table_name,
  COUNT(*) AS row_count
FROM route_likes

UNION ALL

SELECT 
  'pin_likes' AS table_name,
  COUNT(*) AS row_count
FROM pin_likes

UNION ALL

SELECT 
  'badges' AS table_name,
  COUNT(*) AS row_count
FROM badges

UNION ALL

SELECT 
  'badge_definitions' AS table_name,
  COUNT(*) AS row_count
FROM badge_definitions

UNION ALL

SELECT 
  'user_badges' AS table_name,
  COUNT(*) AS row_count
FROM user_badges

UNION ALL

SELECT 
  'favorites' AS table_name,
  COUNT(*) AS row_count
FROM favorites

UNION ALL

SELECT 
  'route_favorites' AS table_name,
  COUNT(*) AS row_count
FROM route_favorites

ORDER BY table_name;
