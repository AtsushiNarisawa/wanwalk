-- ========================================
-- フェーズ2: ブックマーク機能のデータベース実装
-- ========================================

-- 1. route_pin_bookmarks テーブルの作成
CREATE TABLE IF NOT EXISTS route_pin_bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pin_id UUID NOT NULL REFERENCES route_pins(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(pin_id, user_id)
);

-- インデックスの作成（パフォーマンス向上）
CREATE INDEX IF NOT EXISTS idx_pin_bookmarks_pin_id ON route_pin_bookmarks(pin_id);
CREATE INDEX IF NOT EXISTS idx_pin_bookmarks_user_id ON route_pin_bookmarks(user_id);
CREATE INDEX IF NOT EXISTS idx_pin_bookmarks_created_at ON route_pin_bookmarks(created_at DESC);

-- 2. RPC関数: ブックマークを追加
DROP FUNCTION IF EXISTS bookmark_pin(UUID, UUID);
CREATE FUNCTION bookmark_pin(p_pin_id UUID, p_user_id UUID)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
BEGIN
  IF EXISTS (SELECT 1 FROM route_pin_bookmarks WHERE pin_id = p_pin_id AND user_id = p_user_id) THEN
    v_result := json_build_object('success', false, 'message', 'Already bookmarked');
    RETURN v_result;
  END IF;
  
  INSERT INTO route_pin_bookmarks (pin_id, user_id) VALUES (p_pin_id, p_user_id);
  
  v_result := json_build_object('success', true, 'message', 'Bookmarked successfully');
  RETURN v_result;
EXCEPTION
  WHEN OTHERS THEN
    v_result := json_build_object('success', false, 'message', SQLERRM);
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. RPC関数: ブックマークを削除
DROP FUNCTION IF EXISTS unbookmark_pin(UUID, UUID);
CREATE FUNCTION unbookmark_pin(p_pin_id UUID, p_user_id UUID)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
BEGIN
  DELETE FROM route_pin_bookmarks WHERE pin_id = p_pin_id AND user_id = p_user_id;
  
  IF FOUND THEN
    v_result := json_build_object('success', true, 'message', 'Unbookmarked successfully');
  ELSE
    v_result := json_build_object('success', false, 'message', 'Bookmark not found');
  END IF;
  
  RETURN v_result;
EXCEPTION
  WHEN OTHERS THEN
    v_result := json_build_object('success', false, 'message', SQLERRM);
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. RPC関数: ユーザーがブックマーク済みか確認
DROP FUNCTION IF EXISTS check_user_bookmarked_pin(UUID, UUID);
CREATE FUNCTION check_user_bookmarked_pin(p_pin_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (SELECT 1 FROM route_pin_bookmarks WHERE pin_id = p_pin_id AND user_id = p_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. RPC関数: ユーザーがブックマークしたピン一覧を取得
DROP FUNCTION IF EXISTS get_user_bookmarked_pins(UUID, INTEGER, INTEGER);
CREATE FUNCTION get_user_bookmarked_pins(p_user_id UUID, p_limit INTEGER DEFAULT 50, p_offset INTEGER DEFAULT 0)
RETURNS TABLE (
  pin_id UUID,
  route_id UUID,
  route_name TEXT,
  area_name TEXT,
  pin_title TEXT,
  pin_comment TEXT,
  pin_type TEXT,
  photo_url TEXT,
  likes_count INTEGER,
  bookmarked_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    rp.id AS pin_id,
    rp.route_id,
    r.name AS route_name,
    a.name AS area_name,
    rp.title AS pin_title,
    rp.comment AS pin_comment,
    rp.pin_type,
    (SELECT photo_url FROM route_pin_photos WHERE pin_id = rp.id ORDER BY display_order LIMIT 1) AS photo_url,
    rp.likes_count,
    rpb.created_at AS bookmarked_at
  FROM route_pin_bookmarks rpb
  JOIN route_pins rp ON rpb.pin_id = rp.id
  JOIN official_routes r ON rp.route_id = r.id
  JOIN areas a ON r.area_id = a.id
  WHERE rpb.user_id = p_user_id
  ORDER BY rpb.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 実行完了メッセージ
-- ========================================
DO $$
BEGIN
  RAISE NOTICE 'ブックマーク機能のデータベース実装が完了しました';
  RAISE NOTICE 'テーブル: route_pin_bookmarks';
  RAISE NOTICE 'RPC関数: bookmark_pin, unbookmark_pin, check_user_bookmarked_pin, get_user_bookmarked_pins';
END $$;
