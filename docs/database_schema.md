# Database Schema Documentation

This document provides a comprehensive overview of all tables and their columns in the Supabase database for the Option V4.1 Uber Clone project.

## Database Overview

- **Total Tables**: 36 tables
- **Total Views**: 2 views (`available_drivers_view`, `profiles`)
- **Database Type**: PostgreSQL with Supabase
- **Primary Key Type**: UUID for all tables
- **Security**: Row Level Security (RLS) enabled on all tables

## Table Categories

### Core Entity Tables (5)
- `app_users` - Main user accounts
- `drivers` - Driver profiles and vehicle information
- `passengers` - Passenger profiles
- `trips` - Completed trip records
- `trip_requests` - Trip booking requests

### Driver-Related Tables (7)
- `driver_documents` - Document storage and approval
- `driver_excluded_zones` - Driver area preferences
- `driver_offers` - Trip offer responses
- `driver_operational_cities` - Service area configuration
- `driver_performance` - Performance metrics
- `driver_schedules` - Availability schedules
- `driver_wallets` - Financial accounts

### Passenger-Related Tables (4)
- `passenger_wallets` - Passenger wallet system
- `passenger_wallet_transactions` - Wallet transaction history
- `passenger_promo_codes` - Available promotional codes
- `passenger_promo_code_usage` - Promo code usage tracking

### Trip-Related Tables (4)
- `trip_chats` - In-trip messaging
- `trip_location_history` - GPS tracking
- `trip_status_history` - Status change logs
- `trip_stops` - Multiple stop support

### Payment & Financial Tables (3)
- `payment_methods` - User payment methods
- `wallet_transactions` - General wallet transactions
- `withdrawals` - Driver payout requests

### System/Infrastructure Tables (5)
- `notifications` - Push notification system
- `activity_logs` - Audit trail
- `user_devices` - Device management
- `platform_settings` - Configuration
- `ratings` - Trip rating system

### Geographic & Promotional Tables (4)
- `operational_cities` - Service area definitions
- `saved_places` - User location favorites
- `promo_codes` - General promotional codes
- `promo_code_usage` - General promo code usage

### Analytics Tables (1)
- `daily_statistics` - Daily operational statistics

## Detailed Table Structures

### Core Tables

## app_users
**Base user management table**

**Columns:**
- **id**: UUID (Primary key)
- **email**: string (User email address)
- **full_name**: string (User full name)
- **phone**: string (Phone number)
- **photo_url**: string (Profile photo URL)
- **user_type**: string (passenger/driver)
- **status**: string (active/inactive/suspended)
- **created_at**: timestamptz (Creation timestamp)
- **updated_at**: timestamptz (Last update timestamp)
- **user_id**: UUID (Reference to auth.users)

## profiles
**User profiles (compatibility view mapping app_users)**

**Columns:**
- **id**: UUID (Primary key)
- **user_id**: UUID (Reference to auth.users)
- **nome**: string (Portuguese name field)
- **telefone**: string (Portuguese phone field)
- **avatar_url**: string (Profile avatar URL)
- **tipo_usuario**: string (Portuguese user type field)
- **created_at**: timestamptz (Creation timestamp)
- **updated_at**: timestamptz (Last update timestamp)

## passengers
**Passenger-specific data**

**Columns:**
- **id**: UUID (Primary key)
- **user_id**: UUID (Reference to auth.users)
- **consecutive_cancellations**: integer (Track cancellation behavior)
- **total_trips**: integer (Total trips taken)
- **average_rating**: numeric (Average passenger rating)
- **payment_method_id**: UUID (Default payment method)
- **created_at**: timestamptz (Creation timestamp)
- **updated_at**: timestamptz (Last update timestamp)

## drivers
**Driver-specific data with vehicle and financial information**

