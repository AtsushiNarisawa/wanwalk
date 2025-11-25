-- ===============================================
-- テストユーザーの存在確認
-- ===============================================
-- このSQLをSupabase Dashboard → SQL Editorで実行してください
--
-- 実行手順:
-- 1. https://supabase.com/dashboard にアクセス
-- 2. WanMapプロジェクトを選択
-- 3. 左サイドバー → SQL Editor
-- 4. このSQLをコピー&ペースト
-- 5. Runをクリック
--
-- 確認事項:
-- - test1@example.comが存在するか
-- - email_confirmed_atがNULLでないか（メール確認済み）
-- - banned_untilがNULLか（アカウント停止されていないか）
-- ===============================================

-- test1@example.comのアカウント情報を確認
SELECT 
  id,
  email,
  created_at,
  email_confirmed_at,
  banned_until,
  deleted_at,
  last_sign_in_at
FROM auth.users
WHERE email = 'test1@example.com';

-- すべてのテストアカウントを確認
SELECT 
  id,
  email,
  created_at,
  email_confirmed_at,
  banned_until,
  deleted_at,
  last_sign_in_at
FROM auth.users
WHERE email LIKE 'test%@example.com'
ORDER BY email;

-- アカウント総数を確認
SELECT COUNT(*) as total_users
FROM auth.users;
