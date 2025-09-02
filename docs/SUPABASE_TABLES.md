# Supabase Database Schema - OPTION App

**Updated:** 2025-01-22  
**Database:** https://qlbwacmavngtonauxnte.supabase.co  
**Status:** 🟢 Complete production database with 30+ tables and automatic user type association

## Core User Tables

### 1. `app_users` (Application users)
**Purpose:** Main user profiles for passengers and drivers

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key, app user UUID |
| `user_id` | uuid | Foreign key to auth.users.id |
| `email` | text | User email address |
| `full_name` | text | User full name |
| `phone` | text | User phone number |
| `photo_url` | text | Profile photo URL |
| `user_type` | text | 'passenger' or 'driver' |
| `status` | text | User status |
| `created_at` | timestamp | Account creation timestamp |
| `updated_at` | timestamp | Last update timestamp |

**🔄 Automatic User Type Association:**
- When a user registers and selects their type (passenger/driver), the `user_type` field is automatically set
- The system automatically creates corresponding records in `passengers` or `drivers` tables
- This is handled by `UserService._createUserSpecificRecord()` in the Flutter app
- A database trigger `auto_create_driver_record_trigger` ensures driver records are created when `user_type` is updated to 'driver'

### 2. `passengers` 
**Purpose:** Passenger-specific data and preferences

**🔄 Automatic Creation:**
- Automatically created when `user_type='passenger'` via `UserService._createPassengerRecord()`
- Fallback creation in `WalletService._autoCreateMissingPassengerRecord()` for existing users
- Database trigger automatically creates passenger wallet when passenger record is inserted

**Key Fields:**
- `user_id` (uuid) - Links to app_users.id
- `consecutive_cancellations` (int) - Default: 0
- `total_trips` (int) - Default: 0
- `average_rating` (decimal) - Default: null
- `payment_method_id` (uuid) - Default: null

### 3. `drivers`
**Purpose:** Driver-specific data and status

**🔄 Automatic Creation:**
- Automatically created when `user_type='driver'` via `UserService._createDriverRecord()`
- Creates basic record with placeholder values (e.g., 'PENDENTE_CADASTRO' for CNH)
- Database trigger `auto_create_driver_record_trigger` handles future user_type changes
- Driver completes full profile during onboarding process

**Key Fields:**
- `user_id` (uuid) - Links to app_users.id
- `cnh_number` (text) - Default: 'PENDENTE_CADASTRO'
- `vehicle_brand`, `vehicle_model` (text) - Default: 'PENDENTE'
- `approval_status` (text) - Default: 'pending'
- `is_online` (boolean) - Default: false

## Trip & Request Tables

### 4. `trips`
**Purpose:** Complete trip records with all details

**Key Fields (47 total):**
- Trip identification: `id`, `trip_code`, `request_id`
- Users: `passenger_id`, `driver_id`  
- Locations: `origin_*`, `destination_*` (address, lat, lng, neighborhood)
- Distance & Time: `estimated_*`, `actual_*`, `driver_to_pickup_*`
- Financial: `base_fare`, `total_fare`, `driver_earnings`, `platform_commission`
- Status & Timeline: `status`, `*_at` timestamps for each stage
- Special needs: `needs_ac`, `needs_pet`, `needs_grocery_space`
- Route: `route_polyline`, `number_of_stops`

### 5. `trip_requests`
**Purpose:** Passenger trip requests before driver assignment

### 6. `trip_status_history`
**Purpose:** Track all status changes during trip lifecycle

### 7. `trip_location_history` 
**Purpose:** GPS tracking data during trips

### 8. `trip_chats`
**Purpose:** Communication between passengers and drivers

## Driver Management Tables

### 9. `driver_offers`
**Purpose:** Driver responses to trip requests

### 10. `driver_schedules`
**Purpose:** Driver availability schedules

### 11. `driver_documents`
**Purpose:** Driver license, vehicle documents

### 12. `driver_wallets` & `wallet_transactions`
**Purpose:** Driver earnings and financial transactions

### 13. `driver_performance`
**Purpose:** Driver metrics and ratings

### 14. `driver_excluded_zones`
**Purpose:** Areas where drivers cannot operate

## Location & Geography

### 15. `operational_cities`
**Purpose:** Cities where app operates

