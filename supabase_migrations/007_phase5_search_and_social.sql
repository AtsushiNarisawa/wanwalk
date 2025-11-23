-- =====================================================
-- WanMap Phase 5: 検索・ソーシャル機能
-- =====================================================
-- 実行日: 2025-11-22
-- 目的: 高度な検索機能、お気に入り、フォロー、通知機能の追加

-- =====================================================
-- お気に入りルート
-- =====================================================
CREATE TABLE IF NOT EXISTS route_favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  route_id UUID REFERENCES official_routes NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, route_id)
);

CREATE INDEX route_favorites_user_idx ON route_favorites (user_id);
CREATE INDEX route_favorites_route_idx ON route_favorites (route_id);
CREATE INDEX route_favorites_created_at_idx ON route_favorites (created_at DESC);

COMMENT ON TABLE route_favorites IS 'ユーザーがお気に入り登録した公式ルート';

-- =====================================================
-- ピンブックマーク
-- =====================================================
CREATE TABLE IF NOT EXISTS pin_bookmarks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  pin_id UUID REFERENCES route_pins NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, pin_id)
);

CREATE INDEX pin_bookmarks_user_idx ON pin_bookmarks (user_id);
CREATE INDEX pin_bookmarks_pin_idx ON pin_bookmarks (pin_id);
CREATE INDEX pin_bookmarks_created_at_idx ON pin_bookmarks (created_at DESC);

COMMENT ON TABLE pin_bookmarks IS 'ユーザーが保存したピン';

-- =====================================================
-- ユーザーフォロー
-- =====================================================
CREATE TABLE IF NOT EXISTS user_follows (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  follower_id UUID REFERENCES auth.users NOT NULL,
  following_id UUID REFERENCES auth.users NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (follower_id, following_id),
  CHECK (follower_id != following_id)
);

CREATE INDEX user_follows_follower_idx ON user_follows (follower_id);
CREATE INDEX user_follows_following_idx ON user_follows (following_id);

COMMENT ON TABLE user_follows IS 'ユーザー間のフォロー関係';

-- =====================================================
-- 通知
-- =====================================================
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('new_pin', 'new_follower', 'pin_liked', 'pin_commented', 'route_walked')),
  actor_id UUID REFERENCES auth.users, -- 誰がアクションしたか
  target_id UUID, -- 対象のID（pin_id, route_idなど）
  title TEXT NOT NULL,
  body TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX notifications_user_idx ON notifications (user_id, is_read);
CREATE INDEX notifications_created_at_idx ON notifications (created_at DESC);

COMMENT ON TABLE notifications IS 'ユーザーへの通知';

