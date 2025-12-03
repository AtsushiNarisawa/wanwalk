-- お気に入りルート機能
-- 作成日: 2025-11-28

-- favorite_routes テーブル
CREATE TABLE IF NOT EXISTS favorite_routes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  route_id UUID NOT NULL REFERENCES official_routes(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, route_id)
);

-- インデックス
CREATE INDEX IF NOT EXISTS idx_favorite_routes_user_id ON favorite_routes(user_id);
CREATE INDEX IF NOT EXISTS idx_favorite_routes_route_id ON favorite_routes(route_id);
CREATE INDEX IF NOT EXISTS idx_favorite_routes_created_at ON favorite_routes(created_at DESC);

-- RLS有効化
ALTER TABLE favorite_routes ENABLE ROW LEVEL SECURITY;

-- RLSポリシー: ユーザーは自分のお気に入りのみ閲覧可能
CREATE POLICY "Users can view their own favorites"
  ON favorite_routes FOR SELECT
  USING (auth.uid() = user_id);

-- RLSポリシー: ユーザーは自分のお気に入りのみ追加可能
CREATE POLICY "Users can insert their own favorites"
  ON favorite_routes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RLSポリシー: ユーザーは自分のお気に入りのみ削除可能
CREATE POLICY "Users can delete their own favorites"
  ON favorite_routes FOR DELETE
  USING (auth.uid() = user_id);

-- RPC関数: お気に入りのトグル
CREATE OR REPLACE FUNCTION toggle_favorite_route(
  p_user_id UUID,
  p_route_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_existing_id UUID;
  v_result JSONB;
BEGIN
  -- 既存のお気に入りを検索
  SELECT id INTO v_existing_id
  FROM favorite_routes
  WHERE user_id = p_user_id AND route_id = p_route_id;

  IF v_existing_id IS NOT NULL THEN
    -- お気に入り解除
    DELETE FROM favorite_routes WHERE id = v_existing_id;
    v_result := jsonb_build_object('is_favorite', false, 'message', 'Favorite removed');
  ELSE
    -- お気に入り追加
    INSERT INTO favorite_routes (user_id, route_id)
    VALUES (p_user_id, p_route_id);
    v_result := jsonb_build_object('is_favorite', true, 'message', 'Favorite added');
  END IF;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC関数: ユーザーのお気に入りルート一覧取得
CREATE OR REPLACE FUNCTION get_user_favorite_routes(
  p_user_id UUID
)
RETURNS TABLE (
  route_id UUID,
  route_name TEXT,
  area_name TEXT,
  distance_meters FLOAT,
  estimated_minutes INT,
  difficulty_level TEXT,
  total_pins INT,
  is_favorite BOOLEAN,
  favorited_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id AS route_id,
    r.name AS route_name,
    a.name AS area_name,
    r.distance_meters,
    r.estimated_minutes,
    r.difficulty_level,
    r.total_pins,
    TRUE AS is_favorite,
    f.created_at AS favorited_at
  FROM favorite_routes f
  JOIN official_routes r ON f.route_id = r.id
  JOIN areas a ON r.area_id = a.id
  WHERE f.user_id = p_user_id
  ORDER BY f.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON TABLE favorite_routes IS 'ユーザーのお気に入りルート';
COMMENT ON FUNCTION toggle_favorite_route IS 'お気に入りルートのトグル（追加/削除）';
COMMENT ON FUNCTION get_user_favorite_routes IS 'ユーザーのお気に入りルート一覧取得';
