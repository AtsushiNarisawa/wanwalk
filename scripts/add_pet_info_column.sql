-- =====================================================
-- WanMap: official_routesテーブルにpet_infoカラムを追加
-- =====================================================
-- 実行日: 2025-11-30
-- 目的: 愛犬家向け情報を格納するJSONBカラムを追加

-- pet_infoカラムを追加（存在しない場合のみ）
ALTER TABLE public.official_routes 
ADD COLUMN IF NOT EXISTS pet_info JSONB;

-- コメントを追加
COMMENT ON COLUMN public.official_routes.pet_info IS '愛犬家向け情報（駐車場、道の状態、水飲み場、トイレ、ペット施設、その他）';

-- インデックスを追加（JSONB検索の高速化）
CREATE INDEX IF NOT EXISTS idx_official_routes_pet_info 
ON public.official_routes USING GIN (pet_info);

-- 完了メッセージ
SELECT 'pet_infoカラムの追加が完了しました' AS status;
