# Supabase Tabelas - Resumo

_Atualizado em: 2025-08-20_

## 👥 Usuários e Autenticação
### app_users
- id (uuid, PK)
- email (text, unique)
- full_name (text)
- phone (text)
- photo_url (text)
- user_type (text)
- status (text)
- created_at (timestamp)

### passengers
- id (uuid, PK)
- user_id (uuid, FK → app_users.id)
- consecutive_cancellations (int)
- total_trips (int)
- average_rating (numeric)
- payment_method_id (uuid)

### drivers
- id (uuid, PK)
- user_id (uuid, FK → app_users.id)
- cnh_number (text)
- cnh_expiry_date (date)
- cnh_photo_url (text)
- brand (text)
- model (text)
- year (int)
- color (text)
- plate (text)
- category (text)
- crlv_photo_url (text)
- approval_status (text)
- is_online (bool)
- accepts_pet (bool)
- accepts_grocery (bool)
- accepts_condo (bool)
- fees (jsonb)
- ac_policy (text)
- custom_price_per_km (numeric)
- custom_price_per_minute (numeric)
- bank_data (jsonb)
- pix_data (jsonb)
- current_latitude (numeric)
- current_longitude (numeric)
- ratings (numeric)
- trips (int)
- cancellations (int)

## 🌍 Configuração e Localização
### operational_cities
- id (uuid, PK)
- name (text)
- state (text)
- country (text)
- is_active (bool)
- min_fare (numeric)
- polygon_coordinates (geometry)

### driver_operational_cities
- driver_id (uuid, FK → drivers.id)
- city_id (uuid, FK → operational_cities.id)
- is_primary (bool)

### driver_excluded_zones
- driver_id (uuid, FK → drivers.id)
- neighborhood_name (text)
- city (text)
- state (text)

### driver_schedules
- driver_id (uuid, FK → drivers.id)
- day_of_week (int)
- start_time (time)
- end_time (time)

### saved_places
- passenger_id (uuid, FK → passengers.id)
- label (text)
- address (text)
- latitude (numeric)
- longitude (numeric)

### platform_settings
- category (text)
- base_price_per_km (numeric)
- base_price_per_minute (numeric)
- platform_commission_percent (numeric)
- min_fare (numeric)
- cancellation_fees (numeric)
- timeouts (jsonb)
- search_radius (numeric)

## 🚖 Solicitações e Matching
### trip_requests
- id (uuid, PK)
- passenger_id (uuid, FK → passengers.id)
- origin_address (text)
- origin_lat (numeric)
- origin_lng (numeric)
- origin_neighborhood (text)
- destination_address (text)
- destination_lat (numeric)
- destination_lng (numeric)
- destination_neighborhood (text)
- vehicle_category (text)
- needs_pet (bool)
- needs_grocery (bool)
- needs_condo (bool)
- number_of_stops (int)
- status (text)
- selected_offer_id (uuid, FK → driver_offers.request_id)
- expires_at (timestamp)

### driver_offers
- request_id (uuid, FK → trip_requests.id)
- driver_id (uuid, FK → drivers.id)
- driver_distance_km (numeric)
- driver_eta_minutes (int)
- base_fare (numeric)
- additional_fees (numeric)
- total_fare (numeric)
- is_available (bool)
- was_selected (bool)

## 🛣️ Viagens
### trips
- id (uuid, PK)
- trip_code (text, unique)
- request_id (uuid, FK → trip_requests.id)
- passenger_id (uuid, FK → passengers.id)
- driver_id (uuid, FK → drivers.id)
- status (text)
- origin_address (text)
- origin_lat (numeric)
- origin_lng (numeric)
- destination_address (text)
- destination_lat (numeric)
- destination_lng (numeric)
- vehicle_category (text)
- needs_pet (bool)
- needs_grocery (bool)
- needs_condo (bool)
- stops (jsonb)
- route_polyline (text)
- estimated_distance_km (numeric)
- estimated_duration_min (numeric)
- actual_distance_km (numeric)
- actual_duration_min (numeric)
- waiting_time_min (numeric)
- base_fare (numeric)
- additional_fees (numeric)
- commission (numeric)
- earnings (numeric)
- cancellation_reason (text)
- cancellation_fee (numeric)
- cancelled_by (text)
- payment_status (text)
- payment_id (uuid)
- requested_at (timestamp)
- accepted_at (timestamp)
- started_at (timestamp)
- completed_at (timestamp)
- cancelled_at (timestamp)
- paid_at (timestamp)

