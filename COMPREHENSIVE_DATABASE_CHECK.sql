-- ============================================================
-- 包括的データベース実装状況確認
-- Phase 1 - Phase 5 の全機能確認
-- ============================================================

\echo '========================================='
\echo 'PHASE 1-5 包括的データベース実装状況確認'
\echo '========================================='
\echo ''

-- ============================================================
-- 1. テーブル一覧確認
-- ============================================================
\echo '========================================='
\echo '1. テーブル一覧'
\echo '========================================='

SELECT 
    schemaname,
    tablename,
    CASE 
        WHEN tablename LIKE '%user%' OR tablename LIKE '%profile%' THEN 'Phase 1: User/Auth'
        WHEN tablename LIKE '%route%' OR tablename LIKE '%walk%' THEN 'Phase 1: Route/Walk'
        WHEN tablename LIKE '%pin%' OR tablename LIKE '%photo%' THEN 'Phase 1: Pin/Photo'
        WHEN tablename LIKE '%area%' OR tablename LIKE '%official%' THEN 'Phase 2: Area'
        WHEN tablename LIKE '%history%' OR tablename LIKE '%trip%' THEN 'Phase 4: History'
        WHEN tablename LIKE '%follow%' OR tablename LIKE '%like%' OR tablename LIKE '%favorite%' THEN 'Phase 5: Social'
        WHEN tablename LIKE '%badge%' THEN 'Phase 5: Badge'
        WHEN tablename LIKE '%notification%' THEN 'Phase 5: Notification'
        ELSE 'Other'
    END as phase_category
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY phase_category, tablename;

\echo ''

-- ============================================================
-- 2. Phase 1: 基本機能確認
-- ============================================================
\echo '========================================='
\echo '2. PHASE 1: 基本機能テーブル'
\echo '========================================='

\echo 'Phase 1 必須テーブル:'
SELECT 
    table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = t.table_name) 
        THEN '✓ 存在' 
        ELSE '✗ 不足' 
    END as status
FROM (VALUES 
    ('profiles'),
    ('routes'),
    ('route_points'),
    ('pins'),
    ('pin_photos')
) AS t(table_name);

\echo ''
\echo 'プロフィールテーブルのカラム:'
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'profiles'
ORDER BY ordinal_position;

\echo ''
\echo 'ルートテーブルのカラム:'
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'routes'
ORDER BY ordinal_position;

\echo ''

-- ============================================================
-- 3. Phase 2: エリア機能確認
-- ============================================================
\echo '========================================='
\echo '3. PHASE 2: エリア機能テーブル'
\echo '========================================='

\echo 'Phase 2 必須テーブル:'
SELECT 
    table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = t.table_name) 
        THEN '✓ 存在' 
        ELSE '✗ 不足' 
    END as status
FROM (VALUES 
    ('areas'),
    ('official_routes')
) AS t(table_name);

\echo ''
\echo 'エリアテーブルの確認:'
SELECT 
    'areas' as table_name,
    COUNT(*) as record_count
FROM areas;

\echo ''

-- ============================================================
-- 4. Phase 3: 検索機能確認（Phase 5に統合）
-- ============================================================
\echo '========================================='
\echo '4. PHASE 3: 検索機能（Phase 5実装）'
\echo '========================================='

\echo '検索関連RPC関数:'
SELECT 
    routine_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = r.routine_name) 
        THEN '✓ 存在' 
        ELSE '✗ 不足' 
    END as status
FROM (VALUES 
    ('search_routes'),
    ('search_users')
) AS r(routine_name);

\echo ''

-- ============================================================
-- 5. Phase 4: 履歴機能確認
-- ============================================================
\echo '========================================='
\echo '5. PHASE 4: 履歴機能テーブル'
\echo '========================================='

\echo 'Phase 4 必須テーブル:'
SELECT 
    table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = t.table_name) 
        THEN '✓ 存在' 
        ELSE '✗ 不足' 
    END as status
FROM (VALUES 
    ('trips'),
    ('trip_routes')
) AS t(table_name);

\echo ''

\echo '履歴関連RPC関数:'
SELECT 
    routine_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = r.routine_name) 
        THEN '✓ 存在' 
        ELSE '✗ 不足' 
    END as status
FROM (VALUES 
    ('get_user_trip_history'),
    ('get_trip_details')
) AS r(routine_name);

\echo ''

-- ============================================================
-- 6. Phase 5: ソーシャル機能確認
-- ============================================================
\echo '========================================='
\echo '6. PHASE 5: ソーシャル機能テーブル'
\echo '========================================='

