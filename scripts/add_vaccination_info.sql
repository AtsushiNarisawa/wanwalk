-- =====================================================
-- WanWalk: 愛犬プロフィールに予防接種情報を追加
-- =====================================================
-- 作成日: 2025-12-08
-- 機能: 狂犬病ワクチンと混合ワクチンの接種情報を記録
--       - 接種証明書の写真URL
--       - 接種日
-- =====================================================

-- Step 1: dogs テーブルに予防接種情報カラムを追加
ALTER TABLE dogs 
ADD COLUMN IF NOT EXISTS rabies_vaccine_photo_url TEXT,
ADD COLUMN IF NOT EXISTS rabies_vaccine_date DATE,
ADD COLUMN IF NOT EXISTS mixed_vaccine_photo_url TEXT,
ADD COLUMN IF NOT EXISTS mixed_vaccine_date DATE;

-- Step 2: カラムにコメントを追加（説明用）
COMMENT ON COLUMN dogs.rabies_vaccine_photo_url IS '狂犬病ワクチン接種証明書の写真URL';
COMMENT ON COLUMN dogs.rabies_vaccine_date IS '狂犬病ワクチン接種日';
COMMENT ON COLUMN dogs.mixed_vaccine_photo_url IS '混合ワクチン接種証明書の写真URL';
COMMENT ON COLUMN dogs.mixed_vaccine_date IS '混合ワクチン接種日';

-- 完了メッセージ
SELECT '✅ 予防接種情報カラムを追加しました' AS status;

-- 動作確認クエリ: テーブル構造を確認
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'dogs'
  AND column_name IN (
    'rabies_vaccine_photo_url',
    'rabies_vaccine_date',
    'mixed_vaccine_photo_url',
    'mixed_vaccine_date'
  )
ORDER BY column_name;
