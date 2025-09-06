# Fix for CNH Photo URL Required Field Error

## Problem
The application was throwing the following error when trying to create driver records:
```
PostgrestException: 23502 - null value in column "cnh_photo_url" of relation "drivers" violates not-null constraint
```

This error occurred because the `cnh_photo_url` field in the `drivers` table is required (NOT NULL constraint) but was not being provided when creating driver records.

## Root Cause
1. The `cnh_photo_url` field was missing from the driver creation data in UserService
2. The Driver model was missing the `cnhPhotoUrl` field
3. The DriverService createDriver and updateDriver methods were not handling the `cnh_photo_url` field
4. The DriverStepperController was not passing the `cnhPhotoUrl` to the updateDriver method

## Solution
I made the following changes to fix the issue:

### 1. Updated UserService (_createDriverRecord method)
- Added `'cnh_photo_url': ''` to the driverData object to satisfy the NOT NULL constraint

### 2. Updated Driver Model (lib/models/supabase/driver.dart)
- Added `cnhPhotoUrl` field to the class constructor
- Added `cnhPhotoUrl` parameter to the factory constructor
- Added `cnhPhotoUrl` field to the class properties
- Added `cnh_photo_url` to the `toJson()` method
- Added `cnhPhotoUrl` parameter to the `copyWith` method

### 3. Updated DriverService (lib/services/driver_service.dart)
- Added `cnhPhotoUrl` parameter to the `createDriver` method signature
- Added `cnh_photo_url` to the insertData object in `createDriver` method
- Added `cnhPhotoUrl` parameter to the `updateDriver` method signature
- Added logic to update `cnh_photo_url` field in `updateDriver` method

### 4. Updated DriverStepperController (lib/controllers/driver_stepper_controller.dart)
- Added `cnhPhotoUrl: cnhUrl` parameter to the `updateDriver` call in `completeDriverRegistration` method

### 5. Created Database Migration Script
- Created SQL script to add default value for `cnh_photo_url` field and update existing records

## Testing
To test the fix:
1. Run the application and try to create a new driver account
2. Verify that the driver registration process completes without the CNH photo URL error
3. Check that driver records are created with empty `cnh_photo_url` fields initially
4. Verify that the `cnh_photo_url` field is properly updated when the user uploads their CNH photo

## Additional Considerations
1. The fix provides a temporary empty string value for `cnh_photo_url` to satisfy the database constraint
2. The actual CNH photo URL will be updated when the user completes the driver registration process
3. In a production environment, you might want to consider making the field nullable or providing a better default value
4. The database migration script should be run on the production database to ensure consistency