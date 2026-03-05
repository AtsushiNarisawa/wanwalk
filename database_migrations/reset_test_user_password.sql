-- ===============================================
-- テストユーザーのパスワードリセット
-- ===============================================
-- このSQLは直接実行できません
-- Supabase Dashboardから手動でパスワードをリセットしてください
--
-- 実行手順:
-- 1. https://supabase.com/dashboard にアクセス
-- 2. WanWalkプロジェクトを選択
-- 3. 左サイドバー → Authentication → Users
-- 4. test1@example.com をクリック
-- 5. 画面右上の "..." メニュー → "Send password reset email" または "Update user"
-- 6. "Update user" を選択した場合:
--    - New Password: test1234
--    - ☑️ Auto Confirm User
--    - "Update user" をクリック
--
-- または、以下の方法でユーザーを再作成:
-- 1. test1@example.com を削除（Delete user）
-- 2. 新しく作成（Add user）
--    - Email: test1@example.com
--    - Password: test1234
--    - ☑️ Auto Confirm User
-- ===============================================

-- 参考: ユーザーのauth設定を確認するクエリ
SELECT 
  id,
  email,
  encrypted_password IS NOT NULL as has_password,
  email_confirmed_at IS NOT NULL as email_confirmed,
  confirmation_token,
  recovery_token,
  email_change_token_current,
  banned_until,
  deleted_at
FROM auth.users
WHERE email = 'test1@example.com';
