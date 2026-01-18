-- route_pins テーブルのカラム構造を確認
SELECT 
  column_name,
  data_type,
  character_maximum_length,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'route_pins'
ORDER BY ordinal_position;
