-- WanWalk 完全データベーススキーマ (Phase 1-24)
-- Supabase SQL Editorで実行してください
-- 既存のテーブルがある場合は影響しません (CREATE TABLE IF NOT EXISTS)

-- ============================================================
-- Phase 1-15: 基本テーブル
-- ============================================================

-- 1. profilesテーブル（ユーザープロフィール）
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

-- RLS Policies for profiles
DROP POLICY IF EXISTS "Anyone can view profiles" ON public.profiles;
CREATE POLICY "Anyone can view profiles" ON public.profiles
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- 2. dogsテーブル（犬の情報）
CREATE TABLE IF NOT EXISTS public.dogs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  breed TEXT,
  birth_date DATE,
  weight NUMERIC,
  photo_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.dogs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own dogs" ON public.dogs;
CREATE POLICY "Users can view own dogs" ON public.dogs
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own dogs" ON public.dogs;
CREATE POLICY "Users can manage own dogs" ON public.dogs
  FOR ALL USING (auth.uid() = user_id);

-- 3. routesテーブル（散歩ルート）
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
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own routes" ON public.routes;
CREATE POLICY "Users can view own routes" ON public.routes
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view public routes" ON public.routes;
CREATE POLICY "Users can view public routes" ON public.routes
  FOR SELECT USING (is_public = true);

DROP POLICY IF EXISTS "Users can manage own routes" ON public.routes;
CREATE POLICY "Users can manage own routes" ON public.routes
  FOR ALL USING (auth.uid() = user_id);

-- 4. route_pointsテーブル（GPS座標）
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

DROP POLICY IF EXISTS "Users can view own route points" ON public.route_points;
CREATE POLICY "Users can view own route points" ON public.route_points
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.routes 
      WHERE routes.id = route_points.route_id 
      AND routes.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can view public route points" ON public.route_points;
CREATE POLICY "Users can view public route points" ON public.route_points
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.routes 
      WHERE routes.id = route_points.route_id 
      AND routes.is_public = true
    )
  );

DROP POLICY IF EXISTS "Users can manage own route points" ON public.route_points;
CREATE POLICY "Users can manage own route points" ON public.route_points
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.routes 
      WHERE routes.id = route_points.route_id 
      AND routes.user_id = auth.uid()
    )
  );

-- 5. favoritesテーブル（お気に入り）
CREATE TABLE IF NOT EXISTS public.favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, route_id)
);

ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own favorites" ON public.favorites;
CREATE POLICY "Users can view own favorites" ON public.favorites
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own favorites" ON public.favorites;
CREATE POLICY "Users can manage own favorites" ON public.favorites
  FOR ALL USING (auth.uid() = user_id);

-- 6. route_photosテーブル（ルート写真）
CREATE TABLE IF NOT EXISTS public.route_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  display_order INTEGER DEFAULT 0,
  caption TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.route_photos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own route photos" ON public.route_photos;
CREATE POLICY "Users can manage own route photos" ON public.route_photos
  FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Anyone can view public route photos" ON public.route_photos;
CREATE POLICY "Anyone can view public route photos" ON public.route_photos
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.routes 
      WHERE routes.id = route_photos.route_id 
      AND routes.is_public = true
    )
  );

DROP POLICY IF EXISTS "Users can view own route photos" ON public.route_photos;
CREATE POLICY "Users can view own route photos" ON public.route_photos
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.routes 
      WHERE routes.id = route_photos.route_id 
      AND routes.user_id = auth.uid()
    )
  );

-- ============================================================
-- Phase 17: コメント機能
-- ============================================================

-- 7. commentsテーブル（ルートへのコメント）
CREATE TABLE IF NOT EXISTS public.comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view comments on public routes" ON public.comments;
CREATE POLICY "Anyone can view comments on public routes" ON public.comments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.routes 
      WHERE routes.id = comments.route_id 
      AND routes.is_public = true
    )
  );

DROP POLICY IF EXISTS "Users can view comments on own routes" ON public.comments;
CREATE POLICY "Users can view comments on own routes" ON public.comments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.routes 
      WHERE routes.id = comments.route_id 
      AND routes.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Authenticated users can create comments" ON public.comments;
CREATE POLICY "Authenticated users can create comments" ON public.comments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own comments" ON public.comments;
CREATE POLICY "Users can delete own comments" ON public.comments
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================================
-- Phase 24: ソーシャル機能
-- ============================================================

-- 8. followsテーブル（フォロー/フォロワー関係）
CREATE TABLE IF NOT EXISTS public.follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(follower_id, following_id),
  CONSTRAINT no_self_follow CHECK (follower_id != following_id)
);

ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view follows" ON public.follows;
CREATE POLICY "Anyone can view follows" ON public.follows
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can create their own follows" ON public.follows;
CREATE POLICY "Users can create their own follows" ON public.follows
  FOR INSERT WITH CHECK (auth.uid() = follower_id);

