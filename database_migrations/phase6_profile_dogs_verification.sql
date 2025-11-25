-- ============================================================================
-- Phase 6: プロフィール・愛犬管理機能の検証SQL
-- ============================================================================
-- このSQLは既存のテーブル・バケット・RLSポリシーが正しく設定されているか確認します
-- Supabase SQLエディタで実行してください

-- 1. profilesテーブルの存在確認
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'profiles'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. dogsテーブルの存在確認
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'dogs'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Storageバケットの存在確認
SELECT 
  id,
  name,
  public
FROM storage.buckets
WHERE name IN ('profile-avatars', 'dog-photos');

-- 4. profilesテーブルのRLSポリシー確認
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'profiles';

-- 5. dogsテーブルのRLSポリシー確認
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'dogs';

-- ============================================================================
-- 以下は、テーブル・バケット・ポリシーが存在しない場合の作成SQL
-- ============================================================================

-- profilesテーブルが存在しない場合の作成
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  bio TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- dogsテーブルが存在しない場合の作成
CREATE TABLE IF NOT EXISTS public.dogs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  breed TEXT,
  size TEXT CHECK (size IN ('small', 'medium', 'large')),
  birth_date DATE,
  weight DECIMAL(5,2),
  photo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- インデックス作成
CREATE INDEX IF NOT EXISTS idx_dogs_user_id ON public.dogs(user_id);
CREATE INDEX IF NOT EXISTS idx_dogs_created_at ON public.dogs(created_at DESC);

-- RLS有効化
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dogs ENABLE ROW LEVEL SECURITY;

-- profilesテーブルのRLSポリシー
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
CREATE POLICY "Users can view their own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- dogsテーブルのRLSポリシー
DROP POLICY IF EXISTS "Users can view their own dogs" ON public.dogs;
CREATE POLICY "Users can view their own dogs"
  ON public.dogs FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own dogs" ON public.dogs;
CREATE POLICY "Users can insert their own dogs"
  ON public.dogs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own dogs" ON public.dogs;
CREATE POLICY "Users can update their own dogs"
  ON public.dogs FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own dogs" ON public.dogs;
CREATE POLICY "Users can delete their own dogs"
  ON public.dogs FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- Storageバケットとポリシー設定（Supabase UIで手動作成を推奨）
-- ============================================================================
-- 以下のバケットをSupabase Dashboard > Storage で作成してください：
--
-- 1. profile-avatars
--    - Public: true
--    - File size limit: 5MB
--    - Allowed MIME types: image/*
--
-- 2. dog-photos
--    - Public: true
--    - File size limit: 5MB
--    - Allowed MIME types: image/*
--
-- RLSポリシー設定（各バケットに適用）:
--
-- SELECT (閲覧):
--   - Everyone can view public files
--   - Policy: bucket_id = 'bucket-name'
--
-- INSERT (アップロード):
--   - Authenticated users can upload their own files
--   - Policy: bucket_id = 'bucket-name' AND auth.uid()::text = (storage.foldername(name))[1]
--
-- UPDATE/DELETE:
--   - Users can modify their own files
--   - Policy: bucket_id = 'bucket-name' AND auth.uid()::text = (storage.foldername(name))[1]

-- ============================================================================
-- 確認クエリ: 正しく設定されているか最終確認
-- ============================================================================
-- profilesテーブルのサンプル挿入テスト（実際のauth.usersが必要）
-- INSERT INTO public.profiles (id, email, display_name) VALUES 
--   ((SELECT id FROM auth.users LIMIT 1), 'test@example.com', 'テストユーザー');

-- dogsテーブルのサンプル挿入テスト
-- INSERT INTO public.dogs (user_id, name, breed, size) VALUES 
--   ((SELECT id FROM auth.users LIMIT 1), 'ポチ', '柴犬', 'medium');
