-- =====================================================
-- WanMap リニューアル Phase 1a: 新規テーブル作成
-- =====================================================
-- 実行日: 2024-11-22
-- 目的: 公式ルート、ピン投稿などの新機能用テーブル作成

-- PostGIS拡張を有効化（既存でなければ）
CREATE EXTENSION IF NOT EXISTS postgis;

-- =====================================================
-- エリアマスタ
-- =====================================================
CREATE TABLE areas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  area_code TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  category TEXT CHECK (category IN ('tourist', 'urban')) NOT NULL,
  prefecture TEXT NOT NULL,
  description TEXT,
  thumbnail_url TEXT,
  route_count INTEGER DEFAULT 0,
  total_walks INTEGER DEFAULT 0,
  last_walked_at TIMESTAMPTZ,
  center_location GEOGRAPHY(Point, 4326),
  is_active BOOLEAN DEFAULT TRUE,
  display_order INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX areas_category_idx ON areas (category);
CREATE INDEX areas_display_order_idx ON areas (display_order);
CREATE INDEX areas_is_active_idx ON areas (is_active);

COMMENT ON TABLE areas IS 'エリアマスタ（観光地・都市エリア）';

-- =====================================================
-- 公式ルート
-- =====================================================
CREATE TABLE official_routes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  area_id UUID REFERENCES areas NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  difficulty TEXT CHECK (difficulty IN ('easy', 'moderate', 'hard')) NOT NULL,
  distance_km DECIMAL(4,2) NOT NULL,
  estimated_duration_minutes INTEGER NOT NULL,
  elevation_gain_m INTEGER,
  features TEXT[], -- ['scenic_view', 'cafe_nearby', 'shaded']
  best_seasons TEXT[], -- ['spring', 'summer', 'autumn', 'winter']
  best_time_slots TEXT[], -- ['morning', 'midday', 'evening', 'night']
  start_location GEOGRAPHY(Point, 4326) NOT NULL,
  end_location GEOGRAPHY(Point, 4326) NOT NULL,
  route_line GEOGRAPHY(LineString, 4326),
  total_walks INTEGER DEFAULT 0,
  total_pins INTEGER DEFAULT 0,
  average_rating DECIMAL(2,1),
  last_walked_at TIMESTAMPTZ,
  created_by UUID REFERENCES auth.users,
  is_official BOOLEAN DEFAULT TRUE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX official_routes_area_idx ON official_routes (area_id);
CREATE INDEX official_routes_difficulty_idx ON official_routes (difficulty);
CREATE INDEX official_routes_start_location_idx ON official_routes USING GIST (start_location);
CREATE INDEX official_routes_is_active_idx ON official_routes (is_active);

COMMENT ON TABLE official_routes IS '管理者が登録する公式散歩ルート';

-- =====================================================
-- 公式ルート経路ポイント
-- =====================================================
CREATE TABLE official_route_points (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id UUID REFERENCES official_routes NOT NULL,
  point_order INTEGER NOT NULL,
  location GEOGRAPHY(Point, 4326) NOT NULL,
  elevation_m INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (route_id, point_order)
);

CREATE INDEX official_route_points_route_idx ON official_route_points (route_id, point_order);

COMMENT ON TABLE official_route_points IS '公式ルートの経路ポイント（順序付き）';

-- =====================================================
-- 公式ルート実行記録
-- =====================================================
CREATE TABLE route_walks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id UUID REFERENCES official_routes NOT NULL,
  user_id UUID REFERENCES auth.users NOT NULL,
  dog_id UUID REFERENCES dogs NOT NULL,
  walked_at TIMESTAMPTZ NOT NULL,
  duration_minutes INTEGER,
  time_slot TEXT CHECK (time_slot IN ('morning', 'midday', 'evening', 'night')),
  season TEXT CHECK (season IN ('spring', 'summer', 'autumn', 'winter')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX route_walks_route_idx ON route_walks (route_id);
CREATE INDEX route_walks_user_idx ON route_walks (user_id);
CREATE INDEX route_walks_walked_at_idx ON route_walks (walked_at DESC);

COMMENT ON TABLE route_walks IS 'ユーザーが公式ルートを歩いた記録';

-- =====================================================
-- ピン機能（最重要）
-- =====================================================
CREATE TABLE route_pins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id UUID REFERENCES official_routes NOT NULL,
  user_id UUID REFERENCES auth.users NOT NULL,
  dog_id UUID REFERENCES dogs,
  location GEOGRAPHY(Point, 4326) NOT NULL,
  pin_type TEXT CHECK (pin_type IN ('scenery', 'shop', 'encounter', 'other')) NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  likes_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX route_pins_route_idx ON route_pins (route_id);
CREATE INDEX route_pins_location_idx ON route_pins USING GIST (location);
CREATE INDEX route_pins_created_at_idx ON route_pins (created_at DESC);
CREATE INDEX route_pins_is_active_idx ON route_pins (is_active);

COMMENT ON TABLE route_pins IS 'ユーザーが投稿するルート上のピン（体験共有）';

-- =====================================================
-- ピン写真
-- =====================================================
CREATE TABLE route_pin_photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pin_id UUID REFERENCES route_pins ON DELETE CASCADE NOT NULL,
  photo_url TEXT NOT NULL,
  photo_order INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (pin_id, photo_order)
);

CREATE INDEX route_pin_photos_pin_idx ON route_pin_photos (pin_id, photo_order);

COMMENT ON TABLE route_pin_photos IS 'ピンに添付される写真（最大5枚）';

-- =====================================================
-- ピンいいね
-- =====================================================
CREATE TABLE pin_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pin_id UUID REFERENCES route_pins ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (pin_id, user_id)
);

CREATE INDEX pin_likes_pin_idx ON pin_likes (pin_id);
CREATE INDEX pin_likes_user_idx ON pin_likes (user_id);

COMMENT ON TABLE pin_likes IS 'ピンへのいいね';

-- =====================================================
-- ユーザープロファイル（自動構築）
-- =====================================================
CREATE TABLE user_walking_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users UNIQUE NOT NULL,
  avg_duration_minutes INTEGER,
  avg_distance_km DECIMAL(4,2),
  preferred_time_slots TEXT[],
  frequency_per_week INTEGER,
  preferred_difficulty TEXT,
  favorite_area_ids UUID[],
  last_calculated_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX user_walking_profiles_user_idx ON user_walking_profiles (user_id);

COMMENT ON TABLE user_walking_profiles IS 'ユーザーの散歩プロファイル（レコメンド用）';
