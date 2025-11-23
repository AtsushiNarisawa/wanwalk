-- ============================================================
-- バッジビュー作成SQL（既存テーブルを活かす）
-- ============================================================
-- 現状確認:
--   ✓ badge_definitions テーブルは既に存在
--   ✓ user_badges テーブルも既に存在
--   ✗ badges ビューが存在しない
--
-- 対応:
--   既存のテーブル構造に合わせてbadgesビューを作成
--   requirement_type, requirement_value カラムは無いので除外
-- ============================================================

BEGIN;

-- 既存のbadgesビューを削除（存在する場合）
DROP VIEW IF EXISTS badges CASCADE;

-- 既存のbadge_definitionsテーブルに合わせたbadgesビューを作成
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
    sort_order as display_order,
    created_at,
    true as is_active  -- カラムが無いのでデフォルトtrue
FROM badge_definitions;

COMMENT ON VIEW badges IS 'badge_definitions のビュー（Flutterアプリとの互換性のため）';

-- 確認クエリ
SELECT 'badges view created successfully' as status;
SELECT 'Total badges:' as info, COUNT(*) as count FROM badges;
SELECT 'Badges by category:' as info, category, COUNT(*) as count 
FROM badges 
GROUP BY category 
ORDER BY category;

COMMIT;

-- 成功メッセージ
DO $$
DECLARE
    badge_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO badge_count FROM badges;
    RAISE NOTICE 'badgesビューが正常に作成されました！';
    RAISE NOTICE '総バッジ数: %', badge_count;
END $$;
