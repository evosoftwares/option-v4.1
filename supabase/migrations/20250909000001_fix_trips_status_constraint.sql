-- Fix trips status constraint to include 'requested' status used in code

-- Drop existing constraint
ALTER TABLE trips DROP CONSTRAINT IF EXISTS trips_status_check;

-- Add new constraint with all status values used in the code
ALTER TABLE trips ADD CONSTRAINT trips_status_check 
  CHECK (status = ANY (ARRAY[
    'requested'::text,            -- Initial state when trip is created from accepted request
    'driver_assigned'::text,      -- Driver assigned to trip
    'driver_arriving'::text,      -- Driver is on the way to passenger
    'waiting_passenger'::text,    -- Driver has arrived and is waiting
    'in_progress'::text,          -- Trip is in progress
    'completed'::text,            -- Trip completed successfully
    'cancelled_by_passenger'::text, -- Cancelled by passenger
    'cancelled_by_driver'::text,  -- Cancelled by driver
    'no_show'::text              -- Passenger didn't show up
  ]));

-- Update comment for documentation
COMMENT ON CONSTRAINT trips_status_check ON trips IS 
  'Trip status values: requested (created from accepted request), driver_assigned, driver_arriving, waiting_passenger, in_progress, completed, cancelled_by_passenger, cancelled_by_driver, no_show';