-- WanMap リニューアル Phase 1a: RPC関数定義
-- カウンター更新、いいね処理、プロファイル自動構築などのストアドプロシージャ

-- ============================================================
-- 1. いいね数の更新（トリガー関数）
-- ============================================================

-- いいねが追加されたときのトリガー関数
CREATE OR REPLACE FUNCTION increment_pin_likes()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE route_pins
  SET likes_count = likes_count + 1
  WHERE id = NEW.pin_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- いいねが削除されたときのトリガー関数
CREATE OR REPLACE FUNCTION decrement_pin_likes()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE route_pins
  SET likes_count = likes_count - 1
  WHERE id = OLD.pin_id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- トリガーの作成
DROP TRIGGER IF EXISTS on_pin_like_added ON pin_likes;
CREATE TRIGGER on_pin_like_added
  AFTER INSERT ON pin_likes
  FOR EACH ROW
  EXECUTE FUNCTION increment_pin_likes();

DROP TRIGGER IF EXISTS on_pin_like_removed ON pin_likes;
CREATE TRIGGER on_pin_like_removed
  AFTER DELETE ON pin_likes
  FOR EACH ROW
  EXECUTE FUNCTION decrement_pin_likes();

-- ============================================================
-- 2. 公式ルートの総ピン数更新（トリガー関数）
-- ============================================================

-- ピンが追加されたときのトリガー関数
CREATE OR REPLACE FUNCTION increment_route_pins()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE official_routes
  SET total_pins = total_pins + 1
  WHERE id = NEW.route_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ピンが削除されたときのトリガー関数
CREATE OR REPLACE FUNCTION decrement_route_pins()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE official_routes
  SET total_pins = total_pins - 1
  WHERE id = OLD.route_id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- トリガーの作成
DROP TRIGGER IF EXISTS on_route_pin_added ON route_pins;
CREATE TRIGGER on_route_pin_added
  AFTER INSERT ON route_pins
  FOR EACH ROW
  EXECUTE FUNCTION increment_route_pins();

DROP TRIGGER IF EXISTS on_route_pin_removed ON route_pins;
CREATE TRIGGER on_route_pin_removed
  AFTER DELETE ON route_pins
  FOR EACH ROW
  EXECUTE FUNCTION decrement_route_pins();

-- ============================================================
-- 3. いいねトグル関数（クライアントから呼び出し可能）
-- ============================================================

