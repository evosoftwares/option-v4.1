# Supabase Schema Documentation

This document outlines the database schema for the Supabase project. It includes tables, views, functions, RLS policies, and constraints that are part of the application's data layer.

**Note**: This project uses a hybrid architecture:
- **Database, Authentication, Realtime**: Supabase
- **File Storage**: Firebase Storage (not Supabase Storage)

## 🔍 Connection Information

### Project Details
- **Project URL**: `https://qlbwacmavngtonauxnte.supabase.co`
- **Project ID**: `qlbwacmavngtonauxnte`
- **Region**: Unknown (accessed via URL)
- **Connection Status**: ✅ Active and Accessible

### Authentication Keys
- **Service Role Key**: Available in project configuration
- **Anonymous Key**: Available in project configuration
- **Access Method**: REST API + Supabase CLI (v2.34.3)

## 📊 Current Database State

### Accessible Tables
Based on direct API connection testing:

#### ✅ drivers
- **Status**: ✅ Accessible (200 OK)
- **Row Count**: 3 records
- **Data Sample**:
  ```json
  [
    {
      "id": "driver_uuid_1",
      "user_id": "user_uuid_1",
      "approval_status": "pending",
      "is_online": false,
      "vehicle_brand": "VW",
      "vehicle_model": "Gol",
      "vehicle_year": 2020,
      "vehicle_color": "Branco",
      "vehicle_plate": "ABC1234",
      "vehicle_category": "standard",
      "current_latitude": -23.5505,
      "current_longitude": -46.6333,
      "total_trips": 0,
      "average_rating": 0.0,
      "consecutive_cancellations": 0,
      "created_at": "2024-01-15T10:30:00Z"
    }
  ]
  ```

#### ❌ Other Tables Status
- **app_users**: 403 Forbidden (RLS Policy Restricted)
- **passengers**: 403 Forbidden (RLS Policy Restricted)
- **trips**: 403 Forbidden (RLS Policy Restricted)
- **trip_requests**: 403 Forbidden (RLS Policy Restricted)
- **payment_methods**: 403 Forbidden (RLS Policy Restricted)

### 🔒 RLS Policies Impact
**Important**: Row Level Security (RLS) is **enabled** on most user tables:
- **app_users**: Has RLS policies restricting access
- **passengers**: Has RLS policies restricting access
- **drivers**: Has RLS policies but accessible via Service Role Key
- **trips**: Has RLS policies restricting access
- **trip_requests**: Has RLS policies restricting access

**Recommendation**: Use Service Role Key for administrative operations or implement proper user authentication flow.

## 🗃️ Complete Table Schema

## Tables

### activity_logs
- id (uuid) **PRIMARY KEY**
- user_id (uuid) **FOREIGN KEY** -> table='app_users' column='id'
- action (text)
- entity_type (text)
- entity_id (uuid)
- old_values (jsonb)
- new_values (jsonb)
- metadata (jsonb)
- ip_address (inet)
- user_agent (text)
- created_at (timestamp with time zone) **DEFAULT** now()

### app_users
- id (uuid) **PRIMARY KEY**
- email (text)
- full_name (text)
- phone (text) **DEFAULT** pending
- photo_url (text)
- user_type (text)
- status (text) **DEFAULT** active
- created_at (timestamp with time zone) **DEFAULT** now()
- updated_at (timestamp with time zone) **DEFAULT** now()
- user_id (uuid)
- fcm_token (text)
- device_id (text)
- device_platform (text)
- last_active_at (timestamp with time zone) **DEFAULT** now()

**RLS Policies:**
- "Users can view own profile" (FOR SELECT USING auth.uid() = id)
- "Users can update own profile" (FOR UPDATE USING auth.uid() = id)
- "Enable insert for authenticated users only" (FOR INSERT WITH CHECK auth.uid() = id)

### backup_app_users_migration
- id (uuid)
- email (text)
- full_name (text)
- phone (text)
- photo_url (text)
- user_type (text)
- status (text)
- created_at (timestamp with time zone)
- updated_at (timestamp with time zone)
- user_id (uuid)

