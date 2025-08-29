-- Create saved_places table for storing user favorite locations
-- This table is needed for the stepper registration flow

CREATE TABLE IF NOT EXISTS saved_places (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    passenger_id UUID NOT NULL REFERENCES passengers(id) ON DELETE CASCADE,
    label VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    category VARCHAR(50) NOT NULL DEFAULT 'other',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    -- Add check constraint to ensure valid category values
    CONSTRAINT check_category_valid 
    CHECK (category IN (
        'home', 'work', 'school', 'gym', 'restaurant', 'shopping',
        'hospital', 'bank', 'pharmacy', 'gasStation', 'park', 'cinema',
        'airport', 'hotel', 'church', 'beach', 'library', 'supermarket',
        'cafe', 'favorite', 'other'
    )),
    
    -- Ensure passenger can't have duplicate locations with same name
    CONSTRAINT unique_passenger_label UNIQUE (passenger_id, label)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_saved_places_passenger_id ON saved_places(passenger_id);
CREATE INDEX IF NOT EXISTS idx_saved_places_category ON saved_places(category);
CREATE INDEX IF NOT EXISTS idx_saved_places_created_at ON saved_places(created_at);

-- Add updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_saved_places_updated_at BEFORE UPDATE ON saved_places 
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Add comments for documentation
COMMENT ON TABLE saved_places IS 'Stores user favorite locations entered during registration and later';
COMMENT ON COLUMN saved_places.passenger_id IS 'Reference to the passenger who owns this location';
COMMENT ON COLUMN saved_places.label IS 'User-friendly name for the location (e.g., "Casa", "Trabalho")';
COMMENT ON COLUMN saved_places.address IS 'Full address of the location';
COMMENT ON COLUMN saved_places.latitude IS 'Latitude coordinate of the location';
COMMENT ON COLUMN saved_places.longitude IS 'Longitude coordinate of the location';
COMMENT ON COLUMN saved_places.category IS 'Category type for the saved place (LocationType enum)';

-- Grant necessary permissions (adjust based on your RLS policies)
-- ALTER TABLE saved_places ENABLE ROW LEVEL SECURITY;

-- Example RLS policy (uncomment and adjust as needed):
-- CREATE POLICY "Users can view their own saved places" ON saved_places FOR SELECT 
-- USING (passenger_id = (
--     SELECT p.id FROM passengers p 
--     JOIN app_users au ON p.user_id = au.user_id 
--     WHERE au.user_id = auth.uid()
-- ));

-- CREATE POLICY "Users can insert their own saved places" ON saved_places FOR INSERT 
-- WITH CHECK (passenger_id = (
--     SELECT p.id FROM passengers p 
--     JOIN app_users au ON p.user_id = au.user_id 
--     WHERE au.user_id = auth.uid()
-- ));

-- CREATE POLICY "Users can update their own saved places" ON saved_places FOR UPDATE 
-- USING (passenger_id = (
--     SELECT p.id FROM passengers p 
--     JOIN app_users au ON p.user_id = au.user_id 
--     WHERE au.user_id = auth.uid()
-- ));

-- CREATE POLICY "Users can delete their own saved places" ON saved_places FOR DELETE 
-- USING (passenger_id = (
--     SELECT p.id FROM passengers p 
--     JOIN app_users au ON p.user_id = au.user_id 
--     WHERE au.user_id = auth.uid()
-- ));

-- Verification query to check if table was created successfully
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'saved_places' 
ORDER BY ordinal_position;