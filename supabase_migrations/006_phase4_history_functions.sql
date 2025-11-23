-- ============================================================
-- Phase 4: 散歩履歴とホーム画面用のRPC関数
-- ============================================================
-- 作成日: 2025-11-22
-- 目的: お出かけ散歩の思い出表示、履歴機能の実装

-- ============================================================
-- 1. お出かけ散歩履歴取得（写真付き）
-- ============================================================
CREATE OR REPLACE FUNCTION get_outing_walk_history(
  p_user_id UUID,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  walk_id UUID,
  route_id UUID,
  route_name TEXT,
  area_name TEXT,
  walked_at TIMESTAMPTZ,
  distance_meters FLOAT,
  duration_seconds INT,
  photo_count INT,
  pin_count INT,
  photo_urls TEXT[]
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    rw.id,
    r.id,
    r.name,
    a.name,
    rw.walked_at,
    r.distance_meters,
    rw.duration,
    (SELECT COUNT(*)::INT 
     FROM route_pins rp 
     INNER JOIN route_pin_photos rpp ON rp.id = rpp.route_pin_id
     WHERE rp.user_id = p_user_id 
       AND rp.official_route_id = r.id
       AND DATE(rp.created_at) = DATE(rw.walked_at)
    ),
    (SELECT COUNT(*)::INT 
     FROM route_pins rp 
     WHERE rp.user_id = p_user_id 
       AND rp.official_route_id = r.id
       AND DATE(rp.created_at) = DATE(rw.walked_at)
    ),
    (SELECT ARRAY_AGG(rpp.photo_url ORDER BY rpp.display_order)
     FROM route_pins rp 
     INNER JOIN route_pin_photos rpp ON rp.id = rpp.route_pin_id
     WHERE rp.user_id = p_user_id 
       AND rp.official_route_id = r.id
       AND DATE(rp.created_at) = DATE(rw.walked_at)
     LIMIT 5
    )
  FROM route_walks rw
  INNER JOIN official_routes r ON rw.route_id = r.id
  INNER JOIN areas a ON r.area_id = a.id
  WHERE rw.user_id = p_user_id
  ORDER BY rw.walked_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_outing_walk_history IS 'お出かけ散歩の履歴を写真付きで取得';

-- ============================================================
-- 2. 日常散歩履歴取得（シンプル）
-- ============================================================
CREATE OR REPLACE FUNCTION get_daily_walk_history(
  p_user_id UUID,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  walk_id UUID,
  walked_at TIMESTAMPTZ,
  distance_meters FLOAT,
  duration_seconds INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    dw.id,
    dw.walked_at,
    dw.distance_meters,
    dw.duration
  FROM daily_walks dw
  WHERE dw.user_id = p_user_id
  ORDER BY dw.walked_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_daily_walk_history IS '日常散歩の履歴をシンプルに取得';

-- ============================================================
-- 3. おすすめルート取得（ユーザープロファイルベース）
-- ============================================================
CREATE OR REPLACE FUNCTION get_recommended_routes(
  p_user_id UUID,
  p_limit INT DEFAULT 5
)
RETURNS TABLE (
  route_id UUID,
  route_name TEXT,
  area_name TEXT,
  distance_meters FLOAT,
  estimated_minutes INT,
  difficulty_level TEXT,
  total_pins INT,
  average_rating DECIMAL,
  thumbnail_url TEXT,
  features TEXT[],
  reason TEXT
) AS $$
DECLARE
  v_preferred_route_ids UUID[];
  v_total_walks INT;
BEGIN
  -- ユーザーのよく歩くルートを取得
  SELECT preferred_route_ids, (total_daily_walks + total_outing_walks)
  INTO v_preferred_route_ids, v_total_walks
  FROM user_walking_profiles
  WHERE user_id = p_user_id;

  -- まだ歩いたことがない or 履歴が少ない場合は人気ルートを返す
  IF v_total_walks IS NULL OR v_total_walks < 3 THEN
    RETURN QUERY
    SELECT
      r.id,
      r.name,
      a.name,
      r.distance_meters,
      r.estimated_minutes,
      r.difficulty_level,
      r.total_pins,
      r.average_rating,
      a.thumbnail_url,
      r.features,
      '人気のルート'::TEXT
    FROM official_routes r
    INNER JOIN areas a ON r.area_id = a.id
    WHERE r.is_active = TRUE
    ORDER BY r.total_pins DESC, r.average_rating DESC NULLS LAST
    LIMIT p_limit;
  ELSE
    -- ユーザーの好みに基づいたおすすめ
    RETURN QUERY
    SELECT
      r.id,
      r.name,
      a.name,
      r.distance_meters,
      r.estimated_minutes,
      r.difficulty_level,
      r.total_pins,
      r.average_rating,
      a.thumbnail_url,
      r.features,
      CASE 
        WHEN r.id = ANY(v_preferred_route_ids) THEN 'お気に入りのルート'
        ELSE '新しいルート'
      END::TEXT
    FROM official_routes r
    INNER JOIN areas a ON r.area_id = a.id
    WHERE r.is_active = TRUE
      AND (r.id = ANY(v_preferred_route_ids) OR r.id NOT IN (
        SELECT route_id FROM route_walks WHERE user_id = p_user_id
      ))
    ORDER BY 
      CASE WHEN r.id = ANY(v_preferred_route_ids) THEN 1 ELSE 2 END,
      r.total_pins DESC,
      r.average_rating DESC NULLS LAST
    LIMIT p_limit;
  END IF;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_recommended_routes IS 'ユーザーに最適なおすすめルートを取得';

-- ============================================================
-- 4. 人気急上昇ルート取得（直近1週間のピン数ベース）
-- ============================================================
CREATE OR REPLACE FUNCTION get_trending_routes(
  p_limit INT DEFAULT 5
)
RETURNS TABLE (
  route_id UUID,
  route_name TEXT,
  area_name TEXT,
  distance_meters FLOAT,
  estimated_minutes INT,
  difficulty_level TEXT,
  recent_pins_count INT,
  total_pins INT,
  thumbnail_url TEXT,
  features TEXT[]
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    r.id,
    r.name,
    a.name,
    r.distance_meters,
    r.estimated_minutes,
    r.difficulty_level,
    (SELECT COUNT(*)::INT 
     FROM route_pins rp 
     WHERE rp.official_route_id = r.id 
       AND rp.created_at >= NOW() - INTERVAL '7 days'
    ) as recent_pins,
    r.total_pins,
    a.thumbnail_url,
    r.features
  FROM official_routes r
  INNER JOIN areas a ON r.area_id = a.id
  WHERE r.is_active = TRUE
  ORDER BY recent_pins DESC, r.total_pins DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_trending_routes IS '人気急上昇中のルートを取得（直近1週間のピン数）';

-- ============================================================
-- 5. 最近の思い出写真取得（ホーム画面用）
-- ============================================================
CREATE OR REPLACE FUNCTION get_recent_memories(
  p_user_id UUID,
  p_limit INT DEFAULT 6
)
RETURNS TABLE (
  walk_id UUID,
  route_id UUID,
  route_name TEXT,
  walked_at TIMESTAMPTZ,
  photo_url TEXT,
  pin_count INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT ON (rw.id)
    rw.id,
    r.id,
    r.name,
    rw.walked_at,
    rpp.photo_url,
    (SELECT COUNT(*)::INT 
     FROM route_pins rp 
     WHERE rp.user_id = p_user_id 
       AND rp.official_route_id = r.id
       AND DATE(rp.created_at) = DATE(rw.walked_at)
    )
  FROM route_walks rw
  INNER JOIN official_routes r ON rw.route_id = r.id
  INNER JOIN route_pins rp ON rp.official_route_id = r.id AND rp.user_id = p_user_id
  INNER JOIN route_pin_photos rpp ON rpp.route_pin_id = rp.id
  WHERE rw.user_id = p_user_id
    AND DATE(rp.created_at) = DATE(rw.walked_at)
  ORDER BY rw.id, rw.walked_at DESC, rpp.display_order ASC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_recent_memories IS '最近の思い出写真を取得（ホーム画面プレビュー用）';

-- ============================================================
-- 6. エリア別ルート取得（お出かけ中心の並び順）
-- ============================================================
CREATE OR REPLACE FUNCTION get_routes_by_area_enhanced(
  p_area_id UUID,
  p_user_id UUID DEFAULT NULL,
  p_limit INT DEFAULT 20
)
RETURNS TABLE (
  route_id UUID,
  route_name TEXT,
  distance_meters FLOAT,
  estimated_minutes INT,
  difficulty_level TEXT,
  total_pins INT,
  average_rating DECIMAL,
  description TEXT,
  thumbnail_url TEXT,
  features TEXT[],
  has_walked BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    r.id,
    r.name,
    r.distance_meters,
    r.estimated_minutes,
    r.difficulty_level,
    r.total_pins,
    r.average_rating,
    r.description,
    a.thumbnail_url,
    r.features,
    CASE 
      WHEN p_user_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM route_walks WHERE route_id = r.id AND user_id = p_user_id
      ) THEN TRUE
      ELSE FALSE
    END
  FROM official_routes r
  INNER JOIN areas a ON r.area_id = a.id
  WHERE r.area_id = p_area_id AND r.is_active = TRUE
  ORDER BY r.total_pins DESC, r.average_rating DESC NULLS LAST
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_routes_by_area_enhanced IS 'エリア別ルート取得（写真・評価付き）';

-- ============================================================
-- Phase 4 RPC関数定義完了
-- ============================================================
-- 定義された関数：
-- 1. get_outing_walk_history() - お出かけ散歩履歴（写真付き）
-- 2. get_daily_walk_history() - 日常散歩履歴（シンプル）
-- 3. get_recommended_routes() - おすすめルート
-- 4. get_trending_routes() - 人気急上昇ルート
-- 5. get_recent_memories() - 最近の思い出写真
-- 6. get_routes_by_area_enhanced() - エリア別ルート（拡張版）
