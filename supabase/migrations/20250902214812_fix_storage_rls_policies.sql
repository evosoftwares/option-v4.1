-- Fix Supabase Storage RLS Policies for user-photos bucket
-- This migration addresses the "new row violates row-level security policy" error

-- Drop existing policies if they exist (to recreate them properly)
DROP POLICY IF EXISTS "user_photos_insert" ON storage.objects;
DROP POLICY IF EXISTS "user_photos_select" ON storage.objects;
DROP POLICY IF EXISTS "user_photos_update" ON storage.objects;
DROP POLICY IF EXISTS "user_photos_delete" ON storage.objects;
DROP POLICY IF EXISTS "user_photos_public_select" ON storage.objects;

-- Enable RLS on storage.objects table
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Create comprehensive INSERT policy for user-photos bucket
-- This allows authenticated users to insert files in user-photos bucket
CREATE POLICY "user_photos_insert" ON storage.objects
FOR INSERT 
TO authenticated
WITH CHECK (
  bucket_id = 'user-photos'
  AND auth.uid()::text IS NOT NULL
);

-- Create SELECT policy for user-photos bucket
-- This allows users to read files from user-photos bucket
CREATE POLICY "user_photos_select" ON storage.objects
FOR SELECT 
TO authenticated
USING (
  bucket_id = 'user-photos'
);

-- Create UPDATE policy for user-photos bucket (needed for upsert functionality)
-- This allows users to update files in user-photos bucket
CREATE POLICY "user_photos_update" ON storage.objects
FOR UPDATE 
TO authenticated
USING (
  bucket_id = 'user-photos'
  AND auth.uid()::text IS NOT NULL
)
WITH CHECK (
  bucket_id = 'user-photos'
  AND auth.uid()::text IS NOT NULL
);

-- Create DELETE policy for user-photos bucket
-- This allows users to delete files from user-photos bucket
CREATE POLICY "user_photos_delete" ON storage.objects
FOR DELETE 
TO authenticated
USING (
  bucket_id = 'user-photos'
  AND auth.uid()::text IS NOT NULL
);

-- Additional policy to allow public read access (since bucket is public)
CREATE POLICY "user_photos_public_select" ON storage.objects
FOR SELECT 
TO public
USING (
  bucket_id = 'user-photos'
);

-- Allow authenticated users to access storage.objects table operations
-- This is crucial for the upload to work
GRANT ALL ON storage.objects TO authenticated;

-- Ensure the bucket exists and is properly configured
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'user-photos',
  'user-photos', 
  true,
  52428800, -- 50MB
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) 
DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;