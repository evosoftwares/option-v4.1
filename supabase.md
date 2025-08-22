[
  {
    "table_name": "activity_logs",
    "column_name": "id",
    "data_type": "uuid",
    "nullable": "NOT NULL",
    "default_value": "gen_random_uuid()"
  },
  {
    "table_name": "activity_logs",
    "column_name": "user_id",
    "data_type": "uuid",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "activity_logs",
    "column_name": "action",
    "data_type": "text",
    "nullable": "NOT NULL",
    "default_value": "No default"
  },
  {
    "table_name": "activity_logs",
    "column_name": "entity_type",
    "data_type": "text",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "activity_logs",
    "column_name": "entity_id",
    "data_type": "uuid",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "activity_logs",
    "column_name": "old_values",
    "data_type": "jsonb",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "activity_logs",
    "column_name": "new_values",
    "data_type": "jsonb",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "activity_logs",
    "column_name": "metadata",
    "data_type": "jsonb",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "activity_logs",
    "column_name": "ip_address",
    "data_type": "inet",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "activity_logs",
    "column_name": "user_agent",
    "data_type": "text",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "activity_logs",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "nullable": "NULL",
    "default_value": "now()"
  },
  {
    "table_name": "app_users",
    "column_name": "id",
    "data_type": "uuid",
    "nullable": "NOT NULL",
    "default_value": "No default"
  },
  {
    "table_name": "app_users",
    "column_name": "email",
    "data_type": "text",
    "nullable": "NOT NULL",
    "default_value": "No default"
  },
  {
    "table_name": "app_users",
    "column_name": "full_name",
    "data_type": "text",
    "nullable": "NOT NULL",
    "default_value": "No default"
  },
  {
    "table_name": "app_users",
    "column_name": "phone",
    "data_type": "text",
    "nullable": "NOT NULL",
    "default_value": "No default"
  },
  {
    "table_name": "app_users",
    "column_name": "photo_url",
    "data_type": "text",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "app_users",
    "column_name": "user_type",
    "data_type": "text",
    "nullable": "NOT NULL",
    "default_value": "No default"
  },
  {
    "table_name": "app_users",
    "column_name": "status",
    "data_type": "text",
    "nullable": "NOT NULL",
    "default_value": "'active'::text"
  },
  {
    "table_name": "app_users",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "nullable": "NULL",
    "default_value": "now()"
  },
  {
    "table_name": "app_users",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone",
    "nullable": "NULL",
    "default_value": "now()"
  },
  {
    "table_name": "app_users",
    "column_name": "user_id",
    "data_type": "uuid",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "driver_id",
    "data_type": "uuid",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "user_id",
    "data_type": "uuid",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "full_name",
    "data_type": "text",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "photo_url",
    "data_type": "text",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "phone",
    "data_type": "text",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "vehicle_brand",
    "data_type": "text",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "vehicle_model",
    "data_type": "text",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "vehicle_year",
    "data_type": "integer",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "vehicle_color",
    "data_type": "text",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "vehicle_category",
    "data_type": "text",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "average_rating",
    "data_type": "numeric",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "total_trips",
    "data_type": "integer",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "is_online",
    "data_type": "boolean",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "current_latitude",
    "data_type": "numeric",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "current_longitude",
    "data_type": "numeric",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "last_location_update",
    "data_type": "timestamp with time zone",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "accepts_pet",
    "data_type": "boolean",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "accepts_grocery",
    "data_type": "boolean",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "accepts_condo",
    "data_type": "boolean",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "ac_policy",
    "data_type": "text",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "custom_price_per_km",
    "data_type": "numeric",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "custom_price_per_minute",
    "data_type": "numeric",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "pet_fee",
    "data_type": "numeric",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "grocery_fee",
    "data_type": "numeric",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "condo_fee",
    "data_type": "numeric",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "stop_fee",
    "data_type": "numeric",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "daily_statistics",
    "column_name": "date",
    "data_type": "date",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "daily_statistics",
    "column_name": "total_trips",
    "data_type": "bigint",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "daily_statistics",
    "column_name": "completed_trips",
    "data_type": "bigint",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "daily_statistics",
    "column_name": "cancelled_trips",
    "data_type": "bigint",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "daily_statistics",
    "column_name": "no_show_trips",
    "data_type": "bigint",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "daily_statistics",
    "column_name": "avg_fare",
    "data_type": "numeric",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "daily_statistics",
    "column_name": "total_revenue",
    "data_type": "numeric",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "daily_statistics",
    "column_name": "total_commission",
    "data_type": "numeric",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "daily_statistics",
    "column_name": "unique_passengers",
    "data_type": "bigint",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "daily_statistics",
    "column_name": "unique_drivers",
    "data_type": "bigint",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_documents",
    "column_name": "id",
    "data_type": "uuid",
    "nullable": "NOT NULL",
    "default_value": "gen_random_uuid()"
  },
  {
    "table_name": "driver_documents",
    "column_name": "driver_id",
    "data_type": "uuid",
    "nullable": "NOT NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_documents",
    "column_name": "document_type",
    "data_type": "text",
    "nullable": "NOT NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_documents",
    "column_name": "file_url",
    "data_type": "text",
    "nullable": "NOT NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_documents",
    "column_name": "file_size",
    "data_type": "integer",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_documents",
    "column_name": "mime_type",
    "data_type": "text",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_documents",
    "column_name": "expiry_date",
    "data_type": "date",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_documents",
    "column_name": "status",
    "data_type": "text",
    "nullable": "NULL",
    "default_value": "'pending'::text"
  },
  {
    "table_name": "driver_documents",
    "column_name": "rejection_reason",
    "data_type": "text",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_documents",
    "column_name": "reviewed_by",
    "data_type": "uuid",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_documents",
    "column_name": "reviewed_at",
    "data_type": "timestamp with time zone",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_documents",
    "column_name": "is_current",
    "data_type": "boolean",
    "nullable": "NULL",
    "default_value": "true"
  },
  {
    "table_name": "driver_documents",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "nullable": "NULL",
    "default_value": "now()"
  },
  {
    "table_name": "driver_excluded_zones",
    "column_name": "id",
    "data_type": "uuid",
    "nullable": "NOT NULL",
    "default_value": "gen_random_uuid()"
  },
  {
    "table_name": "driver_excluded_zones",
    "column_name": "driver_id",
    "data_type": "uuid",
    "nullable": "NOT NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_excluded_zones",
    "column_name": "neighborhood_name",
    "data_type": "text",
    "nullable": "NOT NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_excluded_zones",
    "column_name": "city",
    "data_type": "text",
    "nullable": "NOT NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_excluded_zones",
    "column_name": "state",
    "data_type": "text",
    "nullable": "NOT NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_excluded_zones",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "nullable": "NULL",
    "default_value": "now()"
  },
  {
    "table_name": "driver_offers",
    "column_name": "id",
    "data_type": "uuid",
    "nullable": "NOT NULL",
    "default_value": "gen_random_uuid()"
  },
  {
    "table_name": "driver_offers",
    "column_name": "request_id",
    "data_type": "uuid",
    "nullable": "NOT NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_offers",
    "column_name": "driver_id",
    "data_type": "uuid",
    "nullable": "NOT NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_offers",
    "column_name": "driver_distance_km",
    "data_type": "numeric",
    "nullable": "NOT NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_offers",
    "column_name": "driver_eta_minutes",
    "data_type": "integer",
    "nullable": "NOT NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_offers",
    "column_name": "base_fare",
    "data_type": "numeric",
    "nullable": "NOT NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_offers",
    "column_name": "additional_fees",
    "data_type": "numeric",
    "nullable": "NOT NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_offers",
    "column_name": "total_fare",
    "data_type": "numeric",
    "nullable": "NOT NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_offers",
    "column_name": "distance_component",
    "data_type": "numeric",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_offers",
    "column_name": "time_component",
    "data_type": "numeric",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_offers",
    "column_name": "is_available",
    "data_type": "boolean",
    "nullable": "NULL",
    "default_value": "true"
  },
  {
    "table_name": "driver_offers",
    "column_name": "was_selected",
    "data_type": "boolean",
    "nullable": "NULL",
    "default_value": "false"
  },
  {
    "table_name": "driver_offers",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "nullable": "NULL",
    "default_value": "now()"
  },
  {
    "table_name": "driver_operational_cities",
    "column_name": "id",
    "data_type": "uuid",
    "nullable": "NOT NULL",
    "default_value": "gen_random_uuid()"
  },
  {
    "table_name": "driver_operational_cities",
    "column_name": "driver_id",
    "data_type": "uuid",
    "nullable": "NOT NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_operational_cities",
    "column_name": "city_id",
    "data_type": "uuid",
    "nullable": "NOT NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_operational_cities",
    "column_name": "is_primary",
    "data_type": "boolean",
    "nullable": "NULL",
    "default_value": "false"
  },
  {
    "table_name": "driver_operational_cities",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "nullable": "NULL",
    "default_value": "now()"
  },
  {
    "table_name": "driver_performance",
    "column_name": "driver_id",
    "data_type": "uuid",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_performance",
    "column_name": "driver_name",
    "data_type": "text",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_performance",
    "column_name": "average_rating",
    "data_type": "numeric",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_performance",
    "column_name": "total_trips",
    "data_type": "integer",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_performance",
    "column_name": "consecutive_cancellations",
    "data_type": "integer",
    "nullable": "NULL",
    "default_value": "No default"
  },
  {
    "table_name": "driver_performance",
    "column_name": "completed_trips_30d",
    "data_type": "bigint",
    "nullable": "NULL",
    "default_value": "No default"
  }
]