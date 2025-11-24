-- ============================================================
-- 実際のテーブル構造を確認するクエリ
-- ============================================================

-- ■ 1. 全テーブル一覧
SELECT 
    tablename
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- ■ 2. areas テーブルのカラム構造
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'areas'
ORDER BY ordinal_position;

-- ■ 3. official_routes テーブルのカラム構造
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'official_routes'
ORDER BY ordinal_position;

-- ■ 4. areasテーブルの既存データ件数
SELECT COUNT(*) as areas_count FROM areas;

-- ■ 5. official_routesテーブルの既存データ件数
SELECT COUNT(*) as routes_count FROM official_routes;

-- ■ 6. areasテーブルの既存データをすべて表示
SELECT * FROM areas LIMIT 10;

-- ■ 7. official_routesテーブルの既存データをすべて表示
SELECT * FROM official_routes LIMIT 10;
