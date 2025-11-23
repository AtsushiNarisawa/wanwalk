-- ============================================================
-- PHASE 5-5 COMPREHENSIVE DEBUG SCRIPT
-- ============================================================
-- Purpose: Debug all remaining issues with badge system
-- 1. Check badge definitions
-- 2. Check user_badges records
-- 3. Check get_user_badges function
-- 4. Test badge queries for test users
-- 5. Check statistics for badge eligibility
-- ============================================================

\echo '========================================='
\echo 'PHASE 5-5 COMPREHENSIVE DEBUGGING'
\echo '========================================='
\echo ''

-- ============================================================
-- 1. CHECK BADGE DEFINITIONS
-- ============================================================
\echo '1. BADGE DEFINITIONS (should be 17 badges):'
\echo '-----------------------------------------'
SELECT 
    badge_code,
    name_ja,
    category,
    tier,
    requirement_type,
    requirement_value
FROM badges
ORDER BY category, tier;

\echo ''
\echo 'Badge count by category:'
SELECT category, COUNT(*) as badge_count
FROM badges
GROUP BY category
ORDER BY category;

\echo ''

-- ============================================================
-- 2. CHECK USER_BADGES RECORDS
-- ============================================================
\echo '2. USER_BADGES RECORDS:'
\echo '-----------------------------------------'
SELECT 
    ub.user_id,
    p.display_name,
    b.badge_code,
    b.name_ja,
    b.category,
    b.tier,
    ub.unlocked_at,
    ub.is_new
FROM user_badges ub
JOIN badges b ON ub.badge_id = b.badge_id
JOIN profiles p ON ub.user_id = p.user_id
ORDER BY ub.user_id, ub.unlocked_at DESC;

\echo ''
\echo 'User badge counts:'
SELECT 
    p.display_name,
    COUNT(*) as badge_count
FROM user_badges ub
JOIN profiles p ON ub.user_id = p.user_id
GROUP BY p.display_name
ORDER BY p.display_name;

\echo ''

-- ============================================================
-- 3. CHECK GET_USER_BADGES FUNCTION
-- ============================================================
\echo '3. TESTING get_user_badges FUNCTION:'
\echo '-----------------------------------------'

-- Get test1 user ID
\set test1_id `psql -d "postgresql://postgres.enmmmxkwdfnxjmgbpccz:wanmap2024Secure!@aws-0-ap-northeast-1.pooler.supabase.com:6543/postgres" -t -A -c "SELECT user_id FROM profiles WHERE display_name = 'test1' LIMIT 1"`

\echo 'Test1 user ID:' :test1_id
\echo ''

-- Test get_user_badges for test1
\echo 'Calling get_user_badges for test1:'
SELECT * FROM get_user_badges(:test1_id\\:\\:uuid);

\echo ''

-- ============================================================
-- 4. CHECK USER STATISTICS
-- ============================================================
\echo '4. USER STATISTICS (for badge eligibility):'
\echo '-----------------------------------------'

-- Get statistics for test users
SELECT 
    p.display_name,
    COALESCE(SUM(r.distance_km), 0) as total_distance_km,
    COUNT(DISTINCT r.route_id) as total_routes,
    COUNT(DISTINCT r.route_id) FILTER (WHERE r.is_public = true) as public_routes
FROM profiles p
LEFT JOIN routes r ON p.user_id = r.user_id
WHERE p.display_name IN ('test1', 'test2', 'test3')
GROUP BY p.display_name
ORDER BY p.display_name;

\echo ''

-- ============================================================
-- 5. CHECK BADGE ELIGIBILITY
-- ============================================================
\echo '5. BADGE ELIGIBILITY CHECK:'
\echo '-----------------------------------------'

