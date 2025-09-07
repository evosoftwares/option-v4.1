# Supabase Schema Documentation

This document provides a comprehensive overview of the database schema for the OPTION urban mobility application. It includes detailed information about tables, views, functions, triggers, and Row Level Security (RLS) policies.

## 🔍 Connection Information

### Project Details
- **Project URL**: `https://qlbwacmavngtonauxnte.supabase.co`
- **Project ID**: `qlbwacmavngtonauxnte`
- **Region**: Unknown (accessed via URL)

### Authentication Keys
- **Service Role Key**: Available in project configuration
- **Anonymous Key**: Available in project configuration

## 📊 Database Schema Overview

The database consists of 45+ tables, 10+ views, and numerous functions that support the ride-sharing platform functionality. The schema is organized around core entities like users, drivers, passengers, trips, and payments.

## 🗃️ Complete Table Schema

### activity_logs
Audit trail of user activities and system events.
- id (uuid) **PRIMARY KEY** - Unique identifier
- user_id (uuid) **FOREIGN KEY** -> app_users.id - User who performed the action
- action (text) NOT NULL - Type of action performed
- entity_type (text) - Type of entity affected
- entity_id (uuid) - ID of the affected entity
- old_values (jsonb) - Previous values before change
- new_values (jsonb) - New values after change
- metadata (jsonb) - Additional information about the action
- ip_address (inet) - IP address of the requester
- user_agent (text) - User agent string
- created_at (timestamp with time zone) DEFAULT now() - When the log was created

### app_users
Core user information for all users of the platform.
- id (uuid) **PRIMARY KEY** - User ID (matches auth.users.id)
- email (text) NOT NULL UNIQUE - User's email address
- full_name (text) NOT NULL - User's full name
- phone (text) NOT NULL DEFAULT 'pending' - User's phone number
- photo_url (text) - URL to user's profile photo
- user_type (text) NOT NULL - Type of user (passenger/driver/admin)
- status (text) NOT NULL DEFAULT 'active' - Account status
- created_at (timestamp with time zone) DEFAULT now() - Account creation timestamp
- updated_at (timestamp with time zone) DEFAULT now() - Last update timestamp
- fcm_token (text) - Firebase Cloud Messaging token for push notifications
- device_id (text) - Device identifier
- device_platform (text) - Platform (ios/android/web)
- last_active_at (timestamp with time zone) DEFAULT now() - Last activity timestamp
- profile_complete (boolean) NOT NULL DEFAULT false - Whether registration is complete

**Constraints:**
- user_type CHECK constraint: Must be one of passenger, driver, admin
- status CHECK constraint: Must be one of active, suspended, pending, rejected
- device_platform CHECK constraint: Must be one of ios, android, web

**RLS Policies:**
- "Enable insert for authenticated users only" (FOR INSERT WITH CHECK auth.uid() = id)
- "Users can view own profile" (FOR SELECT USING auth.uid() = id)
- "Users can update own profile" (FOR UPDATE USING auth.uid() = id)

### asaas_webhook_events
Tracks processed Asaas payment webhook events to prevent duplicate processing.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Unique identifier
- asaas_event_id (text) NOT NULL UNIQUE - Unique event ID from Asaas
- event_type (text) NOT NULL - Type of webhook event
- payment_id (text) - Asaas payment ID
- payload (jsonb) NOT NULL - Complete webhook payload
- processed_at (timestamp with time zone) DEFAULT now() - When event was processed
- created_at (timestamp with time zone) DEFAULT now() - When record was created

### backup_app_users_migration
Backup table for app_users during migration processes.
- id (uuid) - User ID
- email (text) - User's email
- full_name (text) - User's full name
- phone (text) - User's phone
- photo_url (text) - Photo URL
- user_type (text) - User type
- status (text) - Account status
- created_at (timestamp with time zone) - Creation timestamp
- updated_at (timestamp with time zone) - Update timestamp
- user_id (uuid) - User ID reference

### backup_conflict_409_removal
Backup table for conflict resolution during data migration.
- source_table (text) - Source table name
- backup_timestamp (timestamp with time zone) - Backup creation time
- id (uuid) - Record ID
- email (text) - User email
- full_name (text) - User full name
- phone (text) - User phone
- photo_url (text) - Photo URL
- user_type (text) - User type
- status (text) - Account status
- created_at (timestamp with time zone) - Creation timestamp
- updated_at (timestamp with time zone) - Update timestamp

### backup_drivers_migration
Backup table for drivers during migration processes.
- id (uuid) - Driver ID
- user_id (uuid) - User ID reference
- cnh_number (text) - Driver's license number
- cnh_expiry_date (date) - License expiration date
- cnh_photo_url (text) - License photo URL
- vehicle_brand (text) - Vehicle brand
- vehicle_model (text) - Vehicle model
- vehicle_year (integer) - Vehicle year
- vehicle_color (text) - Vehicle color
- vehicle_plate (text) - Vehicle plate
- vehicle_category (text) - Vehicle category
- crlv_photo_url (text) - Vehicle registration photo URL
- approval_status (text) - Driver approval status
- approved_by (uuid) - ID of approver
- approved_at (timestamp with time zone) - Approval timestamp
- is_online (boolean) - Online status
- accepts_pet (boolean) - Accepts pets
- pet_fee (numeric(10,2)) - Pet fee
- accepts_grocery (boolean) - Accepts grocery trips
- grocery_fee (numeric(10,2)) - Grocery fee
- accepts_condo (boolean) - Accepts condo trips
- condo_fee (numeric(10,2)) - Condo fee
- stop_fee (numeric(10,2)) - Fee per stop
- ac_policy (text) - Air conditioning policy
- custom_price_per_km (numeric(10,2)) - Custom price per km
- custom_price_per_minute (numeric(10,2)) - Custom price per minute
- bank_account_type (text) - Bank account type
- bank_code (text) - Bank code
- bank_agency (text) - Bank agency
- bank_account (text) - Bank account number
- pix_key (text) - PIX key
- pix_key_type (text) - PIX key type
- consecutive_cancellations (integer) - Number of consecutive cancellations
- total_trips (integer) - Total trips completed
- average_rating (numeric(3,2)) - Average rating
- current_latitude (numeric(10,8)) - Current latitude
- current_longitude (numeric(11,8)) - Current longitude
- last_location_update (timestamp with time zone) - Last location update
- created_at (timestamp with time zone) - Creation timestamp
- updated_at (timestamp with time zone) - Update timestamp

