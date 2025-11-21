-- ============================================
-- WanMap Database Schema v3.0 (Phase 1 MVP)
-- ============================================
-- 実装指示書: wanmap_implementation_guide_v3.md に基づく
-- Supabase SQL Editorでこのスクリプトを実行してください

-- PostGIS拡張を有効化
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. user_profiles（ユーザープロフィール）
-- ============================================
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  is_admin BOOLEAN DEFAULT FALSE,
  business_name TEXT,
  business_location GEOMETRY(POINT, 4326),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all profiles"
  ON user_profiles FOR SELECT USING (true);

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- ============================================
-- 2. dogs（犬情報）
-- ============================================
CREATE TABLE IF NOT EXISTS dogs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  breed TEXT,
  size TEXT CHECK (size IN ('small', 'medium', 'large')),
  birth_date DATE,
  weight DECIMAL(5, 2),
  photo_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dogs_user_id ON dogs(user_id);
ALTER TABLE dogs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all dogs"
  ON dogs FOR SELECT USING (true);

CREATE POLICY "Users can manage own dogs"
  ON dogs FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 3. routes（散歩ルート）
-- ============================================
CREATE TABLE IF NOT EXISTS routes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  dog_id UUID REFERENCES dogs(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  is_public BOOLEAN DEFAULT TRUE,
  distance_meters DECIMAL(10, 2) NOT NULL,
  duration_seconds INTEGER NOT NULL,
  elevation_gain DECIMAL(8, 2),
  difficulty TEXT CHECK (difficulty IN ('easy', 'medium', 'hard')),
  start_location GEOMETRY(POINT, 4326) NOT NULL,
  end_location GEOMETRY(POINT, 4326) NOT NULL,
  area_name TEXT,
  tags TEXT[],
  is_featured BOOLEAN DEFAULT FALSE,
  featured_by UUID REFERENCES auth.users(id),
  featured_comment TEXT,
  view_count INTEGER DEFAULT 0,
  like_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_routes_user_id ON routes(user_id);
CREATE INDEX IF NOT EXISTS idx_routes_is_public ON routes(is_public);
CREATE INDEX IF NOT EXISTS idx_routes_area_name ON routes(area_name);
CREATE INDEX IF NOT EXISTS idx_routes_start_location ON routes USING GIST(start_location);
CREATE INDEX IF NOT EXISTS idx_routes_tags ON routes USING GIN(tags);

ALTER TABLE routes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public routes are viewable by everyone"
  ON routes FOR SELECT USING (is_public = true OR auth.uid() = user_id);

CREATE POLICY "Users can manage own routes"
  ON routes FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 4. route_points（ルート座標点）
-- ============================================
CREATE TABLE IF NOT EXISTS route_points (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
  location GEOMETRY(POINT, 4326) NOT NULL,
  altitude DECIMAL(8, 2),
  accuracy DECIMAL(6, 2),
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
  sequence_number INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_route_points_route_id ON route_points(route_id);
CREATE INDEX IF NOT EXISTS idx_route_points_sequence ON route_points(route_id, sequence_number);
CREATE INDEX IF NOT EXISTS idx_route_points_location ON route_points USING GIST(location);

ALTER TABLE route_points ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Route points inherit route visibility"
  ON route_points FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM routes
      WHERE routes.id = route_points.route_id
      AND (routes.is_public = true OR routes.user_id = auth.uid())
    )
  );

CREATE POLICY "Users can manage own route points"
  ON route_points FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM routes
      WHERE routes.id = route_points.route_id
      AND routes.user_id = auth.uid()
    )
  );

-- ============================================
-- 5. route_photos（ルート写真）
-- ============================================
CREATE TABLE IF NOT EXISTS route_photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
  photo_url TEXT NOT NULL,
  thumbnail_url TEXT,
  storage_path TEXT NOT NULL,
  location GEOMETRY(POINT, 4326),
  caption TEXT,
  taken_at TIMESTAMP WITH TIME ZONE,
  sequence_number INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_route_photos_route_id ON route_photos(route_id);
ALTER TABLE route_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Route photos inherit route visibility"
  ON route_photos FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM routes
      WHERE routes.id = route_photos.route_id
      AND (routes.is_public = true OR routes.user_id = auth.uid())
    )
  );

CREATE POLICY "Users can manage own route photos"
  ON route_photos FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM routes
      WHERE routes.id = route_photos.route_id
      AND routes.user_id = auth.uid()
    )
  );