### ~~working_hours~~ (REMOVIDA)
**TABELA REMOVIDA NA MIGRAÇÃO PARA LÓGICA BASEADA EM DOCUMENTOS**
- Esta tabela foi completamente removida
- A lógica de horários de trabalho foi substituída por validação de documentos
- Motoristas agora controlam quando querem trabalhar sem restrições de horário
- Status online depende apenas de: `online_intent` + `documentos aprovados`

### corrupted_users_backup
- id (uuid) **PRIMARY KEY**
- original_user_id (uuid)
- original_full_name (text)
- original_phone (text)
- original_email (text)
- correction_timestamp (timestamp with time zone) **DEFAULT** now()
- correction_reason (text)
- restored (boolean) **DEFAULT** false
- restored_at (timestamp with time zone)

### trips
- id (uuid) **PRIMARY KEY**
- trip_code (text)
- request_id (uuid) **FOREIGN KEY** -> table='trip_requests' column='id'
- passenger_id (uuid) **FOREIGN KEY** -> table='passengers' column='id'
- driver_id (uuid) **FOREIGN KEY** -> table='drivers' column='id'
- status (text)
- origin_address (text)
- origin_latitude (numeric)
- origin_longitude (numeric)
- origin_neighborhood (text)
- destination_address (text)
- destination_latitude (numeric)
- destination_longitude (numeric)
- destination_neighborhood (text)
- vehicle_category (text)
- needs_pet (boolean) **DEFAULT** false
- needs_grocery_space (boolean) **DEFAULT** false
- is_condo_destination (boolean) **DEFAULT** false
- is_condo_origin (boolean) **DEFAULT** false
- needs_ac (boolean) **DEFAULT** false
- number_of_stops (integer) **DEFAULT** 0
- route_polyline (text)
- estimated_distance_km (numeric)
- estimated_duration_minutes (integer)
- driver_to_pickup_distance_km (numeric)
- driver_to_pickup_duration_minutes (integer)
- actual_distance_km (numeric)
- actual_duration_minutes (integer)
- waiting_time_minutes (integer)
- driver_distance_traveled_km (numeric)
- base_fare (numeric)
- additional_fees (numeric) **DEFAULT** 0
- surge_multiplier (numeric) **DEFAULT** 1.0
- total_fare (numeric)
- platform_commission (numeric)
- driver_earnings (numeric)
- cancellation_reason (text)
- cancellation_fee (numeric)
- cancelled_by (text)
- created_at (timestamp with time zone) **DEFAULT** now()
- driver_assigned_at (timestamp with time zone)
- driver_arrived_at (timestamp with time zone)
- trip_started_at (timestamp with time zone)
- trip_completed_at (timestamp with time zone)
- cancelled_at (timestamp with time zone)
- start_time (timestamp with time zone)
- end_time (timestamp with time zone)
- requested_at (timestamp with time zone)
- completed_at (timestamp with time zone)
- assigned_at (timestamp with time zone)
- arrived_at (timestamp with time zone)
- payment_status (text) **DEFAULT** pending
- payment_id (text)
- payment_completed_at (timestamp with time zone)
- promo_code_id (uuid)
- discount_applied (numeric)
- updated_at (timestamp with time zone) **DEFAULT** now()

### backup_conflict_409_removal
- source_table (text)
- backup_timestamp (timestamp with time zone)
- id (uuid)
- email (text)
- full_name (text)
- phone (text)
- photo_url (text)
- user_type (text)
- status (text)
- created_at (timestamp with time zone)
- updated_at (timestamp with time zone)

### driver_operational_cities
- id (uuid) **PRIMARY KEY**
- driver_id (uuid) **FOREIGN KEY** -> table='drivers' column='id'
- city_id (uuid) **FOREIGN KEY** -> table='operational_cities' column='id'
- is_primary (boolean) **DEFAULT** false
- created_at (timestamp with time zone) **DEFAULT** now()

### payment_methods
- id (uuid) **PRIMARY KEY**
- user_id (uuid)
- type (character varying)
- is_default (boolean) **DEFAULT** false
- is_active (boolean) **DEFAULT** true
- card_data (jsonb)
- pix_data (jsonb)
- asaas_customer_id (character varying)
- created_at (timestamp with time zone) **DEFAULT** now()
- updated_at (timestamp with time zone) **DEFAULT** now()

