-- route_pins テーブルの構造を確認するSQL

-- 1. route_pins テーブルのカラム一覧
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default,
  character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'route_pins'
ORDER BY ordinal_position;

-- 2. route_pins テーブルの制約条件
SELECT
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.table_schema = 'public'
  AND tc.table_name = 'route_pins';

-- 3. route_pins テーブルのインデックス
SELECT
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'route_pins';

-- 4. route_pins テーブルのサンプルデータ（最新3件）
SELECT 
  id,
  user_id,
  route_id,
  pin_type,
  title,
  comment,
  likes_count,
  comments_count,
  facility_info,
  is_official,
  created_at
FROM route_pins
ORDER BY created_at DESC
LIMIT 3;
