# Wallet Access Fix Implementation

## Problem
Passenger users were unable to access their wallet due to the error "Não encontramos seu perfil de passageiro" (We didn't find your passenger profile).

## Root Cause
The system was creating `app_users` records during registration but not creating corresponding records in the `passengers` table. The wallet system depends on the existence of passenger records to function properly.

## Solution Overview

The fix implements a three-layer approach to ensure robust passenger record management:

### 1. Registration Fix (UserService)
**File:** `lib/services/user_service.dart`

- **Modified:** `createUser()` method to automatically create passenger/driver records
- **Added:** `_createUserSpecificRecord()`, `_createPassengerRecord()`, and `_createDriverRecord()` methods
- **Behavior:** When a new user is created, the system now automatically creates the corresponding passenger or driver record based on the user type

### 2. Data Migration (SQL)
**File:** `fix_missing_passenger_records_migration.sql`

- **Purpose:** Fix existing users who were created before the passenger record logic was implemented
- **Actions:**
  - Creates missing passenger records for all `app_users` with `user_type='passenger'`
  - Creates placeholder driver records for all `app_users` with `user_type='driver'` (with values like 'PENDENTE_CADASTRO' that need to be completed during driver onboarding)
  - Includes verification queries to confirm the migration success
- **Database Triggers:** The existing database trigger will automatically create wallet records when passenger records are inserted
- **Driver Records:** Uses placeholder values for required fields since existing driver users haven't completed onboarding

### 3. Runtime Fallback (WalletService)
**File:** `lib/services/wallet_service.dart`

- **Modified:** `getPassengerIdForUser()` method
- **Added:** `_autoCreateMissingPassengerRecord()` method
- **Behavior:** If a passenger record is not found at runtime, the system checks if the user is a passenger-type user and auto-creates the missing record

## Implementation Details

### UserService Changes
```dart
// In createUser() method
final user = User.fromMap(response);

// Create corresponding passenger or driver record
await _createUserSpecificRecord(user);

return user;
```

The new methods handle:
- Checking if records already exist (idempotent)
- Creating minimal required data for passengers
- Creating basic driver records (to be completed during onboarding)
- Error handling without breaking user creation

### WalletService Changes
```dart
// In getPassengerIdForUser() method
final data = await _supabase
    .from('passengers')
    .select('id')
    .eq('user_id', userId)
    .maybeSingle();
    
if (data != null) {
  return data['id'] as String;
}

// Auto-create missing passenger record
return await _autoCreateMissingPassengerRecord(userId);
```

The fallback logic:
- Verifies the user is actually a passenger-type user
- Creates the missing passenger record
- Handles race conditions (multiple requests creating records simultaneously)
- Returns null for non-passenger users

## Database Schema Dependencies

The fix relies on existing database structures:
- `app_users` table with `user_type` field
- `passengers` table with `user_id` foreign key
- `drivers` table with `user_id` foreign key
- Database trigger that auto-creates `passenger_wallets` when passenger records are inserted

## Migration Instructions

1. **Deploy Code Changes**
   ```bash
   # The updated UserService and WalletService are now deployed
   ```

2. **Run Migration SQL**
   ```sql
   -- Execute the contents of fix_missing_passenger_records_migration.sql
   -- in Supabase SQL editor
   ```

3. **Verify Fix**
   - Test wallet access for existing passenger users
   - Create new passenger users and verify wallet access works
   - Check migration verification queries results

## Testing Scenarios

✅ **New User Registration**
- Create new passenger user → passenger record should be created automatically
- Wallet screen should work immediately

✅ **Existing Users (Post-Migration)**
- Existing passenger users should have passenger records created by migration
- Wallet screen should work for all existing users

✅ **Edge Cases**
- Multiple concurrent requests creating records → handled by unique constraints
- Driver users accessing driver functionality → driver records created
- Non-existent users → proper error handling

## Monitoring

The implementation includes logging for monitoring:
- Successful passenger/driver record creation
- Auto-creation of missing records at runtime
- Error cases and fallback scenarios

Look for log messages:
- `🔄 Criando registro específico para passenger: <user_id>`
- `🆘 Auto-created missing passenger record for user <user_id> -> passenger <passenger_id>`
- `❌ Failed to auto-create passenger record: <error>`

## Rollback Plan

If issues arise, the changes can be safely rolled back:
1. Revert the UserService and WalletService changes
2. The migration SQL only adds data, doesn't modify existing data
3. Any auto-created passenger records will remain and continue to work

The fix is designed to be backward-compatible and non-destructive.