### 16. `driver_operational_cities`
**Purpose:** Cities where each driver can work

### 17. `saved_places`
**Purpose:** User favorite locations (Home, Work, etc.)

## Financial & Promotions

### 18. `promo_codes` & `promo_code_usage`
**Purpose:** Promotional codes and usage tracking

### 19. `withdrawals`
**Purpose:** Driver earnings withdrawal requests

## System & Analytics

### 20. `notifications`
**Purpose:** Push notifications to users

### 21. `user_devices`
**Purpose:** Device registration for notifications

### 22. `ratings`
**Purpose:** Trip ratings and reviews

### 23. `activity_logs`
**Purpose:** User activity tracking

### 24. `daily_statistics`
**Purpose:** Daily metrics and analytics

### 25. `platform_settings`
**Purpose:** App configuration settings

### 26. `profiles` (Supabase Auth)
**Purpose:** Extended auth user profiles

## Views & Functions

### 27. `available_drivers_view`
**Purpose:** Real-time view of drivers available for trips

### RPC Functions
- `archive_old_trips`
- `calculate_cancellation_fee`
- `check_and_suspend_user`
- `cleanup_expired_requests`
- `find_available_drivers`
- `process_trip_payment`

## Key Relationships

```
auth.users (1) ←→ (1) app_users
app_users (1) ←→ (1) passengers  
app_users (1) ←→ (1) drivers
passengers (1) ←→ (n) trip_requests
drivers (1) ←→ (n) driver_offers
trips (n) → (1) passengers
trips (n) → (1) drivers
trips (1) ←→ (n) trip_status_history
```

## Automatic User Type Association Implementation

### Flutter App Logic
**File:** `lib/services/user_service.dart`

```dart
// During user creation
static Future<void> _createUserSpecificRecord(User user) async {
  if (user.userType.toLowerCase() == 'passenger') {
    await _createPassengerRecord(user);
  } else if (user.userType.toLowerCase() == 'driver') {
    await _createDriverRecord(user);
  }
}
```

**Passenger Creation:**
- Creates record in `passengers` table with default values
- Database trigger automatically creates `passenger_wallets` record
- Fallback logic in `WalletService` for existing users

**Driver Creation:**
- Creates basic record in `drivers` table with placeholder values
- Sets `approval_status='pending'` for manual approval process
- Driver completes profile during onboarding

### Database Triggers
**File:** `correcao_associacao_motorista.sql`

```sql
-- Automatic driver record creation when user_type changes
CREATE TRIGGER auto_create_driver_record_trigger
    AFTER UPDATE OF user_type ON app_users
    FOR EACH ROW
    EXECUTE FUNCTION auto_create_driver_record();
```

**Trigger Function:**
- Monitors changes to `user_type` field in `app_users`
- Automatically creates `drivers` record when type changes to 'driver'
- Prevents duplicate records with existence check
- Uses same placeholder values as Flutter app

### Fallback Mechanisms

**For Passengers:**
- `WalletService._autoCreateMissingPassengerRecord()` handles legacy users
- Verifies user type before creating record
- Handles race conditions with unique constraint violations

**For Drivers:**
- `fix_driver_associations()` function corrects existing inconsistencies
- One-time execution to fix historical data
- Future cases handled by trigger

### Data Flow

1. **User Registration:**
   - User selects type (passenger/driver) during signup
   - `app_users` record created with `user_type`
   - `UserService._createUserSpecificRecord()` called
   - Corresponding `passengers` or `drivers` record created

2. **Profile Type Change:**
   - User updates profile to become driver
   - `app_users.user_type` updated to 'driver'
   - Database trigger `auto_create_driver_record_trigger` fires
   - Basic `drivers` record created automatically

3. **Legacy User Support:**
   - Existing users without proper associations
   - Fallback creation during wallet access
   - Correction scripts for bulk fixes

## Database Status

🟢 **Production Ready:** This is a fully implemented ride-sharing database with:
- Complete user management (passengers + drivers)
- **Automatic user type association** with fallback mechanisms
- Full trip lifecycle (request → assignment → completion)
- Financial transactions and earnings
- Real-time tracking and communication
- Analytics and reporting
- Geographic operations management

**Note:** Row Level Security (RLS) is enabled on all tables, preventing direct access without proper authentication.