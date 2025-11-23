-- =====================================================
-- テストユーザーのパスワードをリセット
-- =====================================================
-- test1, test2, test3 のパスワードを "password123" に設定
-- Supabase Dashboardから実行してください
-- =====================================================

-- 注意: このSQLはSupabase DashboardのSQL Editorから実行してください
-- Supabaseの内部関数を使用してパスワードをハッシュ化します

-- =====================================================
-- 方法1: Supabase Dashboardの認証機能を使う（推奨）
-- =====================================================
-- 1. Supabase Dashboard → Authentication → Users
-- 2. test1@example.com を探す
-- 3. 右側の「...」メニュー → "Send password recovery email"
-- 4. または "Reset password" を選択

-- =====================================================
-- 方法2: SQLでパスワードをリセット（上級者向け）
-- =====================================================
-- 注意: この方法はSupabaseの内部APIを使用します

-- test1@example.com のパスワードを更新
UPDATE auth.users
SET 
  encrypted_password = crypt('password123', gen_salt('bf')),
  updated_at = NOW()
WHERE email = 'test1@example.com';

-- test2@example.com のパスワードを更新
UPDATE auth.users
SET 
  encrypted_password = crypt('password123', gen_salt('bf')),
  updated_at = NOW()
WHERE email = 'test2@example.com';

-- test3@example.com のパスワードを更新
UPDATE auth.users
SET 
  encrypted_password = crypt('password123', gen_salt('bf')),
  updated_at = NOW()
WHERE email = 'test3@example.com';

-- =====================================================
-- 検証クエリ
-- =====================================================
SELECT 
  email,
  encrypted_password IS NOT NULL as has_password,
  confirmed_at IS NOT NULL as is_confirmed,
  email_confirmed_at IS NOT NULL as email_confirmed,
  created_at,
  updated_at
FROM auth.users 
WHERE email IN ('test1@example.com', 'test2@example.com', 'test3@example.com')
ORDER BY email;
