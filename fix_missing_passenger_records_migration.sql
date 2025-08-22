-- Migration to fix missing passenger/driver records for existing users
-- This addresses the issue where wallet access fails due to missing passenger records
-- Run this in Supabase SQL editor after deploying the UserService changes

-- ==========================================
-- 1) Create missing passenger records
-- ==========================================

-- Insert passenger records for app_users with user_type='passenger' who don't have passenger records
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
-- 2) Create missing driver records (basic)
-- ==========================================

-- NOTE: For driver records, we need to provide all required fields.
-- Since these are existing users who haven't completed driver onboarding,
-- we'll create placeholder records that will need to be completed later.

INSERT INTO drivers (
    user_id,
    cnh_number,
    cnh_expiry_date,
    cnh_photo_url,
    vehicle_brand,
    vehicle_model,
    vehicle_year,
    vehicle_color,
    vehicle_plate,
    vehicle_category,
    crlv_photo_url,
    approval_status,
    approved_by,
    approved_at,
    is_online,
    accepts_pet,
    pet_fee,
    accepts_grocery,
    grocery_fee,
    accepts_condo,
    condo_fee,
    stop_fee,
    ac_policy,
    custom_price_per_km,
    custom_price_per_minute,
    bank_account_type,
    bank_code,
    bank_agency,
    bank_account,
    pix_key,
    pix_key_type,
    consecutive_cancellations,
    total_trips,
    average_rating,
    current_latitude,
    current_longitude,
    last_location_update
)
SELECT 
    au.user_id,
    'PENDENTE_CADASTRO' as cnh_number,
    CURRENT_DATE + INTERVAL '1 year' as cnh_expiry_date,
    '' as cnh_photo_url,
    'PENDENTE' as vehicle_brand,
    'PENDENTE' as vehicle_model,
    2020 as vehicle_year,
    'PENDENTE' as vehicle_color,
    'PENDENTE' as vehicle_plate,
    'standard' as vehicle_category,
    '' as crlv_photo_url,
    'pending' as approval_status,
    NULL as approved_by,
    NULL as approved_at,
    false as is_online,
    false as accepts_pet,
    0.0 as pet_fee,
    false as accepts_grocery,
    0.0 as grocery_fee,
    false as accepts_condo,
    0.0 as condo_fee,
    0.0 as stop_fee,
    'on_request' as ac_policy,
    0.0 as custom_price_per_km,
    0.0 as custom_price_per_minute,
    'corrente' as bank_account_type,
    '' as bank_code,
    '' as bank_agency,
    '' as bank_account,
    '' as pix_key,
    'email' as pix_key_type,
    0 as consecutive_cancellations,
    0 as total_trips,
    NULL as average_rating,
    NULL as current_latitude,
    NULL as current_longitude,
    NULL as last_location_update
FROM app_users au
LEFT JOIN drivers d ON au.user_id = d.user_id
WHERE au.user_type = 'driver' 
  AND au.status = 'active'
  AND d.id IS NULL;

-- ==========================================
-- 3) Verify the migration results
-- ==========================================

-- Check how many passenger records were created
SELECT 
    'passenger_records_created' as operation,
    COUNT(*) as count
FROM passengers p
JOIN app_users au ON p.user_id = au.user_id
WHERE au.user_type = 'passenger';

-- Check how many driver records were created
SELECT 
    'driver_records_created' as operation,
    COUNT(*) as count
FROM drivers d
JOIN app_users au ON d.user_id = au.user_id
WHERE au.user_type = 'driver';

-- Check for any remaining missing records (should be 0)
SELECT 
    'missing_passenger_records' as issue,
    COUNT(*) as count
FROM app_users au
LEFT JOIN passengers p ON au.user_id = p.user_id
WHERE au.user_type = 'passenger' 
  AND au.status = 'active'
  AND p.id IS NULL;

SELECT 
    'missing_driver_records' as issue,
    COUNT(*) as count
FROM app_users au
LEFT JOIN drivers d ON au.user_id = d.user_id
WHERE au.user_type = 'driver' 
  AND au.status = 'active'
  AND d.id IS NULL;

-- ==========================================
-- 4) Wallet creation verification
-- ==========================================

-- Check if passenger wallets are properly created by the trigger
-- (The trigger should auto-create wallets when passenger records are inserted)
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

-- Success message
SELECT 'Migration completed successfully! Check the counts above to verify results.' as status;