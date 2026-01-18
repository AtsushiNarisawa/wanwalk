-- Step 1: pin_type の制約を削除
ALTER TABLE route_pins
DROP CONSTRAINT IF EXISTS route_pins_pin_type_check;

-- Step 2: 新しい制約を追加（facility を含む）
ALTER TABLE route_pins
ADD CONSTRAINT route_pins_pin_type_check 
CHECK (pin_type = ANY (ARRAY['scenery'::text, 'shop'::text, 'encounter'::text, 'other'::text, 'facility'::text]));

-- Step 3: facility_info カラムを追加（施設情報を JSON で格納）
ALTER TABLE route_pins
ADD COLUMN IF NOT EXISTS facility_info JSONB;

-- Step 4: is_official フラグを追加（管理者投稿かどうか）
ALTER TABLE route_pins
ADD COLUMN IF NOT EXISTS is_official BOOLEAN NOT NULL DEFAULT false;

-- Step 5: facility_info のコメント（ドキュメント用）
COMMENT ON COLUMN route_pins.facility_info IS '施設情報（JSON形式）: {"opening_hours": "9:00-17:00", "phone": "0460-80-0290", "website": "https://...", "pet_friendly": true, "services": ["ドッグホテル", "カフェ"]}';

COMMENT ON COLUMN route_pins.is_official IS '公式投稿フラグ（管理者が投稿した施設紹介ピン）';

-- Step 6: 変更内容を確認
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'route_pins'
  AND column_name IN ('pin_type', 'facility_info', 'is_official')
ORDER BY ordinal_position;
