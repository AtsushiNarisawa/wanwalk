-- ============================================================================
-- Phase 1-1: Walks Table (散歩履歴)
-- ============================================================================
-- Description: Core table for storing walk history (both Daily and Outing)
-- Author: WanMap Development Team
-- Created: 2025-11-23
-- Version: 2 (修正版 - 未作成テーブルへの参照を削除)
-- ============================================================================
--
-- 設計方針:
-- - Daily散歩とOuting散歩を1つのテーブルで管理
-- - walk_typeカラムで区別 ('daily' or 'outing')
-- - Outing散歩のみroute_idを持つ
-- - GPS経路データはGeoJSON形式でJSONBに保存
-- - PostGISのGEOGRAPHY型を使用して地理空間検索を可能にする
-- ============================================================================

-- ============================================================================
-- 1. Enable PostGIS Extension (if not already enabled)
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================================================
-- 2. Walks Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS walks (
  -- Primary identifiers
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Walk type: 'daily' (日常散歩) or 'outing' (お出かけ散歩)
  walk_type TEXT NOT NULL CHECK (walk_type IN ('daily', 'outing')),
  
  -- Route reference (for outing walks only)
  route_id UUID REFERENCES routes(id) ON DELETE SET NULL,
  
  -- Timing information
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,
  
  -- Distance and duration
  distance_meters DECIMAL(10,2) NOT NULL DEFAULT 0,
  duration_seconds INTEGER NOT NULL DEFAULT 0,
  
  -- GPS path data (GeoJSON LineString)
  -- Example: {"type": "LineString", "coordinates": [[lng, lat], [lng, lat], ...]}
  path_geojson JSONB,
  
  -- Geographic line for spatial queries (derived from path_geojson)
  path_geography GEOGRAPHY(LINESTRING, 4326),
  
  -- Walk statistics
  average_speed_kmh DECIMAL(5,2),
  max_speed_kmh DECIMAL(5,2),
  
  -- User notes and comments
  comment TEXT,
  
  -- Weather and conditions (optional)
  weather JSONB DEFAULT '{}',
  
  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 3. Indexes for Performance
-- ============================================================================

-- Core query indexes
CREATE INDEX IF NOT EXISTS idx_walks_user_id ON walks(user_id);
CREATE INDEX IF NOT EXISTS idx_walks_walk_type ON walks(walk_type);
CREATE INDEX IF NOT EXISTS idx_walks_route_id ON walks(route_id) WHERE route_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_walks_start_time ON walks(start_time DESC);
CREATE INDEX IF NOT EXISTS idx_walks_created_at ON walks(created_at DESC);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_walks_user_type_time 
  ON walks(user_id, walk_type, start_time DESC);

-- Spatial index for geographic queries
CREATE INDEX IF NOT EXISTS idx_walks_path_geography 
  ON walks USING GIST(path_geography);

-- JSONB indexes for weather data
CREATE INDEX IF NOT EXISTS idx_walks_weather_condition 
  ON walks USING GIN(weather);

-- ============================================================================
-- 4. Triggers
-- ============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_walks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_walks_updated_at
  BEFORE UPDATE ON walks
  FOR EACH ROW
  EXECUTE FUNCTION update_walks_updated_at();

-- Auto-compute path_geography from path_geojson
CREATE OR REPLACE FUNCTION update_walks_path_geography()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.path_geojson IS NOT NULL THEN
    -- Convert GeoJSON to PostGIS Geography
    NEW.path_geography = ST_GeogFromGeoJSON(NEW.path_geojson::TEXT);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_walks_path_geography
  BEFORE INSERT OR UPDATE OF path_geojson ON walks
  FOR EACH ROW
  EXECUTE FUNCTION update_walks_path_geography();

-- Auto-compute average_speed_kmh
CREATE OR REPLACE FUNCTION update_walks_speed()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.distance_meters > 0 AND NEW.duration_seconds > 0 THEN
    -- Calculate average speed: (distance_meters / 1000) / (duration_seconds / 3600)
    NEW.average_speed_kmh = (NEW.distance_meters / 1000.0) / (NEW.duration_seconds / 3600.0);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_walks_speed
  BEFORE INSERT OR UPDATE OF distance_meters, duration_seconds ON walks
  FOR EACH ROW
  EXECUTE FUNCTION update_walks_speed();

-- ============================================================================
-- 5. Row Level Security (RLS)
-- ============================================================================

ALTER TABLE walks ENABLE ROW LEVEL SECURITY;

-- Users can view their own walks
CREATE POLICY "Users can view own walks"
  ON walks FOR SELECT
  USING (auth.uid() = user_id);

-- Users can view outing walks on public routes (for social features)
CREATE POLICY "Users can view public outing walks"
  ON walks FOR SELECT
  USING (walk_type = 'outing' AND route_id IS NOT NULL);

-- Users can insert their own walks
CREATE POLICY "Users can insert own walks"
  ON walks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own walks
CREATE POLICY "Users can update own walks"
  ON walks FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own walks
CREATE POLICY "Users can delete own walks"
  ON walks FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- 6. Comments
-- ============================================================================

COMMENT ON TABLE walks IS 'User walk history for both daily and outing walks';
COMMENT ON COLUMN walks.walk_type IS 'Type of walk: daily (日常散歩) or outing (お出かけ散歩)';
COMMENT ON COLUMN walks.route_id IS 'Reference to official route (for outing walks only)';
COMMENT ON COLUMN walks.path_geojson IS 'GPS path data in GeoJSON LineString format';
COMMENT ON COLUMN walks.path_geography IS 'PostGIS geography for spatial queries (auto-generated from path_geojson)';
COMMENT ON COLUMN walks.distance_meters IS 'Total distance walked in meters';
COMMENT ON COLUMN walks.duration_seconds IS 'Total duration in seconds';
COMMENT ON COLUMN walks.average_speed_kmh IS 'Average walking speed in km/h (auto-calculated)';
COMMENT ON COLUMN walks.weather IS 'Weather conditions during walk (JSON format)';

-- ============================================================================
-- 7. Helper RPC Functions (簡易版 - pinsとwalk_photosテーブル作成後に更新)
-- ============================================================================

-- Get daily walk history for a user
CREATE OR REPLACE FUNCTION get_daily_walk_history(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE(
  walk_id UUID,
  walked_at TIMESTAMPTZ,
  distance_meters DECIMAL,
  duration_seconds INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    id AS walk_id,
    start_time AS walked_at,
    w.distance_meters,
    w.duration_seconds
  FROM walks w
  WHERE w.user_id = p_user_id
    AND w.walk_type = 'daily'
  ORDER BY w.start_time DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get outing walk history for a user (簡易版 - photo/pinカウントなし)
CREATE OR REPLACE FUNCTION get_outing_walk_history(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE(
  walk_id UUID,
  route_id UUID,
  route_name TEXT,
  area_name TEXT,
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
    r.name AS route_name,
    a.name_ja AS area_name,
    w.start_time AS walked_at,
    w.distance_meters,
    w.duration_seconds,
    0::INTEGER AS photo_count,  -- Phase 1-3で更新予定
    0::INTEGER AS pin_count,    -- Phase 1-2で更新予定
    ARRAY[]::TEXT[] AS photo_urls -- Phase 1-3で更新予定
  FROM walks w
  LEFT JOIN routes r ON w.route_id = r.id
  LEFT JOIN areas a ON r.area_id = a.id
  WHERE w.user_id = p_user_id
    AND w.walk_type = 'outing'
  ORDER BY w.start_time DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get walk statistics for a user (internal helper)
CREATE OR REPLACE FUNCTION calculate_walk_statistics(p_user_id UUID)
RETURNS TABLE(
  total_walks INTEGER,
  total_outing_walks INTEGER,
  total_distance_km DECIMAL,
  total_duration_hours DECIMAL,
  areas_visited INTEGER,
  routes_completed INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::INTEGER AS total_walks,
    COUNT(*) FILTER (WHERE walk_type = 'outing')::INTEGER AS total_outing_walks,
    COALESCE(SUM(distance_meters) / 1000.0, 0)::DECIMAL AS total_distance_km,
    COALESCE(SUM(duration_seconds) / 3600.0, 0)::DECIMAL AS total_duration_hours,
    COUNT(DISTINCT r.area_id) FILTER (WHERE walk_type = 'outing')::INTEGER AS areas_visited,
    COUNT(DISTINCT route_id) FILTER (WHERE walk_type = 'outing')::INTEGER AS routes_completed
  FROM walks w
  LEFT JOIN routes r ON w.route_id = r.id
  WHERE w.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 8. Update get_user_walk_statistics to use walks table
-- ============================================================================

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
    -- Pin statistics (0 until pins table is created - Phase 1-2)
    0::INTEGER AS pins_created,
    0::INTEGER AS pins_liked_count,
    -- Social statistics (from existing user_follows table)
    COALESCE(follower_stats.followers_count, 0)::INTEGER AS followers_count,
    COALESCE(following_stats.following_count, 0)::INTEGER AS following_count
  FROM calculate_walk_statistics(p_user_id) ws
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
-- 9. Verification Query
-- ============================================================================

-- 実行後に以下のクエリで確認してください:
-- SELECT * FROM walks LIMIT 1;
-- SELECT * FROM get_daily_walk_history('test-user-id', 10, 0);
-- SELECT * FROM get_user_walk_statistics('test-user-id');

-- ============================================================================
-- End of Migration: 001_walks_table_v2.sql
-- ============================================================================
