-- ========================================
-- フェーズ3: コメント機能のデータベース実装
-- ========================================

-- 1. route_pinsテーブルにcomments_countカラムを追加
ALTER TABLE route_pins 
ADD COLUMN IF NOT EXISTS comments_count INTEGER DEFAULT 0;

-- 既存データのcomments_countを0で初期化
UPDATE route_pins SET comments_count = 0 WHERE comments_count IS NULL;

-- 2. route_pin_commentsテーブルの作成
CREATE TABLE IF NOT EXISTS route_pin_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pin_id UUID NOT NULL REFERENCES route_pins(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  comment TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- インデックスの作成（パフォーマンス向上）
CREATE INDEX IF NOT EXISTS idx_pin_comments_pin_id ON route_pin_comments(pin_id);
CREATE INDEX IF NOT EXISTS idx_pin_comments_user_id ON route_pin_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_pin_comments_created_at ON route_pin_comments(created_at DESC);

-- 3. トリガー関数: route_pinsのcomments_countを自動更新
DROP FUNCTION IF EXISTS update_pin_comments_count() CASCADE;
CREATE FUNCTION update_pin_comments_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE route_pins 
    SET comments_count = COALESCE(comments_count, 0) + 1
    WHERE id = NEW.pin_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE route_pins 
    SET comments_count = GREATEST(COALESCE(comments_count, 0) - 1, 0)
    WHERE id = OLD.pin_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- トリガーの作成
DROP TRIGGER IF EXISTS pin_comments_count_trigger ON route_pin_comments;
CREATE TRIGGER pin_comments_count_trigger
AFTER INSERT OR DELETE ON route_pin_comments
FOR EACH ROW EXECUTE FUNCTION update_pin_comments_count();

-- 4. RPC関数: コメントを追加
DROP FUNCTION IF EXISTS add_pin_comment(UUID, UUID, TEXT);
CREATE FUNCTION add_pin_comment(
  p_pin_id UUID,
  p_user_id UUID,
  p_comment TEXT
)
RETURNS JSON AS $$
DECLARE
  v_comment_id UUID;
  v_result JSON;
BEGIN
  -- 空コメントチェック
  IF p_comment IS NULL OR TRIM(p_comment) = '' THEN
    v_result := json_build_object(
      'success', false,
      'message', 'Comment cannot be empty'
    );
    RETURN v_result;
  END IF;

  -- コメント追加
  INSERT INTO route_pin_comments (pin_id, user_id, comment)
  VALUES (p_pin_id, p_user_id, p_comment)
  RETURNING id INTO v_comment_id;

  v_result := json_build_object(
    'success', true,
    'comment_id', v_comment_id,
    'message', 'Comment added successfully'
  );
  RETURN v_result;
EXCEPTION
  WHEN OTHERS THEN
    v_result := json_build_object(
      'success', false,
      'message', SQLERRM
    );
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. RPC関数: コメントを削除
DROP FUNCTION IF EXISTS delete_pin_comment(UUID, UUID);
CREATE FUNCTION delete_pin_comment(
  p_comment_id UUID,
  p_user_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
BEGIN
  -- 自分のコメントのみ削除可能
  DELETE FROM route_pin_comments
  WHERE id = p_comment_id AND user_id = p_user_id;

  IF FOUND THEN
    v_result := json_build_object(
      'success', true,
      'message', 'Comment deleted successfully'
    );
  ELSE
    v_result := json_build_object(
      'success', false,
      'message', 'Comment not found or unauthorized'
    );
  END IF;

  RETURN v_result;
EXCEPTION
  WHEN OTHERS THEN
    v_result := json_build_object(
      'success', false,
      'message', SQLERRM
    );
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. RPC関数: コメント一覧を取得
DROP FUNCTION IF EXISTS get_pin_comments(UUID, INTEGER, INTEGER);
CREATE FUNCTION get_pin_comments(
  p_pin_id UUID,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  comment_id UUID,
  user_id UUID,
  user_name TEXT,
  user_avatar TEXT,
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id AS comment_id,
    c.user_id,
    COALESCE(p.display_name, u.email) AS user_name,
    p.avatar_url AS user_avatar,
    c.comment,
    c.created_at,
    c.updated_at
  FROM route_pin_comments c
  JOIN auth.users u ON c.user_id = u.id
  LEFT JOIN profiles p ON c.user_id = p.user_id
  WHERE c.pin_id = p_pin_id
  ORDER BY c.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. RPC関数: コメント数を取得
DROP FUNCTION IF EXISTS get_pin_comments_count(UUID);
CREATE FUNCTION get_pin_comments_count(p_pin_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM route_pin_comments
  WHERE pin_id = p_pin_id;
  
  RETURN COALESCE(v_count, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 実行完了メッセージ
-- ========================================
DO $$
BEGIN
  RAISE NOTICE 'コメント機能のデータベース実装が完了しました';
  RAISE NOTICE 'テーブル: route_pin_comments';
  RAISE NOTICE 'カラム追加: route_pins.comments_count';
  RAISE NOTICE 'RPC関数: add_pin_comment, delete_pin_comment, get_pin_comments, get_pin_comments_count';
END $$;