### backup_passengers_migration
Backup table for passengers during migration processes.
- id (uuid) - Passenger ID
- user_id (uuid) - User ID reference
- consecutive_cancellations (integer) - Consecutive cancellations count
- total_trips (integer) - Total trips taken
- average_rating (numeric(3,2)) - Average rating
- payment_method_id (text) - Payment method ID
- created_at (timestamp with time zone) - Creation timestamp
- updated_at (timestamp with time zone) - Update timestamp

### corrupted_users_backup
Backup of user data before corruption corrections.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Backup record ID
- original_user_id (uuid) NOT NULL - Original user ID
- original_full_name (text) - Original full name
- original_phone (text) - Original phone
- original_email (text) - Original email
- correction_timestamp (timestamp with time zone) DEFAULT now() - When correction was made
- correction_reason (text) - Reason for correction
- restored (boolean) DEFAULT false - Whether record was restored
- restored_at (timestamp with time zone) - When record was restored

### driver_approval_audit
Audit trail of driver approval status changes.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Audit record ID
- driver_id (uuid) NOT NULL FOREIGN KEY -> drivers.id - Driver ID
- old_status (text) - Previous approval status
- new_status (text) - New approval status
- reason (text) - Reason for status change
- approved_documents (jsonb) - Documents used for approval
- created_at (timestamp with time zone) DEFAULT now() - When audit record was created

### driver_documents
Storage of driver verification documents.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Document ID
- driver_id (uuid) NOT NULL FOREIGN KEY -> drivers.id - Driver ID
- document_type (text) NOT NULL - Type of document
- file_url (text) NOT NULL - URL to document file
- file_size (integer) - File size in bytes
- mime_type (text) - MIME type of file
- expiry_date (date) - Document expiration date
- rejection_reason (text) - Reason for document rejection
- reviewed_by (uuid) FOREIGN KEY -> app_users.id - ID of reviewer
- reviewed_at (timestamp with time zone) - Review timestamp
- is_current (boolean) DEFAULT true - Whether document is current
- created_at (timestamp with time zone) DEFAULT now() - Creation timestamp
- updated_at (timestamp with time zone) DEFAULT now() - Update timestamp
- status (approval_status_enum) NOT NULL DEFAULT 'pending' - Document status

**Constraints:**
- document_type CHECK constraint: Must be one of CNH_FRONT, CNH_BACK, CRLV, VEHICLE_FRONT, VEHICLE_BACK, VEHICLE_LEFT, VEHICLE_RIGHT, VEHICLE_INTERIOR

### driver_status
Tracks driver online/offline intentions.
- driver_id (uuid) NOT NULL PRIMARY KEY FOREIGN KEY -> drivers.id - Driver ID
- online_intent (boolean) NOT NULL DEFAULT false - Whether driver intends to be online
- updated_at (timestamp with time zone) NOT NULL DEFAULT now() - Last update timestamp

### driver_excluded_zones
Zones where drivers have chosen not to operate.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Exclusion ID
- driver_id (uuid) NOT NULL FOREIGN KEY -> drivers.id - Driver ID
- neighborhood_name (text) NOT NULL - Name of excluded neighborhood
- city (text) NOT NULL - City name
- state (text) NOT NULL - State name
- created_at (timestamp with time zone) DEFAULT now() - Creation timestamp

### driver_offers
Trip offers made by drivers to passengers.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Offer ID
- request_id (uuid) NOT NULL FOREIGN KEY -> trip_requests.id - Trip request ID
- driver_id (uuid) NOT NULL FOREIGN KEY -> drivers.id - Driver ID
- driver_distance_km (numeric(10,2)) NOT NULL - Distance from driver to passenger
- driver_eta_minutes (integer) NOT NULL - Estimated time of arrival
- base_fare (numeric(10,2)) NOT NULL - Base fare estimate
- additional_fees (numeric(10,2)) NOT NULL - Additional fees
- total_fare (numeric(10,2)) NOT NULL - Total fare
- distance_component (numeric(10,2)) - Distance-based component
- time_component (numeric(10,2)) - Time-based component
- is_available (boolean) DEFAULT true - Whether offer is still available
- was_selected (boolean) DEFAULT false - Whether offer was selected
- created_at (timestamp with time zone) DEFAULT now() - Creation timestamp

**Unique Constraints:**
- request_id, driver_id combination must be unique

### driver_operation_zones
Custom operation zones defined by drivers with price multipliers.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Zone ID
- driver_id (uuid) NOT NULL FOREIGN KEY -> drivers.id - Driver ID
- zone_name (text) NOT NULL - Name of the zone
- polygon_coordinates (jsonb) NOT NULL - Zone boundary coordinates
- price_multiplier (numeric(4,2)) NOT NULL DEFAULT 1.00 - Price multiplier
- is_active (boolean) NOT NULL DEFAULT true - Whether zone is active
- created_at (timestamp with time zone) DEFAULT now() - Creation timestamp
- updated_at (timestamp with time zone) DEFAULT now() - Update timestamp

**Constraints:**
- price_multiplier CHECK constraint: Must be between 0.1 and 10.0

### driver_operational_cities
Cities where drivers operate.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Record ID
- driver_id (uuid) NOT NULL FOREIGN KEY -> drivers.id - Driver ID
- city_id (uuid) NOT NULL FOREIGN KEY -> operational_cities.id - City ID
- is_primary (boolean) DEFAULT false - Whether this is primary city
- created_at (timestamp with time zone) DEFAULT now() - Creation timestamp

**Unique Constraints:**
- driver_id, city_id combination must be unique

### driver_schedule_overrides
Temporary exceptions to normal working hours.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Override ID
- driver_id (uuid) NOT NULL FOREIGN KEY -> drivers.id - Driver ID
- override_start (timestamp with time zone) NOT NULL - Start of override period
- override_end (timestamp with time zone) NOT NULL - End of override period
- is_active (boolean) NOT NULL DEFAULT true - Whether override is active
- reason (text) - Reason for override
- created_by (uuid) FOREIGN KEY -> drivers.id - Creator ID
- created_at (timestamp with time zone) NOT NULL DEFAULT now() - Creation timestamp
- updated_at (timestamp with time zone) NOT NULL DEFAULT now() - Update timestamp

**Constraints:**
- override_future_start CHECK constraint: Override must start in the future
- override_max_duration CHECK constraint: Override must be ≤ 24 hours
- override_valid_period CHECK constraint: End must be after start

