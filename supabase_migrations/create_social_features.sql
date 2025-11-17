-- ==============================================
-- Social Features - Follow & Like System
-- ==============================================
-- This migration creates tables and policies for social features
-- Executed: 2024-11-17
-- ==============================================

-- ==============================================
-- 1. user_follows テーブルの作成（ユーザーフォロー機能）
-- ==============================================
CREATE TABLE IF NOT EXISTS public.user_follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- 制約: 自分自身をフォローできない
    CONSTRAINT user_follows_no_self_follow CHECK (follower_id != following_id),
    
    -- 制約: 同じユーザーを複数回フォローできない
    CONSTRAINT user_follows_unique UNIQUE (follower_id, following_id)
);

-- user_follows テーブルのインデックス
CREATE INDEX IF NOT EXISTS idx_user_follows_follower ON public.user_follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_user_follows_following ON public.user_follows(following_id);
CREATE INDEX IF NOT EXISTS idx_user_follows_created_at ON public.user_follows(created_at);

-- ==============================================
-- 2. route_likes テーブルの作成（ルートいいね機能）
-- ==============================================
CREATE TABLE IF NOT EXISTS public.route_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- 制約: 同じルートを複数回いいねできない
    CONSTRAINT route_likes_unique UNIQUE (user_id, route_id)
);

-- route_likes テーブルのインデックス
CREATE INDEX IF NOT EXISTS idx_route_likes_user ON public.route_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_route_likes_route ON public.route_likes(route_id);
CREATE INDEX IF NOT EXISTS idx_route_likes_created_at ON public.route_likes(created_at);

-- ==============================================
-- 3. users テーブルにフォロワー・フォロー中カウントを追加
-- ==============================================
-- 既存のusersテーブルに統計カラムを追加（存在しない場合のみ）
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS followers_count INTEGER NOT NULL DEFAULT 0;

ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS following_count INTEGER NOT NULL DEFAULT 0;

-- ==============================================
-- 4. routes テーブルにいいね数カウントを追加
-- ==============================================
-- 既存のroutesテーブルに統計カラムを追加（存在しない場合のみ）
ALTER TABLE public.routes 
ADD COLUMN IF NOT EXISTS likes_count INTEGER NOT NULL DEFAULT 0;

-- ==============================================
-- 5. フォロー時のカウント更新トリガー
-- ==============================================
CREATE OR REPLACE FUNCTION public.handle_follow_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- フォローした人のfollowing_countを+1
        UPDATE public.users
        SET following_count = following_count + 1
        WHERE id = NEW.follower_id;
        
        -- フォローされた人のfollowers_countを+1
        UPDATE public.users
        SET followers_count = followers_count + 1
        WHERE id = NEW.following_id;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        -- フォロー解除した人のfollowing_countを-1
        UPDATE public.users
        SET following_count = GREATEST(following_count - 1, 0)
        WHERE id = OLD.follower_id;
        
        -- フォロー解除された人のfollowers_countを-1
        UPDATE public.users
        SET followers_count = GREATEST(followers_count - 1, 0)
        WHERE id = OLD.following_id;
        
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_handle_follow_count
    AFTER INSERT OR DELETE ON public.user_follows
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_follow_count();

-- ==============================================
-- 6. いいね時のカウント更新トリガー
-- ==============================================
CREATE OR REPLACE FUNCTION public.handle_like_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- ルートのlikes_countを+1
        UPDATE public.routes
        SET likes_count = likes_count + 1
        WHERE id = NEW.route_id;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        -- ルートのlikes_countを-1
        UPDATE public.routes
        SET likes_count = GREATEST(likes_count - 1, 0)
        WHERE id = OLD.route_id;
        
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_handle_like_count
    AFTER INSERT OR DELETE ON public.route_likes
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_like_count();

-- ==============================================
-- 7. Row Level Security (RLS) の有効化
-- ==============================================
ALTER TABLE public.user_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.route_likes ENABLE ROW LEVEL SECURITY;

-- ==============================================
-- 8. user_follows テーブルのRLSポリシー
-- ==============================================

-- 誰でもフォロー関係を閲覧可能（公開情報）
CREATE POLICY "Anyone can view follows"
    ON public.user_follows
    FOR SELECT
    USING (true);

-- 自分のフォロー操作のみ可能
CREATE POLICY "Users can follow others"
    ON public.user_follows
    FOR INSERT
    WITH CHECK (auth.uid() = follower_id);

-- 自分のフォローのみ解除可能
CREATE POLICY "Users can unfollow others"
    ON public.user_follows
    FOR DELETE
    USING (auth.uid() = follower_id);

-- ==============================================
-- 9. route_likes テーブルのRLSポリシー
-- ==============================================

