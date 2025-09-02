# Supabase Database Schema - OPTION App

**Updated:** 2025-08-20  
**Database:** https://qlbwacmavngtonauxnte.supabase.co  
**Status:** 🟢 Complete production database with 30+ tables

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

### 2. `passengers` 
**Purpose:** Passenger-specific data and preferences

### 3. `drivers`
**Purpose:** Driver-specific data and status

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

## Database Status

🟢 **Production Ready:** This is a fully implemented ride-sharing database with:
- Complete user management (passengers + drivers)
- Full trip lifecycle (request → assignment → completion)
- Financial transactions and earnings
- Real-time tracking and communication
- Analytics and reporting
- Geographic operations management

**Note:** Row Level Security (RLS) is enabled on all tables, preventing direct access without proper authentication.