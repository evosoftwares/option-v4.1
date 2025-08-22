-- Query to check database constraints for drivers table
-- Run this first to understand what values are allowed

-- Check all check constraints on drivers table
SELECT 
    tc.constraint_name,
    cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc 
    ON tc.constraint_name = cc.constraint_name
WHERE tc.table_name = 'drivers'
  AND tc.constraint_type = 'CHECK';

-- Check existing values in drivers table for enum-like fields
SELECT DISTINCT approval_status FROM drivers WHERE approval_status IS NOT NULL;
SELECT DISTINCT vehicle_category FROM drivers WHERE vehicle_category IS NOT NULL;  
SELECT DISTINCT ac_policy FROM drivers WHERE ac_policy IS NOT NULL;
SELECT DISTINCT bank_account_type FROM drivers WHERE bank_account_type IS NOT NULL;
SELECT DISTINCT pix_key_type FROM drivers WHERE pix_key_type IS NOT NULL;