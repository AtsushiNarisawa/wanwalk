-- ============================================================================
-- Phase 1-4: 重複・不要テーブルの削除（修正版）
-- ============================================================================
-- 目的: データベースをクリーンアップし、重複テーブル/ビューを削除
-- 実行方法: Supabase Dashboard > SQL Editor で実行
-- ============================================================================
-- 
-- 削除対象:
-- 1. badges (VIEW) → badge_definitions を使用
-- 2. follows (テーブル) → user_follows を使用
-- 3. likes (テーブル) → pin_likes + route_likes を使用
-- 4. favorites (テーブル) → route_favorites を使用
-- 5. official_routes (テーブル) → routes を使用
-- 6. follow_stats (テーブル) → RPC関数で動的計算
--
-- ============================================================================

-- ============================================================================
-- 1. badges ビューの削除（badge_definitions を使用）
-- ============================================================================

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'badges') THEN
    RAISE NOTICE '✅ badges ビューを削除します（badge_definitions を使用）';
    DROP VIEW IF EXISTS badges CASCADE;
    RAISE NOTICE '   → badges ビューを削除しました';
  ELSIF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'badges') THEN
    RAISE NOTICE '✅ badges テーブルを削除します（badge_definitions を使用）';
    DROP TABLE IF EXISTS badges CASCADE;
    RAISE NOTICE '   → badges テーブルを削除しました';
  ELSE
    RAISE NOTICE '✅ badges は既に削除されています';
  END IF;
END $$;

-- ============================================================================
-- 2. follows テーブルの削除（user_follows に統合）
-- ============================================================================

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'follows' AND table_type = 'BASE TABLE') THEN
    RAISE NOTICE '✅ follows テーブルを削除します（user_follows を使用）';
    DROP TABLE IF EXISTS follows CASCADE;
    RAISE NOTICE '   → follows テーブルを削除しました';
  ELSIF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'follows') THEN
    RAISE NOTICE '✅ follows ビューを削除します（user_follows を使用）';
    DROP VIEW IF EXISTS follows CASCADE;
    RAISE NOTICE '   → follows ビューを削除しました';
  ELSE
    RAISE NOTICE '✅ follows は既に削除されています';
  END IF;
END $$;

-- ============================================================================
-- 3. likes テーブルの削除（pin_likes + route_likes に分離）
-- ============================================================================

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'likes' AND table_type = 'BASE TABLE') THEN
    RAISE NOTICE '✅ likes テーブルを削除します（pin_likes + route_likes を使用）';
    DROP TABLE IF EXISTS likes CASCADE;
    RAISE NOTICE '   → likes テーブルを削除しました';
  ELSIF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'likes') THEN
    RAISE NOTICE '✅ likes ビューを削除します';
    DROP VIEW IF EXISTS likes CASCADE;
    RAISE NOTICE '   → likes ビューを削除しました';
  ELSE
    RAISE NOTICE '✅ likes は既に削除されています';
  END IF;
END $$;

-- ============================================================================
-- 4. favorites テーブルの削除（route_favorites に統合）
-- ============================================================================

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'favorites' AND table_type = 'BASE TABLE') THEN
    RAISE NOTICE '✅ favorites テーブルを削除します（route_favorites を使用）';
    DROP TABLE IF EXISTS favorites CASCADE;
    RAISE NOTICE '   → favorites テーブルを削除しました';
  ELSIF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'favorites') THEN
    RAISE NOTICE '✅ favorites ビューを削除します';
    DROP VIEW IF EXISTS favorites CASCADE;
    RAISE NOTICE '   → favorites ビューを削除しました';
  ELSE
    RAISE NOTICE '✅ favorites は既に削除されています';
  END IF;
END $$;

