-- ============================================================================
-- WanWalk Phase 1+2 Supabase セットアップ・検証スクリプト
-- ============================================================================
-- 作成日: 2026-03-03
-- 目的: Phase 1+2 コード修正に伴うSupabase環境の確認・整備
-- 実行方法: Supabase SQL Editor で各セクションを順番に実行
-- ============================================================================
--
-- 概要:
--   1. profiles テーブルの作成（BUG-C02 対応）
--   2. user-avatars バケットの確認・作成（BUG-C03 対応）
--   3. users → profiles データ移行
--   4. 39個のRPC関数の確認・作成
--   5. テーブル・バケットの存在確認
-- ============================================================================


-- ============================================================================
-- セクション 1: profiles テーブルの作成
-- ============================================================================
-- BUG-C02: Flutterアプリは SupabaseTables.users = 'profiles' に統一済み
-- auth.users はSupabase Authが自動管理するため、
-- ユーザーの公開プロフィール情報は profiles テーブルで管理する

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  display_name TEXT,
  bio TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- インデックス
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_display_name ON profiles(display_name);
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON profiles(created_at DESC);

-- RLS 有効化
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- RLS ポリシー: 全ユーザーがプロフィールを閲覧可能
CREATE POLICY IF NOT EXISTS "Anyone can view profiles"
  ON profiles FOR SELECT
  USING (true);

-- RLS ポリシー: 自分のプロフィールのみ作成可能
CREATE POLICY IF NOT EXISTS "Users can create their own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- RLS ポリシー: 自分のプロフィールのみ更新可能
CREATE POLICY IF NOT EXISTS "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- updated_at 自動更新トリガー
CREATE OR REPLACE FUNCTION update_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS profiles_updated_at ON profiles;
CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_profiles_updated_at();

-- 新規サインアップ時にプロフィールを自動作成するトリガー
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email, display_name, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

COMMENT ON TABLE profiles IS 'ユーザー公開プロフィール（auth.usersと1:1対応）';


-- ============================================================================
-- セクション 2: user-avatars ストレージバケットの作成
-- ============================================================================
-- BUG-C03: Flutterアプリは SupabaseBuckets.userAvatars = 'user-avatars' に統一済み
-- ※ Supabase管理画面の Storage セクションで作成する場合はSQLは不要
-- ※ SQL Editorから実行する場合は以下を使用

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'user-avatars',
  'user-avatars',
  true,
  5242880,  -- 5MB
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- バケットのRLSポリシー
-- 誰でも閲覧可能（公開アバター）
CREATE POLICY IF NOT EXISTS "Avatar images are publicly accessible"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'user-avatars');

-- 認証済みユーザーは自分のフォルダにのみアップロード可能
CREATE POLICY IF NOT EXISTS "Users can upload their own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'user-avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- 認証済みユーザーは自分のフォルダのファイルのみ更新可能
CREATE POLICY IF NOT EXISTS "Users can update their own avatar"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'user-avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- 認証済みユーザーは自分のフォルダのファイルのみ削除可能
CREATE POLICY IF NOT EXISTS "Users can delete their own avatar"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'user-avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );


-- ============================================================================
-- セクション 3: 他のストレージバケットの確認・作成
-- ============================================================================
-- アプリが参照する4つのバケット

-- dog-photos バケット
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'dog-photos',
  'dog-photos',
  true,
  10485760,  -- 10MB
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- route-photos バケット
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'route-photos',
  'route-photos',
  true,
  10485760,  -- 10MB
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- walk-photos バケット
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'walk-photos',
  'walk-photos',
  true,
  10485760,  -- 10MB
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- pin_photos バケット (storage_service.dart で使用)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'pin_photos',
  'pin_photos',
  true,
  10485760,  -- 10MB
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- 各バケットの公開読み取りポリシー
DO $$
DECLARE
  bucket_name TEXT;
BEGIN
  FOREACH bucket_name IN ARRAY ARRAY['dog-photos', 'route-photos', 'walk-photos', 'pin_photos']
  LOOP
    -- SELECT policy
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies 
      WHERE tablename = 'objects' 
      AND policyname = bucket_name || ' are publicly accessible'
    ) THEN
      EXECUTE format(
        'CREATE POLICY "%s are publicly accessible" ON storage.objects FOR SELECT USING (bucket_id = %L)',
        bucket_name, bucket_name
      );
    END IF;
    
    -- INSERT policy
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies 
      WHERE tablename = 'objects' 
      AND policyname = 'Authenticated users can upload to ' || bucket_name
    ) THEN
      EXECUTE format(
        'CREATE POLICY "Authenticated users can upload to %s" ON storage.objects FOR INSERT WITH CHECK (bucket_id = %L AND auth.role() = ''authenticated'')',
        bucket_name, bucket_name
      );
    END IF;
  END LOOP;
END $$;


-- ============================================================================
-- セクション 4: users → profiles データ移行
-- ============================================================================
-- 既存の users テーブルにデータがある場合、profiles にコピーする
-- ※ users テーブルが存在しない場合はスキップされる

DO $$
BEGIN
  -- users テーブルが存在する場合のみ実行
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'users'
  ) THEN
    INSERT INTO profiles (id, email, display_name, bio, avatar_url, created_at, updated_at)
    SELECT 
      id,
      email,
      COALESCE(display_name, username, split_part(email, '@', 1)),
      bio,
      avatar_url,
      COALESCE(created_at, NOW()),
      COALESCE(updated_at, NOW())
    FROM users
    ON CONFLICT (id) DO UPDATE SET
      email = EXCLUDED.email,
      display_name = COALESCE(EXCLUDED.display_name, profiles.display_name),
      bio = COALESCE(EXCLUDED.bio, profiles.bio),
      avatar_url = COALESCE(EXCLUDED.avatar_url, profiles.avatar_url),
      updated_at = NOW();
    
    RAISE NOTICE 'users → profiles データ移行完了';
  ELSE
    RAISE NOTICE 'users テーブルが存在しません。スキップします。';
  END IF;
  
  -- auth.users に存在するがprofilesにないユーザーもプロフィールを作成
  INSERT INTO profiles (id, email, display_name, created_at, updated_at)
  SELECT 
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'display_name', split_part(au.email, '@', 1)),
    COALESCE(au.created_at, NOW()),
    NOW()
  FROM auth.users au
  WHERE NOT EXISTS (SELECT 1 FROM profiles p WHERE p.id = au.id)
  ON CONFLICT (id) DO NOTHING;
  
  RAISE NOTICE 'auth.users → profiles 同期完了';
END $$;


-- ============================================================================
-- セクション 5: RPC関数 - ピンいいね関連 (6個)
-- ============================================================================

