[
  {
    "table_name": "activity_logs",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "activity_logs",
    "column_name": "user_id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "activity_logs",
    "column_name": "action",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "activity_logs",
    "column_name": "entity_type",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "activity_logs",
    "column_name": "entity_id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "activity_logs",
    "column_name": "old_values",
    "data_type": "jsonb",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "activity_logs",
    "column_name": "new_values",
    "data_type": "jsonb",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "activity_logs",
    "column_name": "metadata",
    "data_type": "jsonb",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "activity_logs",
    "column_name": "ip_address",
    "data_type": "inet",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "activity_logs",
    "column_name": "user_agent",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "activity_logs",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "app_users",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "app_users",
    "column_name": "email",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "app_users",
    "column_name": "full_name",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "app_users",
    "column_name": "phone",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": "'pending'::text",
    "column_comment": null
  },
  {
    "table_name": "app_users",
    "column_name": "photo_url",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "app_users",
    "column_name": "user_type",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "app_users",
    "column_name": "status",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": "'active'::text",
    "column_comment": null
  },
  {
    "table_name": "app_users",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "app_users",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "app_users",
    "column_name": "user_id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "app_users",
    "column_name": "fcm_token",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "app_users",
    "column_name": "device_id",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "app_users",
    "column_name": "device_platform",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "app_users",
    "column_name": "last_active_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "driver_id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "user_id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "full_name",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "photo_url",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "phone",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "vehicle_brand",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "vehicle_model",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "vehicle_year",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "vehicle_color",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "vehicle_category",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "average_rating",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "total_trips",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "is_online",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "current_latitude",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "current_longitude",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "last_location_update",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "accepts_pet",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "accepts_grocery",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "accepts_condo",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "ac_policy",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "custom_price_per_km",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "custom_price_per_minute",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "pet_fee",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "grocery_fee",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "condo_fee",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "available_drivers_view",
    "column_name": "stop_fee",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_app_users_migration",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_app_users_migration",
    "column_name": "email",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_app_users_migration",
    "column_name": "full_name",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_app_users_migration",
    "column_name": "phone",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_app_users_migration",
    "column_name": "photo_url",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_app_users_migration",
    "column_name": "user_type",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_app_users_migration",
    "column_name": "status",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_app_users_migration",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_app_users_migration",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_app_users_migration",
    "column_name": "user_id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "user_id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "cnh_number",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "cnh_expiry_date",
    "data_type": "date",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "cnh_photo_url",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "vehicle_brand",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "vehicle_model",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "vehicle_year",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "vehicle_color",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "vehicle_plate",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "vehicle_category",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "crlv_photo_url",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "approval_status",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "approved_by",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "approved_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "is_online",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "accepts_pet",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "pet_fee",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "accepts_grocery",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "grocery_fee",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "accepts_condo",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "condo_fee",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "stop_fee",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "ac_policy",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "custom_price_per_km",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "custom_price_per_minute",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "bank_account_type",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "bank_code",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "bank_agency",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "bank_account",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "pix_key",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "pix_key_type",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "consecutive_cancellations",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "total_trips",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "average_rating",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "current_latitude",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "current_longitude",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "last_location_update",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_drivers_migration",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_passengers_migration",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_passengers_migration",
    "column_name": "user_id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_passengers_migration",
    "column_name": "consecutive_cancellations",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_passengers_migration",
    "column_name": "total_trips",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_passengers_migration",
    "column_name": "average_rating",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_passengers_migration",
    "column_name": "payment_method_id",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_passengers_migration",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "backup_passengers_migration",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "corrupted_users_backup",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "corrupted_users_backup",
    "column_name": "original_user_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "corrupted_users_backup",
    "column_name": "original_full_name",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "corrupted_users_backup",
    "column_name": "original_phone",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "corrupted_users_backup",
    "column_name": "original_email",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "corrupted_users_backup",
    "column_name": "correction_timestamp",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "corrupted_users_backup",
    "column_name": "correction_reason",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "corrupted_users_backup",
    "column_name": "restored",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "false",
    "column_comment": null
  },
  {
    "table_name": "corrupted_users_backup",
    "column_name": "restored_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "daily_statistics",
    "column_name": "date",
    "data_type": "date",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "daily_statistics",
    "column_name": "total_trips",
    "data_type": "bigint",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "daily_statistics",
    "column_name": "completed_trips",
    "data_type": "bigint",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "daily_statistics",
    "column_name": "cancelled_trips",
    "data_type": "bigint",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "daily_statistics",
    "column_name": "no_show_trips",
    "data_type": "bigint",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "daily_statistics",
    "column_name": "avg_fare",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "daily_statistics",
    "column_name": "total_revenue",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "daily_statistics",
    "column_name": "total_commission",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "daily_statistics",
    "column_name": "unique_passengers",
    "data_type": "bigint",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "daily_statistics",
    "column_name": "unique_drivers",
    "data_type": "bigint",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "data_correction_monitoring",
    "column_name": "correction_date",
    "data_type": "date",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "data_correction_monitoring",
    "column_name": "corrections_made",
    "data_type": "bigint",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "data_correction_monitoring",
    "column_name": "corrections_restored",
    "data_type": "bigint",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "data_correction_monitoring",
    "column_name": "corrections_active",
    "data_type": "bigint",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "data_correction_monitoring",
    "column_name": "correction_reason",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_documents",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "driver_documents",
    "column_name": "driver_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_documents",
    "column_name": "document_type",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_documents",
    "column_name": "file_url",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_documents",
    "column_name": "file_size",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_documents",
    "column_name": "mime_type",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_documents",
    "column_name": "expiry_date",
    "data_type": "date",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_documents",
    "column_name": "status",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": "'pending'::text",
    "column_comment": null
  },
  {
    "table_name": "driver_documents",
    "column_name": "rejection_reason",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_documents",
    "column_name": "reviewed_by",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_documents",
    "column_name": "reviewed_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_documents",
    "column_name": "is_current",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "true",
    "column_comment": null
  },
  {
    "table_name": "driver_documents",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "driver_excluded_zones",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "driver_excluded_zones",
    "column_name": "driver_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_excluded_zones",
    "column_name": "neighborhood_name",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_excluded_zones",
    "column_name": "city",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_excluded_zones",
    "column_name": "state",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_excluded_zones",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "driver_offers",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "driver_offers",
    "column_name": "request_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_offers",
    "column_name": "driver_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_offers",
    "column_name": "driver_distance_km",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_offers",
    "column_name": "driver_eta_minutes",
    "data_type": "integer",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_offers",
    "column_name": "base_fare",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_offers",
    "column_name": "additional_fees",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_offers",
    "column_name": "total_fare",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_offers",
    "column_name": "distance_component",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_offers",
    "column_name": "time_component",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_offers",
    "column_name": "is_available",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "true",
    "column_comment": null
  },
  {
    "table_name": "driver_offers",
    "column_name": "was_selected",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "false",
    "column_comment": null
  },
  {
    "table_name": "driver_offers",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "driver_operation_zones",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "driver_operation_zones",
    "column_name": "driver_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_operation_zones",
    "column_name": "zone_name",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": "Nome da área definido pelo motorista"
  },
  {
    "table_name": "driver_operation_zones",
    "column_name": "polygon_coordinates",
    "data_type": "jsonb",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": "Coordenadas do polígono em formato JSON: [{\"lat\": -23.5505, \"lng\": -46.6333}, ...]"
  },
  {
    "table_name": "driver_operation_zones",
    "column_name": "price_multiplier",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": "1.00",
    "column_comment": "Fator de multiplicação do preço (1.0 = normal, 1.5 = 50% a mais, etc.)"
  },
  {
    "table_name": "driver_operation_zones",
    "column_name": "is_active",
    "data_type": "boolean",
    "is_nullable": "NO",
    "column_default": "true",
    "column_comment": "Se a área está ativa para aplicação do multiplicador"
  },
  {
    "table_name": "driver_operation_zones",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "driver_operation_zones",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "driver_operational_cities",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "driver_operational_cities",
    "column_name": "driver_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_operational_cities",
    "column_name": "city_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_operational_cities",
    "column_name": "is_primary",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "false",
    "column_comment": null
  },
  {
    "table_name": "driver_operational_cities",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "driver_performance",
    "column_name": "driver_id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_performance",
    "column_name": "driver_name",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_performance",
    "column_name": "average_rating",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_performance",
    "column_name": "total_trips",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_performance",
    "column_name": "consecutive_cancellations",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_performance",
    "column_name": "completed_trips_30d",
    "data_type": "bigint",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_performance",
    "column_name": "cancelled_trips_30d",
    "data_type": "bigint",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_performance",
    "column_name": "rating_30d",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_performance",
    "column_name": "earnings_30d",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_schedules",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "driver_schedules",
    "column_name": "driver_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_schedules",
    "column_name": "day_of_week",
    "data_type": "integer",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_schedules",
    "column_name": "start_time",
    "data_type": "time without time zone",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_schedules",
    "column_name": "end_time",
    "data_type": "time without time zone",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_schedules",
    "column_name": "is_active",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "true",
    "column_comment": null
  },
  {
    "table_name": "driver_schedules",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "driver_wallets",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "driver_wallets",
    "column_name": "driver_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "driver_wallets",
    "column_name": "available_balance",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": "0",
    "column_comment": null
  },
  {
    "table_name": "driver_wallets",
    "column_name": "pending_balance",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": "0",
    "column_comment": null
  },
  {
    "table_name": "driver_wallets",
    "column_name": "total_earned",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": "0",
    "column_comment": null
  },
  {
    "table_name": "driver_wallets",
    "column_name": "total_withdrawn",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": "0",
    "column_comment": null
  },
  {
    "table_name": "driver_wallets",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "driver_wallets",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "user_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "cnh_number",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "cnh_expiry_date",
    "data_type": "date",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "cnh_photo_url",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "vehicle_brand",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "vehicle_model",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "vehicle_year",
    "data_type": "integer",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "vehicle_color",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "vehicle_plate",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "vehicle_category",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "crlv_photo_url",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "approval_status",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": "'pending'::text",
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "approved_by",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "approved_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "is_online",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "false",
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "accepts_pet",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "false",
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "pet_fee",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": "0",
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "accepts_grocery",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "false",
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "grocery_fee",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": "0",
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "accepts_condo",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "false",
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "condo_fee",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": "0",
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "stop_fee",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": "0",
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "ac_policy",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": "'on_request'::text",
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "custom_price_per_km",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "custom_price_per_minute",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "bank_account_type",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "bank_code",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "bank_agency",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "bank_account",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "pix_key",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "pix_key_type",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "consecutive_cancellations",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": "0",
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "total_trips",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": "0",
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "average_rating",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "current_latitude",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "current_longitude",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "last_location_update",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "fcm_token",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "device_platform",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "drivers",
    "column_name": "last_notification_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "notifications",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "notifications",
    "column_name": "user_id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "notifications",
    "column_name": "title",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "notifications",
    "column_name": "body",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "notifications",
    "column_name": "type",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "notifications",
    "column_name": "data",
    "data_type": "jsonb",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "notifications",
    "column_name": "priority",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": "'normal'::text",
    "column_comment": null
  },
  {
    "table_name": "notifications",
    "column_name": "is_read",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "false",
    "column_comment": null
  },
  {
    "table_name": "notifications",
    "column_name": "sent_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "notifications",
    "column_name": "read_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "operational_cities",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "operational_cities",
    "column_name": "name",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "operational_cities",
    "column_name": "state",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "operational_cities",
    "column_name": "country",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": "'Brasil'::text",
    "column_comment": null
  },
  {
    "table_name": "operational_cities",
    "column_name": "is_active",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "true",
    "column_comment": null
  },
  {
    "table_name": "operational_cities",
    "column_name": "min_fare",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": "8.00",
    "column_comment": null
  },
  {
    "table_name": "operational_cities",
    "column_name": "launch_date",
    "data_type": "date",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "operational_cities",
    "column_name": "polygon_coordinates",
    "data_type": "jsonb",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "operational_cities",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "passenger_promo_code_usage",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "passenger_promo_code_usage",
    "column_name": "user_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_promo_code_usage",
    "column_name": "promo_code_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_promo_code_usage",
    "column_name": "trip_id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_promo_code_usage",
    "column_name": "original_amount",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_promo_code_usage",
    "column_name": "discount_amount",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_promo_code_usage",
    "column_name": "final_amount",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_promo_code_usage",
    "column_name": "used_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "NO",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "passenger_promo_codes",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "passenger_promo_codes",
    "column_name": "code",
    "data_type": "character varying",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_promo_codes",
    "column_name": "type",
    "data_type": "character varying",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_promo_codes",
    "column_name": "value",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_promo_codes",
    "column_name": "min_amount",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": "0.00",
    "column_comment": null
  },
  {
    "table_name": "passenger_promo_codes",
    "column_name": "max_discount",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_promo_codes",
    "column_name": "is_active",
    "data_type": "boolean",
    "is_nullable": "NO",
    "column_default": "true",
    "column_comment": null
  },
  {
    "table_name": "passenger_promo_codes",
    "column_name": "is_first_ride_only",
    "data_type": "boolean",
    "is_nullable": "NO",
    "column_default": "false",
    "column_comment": null
  },
  {
    "table_name": "passenger_promo_codes",
    "column_name": "usage_limit",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_promo_codes",
    "column_name": "usage_count",
    "data_type": "integer",
    "is_nullable": "NO",
    "column_default": "0",
    "column_comment": null
  },
  {
    "table_name": "passenger_promo_codes",
    "column_name": "valid_from",
    "data_type": "timestamp with time zone",
    "is_nullable": "NO",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "passenger_promo_codes",
    "column_name": "valid_until",
    "data_type": "timestamp with time zone",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_promo_codes",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "NO",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "passenger_wallet_transactions",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "passenger_wallet_transactions",
    "column_name": "wallet_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_wallet_transactions",
    "column_name": "passenger_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_wallet_transactions",
    "column_name": "type",
    "data_type": "character varying",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_wallet_transactions",
    "column_name": "amount",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_wallet_transactions",
    "column_name": "description",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_wallet_transactions",
    "column_name": "trip_id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_wallet_transactions",
    "column_name": "payment_method_id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_wallet_transactions",
    "column_name": "asaas_payment_id",
    "data_type": "character varying",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_wallet_transactions",
    "column_name": "status",
    "data_type": "character varying",
    "is_nullable": "NO",
    "column_default": "'pending'::character varying",
    "column_comment": null
  },
  {
    "table_name": "passenger_wallet_transactions",
    "column_name": "metadata",
    "data_type": "jsonb",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_wallet_transactions",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "NO",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "passenger_wallet_transactions",
    "column_name": "processed_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_wallets",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_wallets",
    "column_name": "passenger_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_wallets",
    "column_name": "user_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passenger_wallets",
    "column_name": "available_balance",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": "0.00",
    "column_comment": null
  },
  {
    "table_name": "passenger_wallets",
    "column_name": "pending_balance",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": "0.00",
    "column_comment": null
  },
  {
    "table_name": "passenger_wallets",
    "column_name": "total_spent",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": "0.00",
    "column_comment": null
  },
  {
    "table_name": "passenger_wallets",
    "column_name": "total_cashback",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": "0.00",
    "column_comment": null
  },
  {
    "table_name": "passenger_wallets",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "NO",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "passenger_wallets",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "NO",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "passengers",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "passengers",
    "column_name": "user_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passengers",
    "column_name": "consecutive_cancellations",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": "0",
    "column_comment": null
  },
  {
    "table_name": "passengers",
    "column_name": "total_trips",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": "0",
    "column_comment": null
  },
  {
    "table_name": "passengers",
    "column_name": "average_rating",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passengers",
    "column_name": "payment_method_id",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "passengers",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "passengers",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "payment_methods",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "payment_methods",
    "column_name": "user_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "payment_methods",
    "column_name": "type",
    "data_type": "character varying",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "payment_methods",
    "column_name": "is_default",
    "data_type": "boolean",
    "is_nullable": "NO",
    "column_default": "false",
    "column_comment": null
  },
  {
    "table_name": "payment_methods",
    "column_name": "is_active",
    "data_type": "boolean",
    "is_nullable": "NO",
    "column_default": "true",
    "column_comment": null
  },
  {
    "table_name": "payment_methods",
    "column_name": "card_data",
    "data_type": "jsonb",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "payment_methods",
    "column_name": "pix_data",
    "data_type": "jsonb",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": "JSON com dados do PIX: {\"key_type\": \"cpf|email|phone|random_key\", \"key_value\": \"valor_da_chave\", \"qr_code_data\": \"dados_qr\"}"
  },
  {
    "table_name": "payment_methods",
    "column_name": "asaas_customer_id",
    "data_type": "character varying",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "payment_methods",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "NO",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "payment_methods",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "NO",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "platform_settings",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "platform_settings",
    "column_name": "category",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "platform_settings",
    "column_name": "base_price_per_km",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "platform_settings",
    "column_name": "base_price_per_minute",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "platform_settings",
    "column_name": "platform_commission_percent",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "platform_settings",
    "column_name": "min_fare",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": "8.00",
    "column_comment": null
  },
  {
    "table_name": "platform_settings",
    "column_name": "min_cancellation_fee",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": "10.00",
    "column_comment": null
  },
  {
    "table_name": "platform_settings",
    "column_name": "cancellation_fee_percent",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": "20.00",
    "column_comment": null
  },
  {
    "table_name": "platform_settings",
    "column_name": "no_show_wait_minutes",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": "3",
    "column_comment": null
  },
  {
    "table_name": "platform_settings",
    "column_name": "driver_acceptance_timeout_seconds",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": "10",
    "column_comment": null
  },
  {
    "table_name": "platform_settings",
    "column_name": "search_radius_km",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": "10",
    "column_comment": null
  },
  {
    "table_name": "platform_settings",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "platform_settings",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "profiles",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "profiles",
    "column_name": "user_id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "profiles",
    "column_name": "nome",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "profiles",
    "column_name": "telefone",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "profiles",
    "column_name": "avatar_url",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "profiles",
    "column_name": "tipo_usuario",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "profiles",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "profiles",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "promo_code_usage",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "promo_code_usage",
    "column_name": "promo_code_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "promo_code_usage",
    "column_name": "passenger_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "promo_code_usage",
    "column_name": "trip_id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "promo_code_usage",
    "column_name": "discount_applied",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "promo_code_usage",
    "column_name": "used_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "promo_codes",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "promo_codes",
    "column_name": "code",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "promo_codes",
    "column_name": "description",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "promo_codes",
    "column_name": "discount_type",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "promo_codes",
    "column_name": "discount_value",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "promo_codes",
    "column_name": "max_discount",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "promo_codes",
    "column_name": "min_trip_value",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "promo_codes",
    "column_name": "max_uses_per_user",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": "1",
    "column_comment": null
  },
  {
    "table_name": "promo_codes",
    "column_name": "valid_from",
    "data_type": "timestamp with time zone",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "promo_codes",
    "column_name": "valid_until",
    "data_type": "timestamp with time zone",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "promo_codes",
    "column_name": "usage_limit",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "promo_codes",
    "column_name": "used_count",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": "0",
    "column_comment": null
  },
  {
    "table_name": "promo_codes",
    "column_name": "target_cities",
    "data_type": "ARRAY",
    "is_nullable": "YES",
    "column_default": "'{}'::uuid[]",
    "column_comment": null
  },
  {
    "table_name": "promo_codes",
    "column_name": "target_categories",
    "data_type": "ARRAY",
    "is_nullable": "YES",
    "column_default": "'{}'::text[]",
    "column_comment": null
  },
  {
    "table_name": "promo_codes",
    "column_name": "is_first_trip_only",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "false",
    "column_comment": null
  },
  {
    "table_name": "promo_codes",
    "column_name": "is_active",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "true",
    "column_comment": null
  },
  {
    "table_name": "promo_codes",
    "column_name": "created_by",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "promo_codes",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "ratings",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "ratings",
    "column_name": "trip_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "ratings",
    "column_name": "passenger_rating",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "ratings",
    "column_name": "passenger_rating_tags",
    "data_type": "ARRAY",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "ratings",
    "column_name": "passenger_rating_comment",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "ratings",
    "column_name": "passenger_rated_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "ratings",
    "column_name": "driver_rating",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "ratings",
    "column_name": "driver_rating_tags",
    "data_type": "ARRAY",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "ratings",
    "column_name": "driver_rating_comment",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "ratings",
    "column_name": "driver_rated_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "ratings",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "ratings",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "saved_places",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "saved_places",
    "column_name": "user_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "saved_places",
    "column_name": "label",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "saved_places",
    "column_name": "address",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "saved_places",
    "column_name": "latitude",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "saved_places",
    "column_name": "longitude",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "saved_places",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "saved_places",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "saved_places",
    "column_name": "category",
    "data_type": "character varying",
    "is_nullable": "NO",
    "column_default": "'other'::character varying",
    "column_comment": "Category type for the saved place (LocationType enum)"
  },
  {
    "table_name": "trip_chats",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "trip_chats",
    "column_name": "trip_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_chats",
    "column_name": "sender_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_chats",
    "column_name": "message",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_chats",
    "column_name": "is_read",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "false",
    "column_comment": null
  },
  {
    "table_name": "trip_chats",
    "column_name": "read_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_chats",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "trip_location_history",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "trip_location_history",
    "column_name": "trip_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_location_history",
    "column_name": "latitude",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_location_history",
    "column_name": "longitude",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_location_history",
    "column_name": "speed_kmh",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_location_history",
    "column_name": "heading",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_location_history",
    "column_name": "accuracy_meters",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_location_history",
    "column_name": "recorded_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "passenger_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "origin_address",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "origin_latitude",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "origin_longitude",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "origin_neighborhood",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "destination_address",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "destination_latitude",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "destination_longitude",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "destination_neighborhood",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "vehicle_category",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "needs_pet",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "false",
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "needs_grocery_space",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "false",
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "needs_ac",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "false",
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "is_condo_origin",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "false",
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "is_condo_destination",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "false",
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "number_of_stops",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": "0",
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "status",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": "'searching'::text",
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "selected_offer_id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "expires_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "(now() + '00:00:10'::interval)",
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "target_driver_id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "fallback_drivers",
    "data_type": "ARRAY",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "accepted_by_driver_id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "accepted_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "current_fallback_index",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": "0",
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "timeout_count",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": "0",
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "estimated_distance_km",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "estimated_duration_minutes",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_requests",
    "column_name": "estimated_fare",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_status_history",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "trip_status_history",
    "column_name": "trip_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_status_history",
    "column_name": "old_status",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_status_history",
    "column_name": "new_status",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_status_history",
    "column_name": "changed_by",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_status_history",
    "column_name": "reason",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_status_history",
    "column_name": "metadata",
    "data_type": "jsonb",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_status_history",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "trip_stops",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "trip_stops",
    "column_name": "trip_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_stops",
    "column_name": "stop_order",
    "data_type": "integer",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_stops",
    "column_name": "address",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_stops",
    "column_name": "latitude",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_stops",
    "column_name": "longitude",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_stops",
    "column_name": "arrived_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_stops",
    "column_name": "departed_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trip_stops",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "trip_code",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "request_id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "passenger_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "driver_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "status",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "origin_address",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "origin_latitude",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "origin_longitude",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "origin_neighborhood",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "destination_address",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "destination_latitude",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "destination_longitude",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "destination_neighborhood",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "vehicle_category",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "needs_pet",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "false",
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "needs_grocery_space",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "false",
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "is_condo_destination",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "false",
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "is_condo_origin",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "false",
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "needs_ac",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "false",
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "number_of_stops",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": "0",
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "route_polyline",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "estimated_distance_km",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "estimated_duration_minutes",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "driver_to_pickup_distance_km",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "driver_to_pickup_duration_minutes",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "actual_distance_km",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "actual_duration_minutes",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "waiting_time_minutes",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "driver_distance_traveled_km",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "base_fare",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "additional_fees",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": "0",
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "surge_multiplier",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": "1.0",
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "total_fare",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "platform_commission",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "driver_earnings",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "cancellation_reason",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "cancellation_fee",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "cancelled_by",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "driver_assigned_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "driver_arrived_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "trip_started_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "trip_completed_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "cancelled_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "payment_status",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": "'pending'::text",
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "payment_id",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "payment_completed_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "promo_code_id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "trips",
    "column_name": "discount_applied",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "user_devices",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "user_devices",
    "column_name": "user_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "user_devices",
    "column_name": "device_token",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "user_devices",
    "column_name": "platform",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "user_devices",
    "column_name": "device_model",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "user_devices",
    "column_name": "app_version",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "user_devices",
    "column_name": "os_version",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "user_devices",
    "column_name": "is_active",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "true",
    "column_comment": null
  },
  {
    "table_name": "user_devices",
    "column_name": "last_used_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "user_devices",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "user_devices",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "wallet_transactions",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "wallet_transactions",
    "column_name": "wallet_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "wallet_transactions",
    "column_name": "type",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "wallet_transactions",
    "column_name": "amount",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "wallet_transactions",
    "column_name": "description",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "wallet_transactions",
    "column_name": "reference_type",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "wallet_transactions",
    "column_name": "reference_id",
    "data_type": "uuid",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "wallet_transactions",
    "column_name": "balance_after",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "wallet_transactions",
    "column_name": "status",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": "'completed'::text",
    "column_comment": null
  },
  {
    "table_name": "wallet_transactions",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "withdrawals",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()",
    "column_comment": null
  },
  {
    "table_name": "withdrawals",
    "column_name": "driver_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "withdrawals",
    "column_name": "wallet_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "withdrawals",
    "column_name": "amount",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "withdrawals",
    "column_name": "withdrawal_method",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "withdrawals",
    "column_name": "bank_account_info",
    "data_type": "jsonb",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "withdrawals",
    "column_name": "asaas_transfer_id",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "withdrawals",
    "column_name": "status",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": "'pending'::text",
    "column_comment": null
  },
  {
    "table_name": "withdrawals",
    "column_name": "failure_reason",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "withdrawals",
    "column_name": "requested_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()",
    "column_comment": null
  },
  {
    "table_name": "withdrawals",
    "column_name": "processed_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  },
  {
    "table_name": "withdrawals",
    "column_name": "completed_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null,
    "column_comment": null
  }
]