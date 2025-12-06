-- ========================================
-- フェーズ1: いいね機能のデータベース実装
-- ========================================

-- 1. route_pin_likes テーブルの作成
CREATE TABLE IF NOT EXISTS route_pin_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pin_id UUID NOT NULL REFERENCES route_pins(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(pin_id, user_id) -- 1ユーザー1ピンに1回のみいいね可能
);

-- インデックスの作成（パフォーマンス向上）
CREATE INDEX IF NOT EXISTS idx_pin_likes_pin_id ON route_pin_likes(pin_id);
CREATE INDEX IF NOT EXISTS idx_pin_likes_user_id ON route_pin_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_pin_likes_created_at ON route_pin_likes(created_at DESC);

-- 2. いいね数自動更新のトリガー関数
CREATE OR REPLACE FUNCTION update_pin_likes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- いいね追加時: likes_count を +1
    UPDATE route_pins SET likes_count = likes_count + 1 WHERE id = NEW.pin_id;
  ELSIF TG_OP = 'DELETE' THEN
    -- いいね削除時: likes_count を -1（0未満にならないように）
    UPDATE route_pins SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.pin_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 3. トリガーの作成
DROP TRIGGER IF EXISTS pin_likes_count_trigger ON route_pin_likes;
CREATE TRIGGER pin_likes_count_trigger
AFTER INSERT OR DELETE ON route_pin_likes
FOR EACH ROW EXECUTE FUNCTION update_pin_likes_count();

-- 4. RPC関数: いいねを追加
CREATE OR REPLACE FUNCTION like_pin(p_pin_id UUID, p_user_id UUID)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
BEGIN
  -- 既にいいね済みかチェック
  IF EXISTS (SELECT 1 FROM route_pin_likes WHERE pin_id = p_pin_id AND user_id = p_user_id) THEN
    v_result := json_build_object('success', false, 'message', 'Already liked');
    RETURN v_result;
  END IF;
  
  -- いいねを追加
  INSERT INTO route_pin_likes (pin_id, user_id) VALUES (p_pin_id, p_user_id);
  
  v_result := json_build_object('success', true, 'message', 'Liked successfully');
  RETURN v_result;
EXCEPTION
  WHEN OTHERS THEN
    v_result := json_build_object('success', false, 'message', SQLERRM);
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. RPC関数: いいねを削除
CREATE OR REPLACE FUNCTION unlike_pin(p_pin_id UUID, p_user_id UUID)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
BEGIN
  -- いいねを削除
  DELETE FROM route_pin_likes WHERE pin_id = p_pin_id AND user_id = p_user_id;
  
  IF FOUND THEN
    v_result := json_build_object('success', true, 'message', 'Unliked successfully');
  ELSE
    v_result := json_build_object('success', false, 'message', 'Like not found');
  END IF;
  
  RETURN v_result;
EXCEPTION
  WHEN OTHERS THEN
    v_result := json_build_object('success', false, 'message', SQLERRM);
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. RPC関数: ユーザーがいいね済みか確認
CREATE OR REPLACE FUNCTION check_user_liked_pin(p_pin_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (SELECT 1 FROM route_pin_likes WHERE pin_id = p_pin_id AND user_id = p_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. RPC関数: ユーザーがいいねしたピン一覧を取得
CREATE OR REPLACE FUNCTION get_user_liked_pins(p_user_id UUID, p_limit INTEGER DEFAULT 50, p_offset INTEGER DEFAULT 0)
RETURNS TABLE (
  pin_id UUID,
  route_id UUID,
  route_name TEXT,
  pin_title TEXT,
  pin_comment TEXT,
  pin_type TEXT,
  photo_url TEXT,
  likes_count INTEGER,
  liked_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    rp.id AS pin_id,
    rp.route_id,
    r.name AS route_name,
    rp.title AS pin_title,
    rp.comment AS pin_comment,
    rp.pin_type,
    (SELECT photo_url FROM route_pin_photos WHERE pin_id = rp.id ORDER BY display_order LIMIT 1) AS photo_url,
    rp.likes_count,
    rpl.created_at AS liked_at
  FROM route_pin_likes rpl
  JOIN route_pins rp ON rpl.pin_id = rp.id
  JOIN official_routes r ON rp.route_id = r.id
  WHERE rpl.user_id = p_user_id
  ORDER BY rpl.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 実行完了メッセージ
-- ========================================
DO $$
BEGIN
  RAISE NOTICE 'いいね機能のデータベース実装が完了しました';
  RAISE NOTICE 'テーブル: route_pin_likes';
  RAISE NOTICE 'RPC関数: like_pin, unlike_pin, check_user_liked_pin, get_user_liked_pins';
END $$;
