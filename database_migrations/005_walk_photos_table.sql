-- ============================================================================
-- Phase 1-3: Walk Photos Table (散歩写真)
-- ============================================================================
-- Description: Table for storing photos taken during walks
-- Author: WanMap Development Team
-- Created: 2025-11-23
-- Version: 1
-- ============================================================================

-- ============================================================================
-- 1. walk_photos Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS walk_photos (
  -- Primary identifiers
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  walk_id UUID NOT NULL REFERENCES walks(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Photo details
  photo_url TEXT NOT NULL,
  display_order INTEGER NOT NULL DEFAULT 1,
  caption TEXT,
  
  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Constraint: Max 10 photos per walk
  CONSTRAINT check_max_photos_per_walk CHECK (display_order BETWEEN 1 AND 10)
);

-- ============================================================================
-- 2. Indexes for Performance
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_walk_photos_walk_id ON walk_photos(walk_id);
CREATE INDEX IF NOT EXISTS idx_walk_photos_user_id ON walk_photos(user_id);
CREATE INDEX IF NOT EXISTS idx_walk_photos_walk_order ON walk_photos(walk_id, display_order);
CREATE INDEX IF NOT EXISTS idx_walk_photos_created_at ON walk_photos(created_at DESC);

-- ============================================================================
-- 3. Row Level Security (RLS)
-- ============================================================================

ALTER TABLE walk_photos ENABLE ROW LEVEL SECURITY;

-- Anyone can view walk photos
DROP POLICY IF EXISTS "Anyone can view walk photos" ON walk_photos;
CREATE POLICY "Anyone can view walk photos"
  ON walk_photos FOR SELECT
  USING (true);

-- Users can insert photos for own walks
DROP POLICY IF EXISTS "Users can insert photos for own walks" ON walk_photos;
CREATE POLICY "Users can insert photos for own walks"
  ON walk_photos FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update photos for own walks
DROP POLICY IF EXISTS "Users can update photos for own walks" ON walk_photos;
CREATE POLICY "Users can update photos for own walks"
  ON walk_photos FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete photos for own walks
DROP POLICY IF EXISTS "Users can delete photos for own walks" ON walk_photos;
CREATE POLICY "Users can delete photos for own walks"
  ON walk_photos FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- 4. Comments
-- ============================================================================

COMMENT ON TABLE walk_photos IS 'Photos taken during walks (max 10 per walk)';
COMMENT ON COLUMN walk_photos.walk_id IS 'Reference to walk';
COMMENT ON COLUMN walk_photos.display_order IS 'Display order of photos (1-10)';
COMMENT ON COLUMN walk_photos.caption IS 'Optional photo caption';

-- ============================================================================
-- 5. Update get_outing_walk_history to include photo info
-- ============================================================================

CREATE OR REPLACE FUNCTION get_outing_walk_history(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE(
  walk_id UUID,
  route_id UUID,
  route_title TEXT,
  route_area TEXT,
  route_prefecture TEXT,
  walked_at TIMESTAMPTZ,
  distance_meters DECIMAL,
  duration_seconds INTEGER,
  photo_count INTEGER,
  pin_count INTEGER,
  photo_urls TEXT[]
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    w.id AS walk_id,
    w.route_id,
    r.title AS route_title,
    r.area AS route_area,
    r.prefecture AS route_prefecture,
    w.start_time AS walked_at,
    w.distance_meters,
    w.duration_seconds,
    -- Photo count from walk_photos table
    COALESCE((
      SELECT COUNT(*)::INTEGER
      FROM walk_photos wp
      WHERE wp.walk_id = w.id
    ), 0) AS photo_count,
    -- Pin count (still 0 - already implemented in route_pins)
    COALESCE((
      SELECT COUNT(*)::INTEGER
      FROM route_pins rp
      WHERE rp.route_id = w.route_id
        AND rp.user_id = w.user_id
    ), 0) AS pin_count,
    -- Photo URLs from walk_photos table
    COALESCE(
      ARRAY(
        SELECT wp.photo_url
        FROM walk_photos wp
        WHERE wp.walk_id = w.id
        ORDER BY wp.display_order
        LIMIT 3
      ),
      ARRAY[]::TEXT[]
    ) AS photo_urls
  FROM walks w
  LEFT JOIN routes r ON w.route_id = r.id
  WHERE w.user_id = p_user_id
    AND w.walk_type = 'outing'
  ORDER BY w.start_time DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 6. Helper RPC Functions
-- ============================================================================

-- Get photos for a specific walk
CREATE OR REPLACE FUNCTION get_walk_photos(
  p_walk_id UUID
)
RETURNS TABLE(
  photo_id UUID,
  photo_url TEXT,
  caption TEXT,
  display_order INTEGER,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    id AS photo_id,
    wp.photo_url,
    wp.caption,
    wp.display_order,
    wp.created_at
  FROM walk_photos wp
  WHERE wp.walk_id = p_walk_id
  ORDER BY wp.display_order;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 7. Verification Query
-- ============================================================================

-- 実行後に以下のクエリで確認してください:
-- SELECT * FROM walk_photos LIMIT 1;
-- SELECT * FROM get_walk_photos('test-walk-id');
-- SELECT * FROM get_outing_walk_history('test-user-id', 10, 0);

-- ============================================================================
-- End of Migration: 005_walk_photos_table.sql
-- ============================================================================
