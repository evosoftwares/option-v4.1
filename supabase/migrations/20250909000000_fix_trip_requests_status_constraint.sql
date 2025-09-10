-- Fix trip_requests status constraint to include missing status values used in code

-- Drop existing constraint
ALTER TABLE trip_requests DROP CONSTRAINT IF EXISTS trip_requests_status_check;

-- Add new constraint with all status values used in the code
ALTER TABLE trip_requests ADD CONSTRAINT trip_requests_status_check 
  CHECK (status = ANY (ARRAY[
    'searching'::text,         -- Initial state when passenger requests trip
    'pending'::text,           -- When sent to specific driver (fallback system)
    'driver_selected'::text,   -- When driver is selected but not yet accepted
    'accepted'::text,          -- When driver accepts the request  
    'rejected'::text,          -- When driver rejects the request
    'expired'::text,           -- When request times out
    'cancelled'::text          -- When request is cancelled by passenger or system
  ]));

-- Update supabase.md documentation comment
COMMENT ON CONSTRAINT trip_requests_status_check ON trip_requests IS 
  'Status values: searching (initial), pending (sent to driver), driver_selected (driver chosen), accepted (driver accepted), rejected (driver rejected), expired (timeout), cancelled (cancelled by user/system)';