-- 誰でもいいねを閲覧可能（公開情報）
CREATE POLICY "Anyone can view likes"
    ON public.route_likes
    FOR SELECT
    USING (true);

-- ログインユーザーは公開ルートにいいね可能
CREATE POLICY "Users can like public routes"
    ON public.route_likes
    FOR INSERT
    WITH CHECK (
        auth.uid() = user_id
        AND EXISTS (
            SELECT 1 FROM public.routes
            WHERE routes.id = route_id
            AND routes.is_public = true
        )
    );

-- 自分のいいねのみ解除可能
CREATE POLICY "Users can unlike routes"
    ON public.route_likes
    FOR DELETE
    USING (auth.uid() = user_id);

-- ==============================================
-- 10. フォロー・いいね関連の集計関数
-- ==============================================

-- フォロワー一覧を取得する関数
CREATE OR REPLACE FUNCTION public.get_followers(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    user_id UUID,
    username TEXT,
    avatar_url TEXT,
    followed_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id as user_id,
        u.username,
        u.avatar_url,
        uf.created_at as followed_at
    FROM public.user_follows uf
    JOIN public.users u ON u.id = uf.follower_id
    WHERE uf.following_id = p_user_id
    ORDER BY uf.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;

-- フォロー中のユーザー一覧を取得する関数
CREATE OR REPLACE FUNCTION public.get_following(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    user_id UUID,
    username TEXT,
    avatar_url TEXT,
    followed_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id as user_id,
        u.username,
        u.avatar_url,
        uf.created_at as followed_at
    FROM public.user_follows uf
    JOIN public.users u ON u.id = uf.following_id
    WHERE uf.follower_id = p_user_id
    ORDER BY uf.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;

-- ルートにいいねしたユーザー一覧を取得する関数
CREATE OR REPLACE FUNCTION public.get_route_likers(
    p_route_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    user_id UUID,
    username TEXT,
    avatar_url TEXT,
    liked_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id as user_id,
        u.username,
        u.avatar_url,
        rl.created_at as liked_at
    FROM public.route_likes rl
    JOIN public.users u ON u.id = rl.user_id
    WHERE rl.route_id = p_route_id
    ORDER BY rl.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;

-- フォローしているユーザーの最新ルートを取得する関数（タイムライン）
CREATE OR REPLACE FUNCTION public.get_following_timeline(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    route_id UUID,
    title TEXT,
    description TEXT,
    thumbnail_url TEXT,
    distance NUMERIC,
    duration INTEGER,
    area TEXT,
    prefecture TEXT,
    likes_count INTEGER,
    user_id UUID,
    username TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id as route_id,
        r.title,
        r.description,
        r.thumbnail_url,
        r.distance,
        r.duration,
        r.area,
        r.prefecture,
        r.likes_count,
        u.id as user_id,
        u.username,
        u.avatar_url,
        r.created_at
    FROM public.routes r
    JOIN public.users u ON u.id = r.user_id
    WHERE r.user_id IN (
        SELECT following_id 
        FROM public.user_follows 
        WHERE follower_id = p_user_id
    )
    AND r.is_public = true
    ORDER BY r.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;

-- 人気のルートを取得する関数（いいね数順）
CREATE OR REPLACE FUNCTION public.get_popular_routes(
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0,
    p_area TEXT DEFAULT NULL
)
RETURNS TABLE (
    route_id UUID,
    title TEXT,
    description TEXT,
    thumbnail_url TEXT,
    distance NUMERIC,
    duration INTEGER,
    area TEXT,
    prefecture TEXT,
    likes_count INTEGER,
    user_id UUID,
    username TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id as route_id,
        r.title,
        r.description,
        r.thumbnail_url,
        r.distance,
        r.duration,
        r.area,
        r.prefecture,
        r.likes_count,
        u.id as user_id,
        u.username,
        u.avatar_url,
        r.created_at
    FROM public.routes r
    JOIN public.users u ON u.id = r.user_id
    WHERE r.is_public = true
    AND r.likes_count > 0
    AND (p_area IS NULL OR r.area = p_area)
    ORDER BY r.likes_count DESC, r.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;

-- ==============================================
-- 11. 既存データのカウント初期化（初回のみ実行）
-- ==============================================
-- フォロワー・フォロー中のカウントを正しい値に更新
UPDATE public.users u
SET followers_count = (
    SELECT COUNT(*) FROM public.user_follows
    WHERE following_id = u.id
);

UPDATE public.users u
SET following_count = (
    SELECT COUNT(*) FROM public.user_follows
    WHERE follower_id = u.id
);

-- ルートのいいね数を正しい値に更新
UPDATE public.routes r
SET likes_count = (
    SELECT COUNT(*) FROM public.route_likes
    WHERE route_id = r.id
);

-- ==============================================
-- Migration completed successfully
-- ==============================================
