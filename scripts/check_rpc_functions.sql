-- Supabaseに存在するRPC関数を確認するSQL
-- get_recent_pins 関数が存在するかチェック

-- 1. すべてのRPC関数をリストアップ
SELECT 
  routine_name AS function_name,
  routine_type AS type,
  routine_definition AS definition
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_type = 'FUNCTION'
ORDER BY routine_name;

-- 2. get_recent_pins 関数の詳細を確認
SELECT 
  routine_name,
  routine_type,
  data_type AS return_type,
  routine_definition
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name = 'get_recent_pins';

-- 3. get_recent_pins 関数のパラメータを確認
SELECT 
  parameter_name,
  data_type,
  parameter_mode
FROM information_schema.parameters
WHERE specific_schema = 'public'
  AND specific_name LIKE '%get_recent_pins%'
ORDER BY ordinal_position;