**Description:** Métodos de pagamento dos usuários (PIX, Carteira Digital)

### driver_documents
- id (uuid) **PRIMARY KEY**
- driver_id (uuid) **FOREIGN KEY** -> table='drivers' column='id'
- document_type (text)
- file_url (text)
- file_size (integer)
- mime_type (text)
- expiry_date (date)
- rejection_reason (text)
- reviewed_by (uuid) **FOREIGN KEY** -> table='app_users' column='id'
- reviewed_at (timestamp with time zone)
- is_current (boolean) **DEFAULT** true
- created_at (timestamp with time zone) **DEFAULT** now()
- updated_at (timestamp with time zone) **DEFAULT** now()
- status (text) **DEFAULT** pending

**Constraints:**
- document_type CHECK constraint: Must be one of:
  - 'CNH_FRONT'
  - 'CNH_BACK'
  - 'CRLV'
  - 'VEHICLE_FRONT'
  - 'VEHICLE_BACK'
  - 'VEHICLE_LEFT'
  - 'VEHICLE_RIGHT'
  - 'VEHICLE_INTERIOR'

### backup_drivers_migration
- id (uuid)
- user_id (uuid)
- cnh_number (text)
- cnh_expiry_date (date)
- cnh_photo_url (text)
- vehicle_brand (text)
- vehicle_model (text)
- vehicle_year (integer)
- vehicle_color (text)
- vehicle_plate (text)
- vehicle_category (text)
- crlv_photo_url (text)
- approval_status (text)
- approved_by (uuid)
- approved_at (timestamp with time zone)
- is_online (boolean)
- accepts_pet (boolean)
- pet_fee (numeric)
- accepts_grocery (boolean)
- grocery_fee (numeric)
- accepts_condo (boolean)
- condo_fee (numeric)
- stop_fee (numeric)
- ac_policy (text)
- custom_price_per_km (numeric)
- custom_price_per_minute (numeric)
- bank_account_type (text)
- bank_code (text)
- bank_agency (text)
- bank_account (text)
- pix_key (text)
- pix_key_type (text)
- consecutive_cancellations (integer)
- total_trips (integer)
- average_rating (numeric)
- current_latitude (numeric)
- current_longitude (numeric)
- last_location_update (timestamp with time zone)
- created_at (timestamp with time zone)
- updated_at (timestamp with time zone)

### driver_status
- driver_id (uuid) **PRIMARY KEY** **FOREIGN KEY** -> table='drivers' column='id'
- online_intent (boolean) **DEFAULT** false
- updated_at (timestamp with time zone) **DEFAULT** now()

### passenger_promo_codes
- id (uuid) **PRIMARY KEY**
- code (character varying)
- type (character varying)
- value (numeric)
- min_amount (numeric) **DEFAULT** 0.0
- max_discount (numeric)
- is_active (boolean) **DEFAULT** true
- is_first_ride_only (boolean) **DEFAULT** false
- usage_limit (integer)
- usage_count (integer) **DEFAULT** 0
- valid_from (timestamp with time zone) **DEFAULT** now()
- valid_until (timestamp with time zone)
- created_at (timestamp with time zone) **DEFAULT** now()

