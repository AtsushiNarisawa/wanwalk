-- ============================================================================
-- walksテーブルの存在確認
-- ============================================================================

-- 1. walksテーブルが存在するか
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'walks') 
    THEN '✅ walks テーブルは存在します'
    ELSE '❌ walks テーブルは存在しません'
  END AS walks_exists;

-- 2. walksテーブルのカラム一覧
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'walks'
ORDER BY ordinal_position;

-- 3. walksテーブルのトリガー一覧
SELECT trigger_name, event_manipulation, event_object_table
FROM information_schema.triggers
WHERE event_object_table = 'walks';

-- 4. walksテーブルのデータ数
SELECT COUNT(*) as row_count FROM walks;
