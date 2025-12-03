-- =====================================================
-- WanMap: get_route_by_id_geojson RPC関数にpet_infoを追加
-- =====================================================
-- 実行日: 2025-11-30
-- 目的: ルート詳細取得時にpet_info（愛犬家向け情報）も返すように修正

CREATE OR REPLACE FUNCTION get_route_by_id_geojson(p_route_id UUID)
RETURNS TABLE (
  id UUID,
  area_id UUID,
  name TEXT,
  description TEXT,
  start_location TEXT,
  end_location TEXT,
  route_line TEXT,
  distance_meters FLOAT,
  estimated_minutes INT,
  difficulty_level TEXT,
  total_pins INT,
  thumbnail_url TEXT,
  gallery_images TEXT[],
  pet_info JSONB,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id,
    r.area_id,
    r.name,
    r.description,
    ST_AsGeoJSON(r.start_location)::TEXT AS start_location,
    ST_AsGeoJSON(r.end_location)::TEXT AS end_location,
    ST_AsGeoJSON(r.route_line)::TEXT AS route_line,
    r.distance_meters,
    r.estimated_minutes,
    r.difficulty_level,
    COALESCE(
      (SELECT COUNT(*)::INT 
       FROM route_pins rp 
       WHERE rp.route_id = r.id),
      0
    ) AS total_pins,
    r.thumbnail_url,
    r.gallery_images,
    r.pet_info,
    r.created_at,
    r.updated_at
  FROM official_routes r
  WHERE r.id = p_route_id;
END;
$$;

-- 完了メッセージ
SELECT 'get_route_by_id_geojson RPCにpet_infoを追加しました' AS status;