-- ============================================
-- 6. route_likes（ルートいいね）
-- ============================================
CREATE TABLE IF NOT EXISTS route_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(route_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_route_likes_route_id ON route_likes(route_id);
CREATE INDEX IF NOT EXISTS idx_route_likes_user_id ON route_likes(user_id);
ALTER TABLE route_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view likes"
  ON route_likes FOR SELECT USING (true);

CREATE POLICY "Users can manage own likes"
  ON route_likes FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 7. route_comments（ルートコメント）
-- ============================================
CREATE TABLE IF NOT EXISTS route_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_route_comments_route_id ON route_comments(route_id);
CREATE INDEX IF NOT EXISTS idx_route_comments_user_id ON route_comments(user_id);
ALTER TABLE route_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public route comments are viewable"
  ON route_comments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM routes
      WHERE routes.id = route_comments.route_id
      AND (routes.is_public = true OR routes.user_id = auth.uid())
    )
  );

CREATE POLICY "Users can create comments"
  ON route_comments FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own comments"
  ON route_comments FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments"
  ON route_comments FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- 8. spots（わんスポット）
-- ============================================
CREATE TABLE IF NOT EXISTS spots (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN ('park', 'cafe', 'shop', 'hospital', 'other')),
  location GEOMETRY(POINT, 4326) NOT NULL,
  address TEXT,
  phone TEXT,
  website TEXT,
  rating DECIMAL(2, 1) CHECK (rating >= 0 AND rating <= 5),
  upvote_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_spots_location ON spots USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_spots_category ON spots(category);
ALTER TABLE spots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view spots"
  ON spots FOR SELECT USING (true);

CREATE POLICY "Users can create spots"
  ON spots FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own spots"
  ON spots FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own spots"
  ON spots FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- 9. spot_photos（わんスポット写真）