### driver_schedules
Regular working schedules for drivers.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Schedule ID
- driver_id (uuid) NOT NULL FOREIGN KEY -> drivers.id - Driver ID
- day_of_week (integer) NOT NULL - Day of week (0-6, Sunday-Saturday)
- start_time (time without time zone) NOT NULL - Start time
- end_time (time without time zone) NOT NULL - End time
- is_active (boolean) DEFAULT true - Whether schedule is active
- created_at (timestamp with time zone) DEFAULT now() - Creation timestamp

**Constraints:**
- day_of_week CHECK constraint: Must be between 0 and 6
- driver_id, day_of_week, start_time combination must be unique

### driver_wallets
Financial records for drivers.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Wallet ID
- driver_id (uuid) NOT NULL UNIQUE FOREIGN KEY -> drivers.id - Driver ID
- available_balance (numeric(10,2)) DEFAULT 0 - Available balance
- pending_balance (numeric(10,2)) DEFAULT 0 - Pending balance
- total_earned (numeric(10,2)) DEFAULT 0 - Total earnings
- total_withdrawn (numeric(10,2)) DEFAULT 0 - Total withdrawals
- created_at (timestamp with time zone) DEFAULT now() - Creation timestamp
- updated_at (timestamp with time zone) DEFAULT now() - Update timestamp

### drivers
Core driver information and vehicle details.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Driver ID
- user_id (uuid) NOT NULL UNIQUE FOREIGN KEY -> app_users.id - User ID
- vehicle_brand (text) NOT NULL - Vehicle brand
- vehicle_model (text) NOT NULL - Vehicle model
- vehicle_year (integer) NOT NULL - Vehicle year
- vehicle_color (text) NOT NULL - Vehicle color
- vehicle_plate (text) NOT NULL UNIQUE - Vehicle plate number
- vehicle_category (text) NOT NULL FOREIGN KEY -> platform_settings.category - Vehicle category
- approved_by (uuid) FOREIGN KEY -> app_users.id - ID of approver
- approved_at (timestamp with time zone) - Approval timestamp
- is_online (boolean) DEFAULT false - Whether driver is online
- accepts_pet (boolean) DEFAULT false - Whether driver accepts pets
- pet_fee (numeric(10,2)) DEFAULT 0 - Fee for pet transportation
- accepts_grocery (boolean) DEFAULT false - Whether driver accepts grocery trips
- grocery_fee (numeric(10,2)) DEFAULT 0 - Fee for grocery trips
- accepts_condo (boolean) DEFAULT false - Whether driver accepts condo trips
- condo_fee (numeric(10,2)) DEFAULT 0 - Fee for condo trips
- stop_fee (numeric(10,2)) DEFAULT 0 - Fee per additional stop
- ac_policy (text) DEFAULT 'on_request' - Air conditioning policy
- custom_price_per_km (numeric(10,2)) - Custom price per kilometer
- custom_price_per_minute (numeric(10,2)) - Custom price per minute
- bank_account_type (text) - Bank account type
- bank_code (text) - Bank code
- bank_agency (text) - Bank agency
- bank_account (text) - Bank account number
- pix_key (text) - PIX key for payments
- pix_key_type (text) - Type of PIX key
- consecutive_cancellations (integer) DEFAULT 0 - Consecutive cancellations
- total_trips (integer) DEFAULT 0 - Total trips completed
- average_rating (numeric(3,2)) - Average passenger rating
- current_latitude (numeric(10,8)) - Current latitude
- current_longitude (numeric(11,8)) - Current longitude
- last_location_update (timestamp with time zone) - Last location update
- created_at (timestamp with time zone) DEFAULT now() - Creation timestamp
- updated_at (timestamp with time zone) DEFAULT now() - Update timestamp
- fcm_token (text) - Firebase Cloud Messaging token
- device_platform (text) - Device platform
- last_notification_at (timestamp with time zone) - Last notification timestamp
- approval_status (approval_status_enum) DEFAULT 'pending' - Approval status

**Constraints:**
- ac_policy CHECK constraint: Must be one of always_on, always_off, on_request
- bank_account_type CHECK constraint: Must be one of checking, savings
- device_platform CHECK constraint: Must be one of ios, android, web
- pix_key_type CHECK constraint: Must be one of cpf, cnpj, email, phone, random

**RLS Policies:**
- "admin can update any driver" (FOR UPDATE TO service_role USING true)
- "drivers can update own record" (FOR UPDATE TO authenticated USING auth.uid() = user_id)

### location_sharing
Emergency location sharing sessions.
- id (uuid) DEFAULT extensions.uuid_generate_v4() NOT NULL PRIMARY KEY - Session ID
- user_id (uuid) NOT NULL FOREIGN KEY -> app_users.id - User sharing location
- expires_at (timestamp with time zone) NOT NULL - When session expires
- shared_with_users (uuid[]) DEFAULT '{}' - Users who can view location
- is_active (boolean) NOT NULL DEFAULT true - Whether session is active
- created_at (timestamp with time zone) NOT NULL DEFAULT now() - Creation timestamp
- ended_at (timestamp with time zone) - When session was ended

### location_updates
Location updates during active sharing sessions.
- id (uuid) DEFAULT extensions.uuid_generate_v4() NOT NULL PRIMARY KEY - Update ID
- sharing_id (uuid) NOT NULL FOREIGN KEY -> location_sharing.id - Sharing session ID
- latitude (double precision) NOT NULL - Latitude coordinate
- longitude (double precision) NOT NULL - Longitude coordinate
- timestamp (timestamp with time zone) NOT NULL DEFAULT now() - Update timestamp

### notifications
In-app and push notifications for users.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Notification ID
- user_id (uuid) FOREIGN KEY -> app_users.id - Recipient user ID
- title (text) NOT NULL - Notification title
- body (text) NOT NULL - Notification body
- type (text) NOT NULL - Type of notification
- data (jsonb) - Additional data
- priority (text) DEFAULT 'normal' - Notification priority
- is_read (boolean) DEFAULT false - Whether notification was read
- sent_at (timestamp with time zone) DEFAULT now() - When sent
- read_at (timestamp with time zone) - When read

**Constraints:**
- priority CHECK constraint: Must be one of low, normal, high
- type CHECK constraint: Must be one of trip, promotion, system, chat, payment

