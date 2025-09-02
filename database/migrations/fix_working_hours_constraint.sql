-- Migration: Fix working_hours constraint to allow multiple time slots per day
-- Date: 2024-01-23
-- Description: Remove the unique constraint that prevents multiple working hours per day
--              and add a better constraint that prevents exact duplicates

-- Remove the problematic constraint
ALTER TABLE working_hours DROP CONSTRAINT IF EXISTS working_hours_driver_day_unique;

-- Add a new constraint that prevents exact duplicates but allows multiple slots per day
ALTER TABLE working_hours ADD CONSTRAINT working_hours_no_duplicates 
    UNIQUE (driver_id, day_of_week, start_time, end_time, is_active);

-- Add constraint to ensure start_time < end_time
ALTER TABLE working_hours ADD CONSTRAINT working_hours_valid_time_range 
    CHECK (start_time < end_time);

-- Update the schema file comment
COMMENT ON TABLE working_hours IS 'Horários de trabalho dos motoristas. Permite múltiplos intervalos por dia.';
COMMENT ON CONSTRAINT working_hours_no_duplicates ON working_hours IS 'Previne horários exatamente duplicados';
COMMENT ON CONSTRAINT working_hours_valid_time_range ON working_hours IS 'Garante que horário de início seja menor que horário de fim';