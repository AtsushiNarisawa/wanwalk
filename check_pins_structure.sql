-- pins テーブルの詳細情報を確認（別の方法）
SELECT 
  table_name,
  column_name,
  data_type,
  character_maximum_length,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'pins'
ORDER BY ordinal_position;

-- pins テーブルの制約を確認
SELECT
  conname AS constraint_name,
  contype AS constraint_type,
  pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.pins'::regclass;

-- 既存のピンデータを確認（最初の5件）
SELECT 
  id,
  user_id,
  title,
  description,
  location,
  created_at
FROM pins
LIMIT 5;
