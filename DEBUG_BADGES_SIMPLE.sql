-- Simple badge debugging queries

-- 1. Count all badges
SELECT 'Total badges:' as info, COUNT(*) as count FROM badges;

-- 2. Count user_badges
SELECT 'Total user_badges records:' as info, COUNT(*) as count FROM user_badges;

-- 3. Badge counts by category
SELECT category, COUNT(*) as badge_count
FROM badges
GROUP BY category
ORDER BY category;

-- 4. User badge counts
SELECT 
    p.display_name,
    COUNT(ub.badge_id) as unlocked_badges
FROM profiles p
LEFT JOIN user_badges ub ON p.user_id = ub.user_id
WHERE p.display_name IN ('test1', 'test2', 'test3')
GROUP BY p.display_name
ORDER BY p.display_name;

-- 5. Sample badges for test1
SELECT 
    badge_code,
    name_ja,
    category,
    tier,
    unlocked_at,
    is_unlocked
FROM get_user_badges((SELECT user_id FROM profiles WHERE display_name = 'test1' LIMIT 1))
LIMIT 5;

-- 6. User statistics
SELECT 
    p.display_name,
    COALESCE(SUM(r.distance_km), 0) as total_distance_km,
    COUNT(DISTINCT r.route_id) as total_routes
FROM profiles p
LEFT JOIN routes r ON p.user_id = r.user_id
WHERE p.display_name IN ('test1', 'test2', 'test3')
GROUP BY p.display_name
ORDER BY p.display_name;
