-- Migration: Add category column to saved_places table
-- Date: 2024-01-21
-- Description: Adds a category column to store LocationType for saved places

-- Add category column with default value 'other'
ALTER TABLE saved_places 
ADD COLUMN category VARCHAR(50) NOT NULL DEFAULT 'other';

-- Add check constraint to ensure valid category values
ALTER TABLE saved_places 
ADD CONSTRAINT check_category_valid 
CHECK (category IN (
  'home', 'work', 'school', 'gym', 'restaurant', 'shopping',
  'hospital', 'bank', 'pharmacy', 'gasStation', 'park', 'cinema',
  'airport', 'hotel', 'church', `'beach', 'library', 'supermarket',
  'cafe', 'favorite', 'other'
));

-- Create index for better query performance
CREATE INDEX idx_saved_places_category ON saved_places(category);

-- Update existing records to have 'other' category if null
UPDATE saved_places 
SET category = 'other' 
WHERE category IS NULL;

-- Add comment to the column
COMMENT ON COLUMN saved_places.category IS 'Category type for the saved place (LocationType enum)';