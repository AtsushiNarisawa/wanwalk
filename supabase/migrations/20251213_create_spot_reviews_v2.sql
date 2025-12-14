-- スポット評価・レビュー機能のマイグレーション
-- 作成日: 2025-12-13
-- 目的: バッジコレクション機能をスポット評価・レビュー機能に置き換え
-- バージョン: v2（ポリシー名を明確化）

-- スポット評価・レビューテーブル
CREATE TABLE IF NOT EXISTS spot_reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  spot_id UUID NOT NULL REFERENCES route_pins(id) ON DELETE CASCADE,
  
  -- 評価情報
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review_text TEXT,
  
  -- 基本設備情報
  has_water_fountain BOOLEAN DEFAULT false,
  has_dog_run BOOLEAN DEFAULT false,
  has_shade BOOLEAN DEFAULT false,
  has_toilet BOOLEAN DEFAULT false,
  has_parking BOOLEAN DEFAULT false,
  has_dog_waste_bin BOOLEAN DEFAULT false,
  
  -- 利用条件
  leash_required BOOLEAN DEFAULT false,
  dog_friendly_cafe BOOLEAN DEFAULT false,
  dog_size_suitable VARCHAR(50), -- 'small', 'medium', 'large', 'all'
  
  -- 追加情報
  seasonal_info VARCHAR(100), -- 季節の見どころ（任意）
  
  -- 写真
  photo_urls TEXT[], -- 複数の写真URL
  
  -- メタ情報
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  -- ユニーク制約：1ユーザー1スポット1レビュー
  UNIQUE(user_id, spot_id)
);

-- コメント追加
COMMENT ON TABLE spot_reviews IS 'スポット評価・レビュー情報';
COMMENT ON COLUMN spot_reviews.rating IS '星評価（1-5）';
COMMENT ON COLUMN spot_reviews.review_text IS 'レビューテキスト';
COMMENT ON COLUMN spot_reviews.has_water_fountain IS '水飲み場の有無';
COMMENT ON COLUMN spot_reviews.has_dog_run IS 'ドッグランの有無';
COMMENT ON COLUMN spot_reviews.has_shade IS '日陰の有無';
COMMENT ON COLUMN spot_reviews.has_toilet IS 'トイレの有無';
COMMENT ON COLUMN spot_reviews.has_parking IS '駐車場の有無';
COMMENT ON COLUMN spot_reviews.has_dog_waste_bin IS '犬用ゴミ箱の有無';
COMMENT ON COLUMN spot_reviews.leash_required IS 'リード必須かどうか';
COMMENT ON COLUMN spot_reviews.dog_friendly_cafe IS '犬同伴可能なカフェがあるか';
COMMENT ON COLUMN spot_reviews.dog_size_suitable IS '適した犬のサイズ（small/medium/large/all）';
COMMENT ON COLUMN spot_reviews.seasonal_info IS '季節情報（桜の季節、紅葉など）';
COMMENT ON COLUMN spot_reviews.photo_urls IS 'レビュー写真のURL配列';

-- インデックス（クエリ最適化）
CREATE INDEX IF NOT EXISTS idx_spot_reviews_spot_id ON spot_reviews(spot_id);
CREATE INDEX IF NOT EXISTS idx_spot_reviews_user_id ON spot_reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_spot_reviews_rating ON spot_reviews(rating DESC);
CREATE INDEX IF NOT EXISTS idx_spot_reviews_created_at ON spot_reviews(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_spot_reviews_spot_rating ON spot_reviews(spot_id, rating DESC);

-- 更新日時の自動更新トリガー
-- 注: update_updated_at_column()関数は既存のため、CREATE OR REPLACEで再利用
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- トリガーの作成（DROP IF EXISTSで既存を削除してから作成）
DROP TRIGGER IF EXISTS update_spot_reviews_updated_at ON spot_reviews;
CREATE TRIGGER update_spot_reviews_updated_at 
    BEFORE UPDATE ON spot_reviews 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS)
ALTER TABLE spot_reviews ENABLE ROW LEVEL SECURITY;

-- 既存ポリシーを削除（あれば）
DROP POLICY IF EXISTS "spot_reviews_select_policy" ON spot_reviews;
DROP POLICY IF EXISTS "spot_reviews_insert_policy" ON spot_reviews;
DROP POLICY IF EXISTS "spot_reviews_update_policy" ON spot_reviews;
DROP POLICY IF EXISTS "spot_reviews_delete_policy" ON spot_reviews;

-- ポリシー：誰でも読み取り可能（テーブル名を含む明確な名前）
CREATE POLICY "spot_reviews_select_policy" ON spot_reviews
    FOR SELECT USING (true);

-- ポリシー：自分のレビューのみ作成可能
CREATE POLICY "spot_reviews_insert_policy" ON spot_reviews
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ポリシー：自分のレビューのみ更新可能
CREATE POLICY "spot_reviews_update_policy" ON spot_reviews
    FOR UPDATE USING (auth.uid() = user_id);

-- ポリシー：自分のレビューのみ削除可能
CREATE POLICY "spot_reviews_delete_policy" ON spot_reviews
    FOR DELETE USING (auth.uid() = user_id);
