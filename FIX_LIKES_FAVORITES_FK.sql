-- =====================================================
-- likes と favorites テーブルの外部キー制約を修正
-- =====================================================
-- 問題: likesとfavoritesがdaily_walksを参照している
-- 解決: 外部キー制約を削除して、routesを参照するように修正
-- =====================================================

BEGIN;

-- =====================================================
-- 1. likesテーブルの外部キー制約を修正
-- =====================================================

-- 既存の誤った外部キー制約を削除
ALTER TABLE public.likes 
DROP CONSTRAINT IF EXISTS likes_route_id_fkey;

-- 正しい外部キー制約を追加（routes テーブルを参照）
ALTER TABLE public.likes
ADD CONSTRAINT likes_route_id_fkey 
FOREIGN KEY (route_id) REFERENCES public.routes(id) ON DELETE CASCADE;

-- =====================================================
-- 2. favoritesテーブルの外部キー制約を修正
-- =====================================================

-- 既存の誤った外部キー制約を削除
ALTER TABLE public.favorites 
DROP CONSTRAINT IF EXISTS favorites_route_id_fkey;

-- 正しい外部キー制約を追加（routes テーブルを参照）
ALTER TABLE public.favorites
ADD CONSTRAINT favorites_route_id_fkey 
FOREIGN KEY (route_id) REFERENCES public.routes(id) ON DELETE CASCADE;

COMMIT;

-- =====================================================
-- 検証クエリ
-- =====================================================
SELECT
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name IN ('likes', 'favorites')
ORDER BY tc.table_name, kcu.column_name;