### trip_stops
- trip_id (uuid, FK → trips.id)
- stop_order (int)
- address (text)
- latitude (numeric)
- longitude (numeric)
- arrived_at (timestamp)
- departed_at (timestamp)

### trip_location_history
- trip_id (uuid, FK → trips.id)
- latitude (numeric)
- longitude (numeric)
- speed_kmh (numeric)
- heading (numeric)
- accuracy (numeric)
- recorded_at (timestamp)

### trip_status_history
- trip_id (uuid, FK → trips.id)
- old_status (text)
- new_status (text)
- changed_by (uuid)
- reason (text)
- metadata (jsonb)
- changed_at (timestamp)

## 💳 Sistema Financeiro
### driver_wallets
- driver_id (uuid, PK)
- available_balance (numeric)
- pending_balance (numeric)
- total_earned (numeric)
- total_withdrawn (numeric)

### wallet_transactions
- wallet_id (uuid, FK → driver_wallets.driver_id)
- type (text)
- amount (numeric)
- description (text)
- reference_type (text)
- reference_id (uuid)
- balance_after (numeric)
- status (text)
- created_at (timestamp)

### withdrawals
- driver_id (uuid, FK → drivers.id)
- wallet_id (uuid, FK → driver_wallets.driver_id)
- amount (numeric)
- withdrawal_method (text)
- bank_account_info (jsonb)
- asaas_transfer_id (text)
- status (text)
- failure_reason (text)
- requested_at (timestamp)
- processed_at (timestamp)

## 💬 Comunicação e Avaliação
### trip_chats
- trip_id (uuid, FK → trips.id)
- sender_id (uuid)
- message (text)
- is_read (bool)
- read_at (timestamp)
- sent_at (timestamp)

### ratings
- trip_id (uuid, FK → trips.id)
- passenger_rating (numeric)
- passenger_tags (jsonb)
- passenger_comment (text)
- driver_rating (numeric)
- driver_tags (jsonb)
- driver_comment (text)

## 🎁 Promoções
### promo_codes
- code (text, PK)
- description (text)
- discount_type (text)
- discount_value (numeric)
- max_discount (numeric)
- min_trip_value (numeric)
- validity (daterange)
- usage_limits (int)
- target_cities (text[])
- target_categories (text[])
- is_first_trip_only (bool)

### promo_code_usage
- promo_code_id (text, FK → promo_codes.code)
- passenger_id (uuid, FK → passengers.id)
- trip_id (uuid, FK → trips.id)
- discount_applied (numeric)
- used_at (timestamp)

## 🔧 Sistema e Auditoria
### notifications
- user_id (uuid)
- title (text)
- body (text)
- type (text)
- data (jsonb)
- priority (text)
- is_read (bool)
- created_at (timestamp)
- read_at (timestamp)

### user_devices
- user_id (uuid)
- device_token (text)
- platform (text)
- device_info (jsonb)
- app_version (text)
- os_version (text)
- registered_at (timestamp)

### driver_documents
- driver_id (uuid, FK → drivers.id)
- document_type (text)
- file_url (text)
- file_size (numeric)
- mime_type (text)
- status (text)
- rejection_reason (text)
- reviewed_by (uuid)
- reviewed_at (timestamp)
- uploaded_at (timestamp)

### activity_logs
- user_id (uuid)
- action (text)
- entity_type (text)
- entity_id (uuid)
- old_values (jsonb)
- new_values (jsonb)
- metadata (jsonb)
- ip_address (text)
- created_at (timestamp)

## 👁️ Views
- **available_drivers_view**
- **daily_statistics**
- **driver_performance**

## ⚡ Triggers Principais
- **update_updated_at_column()**
- **find_available_drivers()**

## 🎯 Índices Estratégicos
- **Localização** (drivers online e coordenadas)
- **Viagens** (status, passenger_id, driver_id)
- **Financeiro** (transações e saques)
- **Temporal** (ordenado por created_at)
- **Geoespacial** (PostGIS para proximidade)