### operational_cities
Cities where the service operates.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - City ID
- name (text) NOT NULL - City name
- state (text) NOT NULL - State name
- country (text) DEFAULT 'Brasil' - Country name
- is_active (boolean) DEFAULT true - Whether service is active
- min_fare (numeric(10,2)) DEFAULT 8.00 - Minimum fare
- launch_date (date) - Service launch date
- polygon_coordinates (jsonb) - City boundary coordinates
- created_at (timestamp with time zone) DEFAULT now() - Creation timestamp

**Unique Constraints:**
- name, state combination must be unique

### passenger_promo_code_usage
Tracking of promo code usage by passengers.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Usage record ID
- user_id (uuid) NOT NULL FOREIGN KEY -> auth.users.id - User ID
- promo_code_id (uuid) NOT NULL FOREIGN KEY -> passenger_promo_codes.id - Promo code ID
- trip_id (uuid) FOREIGN KEY -> trips.id - Trip ID
- original_amount (numeric(10,2)) NOT NULL - Original amount
- discount_amount (numeric(10,2)) NOT NULL - Discount amount
- final_amount (numeric(10,2)) NOT NULL - Final amount after discount
- used_at (timestamp with time zone) NOT NULL DEFAULT now() - When used

**Constraints:**
- discount_amount CHECK constraint: Must be ≥ 0
- final_amount CHECK constraint: Must be ≥ 0
- original_amount CHECK constraint: Must be > 0
- valid_amounts_check CHECK constraint: original_amount = discount_amount + final_amount

### passenger_promo_codes
Promotional codes for passengers.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Promo code ID
- code (character varying(50)) NOT NULL UNIQUE - Promo code string
- type (character varying(50)) NOT NULL - Type of promo code
- value (numeric(10,2)) NOT NULL - Value of discount
- min_amount (numeric(10,2)) NOT NULL DEFAULT 0.00 - Minimum trip amount
- max_discount (numeric(10,2)) - Maximum discount amount
- is_active (boolean) NOT NULL DEFAULT true - Whether code is active
- is_first_ride_only (boolean) NOT NULL DEFAULT false - First ride only
- usage_limit (integer) - Maximum total uses
- usage_count (integer) NOT NULL DEFAULT 0 - Current usage count
- valid_from (timestamp with time zone) NOT NULL DEFAULT now() - Valid from date
- valid_until (timestamp with time zone) NOT NULL - Valid until date
- created_at (timestamp with time zone) NOT NULL DEFAULT now() - Creation timestamp

**Constraints:**
- max_discount CHECK constraint: Must be NULL or > 0
- min_amount CHECK constraint: Must be ≥ 0
- type CHECK constraint: Must be one of percentage, fixed, free_ride
- usage_count CHECK constraint: Must be ≥ 0
- usage_limit CHECK constraint: Must be NULL or > 0
- value CHECK constraint: Must be > 0
- valid_dates_check CHECK constraint: valid_from < valid_until

### passenger_wallet_transactions
Financial transactions in passenger wallets.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Transaction ID
- wallet_id (uuid) NOT NULL FOREIGN KEY -> passenger_wallets.id - Wallet ID
- passenger_id (uuid) NOT NULL FOREIGN KEY -> passengers.id - Passenger ID
- type (character varying(50)) NOT NULL - Transaction type
- amount (numeric(10,2)) NOT NULL - Transaction amount
- description (text) NOT NULL - Transaction description
- trip_id (uuid) FOREIGN KEY -> trips.id - Related trip ID
- payment_method_id (uuid) FOREIGN KEY -> payment_methods.id - Payment method
- asaas_payment_id (character varying(255)) - Asaas payment ID
- status (character varying(50)) NOT NULL DEFAULT 'pending' - Transaction status
- metadata (jsonb) - Additional metadata
- created_at (timestamp with time zone) NOT NULL DEFAULT now() - Creation timestamp
- processed_at (timestamp with time zone) - Processing timestamp

**Constraints:**
- amount CHECK constraint: Must be > 0
- status CHECK constraint: Must be one of pending, processing, completed, failed, cancelled
- type CHECK constraint: Must be one of credit, trip_payment, cashback, refund, cancellation_fee

### passenger_wallets
Financial records for passengers.
- id (uuid) NOT NULL PRIMARY KEY - Wallet ID (matches passenger_id)
- passenger_id (uuid) NOT NULL UNIQUE FOREIGN KEY -> passengers.id - Passenger ID
- user_id (uuid) NOT NULL UNIQUE FOREIGN KEY -> auth.users.id - User ID
- available_balance (numeric(10,2)) NOT NULL DEFAULT 0.00 - Available balance
- pending_balance (numeric(10,2)) NOT NULL DEFAULT 0.00 - Pending balance
- total_spent (numeric(10,2)) NOT NULL DEFAULT 0.00 - Total spent
- total_cashback (numeric(10,2)) NOT NULL DEFAULT 0.00 - Total cashback earned
- created_at (timestamp with time zone) NOT NULL DEFAULT now() - Creation timestamp
- updated_at (timestamp with time zone) NOT NULL DEFAULT now() - Update timestamp

**Constraints:**
- available_balance CHECK constraint: Must be ≥ 0
- pending_balance CHECK constraint: Must be ≥ 0
- total_cashback CHECK constraint: Must be ≥ 0
- total_spent CHECK constraint: Must be ≥ 0
- wallet_id_equals_passenger_id CHECK constraint: id = passenger_id

### passengers
Core passenger information.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Passenger ID
- user_id (uuid) NOT NULL UNIQUE FOREIGN KEY -> app_users.id - User ID
- consecutive_cancellations (integer) DEFAULT 0 - Consecutive cancellations
- total_trips (integer) DEFAULT 0 - Total trips taken
- average_rating (numeric(3,2)) - Average driver rating
- payment_method_id (text) - Default payment method ID
- created_at (timestamp with time zone) DEFAULT now() - Creation timestamp
- updated_at (timestamp with time zone) DEFAULT now() - Update timestamp

### payment_methods
Payment methods registered by users.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Payment method ID
- user_id (uuid) NOT NULL FOREIGN KEY -> auth.users.id - User ID
- type (character varying(50)) NOT NULL - Payment method type
- is_default (boolean) NOT NULL DEFAULT false - Whether it's default
- is_active (boolean) NOT NULL DEFAULT true - Whether it's active
- card_data (jsonb) - Card data (encrypted)
- pix_data (jsonb) - PIX key data
- asaas_customer_id (character varying(255)) - Asaas customer ID
- created_at (timestamp with time zone) NOT NULL DEFAULT now() - Creation timestamp
- updated_at (timestamp with time zone) NOT NULL DEFAULT now() - Update timestamp

