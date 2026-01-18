-- get_recent_pins RPC関数が参照する可能性のあるテーブルを確認

-- 1. profiles テーブルの構造（ユーザー名取得用）
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
ORDER BY ordinal_position;

-- 2. photos テーブルの構造（写真URL取得用）
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'photos'
ORDER BY ordinal_position;

-- 3. areas テーブルの構造（エリア名取得用）
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'areas'
ORDER BY ordinal_position;

-- 4. official_routes テーブルの構造（ルート情報取得用）
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'official_routes'
ORDER BY ordinal_position;

-- 5. テーブル間の関連を確認（外部キー）
SELECT
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name,
  tc.constraint_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name IN ('route_pins', 'photos', 'profiles', 'official_routes')
ORDER BY tc.table_name, kcu.column_name;