DROP POLICY IF EXISTS "Users can delete their own follows" ON public.follows;
CREATE POLICY "Users can delete their own follows" ON public.follows
  FOR DELETE USING (auth.uid() = follower_id);

-- 9. likesテーブル（ルートへのいいね）
CREATE TABLE IF NOT EXISTS public.likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, route_id)
);

ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view likes" ON public.likes;
CREATE POLICY "Anyone can view likes" ON public.likes
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can create likes" ON public.likes;
CREATE POLICY "Authenticated users can create likes" ON public.likes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own likes" ON public.likes;
CREATE POLICY "Users can delete their own likes" ON public.likes
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================================
-- インデックス作成（パフォーマンス向上）
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_route_points_route_id ON public.route_points(route_id);
CREATE INDEX IF NOT EXISTS idx_route_points_timestamp ON public.route_points(timestamp);
CREATE INDEX IF NOT EXISTS idx_routes_user_id ON public.routes(user_id);
CREATE INDEX IF NOT EXISTS idx_routes_created_at ON public.routes(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_routes_is_public ON public.routes(is_public);
CREATE INDEX IF NOT EXISTS idx_dogs_user_id ON public.dogs(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON public.favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_route_id ON public.favorites(route_id);
CREATE INDEX IF NOT EXISTS idx_route_photos_route_id ON public.route_photos(route_id);
CREATE INDEX IF NOT EXISTS idx_route_photos_user_id ON public.route_photos(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_route_id ON public.comments(route_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON public.comments(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON public.comments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_follows_follower_id ON public.follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following_id ON public.follows(following_id);
CREATE INDEX IF NOT EXISTS idx_follows_created_at ON public.follows(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_likes_user_id ON public.likes(user_id);
CREATE INDEX IF NOT EXISTS idx_likes_route_id ON public.likes(route_id);
CREATE INDEX IF NOT EXISTS idx_likes_created_at ON public.likes(created_at DESC);

-- ============================================================
-- トリガー: updated_atの自動更新
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_dogs_updated_at ON public.dogs;
CREATE TRIGGER update_dogs_updated_at BEFORE UPDATE ON public.dogs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_routes_updated_at ON public.routes;
CREATE TRIGGER update_routes_updated_at BEFORE UPDATE ON public.routes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_comments_updated_at ON public.comments;
CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON public.comments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- ビュー: フォロー統計
-- ============================================================

CREATE OR REPLACE VIEW public.follow_stats AS
SELECT 
  u.id as user_id,
  COUNT(DISTINCT f1.id) as follower_count,
  COUNT(DISTINCT f2.id) as following_count
FROM auth.users u
LEFT JOIN public.follows f1 ON f1.following_id = u.id
LEFT JOIN public.follows f2 ON f2.follower_id = u.id
GROUP BY u.id;

-- ============================================================
-- ビュー: ルートのいいね数
-- ============================================================

CREATE OR REPLACE VIEW public.route_like_counts AS
SELECT 
  r.id as route_id,
  COUNT(l.id) as like_count
FROM public.routes r
LEFT JOIN public.likes l ON l.route_id = r.id
GROUP BY r.id;

-- ============================================================
-- 関数: ユーザーがフォローしているかチェック
-- ============================================================

CREATE OR REPLACE FUNCTION public.is_following(
  follower_user_id UUID,
  following_user_id UUID
)
RETURNS BOOLEAN AS $$
  SELECT EXISTS(
    SELECT 1 FROM public.follows
    WHERE follower_id = follower_user_id
      AND following_id = following_user_id
  );
$$ LANGUAGE sql STABLE;

-- ============================================================
-- 関数: ユーザーがルートにいいねしているかチェック
-- ============================================================

CREATE OR REPLACE FUNCTION public.has_liked_route(
  check_user_id UUID,
  check_route_id UUID
)
RETURNS BOOLEAN AS $$
  SELECT EXISTS(
    SELECT 1 FROM public.likes
    WHERE user_id = check_user_id
      AND route_id = check_route_id
  );
$$ LANGUAGE sql STABLE;

-- ============================================================
-- 完了メッセージ
-- ============================================================

DO $$
BEGIN
  RAISE NOTICE '====================================';
  RAISE NOTICE 'WanWalk データベーススキーマ適用完了';
  RAISE NOTICE '====================================';
  RAISE NOTICE 'テーブル作成: profiles, dogs, routes, route_points, favorites, route_photos, comments, follows, likes';
  RAISE NOTICE 'RLSポリシー: すべて設定済み';
  RAISE NOTICE 'インデックス: すべて作成済み';
  RAISE NOTICE 'ビュー: follow_stats, route_like_counts';
  RAISE NOTICE '関数: is_following(), has_liked_route()';
  RAISE NOTICE '====================================';
END $$;
