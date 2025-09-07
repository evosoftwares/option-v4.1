-- Update schema to match production environment
-- Remove problematic ownership statements that cause errors

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";
CREATE EXTENSION IF NOT EXISTS "pgsodium";
CREATE SCHEMA IF NOT EXISTS "pgmq_public";
ALTER SCHEMA "pgmq_public" OWNER TO "postgres";
ALTER SCHEMA "public" OWNER TO "postgres";
CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "public";
CREATE EXTENSION IF NOT EXISTS "pgmq" WITH SCHEMA "pgmq";
CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";

-- Create types
CREATE TYPE "public"."approval_status_enum" AS ENUM (
    'pending',
    'approved',
    'rejected'
);

-- Note: Changed ownership from "supabase_read_only_user" to "postgres" to avoid errors
ALTER TYPE "public"."approval_status_enum" OWNER TO "postgres";

-- Rest of the schema would go here, but we'll apply it incrementally to avoid issues