**Constraints:**
- type CHECK constraint: Must be one of wallet, credit_card, debit_card, pix

### platform_settings
Pricing and platform configuration settings.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Setting ID
- category (text) NOT NULL UNIQUE - Vehicle category
- base_price_per_km (numeric(10,2)) NOT NULL - Base price per kilometer
- base_price_per_minute (numeric(10,2)) NOT NULL - Base price per minute
- platform_commission_percent (numeric(5,2)) NOT NULL - Platform commission
- min_fare (numeric(10,2)) DEFAULT 8.00 - Minimum fare
- min_cancellation_fee (numeric(10,2)) DEFAULT 10.00 - Minimum cancellation fee
- cancellation_fee_percent (numeric(5,2)) DEFAULT 20.00 - Cancellation fee %
- no_show_wait_minutes (integer) DEFAULT 3 - Wait time for no-show
- driver_acceptance_timeout_seconds (integer) DEFAULT 10 - Acceptance timeout
- created_at (timestamp with time zone) DEFAULT now() - Creation timestamp
- updated_at (timestamp with time zone) DEFAULT now() - Update timestamp

### promo_code_usage
Tracking of promo code usage in trips.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Usage record ID
- promo_code_id (uuid) NOT NULL FOREIGN KEY -> promo_codes.id - Promo code ID
- passenger_id (uuid) NOT NULL FOREIGN KEY -> passengers.id - Passenger ID
- trip_id (uuid) FOREIGN KEY -> trips.id - Trip ID
- discount_applied (numeric(10,2)) - Discount amount applied
- used_at (timestamp with time zone) DEFAULT now() - When used

**Unique Constraints:**
- promo_code_id, trip_id combination must be unique

### promo_codes
Promotional codes for the platform.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Promo code ID
- code (text) NOT NULL UNIQUE - Promo code string
- description (text) - Description of promo code
- discount_type (text) NOT NULL - Type of discount
- discount_value (numeric(10,2)) NOT NULL - Value of discount
- max_discount (numeric(10,2)) - Maximum discount amount
- min_trip_value (numeric(10,2)) - Minimum trip value
- max_uses_per_user (integer) DEFAULT 1 - Maximum uses per user
- valid_from (timestamp with time zone) NOT NULL - Valid from date
- valid_until (timestamp with time zone) NOT NULL - Valid until date
- usage_limit (integer) - Maximum total uses
- used_count (integer) DEFAULT 0 - Current usage count
- target_cities (uuid[]) DEFAULT '{}' - Target cities
- target_categories (text[]) DEFAULT '{}' - Target vehicle categories
- is_first_trip_only (boolean) DEFAULT false - First trip only
- is_active (boolean) DEFAULT true - Whether code is active
- created_by (uuid) FOREIGN KEY -> app_users.id - Creator ID
- created_at (timestamp with time zone) DEFAULT now() - Creation timestamp

**Constraints:**
- discount_type CHECK constraint: Must be one of percentage, fixed

### ratings
Trip ratings provided by passengers and drivers.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Rating ID
- trip_id (uuid) NOT NULL UNIQUE FOREIGN KEY -> trips.id - Trip ID
- passenger_rating (integer) - Passenger's rating of driver
- passenger_rating_tags (text[]) - Tags for passenger rating
- passenger_rating_comment (text) - Comment on passenger rating
- passenger_rated_at (timestamp with time zone) - When passenger rated
- driver_rating (integer) - Driver's rating of passenger
- driver_rating_tags (text[]) - Tags for driver rating
- driver_rating_comment (text) - Comment on driver rating
- driver_rated_at (timestamp with time zone) - When driver rated
- created_at (timestamp with time zone) DEFAULT now() - Creation timestamp
- updated_at (timestamp with time zone) DEFAULT now() - Update timestamp

**Constraints:**
- driver_rating CHECK constraint: Must be between 1 and 5
- passenger_rating CHECK constraint: Must be between 1 and 5

### saved_places
Favorite locations saved by users.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Place ID
- user_id (uuid) NOT NULL FOREIGN KEY -> auth.users.id - User ID
- label (character varying(255)) NOT NULL - Label for the place
- address (text) NOT NULL - Full address
- latitude (numeric(10,8)) NOT NULL - Latitude coordinate
- longitude (numeric(11,8)) NOT NULL - Longitude coordinate
- category (character varying(50)) NOT NULL DEFAULT 'other' - Place category
- created_at (timestamp with time zone) DEFAULT now() - Creation timestamp
- updated_at (timestamp with time zone) DEFAULT now() - Update timestamp

### trip_chats
Real-time chat messages during trips.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Chat message ID
- trip_id (uuid) NOT NULL FOREIGN KEY -> trips.id - Trip ID
- sender_id (uuid) NOT NULL FOREIGN KEY -> app_users.id - Sender user ID
- message (text) NOT NULL - Chat message
- is_read (boolean) DEFAULT false - Whether message was read
- read_at (timestamp with time zone) - When message was read
- created_at (timestamp with time zone) DEFAULT now() - Creation timestamp

### trip_location_history
GPS location history during trips.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Location history ID
- trip_id (uuid) NOT NULL FOREIGN KEY -> trips.id - Trip ID
- latitude (numeric(10,8)) NOT NULL - Latitude coordinate
- longitude (numeric(11,8)) NOT NULL - Longitude coordinate
- speed_kmh (numeric(5,2)) - Speed in km/h
- heading (numeric(5,2)) - Direction of travel
- accuracy_meters (numeric(6,2)) - Location accuracy
- recorded_at (timestamp with time zone) DEFAULT now() - When recorded

