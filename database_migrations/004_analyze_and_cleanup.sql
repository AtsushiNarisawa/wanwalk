-- ============================================================================
-- データベース分析とクリーンアップスクリプト
-- ============================================================================
-- 目的: 不要なテーブルを特定し、削除候補をリストアップ
-- 実行方法: Supabase Dashboard > SQL Editor で実行
-- ============================================================================

-- 1. 存在するテーブルのみ調査
-- follow_stats テーブルの内容確認
SELECT 'follow_stats テーブルの行数:' AS info, COUNT(*) AS row_count FROM follow_stats;

-- route_pins テーブルの内容確認
SELECT 'route_pins テーブルの行数:' AS info, COUNT(*) AS row_count FROM route_pins;

-- routes テーブルの内容確認
SELECT 'routes テーブルの行数:' AS info, COUNT(*) AS row_count FROM routes;

-- 2. 重複・古いテーブルの確認
-- official_routes と routes の関係確認
SELECT 'official_routes テーブルの行数:' AS info, COUNT(*) AS row_count FROM official_routes;

-- follows と user_follows の関係確認
SELECT 'follows テーブルの行数:' AS info, COUNT(*) AS row_count FROM follows;
SELECT 'user_follows テーブルの行数:' AS info, COUNT(*) AS row_count FROM user_follows;

-- likes と route_likes の関係確認
SELECT 'likes テーブルの行数:' AS info, COUNT(*) AS row_count FROM likes;
SELECT 'route_likes テーブルの行数:' AS info, COUNT(*) AS row_count FROM route_likes;

-- pin_likes テーブルの確認
SELECT 'pin_likes テーブルの行数:' AS info, COUNT(*) AS row_count FROM pin_likes;

-- 3. badge関連テーブルの確認
SELECT 'badges テーブルの行数:' AS info, COUNT(*) AS row_count FROM badges;
SELECT 'badge_definitions テーブルの行数:' AS info, COUNT(*) AS row_count FROM badge_definitions;
SELECT 'user_badges テーブルの行数:' AS info, COUNT(*) AS row_count FROM user_badges;

-- 4. その他のテーブル
SELECT 'favorites テーブルの行数:' AS info, COUNT(*) AS row_count FROM favorites;
SELECT 'route_favorites テーブルの行数:' AS info, COUNT(*) AS row_count FROM route_favorites;

-- ============================================================================
-- 実行結果を確認してから、次のステップで削除候補を提案します
-- ============================================================================
