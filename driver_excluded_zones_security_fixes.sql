-- ==========================================
-- Driver Excluded Zones Security Fixes
-- ==========================================
-- This migration addresses critical security and performance issues
-- identified in the excluded zones analysis

-- 1. Add UNIQUE constraint to prevent duplicates
-- This fixes the critical race condition issue
DO $$
BEGIN
    -- First remove any existing duplicates if they exist
    DELETE FROM driver_excluded_zones a USING (
        SELECT MIN(ctid) as ctid, driver_id, neighborhood_name, city, state
        FROM driver_excluded_zones 
        GROUP BY driver_id, neighborhood_name, city, state 
        HAVING COUNT(*) > 1
    ) b
    WHERE a.driver_id = b.driver_id 
    AND a.neighborhood_name = b.neighborhood_name 
    AND a.city = b.city 
    AND a.state = b.state 
    AND a.ctid <> b.ctid;

    -- Add the unique constraint
    ALTER TABLE driver_excluded_zones 
    ADD CONSTRAINT uk_driver_excluded_zones 
    UNIQUE (driver_id, neighborhood_name, city, state);
END
$$;

-- 2. Add audit fields for tracking changes
ALTER TABLE driver_excluded_zones 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES auth.users(id);

-- 3. Create trigger function for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 4. Create trigger for automatic updated_at updates
DROP TRIGGER IF EXISTS update_driver_excluded_zones_updated_at ON driver_excluded_zones;
CREATE TRIGGER update_driver_excluded_zones_updated_at 
BEFORE UPDATE ON driver_excluded_zones 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 5. Add performance indexes
CREATE INDEX IF NOT EXISTS idx_driver_excluded_zones_driver_id 
ON driver_excluded_zones(driver_id);

CREATE INDEX IF NOT EXISTS idx_driver_excluded_zones_location 
ON driver_excluded_zones(city, state);

CREATE INDEX IF NOT EXISTS idx_driver_excluded_zones_updated_at 
ON driver_excluded_zones(updated_at);

-- 6. Create function to check zone limits per driver
CREATE OR REPLACE FUNCTION check_driver_zones_limit()
RETURNS TRIGGER AS $$
DECLARE
    zone_count integer;
    max_zones integer := 50; -- Maximum zones per driver
BEGIN
    -- Count existing zones for this driver
    SELECT COUNT(*) INTO zone_count
    FROM driver_excluded_zones 
    WHERE driver_id = NEW.driver_id;
    
    -- Check if limit would be exceeded
    IF zone_count >= max_zones THEN
        RAISE EXCEPTION 'Driver has reached maximum number of excluded zones (%). Current count: %', 
            max_zones, zone_count;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 7. Create trigger for zone limit validation
DROP TRIGGER IF EXISTS check_zones_limit ON driver_excluded_zones;
CREATE TRIGGER check_zones_limit
BEFORE INSERT ON driver_excluded_zones
FOR EACH ROW EXECUTE FUNCTION check_driver_zones_limit();

-- 8. Create function for normalized text comparison
CREATE OR REPLACE FUNCTION normalize_text(input_text text)
RETURNS text AS $$
BEGIN
    IF input_text IS NULL THEN
        RETURN NULL;
    END IF;
    
    RETURN LOWER(
        TRIM(
            REGEXP_REPLACE(
                TRANSLATE(
                    input_text,
                    'ãáàâäõóòôöúùûüíìîïéèêëçñ',
                    'aaaaaoooooouuuuiiiieeeecn'
                ),
                '\s+', ' ', 'g'
            )
        )
    );
END;
$$ language 'plpgsql' IMMUTABLE;

-- 9. Create function to validate Brazilian states
CREATE OR REPLACE FUNCTION is_valid_brazilian_state(state_code text)
RETURNS boolean AS $$
DECLARE
    valid_states text[] := ARRAY[
        'ac', 'al', 'ap', 'am', 'ba', 'ce', 'df', 'es', 'go',
        'ma', 'mt', 'ms', 'mg', 'pa', 'pb', 'pr', 'pe', 'pi',
        'rj', 'rn', 'rs', 'ro', 'rr', 'sc', 'sp', 'se', 'to'
    ];
BEGIN
    RETURN normalize_text(state_code) = ANY(valid_states);
END;
$$ language 'plpgsql' IMMUTABLE;

