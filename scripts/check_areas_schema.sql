-- 1. areasテーブルの全カラムを確認
SELECT column_name, data_type, udt_name
FROM information_schema.columns
WHERE table_name = 'areas'
ORDER BY ordinal_position;

-- 2. areasテーブルの実際のデータを確認
SELECT * FROM areas LIMIT 3;

-- 3. get_areas_simple関数の定義を確認（存在する場合）
SELECT routine_name, routine_definition
FROM information_schema.routines
WHERE routine_name = 'get_areas_simple';