**Columns:**
- **id**: UUID (Primary key)
- **user_id**: UUID (Reference to auth.users)
- **cnh_number**: string (Driver's license number)
- **cnh_expiry_date**: date (License expiry date)
- **cnh_photo_url**: string (License photo URL)
- **vehicle_brand**: string (Vehicle brand)
- **vehicle_model**: string (Vehicle model)
- **vehicle_year**: integer (Vehicle year)
- **vehicle_color**: string (Vehicle color)
- **vehicle_plate**: string (License plate)
- **vehicle_category**: string (Vehicle category)
- **crlv_photo_url**: string (Vehicle registration photo)
- **approval_status**: string (pending/approved/rejected)
- **approved_by**: UUID (Admin who approved)
- **approved_at**: timestamptz (Approval timestamp)
- **is_online**: boolean (Driver availability status)
- **accepts_pet**: boolean (Pet transport availability)
- **pet_fee**: numeric (Additional fee for pets)
- **accepts_grocery**: boolean (Grocery transport availability)
- **grocery_fee**: numeric (Additional fee for groceries)
- **accepts_condo**: boolean (Condo pickup availability)
- **condo_fee**: numeric (Additional fee for condo)
- **stop_fee**: numeric (Fee per additional stop)
- **ac_policy**: string (Air conditioning policy)
- **custom_price_per_km**: numeric (Custom pricing per km)
- **custom_price_per_minute**: numeric (Custom pricing per minute)
- **bank_account_type**: string (Bank account type)
- **bank_code**: string (Bank code)
- **bank_agency**: string (Bank agency)
- **bank_account**: string (Bank account number)
- **pix_key**: string (PIX key for payments)
- **pix_key_type**: string (PIX key type)
- **consecutive_cancellations**: integer (Track cancellation behavior)
- **total_trips**: integer (Total trips completed)
- **average_rating**: numeric (Average driver rating)
- **current_latitude**: numeric (Current GPS latitude)
- **current_longitude**: numeric (Current GPS longitude)
- **last_location_update**: timestamptz (Last GPS update timestamp)
- **created_at**: timestamptz (Creation timestamp)
- **updated_at**: timestamptz (Last update timestamp)

### Trip Management

## trips
**Core trip data with comprehensive trip information**

**Columns:**
- **id**: string (UUID primary key)
- **trip_code**: string (Human-readable trip identifier)
- **request_id**: string (Reference to trip request)
- **passenger_id**: string (Reference to passenger)
- **driver_id**: string (Reference to driver)
- **status**: string (Trip status)
- **origin_address**: string (Pickup address)
- **origin_latitude**: number (Pickup GPS latitude)
- **origin_longitude**: number (Pickup GPS longitude)
- **origin_neighborhood**: string (Pickup neighborhood)
- **destination_address**: string (Destination address)
- **destination_latitude**: number (Destination GPS latitude)
- **destination_longitude**: number (Destination GPS longitude)
- **destination_neighborhood**: string (Destination neighborhood)
- **vehicle_category**: string (Requested vehicle type)
- **needs_pet**: boolean (Pet transport required)
- **needs_grocery_space**: boolean (Grocery space required)
- **is_condo_destination**: boolean (Destination is condo)
- **is_condo_origin**: boolean (Origin is condo)
- **needs_ac**: boolean (Air conditioning required)
- **number_of_stops**: integer (Additional stops count)
- **route_polyline**: string (Encoded route polyline)
- **estimated_distance_km**: number (Estimated trip distance)
- **estimated_duration_minutes**: integer (Estimated trip duration)
- **driver_to_pickup_distance_km**: number (Distance driver to pickup)
- **driver_to_pickup_duration_minutes**: integer (Time driver to pickup)
- **actual_distance_km**: number (Actual trip distance)
- **actual_duration_minutes**: integer (Actual trip duration)
- **waiting_time_minutes**: integer (Passenger waiting time)
- **driver_distance_traveled_km**: number (Total driver distance)
- **base_fare**: number (Base trip fare)
- **additional_fees**: number (Extra fees applied)
- **surge_multiplier**: number (Surge pricing multiplier)
- **total_fare**: number (Total trip cost)
- **platform_commission**: number (Platform commission)
- **driver_earnings**: number (Driver earnings)
- **cancellation_reason**: string (Reason for cancellation)
- **cancellation_fee**: number (Cancellation fee charged)
- **cancelled_by**: string (Who cancelled the trip)
- **created_at**: string (Trip creation timestamp)
- **driver_assigned_at**: string (Driver assignment timestamp)
- **driver_arrived_at**: string (Driver arrival timestamp)
- **trip_started_at**: string (Trip start timestamp)
- **trip_completed_at**: string (Trip completion timestamp)
- **cancelled_at**: string (Trip cancellation timestamp)
- **payment_status**: string (Payment processing status)
- **payment_id**: string (Payment reference ID)
- **payment_completed_at**: string (Payment completion timestamp)
- **promo_code_id**: string (Applied promo code)
- **discount_applied**: number (Discount amount applied)

## trip_requests
**Trip request records**

**Columns:**
- **id**: string (UUID primary key)
- **passenger_id**: string (Reference to passenger)
- **origin_address**: string (Pickup address)
- **origin_latitude**: number (Pickup GPS latitude)
- **origin_longitude**: number (Pickup GPS longitude)
- **origin_neighborhood**: string (Pickup neighborhood)
- **destination_address**: string (Destination address)
- **destination_latitude**: number (Destination GPS latitude)
- **destination_longitude**: number (Destination GPS longitude)
- **destination_neighborhood**: string (Destination neighborhood)
- **vehicle_category**: string (Requested vehicle type)
- **needs_pet**: boolean (Pet transport required)
- **needs_grocery_space**: boolean (Grocery space required)
- **needs_ac**: boolean (Air conditioning required)
- **is_condo_origin**: boolean (Origin is condo)
- **is_condo_destination**: boolean (Destination is condo)
- **number_of_stops**: integer (Additional stops count)
- **status**: string (Request status)
- **selected_offer_id**: string (Selected driver offer)
- **created_at**: string (Request timestamp)
- **expires_at**: string (Request expiry timestamp)

## trip_chats
**Communication between drivers and passengers**

**Columns:**
- **id**: string (UUID primary key)
- **trip_id**: string (Reference to trip)
- **sender_id**: string (Message sender ID)
- **message**: string (Message content)
- **is_read**: boolean (Message read status)
- **read_at**: string (Message read timestamp)
- **created_at**: string (Message timestamp)

## trip_location_history
**GPS tracking during trips**

**Columns:**
- **id**: string (UUID primary key)
- **trip_id**: string (Reference to trip)
- **latitude**: number (GPS latitude)
- **longitude**: number (GPS longitude)
- **speed_kmh**: number (Speed in km/h)
- **heading**: number (Direction heading)
- **accuracy_meters**: number (GPS accuracy)
- **recorded_at**: string (Location timestamp)

## trip_status_history
**Status change history for trips**

**Columns:**
- **id**: string (UUID primary key)
- **trip_id**: string (Reference to trip)
- **old_status**: string (Previous status)
- **new_status**: string (New status)
- **changed_by**: string (Who changed the status)
- **reason**: string (Reason for change)
- **metadata**: unknown (Additional change data)
- **created_at**: string (Change timestamp)

## trip_stops
**Multiple stops within a trip**

**Columns:**
- **id**: string (UUID primary key)
- **trip_id**: string (Reference to trip)
- **stop_order**: integer (Stop sequence number)
- **address**: string (Stop address)
- **latitude**: number (Stop GPS latitude)
- **longitude**: number (Stop GPS longitude)
- **arrived_at**: string (Arrival timestamp)
- **departed_at**: string (Departure timestamp)
- **created_at**: string (Stop creation timestamp)

### Driver System

## driver_documents
**Driver document verification**

**Columns:**
- **id**: string (UUID primary key)
- **driver_id**: string (Reference to driver)
- **document_type**: string (Type of document)
- **file_url**: string (Document file URL)
- **file_size**: integer (File size in bytes)
- **mime_type**: string (File MIME type)
- **expiry_date**: string (Document expiry date)
- **status**: string (Verification status)
- **rejection_reason**: string (Reason if rejected)
- **reviewed_by**: string (Admin who reviewed)
- **reviewed_at**: string (Review timestamp)
- **is_current**: boolean (Current valid document)
- **created_at**: string (Upload timestamp)

## driver_offers
**Driver offer management**

**Columns:**
- **id**: string (UUID primary key)
- **request_id**: string (Reference to trip request)
- **driver_id**: string (Reference to driver)
- **driver_distance_km**: number (Driver distance to pickup)
- **driver_eta_minutes**: integer (Estimated time to pickup)
- **base_fare**: number (Base fare offered)
- **additional_fees**: number (Additional fees)
- **total_fare**: number (Total fare offered)
- **distance_component**: number (Distance-based pricing)
- **time_component**: number (Time-based pricing)
- **is_available**: boolean (Offer availability)
- **was_selected**: boolean (Offer was selected)
- **created_at**: string (Offer timestamp)

## driver_operational_cities
**Cities where drivers operate**

**Columns:**
- **id**: string (UUID primary key)
- **driver_id**: string (Reference to driver)
- **city_id**: string (Reference to operational city)
- **is_primary**: boolean (Primary operational city)
- **created_at**: string (Registration timestamp)

## driver_performance
**Driver performance metrics**

**Columns:**
- **driver_id**: string (Reference to driver)
- **driver_name**: string (Driver name)
- **average_rating**: number (Overall average rating)
- **total_trips**: integer (Total trips completed)
- **consecutive_cancellations**: integer (Current cancellation streak)
- **completed_trips_30d**: integer (Trips completed in last 30 days)
- **cancelled_trips_30d**: integer (Trips cancelled in last 30 days)
- **rating_30d**: number (Average rating last 30 days)
- **earnings_30d**: number (Earnings in last 30 days)

## driver_schedules
**Driver availability schedules**

**Columns:**
- **id**: string (UUID primary key)
- **driver_id**: string (Reference to driver)
- **day_of_week**: integer (Day of week 0-6)
- **start_time**: string (Schedule start time)
- **end_time**: string (Schedule end time)
- **is_active**: boolean (Schedule active status)
- **created_at**: string (Schedule creation timestamp)

## driver_excluded_zones
**Areas where drivers don't operate**

**Columns:**
- **id**: string (UUID primary key)
- **driver_id**: string (Reference to driver)
- **neighborhood_name**: string (Excluded neighborhood)
- **city**: string (City name)
- **state**: string (State name)
- **created_at**: string (Exclusion timestamp)

## driver_wallets
**Driver earnings and payments**

**Columns:**
- **id**: string (UUID primary key)
- **driver_id**: string (Reference to driver)
- **available_balance**: number (Available balance)
- **pending_balance**: number (Pending balance)
- **total_earned**: number (Total lifetime earnings)
- **total_withdrawn**: number (Total withdrawals)
- **created_at**: string (Wallet creation timestamp)
- **updated_at**: string (Last update timestamp)

### Passenger System

## passenger_wallets
**Passenger wallet system**

**Columns:**
- **id**: string (UUID primary key)
- **passenger_id**: string (Reference to passenger)
- **user_id**: string (Reference to auth.users)
- **available_balance**: number (Available balance)
- **pending_balance**: number (Pending balance)
- **total_spent**: number (Total money spent)
- **total_cashback**: number (Total cashback earned)
- **created_at**: string (Wallet creation timestamp)
- **updated_at**: string (Last update timestamp)

## passenger_wallet_transactions
**Passenger wallet transaction history**

**Columns:**
- **id**: string (UUID primary key)
- **wallet_id**: string (Reference to passenger wallet)
- **passenger_id**: string (Reference to passenger)
- **type**: string (Transaction type)
- **amount**: number (Transaction amount)
- **description**: string (Transaction description)
- **trip_id**: string (Related trip ID)
- **payment_method_id**: string (Payment method used)
- **asaas_payment_id**: string (Asaas payment reference)
- **status**: string (Transaction status)
- **metadata**: unknown (Additional transaction data)
- **created_at**: string (Transaction timestamp)
- **processed_at**: string (Processing timestamp)

## passenger_promo_codes
**Available promotional codes**

**Columns:**
- **id**: string (UUID primary key)
- **code**: string (Promo code string)
- **type**: string (percentage/fixed/free_ride)
- **value**: number (Discount value)
- **min_amount**: number (Minimum trip amount)
- **max_discount**: number (Maximum discount limit)
- **is_active**: boolean (Code active status)
- **is_first_ride_only**: boolean (First ride restriction)
- **usage_limit**: integer (Maximum uses)
- **usage_count**: integer (Current usage count)
- **valid_from**: string (Valid from timestamp)
- **valid_until**: string (Valid until timestamp)
- **created_at**: string (Creation timestamp)

## passenger_promo_code_usage
**Promo code usage tracking**

**Columns:**
- **id**: string (UUID primary key)
- **user_id**: string (Reference to auth.users)
- **promo_code_id**: string (Reference to promo code)
- **trip_id**: string (Reference to trip)
- **original_amount**: number (Original trip amount)
- **discount_amount**: number (Discount applied)
- **final_amount**: number (Final amount paid)
- **used_at**: string (Usage timestamp)

### Payment System

## payment_methods
**User payment methods**

**Columns:**
- **id**: string (UUID primary key)
- **user_id**: string (Reference to auth.users)
- **type**: string (wallet/credit_card/debit_card/pix)
- **is_default**: boolean (Default payment method)
- **is_active**: boolean (Active status)
- **card_data**: unknown (Card information JSON)
- **pix_data**: unknown (PIX information JSON)
- **asaas_customer_id**: string (Asaas customer reference)
- **created_at**: string (Creation timestamp)
- **updated_at**: string (Last update timestamp)

## wallet_transactions
**General wallet transactions**

**Columns:**
- **id**: string (UUID primary key)
- **wallet_id**: string (Reference to wallet)
- **type**: string (Transaction type)
- **amount**: number (Transaction amount)
- **description**: string (Transaction description)
- **reference_type**: string (Reference entity type)
- **reference_id**: string (Reference entity ID)
- **balance_after**: number (Balance after transaction)
- **status**: string (Transaction status)
- **created_at**: string (Transaction timestamp)

## withdrawals
**Driver withdrawal requests**

**Columns:**
- **id**: string (UUID primary key)
- **driver_id**: string (Reference to driver)
- **wallet_id**: string (Reference to driver wallet)
- **amount**: number (Withdrawal amount)
- **withdrawal_method**: string (Withdrawal method)
- **bank_account_info**: unknown (Bank account details)
- **asaas_transfer_id**: string (Asaas transfer reference)
- **status**: string (Withdrawal status)
- **failure_reason**: string (Failure reason if failed)
- **requested_at**: string (Request timestamp)
- **processed_at**: string (Processing timestamp)
- **completed_at**: string (Completion timestamp)

### Geographic & Operational

## operational_cities
**Cities where the service operates**

**Columns:**
- **id**: string (UUID primary key)
- **name**: string (City name)
- **state**: string (State name)
- **country**: string (Country name)
- **is_active**: boolean (Service active in city)
- **min_fare**: number (Minimum fare for city)
- **launch_date**: string (Service launch date)
- **polygon_coordinates**: unknown (City boundary coordinates)
- **created_at**: string (Creation timestamp)

## saved_places
**User saved locations**

**Columns:**
- **id**: string (UUID primary key)
- **passenger_id**: string (Reference to passenger)
- **label**: string (Place label like "Home", "Work")
- **address**: string (Full address)
- **latitude**: number (GPS latitude)
- **longitude**: number (GPS longitude)
- **created_at**: string (Creation timestamp)
- **updated_at**: string (Last update timestamp)

### Promotional System

## promo_codes
**General promotional codes**

**Columns:**
- **id**: string (UUID primary key)
- **code**: string (Promo code string)
- **description**: string (Code description)
- **discount_type**: string (Discount type)
- **discount_value**: number (Discount value)
- **max_discount**: number (Maximum discount)
- **min_trip_value**: number (Minimum trip value)
- **max_uses_per_user**: integer (Max uses per user)
- **valid_from**: string (Valid from timestamp)
- **valid_until**: string (Valid until timestamp)
- **usage_limit**: integer (Total usage limit)
- **used_count**: integer (Current usage count)
- **target_cities**: array (Target cities)
- **target_categories**: array (Target vehicle categories)
- **is_first_trip_only**: boolean (First trip restriction)
- **is_active**: boolean (Active status)
- **created_by**: string (Creator ID)
- **created_at**: string (Creation timestamp)

## promo_code_usage
**General promo code usage**

**Columns:**
- **id**: string (UUID primary key)
- **promo_code_id**: string (Reference to promo code)
- **passenger_id**: string (Reference to passenger)
- **trip_id**: string (Reference to trip)
- **discount_applied**: number (Discount amount applied)
- **used_at**: string (Usage timestamp)

### System Management

## notifications
**Push notifications system**

**Columns:**
- **id**: string (UUID primary key)
- **user_id**: string (Reference to auth.users)
- **title**: string (Notification title)
- **body**: string (Notification body)
- **type**: string (Notification type)
- **data**: unknown (Additional notification data)
- **priority**: string (Notification priority)
- **is_read**: boolean (Read status)
- **sent_at**: string (Send timestamp)
- **read_at**: string (Read timestamp)

## user_devices
**User device registration for notifications**

**Columns:**
- **id**: string (UUID primary key)
- **user_id**: string (Reference to auth.users)
- **device_token**: string (FCM/APNS device token)
- **platform**: string (android/ios)
- **device_model**: string (Device model)
- **app_version**: string (App version)
- **os_version**: string (OS version)
- **is_active**: boolean (Device active status)
- **last_used_at**: string (Last usage timestamp)
- **created_at**: string (Registration timestamp)
- **updated_at**: string (Last update timestamp)

## activity_logs
**System activity logging**

**Columns:**
- **id**: string (UUID primary key)
- **user_id**: string (Reference to auth.users)
- **action**: string (Action performed)
- **entity_type**: string (Entity affected)
- **entity_id**: string (Entity ID)
- **old_values**: unknown (Previous values)
- **new_values**: unknown (New values)
- **metadata**: unknown (Additional activity data)
- **ip_address**: string (User IP address)
- **user_agent**: string (User agent string)
- **created_at**: string (Activity timestamp)

## ratings
**Trip ratings and reviews**

**Columns:**
- **id**: string (UUID primary key)
- **trip_id**: string (Reference to trip)
- **passenger_rating**: integer (Passenger rating 1-5)
- **passenger_rating_tags**: array (Passenger rating tags)
- **passenger_rating_comment**: string (Passenger comment)
- **passenger_rated_at**: string (Passenger rating timestamp)
- **driver_rating**: integer (Driver rating 1-5)
- **driver_rating_tags**: array (Driver rating tags)
- **driver_rating_comment**: string (Driver comment)
- **driver_rated_at**: string (Driver rating timestamp)
- **created_at**: string (Creation timestamp)
- **updated_at**: string (Last update timestamp)

## platform_settings
**System configuration settings**

**Columns:**
- **id**: string (UUID primary key)
- **category**: string (Setting category)
- **base_price_per_km**: number (Base price per kilometer)
- **base_price_per_minute**: number (Base price per minute)
- **platform_commission_percent**: number (Platform commission %)
- **min_fare**: number (Minimum fare)
- **min_cancellation_fee**: number (Minimum cancellation fee)
- **cancellation_fee_percent**: number (Cancellation fee %)
- **no_show_wait_minutes**: integer (No-show wait time)
- **driver_acceptance_timeout_seconds**: integer (Driver acceptance timeout)
- **search_radius_km**: integer (Driver search radius)
- **created_at**: string (Creation timestamp)
- **updated_at**: string (Last update timestamp)

### Analytics & Reporting

## daily_statistics
**Daily operational statistics**

**Columns:**
- **date**: string (Statistics date)
- **total_trips**: integer (Total trips)
- **completed_trips**: integer (Completed trips)
- **cancelled_trips**: integer (Cancelled trips)
- **no_show_trips**: integer (No-show trips)
- **avg_fare**: number (Average fare)
- **total_revenue**: number (Total revenue)
- **total_commission**: number (Total commission)
- **unique_passengers**: integer (Unique passengers)
- **unique_drivers**: integer (Unique drivers)

### Views

## available_drivers_view
**View for available drivers**

**Columns:**
- **driver_id**: string (Driver ID)
- **user_id**: string (User ID)
- **full_name**: string (Driver name)
- **photo_url**: string (Driver photo)
- **phone**: string (Driver phone)
- **vehicle_brand**: string (Vehicle brand)
- **vehicle_model**: string (Vehicle model)
- **vehicle_year**: integer (Vehicle year)
- **vehicle_color**: string (Vehicle color)
- **vehicle_category**: string (Vehicle category)
- **average_rating**: number (Average rating)
- **total_trips**: integer (Total trips)
- **is_online**: boolean (Online status)
- **current_latitude**: number (Current latitude)
- **current_longitude**: number (Current longitude)
- **last_location_update**: string (Last location update)
- **accepts_pet**: boolean (Accepts pets)
- **accepts_grocery**: boolean (Accepts groceries)
- **accepts_condo**: boolean (Accepts condo pickups)
- **ac_policy**: string (AC policy)
- **custom_price_per_km**: number (Custom price per km)
- **custom_price_per_minute**: number (Custom price per minute)
- **pet_fee**: number (Pet fee)
- **grocery_fee**: number (Grocery fee)
- **condo_fee**: number (Condo fee)
- **stop_fee**: number (Stop fee)

## Database Relationships

The schema follows a hierarchical structure:
- **auth.users** (Supabase auth) → **app_users** → **passengers**/**drivers**
- **trips** connects passengers and drivers with comprehensive trip tracking
- **wallets** and **payment_methods** support financial transactions
- **notifications** and **user_devices** enable real-time communication
- **activity_logs** provide comprehensive audit trails
- **ratings** provide feedback system for quality control
- **promo_codes** and **passenger_promo_codes** enable marketing campaigns

## Security

All tables implement Row Level Security (RLS) with appropriate policies to ensure:
- Users can only access their own data
- Drivers can only see relevant trip information  
- System operations are properly authenticated
- Sensitive financial data is protected
- Audit trails are maintained for compliance

## Recent Schema Changes

Based on the `passenger_wallet_migration.sql` file, the passenger wallet system was recently implemented with:
- Multi-balance system (available/pending)
- Cashback tracking and management
- Payment method integration with Asaas payment processor
- Promotional codes with various types (percentage, fixed, free_ride)
- Comprehensive indexing for performance optimization
- Automatic wallet creation triggers
- Row Level Security policies for data protection

---

*Generated on: 2025-08-21*
*Database: Supabase PostgreSQL*
*Project: Option V4.1 Uber Clone*
*Total Tables: 36*
*Total Views: 2*
*Last Updated: 2025-08-21*