-- ============================================================================
-- Drop v3 broken RPC functions (壊れたRPC関数の削除)
-- ============================================================================
-- Description: Drop the broken RPC functions created by v3 SQL
-- Execute this BEFORE running 001_walks_table_v4.sql
-- ============================================================================

-- Drop all RPC functions that reference the non-existent r.area_id column
DROP FUNCTION IF EXISTS get_daily_walk_history(UUID, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_outing_walk_history(UUID, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS calculate_walk_statistics(UUID);
DROP FUNCTION IF EXISTS get_user_walk_statistics(UUID);

-- Note: The walks table itself is fine and doesn't need to be dropped
-- Only the RPC functions need to be recreated with the correct column references

-- ============================================================================
-- Verification
-- ============================================================================
-- After running this script, verify that functions are dropped:
-- SELECT routine_name FROM information_schema.routines 
-- WHERE routine_name IN ('get_daily_walk_history', 'get_outing_walk_history', 
--                        'calculate_walk_statistics', 'get_user_walk_statistics');
-- (Should return 0 rows)
-- ============================================================================