### trip_requests
Requests for trips made by passengers.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Request ID
- passenger_id (uuid) NOT NULL FOREIGN KEY -> passengers.id - Passenger ID
- origin_address (text) NOT NULL - Origin address
- origin_latitude (numeric(10,8)) NOT NULL - Origin latitude
- origin_longitude (numeric(11,8)) NOT NULL - Origin longitude
- origin_neighborhood (text) - Origin neighborhood
- destination_address (text) NOT NULL - Destination address
- destination_latitude (numeric(10,8)) NOT NULL - Destination latitude
- destination_longitude (numeric(11,8)) NOT NULL - Destination longitude
- destination_neighborhood (text) - Destination neighborhood
- vehicle_category (text) NOT NULL - Requested vehicle category
- needs_pet (boolean) DEFAULT false - Whether pet transport needed
- needs_grocery_space (boolean) DEFAULT false - Whether grocery space needed
- needs_ac (boolean) DEFAULT false - Whether AC needed
- is_condo_origin (boolean) DEFAULT false - Whether origin is condo
- is_condo_destination (boolean) DEFAULT false - Whether destination is condo
- number_of_stops (integer) DEFAULT 0 - Number of additional stops
- status (text) DEFAULT 'searching' - Request status
- selected_offer_id (uuid) - Selected driver offer ID
- created_at (timestamp with time zone) DEFAULT now() - Creation timestamp
- expires_at (timestamp with time zone) DEFAULT (now() + '00:00:10'::interval) - Expiration timestamp
- target_driver_id (uuid) FOREIGN KEY -> drivers.id - Targeted driver ID
- fallback_drivers (uuid[]) - List of fallback drivers
- accepted_by_driver_id (uuid) FOREIGN KEY -> drivers.id - Accepting driver ID
- accepted_at (timestamp with time zone) - When accepted
- current_fallback_index (integer) DEFAULT 0 - Current fallback index
- timeout_count (integer) DEFAULT 0 - Number of timeouts
- estimated_distance_km (numeric) - Estimated distance
- estimated_duration_minutes (integer) - Estimated duration
- estimated_fare (numeric) - Estimated fare

**Constraints:**
- status CHECK constraint: Must be one of searching, driver_selected, expired, cancelled
- vehicle_category CHECK constraint: Must be one of common_car, freight, tow_truck

### trip_status_history
History of trip status changes.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - History record ID
- trip_id (uuid) NOT NULL FOREIGN KEY -> trips.id - Trip ID
- old_status (text) - Previous status
- new_status (text) NOT NULL - New status
- changed_by (uuid) FOREIGN KEY -> app_users.id - User who changed status
- reason (text) - Reason for status change
- metadata (jsonb) - Additional information
- created_at (timestamp with time zone) DEFAULT now() - When change occurred

### trip_stops
Additional stops in trips.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Stop ID
- trip_id (uuid) NOT NULL FOREIGN KEY -> trips.id - Trip ID
- stop_order (integer) NOT NULL - Order of stop
- address (text) NOT NULL - Stop address
- latitude (numeric(10,8)) NOT NULL - Stop latitude
- longitude (numeric(11,8)) NOT NULL - Stop longitude
- arrived_at (timestamp with time zone) - When arrived at stop
- departed_at (timestamp with time zone) - When departed from stop
- created_at (timestamp with time zone) DEFAULT now() - Creation timestamp

### trips
Core trip information.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Trip ID
- trip_code (text) NOT NULL UNIQUE - Unique trip code
- request_id (uuid) FOREIGN KEY -> trip_requests.id - Request ID
- passenger_id (uuid) NOT NULL FOREIGN KEY -> passengers.id - Passenger ID
- driver_id (uuid) NOT NULL FOREIGN KEY -> drivers.id - Driver ID
- status (text) NOT NULL - Trip status
- origin_address (text) NOT NULL - Origin address
- origin_latitude (numeric(10,8)) NOT NULL - Origin latitude
- origin_longitude (numeric(11,8)) NOT NULL - Origin longitude
- origin_neighborhood (text) - Origin neighborhood
- destination_address (text) NOT NULL - Destination address
- destination_latitude (numeric(10,8)) NOT NULL - Destination latitude
- destination_longitude (numeric(11,8)) NOT NULL - Destination longitude
- destination_neighborhood (text) - Destination neighborhood
- vehicle_category (text) NOT NULL - Vehicle category
- needs_pet (boolean) DEFAULT false - Whether pet transport needed
- needs_grocery_space (boolean) DEFAULT false - Whether grocery space needed
- is_condo_destination (boolean) DEFAULT false - Whether destination is condo
- is_condo_origin (boolean) DEFAULT false - Whether origin is condo
- needs_ac (boolean) DEFAULT false - Whether AC needed
- number_of_stops (integer) DEFAULT 0 - Number of additional stops
- route_polyline (text) - Route as encoded polyline
- estimated_distance_km (numeric(10,2)) - Estimated distance
- estimated_duration_minutes (integer) - Estimated duration
- driver_to_pickup_distance_km (numeric(10,2)) - Distance to pickup
- driver_to_pickup_duration_minutes (integer) - Time to pickup
- actual_distance_km (numeric(10,2)) - Actual distance traveled
- actual_duration_minutes (integer) - Actual trip duration
- waiting_time_minutes (integer) - Waiting time at pickup
- driver_distance_traveled_km (numeric(10,2)) - Distance driver traveled
- base_fare (numeric(10,2)) NOT NULL - Base fare
- additional_fees (numeric(10,2)) DEFAULT 0 - Additional fees
- surge_multiplier (numeric(3,2)) DEFAULT 1.0 - Surge pricing multiplier
- total_fare (numeric(10,2)) NOT NULL - Total fare
- platform_commission (numeric(10,2)) - Platform commission
- driver_earnings (numeric(10,2)) - Driver earnings
- cancellation_reason (text) - Reason for cancellation
- cancellation_fee (numeric(10,2)) - Cancellation fee
- cancelled_by (text) - Who canceled trip
- created_at (timestamp with time zone) DEFAULT now() - Creation timestamp
- driver_assigned_at (timestamp with time zone) - When driver was assigned
- driver_arrived_at (timestamp with time zone) - When driver arrived
- trip_started_at (timestamp with time zone) - When trip started
- trip_completed_at (timestamp with time zone) - When trip completed
- cancelled_at (timestamp with time zone) - When trip was canceled
- payment_status (text) DEFAULT 'pending' - Payment status
- payment_id (text) - Payment identifier
- payment_completed_at (timestamp with time zone) - When payment completed
- promo_code_id (uuid) - Promo code used
- discount_applied (numeric(10,2)) - Discount amount
- updated_at (timestamp with time zone) DEFAULT now() - Update timestamp
- start_time (timestamp with time zone) - Actual start time
- end_time (timestamp with time zone) - Actual end time
- requested_at (timestamp with time zone) - When trip was requested
- completed_at (timestamp with time zone) - When trip was completed
- assigned_at (timestamp with time zone) - When trip was assigned
- arrived_at (timestamp with time zone) - When driver arrived