-- ============================================================================
-- 5. official_routes テーブルの削除（routes に統合）
-- ============================================================================

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'official_routes' AND table_type = 'BASE TABLE') THEN
    RAISE NOTICE '✅ official_routes テーブルを削除します（routes を使用）';
    DROP TABLE IF EXISTS official_routes CASCADE;
    RAISE NOTICE '   → official_routes テーブルを削除しました';
  ELSIF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'official_routes') THEN
    RAISE NOTICE '✅ official_routes ビューを削除します';
    DROP VIEW IF EXISTS official_routes CASCADE;
    RAISE NOTICE '   → official_routes ビューを削除しました';
  ELSE
    RAISE NOTICE '✅ official_routes は既に削除されています';
  END IF;
END $$;

-- ============================================================================
-- 6. follow_stats テーブルの削除（RPC関数で動的計算）
-- ============================================================================

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'follow_stats' AND table_type = 'BASE TABLE') THEN
    RAISE NOTICE '✅ follow_stats テーブルを削除します（get_user_walk_statistics で計算）';
    DROP TABLE IF EXISTS follow_stats CASCADE;
    RAISE NOTICE '   → follow_stats テーブルを削除しました';
  ELSIF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'follow_stats') THEN
    RAISE NOTICE '✅ follow_stats ビューを削除します';
    DROP VIEW IF EXISTS follow_stats CASCADE;
    RAISE NOTICE '   → follow_stats ビューを削除しました';
  ELSE
    RAISE NOTICE '✅ follow_stats は既に削除されています';
  END IF;
END $$;

-- ============================================================================
-- 7. 削除完了の確認
-- ============================================================================

DO $$
DECLARE
  v_deleted_count INTEGER := 0;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ データベースクリーンアップ完了';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE '削除されたオブジェクト:';
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'badges') 
     AND NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'badges') THEN
    v_deleted_count := v_deleted_count + 1;
    RAISE NOTICE '  ✓ badges';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'follows') 
     AND NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'follows') THEN
    v_deleted_count := v_deleted_count + 1;
    RAISE NOTICE '  ✓ follows';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'likes') 
     AND NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'likes') THEN
    v_deleted_count := v_deleted_count + 1;
    RAISE NOTICE '  ✓ likes';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'favorites') 
     AND NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'favorites') THEN
    v_deleted_count := v_deleted_count + 1;
    RAISE NOTICE '  ✓ favorites';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'official_routes') 
     AND NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'official_routes') THEN
    v_deleted_count := v_deleted_count + 1;
    RAISE NOTICE '  ✓ official_routes';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'follow_stats') 
     AND NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'follow_stats') THEN
    v_deleted_count := v_deleted_count + 1;
    RAISE NOTICE '  ✓ follow_stats';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '合計 % 個のオブジェクトを削除しました', v_deleted_count;
  RAISE NOTICE '';
END $$;

-- ============================================================================
-- 8. 残存テーブルの確認
-- ============================================================================

SELECT 
  table_name,
  CASE 
    WHEN table_name = 'walks' THEN '✅ Phase 1-1: 散歩履歴'
    WHEN table_name = 'walk_photos' THEN '✅ Phase 1-3: 散歩写真'
    WHEN table_name = 'route_pins' THEN '✅ ピン投稿'
    WHEN table_name = 'route_pin_photos' THEN '✅ ピン写真'
    WHEN table_name = 'pin_likes' THEN '✅ ピンいいね'
    WHEN table_name = 'route_likes' THEN '✅ ルートいいね'
    WHEN table_name = 'route_favorites' THEN '✅ お気に入り'
    WHEN table_name = 'badge_definitions' THEN '✅ バッジ定義'
    WHEN table_name = 'user_badges' THEN '✅ ユーザーバッジ'
    WHEN table_name = 'user_follows' THEN '✅ フォロー関係'
    WHEN table_name = 'dogs' THEN '✅ 愛犬情報'
    WHEN table_name = 'profiles' THEN '✅ プロフィール'
    WHEN table_name = 'routes' THEN '✅ ルート情報'
    WHEN table_name = 'areas' THEN '✅ エリア情報'
    WHEN table_name = 'comments' THEN '✅ コメント'
    WHEN table_name = 'notifications' THEN '✅ 通知'
    ELSE '✅ その他'
  END AS description
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- ============================================================================
-- End of Migration: 006_cleanup_duplicate_tables_v2.sql
-- ============================================================================