### drivers
- id (uuid) **PRIMARY KEY**
- user_id (uuid) **FOREIGN KEY** -> table='app_users' column='id'
- cnh_expiry_date (date)
- cnh_photo_url (text)
- vehicle_brand (text)
- vehicle_model (text)
- vehicle_year (integer)
- vehicle_color (text)
- vehicle_plate (text)
- vehicle_category (text)
- crlv_photo_url (text)
- approved_by (uuid) **FOREIGN KEY** -> table='app_users' column='id'
- approved_at (timestamp with time zone)
- is_online (boolean) **DEFAULT** false
- accepts_pet (boolean) **DEFAULT** false
- pet_fee (numeric) **DEFAULT** 0
- accepts_grocery (boolean) **DEFAULT** false
- grocery_fee (numeric) **DEFAULT** 0
- accepts_condo (boolean) **DEFAULT** false
- condo_fee (numeric) **DEFAULT** 0
- stop_fee (numeric) **DEFAULT** 0
- ac_policy (text) **DEFAULT** on_request
- custom_price_per_km (numeric)
- custom_price_per_minute (numeric)
- bank_account_type (text)
- bank_code (text)
- bank_agency (text)
- bank_account (text)
- pix_key (text)
- pix_key_type (text)
- consecutive_cancellations (integer) **DEFAULT** 0
- total_trips (integer) **DEFAULT** 0
- average_rating (numeric)
- current_latitude (numeric)
- current_longitude (numeric)
- last_location_update (timestamp with time zone)
- created_at (timestamp with time zone) **DEFAULT** now()
- updated_at (timestamp with time zone) **DEFAULT** now()
- fcm_token (text)
- device_platform (text)
- last_notification_at (timestamp with time zone)
- approval_status (text) **DEFAULT** pending

**RLS Policies:**
- "Allow driver operations" (FOR ALL USING complex conditions)

### passengers
- id (uuid) **PRIMARY KEY**
- user_id (uuid) **FOREIGN KEY** -> table='app_users' column='id'
- consecutive_cancellations (integer) **DEFAULT** 0
- total_trips (integer) **DEFAULT** 0
- average_rating (numeric)
- payment_method_id (text)
- created_at (timestamp with time zone) **DEFAULT** now()
- updated_at (timestamp with time zone) **DEFAULT** now()

**RLS Policies:**
- "Allow passenger operations" (FOR ALL USING complex conditions)

### trip_stops
- id (uuid) **PRIMARY KEY**
- trip_id (uuid) **FOREIGN KEY** -> table='trips' column='id'
- stop_order (integer)
- address (text)
- latitude (numeric)
- longitude (numeric)
- arrived_at (timestamp with time zone)
- departed_at (timestamp with time zone)
- created_at (timestamp with time zone) **DEFAULT** now()

### passenger_wallets
- id (uuid) **PRIMARY KEY**
- passenger_id (uuid) **FOREIGN KEY** -> table='passengers' column='id'
- user_id (uuid)
- available_balance (numeric) **DEFAULT** 0.0
- pending_balance (numeric) **DEFAULT** 0.0
- total_spent (numeric) **DEFAULT** 0.0
- total_cashback (numeric) **DEFAULT** 0.0
- created_at (timestamp with time zone) **DEFAULT** now()
- updated_at (timestamp with time zone) **DEFAULT** now()

### saved_places
- id (uuid) **PRIMARY KEY**
- user_id (uuid)
- label (character varying)
- address (text)
- latitude (numeric)
- longitude (numeric)
- category (character varying) **DEFAULT** other
- created_at (timestamp with time zone) **DEFAULT** now()
- updated_at (timestamp with time zone) **DEFAULT** now()

### operational_cities
- id (uuid) **PRIMARY KEY**
- name (text)
- state (text)
- country (text) **DEFAULT** Brasil
- is_active (boolean) **DEFAULT** true
- min_fare (numeric) **DEFAULT** 8.0
- launch_date (date)
- polygon_coordinates (jsonb)
- created_at (timestamp with time zone) **DEFAULT** now()

### driver_excluded_zones
- id (uuid) **PRIMARY KEY**
- driver_id (uuid) **FOREIGN KEY** -> table='drivers' column='id'
- neighborhood_name (text)
- city (text)
- state (text)
- created_at (timestamp with time zone) **DEFAULT** now()

### trip_chats
- id (uuid) **PRIMARY KEY**
- trip_id (uuid) **FOREIGN KEY** -> table='trips' column='id'
- sender_id (uuid) **FOREIGN KEY** -> table='app_users' column='id'
- message (text)
- is_read (boolean) **DEFAULT** false
- read_at (timestamp with time zone)
- created_at (timestamp with time zone) **DEFAULT** now()

### driver_approval_audit
- id (uuid) **PRIMARY KEY**
- driver_id (uuid) **FOREIGN KEY** -> table='drivers' column='id'
- old_status (text)
- new_status (text)
- reason (text)
- approved_documents (jsonb)
- created_at (timestamp with time zone) **DEFAULT** now()

