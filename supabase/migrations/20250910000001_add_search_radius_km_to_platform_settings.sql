-- Add search_radius_km column to platform_settings table

-- Add the new column
ALTER TABLE platform_settings 
ADD COLUMN search_radius_km INTEGER DEFAULT 10;

-- Add check constraint to ensure reasonable radius values
ALTER TABLE platform_settings 
ADD CONSTRAINT search_radius_km_check 
  CHECK (search_radius_km > 0 AND search_radius_km <= 50);

-- Update existing records with default values
UPDATE platform_settings 
SET search_radius_km = CASE 
  WHEN category = 'common_car' THEN 10
  WHEN category = 'freight' THEN 15
  WHEN category = 'tow_truck' THEN 20
  ELSE 10
END
WHERE search_radius_km IS NULL;

-- Add comment to document the column
COMMENT ON COLUMN platform_settings.search_radius_km IS 
  'Search radius in kilometers for finding available drivers. Must be between 1 and 50 km.';