-- =====================================================
-- WanMap: get_all_routes_geojson修正
-- =====================================================
-- 実行日: 2025-12-17
-- 目的: テーブル名をroutesからofficial_routesに修正、カラム追加

-- =====================================================
-- RPC: 全ての公式ルートをGeoJSON形式で取得（MAP画面用）
-- =====================================================
CREATE OR REPLACE FUNCTION get_all_routes_geojson()
RETURNS json
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  result json;
BEGIN
  SELECT json_agg(
    json_build_object(
      'id', r.id,
      'area_id', r.area_id,
      'name', r.name,
      'description', COALESCE(r.description, ''),
      'start_location', json_build_object(
        'type', 'Point',
        'coordinates', ARRAY[ST_X(r.start_location::geometry), ST_Y(r.start_location::geometry)]
      ),
      'end_location', json_build_object(
        'type', 'Point',
        'coordinates', ARRAY[ST_X(r.end_location::geometry), ST_Y(r.end_location::geometry)]
      ),
      'route_line', CASE 
        WHEN r.route_line IS NOT NULL THEN
          json_build_object(
            'type', 'LineString',
            'coordinates', (
              SELECT json_agg(json_build_array(ST_X(geom), ST_Y(geom)))
              FROM ST_DumpPoints(r.route_line::geometry) AS dp(path, geom)
            )
          )
        ELSE NULL
      END,
      'distance_meters', r.distance_meters,
      'estimated_minutes', r.estimated_minutes,
      'difficulty_level', COALESCE(r.difficulty_level, 'easy'),
      'elevation_gain_meters', r.elevation_gain_meters,
      'total_pins', COALESCE(r.total_pins, 0),
      'total_walks', COALESCE(r.total_walks, 0),
      'thumbnail_url', r.thumbnail_url,
      'gallery_images', r.gallery_images,
      'pet_info', r.pet_info,
      'created_at', r.created_at,
      'updated_at', r.updated_at
    ) ORDER BY r.created_at DESC
  ) INTO result
  FROM official_routes r;
  
  RETURN COALESCE(result, '[]'::json);
END;
$$;

COMMENT ON FUNCTION get_all_routes_geojson IS 'MAP画面用：全ての公式ルートをGeoJSON形式で取得';
