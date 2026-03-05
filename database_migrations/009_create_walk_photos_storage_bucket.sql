-- ============================================================================
-- Storage Bucket Creation: walk-photos
-- ============================================================================
-- Description: Create Supabase Storage bucket for walk photos
-- Author: WanWalk Development Team
-- Created: 2025-11-24
-- Version: 1
-- ============================================================================
--
-- Purpose:
-- - Store photos taken during walks (Daily and Outing)
-- - Public bucket for easy access from mobile app
-- - Organized by user_id/walk_id folder structure
--
-- Folder Structure:
-- walk-photos/
--   ├── {user_id}/
--   │   ├── {walk_id}/
--   │   │   ├── photo_1.jpg
--   │   │   ├── photo_2.jpg
--   │   │   └── ...
--
-- Usage from Flutter:
-- ```dart
-- final filePath = '$userId/$walkId/${DateTime.now().millisecondsSinceEpoch}.jpg';
-- await supabase.storage.from('walk-photos').upload(filePath, file);
-- ```
-- ============================================================================

-- ============================================================================
-- 1. Create Storage Bucket
-- ============================================================================

-- Insert bucket configuration into storage.buckets table
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'walk-photos',
  'walk-photos',
  true,  -- Public bucket for easy access
  5242880,  -- 5MB file size limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']  -- Only allow image files
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 2. Storage Policies (RLS)
-- ============================================================================

-- Anyone can read walk photos (public bucket)
CREATE POLICY "Anyone can view walk photos"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'walk-photos');

-- Authenticated users can upload walk photos
CREATE POLICY "Authenticated users can upload walk photos"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'walk-photos' 
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can update their own walk photos
CREATE POLICY "Users can update own walk photos"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'walk-photos'
    AND auth.uid()::text = (storage.foldername(name))[1]
  )
  WITH CHECK (
    bucket_id = 'walk-photos'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Users can delete their own walk photos
CREATE POLICY "Users can delete own walk photos"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'walk-photos'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- ============================================================================
-- 3. Verification Queries
-- ============================================================================

-- Check bucket was created
-- SELECT * FROM storage.buckets WHERE id = 'walk-photos';

-- Check policies were created
-- SELECT * FROM pg_policies WHERE tablename = 'objects' AND policyname LIKE '%walk photos%';

-- ============================================================================
-- 4. Test Upload (from Flutter)
-- ============================================================================

-- After executing this SQL, test from Flutter with:
-- ```dart
-- final file = File('/path/to/image.jpg');
-- final userId = supabase.auth.currentUser!.id;
-- final walkId = 'test-walk-id';
-- final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
-- final filePath = '$userId/$walkId/$fileName';
--
-- await supabase.storage
--     .from('walk-photos')
--     .upload(filePath, file);
--
-- // Get public URL
-- final publicUrl = supabase.storage
--     .from('walk-photos')
--     .getPublicUrl(filePath);
-- print('Photo uploaded: $publicUrl');
-- ```

-- ============================================================================
-- End of Migration: 009_create_walk_photos_storage_bucket.sql
-- ============================================================================
