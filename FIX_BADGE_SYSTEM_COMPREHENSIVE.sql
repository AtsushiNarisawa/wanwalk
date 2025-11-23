-- ============================================================
-- COMPREHENSIVE BADGE SYSTEM FIX
-- ============================================================
-- Purpose: Fix all issues with badge system
-- 1. Ensure all badges are defined correctly
-- 2. Run check_and_unlock_badges for all test users
-- 3. Verify get_user_badges returns correct format
-- ============================================================

BEGIN;

\echo 'Starting comprehensive badge system fix...'

-- ============================================================
-- 1. VERIFY BADGE DEFINITIONS (17 badges expected)
-- ============================================================

\echo 'Step 1: Verifying badge definitions...'

-- Count badges (should be 17)
DO $$
DECLARE
    badge_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO badge_count FROM badges;
    RAISE NOTICE 'Total badges in system: %', badge_count;
    
    IF badge_count < 17 THEN
        RAISE WARNING 'Expected 17 badges but found %. Some badges may be missing!', badge_count;
    END IF;
END $$;

-- ============================================================
-- 2. RUN BADGE UNLOCK CHECK FOR ALL TEST USERS
-- ============================================================

\echo 'Step 2: Running check_and_unlock_badges for all test users...'

-- Test1
DO $$
DECLARE
    test1_id UUID;
    newly_unlocked TEXT[];
BEGIN
    SELECT user_id INTO test1_id FROM profiles WHERE display_name = 'test1' LIMIT 1;
    
    IF test1_id IS NOT NULL THEN
        SELECT newly_unlocked_badges INTO newly_unlocked 
        FROM check_and_unlock_badges(test1_id);
        
        RAISE NOTICE 'Test1 newly unlocked badges: %', COALESCE(array_length(newly_unlocked, 1), 0);
    END IF;
END $$;

-- Test2
DO $$
DECLARE
    test2_id UUID;
    newly_unlocked TEXT[];
BEGIN
    SELECT user_id INTO test2_id FROM profiles WHERE display_name = 'test2' LIMIT 1;
    
    IF test2_id IS NOT NULL THEN
        SELECT newly_unlocked_badges INTO newly_unlocked 
        FROM check_and_unlock_badges(test2_id);
        
        RAISE NOTICE 'Test2 newly unlocked badges: %', COALESCE(array_length(newly_unlocked, 1), 0);
    END IF;
END $$;

-- Test3
DO $$
DECLARE
    test3_id UUID;
    newly_unlocked TEXT[];
BEGIN
    SELECT user_id INTO test3_id FROM profiles WHERE display_name = 'test3' LIMIT 1;
    
    IF test3_id IS NOT NULL THEN
        SELECT newly_unlocked_badges INTO newly_unlocked 
        FROM check_and_unlock_badges(test3_id);
        
        RAISE NOTICE 'Test3 newly unlocked badges: %', COALESCE(array_length(newly_unlocked, 1), 0);
    END IF;
END $$;

-- ============================================================
-- 3. VERIFY USER_BADGES RECORDS
-- ============================================================

\echo 'Step 3: Verifying user_badges records...'

DO $$
DECLARE
    test1_count INTEGER;
    test2_count INTEGER;
    test3_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO test1_count 
    FROM user_badges ub
    JOIN profiles p ON ub.user_id = p.user_id
    WHERE p.display_name = 'test1';
    
    SELECT COUNT(*) INTO test2_count 
    FROM user_badges ub
    JOIN profiles p ON ub.user_id = p.user_id
    WHERE p.display_name = 'test2';
    
    SELECT COUNT(*) INTO test3_count 
    FROM user_badges ub
    JOIN profiles p ON ub.user_id = p.user_id
    WHERE p.display_name = 'test3';
    
    RAISE NOTICE 'Test1 has % badges', test1_count;
    RAISE NOTICE 'Test2 has % badges', test2_count;
    RAISE NOTICE 'Test3 has % badges', test3_count;
END $$;

-- ============================================================
-- 4. TEST GET_USER_BADGES FUNCTION FORMAT
-- ============================================================

\echo 'Step 4: Testing get_user_badges function output format...'

DO $$
DECLARE
    test1_id UUID;
    badge_record RECORD;
    badge_count INTEGER := 0;
BEGIN
    SELECT user_id INTO test1_id FROM profiles WHERE display_name = 'test1' LIMIT 1;
    
    IF test1_id IS NOT NULL THEN
        FOR badge_record IN 
            SELECT * FROM get_user_badges(test1_id)
        LOOP
            badge_count := badge_count + 1;
            
            -- Check for required fields
            IF badge_record.is_unlocked IS NULL THEN
                RAISE WARNING 'Badge % is missing is_unlocked field', badge_record.badge_code;
            END IF;
        END LOOP;
        
        RAISE NOTICE 'get_user_badges returned % badges for test1', badge_count;
    END IF;
END $$;

-- ============================================================
-- 5. DISPLAY FINAL STATISTICS
-- ============================================================

\echo 'Step 5: Displaying final statistics...'

-- Show badge counts by category
SELECT 
    'Badge definitions by category' as report,
    category, 
    COUNT(*) as badge_count
FROM badges
GROUP BY category
ORDER BY category;

-- Show user badge counts
SELECT 
    'User badge counts' as report,
    p.display_name,
    COUNT(ub.badge_id) as unlocked_badges
FROM profiles p
LEFT JOIN user_badges ub ON p.user_id = ub.user_id
WHERE p.display_name IN ('test1', 'test2', 'test3')
GROUP BY p.display_name
ORDER BY p.display_name;

-- Show user statistics
SELECT 
    'User statistics' as report,
    p.display_name,
    COALESCE(SUM(r.distance_km), 0) as total_distance_km,
    COUNT(DISTINCT r.route_id) as total_routes,
    COUNT(DISTINCT r.route_id) FILTER (WHERE r.is_public = true) as public_routes
FROM profiles p
LEFT JOIN routes r ON p.user_id = r.user_id
WHERE p.display_name IN ('test1', 'test2', 'test3')
GROUP BY p.display_name
ORDER BY p.display_name;

\echo 'Comprehensive badge system fix completed successfully!'

COMMIT;
