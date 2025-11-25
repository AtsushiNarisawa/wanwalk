-- ===============================================
-- ユーザーを完全に強制削除（全テーブル対応版）
-- ===============================================
-- このSQLをSupabase Dashboard → SQL Editorで実行してください
--
-- 実行手順:
-- 1. まず check_user_dependencies.sql を実行して依存関係を確認
-- 2. このSQLを実行してユーザーを削除
-- 3. Storage bucketのファイルは手動で削除
-- ===============================================

DO $$
DECLARE
  target_email TEXT := 'romeo07302002@gmail.com';
  target_user_id UUID;
BEGIN
  -- ユーザーIDを取得
  SELECT id INTO target_user_id FROM auth.users WHERE email = target_email;
  
  IF target_user_id IS NULL THEN
    RAISE NOTICE 'ユーザーが見つかりません: %', target_email;
    RETURN;
  END IF;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE '削除開始: %', target_email;
  RAISE NOTICE 'ユーザーID: %', target_user_id;
  RAISE NOTICE '========================================';
  
  -- 1. walk_photos を削除
  DELETE FROM walk_photos WHERE user_id = target_user_id;
  RAISE NOTICE '✓ walk_photos 削除完了';
  
  -- 2. walks を削除
  DELETE FROM walks WHERE user_id = target_user_id;
  RAISE NOTICE '✓ walks 削除完了';
  
  -- 3. dogs を削除
  DELETE FROM dogs WHERE user_id = target_user_id;
  RAISE NOTICE '✓ dogs 削除完了';
  
  -- 4. pins を削除 (存在する場合)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pins') THEN
    DELETE FROM pins WHERE user_id = target_user_id;
    RAISE NOTICE '✓ pins 削除完了';
  END IF;
  
  -- 5. user_follows を削除 (存在する場合)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_follows') THEN
    DELETE FROM user_follows WHERE follower_id = target_user_id OR following_id = target_user_id;
    RAISE NOTICE '✓ user_follows 削除完了';
  END IF;
  
  -- 6. favorites を削除 (存在する場合)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'favorites') THEN
    DELETE FROM favorites WHERE user_id = target_user_id;
    RAISE NOTICE '✓ favorites 削除完了';
  END IF;
  
  -- 7. comments を削除 (存在する場合)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'comments') THEN
    DELETE FROM comments WHERE user_id = target_user_id;
    RAISE NOTICE '✓ comments 削除完了';
  END IF;
  
  -- 8. photos (古いテーブル) を削除 (存在する場合)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'photos') THEN
    DELETE FROM photos WHERE user_id = target_user_id;
    RAISE NOTICE '✓ photos 削除完了';
  END IF;
  
  -- 9. routes (作成したルート) を削除 (存在する場合)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'routes') THEN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'routes' AND column_name = 'created_by') THEN
      DELETE FROM routes WHERE created_by = target_user_id;
      RAISE NOTICE '✓ routes (created_by) 削除完了';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'routes' AND column_name = 'user_id') THEN
      DELETE FROM routes WHERE user_id = target_user_id;
      RAISE NOTICE '✓ routes (user_id) 削除完了';
    END IF;
  END IF;
  
  -- 10. route_points を削除 (存在する場合)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'route_points') THEN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'route_points' AND column_name = 'created_by') THEN
      DELETE FROM route_points WHERE created_by = target_user_id;
      RAISE NOTICE '✓ route_points (created_by) 削除完了';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'route_points' AND column_name = 'user_id') THEN
      DELETE FROM route_points WHERE user_id = target_user_id;
      RAISE NOTICE '✓ route_points (user_id) 削除完了';
    END IF;
  END IF;
  
  -- 11. public.users を削除 (存在する場合)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
    DELETE FROM public.users WHERE id = target_user_id;
    RAISE NOTICE '✓ public.users 削除完了';
  END IF;
  
  -- 12. auth.users から削除（最後に実行）
  DELETE FROM auth.users WHERE id = target_user_id;
  RAISE NOTICE '✓ auth.users 削除完了';
  
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ ユーザー削除完了: %', target_email;
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE '⚠️  Storage bucketのファイルは手動で削除してください:';
  RAISE NOTICE '   1. Storage → walk-photos → % フォルダ', target_user_id;
  RAISE NOTICE '   2. Storage → route-photos → % フォルダ', target_user_id;
  RAISE NOTICE '   3. Storage → dog-photos → % フォルダ', target_user_id;
  RAISE NOTICE '   4. Storage → user-avatars → % フォルダ', target_user_id;
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '❌ エラー発生: %', SQLERRM;
    RAISE NOTICE '詳細: %', SQLSTATE;
END $$;
