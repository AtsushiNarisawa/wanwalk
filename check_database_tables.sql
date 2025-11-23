-- 現在のデータベースに存在するテーブルを確認
SELECT 
    schemaname,
    tablename,
    tableowner
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- dogs テーブルの存在確認
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'dogs'
) AS dogs_exists;

-- profiles テーブルの存在確認
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'profiles'
) AS profiles_exists;

-- route_favorites テーブルの存在確認
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'route_favorites'
) AS route_favorites_exists;

-- walks テーブルの存在確認と行数
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'walks'
) AS walks_exists;

SELECT COUNT(*) as walks_row_count FROM walks;
