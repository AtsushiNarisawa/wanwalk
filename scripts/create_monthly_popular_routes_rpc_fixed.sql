-- =====================================================
-- WanWalk: 今月の人気公式ルート取得RPC関数（修正版）
-- =====================================================
-- 実行日: 2025-12-08
-- 目的: ホーム画面に今月の人気公式ルート表示（過去1ヶ月の散歩回数順）
-- 修正: started_at → walked_at に変更

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
    r.name AS route_name,
    r.description,
    r.area_id,
    a.name AS area_name,
    a.prefecture,
    r.distance_meters,
    r.estimated_minutes,
    r.difficulty_level,
    r.total_walks,
    COALESCE(COUNT(rw.id), 0) AS monthly_walks,
    r.thumbnail_url,
    r.created_at
  FROM official_routes r
  JOIN areas a ON a.id = r.area_id
  LEFT JOIN route_walks rw ON rw.route_id = r.id 
    AND rw.walked_at >= NOW() - INTERVAL '1 month'
  GROUP BY r.id, a.name, a.prefecture
  ORDER BY monthly_walks DESC, r.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- 完了メッセージ
SELECT 'get_monthly_popular_official_routes RPC関数を作成しました（walked_at 使用）' AS status;

-- 動作確認クエリ
SELECT 
  route_name,
  area_name,
  monthly_walks,
  created_at
FROM get_monthly_popular_official_routes(10, 0)
ORDER BY monthly_walks DESC;
