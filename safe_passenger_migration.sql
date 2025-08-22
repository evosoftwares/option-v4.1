-- Safe migration that focuses on passenger records first
-- If driver record creation fails due to constraints, we can handle that separately

-- ==========================================
-- 1) Create missing passenger records ONLY
-- ==========================================

-- This is the critical fix for the wallet access issue
INSERT INTO passengers (user_id, consecutive_cancellations, total_trips, average_rating, payment_method_id)
SELECT 
    au.user_id,
    0 as consecutive_cancellations,
    0 as total_trips,
    NULL as average_rating,
    NULL as payment_method_id
FROM app_users au
LEFT JOIN passengers p ON au.user_id = p.user_id
WHERE au.user_type = 'passenger' 
  AND au.status = 'active'
  AND p.id IS NULL;

-- ==========================================
-- 2) Verify passenger records creation
-- ==========================================

-- Check how many passenger records were created
SELECT 
    'passenger_records_created' as operation,
    COUNT(*) as count
FROM passengers p
JOIN app_users au ON p.user_id = au.user_id
WHERE au.user_type = 'passenger';

-- Check for any remaining missing passenger records (should be 0)
SELECT 
    'missing_passenger_records' as issue,
    COUNT(*) as count
FROM app_users au
LEFT JOIN passengers p ON au.user_id = p.user_id
WHERE au.user_type = 'passenger' 
  AND au.status = 'active'
  AND p.id IS NULL;

-- ==========================================
-- 3) Check passenger wallets creation
-- ==========================================

-- Check if passenger wallets are properly created by the trigger
SELECT 
    'passenger_wallets_created' as operation,
    COUNT(*) as count
FROM passenger_wallets pw
JOIN passengers p ON pw.passenger_id = p.id
JOIN app_users au ON p.user_id = au.user_id
WHERE au.user_type = 'passenger';

-- Check for passengers without wallets (should be 0 if trigger works)
SELECT 
    'passengers_without_wallets' as issue,
    COUNT(*) as count
FROM passengers p
LEFT JOIN passenger_wallets pw ON p.id = pw.passenger_id
JOIN app_users au ON p.user_id = au.user_id
WHERE au.user_type = 'passenger' 
  AND pw.id IS NULL;

-- ==========================================
-- 4) Driver analysis (for information only)
-- ==========================================

-- Check how many driver-type users exist
SELECT 
    'driver_users_total' as info,
    COUNT(*) as count
FROM app_users au
WHERE au.user_type = 'driver' 
  AND au.status = 'active';

-- Check how many already have driver records
SELECT 
    'driver_records_existing' as info,
    COUNT(*) as count
FROM drivers d
JOIN app_users au ON d.user_id = au.user_id
WHERE au.user_type = 'driver';

-- Check how many driver users are missing driver records
SELECT 
    'driver_users_missing_records' as info,
    COUNT(*) as count
FROM app_users au
LEFT JOIN drivers d ON au.user_id = d.user_id
WHERE au.user_type = 'driver' 
  AND au.status = 'active'
  AND d.id IS NULL;

-- Success message
SELECT 'Passenger migration completed successfully! Driver records can be handled separately if needed.' as status;