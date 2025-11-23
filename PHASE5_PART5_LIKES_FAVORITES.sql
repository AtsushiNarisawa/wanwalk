-- =====================================================
-- PHASE 5 PART 5: likes と favorites のテストデータ
-- =====================================================
-- ユーザー同士がルートに「いいね」や「お気に入り」を付ける
-- ソーシャル機能のテスト用データ
-- =====================================================

DO $$
DECLARE
  v_user1_id UUID;
  v_user2_id UUID;
  v_user3_id UUID;
  v_route_ids UUID[];
BEGIN

-- =====================================================
-- ユーザーIDを取得
-- =====================================================
SELECT id INTO v_user1_id FROM auth.users WHERE email = 'test1@example.com';
SELECT id INTO v_user2_id FROM auth.users WHERE email = 'test2@example.com';
SELECT id INTO v_user3_id FROM auth.users WHERE email = 'test3@example.com';

-- =====================================================
-- 公開ルートのIDを取得（他のユーザーが閲覧可能）
-- =====================================================
SELECT ARRAY_AGG(id) INTO v_route_ids
FROM public.routes
WHERE is_public = true;

-- =====================================================
-- likes（いいね）の作成
-- =====================================================

-- test1が他のユーザーの公開ルートに「いいね」
INSERT INTO public.likes (user_id, route_id, created_at)
SELECT 
  v_user1_id,
  id,
  NOW() - (RANDOM() * INTERVAL '5 days')
FROM public.routes
WHERE is_public = true 
  AND user_id != v_user1_id
LIMIT 4
ON CONFLICT (user_id, route_id) DO NOTHING;

-- test2が他のユーザーの公開ルートに「いいね」
INSERT INTO public.likes (user_id, route_id, created_at)
SELECT 
  v_user2_id,
  id,
  NOW() - (RANDOM() * INTERVAL '5 days')
FROM public.routes
WHERE is_public = true 
  AND user_id != v_user2_id
LIMIT 3
ON CONFLICT (user_id, route_id) DO NOTHING;

-- test3が他のユーザーの公開ルートに「いいね」
INSERT INTO public.likes (user_id, route_id, created_at)
SELECT 
  v_user3_id,
  id,
  NOW() - (RANDOM() * INTERVAL '5 days')
FROM public.routes
WHERE is_public = true 
  AND user_id != v_user3_id
LIMIT 5
ON CONFLICT (user_id, route_id) DO NOTHING;

-- =====================================================
-- favorites（お気に入り）の作成
-- =====================================================

-- test1が他のユーザーの公開ルートを「お気に入り」
INSERT INTO public.favorites (user_id, route_id, created_at)
SELECT 
  v_user1_id,
  id,
  NOW() - (RANDOM() * INTERVAL '5 days')
FROM public.routes
WHERE is_public = true 
  AND user_id != v_user1_id
LIMIT 2
ON CONFLICT (user_id, route_id) DO NOTHING;

-- test2が他のユーザーの公開ルートを「お気に入り」
INSERT INTO public.favorites (user_id, route_id, created_at)
SELECT 
  v_user2_id,
  id,
  NOW() - (RANDOM() * INTERVAL '5 days')
FROM public.routes
WHERE is_public = true 
  AND user_id != v_user2_id
LIMIT 3
ON CONFLICT (user_id, route_id) DO NOTHING;

-- test3が他のユーザーの公開ルートを「お気に入り」
INSERT INTO public.favorites (user_id, route_id, created_at)
SELECT 
  v_user3_id,
  id,
  NOW() - (RANDOM() * INTERVAL '5 days')
FROM public.routes
WHERE is_public = true 
  AND user_id != v_user3_id
LIMIT 2
ON CONFLICT (user_id, route_id) DO NOTHING;

END $$;

-- =====================================================
-- 検証クエリ
-- =====================================================

-- likesの件数確認
SELECT 
  u.email,
  COUNT(l.route_id) AS liked_routes
FROM public.profiles u
LEFT JOIN public.likes l ON u.id = l.user_id
WHERE u.email IN ('test1@example.com', 'test2@example.com', 'test3@example.com')
GROUP BY u.email
ORDER BY u.email;

-- favoritesの件数確認
SELECT 
  u.email,
  COUNT(f.route_id) AS favorite_routes
FROM public.profiles u
LEFT JOIN public.favorites f ON u.id = f.user_id
WHERE u.email IN ('test1@example.com', 'test2@example.com', 'test3@example.com')
GROUP BY u.email
ORDER BY u.email;

-- 各ルートの「いいね」数ランキング（上位10件）
SELECT 
  r.title,
  u.email AS owner,
  COUNT(l.user_id) AS like_count
FROM public.routes r
JOIN public.profiles u ON r.user_id = u.id
LEFT JOIN public.likes l ON r.id = l.route_id
WHERE r.is_public = true
GROUP BY r.id, r.title, u.email
ORDER BY like_count DESC, r.title
LIMIT 10;