### ratings
- id (uuid) **PRIMARY KEY**
- trip_id (uuid) **FOREIGN KEY** -> table='trips' column='id'
- passenger_rating (integer)
- passenger_rating_tags (text[])
- passenger_rating_comment (text)
- passenger_rated_at (timestamp with time zone)
- driver_rating (integer)
- driver_rating_tags (text[])
- driver_rating_comment (text)
- driver_rated_at (timestamp with time zone)
- created_at (timestamp with time zone) **DEFAULT** now()
- updated_at (timestamp with time zone) **DEFAULT** now()

### platform_settings
- id (uuid) **PRIMARY KEY**
- category (text)
- base_price_per_km (numeric)
- base_price_per_minute (numeric)
- platform_commission_percent (numeric)
- min_fare (numeric) **DEFAULT** 8.0
- min_cancellation_fee (numeric) **DEFAULT** 10.0
- cancellation_fee_percent (numeric) **DEFAULT** 20.0
- no_show_wait_minutes (integer) **DEFAULT** 3
- driver_acceptance_timeout_seconds (integer) **DEFAULT** 10
- created_at (timestamp with time zone) **DEFAULT** now()
- updated_at (timestamp with time zone) **DEFAULT** now()

### withdrawals
- id (uuid) **PRIMARY KEY**
- driver_id (uuid) **FOREIGN KEY** -> table='drivers' column='id'
- wallet_id (uuid) **FOREIGN KEY** -> table='driver_wallets' column='id'
- amount (numeric)
- withdrawal_method (text)
- bank_account_info (jsonb)
- asaas_transfer_id (text)
- status (text) **DEFAULT** pending
- failure_reason (text)
- requested_at (timestamp with time zone) **DEFAULT** now()
- processed_at (timestamp with time zone)
- completed_at (timestamp with time zone)

### driver_operation_zones
- id (uuid) **PRIMARY KEY**
- driver_id (uuid) **FOREIGN KEY** -> table='drivers' column='id'
- zone_name (text)
- polygon_coordinates (jsonb)
- price_multiplier (numeric) **DEFAULT** 1.0
- is_active (boolean) **DEFAULT** true
- created_at (timestamp with time zone) **DEFAULT** now()
- updated_at (timestamp with time zone) **DEFAULT** now()

**Description:** Áreas de atuação do motorista com fatores de multiplicação de preço

### trip_location_history
- id (uuid) **PRIMARY KEY**
- trip_id (uuid) **FOREIGN KEY** -> table='trips' column='id'
- latitude (numeric)
- longitude (numeric)
- speed_kmh (numeric)
- heading (numeric)
- accuracy_meters (numeric)
- recorded_at (timestamp with time zone) **DEFAULT** now()

### wallet_transactions
- id (uuid) **PRIMARY KEY**
- wallet_id (uuid) **FOREIGN KEY** -> table='driver_wallets' column='id'
- type (text)
- amount (numeric)
- description (text)
- reference_type (text)
- reference_id (uuid)
- balance_after (numeric)
- status (text) **DEFAULT** completed
- created_at (timestamp with time zone) **DEFAULT** now()

### driver_schedules
- id (uuid) **PRIMARY KEY**
- driver_id (uuid) **FOREIGN KEY** -> table='drivers' column='id'
- day_of_week (integer)
- start_time (time without time zone)
- end_time (time without time zone)
- is_active (boolean) **DEFAULT** true
- created_at (timestamp with time zone) **DEFAULT** now()

