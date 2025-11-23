-- =====================================================
-- 欠落テーブルの修正 - WanMap データベース同期
-- =====================================================
-- ポリシーなしバージョン（テーブル作成のみ）
-- RLSポリシーは後でSupabase Dashboardから設定
-- =====================================================

BEGIN;

-- =====================================================
-- 1. profiles テーブル（ユーザープロフィール）
-- =====================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  display_name TEXT,
  bio TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 既存のusersテーブルからprofilesへデータをコピー
INSERT INTO public.profiles (id, email, display_name, created_at, updated_at)
SELECT id, email, display_name, created_at, updated_at
FROM public.users
ON CONFLICT (id) DO UPDATE 
SET display_name = EXCLUDED.display_name,
    updated_at = EXCLUDED.updated_at;

-- =====================================================
-- 2. routes テーブル（ユーザーが作成した散歩ルート）
-- =====================================================
CREATE TABLE IF NOT EXISTS public.routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  dog_id UUID REFERENCES public.dogs(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  distance NUMERIC NOT NULL DEFAULT 0,
  duration INTEGER NOT NULL DEFAULT 0,
  started_at TIMESTAMP WITH TIME ZONE NOT NULL,
  ended_at TIMESTAMP WITH TIME ZONE,
  is_public BOOLEAN DEFAULT false,
  area TEXT,
  prefecture TEXT,
  thumbnail_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 3. route_points テーブル（routesのGPS座標）
-- =====================================================
CREATE TABLE IF NOT EXISTS public.route_points (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  latitude NUMERIC NOT NULL,
  longitude NUMERIC NOT NULL,
  altitude NUMERIC,
  accuracy NUMERIC,
  speed NUMERIC,
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
  sequence_number INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 4. follows テーブル（ユーザーフォロー機能）
-- =====================================================
CREATE TABLE IF NOT EXISTS public.follows (
  follower_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (follower_id, following_id),
  CHECK (follower_id != following_id)
);

-- 既存のuser_followsからfollowsへデータをコピー
INSERT INTO public.follows (follower_id, following_id, created_at)
SELECT follower_id, following_id, created_at
FROM public.user_follows
ON CONFLICT (follower_id, following_id) DO NOTHING;

-- =====================================================
-- 5. likes テーブル（ルートいいね機能）
-- =====================================================
CREATE TABLE IF NOT EXISTS public.likes (
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (user_id, route_id)
);

-- 既存のroute_likesからlikesへデータをコピー
INSERT INTO public.likes (user_id, route_id, created_at)
SELECT user_id, route_id, created_at
FROM public.route_likes
ON CONFLICT (user_id, route_id) DO NOTHING;

-- =====================================================
-- 6. favorites テーブル（お気に入り機能）
-- =====================================================
CREATE TABLE IF NOT EXISTS public.favorites (
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (user_id, route_id)
);

-- 既存のroute_favoritesからfavoritesへデータをコピー
INSERT INTO public.favorites (user_id, route_id, created_at)
SELECT user_id, route_id, created_at
FROM public.route_favorites
ON CONFLICT (user_id, route_id) DO NOTHING;

-- =====================================================
-- 7. インデックスの作成
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_routes_user_id ON public.routes(user_id);
CREATE INDEX IF NOT EXISTS idx_routes_is_public ON public.routes(is_public);
CREATE INDEX IF NOT EXISTS idx_routes_created_at ON public.routes(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_route_points_route_id ON public.route_points(route_id);
CREATE INDEX IF NOT EXISTS idx_route_points_sequence ON public.route_points(route_id, sequence_number);
CREATE INDEX IF NOT EXISTS idx_follows_follower ON public.follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON public.follows(following_id);
CREATE INDEX IF NOT EXISTS idx_likes_route ON public.likes(route_id);
CREATE INDEX IF NOT EXISTS idx_favorites_user ON public.favorites(user_id);

COMMIT;

-- =====================================================
-- 検証クエリ
-- =====================================================
SELECT 'profiles' AS table_name, COUNT(*) AS count FROM public.profiles
UNION ALL
SELECT 'routes', COUNT(*) FROM public.routes
UNION ALL
SELECT 'route_points', COUNT(*) FROM public.route_points
UNION ALL
SELECT 'follows', COUNT(*) FROM public.follows
UNION ALL
SELECT 'likes', COUNT(*) FROM public.likes
UNION ALL
SELECT 'favorites', COUNT(*) FROM public.favorites;
