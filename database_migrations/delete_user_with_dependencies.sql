-- ===============================================
-- ユーザーとその関連データを完全に削除
-- ===============================================
-- このSQLをSupabase Dashboard → SQL Editorで実行してください
--
-- 削除対象ユーザーのIDを確認:
-- SELECT id, email FROM auth.users WHERE email = 'romeo007002003@gmail.com';
--
-- 警告: このSQLは以下のデータを削除します:
-- 1. walks テーブルのデータ
-- 2. walk_photos テーブルのデータ
-- 3. dogs テーブルのデータ
-- 4. pins テーブルのデータ（存在する場合）
-- 5. その他ユーザーに関連するすべてのデータ
-- 6. auth.users テーブルのユーザーレコード
-- ===============================================

-- ステップ1: 削除するユーザーのIDを確認
DO $$
DECLARE
  target_user_id UUID;
  target_email TEXT := 'romeo007002003@gmail.com';
BEGIN
  -- ユーザーIDを取得
  SELECT id INTO target_user_id
  FROM auth.users
  WHERE email = target_email;
  
  IF target_user_id IS NULL THEN
    RAISE NOTICE 'ユーザー % が見つかりません', target_email;
    RETURN;
  END IF;
  
  RAISE NOTICE 'ユーザーID: %', target_user_id;
  RAISE NOTICE 'メール: %', target_email;
  
  -- ステップ2: 関連データの件数を確認
  RAISE NOTICE '--- 削除されるデータ ---';
  
  -- walks
  RAISE NOTICE 'walks: % 件', (SELECT COUNT(*) FROM walks WHERE user_id = target_user_id);
  
  -- walk_photos
  RAISE NOTICE 'walk_photos: % 件', (SELECT COUNT(*) FROM walk_photos WHERE user_id = target_user_id);
  
  -- dogs
  RAISE NOTICE 'dogs: % 件', (SELECT COUNT(*) FROM dogs WHERE owner_id = target_user_id);
  
  -- pins (存在する場合)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pins') THEN
    RAISE NOTICE 'pins: % 件', (SELECT COUNT(*) FROM pins WHERE user_id = target_user_id);
  END IF;
  
  -- user_follows (フォロー関係)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_follows') THEN
    RAISE NOTICE 'user_follows (follower): % 件', (SELECT COUNT(*) FROM user_follows WHERE follower_id = target_user_id);
    RAISE NOTICE 'user_follows (following): % 件', (SELECT COUNT(*) FROM user_follows WHERE following_id = target_user_id);
  END IF;
  
  -- routes (作成したルート)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'routes') THEN
    RAISE NOTICE 'routes: % 件', (SELECT COUNT(*) FROM routes WHERE created_by = target_user_id);
  END IF;
  
  RAISE NOTICE '------------------------';
  
  -- ステップ3: 関連データを削除（ON DELETE CASCADEで自動削除されるものもある）
  
  -- walk_photos (CASCADE設定があるかもしれないが、明示的に削除)
  DELETE FROM walk_photos WHERE user_id = target_user_id;
  RAISE NOTICE '✓ walk_photos削除完了';
  
  -- walks (CASCADE設定により関連データも削除される)
  DELETE FROM walks WHERE user_id = target_user_id;
  RAISE NOTICE '✓ walks削除完了';
  
  -- dogs
  DELETE FROM dogs WHERE owner_id = target_user_id;
  RAISE NOTICE '✓ dogs削除完了';
  
  -- pins (存在する場合)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pins') THEN
    DELETE FROM pins WHERE user_id = target_user_id;
    RAISE NOTICE '✓ pins削除完了';
  END IF;
  
  -- user_follows
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_follows') THEN
    DELETE FROM user_follows WHERE follower_id = target_user_id OR following_id = target_user_id;
    RAISE NOTICE '✓ user_follows削除完了';
  END IF;
  
  -- routes (作成したルートは削除しない場合はコメントアウト)
  -- DELETE FROM routes WHERE created_by = target_user_id;
  
  -- ステップ4: auth.usersからユーザーを削除
  DELETE FROM auth.users WHERE id = target_user_id;
  RAISE NOTICE '✓ auth.users削除完了';
  
  RAISE NOTICE '=============================';
  RAISE NOTICE '✅ ユーザー削除完了: %', target_email;
  RAISE NOTICE '=============================';
  
END $$;

-- ===============================================
-- 複数ユーザーを一括削除する場合
-- ===============================================
-- 以下のメールアドレスリストを編集して実行:

/*
DO $$
DECLARE
  target_emails TEXT[] := ARRAY[
    'romeo007002003@gmail.com',
    'test2@wanmap.com',
    'test3@wanmap.com',
    'c***m@example.com'
  ];
  target_email TEXT;
  target_user_id UUID;
  deleted_count INTEGER := 0;
BEGIN
  FOREACH target_email IN ARRAY target_emails
  LOOP
    -- ユーザーIDを取得
    SELECT id INTO target_user_id
    FROM auth.users
    WHERE email = target_email;
    
    IF target_user_id IS NULL THEN
      RAISE NOTICE '⚠️  ユーザーが見つかりません: %', target_email;
      CONTINUE;
    END IF;
    
    -- 関連データを削除
    DELETE FROM walk_photos WHERE user_id = target_user_id;
    DELETE FROM walks WHERE user_id = target_user_id;
    DELETE FROM dogs WHERE owner_id = target_user_id;
    
    -- pins (存在する場合)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pins') THEN
      DELETE FROM pins WHERE user_id = target_user_id;
    END IF;
    
    -- user_follows
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_follows') THEN
      DELETE FROM user_follows WHERE follower_id = target_user_id OR following_id = target_user_id;
    END IF;
    
    -- auth.users
    DELETE FROM auth.users WHERE id = target_user_id;
    
    deleted_count := deleted_count + 1;
    RAISE NOTICE '✅ 削除完了: %', target_email;
  END LOOP;
  
  RAISE NOTICE '=============================';
  RAISE NOTICE '✅ 合計 % ユーザー削除完了', deleted_count;
  RAISE NOTICE '=============================';
END $$;
*/
