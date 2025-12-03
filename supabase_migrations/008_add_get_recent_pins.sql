-- =====================================================
-- WanMap: ホーム画面用・最新の写真付きピン投稿取得
-- =====================================================
-- 実行日: 2025-11-29
-- 目的: ホームタブに最新の写真付きピン投稿を表示するRPC追加

-- =====================================================
-- RPC: 最新の写真付きピン投稿取得
-- =====================================================
CREATE OR REPLACE FUNCTION get_recent_pins(
  p_limit INT DEFAULT 10,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  pin_id UUID,
  route_id UUID,
  route_name TEXT,
  area_id UUID,
  area_name TEXT,
  prefecture TEXT,
  pin_type TEXT,
  title TEXT,
  comment TEXT,
  likes_count INT,
  photo_url TEXT,
  user_id UUID,
  user_name TEXT,
  user_avatar_url TEXT,
  created_at TIMESTAMPTZ,
  pin_lat FLOAT,
  pin_lon FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    rp.id AS pin_id,
    rp.route_id,
    r.title AS route_name,
    r.area_id,
    a.display_name AS area_name,
    a.prefecture,
    rp.pin_type,
    rp.title,
    rp.description AS comment,
    rp.likes_count,
    (
      SELECT rpp.photo_url
      FROM route_pin_photos rpp
      WHERE rpp.pin_id = rp.id
      ORDER BY rpp.photo_order ASC
      LIMIT 1
    ) AS photo_url,
    rp.user_id,
    COALESCE(u.raw_user_meta_data->>'display_name', 'Unknown User') AS user_name,
    COALESCE(u.raw_user_meta_data->>'avatar_url', '') AS user_avatar_url,
    rp.created_at,
    ST_Y(rp.location::geometry) AS pin_lat,
    ST_X(rp.location::geometry) AS pin_lon
  FROM route_pins rp
  JOIN official_routes r ON r.id = rp.route_id
  JOIN areas a ON a.id = r.area_id
  LEFT JOIN auth.users u ON u.id = rp.user_id
  WHERE rp.is_active = TRUE
    AND EXISTS (
      SELECT 1 FROM route_pin_photos rpp WHERE rpp.pin_id = rp.id
    )
  ORDER BY rp.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION get_recent_pins IS 'ホーム画面用：最新の写真付きピン投稿を取得（写真があるピンのみ）';
