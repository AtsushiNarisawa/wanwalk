-- ========================================
-- get_recent_pins RPC関数を更新してcomments_countを追加
-- ========================================

DROP FUNCTION IF EXISTS get_recent_pins(INTEGER, INTEGER);

CREATE FUNCTION get_recent_pins(
  p_limit INTEGER DEFAULT 10,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE(
  pin_id UUID,
  route_id UUID,
  route_name TEXT,
  area_id UUID,
  area_name TEXT,
  prefecture TEXT,
  pin_type TEXT,
  title TEXT,
  comment TEXT,
  likes_count INTEGER,
  comments_count INTEGER,  -- 🆕 追加
  photo_url TEXT,
  user_id UUID,
  user_name TEXT,           -- 🆕 追加
  user_avatar_url TEXT,     -- 🆕 追加
  created_at TIMESTAMP WITH TIME ZONE,
  pin_lat DOUBLE PRECISION,
  pin_lon DOUBLE PRECISION
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    rp.id AS pin_id,
    rp.route_id,
    r.name::TEXT AS route_name,
    r.area_id,
    a.name::TEXT AS area_name,
    a.prefecture::TEXT,
    rp.pin_type,
    rp.title,
    rp.comment,
    rp.likes_count,
    rp.comments_count,  -- 🆕 追加
    (
      SELECT rpp.photo_url
      FROM route_pin_photos rpp
      WHERE rpp.pin_id = rp.id
      ORDER BY rpp.display_order ASC
      LIMIT 1
    ) AS photo_url,
    rp.user_id,
    COALESCE(p.display_name, u.email) AS user_name,  -- 🆕 追加
    p.avatar_url AS user_avatar_url,                  -- 🆕 追加
    rp.created_at,
    ST_Y(rp.location::geometry) AS pin_lat,
    ST_X(rp.location::geometry) AS pin_lon
  FROM route_pins rp
  JOIN official_routes r ON r.id = rp.route_id
  JOIN areas a ON a.id = r.area_id
  JOIN auth.users u ON rp.user_id = u.id             -- 🆕 追加
  LEFT JOIN profiles p ON rp.user_id = p.user_id     -- 🆕 追加
  WHERE EXISTS (
    SELECT 1 FROM route_pin_photos rpp WHERE rpp.pin_id = rp.id
  )
  ORDER BY rp.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 実行完了メッセージ
-- ========================================
DO $$
BEGIN
  RAISE NOTICE 'get_recent_pins関数を更新しました';
  RAISE NOTICE '追加フィールド: comments_count, user_name, user_avatar_url';
END $$;
