-- ============================================================
-- WanMap v2 データベース構造確認クエリ
-- ============================================================
-- このクエリをSupabase SQL Editorで実行してください
-- 実行後、結果を確認して現在のテーブル状態を把握します
-- ============================================================

-- ■ 1. 全テーブル一覧
SELECT 
    '=== 全テーブル一覧 ===' AS section,
    tablename,
    schemaname
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- ■ 2. areas テーブルの確認
SELECT 
    '=== areasテーブル ===' AS section,
    COUNT(*) as total_areas,
    CASE 
        WHEN COUNT(*) = 0 THEN '❌ データなし - 投入が必要'
        ELSE '✅ データあり'
    END as status
FROM areas;

-- 既存のareasデータを表示
SELECT 
    id,
    name,
    description,
    center_latitude,
    center_longitude
FROM areas
LIMIT 5;

-- ■ 3. official_routes テーブルの確認
SELECT 
    '=== official_routesテーブル ===' AS section,
    COUNT(*) as total_routes,
    CASE 
        WHEN COUNT(*) = 0 THEN '❌ データなし - 投入が必要'
        ELSE '✅ データあり'
    END as status
FROM official_routes;

-- 既存のルートデータを表示
SELECT 
    id,
    name,
    area_id,
    difficulty_level,
    distance_meters,
    estimated_minutes
FROM official_routes
LIMIT 5;

-- ■ 4. official_route_points テーブルの確認
SELECT 
    '=== official_route_pointsテーブル ===' AS section,
    COUNT(*) as total_points,
    CASE 
        WHEN COUNT(*) = 0 THEN '❌ データなし - 投入が必要'
        ELSE '✅ データあり'
    END as status
FROM official_route_points;

-- ■ 5. walks テーブルの確認（散歩履歴）
SELECT 
    '=== walksテーブル ===' AS section,
    COUNT(*) as total_walks,
    CASE 
        WHEN COUNT(*) = 0 THEN 'ℹ️ 散歩履歴なし（これは正常です）'
        ELSE '✅ 散歩履歴あり'
    END as status
FROM walks;

-- ■ 6. walk_photos テーブルの確認
SELECT 
    '=== walk_photosテーブル ===' AS section,
    EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'walk_photos'
    ) AS table_exists,
    CASE 
        WHEN EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = 'walk_photos'
        ) THEN '✅ テーブル存在'
        ELSE '❌ テーブル未作成 - マイグレーション005が必要'
    END as status;

-- ■ 7. profiles テーブルの確認
SELECT 
    '=== profilesテーブル ===' AS section,
    COUNT(*) as total_profiles
FROM profiles;

-- ■ 8. Storage Buckets の確認
SELECT 
    '=== Storage Buckets ===' AS section,
    id as bucket_id,
    name as bucket_name,
    public as is_public,
    CASE 
        WHEN name = 'walk-photos' THEN '✅ Phase3用バケット'
        WHEN name = 'route-photos' THEN '✅ ルート写真用'
        WHEN name = 'pin_photos' THEN '✅ ピン写真用'
        ELSE 'ℹ️ その他のバケット'
    END as usage
FROM storage.buckets
ORDER BY name;

-- ============================================================
-- 確認すべきポイント:
-- ============================================================
-- 1. areas テーブル: データがあるか？
--    → なければ、005_insert_initial_data.sql を実行
-- 
-- 2. official_routes テーブル: データがあるか？
--    → なければ、005_insert_initial_data.sql を実行
--
-- 3. walk_photos テーブル: 存在するか？
--    → なければ、database_migrations/005_walk_photos_table.sql を実行
--
-- 4. Storage Buckets: walk-photos バケットが存在するか？
--    → なければ、database_migrations/007_walk_photos_storage_bucket.sql を実行
-- ============================================================