WITH user_stats AS (
    SELECT 
        p.user_id,
        p.display_name,
        COALESCE(SUM(r.distance_km), 0) as total_distance_km,
        COUNT(DISTINCT r.route_id) as total_routes
    FROM profiles p
    LEFT JOIN routes r ON p.user_id = r.user_id
    WHERE p.display_name IN ('test1', 'test2', 'test3')
    GROUP BY p.user_id, p.display_name
)
SELECT 
    us.display_name,
    us.total_distance_km,
    us.total_routes,
    b.badge_code,
    b.name_ja,
    b.requirement_value,
    CASE 
        WHEN b.requirement_type = 'distance_km' THEN 
            CASE WHEN us.total_distance_km >= b.requirement_value THEN 'ELIGIBLE' ELSE 'NOT YET' END
        WHEN b.requirement_type = 'routes_count' THEN 
            CASE WHEN us.total_routes >= b.requirement_value THEN 'ELIGIBLE' ELSE 'NOT YET' END
        ELSE 'UNKNOWN'
    END as eligibility
FROM user_stats us
CROSS JOIN badges b
WHERE b.requirement_type IN ('distance_km', 'routes_count')
ORDER BY us.display_name, b.badge_code;

\echo ''

-- ============================================================
-- 6. CHECK FOR MISSING BADGES
-- ============================================================
\echo '6. MISSING BADGES (should be unlocked but are not):'
\echo '-----------------------------------------'

WITH user_stats AS (
    SELECT 
        p.user_id,
        p.display_name,
        COALESCE(SUM(r.distance_km), 0) as total_distance_km,
        COUNT(DISTINCT r.route_id) as total_routes
    FROM profiles p
    LEFT JOIN routes r ON p.user_id = r.user_id
    WHERE p.display_name IN ('test1', 'test2', 'test3')
    GROUP BY p.user_id, p.display_name
),
eligible_badges AS (
    SELECT 
        us.user_id,
        us.display_name,
        b.badge_id,
        b.badge_code,
        b.name_ja
    FROM user_stats us
    CROSS JOIN badges b
    WHERE (
        (b.requirement_type = 'distance_km' AND us.total_distance_km >= b.requirement_value)
        OR (b.requirement_type = 'routes_count' AND us.total_routes >= b.requirement_value)
    )
)
SELECT 
    eb.display_name,
    eb.badge_code,
    eb.name_ja,
    'Should be unlocked' as status
FROM eligible_badges eb
WHERE NOT EXISTS (
    SELECT 1 
    FROM user_badges ub 
    WHERE ub.user_id = eb.user_id 
    AND ub.badge_id = eb.badge_id
)
ORDER BY eb.display_name, eb.badge_code;

\echo ''

-- ============================================================
-- 7. CHECK DATABASE FUNCTION RESULT FORMAT
-- ============================================================
\echo '7. CHECK get_user_badges RETURN FORMAT:'
\echo '-----------------------------------------'

\echo 'Sample output from get_user_badges (should include is_unlocked field):'
SELECT 
    badge_id,
    badge_code,
    name_ja,
    name_en,
    description,
    icon_name,
    category,
    tier,
    unlocked_at,
    is_new,
    is_unlocked
FROM get_user_badges(:test1_id\\:\\:uuid)
LIMIT 3;

\echo ''

-- ============================================================
-- 8. SUMMARY
-- ============================================================
\echo '========================================='
\echo 'DEBUGGING SUMMARY'
\echo '========================================='
\echo 'Total badges in system:'
SELECT COUNT(*) FROM badges;

\echo ''
\echo 'Total user_badges records:'
SELECT COUNT(*) FROM user_badges;

\echo ''
\echo 'Users with badges:'
SELECT 
    p.display_name,
    COUNT(ub.badge_id) as unlocked_badges
FROM profiles p
LEFT JOIN user_badges ub ON p.user_id = ub.user_id
WHERE p.display_name IN ('test1', 'test2', 'test3')
GROUP BY p.display_name
ORDER BY p.display_name;

\echo ''
\echo '========================================='
\echo 'END OF DEBUGGING'
\echo '========================================='
