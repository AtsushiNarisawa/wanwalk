-- ============================================================================
-- Phase 6: Dogs Table (犬情報)
-- ============================================================================
-- Description: Table for storing dog information
-- Author: WanWalk Development Team
-- Created: 2025-11-24
-- Version: 1
-- ============================================================================
--
-- 設計方針:
-- - ユーザーは複数の犬を登録可能
-- - 犬の基本情報（名前、品種、年齢、性別）を管理
-- - 犬の写真はdog-photos Storageバケットに保存
-- - 散歩時に犬を選択可能
-- ============================================================================

-- ============================================================================
-- 1. Dogs Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS dogs (
  -- Primary identifiers
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Basic information
  name TEXT NOT NULL,
  breed TEXT,  -- 品種（例: 柴犬、トイプードル）
  gender TEXT CHECK (gender IN ('male', 'female', 'unknown')),
  birth_date DATE,  -- 生年月日
  
  -- Physical attributes
  weight_kg DECIMAL(5,2),  -- 体重（kg）
  color TEXT,  -- 毛色
  
  -- Photo
  photo_url TEXT,  -- Storage path in dog-photos bucket
  
  -- Status
  is_active BOOLEAN NOT NULL DEFAULT true,  -- アクティブかどうか
  
  -- Notes
  notes TEXT,  -- メモ（性格、特徴など）
  
  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 2. Indexes for Performance
-- ============================================================================

-- Core query indexes
CREATE INDEX IF NOT EXISTS idx_dogs_user_id ON dogs(user_id);
CREATE INDEX IF NOT EXISTS idx_dogs_is_active ON dogs(is_active);
CREATE INDEX IF NOT EXISTS idx_dogs_created_at ON dogs(created_at DESC);

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_dogs_user_active 
  ON dogs(user_id, is_active);

-- ============================================================================
-- 3. Triggers
-- ============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_dogs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_dogs_updated_at
  BEFORE UPDATE ON dogs
  FOR EACH ROW
  EXECUTE FUNCTION update_dogs_updated_at();

-- ============================================================================
-- 4. Row Level Security (RLS)
-- ============================================================================

ALTER TABLE dogs ENABLE ROW LEVEL SECURITY;

-- Users can view their own dogs
CREATE POLICY "Users can view own dogs"
  ON dogs FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own dogs
CREATE POLICY "Users can insert own dogs"
  ON dogs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own dogs
CREATE POLICY "Users can update own dogs"
  ON dogs FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own dogs
CREATE POLICY "Users can delete own dogs"
  ON dogs FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- 5. Comments
-- ============================================================================

COMMENT ON TABLE dogs IS 'User dog information';
COMMENT ON COLUMN dogs.name IS 'Dog name';
COMMENT ON COLUMN dogs.breed IS 'Breed (e.g., Shiba Inu, Toy Poodle)';
COMMENT ON COLUMN dogs.gender IS 'Gender: male, female, unknown';
COMMENT ON COLUMN dogs.birth_date IS 'Date of birth';
COMMENT ON COLUMN dogs.weight_kg IS 'Weight in kilograms';
COMMENT ON COLUMN dogs.color IS 'Fur color';
COMMENT ON COLUMN dogs.photo_url IS 'Storage path in dog-photos bucket';
COMMENT ON COLUMN dogs.is_active IS 'Whether the dog is active (false if deceased)';
COMMENT ON COLUMN dogs.notes IS 'Notes about personality, characteristics, etc.';

-- ============================================================================
-- 6. Helper RPC Functions
-- ============================================================================

-- Get active dogs for a user
CREATE OR REPLACE FUNCTION get_user_dogs(p_user_id UUID)
RETURNS TABLE(
  dog_id UUID,
  dog_name TEXT,
  breed TEXT,
  gender TEXT,
  age_years INTEGER,
  photo_url TEXT,
  is_active BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    id AS dog_id,
    name AS dog_name,
    d.breed,
    d.gender,
    CASE 
      WHEN birth_date IS NOT NULL THEN 
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date))::INTEGER
      ELSE NULL
    END AS age_years,
    d.photo_url,
    d.is_active
  FROM dogs d
  WHERE d.user_id = p_user_id
    AND d.is_active = true
  ORDER BY d.created_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 7. Verification Query
-- ============================================================================

-- 実行後に以下のクエリで確認してください:
-- SELECT * FROM dogs LIMIT 1;
-- SELECT * FROM get_user_dogs('test-user-id');

-- ============================================================================
-- End of Migration: 010_create_dogs_table.sql
-- ============================================================================
