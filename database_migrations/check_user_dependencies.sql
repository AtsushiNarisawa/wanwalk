-- ===============================================
-- ユーザーの依存関係を完全にチェック
-- ===============================================
-- このSQLをSupabase Dashboard → SQL Editorで実行してください
--
-- 目的: 削除できないユーザーがどのテーブルにデータを持っているか確認
-- ===============================================

DO $$
DECLARE
  target_email TEXT := 'romeo07302002@gmail.com';
  target_user_id UUID;
  row_count INTEGER;
BEGIN
  -- ユーザーIDを取得
  SELECT id INTO target_user_id FROM auth.users WHERE email = target_email;
  
  IF target_user_id IS NULL THEN
    RAISE NOTICE 'ユーザーが見つかりません: %', target_email;
    RETURN;
  END IF;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'ユーザーID: %', target_user_id;
  RAISE NOTICE 'メール: %', target_email;
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  
  -- すべてのテーブルをチェック
  
  -- 1. walks
  SELECT COUNT(*) INTO row_count FROM walks WHERE user_id = target_user_id;
  RAISE NOTICE 'walks: % 件', row_count;
  
  -- 2. walk_photos
  SELECT COUNT(*) INTO row_count FROM walk_photos WHERE user_id = target_user_id;
  RAISE NOTICE 'walk_photos: % 件', row_count;
  
  -- 3. dogs
  SELECT COUNT(*) INTO row_count FROM dogs WHERE user_id = target_user_id;
  RAISE NOTICE 'dogs: % 件', row_count;
  
  -- 4. users (public.users)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
    SELECT COUNT(*) INTO row_count FROM public.users WHERE id = target_user_id;
    RAISE NOTICE 'public.users: % 件', row_count;
  END IF;
  
  -- 5. pins
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pins') THEN
    SELECT COUNT(*) INTO row_count FROM pins WHERE user_id = target_user_id;
    RAISE NOTICE 'pins: % 件', row_count;
  END IF;
  
  -- 6. routes (user_id or created_by)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'routes') THEN
    -- Check if created_by column exists
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'routes' AND column_name = 'created_by') THEN
      SELECT COUNT(*) INTO row_count FROM routes WHERE created_by = target_user_id;
      RAISE NOTICE 'routes (created_by): % 件', row_count;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'routes' AND column_name = 'user_id') THEN
      SELECT COUNT(*) INTO row_count FROM routes WHERE user_id = target_user_id;
      RAISE NOTICE 'routes (user_id): % 件', row_count;
    END IF;
  END IF;
  
  -- 7. user_follows
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_follows') THEN
    SELECT COUNT(*) INTO row_count FROM user_follows WHERE follower_id = target_user_id;
    RAISE NOTICE 'user_follows (follower): % 件', row_count;
    SELECT COUNT(*) INTO row_count FROM user_follows WHERE following_id = target_user_id;
    RAISE NOTICE 'user_follows (following): % 件', row_count;
  END IF;
  
  -- 8. favorites
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'favorites') THEN
    SELECT COUNT(*) INTO row_count FROM favorites WHERE user_id = target_user_id;
    RAISE NOTICE 'favorites: % 件', row_count;
  END IF;
  
  -- 9. comments
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'comments') THEN
    SELECT COUNT(*) INTO row_count FROM comments WHERE user_id = target_user_id;
    RAISE NOTICE 'comments: % 件', row_count;
  END IF;
  
  -- 10. photos (古いテーブル)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'photos') THEN
    SELECT COUNT(*) INTO row_count FROM photos WHERE user_id = target_user_id;
    RAISE NOTICE 'photos: % 件', row_count;
  END IF;
  
  -- 11. route_points
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'route_points') THEN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'route_points' AND column_name = 'created_by') THEN
      SELECT COUNT(*) INTO row_count FROM route_points WHERE created_by = target_user_id;
      RAISE NOTICE 'route_points (created_by): % 件', row_count;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'route_points' AND column_name = 'user_id') THEN
      SELECT COUNT(*) INTO row_count FROM route_points WHERE user_id = target_user_id;
      RAISE NOTICE 'route_points (user_id): % 件', row_count;
    END IF;
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ チェック完了';
  RAISE NOTICE '========================================';
  
  -- Storage bucketのファイルもチェック
  RAISE NOTICE '';
  RAISE NOTICE '⚠️  注意: Storage bucketのファイルは手動で削除が必要です';
  RAISE NOTICE '   - walk-photos bucket';
  RAISE NOTICE '   - route-photos bucket';
  RAISE NOTICE '   - dog-photos bucket';
  RAISE NOTICE '   - user-avatars bucket';
  
END $$;
