-- Restore get_areas_simple RPC function (Version 4 - CAST FIX)
-- This function retrieves all areas with their coordinates
-- Fixed: Added explicit CAST to handle varchar to text conversion

CREATE OR REPLACE FUNCTION get_areas_simple()
RETURNS TABLE (
  id uuid,
  name text,
  prefecture text,
  description text,
  latitude double precision,
  longitude double precision,
  created_at timestamp with time zone
)
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.id,
    a.name::text,
    a.prefecture::text,
    COALESCE(a.description, '')::text AS description,
    ST_Y(a.center_point::geometry) AS latitude,
    ST_X(a.center_point::geometry) AS longitude,
    a.created_at
  FROM areas a
  ORDER BY a.created_at DESC;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_areas_simple() TO authenticated;
GRANT EXECUTE ON FUNCTION get_areas_simple() TO anon;