-- ============================================
CREATE TABLE IF NOT EXISTS spot_photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  spot_id UUID NOT NULL REFERENCES spots(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  photo_url TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  caption TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_spot_photos_spot_id ON spot_photos(spot_id);
ALTER TABLE spot_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view spot photos"
  ON spot_photos FOR SELECT USING (true);

CREATE POLICY "Users can create spot photos"
  ON spot_photos FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own spot photos"
  ON spot_photos FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- 10. spot_comments（わんスポットコメント）
-- ============================================
CREATE TABLE IF NOT EXISTS spot_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  spot_id UUID NOT NULL REFERENCES spots(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_spot_comments_spot_id ON spot_comments(spot_id);
ALTER TABLE spot_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view spot comments"
  ON spot_comments FOR SELECT USING (true);

CREATE POLICY "Users can create spot comments"
  ON spot_comments FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own spot comments"
  ON spot_comments FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own spot comments"
  ON spot_comments FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- 11. spot_upvotes（わんスポット高評価）
-- ============================================
CREATE TABLE IF NOT EXISTS spot_upvotes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  spot_id UUID NOT NULL REFERENCES spots(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(spot_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_spot_upvotes_spot_id ON spot_upvotes(spot_id);
ALTER TABLE spot_upvotes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view upvotes"
  ON spot_upvotes FOR SELECT USING (true);

CREATE POLICY "Users can manage own upvotes"
  ON spot_upvotes FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- PostgreSQL Functions（Supabase RPC用）
-- ============================================

-- 近くのルートを検索する関数
CREATE OR REPLACE FUNCTION search_nearby_routes(
  user_lat FLOAT,
  user_lng FLOAT,
  search_radius_km FLOAT DEFAULT 10,
  min_distance_m FLOAT DEFAULT NULL,
  max_distance_m FLOAT DEFAULT NULL,
  difficulty_filter TEXT DEFAULT NULL,
  tags_filter TEXT[] DEFAULT NULL,
  featured_only BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  distance_meters DECIMAL,
  duration_seconds INTEGER,
  difficulty TEXT,
  area_name TEXT,
  tags TEXT[],
  is_featured BOOLEAN,
  featured_comment TEXT,
  like_count INTEGER,
  comment_count INTEGER,
  view_count INTEGER,
  distance_from_user_meters FLOAT,
  user_display_name TEXT,
  thumbnail_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id, r.title, r.description, r.distance_meters, r.duration_seconds,
    r.difficulty, r.area_name, r.tags, r.is_featured, r.featured_comment,
    r.like_count, r.comment_count, r.view_count,
    ST_Distance(
      r.start_location::geography,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
    ) as distance_from_user_meters,
    up.display_name as user_display_name,
    (SELECT photo_url FROM route_photos WHERE route_id = r.id ORDER BY sequence_number LIMIT 1) as thumbnail_url,
    r.created_at
  FROM routes r
  JOIN user_profiles up ON r.user_id = up.id
  WHERE r.is_public = true
    AND ST_DWithin(
      r.start_location::geography,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
      search_radius_km * 1000
    )
    AND (min_distance_m IS NULL OR r.distance_meters >= min_distance_m)
    AND (max_distance_m IS NULL OR r.distance_meters <= max_distance_m)
    AND (difficulty_filter IS NULL OR r.difficulty = difficulty_filter)
    AND (tags_filter IS NULL OR r.tags && tags_filter)
    AND (featured_only = false OR r.is_featured = true)
  ORDER BY 
    CASE WHEN r.is_featured THEN 0 ELSE 1 END,
    distance_from_user_meters ASC;
END;
$$ LANGUAGE plpgsql STABLE;

-- 近くのわんスポットを検索する関数
CREATE OR REPLACE FUNCTION search_nearby_spots(
  user_lat FLOAT,
  user_lng FLOAT,
  search_radius_km FLOAT DEFAULT 5,
  category_filter TEXT DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  description TEXT,
  category TEXT,
  address TEXT,
  phone TEXT,
  website TEXT,
  rating DECIMAL,
  upvote_count INTEGER,
  comment_count INTEGER,
  is_verified BOOLEAN,
  distance_from_user_meters FLOAT,
  user_display_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id, s.name, s.description, s.category, s.address, s.phone, s.website,
    s.rating, s.upvote_count, s.comment_count, s.is_verified,
    ST_Distance(
      s.location::geography,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
    ) as distance_from_user_meters,
    up.display_name as user_display_name,
    s.created_at
  FROM spots s
  JOIN user_profiles up ON s.user_id = up.id
  WHERE ST_DWithin(
      s.location::geography,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
      search_radius_km * 1000
    )
    AND (category_filter IS NULL OR s.category = category_filter)
  ORDER BY distance_from_user_meters ASC;
END;
$$ LANGUAGE plpgsql STABLE;

-- わんスポット重複チェック関数（半径50m以内の同名スポット）
CREATE OR REPLACE FUNCTION check_spot_duplicate(
  spot_name TEXT,
  spot_lat FLOAT,
  spot_lng FLOAT,
  radius_meters FLOAT DEFAULT 50
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  distance_meters FLOAT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id,
    s.name,
    ST_Distance(
      s.location::geography,
      ST_SetSRID(ST_MakePoint(spot_lng, spot_lat), 4326)::geography
    ) as distance_meters
  FROM spots s
  WHERE LOWER(s.name) = LOWER(spot_name)
    AND ST_DWithin(
      s.location::geography,
      ST_SetSRID(ST_MakePoint(spot_lng, spot_lat), 4326)::geography,
      radius_meters
    )
  ORDER BY distance_meters ASC
  LIMIT 5;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================
-- Triggers（自動更新）
-- ============================================

-- updated_atを自動更新するトリガー関数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 各テーブルにトリガーを設定
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_dogs_updated_at BEFORE UPDATE ON dogs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_routes_updated_at BEFORE UPDATE ON routes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_route_comments_updated_at BEFORE UPDATE ON route_comments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_spots_updated_at BEFORE UPDATE ON spots
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_spot_comments_updated_at BEFORE UPDATE ON spot_comments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 完了メッセージ
-- ============================================
DO $$
BEGIN
  RAISE NOTICE '✅ WanMap Database Schema v3.0 setup completed successfully!';
  RAISE NOTICE '📋 Tables created: user_profiles, dogs, routes, route_points, route_photos, route_likes, route_comments, spots, spot_photos, spot_comments, spot_upvotes';
  RAISE NOTICE '🔍 Functions created: search_nearby_routes, search_nearby_spots, check_spot_duplicate';
  RAISE NOTICE '🔒 Row Level Security enabled on all tables';
  RAISE NOTICE '🎯 Next step: Configure Supabase Storage buckets (route-photos, profile-avatars)';
END $$;
