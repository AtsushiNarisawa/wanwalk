-- WanMap データベーススキーマ
-- Supabase SQL Editorで実行してください

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

-- RLS (Row Level Security) を有効化
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 全ユーザーが全プロフィールを閲覧可能（公開ルートの作者情報表示のため）
CREATE POLICY "Anyone can view profiles" ON public.profiles
  FOR SELECT USING (true);

-- ユーザーは自分のプロフィールのみ更新可能
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- ユーザーは自分のプロフィールのみ作成可能
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

CREATE POLICY "Users can view own dogs" ON public.dogs
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own dogs" ON public.dogs
  FOR ALL USING (auth.uid() = user_id);

-- 3. routesテーブル（散歩ルート）
CREATE TABLE IF NOT EXISTS public.routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  dog_id UUID REFERENCES public.dogs(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  distance NUMERIC NOT NULL DEFAULT 0, -- メートル
  duration INTEGER NOT NULL DEFAULT 0, -- 秒
  started_at TIMESTAMP WITH TIME ZONE NOT NULL,
  ended_at TIMESTAMP WITH TIME ZONE,
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own routes" ON public.routes
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view public routes" ON public.routes
  FOR SELECT USING (is_public = true);

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

-- インデックス作成（パフォーマンス向上）
CREATE INDEX IF NOT EXISTS idx_route_points_route_id ON public.route_points(route_id);
CREATE INDEX IF NOT EXISTS idx_route_points_timestamp ON public.route_points(timestamp);
CREATE INDEX IF NOT EXISTS idx_routes_user_id ON public.routes(user_id);
CREATE INDEX IF NOT EXISTS idx_routes_created_at ON public.routes(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_dogs_user_id ON public.dogs(user_id);

ALTER TABLE public.route_points ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own route points" ON public.route_points
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.routes 
      WHERE routes.id = route_points.route_id 
      AND routes.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can view public route points" ON public.route_points
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.routes 
      WHERE routes.id = route_points.route_id 
      AND routes.is_public = true
    )
  );

CREATE POLICY "Users can manage own route points" ON public.route_points
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.routes 
      WHERE routes.id = route_points.route_id 
      AND routes.user_id = auth.uid()
    )
  );

-- トリガー: updated_atの自動更新
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_dogs_updated_at BEFORE UPDATE ON public.dogs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_routes_updated_at BEFORE UPDATE ON public.routes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 5. favoritesテーブル（お気に入り）
CREATE TABLE IF NOT EXISTS public.favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, route_id)
);

ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own favorites" ON public.favorites
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own favorites" ON public.favorites
  FOR ALL USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON public.favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_route_id ON public.favorites(route_id);

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

-- 自分のルートの写真は管理可能
CREATE POLICY "Users can manage own route photos" ON public.route_photos
  FOR ALL USING (auth.uid() = user_id);

-- 公開ルートの写真は全員閲覧可能
CREATE POLICY "Anyone can view public route photos" ON public.route_photos
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.routes 
      WHERE routes.id = route_photos.route_id 
      AND routes.is_public = true
    )
  );

-- 自分のルートの写真は閲覧可能
CREATE POLICY "Users can view own route photos" ON public.route_photos
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.routes 
      WHERE routes.id = route_photos.route_id 
      AND routes.user_id = auth.uid()
    )
  );

CREATE INDEX IF NOT EXISTS idx_route_photos_route_id ON public.route_photos(route_id);
CREATE INDEX IF NOT EXISTS idx_route_photos_user_id ON public.route_photos(user_id);
