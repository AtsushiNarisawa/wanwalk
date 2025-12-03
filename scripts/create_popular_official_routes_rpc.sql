-- =====================================================
-- WanMap: 人気の公式ルート取得RPC関数
-- =====================================================
-- 実行日: 2025-11-30
-- 目的: ホーム画面に人気の公式ルートを表示（散歩回数順）

-- 散歩回数を管理するカラムが存在しない場合は追加
ALTER TABLE public.official_routes 
ADD COLUMN IF NOT EXISTS total_walks INT DEFAULT 0;

-- コメントを追加
COMMENT ON COLUMN public.official_routes.total_walks IS 'このルートで散歩した総回数';

-- インデックスを追加（ソート高速化）
CREATE INDEX IF NOT EXISTS idx_official_routes_total_walks 
ON public.official_routes (total_walks DESC);

-- =====================================================
-- RPC: 人気の公式ルート取得（散歩回数順）
-- =====================================================
CREATE OR REPLACE FUNCTION get_popular_official_routes(
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
    r.thumbnail_url,
    r.created_at
  FROM official_routes r
  JOIN areas a ON a.id = r.area_id
  ORDER BY r.total_walks DESC, r.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- 完了メッセージ
SELECT 'get_popular_official_routes RPC関数を作成しました' AS status;
