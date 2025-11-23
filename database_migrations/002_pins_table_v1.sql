-- ============================================================================
-- Phase 1-2: Pins Tables (ピン・写真・いいね)
-- ============================================================================
-- Description: Tables for route pins, photos, and likes
-- Author: WanMap Development Team
-- Created: 2025-11-23
-- Version: 1
-- ============================================================================
--
-- 設計方針:
-- - route_pins: ユーザーがルート上に投稿する体験・発見
-- - route_pin_photos: ピンに関連付けられた写真（最大5枚）
-- - pin_likes: ピンへのいいね
-- - PostGISのPOINT型を使用して位置情報を管理
-- ============================================================================

-- ============================================================================
-- 1. Enable PostGIS Extension (if not already enabled)
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================================================
-- 2. route_pins Table (ピン)
-- ============================================================================

CREATE TABLE IF NOT EXISTS route_pins (
  -- Primary identifiers
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Location (PostGIS Point)
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  
  -- Pin details
  pin_type TEXT NOT NULL CHECK (pin_type IN ('scenery', 'shop', 'encounter', 'other')),
  title TEXT NOT NULL,
  comment TEXT DEFAULT '',
  
  -- Statistics
  likes_count INTEGER NOT NULL DEFAULT 0,
  
  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 3. route_pin_photos Table (ピン写真)
-- ============================================================================

CREATE TABLE IF NOT EXISTS route_pin_photos (
  -- Primary identifiers
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pin_id UUID NOT NULL REFERENCES route_pins(id) ON DELETE CASCADE,
  
  -- Photo details
  photo_url TEXT NOT NULL,
  display_order INTEGER NOT NULL DEFAULT 1,
  
  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 4. pin_likes Table (ピンいいね)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pin_likes (
  -- Primary identifiers
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pin_id UUID NOT NULL REFERENCES route_pins(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Unique constraint: one like per user per pin
  UNIQUE(pin_id, user_id)
);

-- ============================================================================
-- 5. Indexes for Performance
-- ============================================================================

-- route_pins indexes
CREATE INDEX IF NOT EXISTS idx_route_pins_route_id ON route_pins(route_id);
CREATE INDEX IF NOT EXISTS idx_route_pins_user_id ON route_pins(user_id);
CREATE INDEX IF NOT EXISTS idx_route_pins_pin_type ON route_pins(pin_type);
CREATE INDEX IF NOT EXISTS idx_route_pins_created_at ON route_pins(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_route_pins_location ON route_pins USING GIST(location);

-- route_pin_photos indexes
CREATE INDEX IF NOT EXISTS idx_route_pin_photos_pin_id ON route_pin_photos(pin_id);
CREATE INDEX IF NOT EXISTS idx_route_pin_photos_display_order ON route_pin_photos(pin_id, display_order);

-- pin_likes indexes
CREATE INDEX IF NOT EXISTS idx_pin_likes_pin_id ON pin_likes(pin_id);
CREATE INDEX IF NOT EXISTS idx_pin_likes_user_id ON pin_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_pin_likes_pin_user ON pin_likes(pin_id, user_id);

-- ============================================================================
-- 6. Triggers
-- ============================================================================

-- Auto-update updated_at timestamp for route_pins
CREATE OR REPLACE FUNCTION update_route_pins_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_route_pins_updated_at ON route_pins;
CREATE TRIGGER trigger_route_pins_updated_at
  BEFORE UPDATE ON route_pins
  FOR EACH ROW
  EXECUTE FUNCTION update_route_pins_updated_at();

-- Auto-increment likes_count when a like is added
CREATE OR REPLACE FUNCTION increment_pin_likes_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE route_pins
  SET likes_count = likes_count + 1
  WHERE id = NEW.pin_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_increment_pin_likes ON pin_likes;
CREATE TRIGGER trigger_increment_pin_likes
  AFTER INSERT ON pin_likes
  FOR EACH ROW
  EXECUTE FUNCTION increment_pin_likes_count();

-- Auto-decrement likes_count when a like is removed
CREATE OR REPLACE FUNCTION decrement_pin_likes_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE route_pins
  SET likes_count = GREATEST(likes_count - 1, 0)
  WHERE id = OLD.pin_id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_decrement_pin_likes ON pin_likes;
CREATE TRIGGER trigger_decrement_pin_likes
  AFTER DELETE ON pin_likes
  FOR EACH ROW
  EXECUTE FUNCTION decrement_pin_likes_count();

-- ============================================================================
-- 7. Row Level Security (RLS)
-- ============================================================================

-- route_pins RLS
ALTER TABLE route_pins ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view pins" ON route_pins;
CREATE POLICY "Anyone can view pins"
  ON route_pins FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can insert own pins" ON route_pins;
CREATE POLICY "Users can insert own pins"
  ON route_pins FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own pins" ON route_pins;
CREATE POLICY "Users can update own pins"
  ON route_pins FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own pins" ON route_pins;
CREATE POLICY "Users can delete own pins"
  ON route_pins FOR DELETE
  USING (auth.uid() = user_id);

-- route_pin_photos RLS
ALTER TABLE route_pin_photos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view pin photos" ON route_pin_photos;
CREATE POLICY "Anyone can view pin photos"
  ON route_pin_photos FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can insert photos for own pins" ON route_pin_photos;
CREATE POLICY "Users can insert photos for own pins"
  ON route_pin_photos FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM route_pins
      WHERE route_pins.id = pin_id
      AND route_pins.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can delete photos for own pins" ON route_pin_photos;
CREATE POLICY "Users can delete photos for own pins"
  ON route_pin_photos FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM route_pins
      WHERE route_pins.id = pin_id
      AND route_pins.user_id = auth.uid()
    )
  );

-- pin_likes RLS
ALTER TABLE pin_likes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view likes" ON pin_likes;
CREATE POLICY "Anyone can view likes"
  ON pin_likes FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can like pins" ON pin_likes;
CREATE POLICY "Users can like pins"
  ON pin_likes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can unlike pins" ON pin_likes;
CREATE POLICY "Users can unlike pins"
  ON pin_likes FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- 8. Comments
-- ============================================================================

COMMENT ON TABLE route_pins IS 'User-created pins on routes (experiences, discoveries)';
COMMENT ON COLUMN route_pins.route_id IS 'Reference to official route';
COMMENT ON COLUMN route_pins.location IS 'Pin location as PostGIS Point (latitude, longitude)';
COMMENT ON COLUMN route_pins.pin_type IS 'Type: scenery, shop, encounter, other';
COMMENT ON COLUMN route_pins.likes_count IS 'Number of likes (auto-updated by triggers)';

COMMENT ON TABLE route_pin_photos IS 'Photos attached to pins (max 5 per pin)';
COMMENT ON COLUMN route_pin_photos.display_order IS 'Display order of photos';

COMMENT ON TABLE pin_likes IS 'User likes for pins';

-- ============================================================================
-- 9. Helper RPC Functions
-- ============================================================================

-- Toggle pin like (like/unlike)
CREATE OR REPLACE FUNCTION toggle_pin_like(
  p_pin_id UUID,
  p_user_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_liked BOOLEAN;
BEGIN
  -- Check if already liked
  SELECT EXISTS(
    SELECT 1 FROM pin_likes
    WHERE pin_id = p_pin_id AND user_id = p_user_id
  ) INTO v_liked;

  IF v_liked THEN
    -- Unlike
    DELETE FROM pin_likes
    WHERE pin_id = p_pin_id AND user_id = p_user_id;
    
    RETURN json_build_object('liked', false);
  ELSE
    -- Like
    INSERT INTO pin_likes (pin_id, user_id)
    VALUES (p_pin_id, p_user_id)
    ON CONFLICT (pin_id, user_id) DO NOTHING;
    
    RETURN json_build_object('liked', true);
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get pins by route with photo URLs
CREATE OR REPLACE FUNCTION get_pins_by_route(
  p_route_id UUID,
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE(
  pin_id UUID,
  route_id UUID,
  user_id UUID,
  location_lat DOUBLE PRECISION,
  location_lng DOUBLE PRECISION,
  pin_type TEXT,
  title TEXT,
  comment TEXT,
  likes_count INTEGER,
  photo_urls TEXT[],
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id AS pin_id,
    p.route_id,
    p.user_id,
    ST_Y(p.location::geometry) AS location_lat,
    ST_X(p.location::geometry) AS location_lng,
    p.pin_type,
    p.title,
    p.comment,
    p.likes_count,
    COALESCE(
      ARRAY_AGG(ph.photo_url ORDER BY ph.display_order) FILTER (WHERE ph.photo_url IS NOT NULL),
      ARRAY[]::TEXT[]
    ) AS photo_urls,
    p.created_at
  FROM route_pins p
  LEFT JOIN route_pin_photos ph ON p.id = ph.pin_id
  WHERE p.route_id = p_route_id
  GROUP BY p.id
  ORDER BY p.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 10. Update get_user_walk_statistics to include pins
-- ============================================================================

DROP FUNCTION IF EXISTS get_user_walk_statistics(UUID);

CREATE OR REPLACE FUNCTION get_user_walk_statistics(p_user_id UUID)
RETURNS TABLE(
  total_walks INTEGER,
  total_outing_walks INTEGER,
  total_distance_km DECIMAL,
  total_duration_hours DECIMAL,
  areas_visited INTEGER,
  routes_completed INTEGER,
  pins_created INTEGER,
  pins_liked_count INTEGER,
  followers_count INTEGER,
  following_count INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    -- Walk statistics (from walks table)
    ws.total_walks,
    ws.total_outing_walks,
    ws.total_distance_km,
    ws.total_duration_hours,
    ws.areas_visited,
    ws.routes_completed,
    -- Pin statistics (from route_pins table)
    COALESCE(pin_stats.pins_created, 0)::INTEGER AS pins_created,
    COALESCE(pin_stats.pins_liked_count, 0)::INTEGER AS pins_liked_count,
    -- Social statistics (from existing user_follows table)
    COALESCE(follower_stats.followers_count, 0)::INTEGER AS followers_count,
    COALESCE(following_stats.following_count, 0)::INTEGER AS following_count
  FROM calculate_walk_statistics(p_user_id) ws
  -- Pin statistics
  LEFT JOIN LATERAL (
    SELECT 
      COUNT(*)::INTEGER AS pins_created,
      COALESCE(SUM(likes_count), 0)::INTEGER AS pins_liked_count
    FROM route_pins
    WHERE user_id = p_user_id
  ) pin_stats ON TRUE
  -- Follower statistics
  LEFT JOIN LATERAL (
    SELECT COUNT(*)::INTEGER AS followers_count
    FROM user_follows
    WHERE following_id = p_user_id
  ) follower_stats ON TRUE
  -- Following statistics
  LEFT JOIN LATERAL (
    SELECT COUNT(*)::INTEGER AS following_count
    FROM user_follows
    WHERE follower_id = p_user_id
  ) following_stats ON TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 11. Verification Query
-- ============================================================================

-- 実行後に以下のクエリで確認してください:
-- SELECT * FROM route_pins LIMIT 1;
-- SELECT * FROM get_pins_by_route('test-route-id', 10, 0);
-- SELECT * FROM get_user_walk_statistics('test-user-id');

-- ============================================================================
-- End of Migration: 002_pins_table_v1.sql
-- ============================================================================