### trip_requests
- id (uuid) **PRIMARY KEY**
- passenger_id (uuid) **FOREIGN KEY** -> table='passengers' column='id'
- origin_address (text)
- origin_latitude (numeric)
- origin_longitude (numeric)
- origin_neighborhood (text)
- destination_address (text)
- destination_latitude (numeric)
- destination_longitude (numeric)
- destination_neighborhood (text)
- vehicle_category (text)
- needs_pet (boolean) **DEFAULT** false
- needs_grocery_space (boolean) **DEFAULT** false
- needs_ac (boolean) **DEFAULT** false
- is_condo_origin (boolean) **DEFAULT** false
- is_condo_destination (boolean) **DEFAULT** false
- number_of_stops (integer) **DEFAULT** 0
- status (text) **DEFAULT** searching
- selected_offer_id (uuid)
- created_at (timestamp with time zone) **DEFAULT** now()
- expires_at (timestamp with time zone) **DEFAULT** (now() + '00:00:10'::interval)
- target_driver_id (uuid) **FOREIGN KEY** -> table='drivers' column='id'
- fallback_drivers (uuid[])
- accepted_by_driver_id (uuid) **FOREIGN KEY** -> table='drivers' column='id'
- accepted_at (timestamp with time zone)
- current_fallback_index (integer) **DEFAULT** 0
- timeout_count (integer) **DEFAULT** 0
- estimated_distance_km (numeric)
- estimated_duration_minutes (integer)
- estimated_fare (numeric)

**RLS Policies:**
- "Allow trip request operations" (FOR ALL USING complex conditions)

### trip_status_history
- id (uuid) **PRIMARY KEY**
- trip_id (uuid) **FOREIGN KEY** -> table='trips' column='id'
- old_status (text)
- new_status (text)
- changed_by (uuid) **FOREIGN KEY** -> table='app_users' column='id'
- reason (text)
- metadata (jsonb)
- created_at (timestamp with time zone) **DEFAULT** now()

### backup_passengers_migration
- id (uuid)
- user_id (uuid)
- consecutive_cancellations (integer)
- total_trips (integer)
- average_rating (numeric)
- payment_method_id (text)
- created_at (timestamp with time zone)
- updated_at (timestamp with time zone)

### passenger_wallet_transactions
- id (uuid) **PRIMARY KEY**
- wallet_id (uuid) **FOREIGN KEY** -> table='passenger_wallets' column='id'
- passenger_id (uuid) **FOREIGN KEY** -> table='passengers' column='id'
- type (character varying)
- amount (numeric)
- description (text)
- trip_id (uuid) **FOREIGN KEY** -> table='trips' column='id'
- payment_method_id (uuid) **FOREIGN KEY** -> table='payment_methods' column='id'
- asaas_payment_id (character varying)
- status (character varying) **DEFAULT** pending
- metadata (jsonb)
- created_at (timestamp with time zone) **DEFAULT** now()
- processed_at (timestamp with time zone)

### notifications
- id (uuid) **PRIMARY KEY**
- user_id (uuid) **FOREIGN KEY** -> table='app_users' column='id'
- title (text)
- body (text)
- type (text)
- data (jsonb)
- priority (text) **DEFAULT** normal
- is_read (boolean) **DEFAULT** false
- sent_at (timestamp with time zone) **DEFAULT** now()
- read_at (timestamp with time zone)

### promo_code_usage
- id (uuid) **PRIMARY KEY**
- promo_code_id (uuid) **FOREIGN KEY** -> table='promo_codes' column='id'
- passenger_id (uuid) **FOREIGN KEY** -> table='passengers' column='id'
- trip_id (uuid) **FOREIGN KEY** -> table='trips' column='id'
- discount_applied (numeric)
- used_at (timestamp with time zone) **DEFAULT** now()

### driver_wallets
- id (uuid) **PRIMARY KEY**
- driver_id (uuid) **FOREIGN KEY** -> table='drivers' column='id'
- available_balance (numeric) **DEFAULT** 0
- pending_balance (numeric) **DEFAULT** 0
- total_earned (numeric) **DEFAULT** 0
- total_withdrawn (numeric) **DEFAULT** 0
- created_at (timestamp with time zone) **DEFAULT** now()
- updated_at (timestamp with time zone) **DEFAULT** now()

### driver_offers
- id (uuid) **PRIMARY KEY**
- request_id (uuid) **FOREIGN KEY** -> table='trip_requests' column='id'
- driver_id (uuid) **FOREIGN KEY** -> table='drivers' column='id'
- driver_distance_km (numeric)
- driver_eta_minutes (integer)
- base_fare (numeric)
- additional_fees (numeric)
- total_fare (numeric)
- distance_component (numeric)
- time_component (numeric)
- is_available (boolean) **DEFAULT** true
- was_selected (boolean) **DEFAULT** false
- created_at (timestamp with time zone) **DEFAULT** now()

