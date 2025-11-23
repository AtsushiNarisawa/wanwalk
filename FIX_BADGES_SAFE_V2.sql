-- ============================================================
-- バッジシステム修正SQL（安全版 v2）
-- ============================================================
-- 修正: 既存関数を先に削除してから再作成
-- ============================================================

BEGIN;

-- ========================================
-- ステップ1: 既存の関数を削除
-- ========================================

DROP FUNCTION IF EXISTS get_user_badges(uuid);
DROP FUNCTION IF EXISTS mark_badges_as_seen(uuid);

-- ========================================
-- ステップ2: badgesビューを作成
-- ========================================

DROP VIEW IF EXISTS badges CASCADE;

CREATE VIEW badges AS
SELECT 
    id as badge_id,
    badge_code,
    name_ja,
    name_en,
    description,
    icon_name,
    category,
    tier,
    created_at
FROM badge_definitions;

COMMENT ON VIEW badges IS 'badge_definitions のビュー（Flutterアプリとの互換性のため）';

-- ========================================
-- ステップ3: get_user_badges 関数を作成
-- ========================================

CREATE FUNCTION get_user_badges(p_user_id UUID)
RETURNS TABLE (
  badge_id UUID,
  badge_code TEXT,
  name_ja TEXT,
  name_en TEXT,
  description TEXT,
  icon_name TEXT,
  category TEXT,
  tier TEXT,
  unlocked_at TIMESTAMPTZ,
  is_new BOOLEAN,
  is_unlocked BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    bd.id AS badge_id,
    bd.badge_code,
    bd.name_ja,
    bd.name_en,
    bd.description,
    bd.icon_name,
    bd.category,
    bd.tier,
    ub.unlocked_at,
    COALESCE(ub.is_new, FALSE) AS is_new,
    (ub.id IS NOT NULL) AS is_unlocked
  FROM badge_definitions bd
  LEFT JOIN user_badges ub ON ub.badge_id = bd.id AND ub.user_id = p_user_id
  ORDER BY bd.sort_order;
END;
$$;

COMMENT ON FUNCTION get_user_badges IS 'ユーザーの全バッジ（解除済み・未解除）を取得';

-- ========================================
-- ステップ4: mark_badges_as_seen 関数を作成
-- ========================================

CREATE FUNCTION mark_badges_as_seen(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE user_badges
  SET is_new = FALSE
  WHERE user_id = p_user_id AND is_new = TRUE;
END;
$$;

COMMENT ON FUNCTION mark_badges_as_seen IS '新規バッジを既読状態に更新';

-- ========================================
-- ステップ5: 確認クエリ
-- ========================================

SELECT '✓ badges view created' as status;
SELECT '✓ get_user_badges function created' as status;
SELECT '✓ mark_badges_as_seen function created' as status;

SELECT 'Total badges in view:' as info, COUNT(*) as count FROM badges;
SELECT 'Badges by category:' as info, category, COUNT(*) as count 
FROM badges 
GROUP BY category 
ORDER BY category;

COMMIT;

-- ========================================
-- 成功メッセージ
-- ========================================

DO $$
DECLARE
    badge_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO badge_count FROM badges;
    RAISE NOTICE '========================================';
    RAISE NOTICE 'バッジシステム修正完了！';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✓ badges ビュー作成完了';
    RAISE NOTICE '✓ get_user_badges() 関数作成完了';
    RAISE NOTICE '✓ mark_badges_as_seen() 関数作成完了';
    RAISE NOTICE '総バッジ数: %', badge_count;
    RAISE NOTICE '========================================';
END $$;