CREATE OR REPLACE FUNCTION toggle_pin_like(
  p_pin_id UUID,
  p_user_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_existing_like_id UUID;
  v_result JSONB;
BEGIN
  -- 既存のいいねを検索
  SELECT id INTO v_existing_like_id
  FROM pin_likes
  WHERE pin_id = p_pin_id AND user_id = p_user_id;

  IF v_existing_like_id IS NOT NULL THEN
    -- いいね解除
    DELETE FROM pin_likes WHERE id = v_existing_like_id;
    v_result := jsonb_build_object('liked', false, 'message', 'Like removed');
  ELSE
    -- いいね追加
    INSERT INTO pin_likes (pin_id, user_id)
    VALUES (p_pin_id, p_user_id);
    v_result := jsonb_build_object('liked', true, 'message', 'Like added');
  END IF;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 4. ユーザープロファイルの自動構築/更新関数
-- ============================================================

CREATE OR REPLACE FUNCTION update_user_walking_profile(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
  v_total_daily_walks INT;
  v_total_outing_walks INT;
  v_total_pins INT;
  v_total_likes_received INT;
  v_total_distance_m FLOAT;
  v_total_duration_sec INT;
  v_avg_speed_kmh FLOAT;
  v_preferred_route_ids UUID[];
BEGIN
  -- Daily散歩回数
  SELECT COUNT(*)
  INTO v_total_daily_walks
  FROM daily_walks
  WHERE user_id = p_user_id;

  -- Outing散歩回数
  SELECT COUNT(*)
  INTO v_total_outing_walks
  FROM route_walks
  WHERE user_id = p_user_id;

  -- 投稿ピン数
  SELECT COUNT(*)
  INTO v_total_pins
  FROM route_pins
  WHERE user_id = p_user_id;

  -- 受け取ったいいね数
  SELECT COALESCE(SUM(rp.likes_count), 0)
  INTO v_total_likes_received
  FROM route_pins rp
  WHERE rp.user_id = p_user_id;

  -- 累計距離と時間（Daily散歩）
  SELECT
    COALESCE(SUM(distance_meters), 0),
    COALESCE(SUM(duration_seconds), 0)
  INTO v_total_distance_m, v_total_duration_sec
  FROM daily_walks
  WHERE user_id = p_user_id;

  -- 平均速度 (km/h)
  IF v_total_duration_sec > 0 THEN
    v_avg_speed_kmh := (v_total_distance_m / 1000.0) / (v_total_duration_sec / 3600.0);
  ELSE
    v_avg_speed_kmh := 0;
  END IF;

  -- よく歩くルート（上位3件）
  SELECT ARRAY_AGG(route_id ORDER BY walk_count DESC)
  INTO v_preferred_route_ids
  FROM (
    SELECT route_id, COUNT(*) AS walk_count
    FROM route_walks
    WHERE user_id = p_user_id
    GROUP BY route_id
    ORDER BY walk_count DESC
    LIMIT 3
  ) AS top_routes;

  -- プロファイルのUPSERT
  INSERT INTO user_walking_profiles (
    user_id,
    total_daily_walks,
    total_outing_walks,
    total_pins_posted,
    total_likes_received,
    total_distance_meters,
    total_duration_seconds,
    avg_speed_kmh,
    preferred_route_ids
  )
  VALUES (
    p_user_id,
    v_total_daily_walks,
    v_total_outing_walks,
    v_total_pins,
    v_total_likes_received,
    v_total_distance_m,
    v_total_duration_sec,
    v_avg_speed_kmh,
    v_preferred_route_ids
  )
  ON CONFLICT (user_id)
  DO UPDATE SET
    total_daily_walks = EXCLUDED.total_daily_walks,
    total_outing_walks = EXCLUDED.total_outing_walks,
    total_pins_posted = EXCLUDED.total_pins_posted,
    total_likes_received = EXCLUDED.total_likes_received,
    total_distance_meters = EXCLUDED.total_distance_meters,
    total_duration_seconds = EXCLUDED.total_duration_seconds,
    avg_speed_kmh = EXCLUDED.avg_speed_kmh,
    preferred_route_ids = EXCLUDED.preferred_route_ids,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 5. 近くのルート検索関数（PostGIS使用）
-- ============================================================

CREATE OR REPLACE FUNCTION find_nearby_routes(
  p_latitude FLOAT,
  p_longitude FLOAT,
  p_radius_meters INT DEFAULT 5000,
  p_limit INT DEFAULT 20
)
RETURNS TABLE (
  route_id UUID,
  route_name TEXT,
  area_name TEXT,
  distance_meters FLOAT,
  estimated_minutes INT,
  difficulty_level TEXT,
  total_pins INT
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
    r.total_pins
  FROM official_routes r
  INNER JOIN areas a ON r.area_id = a.id
  WHERE ST_DWithin(
    r.start_location::geography,
    ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography,
    p_radius_meters
  )
  ORDER BY ST_Distance(
    r.start_location::geography,
    ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography
  )
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================
-- 6. エリア内のルート取得関数
-- ============================================================

CREATE OR REPLACE FUNCTION get_routes_by_area(
  p_area_id UUID,
  p_sort_by TEXT DEFAULT 'popularity', -- 'popularity', 'distance', 'difficulty'
  p_limit INT DEFAULT 50
)
RETURNS TABLE (
  route_id UUID,
  route_name TEXT,
  distance_meters FLOAT,
  estimated_minutes INT,
  difficulty_level TEXT,
  total_pins INT,
  description TEXT
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
    r.description
  FROM official_routes r
  WHERE r.area_id = p_area_id
  ORDER BY
    CASE
      WHEN p_sort_by = 'popularity' THEN r.total_pins
      WHEN p_sort_by = 'distance' THEN r.distance_meters::INT
      WHEN p_sort_by = 'difficulty' THEN
        CASE r.difficulty_level
          WHEN 'easy' THEN 1
          WHEN 'moderate' THEN 2
          WHEN 'hard' THEN 3
          ELSE 4
        END
      ELSE r.total_pins
    END DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================
-- 7. ルートのピン一覧取得関数（ソート対応）
-- ============================================================

CREATE OR REPLACE FUNCTION get_route_pins(
  p_route_id UUID,
  p_sort_by TEXT DEFAULT 'recent', -- 'recent', 'popular', 'nearby'
  p_user_latitude FLOAT DEFAULT NULL,
  p_user_longitude FLOAT DEFAULT NULL,
  p_limit INT DEFAULT 50
)
RETURNS TABLE (
  pin_id UUID,
  pin_type TEXT,
  title TEXT,
  comment TEXT,
  likes_count INT,
  photo_count INT,
  created_at TIMESTAMPTZ,
  distance_from_user FLOAT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.pin_type,
    p.title,
    p.comment,
    p.likes_count,
    (SELECT COUNT(*) FROM route_pin_photos WHERE pin_id = p.id)::INT,
    p.created_at,
    CASE
      WHEN p_user_latitude IS NOT NULL AND p_user_longitude IS NOT NULL THEN
        ST_Distance(
          p.location::geography,
          ST_SetSRID(ST_MakePoint(p_user_longitude, p_user_latitude), 4326)::geography
        )
      ELSE NULL
    END
  FROM route_pins p
  WHERE p.route_id = p_route_id
  ORDER BY
    CASE
      WHEN p_sort_by = 'recent' THEN p.created_at
      ELSE NULL
    END DESC,
    CASE
      WHEN p_sort_by = 'popular' THEN p.likes_count
      ELSE NULL
    END DESC,
    CASE
      WHEN p_sort_by = 'nearby' AND p_user_latitude IS NOT NULL THEN
        ST_Distance(
          p.location::geography,
          ST_SetSRID(ST_MakePoint(p_user_longitude, p_user_latitude), 4326)::geography
        )
      ELSE NULL
    END ASC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================
-- RPC関数定義完了
-- ============================================================
-- 定義された関数：
-- 1. increment_pin_likes() / decrement_pin_likes() - いいね数自動更新
-- 2. increment_route_pins() / decrement_route_pins() - ルート総ピン数自動更新
-- 3. toggle_pin_like() - いいねトグル
-- 4. update_user_walking_profile() - プロファイル自動構築
-- 5. find_nearby_routes() - 近くのルート検索
-- 6. get_routes_by_area() - エリア内ルート取得
-- 7. get_route_pins() - ルートのピン一覧取得