-- 5-1. like_pin: ピンにいいねする
CREATE OR REPLACE FUNCTION like_pin(
  p_pin_id UUID,
  p_user_id UUID
)
RETURNS JSONB AS $$
BEGIN
  INSERT INTO pin_likes (pin_id, user_id)
  VALUES (p_pin_id, p_user_id)
  ON CONFLICT (pin_id, user_id) DO NOTHING;
  
  RETURN jsonb_build_object('success', true, 'message', 'Like added');
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'message', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5-2. unlike_pin: ピンのいいねを取り消す
CREATE OR REPLACE FUNCTION unlike_pin(
  p_pin_id UUID,
  p_user_id UUID
)
RETURNS JSONB AS $$
BEGIN
  DELETE FROM pin_likes
  WHERE pin_id = p_pin_id AND user_id = p_user_id;
  
  RETURN jsonb_build_object('success', true, 'message', 'Like removed');
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'message', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5-3. check_user_liked_pin: ユーザーがピンにいいねしているか確認
CREATE OR REPLACE FUNCTION check_user_liked_pin(
  p_pin_id UUID,
  p_user_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM pin_likes
    WHERE pin_id = p_pin_id AND user_id = p_user_id
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 5-4. get_user_liked_pins: ユーザーがいいねしたピン一覧
CREATE OR REPLACE FUNCTION get_user_liked_pins(
  p_user_id UUID,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  pin_id UUID,
  route_id UUID,
  route_name TEXT,
  pin_type TEXT,
  title TEXT,
  comment TEXT,
  likes_count INT,
  photo_url TEXT,
  created_at TIMESTAMPTZ,
  pin_lat FLOAT,
  pin_lon FLOAT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    rp.id AS pin_id,
    rp.route_id,
    COALESCE(r.name, r.title, '') AS route_name,
    rp.pin_type,
    rp.title,
    COALESCE(rp.description, rp.comment, '') AS comment,
    rp.likes_count,
    (
      SELECT rpp.photo_url
      FROM route_pin_photos rpp
      WHERE rpp.pin_id = rp.id
      ORDER BY COALESCE(rpp.photo_order, rpp.display_order, 0) ASC
      LIMIT 1
    ) AS photo_url,
    rp.created_at,
    ST_Y(rp.location::geometry) AS pin_lat,
    ST_X(rp.location::geometry) AS pin_lon
  FROM pin_likes pl
  JOIN route_pins rp ON rp.id = pl.pin_id
  LEFT JOIN official_routes r ON r.id = rp.route_id
  WHERE pl.user_id = p_user_id
    AND rp.is_active = TRUE
  ORDER BY pl.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 5-5. toggle_pin_like: いいねトグル
CREATE OR REPLACE FUNCTION toggle_pin_like(
  p_pin_id UUID,
  p_user_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_existing_like_id UUID;
BEGIN
  SELECT id INTO v_existing_like_id
  FROM pin_likes
  WHERE pin_id = p_pin_id AND user_id = p_user_id;

  IF v_existing_like_id IS NOT NULL THEN
    DELETE FROM pin_likes WHERE id = v_existing_like_id;
    RETURN jsonb_build_object('liked', false, 'message', 'Like removed');
  ELSE
    INSERT INTO pin_likes (pin_id, user_id)
    VALUES (p_pin_id, p_user_id);
    RETURN jsonb_build_object('liked', true, 'message', 'Like added');
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================================
-- セクション 6: RPC関数 - ピンブックマーク関連 (4個)
-- ============================================================================

-- 6-1. bookmark_pin: ピンをブックマークする
CREATE OR REPLACE FUNCTION bookmark_pin(
  p_pin_id UUID,
  p_user_id UUID
)
RETURNS JSONB AS $$
BEGIN
  INSERT INTO pin_bookmarks (pin_id, user_id)
  VALUES (p_pin_id, p_user_id)
  ON CONFLICT (pin_id, user_id) DO NOTHING;
  
  RETURN jsonb_build_object('success', true, 'message', 'Bookmark added');
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'message', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6-2. unbookmark_pin: ブックマーク解除
CREATE OR REPLACE FUNCTION unbookmark_pin(
  p_pin_id UUID,
  p_user_id UUID
)
RETURNS JSONB AS $$
BEGIN
  DELETE FROM pin_bookmarks
  WHERE pin_id = p_pin_id AND user_id = p_user_id;
  
  RETURN jsonb_build_object('success', true, 'message', 'Bookmark removed');
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'message', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6-3. check_user_bookmarked_pin: ブックマーク確認
CREATE OR REPLACE FUNCTION check_user_bookmarked_pin(
  p_pin_id UUID,
  p_user_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM pin_bookmarks
    WHERE pin_id = p_pin_id AND user_id = p_user_id
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 6-4. get_user_bookmarked_pins: ブックマーク一覧
CREATE OR REPLACE FUNCTION get_user_bookmarked_pins(
  p_user_id UUID,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  pin_id UUID,
  route_id UUID,
  route_name TEXT,
  pin_type TEXT,
  title TEXT,
  comment TEXT,
  likes_count INT,
  photo_url TEXT,
  created_at TIMESTAMPTZ,
  pin_lat FLOAT,
  pin_lon FLOAT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    rp.id AS pin_id,
    rp.route_id,
    COALESCE(r.name, r.title, '') AS route_name,
    rp.pin_type,
    rp.title,
    COALESCE(rp.description, rp.comment, '') AS comment,
    rp.likes_count,
    (
      SELECT rpp.photo_url
      FROM route_pin_photos rpp
      WHERE rpp.pin_id = rp.id
      ORDER BY COALESCE(rpp.photo_order, rpp.display_order, 0) ASC
      LIMIT 1
    ) AS photo_url,
    rp.created_at,
    ST_Y(rp.location::geometry) AS pin_lat,
    ST_X(rp.location::geometry) AS pin_lon
  FROM pin_bookmarks pb
  JOIN route_pins rp ON rp.id = pb.pin_id
  LEFT JOIN official_routes r ON r.id = rp.route_id
  WHERE pb.user_id = p_user_id
    AND rp.is_active = TRUE
  ORDER BY pb.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;


-- ============================================================================
-- セクション 7: RPC関数 - コメント関連 (4個)
-- ============================================================================

-- 7-1. add_pin_comment: ピンにコメントを追加
CREATE OR REPLACE FUNCTION add_pin_comment(
  p_pin_id UUID,
  p_user_id UUID,
  p_comment TEXT
)
RETURNS JSONB AS $$
DECLARE
  v_comment_id UUID;
  v_user_name TEXT;
BEGIN
  -- コメントテーブルが存在しない場合は作成
  CREATE TABLE IF NOT EXISTS pin_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pin_id UUID NOT NULL REFERENCES route_pins(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    comment TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );

  INSERT INTO pin_comments (pin_id, user_id, comment)
  VALUES (p_pin_id, p_user_id, p_comment)
  RETURNING id INTO v_comment_id;

  SELECT COALESCE(display_name, split_part(email, '@', 1))
  INTO v_user_name
  FROM profiles WHERE id = p_user_id;

  RETURN jsonb_build_object(
    'success', true,
    'comment_id', v_comment_id,
    'user_name', COALESCE(v_user_name, 'Unknown'),
    'message', 'Comment added'
  );
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'message', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7-2. delete_pin_comment: コメント削除
CREATE OR REPLACE FUNCTION delete_pin_comment(
  p_comment_id UUID,
  p_user_id UUID
)
RETURNS JSONB AS $$
BEGIN
  DELETE FROM pin_comments
  WHERE id = p_comment_id AND user_id = p_user_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'Comment not found or not authorized');
  END IF;

  RETURN jsonb_build_object('success', true, 'message', 'Comment deleted');
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'message', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7-3. get_pin_comments: ピンのコメント一覧
CREATE OR REPLACE FUNCTION get_pin_comments(
  p_pin_id UUID,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  comment_id UUID,
  user_id UUID,
  user_name TEXT,
  user_avatar_url TEXT,
  comment TEXT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  -- pin_comments テーブルが存在しない場合は空結果を返す
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'pin_comments'
  ) THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    pc.id AS comment_id,
    pc.user_id,
    COALESCE(p.display_name, split_part(p.email, '@', 1), 'Unknown') AS user_name,
    p.avatar_url AS user_avatar_url,
    pc.comment,
    pc.created_at
  FROM pin_comments pc
  LEFT JOIN profiles p ON p.id = pc.user_id
  WHERE pc.pin_id = p_pin_id
  ORDER BY pc.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 7-4. get_pin_comments_count: コメント数
CREATE OR REPLACE FUNCTION get_pin_comments_count(
  p_pin_id UUID
)
RETURNS INT AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'pin_comments'
  ) THEN
    RETURN 0;
  END IF;

  RETURN (
    SELECT COUNT(*)::INT
    FROM pin_comments
    WHERE pin_id = p_pin_id
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;


-- ============================================================================
-- セクション 8: RPC関数 - ピン位置取得 (1個)
-- ============================================================================

-- 8-1. get_pin_location: ピンの緯度経度を取得
CREATE OR REPLACE FUNCTION get_pin_location(
  pin_id UUID
)
RETURNS TABLE (
  lat FLOAT,
  lon FLOAT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ST_Y(rp.location::geometry) AS lat,
    ST_X(rp.location::geometry) AS lon
  FROM route_pins rp
  WHERE rp.id = get_pin_location.pin_id;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;


-- ============================================================================
-- セクション 9: RPC関数 - マップ・ルート関連 (5個)
-- ============================================================================

-- 9-1. get_all_routes_geojson: 全ルートGeoJSON取得
CREATE OR REPLACE FUNCTION get_all_routes_geojson()
RETURNS json
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  result json;
BEGIN
  SELECT json_agg(
    json_build_object(
      'id', r.id,
      'area_id', r.area_id,
      'name', COALESCE(r.name, r.title, ''),
      'description', COALESCE(r.description, ''),
      'start_location', CASE 
        WHEN r.start_location IS NOT NULL THEN
          json_build_object(
            'type', 'Point',
            'coordinates', ARRAY[ST_X(r.start_location::geometry), ST_Y(r.start_location::geometry)]
          )
        ELSE NULL
      END,
      'end_location', CASE 
        WHEN r.end_location IS NOT NULL THEN
          json_build_object(
            'type', 'Point',
            'coordinates', ARRAY[ST_X(r.end_location::geometry), ST_Y(r.end_location::geometry)]
          )
        ELSE NULL
      END,
      'route_line', CASE 
        WHEN r.route_line IS NOT NULL THEN
          json_build_object(
            'type', 'LineString',
            'coordinates', (
              SELECT json_agg(json_build_array(ST_X(geom), ST_Y(geom)))
              FROM ST_DumpPoints(r.route_line::geometry) AS dp(path, geom)
            )
          )
        ELSE NULL
      END,
      'distance_meters', COALESCE(r.distance_meters, r.distance_km * 1000),
      'estimated_minutes', COALESCE(r.estimated_minutes, r.estimated_duration_minutes),
      'difficulty_level', COALESCE(r.difficulty_level, r.difficulty, 'easy'),
      'elevation_gain_meters', COALESCE(r.elevation_gain_meters, r.elevation_gain_m),
      'total_pins', COALESCE(r.total_pins, 0),
      'total_walks', COALESCE(r.total_walks, 0),
      'thumbnail_url', r.thumbnail_url,
      'gallery_images', r.gallery_images,
      'pet_info', r.pet_info,
      'created_at', r.created_at,
      'updated_at', r.updated_at
    ) ORDER BY r.created_at DESC
  ) INTO result
  FROM official_routes r;
  
  RETURN COALESCE(result, '[]'::json);
END;
$$;

-- 9-2. get_areas_simple: エリア一覧取得
CREATE OR REPLACE FUNCTION get_areas_simple()
RETURNS TABLE (
  id uuid,
  name text,
  prefecture text,
  description text,
  latitude double precision,
  longitude double precision,
  created_at timestamp with time zone
)
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.id,
    COALESCE(a.name, a.display_name, a.area_code)::text,
    a.prefecture::text,
    COALESCE(a.description, '')::text AS description,
    CASE 
      WHEN a.center_location IS NOT NULL THEN ST_Y(a.center_location::geometry)
      WHEN a.center_point IS NOT NULL THEN ST_Y(a.center_point::geometry)
      ELSE 0.0
    END AS latitude,
    CASE 
      WHEN a.center_location IS NOT NULL THEN ST_X(a.center_location::geometry)
      WHEN a.center_point IS NOT NULL THEN ST_X(a.center_point::geometry)
      ELSE 0.0
    END AS longitude,
    a.created_at
  FROM areas a
  WHERE COALESCE(a.is_active, true) = true
  ORDER BY COALESCE(a.display_order, 999), a.created_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION get_areas_simple() TO authenticated;
GRANT EXECUTE ON FUNCTION get_areas_simple() TO anon;

-- 9-3. get_route_by_id_geojson: 個別ルートGeoJSON取得
CREATE OR REPLACE FUNCTION get_route_by_id_geojson(
  p_route_id UUID
)
RETURNS json
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  result json;
BEGIN
  SELECT json_build_object(
    'id', r.id,
    'area_id', r.area_id,
    'name', COALESCE(r.name, r.title, ''),
    'description', COALESCE(r.description, ''),
    'start_location', CASE 
      WHEN r.start_location IS NOT NULL THEN
        json_build_object(
          'type', 'Point',
          'coordinates', ARRAY[ST_X(r.start_location::geometry), ST_Y(r.start_location::geometry)]
        )
      ELSE NULL
    END,
    'end_location', CASE 
      WHEN r.end_location IS NOT NULL THEN
        json_build_object(
          'type', 'Point',
          'coordinates', ARRAY[ST_X(r.end_location::geometry), ST_Y(r.end_location::geometry)]
        )
      ELSE NULL
    END,
    'route_line', CASE 
      WHEN r.route_line IS NOT NULL THEN
        json_build_object(
          'type', 'LineString',
          'coordinates', (
            SELECT json_agg(json_build_array(ST_X(geom), ST_Y(geom)))
            FROM ST_DumpPoints(r.route_line::geometry) AS dp(path, geom)
          )
        )
      ELSE NULL
    END,
    'distance_meters', COALESCE(r.distance_meters, r.distance_km * 1000),
    'estimated_minutes', COALESCE(r.estimated_minutes, r.estimated_duration_minutes),
    'difficulty_level', COALESCE(r.difficulty_level, r.difficulty, 'easy'),
    'elevation_gain_meters', COALESCE(r.elevation_gain_meters, r.elevation_gain_m),
    'total_pins', COALESCE(r.total_pins, 0),
    'total_walks', COALESCE(r.total_walks, 0),
    'thumbnail_url', r.thumbnail_url,
    'gallery_images', r.gallery_images,
    'pet_info', r.pet_info,
    'features', r.features,
    'best_seasons', r.best_seasons,
    'average_rating', r.average_rating,
    'created_at', r.created_at,
    'updated_at', r.updated_at
  ) INTO result
  FROM official_routes r
  WHERE r.id = p_route_id;
  
  RETURN result;
END;
$$;

-- 9-4. get_routes_by_area_geojson: エリア別ルートGeoJSON取得
CREATE OR REPLACE FUNCTION get_routes_by_area_geojson(
  p_area_id UUID
)
RETURNS json
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  result json;
BEGIN
  SELECT json_agg(
    json_build_object(
      'id', r.id,
      'area_id', r.area_id,
      'name', COALESCE(r.name, r.title, ''),
      'description', COALESCE(r.description, ''),
      'start_location', CASE 
        WHEN r.start_location IS NOT NULL THEN
          json_build_object(
            'type', 'Point',
            'coordinates', ARRAY[ST_X(r.start_location::geometry), ST_Y(r.start_location::geometry)]
          )
        ELSE NULL
      END,
      'route_line', CASE 
        WHEN r.route_line IS NOT NULL THEN
          json_build_object(
            'type', 'LineString',
            'coordinates', (
              SELECT json_agg(json_build_array(ST_X(geom), ST_Y(geom)))
              FROM ST_DumpPoints(r.route_line::geometry) AS dp(path, geom)
            )
          )
        ELSE NULL
      END,
      'distance_meters', COALESCE(r.distance_meters, r.distance_km * 1000),
      'estimated_minutes', COALESCE(r.estimated_minutes, r.estimated_duration_minutes),
      'difficulty_level', COALESCE(r.difficulty_level, r.difficulty, 'easy'),
      'total_pins', COALESCE(r.total_pins, 0),
      'total_walks', COALESCE(r.total_walks, 0),
      'thumbnail_url', r.thumbnail_url,
      'created_at', r.created_at
    ) ORDER BY COALESCE(r.total_walks, 0) DESC
  ) INTO result
  FROM official_routes r
  WHERE r.area_id = p_area_id
    AND COALESCE(r.is_active, true) = true;
  
  RETURN COALESCE(result, '[]'::json);
END;
$$;

-- 9-5. get_monthly_popular_official_routes: 月間人気ルート
CREATE OR REPLACE FUNCTION get_monthly_popular_official_routes(
  p_limit INT DEFAULT 10,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  area_id UUID,
  area_name TEXT,
  distance_km DECIMAL,
  estimated_minutes INT,
  difficulty TEXT,
  total_walks INT,
  total_pins INT,
  thumbnail_url TEXT,
  walk_count_this_month BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id,
    COALESCE(r.name, r.title, '')::TEXT AS name,
    r.area_id,
    COALESCE(a.name, a.display_name, '')::TEXT AS area_name,
    COALESCE(r.distance_km, r.distance_meters / 1000.0) AS distance_km,
    COALESCE(r.estimated_minutes, r.estimated_duration_minutes) AS estimated_minutes,
    COALESCE(r.difficulty_level, r.difficulty, 'easy')::TEXT AS difficulty,
    COALESCE(r.total_walks, 0) AS total_walks,
    COALESCE(r.total_pins, 0) AS total_pins,
    r.thumbnail_url,
    COALESCE(
      (SELECT COUNT(*) FROM walks w 
       WHERE w.route_id = r.id::TEXT OR w.route_id::UUID = r.id
         AND w.start_time >= date_trunc('month', NOW())),
      0
    ) AS walk_count_this_month
  FROM official_routes r
  LEFT JOIN areas a ON r.area_id = a.id
  WHERE COALESCE(r.is_active, true) = true
  ORDER BY COALESCE(r.total_walks, 0) DESC, COALESCE(r.total_pins, 0) DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;


-- ============================================================================
-- セクション 10: RPC関数 - 検索 (1個)
-- ============================================================================

-- 10-1. find_nearby_routes: 近くのルート検索
CREATE OR REPLACE FUNCTION find_nearby_routes(
  p_latitude FLOAT,
  p_longitude FLOAT,
  p_radius_meters INT DEFAULT 5000,
  p_limit INT DEFAULT 20
)
RETURNS TABLE (
  route_id UUID,
  route_name TEXT,
  area_name TEXT,
  distance_meters FLOAT,
  estimated_minutes INT,
  difficulty_level TEXT,
  total_pins INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    r.id,
    COALESCE(r.name, r.title, '')::TEXT,
    COALESCE(a.name, a.display_name, '')::TEXT,
    COALESCE(r.distance_meters, r.distance_km * 1000)::FLOAT,
    COALESCE(r.estimated_minutes, r.estimated_duration_minutes),
    COALESCE(r.difficulty_level, r.difficulty, 'easy')::TEXT,
    COALESCE(r.total_pins, 0)
  FROM official_routes r
  LEFT JOIN areas a ON r.area_id = a.id
  WHERE r.start_location IS NOT NULL
    AND ST_DWithin(
      r.start_location::geography,
      ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography,
      p_radius_meters
    )
  ORDER BY ST_Distance(
    r.start_location::geography,
    ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography
  )
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;


-- ============================================================================
-- セクション 11: RPC関数 - 散歩履歴関連 (2個)
-- ============================================================================

-- 11-1. get_daily_walk_history: 日常散歩履歴
CREATE OR REPLACE FUNCTION get_daily_walk_history(
  p_user_id UUID,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  walk_id UUID,
  walked_at TIMESTAMPTZ,
  distance_meters FLOAT,
  duration_seconds INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    w.id,
    COALESCE(w.start_time, w.created_at) AS walked_at,
    w.distance_meters::FLOAT,
    w.duration_seconds
  FROM walks w
  WHERE w.user_id = p_user_id
    AND w.walk_type = 'daily'
  ORDER BY COALESCE(w.start_time, w.created_at) DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;

-- 11-2. get_outing_walk_history: お出かけ散歩履歴
CREATE OR REPLACE FUNCTION get_outing_walk_history(
  p_user_id UUID,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  walk_id UUID,
  route_id UUID,
  route_name TEXT,
  area_name TEXT,
  walked_at TIMESTAMPTZ,
  distance_meters FLOAT,
  duration_seconds INT,
  photo_count INT,
  pin_count INT,
  photo_urls TEXT[]
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    w.id,
    r.id AS route_id,
    COALESCE(r.name, r.title, '')::TEXT AS route_name,
    COALESCE(a.name, a.display_name, '')::TEXT AS area_name,
    COALESCE(w.start_time, w.created_at) AS walked_at,
    w.distance_meters::FLOAT,
    w.duration_seconds,
    COALESCE(
      (SELECT COUNT(*)::INT 
       FROM route_pins rp 
       INNER JOIN route_pin_photos rpp ON rp.id = rpp.pin_id
       WHERE rp.user_id = p_user_id 
         AND rp.route_id = r.id
         AND DATE(rp.created_at) = DATE(COALESCE(w.start_time, w.created_at))
      ), 0
    ) AS photo_count,
    COALESCE(
      (SELECT COUNT(*)::INT 
       FROM route_pins rp 
       WHERE rp.user_id = p_user_id 
         AND rp.route_id = r.id
         AND DATE(rp.created_at) = DATE(COALESCE(w.start_time, w.created_at))
      ), 0
    ) AS pin_count,
    (SELECT ARRAY_AGG(rpp.photo_url ORDER BY COALESCE(rpp.display_order, rpp.photo_order, 0))
     FROM route_pins rp 
     INNER JOIN route_pin_photos rpp ON rp.id = rpp.pin_id
     WHERE rp.user_id = p_user_id 
       AND rp.route_id = r.id
       AND DATE(rp.created_at) = DATE(COALESCE(w.start_time, w.created_at))
     LIMIT 5
    ) AS photo_urls
  FROM walks w
  LEFT JOIN official_routes r ON w.route_id::UUID = r.id
  LEFT JOIN areas a ON r.area_id = a.id
  WHERE w.user_id = p_user_id
    AND w.walk_type = 'outing'
  ORDER BY COALESCE(w.start_time, w.created_at) DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;


-- ============================================================================
-- セクション 12: RPC関数 - ホーム画面関連 (4個)
-- ============================================================================

-- 12-1. get_recommended_routes: おすすめルート
CREATE OR REPLACE FUNCTION get_recommended_routes(
  p_user_id UUID,
  p_limit INT DEFAULT 5
)
RETURNS TABLE (
  route_id UUID,
  route_name TEXT,
  area_name TEXT,
  distance_meters FLOAT,
  estimated_minutes INT,
  difficulty_level TEXT,
  total_pins INT,
  average_rating DECIMAL,
  thumbnail_url TEXT,
  features TEXT[],
  reason TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    r.id,
    COALESCE(r.name, r.title, '')::TEXT,
    COALESCE(a.name, a.display_name, '')::TEXT,
    COALESCE(r.distance_meters, r.distance_km * 1000)::FLOAT,
    COALESCE(r.estimated_minutes, r.estimated_duration_minutes),
    COALESCE(r.difficulty_level, r.difficulty, 'easy')::TEXT,
    COALESCE(r.total_pins, 0),
    r.average_rating,
    COALESCE(r.thumbnail_url, a.thumbnail_url),
    r.features,
    '人気のルート'::TEXT
  FROM official_routes r
  LEFT JOIN areas a ON r.area_id = a.id
  WHERE COALESCE(r.is_active, true) = true
  ORDER BY COALESCE(r.total_pins, 0) DESC, COALESCE(r.average_rating, 0) DESC NULLS LAST
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- 12-2. get_trending_routes: 急上昇ルート
CREATE OR REPLACE FUNCTION get_trending_routes(
  p_limit INT DEFAULT 5
)
RETURNS TABLE (
  route_id UUID,
  route_name TEXT,
  area_name TEXT,
  distance_meters FLOAT,
  estimated_minutes INT,
  difficulty_level TEXT,
  recent_pins_count INT,
  total_pins INT,
  thumbnail_url TEXT,
  features TEXT[]
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    r.id,
    COALESCE(r.name, r.title, '')::TEXT,
    COALESCE(a.name, a.display_name, '')::TEXT,
    COALESCE(r.distance_meters, r.distance_km * 1000)::FLOAT,
    COALESCE(r.estimated_minutes, r.estimated_duration_minutes),
    COALESCE(r.difficulty_level, r.difficulty, 'easy')::TEXT,
    COALESCE(
      (SELECT COUNT(*)::INT 
       FROM route_pins rp 
       WHERE rp.route_id = r.id
         AND rp.created_at >= NOW() - INTERVAL '7 days'
      ), 0
    ) AS recent_pins_count,
    COALESCE(r.total_pins, 0),
    COALESCE(r.thumbnail_url, a.thumbnail_url),
    r.features
  FROM official_routes r
  LEFT JOIN areas a ON r.area_id = a.id
  WHERE COALESCE(r.is_active, true) = true
  ORDER BY recent_pins_count DESC, COALESCE(r.total_pins, 0) DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- 12-3. get_recent_memories: 最近の思い出写真
CREATE OR REPLACE FUNCTION get_recent_memories(
  p_user_id UUID,
  p_limit INT DEFAULT 6
)
RETURNS TABLE (
  walk_id UUID,
  route_id UUID,
  route_name TEXT,
  walked_at TIMESTAMPTZ,
  photo_url TEXT,
  pin_count INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT ON (w.id)
    w.id,
    r.id AS route_id,
    COALESCE(r.name, r.title, '')::TEXT AS route_name,
    COALESCE(w.start_time, w.created_at) AS walked_at,
    rpp.photo_url,
    COALESCE(
      (SELECT COUNT(*)::INT 
       FROM route_pins rp2 
       WHERE rp2.user_id = p_user_id 
         AND rp2.route_id = r.id
         AND DATE(rp2.created_at) = DATE(COALESCE(w.start_time, w.created_at))
      ), 0
    ) AS pin_count
  FROM walks w
  INNER JOIN official_routes r ON w.route_id::UUID = r.id
  INNER JOIN route_pins rp ON rp.route_id = r.id AND rp.user_id = p_user_id
  INNER JOIN route_pin_photos rpp ON rpp.pin_id = rp.id
  WHERE w.user_id = p_user_id
    AND w.walk_type = 'outing'
    AND DATE(rp.created_at) = DATE(COALESCE(w.start_time, w.created_at))
  ORDER BY w.id, COALESCE(w.start_time, w.created_at) DESC, COALESCE(rpp.display_order, rpp.photo_order, 0) ASC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- 12-4. get_routes_by_area_enhanced: エリア別ルート拡張版
CREATE OR REPLACE FUNCTION get_routes_by_area_enhanced(
  p_area_id UUID,
  p_user_id UUID DEFAULT NULL,
  p_limit INT DEFAULT 20
)
RETURNS TABLE (
  route_id UUID,
  route_name TEXT,
  distance_meters FLOAT,
  estimated_minutes INT,
  difficulty_level TEXT,
  total_pins INT,
  average_rating DECIMAL,
  description TEXT,
  thumbnail_url TEXT,
  features TEXT[],
  has_walked BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    r.id,
    COALESCE(r.name, r.title, '')::TEXT,
    COALESCE(r.distance_meters, r.distance_km * 1000)::FLOAT,
    COALESCE(r.estimated_minutes, r.estimated_duration_minutes),
    COALESCE(r.difficulty_level, r.difficulty, 'easy')::TEXT,
    COALESCE(r.total_pins, 0),
    r.average_rating,
    COALESCE(r.description, '')::TEXT,
    COALESCE(r.thumbnail_url, a.thumbnail_url),
    r.features,
    CASE 
      WHEN p_user_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM walks w WHERE w.route_id::UUID = r.id AND w.user_id = p_user_id
      ) THEN TRUE
      ELSE FALSE
    END
  FROM official_routes r
  LEFT JOIN areas a ON r.area_id = a.id
  WHERE r.area_id = p_area_id AND COALESCE(r.is_active, true) = true
  ORDER BY COALESCE(r.total_pins, 0) DESC, COALESCE(r.average_rating, 0) DESC NULLS LAST
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;


-- ============================================================================
-- セクション 13: RPC関数 - 最新ピン (1個)
-- ============================================================================

-- 13-1. get_recent_pins: 最新写真付きピン
CREATE OR REPLACE FUNCTION get_recent_pins(
  p_limit INT DEFAULT 10,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  pin_id UUID,
  route_id UUID,
  route_name TEXT,
  area_id UUID,
  area_name TEXT,
  prefecture TEXT,
  pin_type TEXT,
  title TEXT,
  comment TEXT,
  likes_count INT,
  photo_url TEXT,
  user_id UUID,
  user_name TEXT,
  user_avatar_url TEXT,
  created_at TIMESTAMPTZ,
  pin_lat FLOAT,
  pin_lon FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    rp.id AS pin_id,
    rp.route_id,
    COALESCE(r.name, r.title, '')::TEXT AS route_name,
    r.area_id,
    COALESCE(a.name, a.display_name, '')::TEXT AS area_name,
    COALESCE(a.prefecture, '')::TEXT,
    rp.pin_type,
    rp.title,
    COALESCE(rp.description, rp.comment, '')::TEXT AS comment,
    rp.likes_count,
    (
      SELECT rpp.photo_url
      FROM route_pin_photos rpp
      WHERE rpp.pin_id = rp.id
      ORDER BY COALESCE(rpp.photo_order, rpp.display_order, 0) ASC
      LIMIT 1
    ) AS photo_url,
    rp.user_id,
    COALESCE(p.display_name, 'Unknown User')::TEXT AS user_name,
    COALESCE(p.avatar_url, '')::TEXT AS user_avatar_url,
    rp.created_at,
    ST_Y(rp.location::geometry) AS pin_lat,
    ST_X(rp.location::geometry) AS pin_lon
  FROM route_pins rp
  LEFT JOIN official_routes r ON r.id = rp.route_id
  LEFT JOIN areas a ON a.id = r.area_id
  LEFT JOIN profiles p ON p.id = rp.user_id
  WHERE rp.is_active = TRUE
    AND EXISTS (
      SELECT 1 FROM route_pin_photos rpp WHERE rpp.pin_id = rp.id
    )
  ORDER BY rp.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;


-- ============================================================================
-- セクション 14: RPC関数 - お気に入り・ブックマーク一覧 (2個)
-- ============================================================================

-- 14-1. get_favorite_routes: お気に入りルート一覧
CREATE OR REPLACE FUNCTION get_favorite_routes(
  p_user_id UUID,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  route_id UUID,
  area_name TEXT,
  route_name TEXT,
  difficulty TEXT,
  distance_km DECIMAL,
  estimated_duration_minutes INT,
  total_pins INT,
  thumbnail_url TEXT,
  favorited_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id AS route_id,
    COALESCE(a.name, a.display_name, '')::TEXT AS area_name,
    COALESCE(r.name, r.title, '')::TEXT AS route_name,
    COALESCE(r.difficulty_level, r.difficulty, 'easy')::TEXT AS difficulty,
    COALESCE(r.distance_km, r.distance_meters / 1000.0) AS distance_km,
    COALESCE(r.estimated_minutes, r.estimated_duration_minutes) AS estimated_duration_minutes,
    COALESCE(r.total_pins, 0) AS total_pins,
    COALESCE(r.thumbnail_url, a.thumbnail_url) AS thumbnail_url,
    rf.created_at AS favorited_at
  FROM route_favorites rf
  JOIN official_routes r ON r.id = rf.route_id
  LEFT JOIN areas a ON a.id = r.area_id
  WHERE rf.user_id = p_user_id
    AND COALESCE(r.is_active, true) = true
  ORDER BY rf.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- 14-2. get_bookmarked_pins: ブックマーク済みピン一覧
CREATE OR REPLACE FUNCTION get_bookmarked_pins(
  p_user_id UUID,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  pin_id UUID,
  route_id UUID,
  route_name TEXT,
  area_name TEXT,
  pin_type TEXT,
  title TEXT,
  comment TEXT,
  likes_count INT,
  photo_urls TEXT[],
  user_name TEXT,
  bookmarked_at TIMESTAMPTZ,
  pin_lat FLOAT,
  pin_lon FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    rp.id AS pin_id,
    rp.route_id,
    COALESCE(r.name, r.title, '')::TEXT AS route_name,
    COALESCE(a.name, a.display_name, '')::TEXT AS area_name,
    rp.pin_type,
    rp.title,
    COALESCE(rp.description, rp.comment, '')::TEXT AS comment,
    rp.likes_count,
    ARRAY(
      SELECT photo_url 
      FROM route_pin_photos 
      WHERE pin_id = rp.id 
      ORDER BY COALESCE(photo_order, display_order, 0)
    ) AS photo_urls,
    COALESCE(p.display_name, 'Unknown')::TEXT AS user_name,
    pb.created_at AS bookmarked_at,
    ST_Y(rp.location::geometry) AS pin_lat,
    ST_X(rp.location::geometry) AS pin_lon
  FROM pin_bookmarks pb
  JOIN route_pins rp ON rp.id = pb.pin_id
  LEFT JOIN official_routes r ON r.id = rp.route_id
  LEFT JOIN areas a ON a.id = r.area_id
  LEFT JOIN profiles p ON p.id = rp.user_id
  WHERE pb.user_id = p_user_id
    AND rp.is_active = TRUE
  ORDER BY pb.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;


-- ============================================================================
-- セクション 15: RPC関数 - 統計関連 (8個)
-- ============================================================================

-- 15-1. get_user_statistics: ユーザー統計
CREATE OR REPLACE FUNCTION get_user_statistics(
  p_user_id UUID,
  p_start_date TIMESTAMPTZ DEFAULT NULL,
  p_end_date TIMESTAMPTZ DEFAULT NULL,
  p_dog_id UUID DEFAULT NULL
)
RETURNS TABLE (
  total_routes BIGINT,
  total_distance NUMERIC,
  total_duration INTEGER,
  avg_distance NUMERIC,
  avg_duration NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::BIGINT as total_routes,
    COALESCE(SUM(w.distance_meters), 0)::NUMERIC as total_distance,
    COALESCE(SUM(w.duration_seconds), 0)::INTEGER as total_duration,
    COALESCE(AVG(w.distance_meters), 0)::NUMERIC as avg_distance,
    COALESCE(AVG(w.duration_seconds), 0)::NUMERIC as avg_duration
  FROM walks w
  WHERE w.user_id = p_user_id
    AND (p_start_date IS NULL OR w.start_time >= p_start_date)
    AND (p_end_date IS NULL OR w.start_time <= p_end_date);
END;
$$ LANGUAGE plpgsql STABLE;

-- 15-2. get_monthly_statistics: 月別統計
CREATE OR REPLACE FUNCTION get_monthly_statistics(
  p_user_id UUID,
  p_months INTEGER DEFAULT 12,
  p_dog_id UUID DEFAULT NULL
)
RETURNS TABLE (
  year INTEGER,
  month INTEGER,
  route_count BIGINT,
  total_distance NUMERIC,
  total_duration INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    EXTRACT(YEAR FROM w.start_time)::INTEGER as year,
    EXTRACT(MONTH FROM w.start_time)::INTEGER as month,
    COUNT(*)::BIGINT as route_count,
    COALESCE(SUM(w.distance_meters), 0)::NUMERIC as total_distance,
    COALESCE(SUM(w.duration_seconds), 0)::INTEGER as total_duration
  FROM walks w
  WHERE w.user_id = p_user_id
    AND w.start_time >= (CURRENT_DATE - (p_months || ' months')::INTERVAL)
  GROUP BY year, month
  ORDER BY year DESC, month DESC;
END;
$$ LANGUAGE plpgsql STABLE;

-- 15-3. get_weekly_statistics: 週別統計
CREATE OR REPLACE FUNCTION get_weekly_statistics(
  p_user_id UUID,
  p_weeks INTEGER DEFAULT 8,
  p_dog_id UUID DEFAULT NULL
)
RETURNS TABLE (
  year INTEGER,
  week INTEGER,
  week_start_date DATE,
  route_count BIGINT,
  total_distance NUMERIC,
  total_duration INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    EXTRACT(YEAR FROM w.start_time)::INTEGER as year,
    EXTRACT(WEEK FROM w.start_time)::INTEGER as week,
    DATE_TRUNC('week', w.start_time)::DATE as week_start_date,
    COUNT(*)::BIGINT as route_count,
    COALESCE(SUM(w.distance_meters), 0)::NUMERIC as total_distance,
    COALESCE(SUM(w.duration_seconds), 0)::INTEGER as total_duration
  FROM walks w
  WHERE w.user_id = p_user_id
    AND w.start_time >= (CURRENT_DATE - (p_weeks || ' weeks')::INTERVAL)
  GROUP BY year, week, week_start_date
  ORDER BY year DESC, week DESC;
END;
$$ LANGUAGE plpgsql STABLE;

-- 15-4. get_hourly_statistics: 時間帯別統計
CREATE OR REPLACE FUNCTION get_hourly_statistics(
  p_user_id UUID,
  p_start_date TIMESTAMPTZ DEFAULT NULL,
  p_end_date TIMESTAMPTZ DEFAULT NULL,
  p_dog_id UUID DEFAULT NULL
)
RETURNS TABLE (
  hour INTEGER,
  route_count BIGINT,
  total_distance NUMERIC,
  total_duration INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    EXTRACT(HOUR FROM w.start_time)::INTEGER as hour,
    COUNT(*)::BIGINT as route_count,
    COALESCE(SUM(w.distance_meters), 0)::NUMERIC as total_distance,
    COALESCE(SUM(w.duration_seconds), 0)::INTEGER as total_duration
  FROM walks w
  WHERE w.user_id = p_user_id
    AND (p_start_date IS NULL OR w.start_time >= p_start_date)
    AND (p_end_date IS NULL OR w.start_time <= p_end_date)
  GROUP BY hour
  ORDER BY hour;
END;
$$ LANGUAGE plpgsql STABLE;

-- 15-5. get_lifetime_statistics: 累計統計
CREATE OR REPLACE FUNCTION get_lifetime_statistics(
  p_user_id UUID,
  p_dog_id UUID DEFAULT NULL
)
RETURNS TABLE (
  total_routes BIGINT,
  total_distance NUMERIC,
  total_duration INTEGER,
  first_route_date TIMESTAMPTZ,
  last_route_date TIMESTAMPTZ,
  unique_areas INTEGER,
  unique_prefectures INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::BIGINT as total_routes,
    COALESCE(SUM(w.distance_meters), 0)::NUMERIC as total_distance,
    COALESCE(SUM(w.duration_seconds), 0)::INTEGER as total_duration,
    MIN(w.start_time) as first_route_date,
    MAX(w.start_time) as last_route_date,
    COUNT(DISTINCT r.area_id)::INTEGER as unique_areas,
    0::INTEGER as unique_prefectures
  FROM walks w
  LEFT JOIN official_routes r ON w.route_id::UUID = r.id
  WHERE w.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql STABLE;

-- 15-6. get_area_statistics: エリア別統計
CREATE OR REPLACE FUNCTION get_area_statistics(
  p_user_id UUID,
  p_start_date TIMESTAMPTZ DEFAULT NULL,
  p_end_date TIMESTAMPTZ DEFAULT NULL,
  p_dog_id UUID DEFAULT NULL,
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  area TEXT,
  prefecture TEXT,
  route_count BIGINT,
  total_distance NUMERIC,
  total_duration INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(a.name, a.display_name, 'Unknown')::TEXT as area,
    COALESCE(a.prefecture, '')::TEXT as prefecture,
    COUNT(*)::BIGINT as route_count,
    COALESCE(SUM(w.distance_meters), 0)::NUMERIC as total_distance,
    COALESCE(SUM(w.duration_seconds), 0)::INTEGER as total_duration
  FROM walks w
  LEFT JOIN official_routes r ON w.route_id::UUID = r.id
  LEFT JOIN areas a ON r.area_id = a.id
  WHERE w.user_id = p_user_id
    AND w.walk_type = 'outing'
    AND (p_start_date IS NULL OR w.start_time >= p_start_date)
    AND (p_end_date IS NULL OR w.start_time <= p_end_date)
  GROUP BY area, prefecture
  ORDER BY route_count DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- 15-7. get_dog_statistics: 愛犬別統計
CREATE OR REPLACE FUNCTION get_dog_statistics(
  p_user_id UUID,
  p_start_date TIMESTAMPTZ DEFAULT NULL,
  p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
  dog_id UUID,
  dog_name TEXT,
  route_count BIGINT,
  total_distance NUMERIC,
  total_duration INTEGER,
  avg_distance NUMERIC,
  avg_duration NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    d.id as dog_id,
    d.name as dog_name,
    0::BIGINT as route_count,
    0::NUMERIC as total_distance,
    0::INTEGER as total_duration,
    0::NUMERIC as avg_distance,
    0::NUMERIC as avg_duration
  FROM dogs d
  WHERE d.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql STABLE;

-- 15-8. get_user_walk_statistics: ユーザー散歩統計（プロフィール用）
CREATE OR REPLACE FUNCTION get_user_walk_statistics(
  p_user_id UUID
)
RETURNS TABLE (
  total_distance_km FLOAT,
  total_walks INT,
  total_duration_minutes INT,
  areas_visited INT,
  pins_created INT,
  routes_completed INT,
  current_level INT,
  level_progress FLOAT,
  badges_earned INT
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_total_distance FLOAT;
  v_total_walks INT;
  v_total_duration INT;
  v_areas_visited INT;
  v_pins_created INT;
  v_routes_completed INT;
  v_current_level INT;
  v_level_progress FLOAT;
BEGIN
  -- 総距離と総散歩回数
  SELECT 
    COALESCE(SUM(w.distance_meters), 0) / 1000.0,
    COUNT(*)::INT
  INTO v_total_distance, v_total_walks
  FROM walks w
  WHERE w.user_id = p_user_id;

  -- 総所要時間（分）
  SELECT COALESCE(SUM(w.duration_seconds) / 60, 0)::INT
  INTO v_total_duration
  FROM walks w
  WHERE w.user_id = p_user_id;

  -- 訪問エリア数
  SELECT COUNT(DISTINCT r.area_id)::INT
  INTO v_areas_visited
  FROM walks w
  LEFT JOIN official_routes r ON w.route_id::UUID = r.id
  WHERE w.user_id = p_user_id AND w.walk_type = 'outing';

  -- 作成ピン数
  SELECT COUNT(*)::INT
  INTO v_pins_created
  FROM route_pins
  WHERE user_id = p_user_id AND is_active = TRUE;

  -- 完了ルート数
  SELECT COUNT(*)::INT
  INTO v_routes_completed
  FROM walks w
  WHERE w.user_id = p_user_id AND w.walk_type = 'outing';

  -- レベル計算（10kmごとに1レベル）
  v_current_level := FLOOR(v_total_distance / 10.0)::INT;
  v_level_progress := (v_total_distance - (v_current_level * 10.0)) / 10.0;

  RETURN QUERY
  SELECT 
    v_total_distance,
    v_total_walks,
    v_total_duration,
    v_areas_visited,
    v_pins_created,
    v_routes_completed,
    v_current_level,
    v_level_progress,
    0::INT; -- badges_earned (v1ではバッジ機能なし)
END;
$$;


-- ============================================================================
-- セクション 16: RPC関数 - 通知関連 (1個)
-- ============================================================================

-- 16-1. get_notifications: 通知一覧取得
-- 既存のcreate_notifications.sqlで定義済みだが、テーブル構造の違いに対応
CREATE OR REPLACE FUNCTION get_notifications(
  p_user_id UUID,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  notification_id UUID,
  type TEXT,
  actor_id UUID,
  actor_name TEXT,
  target_id UUID,
  title TEXT,
  body TEXT,
  is_read BOOLEAN,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    n.id AS notification_id,
    n.type,
    n.actor_id,
    COALESCE(p.display_name, 'Unknown')::TEXT AS actor_name,
    n.target_id,
    n.title,
    COALESCE(n.body, n.message, '')::TEXT,
    n.is_read,
    n.created_at
  FROM notifications n
  LEFT JOIN profiles p ON p.id = n.actor_id
  WHERE n.user_id = p_user_id
  ORDER BY n.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;


-- ============================================================================
-- セクション 17: RPC関数 - プロフィール更新 (1個)
-- ============================================================================

-- 17-1. update_user_walking_profile: プロフィール自動更新
CREATE OR REPLACE FUNCTION update_user_walking_profile(
  p_user_id UUID,
  p_distance_meters FLOAT DEFAULT NULL,
  p_duration_minutes FLOAT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  -- user_walking_profiles テーブルが存在する場合は更新
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'user_walking_profiles'
  ) THEN
    INSERT INTO user_walking_profiles (user_id, total_distance_meters, total_duration_seconds, updated_at)
    VALUES (
      p_user_id,
      COALESCE(p_distance_meters, 0),
      COALESCE(p_duration_minutes * 60, 0)::INT,
      NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
      total_distance_meters = user_walking_profiles.total_distance_meters + COALESCE(p_distance_meters, 0),
      total_duration_seconds = user_walking_profiles.total_duration_seconds + COALESCE(p_duration_minutes * 60, 0)::INT,
      updated_at = NOW();
  END IF;

  v_result := jsonb_build_object(
    'success', true,
    'user_id', p_user_id
  );
  
  RETURN v_result;
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'message', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================================
-- セクション 18: 確認クエリ
-- ============================================================================
-- 以下は確認用のSQLです。問題ないことを確認してください。

-- テーブル一覧確認
SELECT table_name, 
       (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name AND table_schema = 'public') as column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
ORDER BY table_name;

-- RPC関数一覧確認
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_type = 'FUNCTION'
ORDER BY routine_name;

-- ストレージバケット確認
SELECT id, name, public, file_size_limit
FROM storage.buckets
ORDER BY name;

-- profiles テーブルのデータ確認
SELECT id, email, display_name, avatar_url IS NOT NULL as has_avatar, created_at
FROM profiles
ORDER BY created_at DESC
LIMIT 10;

-- ============================================================================
-- 完了
-- ============================================================================
-- 全39個のRPC関数、profilesテーブル、ストレージバケットが設定されました。
-- 問題があれば確認クエリの結果をもとに個別対応してください。
-- ============================================================================