**Constraints:**
- cancelled_by CHECK constraint: Must be one of passenger, driver, system
- payment_status CHECK constraint: Must be one of pending, processing, completed, failed, refunded
- status CHECK constraint: Must be one of driver_assigned, driver_arriving, waiting_passenger, in_progress, completed, cancelled_by_passenger, cancelled_by_driver, no_show

### user_devices
Devices registered by users for push notifications.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Device ID
- user_id (uuid) NOT NULL FOREIGN KEY -> app_users.id - User ID
- device_token (text) NOT NULL - Device token for push notifications
- platform (text) NOT NULL - Device platform
- device_model (text) - Device model
- app_version (text) - App version
- os_version (text) - OS version
- is_active (boolean) DEFAULT true - Whether device is active
- last_used_at (timestamp with time zone) - When device was last used
- created_at (timestamp with time zone) DEFAULT now() - Creation timestamp
- updated_at (timestamp with time zone) DEFAULT now() - Update timestamp

**Constraints:**
- platform CHECK constraint: Must be one of ios, android
- user_id, device_token combination must be unique

### wallet_transactions
Financial transactions in driver wallets.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Transaction ID
- wallet_id (uuid) NOT NULL FOREIGN KEY -> driver_wallets.id - Wallet ID
- type (text) NOT NULL - Transaction type
- amount (numeric(10,2)) NOT NULL - Transaction amount
- description (text) - Transaction description
- reference_type (text) - Type of reference entity
- reference_id (uuid) - ID of reference entity
- balance_after (numeric(10,2)) - Balance after transaction
- status (text) DEFAULT 'completed' - Transaction status
- created_at (timestamp with time zone) DEFAULT now() - Creation timestamp

**Constraints:**
- status CHECK constraint: Must be one of pending, completed, failed, reversed
- type CHECK constraint: Must be one of earning, withdrawal, fee, bonus, penalty, adjustment

### withdrawals
Withdrawal requests from driver wallets.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Withdrawal ID
- driver_id (uuid) NOT NULL FOREIGN KEY -> drivers.id - Driver ID
- wallet_id (uuid) NOT NULL FOREIGN KEY -> driver_wallets.id - Wallet ID
- amount (numeric(10,2)) NOT NULL - Withdrawal amount
- withdrawal_method (text) - Withdrawal method
- bank_account_info (jsonb) - Bank account information
- asaas_transfer_id (text) - Asaas transfer ID
- status (text) DEFAULT 'pending' - Withdrawal status
- failure_reason (text) - Reason for failure
- requested_at (timestamp with time zone) DEFAULT now() - When requested
- processed_at (timestamp with time zone) - When processed
- completed_at (timestamp with time zone) - When completed

**Constraints:**
- status CHECK constraint: Must be one of pending, processing, completed, failed, cancelled
- withdrawal_method CHECK constraint: Must be one of pix, bank_transfer

### working_hours
Regular working hours for drivers.
- id (uuid) DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY - Working hours ID
- driver_id (uuid) NOT NULL FOREIGN KEY -> drivers.id - Driver ID
- day_of_week (integer) NOT NULL - Day of week (0-6, Sunday-Saturday)
- start_time (time without time zone) NOT NULL - Start time
- end_time (time without time zone) NOT NULL - End time
- is_active (boolean) NOT NULL DEFAULT true - Whether hours are active
- created_at (timestamp with time zone) NOT NULL DEFAULT now() - Creation timestamp
- updated_at (timestamp with time zone) NOT NULL DEFAULT now() - Update timestamp

**Constraints:**
- day_of_week CHECK constraint: Must be between 0 and 6
- start_time < end_time
- driver_id, day_of_week, start_time, end_time, is_active combination must be unique

## 👁️ Views

### driver_current_documents
Current driver documents with URL freshness tracking.
- id (uuid) - Document ID
- driver_id (uuid) - Driver ID
- document_type (text) - Document type
- file_url (text) - File URL
- file_size (integer) - File size
- mime_type (text) - MIME type
- expiry_date (date) - Expiry date
- status (approval_status_enum) - Document status
- reviewed_at (timestamp with time zone) - Review timestamp
- is_current (boolean) - Whether document is current
- created_at (timestamp with time zone) - Creation timestamp
- updated_at (timestamp with time zone) - Update timestamp
- url_might_be_stale (boolean) - Whether URL may be stale

### driver_effective_status
Driver effective online status considering working hours.
- driver_id (uuid) - Driver ID
- online_intent (boolean) - Whether driver intends to be online
- intent_updated_at (timestamp with time zone) - When intent was updated
- is_within_working_hours (boolean) - Whether current time is within working hours
- effective_online (boolean) - Effective online status

### driver_effective_status_with_overrides
Driver effective status considering both working hours and overrides.
- driver_id (uuid) - Driver ID
- online_intent (boolean) - Whether driver intends to be online
- intent_updated_at (timestamp with time zone) - When intent was updated
- has_active_override (boolean) - Whether driver has active override
- is_within_working_hours (boolean) - Whether current time is within working hours
- effective_online (boolean) - Effective online status

### driver_excluded_zones_stats
Statistics on driver excluded zones.
- driver_id (uuid) - Driver ID
- total_excluded_zones (bigint) - Total excluded zones
- cities (ARRAY) - Cities with excluded zones
- states (ARRAY) - States with excluded zones
- first_exclusion_date (timestamp with time zone) - First exclusion date
- last_exclusion_date (timestamp with time zone) - Last exclusion date

## 🚀 Functions (RPCs)

### add_driver_earnings
Adds earnings to a driver's wallet.
- driver_user_id (uuid) - Driver's user ID
- amount (numeric) - Amount to add
- description (text) - Description of earnings

### archive_old_trips
Archives trips older than 6 months.
- Returns: integer (number of archived trips)

### batch_correct_corrupted_users
Corrects corrupted user data in batches.
- max_corrections (integer) DEFAULT 10 - Maximum corrections to process
- dry_run (boolean) DEFAULT true - Whether to simulate changes

### calculate_cancellation_fee
Calculates cancellation fee for a trip.
- p_trip_id (uuid) - Trip ID
- p_driver_current_lat (numeric) - Driver's current latitude
- p_driver_current_lng (numeric) - Driver's current longitude
- Returns: numeric (cancellation fee)

### check_and_suspend_user
Suspends user after 3 consecutive cancellations.
- p_profile_id (uuid) - Profile ID
- p_user_type (text) - User type (driver/passenger)