-- =====================================================
-- RPC: 高度なルート検索
-- =====================================================
CREATE OR REPLACE FUNCTION search_routes(
  p_user_id UUID,
  p_query TEXT DEFAULT NULL, -- フルテキスト検索
  p_area_ids UUID[] DEFAULT NULL, -- エリアフィルター
  p_difficulties TEXT[] DEFAULT NULL, -- 難易度フィルター ['easy', 'moderate', 'hard']
  p_min_distance_km DECIMAL DEFAULT NULL,
  p_max_distance_km DECIMAL DEFAULT NULL,
  p_min_duration_min INT DEFAULT NULL,
  p_max_duration_min INT DEFAULT NULL,
  p_features TEXT[] DEFAULT NULL, -- 特徴タグフィルター
  p_best_seasons TEXT[] DEFAULT NULL, -- 季節フィルター
  p_sort_by TEXT DEFAULT 'popularity', -- 'popularity', 'distance_asc', 'distance_desc', 'rating', 'newest'
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  route_id UUID,
  area_id UUID,
  area_name TEXT,
  route_name TEXT,
  description TEXT,
  difficulty TEXT,
  distance_km DECIMAL,
  estimated_duration_minutes INT,
  elevation_gain_m INT,
  features TEXT[],
  best_seasons TEXT[],
  total_walks INT,
  total_pins INT,
  average_rating DECIMAL,
  is_favorited BOOLEAN,
  thumbnail_url TEXT,
  start_lat FLOAT,
  start_lon FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id AS route_id,
    r.area_id,
    a.display_name AS area_name,
    r.title AS route_name,
    r.description,
    r.difficulty,
    r.distance_km,
    r.estimated_duration_minutes,
    r.elevation_gain_m,
    r.features,
    r.best_seasons,
    r.total_walks,
    r.total_pins,
    r.average_rating,
    EXISTS(
      SELECT 1 FROM route_favorites rf 
      WHERE rf.route_id = r.id AND rf.user_id = p_user_id
    ) AS is_favorited,
    (
      SELECT rpp.photo_url
      FROM route_pins rp
      JOIN route_pin_photos rpp ON rpp.pin_id = rp.id
      WHERE rp.route_id = r.id AND rp.is_active = TRUE
      ORDER BY rp.created_at DESC
      LIMIT 1
    ) AS thumbnail_url,
    ST_Y(r.start_location::geometry) AS start_lat,
    ST_X(r.start_location::geometry) AS start_lon
  FROM official_routes r
  JOIN areas a ON a.id = r.area_id
  WHERE r.is_active = TRUE
    -- フルテキスト検索
    AND (
      p_query IS NULL OR
      r.title ILIKE '%' || p_query || '%' OR
      r.description ILIKE '%' || p_query || '%'
    )
    -- エリアフィルター
    AND (p_area_ids IS NULL OR r.area_id = ANY(p_area_ids))
    -- 難易度フィルター
    AND (p_difficulties IS NULL OR r.difficulty = ANY(p_difficulties))
    -- 距離フィルター
    AND (p_min_distance_km IS NULL OR r.distance_km >= p_min_distance_km)
    AND (p_max_distance_km IS NULL OR r.distance_km <= p_max_distance_km)
    -- 所要時間フィルター
    AND (p_min_duration_min IS NULL OR r.estimated_duration_minutes >= p_min_duration_min)
    AND (p_max_duration_min IS NULL OR r.estimated_duration_minutes <= p_max_duration_min)
    -- 特徴タグフィルター
    AND (p_features IS NULL OR r.features && p_features)
    -- 季節フィルター
    AND (p_best_seasons IS NULL OR r.best_seasons && p_best_seasons)
  ORDER BY 
    CASE 
      WHEN p_sort_by = 'popularity' THEN r.total_walks
      WHEN p_sort_by = 'rating' THEN COALESCE(r.average_rating, 0)::INT
      WHEN p_sort_by = 'newest' THEN EXTRACT(EPOCH FROM r.created_at)::INT
      ELSE 0
    END DESC,
    CASE 
      WHEN p_sort_by = 'distance_asc' THEN r.distance_km
      ELSE NULL
    END ASC,
    CASE 
      WHEN p_sort_by = 'distance_desc' THEN r.distance_km
      ELSE NULL
    END DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION search_routes IS '高度なルート検索（複数条件、ソート対応）';

-- =====================================================
-- RPC: お気に入りルート一覧取得
-- =====================================================
CREATE OR REPLACE FUNCTION get_favorite_routes(
  p_user_id UUID,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  route_id UUID,
  area_name TEXT,
  route_name TEXT,
  difficulty TEXT,
  distance_km DECIMAL,
  estimated_duration_minutes INT,
  total_pins INT,
  thumbnail_url TEXT,
  favorited_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id AS route_id,
    a.display_name AS area_name,
    r.title AS route_name,
    r.difficulty,
    r.distance_km,
    r.estimated_duration_minutes,
    r.total_pins,
    (
      SELECT rpp.photo_url
      FROM route_pins rp
      JOIN route_pin_photos rpp ON rpp.pin_id = rp.id
      WHERE rp.route_id = r.id AND rp.is_active = TRUE
      ORDER BY rp.created_at DESC
      LIMIT 1
    ) AS thumbnail_url,
    rf.created_at AS favorited_at
  FROM route_favorites rf
  JOIN official_routes r ON r.id = rf.route_id
  JOIN areas a ON a.id = r.area_id
  WHERE rf.user_id = p_user_id
    AND r.is_active = TRUE
  ORDER BY rf.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION get_favorite_routes IS 'ユーザーのお気に入りルート一覧';

-- =====================================================
-- RPC: 保存したピン一覧取得
-- =====================================================
CREATE OR REPLACE FUNCTION get_bookmarked_pins(
  p_user_id UUID,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  pin_id UUID,
  route_id UUID,
  route_name TEXT,
  area_name TEXT,
  pin_type TEXT,
  title TEXT,
  comment TEXT,
  likes_count INT,
  photo_urls TEXT[],
  user_name TEXT,
  bookmarked_at TIMESTAMPTZ,
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
    r.title AS route_name,
    a.display_name AS area_name,
    rp.pin_type,
    rp.title,
    rp.description AS comment,
    rp.likes_count,
    ARRAY(
      SELECT photo_url 
      FROM route_pin_photos 
      WHERE pin_id = rp.id 
      ORDER BY photo_order
    ) AS photo_urls,
    COALESCE(u.raw_user_meta_data->>'display_name', 'Unknown') AS user_name,
    pb.created_at AS bookmarked_at,
    ST_Y(rp.location::geometry) AS pin_lat,
    ST_X(rp.location::geometry) AS pin_lon
  FROM pin_bookmarks pb
  JOIN route_pins rp ON rp.id = pb.pin_id
  JOIN official_routes r ON r.id = rp.route_id
  JOIN areas a ON a.id = r.area_id
  LEFT JOIN auth.users u ON u.id = rp.user_id
  WHERE pb.user_id = p_user_id
    AND rp.is_active = TRUE
  ORDER BY pb.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION get_bookmarked_pins IS 'ユーザーが保存したピン一覧';

-- =====================================================
-- RPC: ユーザー統計取得
-- =====================================================
CREATE OR REPLACE FUNCTION get_user_statistics(
  p_user_id UUID
)
RETURNS TABLE (
  total_walks INT,
  total_outing_walks INT,
  total_distance_km DECIMAL,
  total_duration_hours DECIMAL,
  areas_visited INT,
  routes_completed INT,
  pins_created INT,
  pins_liked_count INT,
  followers_count INT,
  following_count INT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    -- 総散歩回数
    (
      SELECT COUNT(*) 
      FROM route_walks 
      WHERE user_id = p_user_id
    )::INT AS total_walks,
    
    -- お出かけ散歩回数
    (
      SELECT COUNT(*) 
      FROM route_walks 
      WHERE user_id = p_user_id
    )::INT AS total_outing_walks,
    
    -- 総距離（お出かけ散歩のみ）
    (
      SELECT COALESCE(SUM(r.distance_km), 0)
      FROM route_walks rw
      JOIN official_routes r ON r.id = rw.route_id
      WHERE rw.user_id = p_user_id
    )::DECIMAL AS total_distance_km,
    
    -- 総時間（お出かけ散歩のみ）
    (
      SELECT COALESCE(SUM(rw.duration_minutes) / 60.0, 0)
      FROM route_walks rw
      WHERE rw.user_id = p_user_id
    )::DECIMAL AS total_duration_hours,
    
    -- 訪れたエリア数
    (
      SELECT COUNT(DISTINCT r.area_id)
      FROM route_walks rw
      JOIN official_routes r ON r.id = rw.route_id
      WHERE rw.user_id = p_user_id
    )::INT AS areas_visited,
    
    -- 歩いたルート数
    (
      SELECT COUNT(DISTINCT route_id)
      FROM route_walks
      WHERE user_id = p_user_id
    )::INT AS routes_completed,
    
    -- 投稿ピン数
    (
      SELECT COUNT(*)
      FROM route_pins
      WHERE user_id = p_user_id AND is_active = TRUE
    )::INT AS pins_created,
    
    -- 自分のピンが受け取ったいいね数
    (
      SELECT COALESCE(SUM(likes_count), 0)
      FROM route_pins
      WHERE user_id = p_user_id AND is_active = TRUE
    )::INT AS pins_liked_count,
    
    -- フォロワー数
    (
      SELECT COUNT(*)
      FROM user_follows
      WHERE following_id = p_user_id
    )::INT AS followers_count,
    
    -- フォロー中の数
    (
      SELECT COUNT(*)
      FROM user_follows
      WHERE follower_id = p_user_id
    )::INT AS following_count;
END;
$$;

COMMENT ON FUNCTION get_user_statistics IS 'ユーザーの散歩統計を取得';

-- =====================================================
-- RPC: フォロー中ユーザーの最新ピン取得（タイムライン）
-- =====================================================
CREATE OR REPLACE FUNCTION get_following_timeline(
  p_user_id UUID,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  pin_id UUID,
  route_id UUID,
  route_name TEXT,
  area_name TEXT,
  pin_type TEXT,
  title TEXT,
  comment TEXT,
  likes_count INT,
  photo_urls TEXT[],
  user_id UUID,
  user_name TEXT,
  created_at TIMESTAMPTZ,
  pin_lat FLOAT,
  pin_lon FLOAT,
  is_liked BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    rp.id AS pin_id,
    rp.route_id,
    r.title AS route_name,
    a.display_name AS area_name,
    rp.pin_type,
    rp.title,
    rp.description AS comment,
    rp.likes_count,
    ARRAY(
      SELECT photo_url 
      FROM route_pin_photos 
      WHERE pin_id = rp.id 
      ORDER BY photo_order
    ) AS photo_urls,
    rp.user_id,
    COALESCE(u.raw_user_meta_data->>'display_name', 'Unknown') AS user_name,
    rp.created_at,
    ST_Y(rp.location::geometry) AS pin_lat,
    ST_X(rp.location::geometry) AS pin_lon,
    EXISTS(
      SELECT 1 FROM pin_likes pl 
      WHERE pl.pin_id = rp.id AND pl.user_id = p_user_id
    ) AS is_liked
  FROM route_pins rp
  JOIN official_routes r ON r.id = rp.route_id
  JOIN areas a ON a.id = r.area_id
  LEFT JOIN auth.users u ON u.id = rp.user_id
  WHERE rp.user_id IN (
    SELECT following_id 
    FROM user_follows 
    WHERE follower_id = p_user_id
  )
  AND rp.is_active = TRUE
  ORDER BY rp.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION get_following_timeline IS 'フォロー中ユーザーの最新ピン（タイムライン）';

-- =====================================================
-- RPC: 通知一覧取得
-- =====================================================
CREATE OR REPLACE FUNCTION get_notifications(
  p_user_id UUID,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  notification_id UUID,
  type TEXT,
  actor_id UUID,
  actor_name TEXT,
  target_id UUID,
  title TEXT,
  body TEXT,
  is_read BOOLEAN,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    n.id AS notification_id,
    n.type,
    n.actor_id,
    COALESCE(u.raw_user_meta_data->>'display_name', 'Unknown') AS actor_name,
    n.target_id,
    n.title,
    n.body,
    n.is_read,
    n.created_at
  FROM notifications n
  LEFT JOIN auth.users u ON u.id = n.actor_id
  WHERE n.user_id = p_user_id
  ORDER BY n.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION get_notifications IS 'ユーザーの通知一覧を取得';

-- =====================================================
-- RLS Policies
-- =====================================================

-- route_favorites
ALTER TABLE route_favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own favorites"
  ON route_favorites FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can add their own favorites"
  ON route_favorites FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove their own favorites"
  ON route_favorites FOR DELETE
  USING (auth.uid() = user_id);

-- pin_bookmarks
ALTER TABLE pin_bookmarks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own bookmarks"
  ON pin_bookmarks FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can add their own bookmarks"
  ON pin_bookmarks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove their own bookmarks"
  ON pin_bookmarks FOR DELETE
  USING (auth.uid() = user_id);

-- user_follows
ALTER TABLE user_follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view follows"
  ON user_follows FOR SELECT
  USING (true);

CREATE POLICY "Users can follow others"
  ON user_follows FOR INSERT
  WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow"
  ON user_follows FOR DELETE
  USING (auth.uid() = follower_id);

-- notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can mark their notifications as read"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
