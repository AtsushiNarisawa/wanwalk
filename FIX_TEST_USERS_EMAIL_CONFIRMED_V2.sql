-- =====================================================
-- テストユーザーのメール確認状態とパスワードを修正 V2
-- =====================================================
-- confirmed_at は生成カラムなので除外
-- =====================================================

BEGIN;

-- =====================================================
-- 1. メール確認状態を有効化（confirmed_at除外）
-- =====================================================

-- test1@example.com
UPDATE auth.users
SET 
  email_confirmed_at = NOW(),
  encrypted_password = crypt('password123', gen_salt('bf')),
  updated_at = NOW(),
  raw_user_meta_data = jsonb_build_object(
    'email', 'test1@example.com',
    'email_verified', true,
    'phone_verified', false
  )
WHERE email = 'test1@example.com';

-- test2@example.com
UPDATE auth.users
SET 
  email_confirmed_at = NOW(),
  encrypted_password = crypt('password123', gen_salt('bf')),
  updated_at = NOW(),
  raw_user_meta_data = jsonb_build_object(
    'email', 'test2@example.com',
    'email_verified', true,
    'phone_verified', false
  )
WHERE email = 'test2@example.com';

-- test3@example.com
UPDATE auth.users
SET 
  email_confirmed_at = NOW(),
  encrypted_password = crypt('password123', gen_salt('bf')),
  updated_at = NOW(),
  raw_user_meta_data = jsonb_build_object(
    'email', 'test3@example.com',
    'email_verified', true,
    'phone_verified', false
  )
WHERE email = 'test3@example.com';

COMMIT;

-- =====================================================
-- 検証クエリ
-- =====================================================
SELECT 
  email,
  encrypted_password IS NOT NULL as has_password,
  confirmed_at IS NOT NULL as is_confirmed,
  email_confirmed_at IS NOT NULL as email_confirmed,
  raw_user_meta_data->>'email_verified' as email_verified,
  created_at,
  updated_at
FROM auth.users 
WHERE email IN ('test1@example.com', 'test2@example.com', 'test3@example.com')
ORDER BY email;
