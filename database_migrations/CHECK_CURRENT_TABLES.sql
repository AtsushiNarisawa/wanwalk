-- ============================================================================
-- データベース現状確認スクリプト
-- ============================================================================
-- 目的: Phase 1実装前に現在のテーブル状況を確認
-- 実行方法: Supabase Dashboard > SQL Editor で実行
-- ============================================================================

-- 1. 全テーブル一覧を表示
SELECT 
  table_name,
  CASE 
    WHEN table_name = 'walks' THEN '✅ Phase 1-1'
    WHEN table_name = 'route_pins' THEN '✅ Phase 1-2'
    WHEN table_name = 'route_pin_photos' THEN '✅ Phase 1-2'
    WHEN table_name = 'pin_likes' THEN '✅ Phase 1-2'
    WHEN table_name = 'walk_photos' THEN '✅ Phase 1-3'
    WHEN table_name = 'comments' THEN '✅ Phase 1-4'
    WHEN table_name = 'notifications' THEN '✅ Phase 1-5'
    WHEN table_name = 'profiles' THEN '✅ Phase 1-6'
    WHEN table_name = 'dogs' THEN '✅ Phase 1-7'
    ELSE '❓ その他'
  END AS phase_status
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- 2. walks テーブルの確認
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'walks') 
    THEN '✅ walks テーブルは存在します'
    ELSE '❌ walks テーブルは存在しません - 001_walks_table_v4.sql を実行してください'
  END AS walks_status;

-- 3. route_pins テーブルの確認
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'route_pins') 
    THEN '✅ route_pins テーブルは存在します'
    ELSE '❌ route_pins テーブルは存在しません - 002_pins_table_v1.sql を実行してください'
  END AS pins_status;

-- 4. dogs テーブルの確認
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'dogs') 
    THEN '✅ dogs テーブルは存在します'
    ELSE '❌ dogs テーブルは存在しません - dogs テーブル作成が必要です'
  END AS dogs_status;

-- 5. notifications テーブルの確認
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notifications') 
    THEN '✅ notifications テーブルは存在します'
    ELSE '❌ notifications テーブルは存在しません - notifications テーブル作成が必要です'
  END AS notifications_status;

-- 6. PostGIS拡張の確認
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgis') 
    THEN '✅ PostGIS 拡張は有効です'
    ELSE '❌ PostGIS 拡張が無効です - CREATE EXTENSION postgis; を実行してください'
  END AS postgis_status;

-- 7. 古いテーブルの存在確認（削除されているべき）
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'daily_walks') 
    THEN '⚠️ daily_walks テーブルがまだ存在します - 003_drop_old_tables.sql を実行してください'
    ELSE '✅ daily_walks テーブルは削除済みです'
  END AS old_daily_walks_status;

SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'route_walks') 
    THEN '⚠️ route_walks テーブルがまだ存在します - 003_drop_old_tables.sql を実行してください'
    ELSE '✅ route_walks テーブルは削除済みです'
  END AS old_route_walks_status;

-- ============================================================================
-- 実行結果の見方:
-- - ✅: 正常に作成済み
-- - ❌: 未作成（マイグレーション実行が必要）
-- - ⚠️: 古いテーブルが残っている（削除推奨）
-- ============================================================================
