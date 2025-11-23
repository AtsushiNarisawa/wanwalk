-- ============================================================
-- テストユーザーにバッジを付与
-- ============================================================

BEGIN;

-- test1ユーザーに3個のバッジを付与
INSERT INTO user_badges (user_id, badge_id, is_new)
SELECT 
  p.id,
  bd.id,
  true
FROM profiles p
CROSS JOIN badge_definitions bd
WHERE p.display_name = 'test1'
  AND bd.badge_code IN ('first_walk', 'distance_10km', 'pins_5')
ON CONFLICT (user_id, badge_id) DO NOTHING;

-- test2ユーザーに2個のバッジを付与
INSERT INTO user_badges (user_id, badge_id, is_new)
SELECT 
  p.id,
  bd.id,
  true
FROM profiles p
CROSS JOIN badge_definitions bd
WHERE p.display_name = 'test2'
  AND bd.badge_code IN ('first_walk', 'distance_10km')
ON CONFLICT (user_id, badge_id) DO NOTHING;

-- test3ユーザーに1個のバッジを付与
INSERT INTO user_badges (user_id, badge_id, is_new)
SELECT 
  p.id,
  bd.id,
  true
FROM profiles p
CROSS JOIN badge_definitions bd
WHERE p.display_name = 'test3'
  AND bd.badge_code = 'first_walk'
ON CONFLICT (user_id, badge_id) DO NOTHING;

-- 確認
SELECT 
  p.display_name,
  COUNT(ub.badge_id) as unlocked_badges,
  STRING_AGG(bd.badge_code, ', ' ORDER BY bd.badge_code) as badge_codes
FROM profiles p
LEFT JOIN user_badges ub ON p.id = ub.user_id
LEFT JOIN badge_definitions bd ON ub.badge_id = bd.id
WHERE p.display_name IN ('test1', 'test2', 'test3')
GROUP BY p.display_name
ORDER BY p.display_name;

COMMIT;

-- 成功メッセージ
DO $$
BEGIN
    RAISE NOTICE 'テストユーザーにバッジを付与しました！';
    RAISE NOTICE 'test1: 3個のバッジ';
    RAISE NOTICE 'test2: 2個のバッジ';
    RAISE NOTICE 'test3: 1個のバッジ';
END $$;
