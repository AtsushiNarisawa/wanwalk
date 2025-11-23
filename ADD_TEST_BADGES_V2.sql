-- ============================================================
-- テストユーザーにバッジを付与（修正版）
-- ============================================================
-- 実際のユーザー名に合わせて修正
-- ============================================================

BEGIN;

-- 既存のテストバッジを削除（クリーンスタート）
DELETE FROM user_badges 
WHERE user_id IN (
  SELECT id FROM profiles 
  WHERE display_name IN ('テストユーザー1', 'テストユーザー2', 'テストユーザー3', 'テスト', 'テストユーザー', 'romeo')
);

-- テストユーザー1に3個のバッジを付与
INSERT INTO user_badges (user_id, badge_id, is_new)
SELECT 
  p.id,
  bd.id,
  true
FROM profiles p
CROSS JOIN badge_definitions bd
WHERE p.display_name = 'テストユーザー1'
  AND bd.badge_code IN ('first_walk', 'distance_10km', 'pins_5')
ON CONFLICT (user_id, badge_id) DO NOTHING;

-- テストユーザー2に2個のバッジを付与
INSERT INTO user_badges (user_id, badge_id, is_new)
SELECT 
  p.id,
  bd.id,
  true
FROM profiles p
CROSS JOIN badge_definitions bd
WHERE p.display_name = 'テストユーザー2'
  AND bd.badge_code IN ('first_walk', 'distance_10km')
ON CONFLICT (user_id, badge_id) DO NOTHING;

-- テストユーザー3に1個のバッジを付与
INSERT INTO user_badges (user_id, badge_id, is_new)
SELECT 
  p.id,
  bd.id,
  true
FROM profiles p
CROSS JOIN badge_definitions bd
WHERE p.display_name = 'テストユーザー3'
  AND bd.badge_code = 'first_walk'
ON CONFLICT (user_id, badge_id) DO NOTHING;

-- romeo（実ユーザー）に4個のバッジを付与
INSERT INTO user_badges (user_id, badge_id, is_new)
SELECT 
  p.id,
  bd.id,
  true
FROM profiles p
CROSS JOIN badge_definitions bd
WHERE p.display_name = 'romeo'
  AND bd.badge_code IN ('first_walk', 'distance_10km', 'pins_5', 'area_3')
ON CONFLICT (user_id, badge_id) DO NOTHING;

-- 確認
SELECT 
  p.display_name,
  COUNT(ub.badge_id) as unlocked_badges,
  STRING_AGG(bd.badge_code, ', ' ORDER BY bd.badge_code) as badge_codes
FROM profiles p
LEFT JOIN user_badges ub ON p.id = ub.user_id
LEFT JOIN badge_definitions bd ON ub.badge_id = bd.id
WHERE p.display_name IN ('テストユーザー1', 'テストユーザー2', 'テストユーザー3', 'romeo')
GROUP BY p.display_name
ORDER BY p.display_name;

COMMIT;

-- 成功メッセージ
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'テストユーザーにバッジを付与しました！';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'テストユーザー1: 3個のバッジ';
    RAISE NOTICE 'テストユーザー2: 2個のバッジ';
    RAISE NOTICE 'テストユーザー3: 1個のバッジ';
    RAISE NOTICE 'romeo: 4個のバッジ';
    RAISE NOTICE '========================================';
END $$;
