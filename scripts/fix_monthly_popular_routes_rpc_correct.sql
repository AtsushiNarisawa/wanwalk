-- =====================================================
-- WanWalk: 今月の人気公式ルート取得RPC関数（正しいテーブル構造版）
-- =====================================================
-- 実行日: 2025-12-10
-- 目的: walksテーブル（walk_type='outing'）を使用するように修正
-- 修正: route_walks → walks に変更

-- =====================================================
-- RPC: 今月の人気公式ルート取得（過去1ヶ月の散歩回数順）
-- =====================================================
CREATE OR REPLACE FUNCTION get_monthly_popular_official_routes(
  p_limit INT DEFAULT 10,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  route_id UUID,
  route_name TEXT,
  description TEXT,
  area_id UUID,
  area_name TEXT,
  prefecture TEXT,
  distance_meters NUMERIC,
  estimated_minutes INT,
  difficulty_level TEXT,
  total_walks INT,
  monthly_walks BIGINT,
  thumbnail_url TEXT,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id AS route_id,
    r.title AS route_name,
    r.description,
    r.area_id,
    a.name AS area_name,
    a.prefecture,
    r.distance_meters,
    r.estimated_minutes,
    r.difficulty AS difficulty_level,
    r.total_walks,
    COALESCE(COUNT(w.id) FILTER (WHERE w.start_time >= NOW() - INTERVAL '1 month'), 0) AS monthly_walks,
    r.thumbnail_url,
    r.created_at
  FROM official_routes r
  JOIN areas a ON a.id = r.area_id
  LEFT JOIN walks w ON w.route_id = r.id AND w.walk_type = 'outing'
  GROUP BY r.id, r.title, r.description, r.area_id, a.name, a.prefecture, 
           r.distance_meters, r.estimated_minutes, r.difficulty, r.total_walks, 
           r.thumbnail_url, r.created_at
  ORDER BY monthly_walks DESC, r.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- 完了メッセージ
SELECT 'get_monthly_popular_official_routes RPC関数を修正しました（walksテーブル使用）' AS status;

-- 動作確認クエリ
SELECT 
  route_name,
  area_name,
  monthly_walks,
  distance_meters / 1000.0 AS distance_km,
  estimated_minutes
FROM get_monthly_popular_official_routes(10, 0)
ORDER BY monthly_walks DESC;