-- 10. Create trigger function for state validation
CREATE OR REPLACE FUNCTION validate_zone_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Normalize the input data
    NEW.neighborhood_name := normalize_text(NEW.neighborhood_name);
    NEW.city := normalize_text(NEW.city);
    NEW.state := normalize_text(NEW.state);
    
    -- Validate state
    IF NOT is_valid_brazilian_state(NEW.state) THEN
        RAISE EXCEPTION 'Invalid Brazilian state code: %', NEW.state;
    END IF;
    
    -- Validate required fields are not empty after normalization
    IF NEW.neighborhood_name IS NULL OR LENGTH(TRIM(NEW.neighborhood_name)) = 0 THEN
        RAISE EXCEPTION 'Neighborhood name cannot be empty';
    END IF;
    
    IF NEW.city IS NULL OR LENGTH(TRIM(NEW.city)) = 0 THEN
        RAISE EXCEPTION 'City name cannot be empty';
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 11. Create trigger for data validation and normalization
DROP TRIGGER IF EXISTS validate_zone_data_trigger ON driver_excluded_zones;
CREATE TRIGGER validate_zone_data_trigger
BEFORE INSERT OR UPDATE ON driver_excluded_zones
FOR EACH ROW EXECUTE FUNCTION validate_zone_data();

-- 12. Create activity log table for audit trail
CREATE TABLE IF NOT EXISTS activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    action VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 13. Create index for activity logs
CREATE INDEX IF NOT EXISTS idx_activity_logs_user_id ON activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_entity ON activity_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs(created_at);

-- 14. Create audit function for excluded zones
CREATE OR REPLACE FUNCTION audit_excluded_zones()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO activity_logs (user_id, action, entity_type, entity_id, new_values, metadata)
        VALUES (
            NEW.updated_by,
            'CREATE',
            'driver_excluded_zone',
            NEW.id,
            row_to_json(NEW),
            jsonb_build_object('timestamp', NOW(), 'source', 'database_trigger')
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO activity_logs (user_id, action, entity_type, entity_id, old_values, new_values, metadata)
        VALUES (
            NEW.updated_by,
            'UPDATE',
            'driver_excluded_zone',
            NEW.id,
            row_to_json(OLD),
            row_to_json(NEW),
            jsonb_build_object('timestamp', NOW(), 'source', 'database_trigger')
        );
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO activity_logs (user_id, action, entity_type, entity_id, old_values, metadata)
        VALUES (
            OLD.updated_by,
            'DELETE',
            'driver_excluded_zone',
            OLD.id,
            row_to_json(OLD),
            jsonb_build_object('timestamp', NOW(), 'source', 'database_trigger')
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

-- 15. Create audit trigger
DROP TRIGGER IF EXISTS audit_excluded_zones_trigger ON driver_excluded_zones;
CREATE TRIGGER audit_excluded_zones_trigger
AFTER INSERT OR UPDATE OR DELETE ON driver_excluded_zones
FOR EACH ROW EXECUTE FUNCTION audit_excluded_zones();

-- 16. Add helpful comments to functions
COMMENT ON FUNCTION normalize_text(text) IS 
'Normalizes text by converting to lowercase, trimming whitespace, and removing accents for consistent comparison';

COMMENT ON FUNCTION is_valid_brazilian_state(text) IS 
'Validates if the provided text is a valid Brazilian state code (AC, AL, AP, etc.)';

COMMENT ON FUNCTION check_driver_zones_limit() IS 
'Enforces maximum limit of excluded zones per driver (currently 50)';

COMMENT ON FUNCTION validate_zone_data() IS 
'Validates and normalizes zone data before insertion/update';

COMMENT ON FUNCTION audit_excluded_zones() IS 
'Creates audit trail entries for all excluded zone operations';

-- 17. Create view for zone statistics
CREATE OR REPLACE VIEW driver_excluded_zones_stats AS
SELECT 
    driver_id,
    COUNT(*) as total_zones,
    COUNT(DISTINCT city || '-' || state) as cities_count,
    MAX(created_at) as last_zone_added,
    MAX(updated_at) as last_modification
FROM driver_excluded_zones
GROUP BY driver_id;

COMMENT ON VIEW driver_excluded_zones_stats IS 
'Provides statistical overview of excluded zones per driver';

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Driver Excluded Zones security fixes applied successfully!';
    RAISE NOTICE 'Applied fixes:';
    RAISE NOTICE '✓ UNIQUE constraint for duplicate prevention';
    RAISE NOTICE '✓ Audit fields and triggers';
    RAISE NOTICE '✓ Performance indexes';
    RAISE NOTICE '✓ Zone limit validation (50 per driver)';
    RAISE NOTICE '✓ Data normalization and validation';
    RAISE NOTICE '✓ Brazilian state validation';
    RAISE NOTICE '✓ Comprehensive audit logging';
    RAISE NOTICE '✓ Statistical views';
END
$$;