### check_migration_health
Checks the health of database migrations.
- Returns: json (health status)

### cleanup_expired_requests
Cleans up expired trip requests.
- Returns: integer (number of cleaned up requests)

### cleanup_migration_backup
Cleans up migration backup tables.
- Returns: json (cleanup status)

### create_migration_backup
Creates backup of user data before migration.
- Returns: json (backup status)

### data_correction_summary
Provides summary of data correction activities.
- Returns: json (correction summary)

### diagnose_signup_issues_safe
Diagnoses signup issues safely.
- Returns: json (diagnosis results)

### disable_auth_sync
Disables authentication synchronization.
- feature_name (text) DEFAULT 'both' - Feature to disable

### enable_auth_sync
Enables authentication synchronization.
- feature_name (text) DEFAULT 'both' - Feature to enable

### execute_migration_rollback
Executes rollback of migration.
- Returns: json (rollback status)

### find_available_drivers
Finds available drivers for a trip request.
- Multiple parameters for trip details
- Returns: TABLE of available drivers with pricing

### generate_trip_code
Generates unique trip code.
- Trigger function for trips table

### get_available_categories_stats
Gets statistics for available vehicle categories.
- lat (double precision) - Latitude
- lng (double precision) - Longitude
- radius_km (double precision) DEFAULT 10.0 - Search radius
- Returns: TABLE of category statistics

### get_driver_document_signed_url
Gets signed URL for driver document.
- doc_id (uuid) - Document ID
- expires_in (interval) DEFAULT '01:00:00' - Expiration time
- Returns: text (signed URL)

### get_emergency_nearby_drivers
Gets nearby drivers for emergency situations.
- lat (double precision) - Latitude
- lng (double precision) - Longitude
- radius_km (double precision) DEFAULT 10.0 - Search radius
- Returns: TABLE of nearby drivers

### get_nearby_drivers
Gets nearby available drivers.
- lat (double precision) - Latitude
- lng (double precision) - Longitude
- radius_km (double precision) DEFAULT 5.0 - Search radius
- Returns: TABLE of nearby drivers

### identify_corrupted_users
Identifies users with corrupted data.
- Returns: TABLE of corrupted users

### increment_driver_cancellations
Increments driver cancellation count.
- driver_user_id (uuid) - Driver's user ID
- Returns: integer (new cancellation count)

### increment_passenger_cancellations
Increments passenger cancellation count.
- passenger_user_id (uuid) - Passenger's user ID
- Returns: integer (new cancellation count)

### monitor_migration_progress
Monitors migration progress.
- Returns: json (progress status)

### process_trip_payment
Processes payment for completed trip.
- p_trip_id (uuid) - Trip ID
- Returns: boolean (success status)

### reactivate_user
Reactivates suspended user.
- target_user_id (uuid) - User to reactivate
- admin_user_id (uuid) - Admin performing action
- reason (text) - Reason for reactivation
- Returns: boolean (success status)

### reset_driver_cancellations
Resets driver cancellation count.
- driver_user_id (uuid) - Driver's user ID

### reset_passenger_cancellations
Resets passenger cancellation count.
- passenger_user_id (uuid) - Passenger's user ID

### restore_user_data
Restores user data from backup.
- target_user_id (uuid) - User to restore
- Returns: json (restore status)

### safe_correct_user_data
Safely corrects user data.
- target_user_id (uuid) - User to correct
- new_full_name (text) - New full name
- new_phone (text) - New phone
- dry_run (boolean) DEFAULT true - Whether to simulate changes
- Returns: json (correction status)

### sync_status_report
Reports synchronization status.
- Returns: json (sync status)

### update_average_rating
Updates average ratings for users.
- Trigger function for ratings table

### update_user_metrics
Updates user metrics based on trip status.
- Trigger function for trips table

### validate_data_integrity
Validates data integrity.
- Returns: json (integrity report)

## 🔧 Triggers

### bi_set_passenger_wallet_id
Sets passenger wallet ID before insert.

### driver_suspension_trigger
Suspends driver after 3 consecutive cancellations.

### passenger_suspension_trigger
Suspends passenger after 3 consecutive cancellations.

### trigger_create_passenger_wallet
Creates passenger wallet after passenger insert.

### trigger_driver_document_approval
Checks driver approval when document status changes.

### trigger_generate_trip_code
Generates trip code before trip insert.

### trigger_update_driver_operation_zones_updated_at
Updates timestamp for driver operation zones.

### trigger_update_metrics
Updates user metrics when trip status changes.

### trigger_update_override_timestamp
Updates timestamp for schedule overrides.

### trigger_update_ratings
Updates average ratings when ratings change.

### trip_completion_reset_trigger
Resets cancellation counts when trip completes.

### update_app_users_updated_at
Updates app_users timestamp.

### update_driver_documents_updated_at
Updates driver_documents timestamp.

### update_driver_status_updated_at
Updates driver_status timestamp.

### update_driver_wallets_updated_at
Updates driver_wallets timestamp.

### update_drivers_updated_at
Updates drivers timestamp.

### update_passenger_wallets_updated_at
Updates passenger_wallets timestamp.

### update_passengers_updated_at
Updates passengers timestamp.

### update_payment_methods_updated_at
Updates payment_methods timestamp.

### update_trips_updated_at
Updates trips timestamp.

### update_working_hours_updated_at
Updates working_hours timestamp.

## 🔒 RLS Policies Summary

The database uses Row Level Security (RLS) to control access to data. Key policies include:

1. **app_users**: Users can only view and update their own profile data
2. **passengers**: Users can only access passenger records linked to their user account
3. **drivers**: Users can only access driver records linked to their user account
4. **trip_requests**: Users can only access trip requests they created
5. **trips**: Users can only access trips where they are either the passenger or driver
6. **driver_offers**: Users can only access offers they created or that are linked to their trip requests

These policies ensure that users can only access data they are authorized to see, maintaining privacy and security.

## 📈 Database Health Check

### Current Status Summary
- ✅ **Connection**: Active
- ✅ **Authentication**: Valid keys found
- ✅ **Tables**: Schema verified
- ⚠️ **RLS Policies**: Active (may restrict access)
- ✅ **Data Integrity**: All tables consistent with documentation

### Next Steps
1. Review RLS policies for production use
2. Set up proper user authentication flow
3. Consider creating database views for common queries
4. Implement proper error handling for RLS restrictions