\echo 'Phase 5 ソーシャル必須テーブル:'
SELECT 
    table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = t.table_name) 
        THEN '✓ 存在' 
        ELSE '✗ 不足' 
    END as status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = t.table_name)
        THEN (SELECT COUNT(*)::text FROM information_schema.columns WHERE table_schema = 'public' AND table_name = t.table_name)
        ELSE '0'
    END as column_count
FROM (VALUES 
    ('follows'),
    ('likes'),
    ('favorites'),
    ('notifications')
) AS t(table_name);

\echo ''

-- ============================================================
-- 7. Phase 5: バッジシステム確認
-- ============================================================
\echo '========================================='
\echo '7. PHASE 5: バッジシステムテーブル'
\echo '========================================='

\echo 'Phase 5 バッジ必須テーブル:'
SELECT 
    table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = t.table_name) 
        THEN '✓ 存在' 
        ELSE '✗ 不足' 
    END as status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = t.table_name)
        THEN (SELECT COUNT(*)::text || ' badges' FROM badges WHERE table_name = 'badges')
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = t.table_name)
        THEN (SELECT COUNT(*)::text || ' records' FROM user_badges WHERE table_name = 'user_badges')
        ELSE '0'
    END as data_count
FROM (VALUES 
    ('badges'),
    ('user_badges')
) AS t(table_name);

\echo ''

\echo 'バッジ定義数:'
SELECT 
    category,
    COUNT(*) as badge_count
FROM badges
GROUP BY category
ORDER BY category;

\echo ''

\echo 'バッジ関連RPC関数:'
SELECT 
    routine_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = r.routine_name) 
        THEN '✓ 存在' 
        ELSE '✗ 不足' 
    END as status
FROM (VALUES 
    ('get_user_badges'),
    ('check_and_unlock_badges'),
    ('mark_badges_as_seen')
) AS r(routine_name);

\echo ''

-- ============================================================
-- 8. 統計関数確認
-- ============================================================
\echo '========================================='
\echo '8. 統計関数'
\echo '========================================='

\echo '統計関連RPC関数:'
SELECT 
    routine_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = r.routine_name) 
        THEN '✓ 存在' 
        ELSE '✗ 不足' 
    END as status
FROM (VALUES 
    ('get_user_statistics'),
    ('get_home_statistics'),
    ('get_recommended_routes'),
    ('get_trending_routes')
) AS r(routine_name);

\echo ''

-- ============================================================
-- 9. データ件数確認
-- ============================================================
\echo '========================================='
\echo '9. データ件数サマリー'
\echo '========================================='

SELECT 'profiles' as table_name, COUNT(*) as count FROM profiles
UNION ALL
SELECT 'routes', COUNT(*) FROM routes
UNION ALL
SELECT 'route_points', COUNT(*) FROM route_points
UNION ALL
SELECT 'pins', COUNT(*) FROM pins
UNION ALL
SELECT 'areas', COUNT(*) FROM areas
UNION ALL
SELECT 'follows', COUNT(*) FROM follows
UNION ALL
SELECT 'likes', COUNT(*) FROM likes
UNION ALL
SELECT 'favorites', COUNT(*) FROM favorites
UNION ALL
SELECT 'badges', COUNT(*) FROM badges
UNION ALL
SELECT 'user_badges', COUNT(*) FROM user_badges
UNION ALL
SELECT 'notifications', COUNT(*) FROM notifications;

\echo ''

-- ============================================================
-- 10. 不足機能の特定
-- ============================================================
\echo '========================================='
\echo '10. 不足機能の特定'
\echo '========================================='

\echo '【チェック項目】'

-- trips, trip_routes テーブルの存在確認
\echo ''
\echo 'Phase 4 履歴機能:'
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'trips')
        AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'trip_routes')
        THEN '✓ trips/trip_routes テーブルが存在します'
        ELSE '✗ trips/trip_routes テーブルが不足しています - Phase 4 未実装'
    END as status;

-- official_routes テーブルの存在確認
\echo ''
\echo 'Phase 2 公式ルート:'
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'official_routes')
        THEN '✓ official_routes テーブルが存在します'
        ELSE '✗ official_routes テーブルが不足しています - Phase 2 未実装'
    END as status;

-- search関数の存在確認
\echo ''
\echo 'Phase 3/5 検索機能:'
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = 'search_routes')
        AND EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = 'search_users')
        THEN '✓ 検索関数が存在します'
        ELSE '✗ 検索関数が不足しています - Phase 3/5 未実装'
    END as status;

\echo ''
\echo '========================================='
\echo '確認完了'
\echo '========================================='
