-- =====================================================
-- 欠落テーブルの修正 - WanMap データベース同期
-- =====================================================
-- 実行前の状態: routes, route_points, profiles などが欠落
-- 実行後の状態: すべての必要なテーブルが作成される
-- =====================================================

BEGIN;

-- =====================================================
-- 1. profiles テーブル（ユーザープロフィール）
-- 注意: 既存のusersテーブルと統合する必要がある
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

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "Anyone can view profiles" ON public.profiles
  FOR SELECT USING (true);

CREATE POLICY IF NOT EXISTS "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY IF NOT EXISTS "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

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

ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "Users can view own routes" ON public.routes
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can view public routes" ON public.routes
  FOR SELECT USING (is_public = true);

CREATE POLICY IF NOT EXISTS "Users can manage own routes" ON public.routes
  FOR ALL USING (auth.uid() = user_id);

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

ALTER TABLE public.route_points ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "Users can view route points" ON public.route_points
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.routes
      WHERE routes.id = route_points.route_id
      AND (routes.user_id = auth.uid() OR routes.is_public = true)
    )
  );

CREATE POLICY IF NOT EXISTS "Users can manage own route points" ON public.route_points
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.routes
      WHERE routes.id = route_points.route_id
      AND routes.user_id = auth.uid()
    )
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

ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "Users can view follows" ON public.follows
  FOR SELECT USING (true);

CREATE POLICY IF NOT EXISTS "Users can manage own follows" ON public.follows
  FOR ALL USING (auth.uid() = follower_id);

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

ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "Users can view likes" ON public.likes
  FOR SELECT USING (true);

CREATE POLICY IF NOT EXISTS "Users can manage own likes" ON public.likes
  FOR ALL USING (auth.uid() = user_id);

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

ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "Users can view own favorites" ON public.favorites
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can manage own favorites" ON public.favorites
  FOR ALL USING (auth.uid() = user_id);

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
