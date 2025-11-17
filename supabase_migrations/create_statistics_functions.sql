-- ==============================================
-- Statistics and Reporting Feature - Database Functions
-- ==============================================
-- This migration creates PostgreSQL functions for efficient statistics queries
-- Executed: 2024-11-17
-- ==============================================

-- ==============================================
-- 1. ユーザーの期間別統計を取得する関数
-- ==============================================
-- 指定期間のルート統計（総距離、総時間、回数）を取得
CREATE OR REPLACE FUNCTION public.get_user_statistics(
    p_user_id UUID,
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ,
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
        COALESCE(SUM(r.distance), 0)::NUMERIC as total_distance,
        COALESCE(SUM(r.duration), 0)::INTEGER as total_duration,
        COALESCE(AVG(r.distance), 0)::NUMERIC as avg_distance,
        COALESCE(AVG(r.duration), 0)::NUMERIC as avg_duration
    FROM public.routes r
    WHERE r.user_id = p_user_id
        AND r.started_at >= p_start_date
        AND r.started_at <= p_end_date
        AND (p_dog_id IS NULL OR r.dog_id = p_dog_id);
END;
$$ LANGUAGE plpgsql STABLE;

-- ==============================================
-- 2. 月別の統計データを取得する関数
-- ==============================================
-- 過去N ヶ月分の月別統計を取得（グラフ表示用）
CREATE OR REPLACE FUNCTION public.get_monthly_statistics(
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
        EXTRACT(YEAR FROM r.started_at)::INTEGER as year,
        EXTRACT(MONTH FROM r.started_at)::INTEGER as month,
        COUNT(*)::BIGINT as route_count,
        COALESCE(SUM(r.distance), 0)::NUMERIC as total_distance,
        COALESCE(SUM(r.duration), 0)::INTEGER as total_duration
    FROM public.routes r
    WHERE r.user_id = p_user_id
        AND r.started_at >= (CURRENT_DATE - (p_months || ' months')::INTERVAL)
        AND (p_dog_id IS NULL OR r.dog_id = p_dog_id)
    GROUP BY year, month
    ORDER BY year DESC, month DESC;
END;
$$ LANGUAGE plpgsql STABLE;

-- ==============================================
-- 3. エリア別統計を取得する関数
-- ==============================================
-- よく行くエリアのランキング
CREATE OR REPLACE FUNCTION public.get_area_statistics(
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
        r.area,
        r.prefecture,
        COUNT(*)::BIGINT as route_count,
        COALESCE(SUM(r.distance), 0)::NUMERIC as total_distance,
        COALESCE(SUM(r.duration), 0)::INTEGER as total_duration
    FROM public.routes r
    WHERE r.user_id = p_user_id
        AND r.area IS NOT NULL
        AND (p_start_date IS NULL OR r.started_at >= p_start_date)
        AND (p_end_date IS NULL OR r.started_at <= p_end_date)
        AND (p_dog_id IS NULL OR r.dog_id = p_dog_id)
    GROUP BY r.area, r.prefecture
    ORDER BY route_count DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- ==============================================
-- 4. 愛犬別統計を取得する関数
-- ==============================================
-- 登録している全ての犬の統計を比較
CREATE OR REPLACE FUNCTION public.get_dog_statistics(
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
        COUNT(r.id)::BIGINT as route_count,
        COALESCE(SUM(r.distance), 0)::NUMERIC as total_distance,
        COALESCE(SUM(r.duration), 0)::INTEGER as total_duration,
        COALESCE(AVG(r.distance), 0)::NUMERIC as avg_distance,
        COALESCE(AVG(r.duration), 0)::NUMERIC as avg_duration
    FROM public.dogs d
    LEFT JOIN public.routes r ON r.dog_id = d.id
        AND (p_start_date IS NULL OR r.started_at >= p_start_date)
        AND (p_end_date IS NULL OR r.started_at <= p_end_date)
    WHERE d.user_id = p_user_id
    GROUP BY d.id, d.name
    ORDER BY route_count DESC;
END;
$$ LANGUAGE plpgsql STABLE;

-- ==============================================
-- 5. 週別統計を取得する関数（直近の週の活動）
-- ==============================================
CREATE OR REPLACE FUNCTION public.get_weekly_statistics(
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
        EXTRACT(YEAR FROM r.started_at)::INTEGER as year,
        EXTRACT(WEEK FROM r.started_at)::INTEGER as week,
        DATE_TRUNC('week', r.started_at)::DATE as week_start_date,
        COUNT(*)::BIGINT as route_count,
        COALESCE(SUM(r.distance), 0)::NUMERIC as total_distance,
        COALESCE(SUM(r.duration), 0)::INTEGER as total_duration
    FROM public.routes r
    WHERE r.user_id = p_user_id
        AND r.started_at >= (CURRENT_DATE - (p_weeks || ' weeks')::INTERVAL)
        AND (p_dog_id IS NULL OR r.dog_id = p_dog_id)
    GROUP BY year, week, week_start_date
    ORDER BY year DESC, week DESC;
END;
$$ LANGUAGE plpgsql STABLE;

-- ==============================================
-- 6. 累計統計を取得する関数（全期間）
-- ==============================================
CREATE OR REPLACE FUNCTION public.get_lifetime_statistics(
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
        COALESCE(SUM(r.distance), 0)::NUMERIC as total_distance,
        COALESCE(SUM(r.duration), 0)::INTEGER as total_duration,
        MIN(r.started_at) as first_route_date,
        MAX(r.started_at) as last_route_date,
        COUNT(DISTINCT r.area)::INTEGER as unique_areas,
        COUNT(DISTINCT r.prefecture)::INTEGER as unique_prefectures
    FROM public.routes r
    WHERE r.user_id = p_user_id
        AND (p_dog_id IS NULL OR r.dog_id = p_dog_id);
END;
$$ LANGUAGE plpgsql STABLE;

-- ==============================================
-- 7. 時間帯別統計を取得する関数
-- ==============================================
-- どの時間帯によく散歩しているか（0-23時）
CREATE OR REPLACE FUNCTION public.get_hourly_statistics(
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
        EXTRACT(HOUR FROM r.started_at)::INTEGER as hour,
        COUNT(*)::BIGINT as route_count,
        COALESCE(SUM(r.distance), 0)::NUMERIC as total_distance,
        COALESCE(SUM(r.duration), 0)::INTEGER as total_duration
    FROM public.routes r
    WHERE r.user_id = p_user_id
        AND (p_start_date IS NULL OR r.started_at >= p_start_date)
        AND (p_end_date IS NULL OR r.started_at <= p_end_date)
        AND (p_dog_id IS NULL OR r.dog_id = p_dog_id)
    GROUP BY hour
    ORDER BY hour;
END;
$$ LANGUAGE plpgsql STABLE;

-- ==============================================
-- 8. インデックスの最適化
-- ==============================================
-- 統計クエリのパフォーマンス向上のためのインデックス

-- started_at による範囲検索の高速化
CREATE INDEX IF NOT EXISTS idx_routes_started_at ON public.routes(started_at);

-- user_id + started_at の複合インデックス（期間別統計の高速化）
CREATE INDEX IF NOT EXISTS idx_routes_user_started ON public.routes(user_id, started_at);

-- user_id + dog_id の複合インデックス（愛犬別統計の高速化）
CREATE INDEX IF NOT EXISTS idx_routes_user_dog ON public.routes(user_id, dog_id);

-- area と prefecture による集計の高速化
CREATE INDEX IF NOT EXISTS idx_routes_area_prefecture ON public.routes(area, prefecture) WHERE area IS NOT NULL;

-- ==============================================
-- Migration completed successfully
-- ==============================================
