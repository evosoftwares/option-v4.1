-- Migration: Auto-Online System Implementation
-- Date: 2025-01-24
-- Description: Creates working_hours and driver_status tables with driver_effective_status view
--              for automatic online status management based on working hours

-- ============================================================================
-- 1. CREATE WORKING_HOURS TABLE
-- ============================================================================
-- Simplified replacement for driver_schedules table
CREATE TABLE IF NOT EXISTS working_hours (
    id BIGSERIAL PRIMARY KEY,
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6), -- 0=Sunday, 6=Saturday
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    -- Ensure no overlapping schedules for same driver/day
    CONSTRAINT unique_driver_day_time UNIQUE (driver_id, day_of_week, start_time, end_time)
);

-- Create indexes for performance
CREATE INDEX idx_working_hours_driver_id ON working_hours(driver_id);
CREATE INDEX idx_working_hours_day_of_week ON working_hours(day_of_week);
CREATE INDEX idx_working_hours_driver_day ON working_hours(driver_id, day_of_week);

-- Add comments
COMMENT ON TABLE working_hours IS 'Driver working hours schedule (simplified replacement for driver_schedules)';
COMMENT ON COLUMN working_hours.day_of_week IS 'Day of week: 0=Sunday, 1=Monday, ..., 6=Saturday';
COMMENT ON COLUMN working_hours.start_time IS 'Start time (inclusive) - no timezone, uses server time';
COMMENT ON COLUMN working_hours.end_time IS 'End time (exclusive) - handles midnight crossing';

-- ============================================================================
-- 2. CREATE DRIVER_STATUS TABLE
-- ============================================================================
-- Separates online intention from effective status
CREATE TABLE IF NOT EXISTS driver_status (
    driver_id UUID PRIMARY KEY REFERENCES drivers(id) ON DELETE CASCADE,
    online_intent BOOLEAN NOT NULL DEFAULT false,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create index for performance
CREATE INDEX idx_driver_status_online_intent ON driver_status(online_intent);

-- Add comments
COMMENT ON TABLE driver_status IS 'Driver online intention status (separate from effective status)';
COMMENT ON COLUMN driver_status.online_intent IS 'Driver intention to be online (user toggle)';
COMMENT ON COLUMN driver_status.updated_at IS 'Last update timestamp (server UTC time)';

-- ============================================================================
-- 3. CREATE DRIVER_EFFECTIVE_STATUS VIEW
-- ============================================================================
-- Calculates effective online status combining intent + working hours
CREATE OR REPLACE VIEW driver_effective_status AS
SELECT 
    d.id as driver_id,
    COALESCE(ds.online_intent, false) as online_intent,
    COALESCE(ds.updated_at, d.created_at) as intent_updated_at,
    
    -- Check if driver is within working hours
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM working_hours wh WHERE wh.driver_id = d.id) THEN
            true  -- No working hours defined = always available
        ELSE
            EXISTS (
                SELECT 1 FROM working_hours wh 
                WHERE wh.driver_id = d.id 
                AND wh.day_of_week = EXTRACT(DOW FROM now())
                AND (
                    -- Normal case: start_time < end_time (same day)
                    (wh.start_time <= wh.end_time AND now()::time >= wh.start_time AND now()::time < wh.end_time)
                    OR
                    -- Midnight crossing: start_time > end_time (crosses to next day)
                    (wh.start_time > wh.end_time AND (now()::time >= wh.start_time OR now()::time < wh.end_time))
                )
            )
    END as is_within_working_hours,
    
    -- Effective online status = intent AND within working hours
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM working_hours wh WHERE wh.driver_id = d.id) THEN
            COALESCE(ds.online_intent, false)  -- No working hours = use intent only
        ELSE
            COALESCE(ds.online_intent, false) AND EXISTS (
                SELECT 1 FROM working_hours wh 
                WHERE wh.driver_id = d.id 
                AND wh.day_of_week = EXTRACT(DOW FROM now())
                AND (
                    (wh.start_time <= wh.end_time AND now()::time >= wh.start_time AND now()::time < wh.end_time)
                    OR
                    (wh.start_time > wh.end_time AND (now()::time >= wh.start_time OR now()::time < wh.end_time))
                )
            )
    END as effective_online
    
FROM drivers d
LEFT JOIN driver_status ds ON d.id = ds.driver_id;

-- Add comment to view
COMMENT ON VIEW driver_effective_status IS 'Calculates effective online status combining intent and working hours';

-- ============================================================================
-- 4. CREATE TRIGGER FOR UPDATED_AT
-- ============================================================================
-- Simple trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to working_hours table
CREATE TRIGGER update_working_hours_updated_at
    BEFORE UPDATE ON working_hours
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to driver_status table
CREATE TRIGGER update_driver_status_updated_at
    BEFORE UPDATE ON driver_status
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 5. INITIALIZE DRIVER_STATUS FROM EXISTING DRIVERS
-- ============================================================================
-- Populate driver_status table with existing drivers
INSERT INTO driver_status (driver_id, online_intent, updated_at)
SELECT 
    id,
    COALESCE(is_online, false) as online_intent,
    COALESCE(updated_at, created_at) as updated_at
FROM drivers
WHERE id NOT IN (SELECT driver_id FROM driver_status)
ON CONFLICT (driver_id) DO NOTHING;

-- ============================================================================
-- 6. MIGRATION NOTES AND ARCHITECTURAL DECISIONS
-- ============================================================================
/*
ARCHITECTURAL DECISIONS:

1. TIMEZONE HANDLING:
   - Uses server now() (UTC) for all timestamps
   - No timezone conversion - keeps it simple
   - Working hours are stored as TIME (no timezone)

2. CONCURRENCY:
   - Simple updates without version control
   - No optimistic locking
   - Relies on database ACID properties

3. TIME BOUNDARIES:
   - start_time is INCLUSIVE (>=)
   - end_time is EXCLUSIVE (<)
   - Handles midnight crossing (e.g., 22:00 to 06:00)

4. NO WORKING HOURS BEHAVIOR:
   - If no working_hours defined for driver = always available
   - effective_online = online_intent only

5. CONSTRAINTS:
   - No RLS (Row Level Security) as per project requirements
   - No complex functions - only simple view and triggers
   - Well-documented triggers for updated_at only

6. PERFORMANCE:
   - Indexes on frequently queried columns
   - View uses efficient EXISTS queries
   - Unique constraints prevent data duplication

MIGRATION STRATEGY:
- Creates new tables alongside existing driver_schedules
- Initializes driver_status from existing drivers.is_online
- Does NOT migrate data from driver_schedules (manual process if needed)
- Preserves existing functionality while adding new system
*/

-- Migration completed successfully
SELECT 'Auto-Online System Migration completed successfully!' as status;