### promo_codes
- id (uuid) **PRIMARY KEY**
- code (text)
- description (text)
- discount_type (text)
- discount_value (numeric)
- max_discount (numeric)
- min_trip_value (numeric)
- max_uses_per_user (integer) **DEFAULT** 1
- valid_from (timestamp with time zone)
- valid_until (timestamp with time zone)
- usage_limit (integer)
- used_count (integer) **DEFAULT** 0
- target_cities (uuid[])
- target_categories (text[])
- is_first_trip_only (boolean) **DEFAULT** false
- is_active (boolean) **DEFAULT** true
- created_by (uuid) **FOREIGN KEY** -> table='app_users' column='id'
- created_at (timestamp with time zone) **DEFAULT** now()

## 🚀 How to Access Supabase

### Method 1: Using Supabase CLI
```bash
# Link project
supabase link --project-ref qlbwacmavngtonauxnte

# Access database
supabase db list

# Open Supabase dashboard
supabase dashboard
```

### Method 2: Using Python Script
Use the provided `conectar_supabase.py` script:
```bash
python3 conectar_supabase.py
```

### Method 3: Direct REST API
```bash
# Get drivers (works with service role key)
curl -X GET 'https://qlbwacmavngtonauxnte.supabase.co/rest/v1/drivers' \
  -H "apikey: YOUR_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"

# Get app_users (requires user authentication)
curl -X GET 'https://qlbwacmavngtonauxnte.supabase.co/rest/v1/app_users' \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Authorization: Bearer USER_JWT_TOKEN"
```

### Method 4: Supabase Dashboard
1. Go to https://supabase.com/dashboard
2. Sign in with your account
3. Select project: `qlbwacmavngtonauxnte`
4. Navigate to SQL Editor or Table Editor

## 🔧 Troubleshooting

### Common Issues
1. **403 Forbidden**: RLS policies are active - use service role key or proper auth
2. **Connection Timeout**: Check internet connection and URL
3. **Authentication Failed**: Verify API keys in environment variables

### Environment Variables
Ensure these are set in your `.env` file:
```bash
SUPABASE_URL=https://qlbwacmavngtonauxnte.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
```

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

### daily_statistics
- date (date)
- total_trips (bigint)
- completed_trips (bigint)
- cancelled_trips (bigint)
- no_show_trips (bigint)
- avg_fare (numeric)
- total_revenue (numeric)
- total_commission (numeric)
- unique_passengers (bigint)
- unique_drivers (bigint)

### data_correction_monitoring
- correction_date (date)
- corrections_made (bigint)
- corrections_restored (bigint)
- corrections_active (bigint)
- correction_reason (text)

### driver_effective_status (VIEW ATUALIZADA)
**NOVA LÓGICA: Baseada apenas em aprovação de documentos**
- driver_id (uuid) **PRIMARY KEY** **FOREIGN KEY** -> table='drivers' column='id'
- online_intent (boolean) - Intenção do motorista de ficar online
- intent_updated_at (timestamp with time zone) - Quando a intenção foi atualizada
- documents_validated (boolean) - Se TODOS os documentos obrigatórios estão aprovados
- effective_online (boolean) - Status final: `online_intent AND documents_validated`

**Documentos obrigatórios para `documents_validated = true`:**
- CNH_FRONT com `status = 'approved'` e `is_current = true`
- CNH_BACK com `status = 'approved'` e `is_current = true` 
- CRLV com `status = 'approved'` e `is_current = true`
- VEHICLE_FRONT com `status = 'approved'` e `is_current = true`

**REMOVIDO:** ~~is_within_working_hours~~ (não existe mais)

### driver_performance
- driver_id (uuid) **PRIMARY KEY**
- driver_name (text)
- average_rating (numeric)
- total_trips (integer)
- consecutive_cancellations (integer)
- completed_trips_30d (bigint)
- cancelled_trips_30d (bigint)
- rating_30d (numeric)
- earnings_30d (numeric)

