-- ==============================================
-- Notification System
-- ==============================================
-- This migration creates tables and triggers for notification system
-- Executed: 2024-11-17
-- ==============================================

-- ==============================================
-- 1. notifications テーブルの作成
-- ==============================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL, -- 'follow', 'like', 'system'
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    data JSONB, -- 追加データ（関連するuser_id, route_idなど）
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- 制約: typeは定義された値のみ
    CONSTRAINT notifications_type_check CHECK (type IN ('follow', 'like', 'system'))
);

-- notifications テーブルのインデックス
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON public.notifications(user_id, is_read);

-- ==============================================
-- 2. Row Level Security (RLS) の有効化
-- ==============================================
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- ==============================================
-- 3. notifications テーブルのRLSポリシー
-- ==============================================

-- 自分の通知のみ閲覧可能
CREATE POLICY "Users can view their own notifications"
    ON public.notifications
    FOR SELECT
    USING (auth.uid() = user_id);

-- システムが通知を作成（ユーザーは直接作成できない）
-- トリガー経由でのみ作成されるため、INSERTポリシーは制限的に設定
CREATE POLICY "System can create notifications"
    ON public.notifications
    FOR INSERT
    WITH CHECK (false); -- ユーザーからの直接INSERTは不可

-- 自分の通知のみ更新可能（既読状態の変更）
CREATE POLICY "Users can update their own notifications"
    ON public.notifications
    FOR UPDATE
    USING (auth.uid() = user_id);

-- 自分の通知のみ削除可能
CREATE POLICY "Users can delete their own notifications"
    ON public.notifications
    FOR DELETE
    USING (auth.uid() = user_id);

-- ==============================================
-- 4. フォロー時の通知作成トリガー
-- ==============================================
CREATE OR REPLACE FUNCTION public.create_follow_notification()
RETURNS TRIGGER AS $$
DECLARE
    follower_username TEXT;
BEGIN
    -- フォローした人のユーザー名を取得
    SELECT username INTO follower_username
    FROM public.users
    WHERE id = NEW.follower_id;

    -- フォローされた人に通知を作成
    INSERT INTO public.notifications (user_id, type, title, message, data)
    VALUES (
        NEW.following_id,
        'follow',
        '新しいフォロワー',
        follower_username || 'さんがあなたをフォローしました',
        jsonb_build_object('follower_id', NEW.follower_id, 'follower_username', follower_username)
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_create_follow_notification
    AFTER INSERT ON public.user_follows
    FOR EACH ROW
    EXECUTE FUNCTION public.create_follow_notification();

-- ==============================================
-- 5. いいね時の通知作成トリガー
-- ==============================================
CREATE OR REPLACE FUNCTION public.create_like_notification()
RETURNS TRIGGER AS $$
DECLARE
    liker_username TEXT;
    route_owner_id UUID;
    route_title TEXT;
BEGIN
    -- いいねした人のユーザー名を取得
    SELECT username INTO liker_username
    FROM public.users
    WHERE id = NEW.user_id;

    -- ルートの所有者とタイトルを取得
    SELECT user_id, title INTO route_owner_id, route_title
    FROM public.routes
    WHERE id = NEW.route_id;

    -- 自分のルートへの自分のいいねには通知しない
    IF route_owner_id != NEW.user_id THEN
        -- ルートの所有者に通知を作成
        INSERT INTO public.notifications (user_id, type, title, message, data)
        VALUES (
            route_owner_id,
            'like',
            'いいねされました',
            liker_username || 'さんが「' || route_title || '」にいいねしました',
            jsonb_build_object(
                'liker_id', NEW.user_id,
                'liker_username', liker_username,
                'route_id', NEW.route_id,
                'route_title', route_title
            )
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_create_like_notification
    AFTER INSERT ON public.route_likes
    FOR EACH ROW
    EXECUTE FUNCTION public.create_like_notification();

-- ==============================================
-- 6. 通知取得関数
-- ==============================================

-- 未読通知数を取得する関数
CREATE OR REPLACE FUNCTION public.get_unread_notification_count(
    p_user_id UUID
)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)::INTEGER
        FROM public.notifications
        WHERE user_id = p_user_id
        AND is_read = false
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- 通知一覧を取得する関数
CREATE OR REPLACE FUNCTION public.get_notifications(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0,
    p_unread_only BOOLEAN DEFAULT false
)
RETURNS TABLE (
    id UUID,
    type TEXT,
    title TEXT,
    message TEXT,
    data JSONB,
    is_read BOOLEAN,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        n.id,
        n.type,
        n.title,
        n.message,
        n.data,
        n.is_read,
        n.created_at
    FROM public.notifications n
    WHERE n.user_id = p_user_id
    AND (NOT p_unread_only OR n.is_read = false)
    ORDER BY n.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;

-- 全ての通知を既読にする関数
CREATE OR REPLACE FUNCTION public.mark_all_notifications_as_read(
    p_user_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    affected_count INTEGER;
BEGIN
    UPDATE public.notifications
    SET is_read = true
    WHERE user_id = p_user_id
    AND is_read = false;
    
    GET DIAGNOSTICS affected_count = ROW_COUNT;
    RETURN affected_count;
END;
$$ LANGUAGE plpgsql;

-- 古い通知を削除する関数（メンテナンス用）
CREATE OR REPLACE FUNCTION public.delete_old_notifications(
    p_days INTEGER DEFAULT 30
)
RETURNS INTEGER AS $$
DECLARE
    affected_count INTEGER;
BEGIN
    DELETE FROM public.notifications
    WHERE created_at < (CURRENT_DATE - (p_days || ' days')::INTERVAL)
    AND is_read = true;
    
    GET DIAGNOSTICS affected_count = ROW_COUNT;
    RETURN affected_count;
END;
$$ LANGUAGE plpgsql;

-- ==============================================
-- 7. システム通知を作成する関数
-- ==============================================
CREATE OR REPLACE FUNCTION public.create_system_notification(
    p_user_id UUID,
    p_title TEXT,
    p_message TEXT,
    p_data JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    notification_id UUID;
BEGIN
    INSERT INTO public.notifications (user_id, type, title, message, data)
    VALUES (p_user_id, 'system', p_title, p_message, p_data)
    RETURNING id INTO notification_id;
    
    RETURN notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 全ユーザーにシステム通知を送信する関数
CREATE OR REPLACE FUNCTION public.broadcast_system_notification(
    p_title TEXT,
    p_message TEXT,
    p_data JSONB DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    affected_count INTEGER;
BEGIN
    INSERT INTO public.notifications (user_id, type, title, message, data)
    SELECT id, 'system', p_title, p_message, p_data
    FROM auth.users;
    
    GET DIAGNOSTICS affected_count = ROW_COUNT;
    RETURN affected_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==============================================
-- Migration completed successfully
-- ==============================================
