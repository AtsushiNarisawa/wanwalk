-- =====================================================
-- WanWalk: get_recent_pins修正（route_id=NULL対応）
-- =====================================================
-- 実行日: 2025-12-17
-- 目的: route_idがnullのピン（ルートに紐づかないピン）も取得できるように修正

-- =====================================================
-- RPC: 最新の写真付きピン投稿取得（route_id=NULL対応）
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
  area_name VARCHAR(100),
  prefecture VARCHAR(50),
  pin_type TEXT,
  title TEXT,
  comment TEXT,
  likes_count INT,
  comments_count INT,
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
    official_routes.name AS route_name,
    official_routes.area_id,
    areas.name AS area_name,
    areas.prefecture,
    rp.pin_type,
    rp.title,
    rp.comment,
    rp.likes_count,
    0 AS comments_count,  -- コメント機能未実装のため0
    (
      SELECT rpp.photo_url
      FROM route_pin_photos rpp
      WHERE rpp.pin_id = rp.id
      ORDER BY rpp.display_order ASC
      LIMIT 1
    ) AS photo_url,
    rp.user_id,
    COALESCE(auth.users.raw_user_meta_data->>'display_name', 'Unknown User') AS user_name,
    COALESCE(auth.users.raw_user_meta_data->>'avatar_url', '') AS user_avatar_url,
    rp.created_at,
    ST_Y(rp.location::geometry) AS pin_lat,
    ST_X(rp.location::geometry) AS pin_lon
  FROM route_pins rp
  LEFT JOIN official_routes ON official_routes.id = rp.route_id
  LEFT JOIN areas ON areas.id = official_routes.area_id
  LEFT JOIN auth.users ON auth.users.id = rp.user_id
  WHERE EXISTS (
    SELECT 1 FROM route_pin_photos rpp WHERE rpp.pin_id = rp.id
  )
  ORDER BY rp.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION get_recent_pins IS 'ホーム画面用：最新の写真付きピン投稿を取得（route_id=NULLのピンも含む）';