### user_devices
- id (uuid) **PRIMARY KEY**
- user_id (uuid) **FOREIGN KEY** -> table='app_users' column='id'
- device_token (text)
- platform (text)
- device_model (text)
- app_version (text)
- os_version (text)
- is_active (boolean) **DEFAULT** true
- last_used_at (timestamp with time zone)
- created_at (timestamp with time zone) **DEFAULT** now()
- updated_at (timestamp with time zone) **DEFAULT** now()

## Views

### available_drivers_view
- driver_id (uuid) **PRIMARY KEY** **FOREIGN KEY** -> table='app_users' column='id'
- user_id (uuid) **FOREIGN KEY** -> table='app_users' column='id'
- full_name (text)
- photo_url (text)
- phone (text)
- vehicle_brand (text)
- vehicle_model (text)
- vehicle_year (integer)
- vehicle_color (text)
- vehicle_category (text)
- average_rating (numeric)
- total_trips (integer)
- is_online (boolean)
- current_latitude (numeric)
- current_longitude (numeric)
- last_location_update (timestamp with time zone)
- accepts_pet (boolean)
- accepts_grocery (boolean)
- accepts_condo (boolean)
- ac_policy (text)
- custom_price_per_km (numeric)
- custom_price_per_minute (numeric)
- pet_fee (numeric)
- grocery_fee (numeric)
- condo_fee (numeric)
- stop_fee (numeric)

### profiles
- id (uuid) **PRIMARY KEY**
- user_id (uuid)
- nome (text)
- telefone (text)
- avatar_url (text)
- tipo_usuario (text)
- created_at (timestamp with time zone)
- updated_at (timestamp with time zone)

## Functions (RPCs)

- add_driver_earnings
- algorithm_sign
- archive_old_trips
- batch_correct_corrupted_users
- calculate_cancellation_fee
- check_and_suspend_user
- check_migration_health
- cleanup_expired_requests
- cleanup_migration_backup
- create_migration_backup
- data_correction_summary
- diagnose_signup_issues_safe
- disable_auth_sync
- enable_auth_sync
- execute_migration_rollback
- find_available_drivers
- get_available_categories_stats
- get_emergency_nearby_drivers
- get_nearby_drivers
- identify_corrupted_users
- increment_driver_cancellations
- increment_passenger_cancellations
- is_sync_enabled
- monitor_migration_progress
- process_trip_payment
- reactivate_user
- reset_driver_cancellations
- reset_passenger_cancellations
- restore_user_data
- safe_correct_user_data
- sign
- simple_auth_check
- sync_status_report
- test_automatic_approval_system
- test_direct_signup
- test_problematic_insert
- try_cast_double
- url_decode
- url_encode
- validate_data_integrity
- validate_sync_data
- verify
- disable_all_rls (custom function to disable all RLS policies)

## Constraints

### driver_documents
- document_type CHECK constraint: Must be one of:
  - 'CNH_FRONT'
  - 'CNH_BACK'
  - 'CRLV'
  - 'VEHICLE_FRONT'
  - 'VEHICLE_BACK'
  - 'VEHICLE_LEFT'
  - 'VEHICLE_RIGHT'
  - 'VEHICLE_INTERIOR'

## RLS Policies Summary

The database uses Row Level Security (RLS) to control access to data. Key policies include:

1. **app_users**: Users can only view and update their own profile data
2. **passengers**: Users can only access passenger records linked to their user account
3. **drivers**: Users can only access driver records linked to their user account
4. **trip_requests**: Users can only access trip requests they created
5. **trips**: Users can only access trips where they are either the passenger or driver
6. **driver_offers**: Users can only access offers they created or that are linked to their trip requests

These policies ensure that users can only access data they are authorized to see, maintaining privacy and security.

## Functions for RLS Management

- `disable_all_rls()`: A custom function that can disable all RLS policies when needed for testing or maintenance

## Notes

1. When testing, RLS policies may need to be temporarily disabled to allow service role access
2. All tables have RLS enabled, with specific policies for each table
3. Constraints are used to ensure data integrity, particularly for enum-like fields
4. The system uses a combination of RLS and application-level checks to ensure security