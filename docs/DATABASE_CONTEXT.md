# Database Context - OPTION App

## 🚀 Production Database Status

**CRITICAL UPDATE:** The database is fully implemented with 30+ tables for a complete ride-sharing platform!

### ✅ Fully Implemented Database

The OPTION app has a **production-ready database** with comprehensive tables for:

- **User Management:** `app_users`, `passengers`, `drivers`, `profiles`
- **Trip System:** `trips`, `trip_requests`, `trip_status_history`, `trip_chats`
- **Driver Operations:** `driver_offers`, `driver_schedules`, `driver_documents`, `driver_wallets`
- **Financial:** `wallet_transactions`, `withdrawals`, `promo_codes`, `promo_code_usage`
- **Geography:** `operational_cities`, `saved_places`, `driver_operational_cities`
- **Analytics:** `activity_logs`, `daily_statistics`, `ratings`, `notifications`

## Current App vs Database Status

### ⚠️ App Development Status
The **Flutter app is only using basic functionality** while the database supports a full ride-sharing platform:

**Currently Implemented in App:**
- User registration (creates `app_users` record)
- User type selection (passenger/driver)
- Basic authentication flow

**Available but Not Yet Used:**
- Complete trip booking system
- Driver-passenger matching
- Real-time trip tracking
- In-app payments and earnings
- Chat system
- Rating and review system
- Multi-city operations
- Advanced driver features

### 🔧 Model Synchronization Issues

#### ✅ Models That Match Database
1. **AppUser** (`lib/models/supabase/app_user.dart`) → `app_users` table ✅
2. **Trip** (`lib/models/supabase/trip.dart`) → `trips` table ✅  
3. **TripRequest** → `trip_requests` table ✅
4. **PromoCode** → `promo_codes` table ✅

#### ⚠️ Models That Need Updates
1. **User** (`lib/models/user.dart`) - Legacy model with fields not in database
2. **Driver/Passenger** models - Need to sync with actual table structures

## Database Access Status

### 🔒 Row Level Security (RLS)
All tables have RLS enabled, requiring:
- Proper authentication for data access
- User-specific data filtering
- Service role key for admin operations

### 🛠️ Available RPC Functions
- `find_available_drivers` - Driver matching algorithm
- `process_trip_payment` - Payment processing
- `calculate_cancellation_fee` - Fee calculation
- `cleanup_expired_requests` - Maintenance tasks

## Development Roadmap

### Phase 1: Current State (✅ Completed)
- User registration and authentication
- Basic app navigation
- User type selection

### Phase 2: Trip Booking (🚧 Ready to Implement)
- Passenger trip request creation
- Driver availability and matching
- Trip acceptance flow

### Phase 3: Trip Execution (🚧 Ready to Implement)  
- Real-time location tracking
- Trip status updates
- Driver-passenger communication

### Phase 4: Advanced Features (🚧 Ready to Implement)
- Payment processing
- Rating system
- Driver earnings management
- Analytics and reporting

## Service Layer Strategy

### Current Services (Basic)
- `UserService` - Creates/manages `app_users`
- `AuthService` - Handles Supabase authentication

### Services to Implement
- `TripService` - Handle complete trip lifecycle
- `DriverService` - Driver-specific operations
- `PassengerService` - Passenger-specific operations
- `PaymentService` - Financial transactions
- `NotificationService` - Push notifications

## Data Access Patterns

### For Current Development:
```dart
// Use AppUser model for user operations
final appUser = AppUser.fromJson(userData);

// Access user-specific data with RLS
final userTrips = await supabase
  .from('trips')
  .select()
  .eq('passenger_id', userId);
```

### For Future Features:
```dart
// Trip request example
final tripRequest = TripRequest(
  passengerId: user.id,
  originAddress: pickupLocation,
  destinationAddress: dropoffLocation,
);

// Driver matching
final availableDrivers = await supabase
  .rpc('find_available_drivers', {
    'passenger_lat': lat,
    'passenger_lng': lng,
  });
```

## Critical Business Rules

### 1. User Flow
```
auth.users → app_users → passengers/drivers
```

### 2. Trip Lifecycle
```
trip_requests → driver_offers → trips → trip_status_history → ratings
```

### 3. Financial Flow
```
trips → wallet_transactions → driver_wallets → withdrawals
```

## Development Guidelines

### ✅ Best Practices
1. **Use existing models** that match database tables
2. **Leverage RPC functions** for complex operations
3. **Follow RLS patterns** for data security
4. **Implement incremental features** using existing database structure

### ❌ Avoid
1. Creating new tables - the schema is complete
2. Bypassing RLS security measures
3. Using legacy User model for new features
4. Ignoring existing database relationships

## Next Steps for Development

1. **Implement Trip Request System** using existing `trip_requests` table
2. **Add Driver Matching** using `find_available_drivers` RPC
3. **Build Trip Tracking** using `trip_location_history` table
4. **Integrate Payments** using existing financial tables
5. **Add Real-time Features** using existing chat and notification tables

**The database is ready - the app just needs to catch up! 🚀**