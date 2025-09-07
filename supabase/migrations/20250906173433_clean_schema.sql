

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


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";










CREATE EXTENSION IF NOT EXISTS "pgsodium";








ALTER SCHEMA "public" OWNER TO "postgres";


CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "public";












CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."approval_status_enum" AS ENUM (
    'pending',
    'approved',
    'rejected'
);


ALTER TYPE "public"."approval_status_enum" OWNER TO "supabase_read_only_user";


    LANGUAGE "plpgsql"
    SET "search_path" TO ''







    LANGUAGE "plpgsql"
    SET "search_path" TO ''







    LANGUAGE "plpgsql"
    SET "search_path" TO ''







    LANGUAGE "plpgsql"
    SET "search_path" TO ''







    LANGUAGE "plpgsql"
    SET "search_path" TO ''







    LANGUAGE "plpgsql"
    SET "search_path" TO ''







CREATE OR REPLACE FUNCTION "public"."add_driver_earnings"("driver_user_id" "uuid", "amount" numeric, "description" "text" DEFAULT NULL::"text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    wallet_id UUID;
    driver_id_val UUID;
BEGIN
    -- Buscar o driver_id
    SELECT id INTO driver_id_val FROM drivers WHERE user_id = driver_user_id;
    
    IF driver_id_val IS NULL THEN
        RAISE EXCEPTION 'Motorista não encontrado para o usuário %', driver_user_id;
    END IF;

    -- Criar ou atualizar carteira do motorista
    INSERT INTO driver_wallets (driver_id, available_balance, total_earned, created_at, updated_at)
    VALUES (driver_id_val, amount, amount, NOW(), NOW())
    ON CONFLICT (driver_id) 
    DO UPDATE SET 
        available_balance = driver_wallets.available_balance + amount,
        total_earned = driver_wallets.total_earned + amount,
        updated_at = NOW();

    -- Registrar transação
    INSERT INTO wallet_transactions (wallet_id, amount, type, description, status, created_at)
    VALUES (driver_id_val, amount, 'cancellation_compensation', 
            COALESCE(description, 'Compensação por cancelamento'), 'completed', NOW());
END;
$$;


ALTER FUNCTION "public"."add_driver_earnings"("driver_user_id" "uuid", "amount" numeric, "description" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."archive_old_trips"() RETURNS integer
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_count INTEGER;
BEGIN
    -- Criar tabela de arquivo se não existir
    CREATE TABLE IF NOT EXISTS trips_archive (LIKE trips INCLUDING ALL);
    
    -- Mover viagens com mais de 6 meses
    WITH moved AS (
        DELETE FROM trips
        WHERE created_at < NOW() - INTERVAL '6 months'
        AND status IN ('completed', 'cancelled_by_passenger', 'cancelled_by_driver')
        RETURNING *
    )
    INSERT INTO trips_archive SELECT * FROM moved;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$;


ALTER FUNCTION "public"."archive_old_trips"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."batch_correct_corrupted_users"("max_corrections" integer DEFAULT 10, "dry_run" boolean DEFAULT true) RETURNS "json"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    corrupted_user RECORD;
    correction_result json;
    corrections_applied INTEGER := 0;
    corrections_results json[] := '{}';
    total_found INTEGER;
BEGIN
    -- Contar total de usuários corrompidos
    SELECT COUNT(*) INTO total_found
    FROM identify_corrupted_users()
    WHERE corruption_confidence > 0.8; -- Apenas alta confiança
    
    RAISE NOTICE 'CORREÇÃO EM LOTE: % usuários corrompidos encontrados', total_found;
    
    -- Processar usuários corrompidos em lote limitado
    FOR corrupted_user IN 
        SELECT * FROM identify_corrupted_users()
        WHERE corruption_confidence > 0.8
        ORDER BY corruption_confidence DESC
        LIMIT max_corrections
    LOOP
        -- Aplicar correção individual
        SELECT safe_correct_user_data(
            corrupted_user.user_id,
            CASE 
                WHEN corrupted_user.corruption_type LIKE '%_name' 
                THEN corrupted_user.suggested_fix
                ELSE NULL
            END,
            CASE 
                WHEN corrupted_user.corruption_type LIKE '%_phone' 
                THEN corrupted_user.suggested_fix
                ELSE NULL
            END,
            dry_run
        ) INTO correction_result;
        
        corrections_results := array_append(corrections_results, correction_result);
        
        IF NOT dry_run AND (correction_result->>'status') = 'success' THEN
            corrections_applied := corrections_applied + 1;
        END IF;
        
    END LOOP;
    
    RETURN json_build_object(
        'status', CASE WHEN dry_run THEN 'dry_run_completed' ELSE 'batch_completed' END,
        'total_found', total_found,
        'corrections_processed', array_length(corrections_results, 1),
        'corrections_applied', corrections_applied,
        'results', corrections_results,
        'timestamp', NOW()
    );
END;
$$;


ALTER FUNCTION "public"."batch_correct_corrupted_users"("max_corrections" integer, "dry_run" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."calculate_cancellation_fee"("p_trip_id" "uuid", "p_driver_current_lat" numeric, "p_driver_current_lng" numeric) RETURNS numeric
    LANGUAGE "plpgsql"
    AS $_$
DECLARE
   v_total_fare DECIMAL;
   v_origin_lat DECIMAL;
   v_origin_lng DECIMAL;
   v_distance_traveled DECIMAL;
   v_total_distance DECIMAL;
   v_base_fee DECIMAL;
   v_factor DECIMAL;
   v_final_fee DECIMAL;
BEGIN
   -- Buscar dados da viagem
   SELECT 
       total_fare,
       origin_latitude,
       origin_longitude,
       driver_to_pickup_distance_km
   INTO 
       v_total_fare,
       v_origin_lat,
       v_origin_lng,
       v_total_distance
   FROM trips
   WHERE id = p_trip_id;
   
   -- Calcular distância já percorrida pelo motorista
   v_distance_traveled := 6371 * acos(
       LEAST(1, GREATEST(-1,
           cos(radians(v_origin_lat)) * cos(radians(p_driver_current_lat)) *
           cos(radians(p_driver_current_lng) - radians(v_origin_lng)) +
           sin(radians(v_origin_lat)) * sin(radians(p_driver_current_lat))
       ))
   );
   
   -- Calcular multa base (20% do valor total, máximo R$ 10)
   v_base_fee := LEAST(v_total_fare * 0.20, 10.00);
   
   -- Calcular fator de deslocamento
   IF v_total_distance > 0 THEN
       v_factor := v_distance_traveled / v_total_distance;
       -- Limitar fator entre 0 e 1
       v_factor := LEAST(GREATEST(v_factor, 0), 1);
   ELSE
       v_factor := 0;
   END IF;
   
   -- Calcular taxa final
   v_final_fee := v_base_fee * v_factor;
   
   RETURN ROUND(v_final_fee::numeric, 2);
END;
$_$;


ALTER FUNCTION "public"."calculate_cancellation_fee"("p_trip_id" "uuid", "p_driver_current_lat" numeric, "p_driver_current_lng" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_and_suspend_user"("p_profile_id" "uuid", "p_user_type" "text") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
   v_consecutive_cancellations INTEGER;
   v_user_id UUID;
BEGIN
   IF p_user_type = 'driver' THEN
       SELECT consecutive_cancellations, user_id
       INTO v_consecutive_cancellations, v_user_id
       FROM drivers
       WHERE id = p_profile_id;
   ELSE
       SELECT consecutive_cancellations, user_id
       INTO v_consecutive_cancellations, v_user_id
       FROM passengers
       WHERE id = p_profile_id;
   END IF;
   
   -- Suspender se atingir 3 cancelamentos consecutivos
   IF v_consecutive_cancellations >= 3 THEN
       UPDATE app_users
       SET status = 'suspended'
       WHERE id = v_user_id;
       
       -- Criar notificação
       INSERT INTO notifications (
           user_id,
           title,
           body,
           type,
           priority
       ) VALUES (
           v_user_id,
           'Conta Suspensa',
           'Sua conta foi temporariamente suspensa devido a múltiplos cancelamentos consecutivos. Entre em contato com o suporte.',
           'system',
           'high'
       );
       
       -- Registrar no log
       INSERT INTO activity_logs (
           user_id,
           action,
           entity_type,
           entity_id,
           metadata
       ) VALUES (
           v_user_id,
           'account_suspended',
           'user',
           v_user_id,
           jsonb_build_object('reason', 'consecutive_cancellations', 'count', v_consecutive_cancellations)
       );
   END IF;
END;
$$;


ALTER FUNCTION "public"."check_and_suspend_user"("p_profile_id" "uuid", "p_user_type" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_and_update_driver_approval_status"("p_driver_id" "uuid") RETURNS "json"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_current_status TEXT;
    v_required_docs TEXT[] := ARRAY['CNH_FRONT', 'CNH_BACK', 'CRLV', 'VEHICLE_FRONT'];
    v_approved_docs JSONB := '[]'::JSONB;
    v_doc_record RECORD;
    v_all_approved BOOLEAN := TRUE;
    v_missing_docs TEXT[] := ARRAY[]::TEXT[];
    v_result JSON;
BEGIN
    -- Log início da verificação
    RAISE NOTICE 'check_and_update_driver_approval_status: Iniciando verificação para driver_id=%', p_driver_id;
    
    -- Buscar status atual do motorista
    SELECT approval_status INTO v_current_status
    FROM drivers 
    WHERE id = p_driver_id;
    
    IF v_current_status IS NULL THEN
        RAISE NOTICE 'check_and_update_driver_approval_status: Driver não encontrado: %', p_driver_id;
        RETURN json_build_object(
            'success', false, 
            'message', 'Driver não encontrado',
            'driver_id', p_driver_id
        );
    END IF;
    
    RAISE NOTICE 'check_and_update_driver_approval_status: Status atual = %', v_current_status;
    
    -- Se já está aprovado, não precisa verificar
    IF v_current_status = 'approved' THEN
        RAISE NOTICE 'check_and_update_driver_approval_status: Driver já aprovado, finalizando';
        RETURN json_build_object(
            'success', true, 
            'message', 'Driver já estava aprovado',
            'status', 'approved',
            'driver_id', p_driver_id
        );
    END IF;
    
    -- Verificar cada documento obrigatório
    RAISE NOTICE 'check_and_update_driver_approval_status: Verificando documentos obrigatórios...';
    
    FOR i IN 1..array_length(v_required_docs, 1) LOOP
        DECLARE
            v_doc_type TEXT := v_required_docs[i];
            v_doc_found BOOLEAN := FALSE;
        BEGIN
            -- Verificar se existe documento aprovado deste tipo
            SELECT EXISTS(
                SELECT 1 FROM driver_documents 
                WHERE driver_id = p_driver_id 
                AND document_type = v_doc_type 
                AND status = 'approved' 
                AND is_current = true
            ) INTO v_doc_found;
            
            RAISE NOTICE 'check_and_update_driver_approval_status: Documento % = %', v_doc_type, 
                CASE WHEN v_doc_found THEN 'APROVADO' ELSE 'FALTANDO/PENDENTE' END;
            
            IF v_doc_found THEN
                -- Adicionar documento aprovado à lista
                v_approved_docs := v_approved_docs || json_build_object(
                    'type', v_doc_type,
                    'status', 'approved',
                    'verified_at', NOW()
                )::JSONB;
            ELSE
                v_all_approved := FALSE;
                v_missing_docs := array_append(v_missing_docs, v_doc_type);
            END IF;
        END;
    END LOOP;
    
    RAISE NOTICE 'check_and_update_driver_approval_status: Todos documentos aprovados = %', v_all_approved;
    RAISE NOTICE 'check_and_update_driver_approval_status: Documentos faltando = %', v_missing_docs;
    
    -- Se todos os documentos obrigatórios estão aprovados, aprovar motorista
    IF v_all_approved THEN
        RAISE NOTICE 'check_and_update_driver_approval_status: ✅ APROVANDO MOTORISTA AUTOMATICAMENTE!';
        
        -- Atualizar status do motorista
        UPDATE drivers 
        SET approval_status = 'approved',
            approved_at = NOW(),
            approved_by = NULL  -- Sistema automático não tem user_id
        WHERE id = p_driver_id;
        
        -- Registrar na auditoria
        INSERT INTO driver_approval_audit (
            driver_id, 
            old_status, 
            new_status, 
            reason, 
            approved_documents
        ) VALUES (
            p_driver_id,
            v_current_status,
            'approved',
            'APROVAÇÃO AUTOMÁTICA: Sistema verificou que todos os 4 documentos obrigatórios estão aprovados (CNH_FRONT, CNH_BACK, CRLV, VEHICLE_FRONT)',
            v_approved_docs
        );
        
        RAISE NOTICE 'check_and_update_driver_approval_status: ✅ MOTORISTA APROVADO COM SUCESSO!';
        
        v_result := json_build_object(
            'success', true,
            'message', 'Motorista aprovado automaticamente!',
            'old_status', v_current_status,
            'new_status', 'approved',
            'approved_documents', v_approved_docs,
            'driver_id', p_driver_id
        );
    ELSE
        RAISE NOTICE 'check_and_update_driver_approval_status: ❌ Motorista ainda não pode ser aprovado';
        
        v_result := json_build_object(
            'success', false,
            'message', 'Documentos ainda pendentes',
            'current_status', v_current_status,
            'missing_documents', v_missing_docs,
            'approved_documents', v_approved_docs,
            'driver_id', p_driver_id
        );
    END IF;
    
    RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."check_and_update_driver_approval_status"("p_driver_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_driver_documents_approved"("driver_uuid" "uuid") RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Verificar se todos os documentos obrigatórios estão aprovados
    RETURN (
        -- CNH_FRONT aprovado
        EXISTS (
            SELECT 1 FROM driver_documents
            WHERE driver_id = driver_uuid
            AND document_type = 'CNH_FRONT'
            AND status = 'approved'
            AND is_current = true
        )
        AND
        -- CNH_BACK aprovado
        EXISTS (
            SELECT 1 FROM driver_documents
            WHERE driver_id = driver_uuid
            AND document_type = 'CNH_BACK'
            AND status = 'approved'
            AND is_current = true
        )
        AND
        -- CRLV aprovado
        EXISTS (
            SELECT 1 FROM driver_documents
            WHERE driver_id = driver_uuid
            AND document_type = 'CRLV'
            AND status = 'approved'
            AND is_current = true
        )
        AND
        -- VEHICLE_FRONT aprovado
        EXISTS (
            SELECT 1 FROM driver_documents
            WHERE driver_id = driver_uuid
            AND document_type = 'VEHICLE_FRONT'
            AND status = 'approved'
            AND is_current = true
        )
    );
END;
$$;


ALTER FUNCTION "public"."check_driver_documents_approved"("driver_uuid" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_migration_health"() RETURNS "json"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    integrity_result json;
    integrity_score DECIMAL;
    issues_count INTEGER;
    should_rollback BOOLEAN := FALSE;
    result json;
BEGIN
    -- Verificar integridade atual
    SELECT validate_data_integrity() INTO integrity_result;
    
    integrity_score := (integrity_result->>'integrity_score')::DECIMAL;
    issues_count := array_length(
        ARRAY(SELECT json_array_elements_text(integrity_result->'issues')), 1
    );
    
    -- Critérios para rollback automático
    IF integrity_score < 95.0 OR issues_count > 5 THEN
        should_rollback := TRUE;
        RAISE WARNING 'CIRCUIT BREAKER ATIVADO: Score=%, Issues=%', integrity_score, issues_count;
    END IF;
    
    result := json_build_object(
        'integrity_score', integrity_score,
        'issues_count', COALESCE(issues_count, 0),
        'should_rollback', should_rollback,
        'status', CASE 
            WHEN should_rollback THEN 'CRITICAL'
            WHEN integrity_score < 98.0 THEN 'WARNING'
            ELSE 'HEALTHY'
        END,
        'timestamp', NOW()
    );
    
    RETURN result;
END;
$$;


ALTER FUNCTION "public"."check_migration_health"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_suspension_policy"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    -- Para passageiros
    IF TG_TABLE_NAME = 'passengers' AND NEW.consecutive_cancellations >= 3 THEN
        UPDATE app_users 
        SET status = 'suspended', 
            updated_at = NOW()
        WHERE id = NEW.user_id AND status != 'suspended';
        
        -- Inserir log de suspensão
        INSERT INTO activity_logs (user_id, action, entity_type, entity_id, metadata, created_at)
        VALUES (NEW.user_id, 'user_suspended', 'passenger', NEW.user_id, 
                jsonb_build_object('reason', 'consecutive_cancellations', 'count', NEW.consecutive_cancellations),
                NOW());
    END IF;

    -- Para motoristas
    IF TG_TABLE_NAME = 'drivers' AND NEW.consecutive_cancellations >= 3 THEN
        UPDATE app_users 
        SET status = 'suspended',
            updated_at = NOW()
        WHERE id = NEW.user_id AND status != 'suspended';
        
        -- Inserir log de suspensão
        INSERT INTO activity_logs (user_id, action, entity_type, entity_id, metadata, created_at)
        VALUES (NEW.user_id, 'user_suspended', 'driver', NEW.id,
                jsonb_build_object('reason', 'consecutive_cancellations', 'count', NEW.consecutive_cancellations),
                NOW());
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."check_suspension_policy"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cleanup_expired_requests"() RETURNS integer
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_count INTEGER;
BEGIN
    UPDATE trip_requests
    SET status = 'expired'
    WHERE status = 'searching'
    AND expires_at < NOW();
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$;


ALTER FUNCTION "public"."cleanup_expired_requests"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cleanup_migration_backup"() RETURNS "json"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    DROP TABLE IF EXISTS backup_app_users_migration;
    DROP TABLE IF EXISTS backup_passengers_migration;
    DROP TABLE IF EXISTS backup_drivers_migration;
    
    RETURN json_build_object(
        'status', 'cleanup_completed',
        'timestamp', NOW(),
        'message', 'Tabelas de backup removidas com sucesso'
    );
END;
$$;


ALTER FUNCTION "public"."cleanup_migration_backup"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."controlled_sync_auth_to_app"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Verificar se sincronização está habilitada
    IF is_sync_enabled('auth_to_app_sync') THEN
        RETURN sync_auth_to_app_users();
    END IF;
    
    -- Log de sincronização desabilitada
    INSERT INTO auth_sync_logs (
        event_type,
        user_id,
        operation,
        source_table,
        target_table,
        error_message,
        sync_status
    ) VALUES (
        TG_OP || '_auth_user',
        COALESCE(NEW.id, OLD.id),
        'sync_disabled',
        'auth.users',
        'app_users',
        'Sincronização desabilitada por feature flag',
        'skipped'
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION "public"."controlled_sync_auth_to_app"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_migration_backup"() RETURNS "json"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    app_users_count INTEGER;
    passengers_count INTEGER;  
    drivers_count INTEGER;
    result json;
BEGIN
    -- Limpar backups anteriores
    TRUNCATE backup_app_users_migration;
    TRUNCATE backup_passengers_migration;
    TRUNCATE backup_drivers_migration;
    
    -- Fazer backup das tabelas
    INSERT INTO backup_app_users_migration SELECT * FROM app_users;
    INSERT INTO backup_passengers_migration SELECT * FROM passengers;
    INSERT INTO backup_drivers_migration SELECT * FROM drivers;
    
    -- Contar registros copiados
    SELECT COUNT(*) INTO app_users_count FROM backup_app_users_migration;
    SELECT COUNT(*) INTO passengers_count FROM backup_passengers_migration;  
    SELECT COUNT(*) INTO drivers_count FROM backup_drivers_migration;
    
    result := json_build_object(
        'status', 'success',
        'timestamp', NOW(),
        'app_users_backed_up', app_users_count,
        'passengers_backed_up', passengers_count,
        'drivers_backed_up', drivers_count
    );
    
    RAISE NOTICE 'BACKUP COMPLETO: % usuários, % passageiros, % motoristas', 
                 app_users_count, passengers_count, drivers_count;
                 
    RETURN result;
END;
$$;


ALTER FUNCTION "public"."create_migration_backup"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_passenger_wallet_on_passenger_insert"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    INSERT INTO passenger_wallets (passenger_id, user_id, available_balance, pending_balance, total_spent, total_cashback)
    VALUES (NEW.id, NEW.user_id, 0.00, 0.00, 0.00, 0.00)
    ON CONFLICT (passenger_id) DO NOTHING; -- idempotent safeguard
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."create_passenger_wallet_on_passenger_insert"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."data_correction_summary"() RETURNS "json"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    result json;
BEGIN
    SELECT json_build_object(
        'corrupted_users_found', (
            SELECT COUNT(*) 
            FROM identify_corrupted_users() 
            WHERE corruption_confidence > 0.8
        ),
        'corrections_applied', (
            SELECT COUNT(*) 
            FROM corrupted_users_backup 
            WHERE restored = FALSE
        ),
        'corrections_restored', (
            SELECT COUNT(*) 
            FROM corrupted_users_backup 
            WHERE restored = TRUE
        ),
        'last_correction', (
            SELECT MAX(correction_timestamp) 
            FROM corrupted_users_backup
        ),
        'timestamp', NOW()
    ) INTO result;
    
    RETURN result;
END;
$$;


ALTER FUNCTION "public"."data_correction_summary"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."delete_profile"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    DELETE FROM public.app_users WHERE id = OLD.id;
    RETURN OLD;
END;
$$;


ALTER FUNCTION "public"."delete_profile"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."delete_profile"() IS 'Função para deletar dados via view profiles';



CREATE OR REPLACE FUNCTION "public"."diagnose_signup_issues_safe"() RETURNS "json"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    result json;
BEGIN
    SELECT json_build_object(
        'timestamp', NOW(),
        'rls_status', json_build_object(
            'auth_sync_logs', (
                SELECT rowsecurity 
                FROM pg_tables 
                WHERE tablename = 'auth_sync_logs' AND schemaname = 'public'
            ),
            'sync_control', (
                SELECT rowsecurity 
                FROM pg_tables 
                WHERE tablename = 'sync_control' AND schemaname = 'public'
            ),
            'app_users', (
                SELECT rowsecurity 
                FROM pg_tables 
                WHERE tablename = 'app_users' AND schemaname = 'public'
            )
        ),
        'sync_control_status', (
            SELECT json_agg(
                json_build_object(
                    'feature', feature_name,
                    'enabled', enabled,
                    'updated_at', updated_at
                )
            )
            FROM sync_control
        ),
        'recent_errors', (
            SELECT json_agg(
                json_build_object(
                    'event_type', event_type,
                    'operation', operation,
                    'error_message', error_message,
                    'created_at', created_at
                )
            )
            FROM (
                SELECT * FROM auth_sync_logs 
                WHERE sync_status = 'failed' 
                ORDER BY created_at DESC 
                LIMIT 5
            ) recent_errors
        )
    ) INTO result;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'error', SQLERRM,
            'timestamp', NOW()
        );
END;
$$;


ALTER FUNCTION "public"."diagnose_signup_issues_safe"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."disable_auth_sync"("feature_name" "text" DEFAULT 'both'::"text") RETURNS "json"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    IF feature_name = 'both' THEN
        UPDATE sync_control SET enabled = FALSE, updated_at = NOW()
        WHERE feature_name IN ('auth_to_app_sync', 'app_to_auth_sync');
    ELSE
        UPDATE sync_control SET enabled = FALSE, updated_at = NOW()
        WHERE sync_control.feature_name = disable_auth_sync.feature_name;
    END IF;
    
    RETURN json_build_object(
        'status', 'disabled',
        'feature', feature_name,
        'timestamp', NOW()
    );
END;
$$;


ALTER FUNCTION "public"."disable_auth_sync"("feature_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."enable_auth_sync"("feature_name" "text" DEFAULT 'both'::"text") RETURNS "json"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    IF feature_name = 'both' THEN
        UPDATE sync_control SET enabled = TRUE, updated_at = NOW()
        WHERE feature_name IN ('auth_to_app_sync', 'app_to_auth_sync');
    ELSE
        UPDATE sync_control SET enabled = TRUE, updated_at = NOW()
        WHERE sync_control.feature_name = enable_auth_sync.feature_name;
    END IF;
    
    RETURN json_build_object(
        'status', 'enabled',
        'feature', feature_name,
        'timestamp', NOW()
    );
END;
$$;


ALTER FUNCTION "public"."enable_auth_sync"("feature_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."execute_migration_rollback"() RETURNS "json"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    app_users_restored INTEGER;
    passengers_restored INTEGER;
    drivers_restored INTEGER;
    result json;
BEGIN
    RAISE NOTICE 'INICIANDO ROLLBACK COMPLETO...';
    
    -- Desabilitar triggers temporariamente para evitar cascata
    SET session_replication_role = replica;
    
    -- Restaurar tabelas na ordem correta (dependências)
    TRUNCATE app_users CASCADE;
    TRUNCATE passengers CASCADE;
    TRUNCATE drivers CASCADE;
    
    -- Restaurar dados do backup
    INSERT INTO app_users SELECT * FROM backup_app_users_migration;
    INSERT INTO passengers SELECT * FROM backup_passengers_migration;
    INSERT INTO drivers SELECT * FROM backup_drivers_migration;
    
    -- Reabilitar triggers
    SET session_replication_role = DEFAULT;
    
    -- Contar registros restaurados
    SELECT COUNT(*) INTO app_users_restored FROM app_users;
    SELECT COUNT(*) INTO passengers_restored FROM passengers;
    SELECT COUNT(*) INTO drivers_restored FROM drivers;
    
    result := json_build_object(
        'status', 'rollback_completed',
        'timestamp', NOW(),
        'app_users_restored', app_users_restored,
        'passengers_restored', passengers_restored,
        'drivers_restored', drivers_restored
    );
    
    RAISE NOTICE 'ROLLBACK COMPLETO: % usuários, % passageiros, % motoristas restaurados', 
                 app_users_restored, passengers_restored, drivers_restored;
                 
    RETURN result;
END;
$$;


ALTER FUNCTION "public"."execute_migration_rollback"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."find_available_drivers"("p_request_id" "uuid", "p_origin_lat" numeric, "p_origin_lng" numeric, "p_dest_lat" numeric, "p_dest_lng" numeric, "p_category" "text", "p_needs_pet" boolean, "p_needs_grocery" boolean, "p_needs_ac" boolean, "p_is_condo_origin" boolean, "p_is_condo_dest" boolean, "p_stops" integer, "p_origin_neighborhood" "text", "p_dest_neighborhood" "text") RETURNS TABLE("driver_id" "uuid", "driver_name" "text", "driver_photo" "text", "driver_rating" numeric, "total_trips" integer, "vehicle_info" "text", "distance_km" numeric, "eta_minutes" integer, "base_fare" numeric, "additional_fees" numeric, "total_fare" numeric)
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_base_km DECIMAL;
    v_base_min DECIMAL;
BEGIN
    -- Buscar valores base da categoria
    SELECT base_price_per_km, base_price_per_minute 
    INTO v_base_km, v_base_min
    FROM platform_settings 
    WHERE category = p_category;

    RETURN QUERY
    WITH eligible_drivers AS (
        SELECT 
            d.id,
            u.full_name,
            u.photo_url,
            d.average_rating,
            d.total_trips,
            d.vehicle_brand || ' ' || d.vehicle_model || ' ' || d.vehicle_year || ' - ' || d.vehicle_color as vehicle,
            -- Cálculo de distância usando Haversine
            6371 * acos(
                LEAST(1, GREATEST(-1,
                    cos(radians(p_origin_lat)) * cos(radians(d.current_latitude)) *
                    cos(radians(d.current_longitude) - radians(p_origin_lng)) +
                    sin(radians(p_origin_lat)) * sin(radians(d.current_latitude))
                ))
            ) as driver_distance,
            COALESCE(d.custom_price_per_km, v_base_km) as price_km,
            COALESCE(d.custom_price_per_minute, v_base_min) as price_min,
            d.pet_fee,
            d.grocery_fee,
            d.condo_fee,
            d.stop_fee
        FROM drivers d
        JOIN app_users u ON d.user_id = u.id
        WHERE d.is_online = true
            AND d.approval_status = 'approved'
            AND u.status = 'active'
            AND d.vehicle_category = p_category
            -- Verificar prefer-- Verificar preferências
           AND (NOT p_needs_pet OR d.accepts_pet = true)
           AND (NOT p_needs_grocery OR d.accepts_grocery = true)
           AND (NOT p_needs_ac OR d.ac_policy IN ('always_on', 'on_request'))
           AND (NOT p_is_condo_origin OR d.accepts_condo = true)
           AND (NOT p_is_condo_dest OR d.accepts_condo = true)
           -- Excluir zonas não atendidas
           AND NOT EXISTS (
               SELECT 1 FROM driver_excluded_zones dez
               WHERE dez.driver_id = d.id
               AND (dez.neighborhood_name = p_origin_neighborhood 
                    OR dez.neighborhood_name = p_dest_neighborhood)
           )
   ),
   drivers_with_calculation AS (
       SELECT 
           *,
           -- Calcular distância total da viagem
           6371 * acos(
               LEAST(1, GREATEST(-1,
                   cos(radians(p_origin_lat)) * cos(radians(p_dest_lat)) *
                   cos(radians(p_dest_lng) - radians(p_origin_lng)) +
                   sin(radians(p_origin_lat)) * sin(radians(p_dest_lat))
               ))
           ) as trip_distance,
           -- ETA do motorista até o passageiro (3 min por km em média)
           CEIL(driver_distance * 3)::INTEGER as driver_eta
       FROM eligible_drivers
       WHERE driver_distance <= 10 -- Raio máximo de 10km
   ),
   final_calculation AS (
       SELECT 
           id,
           full_name,
           photo_url,
           average_rating,
           total_trips,
           vehicle,
           driver_distance,
           driver_eta,
           -- Cálculo do preço base
           ((driver_distance + trip_distance) * price_km) + 
           ((driver_eta + (trip_distance * 3)) * price_min) as base_price,
           -- Cálculo das taxas adicionais
           (CASE WHEN p_needs_pet THEN pet_fee ELSE 0 END) +
           (CASE WHEN p_needs_grocery THEN grocery_fee ELSE 0 END) +
           (CASE WHEN p_is_condo_origin OR p_is_condo_dest THEN condo_fee ELSE 0 END) +
           (stop_fee * p_stops) as additional_fees
       FROM drivers_with_calculation
   )
   SELECT 
       id,
       full_name,
       photo_url,
       average_rating,
       total_trips,
       vehicle,
       ROUND(driver_distance::numeric, 2),
       driver_eta,
       ROUND(base_price::numeric, 2),
       ROUND(additional_fees::numeric, 2),
       ROUND((base_price + additional_fees)::numeric, 2)
   FROM final_calculation
   ORDER BY driver_distance ASC
   LIMIT 10;
END;
$$;


ALTER FUNCTION "public"."find_available_drivers"("p_request_id" "uuid", "p_origin_lat" numeric, "p_origin_lng" numeric, "p_dest_lat" numeric, "p_dest_lng" numeric, "p_category" "text", "p_needs_pet" boolean, "p_needs_grocery" boolean, "p_needs_ac" boolean, "p_is_condo_origin" boolean, "p_is_condo_dest" boolean, "p_stops" integer, "p_origin_neighborhood" "text", "p_dest_neighborhood" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fix_existing_pending_drivers"() RETURNS TABLE("driver_id" "uuid", "old_status" "text", "new_status" "text", "message" "text")
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_driver RECORD;
    v_result JSON;
    v_count INTEGER := 0;
BEGIN
    RAISE NOTICE 'fix_existing_pending_drivers: Iniciando correção de motoristas pendentes...';
    
    -- Buscar todos os motoristas com status pending
    FOR v_driver IN 
        SELECT d.id, d.approval_status
        FROM drivers d
        WHERE d.approval_status = 'pending'
        ORDER BY d.created_at
    LOOP
        RAISE NOTICE 'fix_existing_pending_drivers: Verificando driver %', v_driver.id;
        
        -- Verificar se pode ser aprovado
        SELECT check_and_update_driver_approval_status(v_driver.id) INTO v_result;
        
        v_count := v_count + 1;
        
        -- Retornar resultado para cada driver
        driver_id := v_driver.id;
        old_status := v_driver.approval_status;
        new_status := COALESCE((v_result->>'new_status')::TEXT, 'pending');
        message := (v_result->>'message')::TEXT;
        
        RETURN NEXT;
    END LOOP;
    
    RAISE NOTICE 'fix_existing_pending_drivers: ✅ Processados % motoristas', v_count;
END;
$$;


ALTER FUNCTION "public"."fix_existing_pending_drivers"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_trip_code"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.trip_code := 'TRP-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                     LPAD(nextval('trip_code_seq')::TEXT, 6, '0');
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."generate_trip_code"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_active_override"("p_driver_id" "uuid") RETURNS TABLE("override_id" "uuid", "override_start" timestamp with time zone, "override_end" timestamp with time zone, "reason" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dso.id,
        dso.override_start,
        dso.override_end,
        dso.reason
    FROM driver_schedule_overrides dso
    WHERE dso.driver_id = p_driver_id
      AND dso.is_active = true
      AND now() >= dso.override_start
      AND now() <= dso.override_end
    ORDER BY dso.created_at DESC
    LIMIT 1;
END;
$$;


ALTER FUNCTION "public"."get_active_override"("p_driver_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_available_categories_stats"("lat" double precision, "lng" double precision, "radius_km" double precision DEFAULT 10.0) RETURNS TABLE("vehicle_category" "text", "driver_count" integer, "avg_price_per_km" numeric, "avg_price_per_minute" numeric, "avg_distance_km" numeric)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  lat_delta float8;
  lng_delta float8;
BEGIN
  -- Calcula deltas aproximados para bounding box (aproximação rápida)
  lat_delta := radius_km / 111.0; -- ~111km por grau de latitude
  lng_delta := radius_km / (111.0 * cos(radians(lat))); -- ajustado pela longitude
  
  RETURN QUERY
  SELECT 
    d.vehicle_category,
    COUNT(*)::integer as driver_count,
    AVG(CASE 
      WHEN d.custom_price_per_km IS NOT NULL AND d.custom_price_per_km > 0 
      THEN d.custom_price_per_km 
      ELSE 1.5 -- preço padrão 
    END)::numeric as avg_price_per_km,
    AVG(CASE 
      WHEN d.custom_price_per_minute IS NOT NULL AND d.custom_price_per_minute > 0 
      THEN d.custom_price_per_minute 
      ELSE 0.20 -- preço padrão 
    END)::numeric as avg_price_per_minute,
    -- Distância média aproximada (pode ser melhorada com cálculo real de distância)
    AVG(
      SQRT(
        POW((d.current_latitude - lat) * 111.0, 2) + 
        POW((d.current_longitude - lng) * 111.0 * cos(radians(lat)), 2)
      )
    )::numeric as avg_distance_km
  FROM drivers d
  WHERE 
    d.is_online = true 
    AND (d.approval_status = 'approved' OR d.approval_status IS NULL)
    AND d.current_latitude IS NOT NULL 
    AND d.current_longitude IS NOT NULL
    AND d.vehicle_category IS NOT NULL
    -- Bounding box filter
    AND d.current_latitude BETWEEN (lat - lat_delta) AND (lat + lat_delta)
    AND d.current_longitude BETWEEN (lng - lng_delta) AND (lng + lng_delta)
  GROUP BY d.vehicle_category
  HAVING COUNT(*) > 0
  ORDER BY driver_count DESC;
END;
$$;


ALTER FUNCTION "public"."get_available_categories_stats"("lat" double precision, "lng" double precision, "radius_km" double precision) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_available_categories_stats"("lat" double precision, "lng" double precision, "radius_km" double precision) IS 'Retorna estatísticas das categorias de veículos disponíveis em uma região específica. Usado pela app para mostrar motoristas disponíveis por categoria em tempo real.';



CREATE OR REPLACE FUNCTION "public"."get_driver_document_signed_url"("doc_id" "uuid", "expires_in" interval DEFAULT '01:00:00'::interval) RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    signed_url text;
    doc_record RECORD;
BEGIN
    -- Get the document record
    SELECT file_url, driver_id, document_type INTO doc_record
    FROM driver_documents 
    WHERE id = doc_id AND is_current = true;
    
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;
    
    -- In a real implementation, this would call Supabase Storage to generate a signed URL
    -- For now, we'll return the original URL (to be replaced with actual signed URL generation)
    RETURN doc_record.file_url;
END;
$$;


ALTER FUNCTION "public"."get_driver_document_signed_url"("doc_id" "uuid", "expires_in" interval) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_emergency_nearby_drivers"("lat" double precision, "lng" double precision, "radius_km" double precision DEFAULT 10.0) RETURNS TABLE("driver_id" "uuid", "user_id" "uuid", "vehicle_brand" "text", "vehicle_model" "text", "vehicle_year" integer, "vehicle_color" "text", "vehicle_category" "text", "vehicle_plate" "text", "is_online" boolean, "current_latitude" double precision, "current_longitude" double precision, "average_rating" numeric, "total_trips" integer, "distance_km" double precision, "onesignal_player_id" "text", "player_id" "text", "fcm_token" "text", "full_name" "text", "phone" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id as driver_id,
        d.user_id,
        d.vehicle_brand,
        d.vehicle_model,
        d.vehicle_year,
        d.vehicle_color,
        d.vehicle_category,
        d.vehicle_plate,
        d.is_online,
        d.current_latitude,
        d.current_longitude,
        d.average_rating,
        d.total_trips,
        (
            6371 * acos(
                cos(radians(lat)) * 
                cos(radians(d.current_latitude)) * 
                cos(radians(d.current_longitude) - radians(lng)) + 
                sin(radians(lat)) * 
                sin(radians(d.current_latitude))
            )
        ) as distance_km,
        au.fcm_token as onesignal_player_id,
        au.fcm_token as player_id,
        au.fcm_token,
        au.full_name,
        au.phone
    FROM drivers d
    INNER JOIN app_users au ON d.user_id = au.id
    WHERE 
        d.is_online = true
        AND (d.approval_status = 'approved' OR d.approval_status IS NULL)
        AND d.current_latitude IS NOT NULL
        AND d.current_longitude IS NOT NULL
        AND d.current_latitude BETWEEN (lat - (radius_km / 111.0)) AND (lat + (radius_km / 111.0))
        AND d.current_longitude BETWEEN (lng - (radius_km / (111.0 * cos(radians(lat))))) AND (lng + (radius_km / (111.0 * cos(radians(lat)))))
    HAVING 
        (
            6371 * acos(
                cos(radians(lat)) * 
                cos(radians(d.current_latitude)) * 
                cos(radians(d.current_longitude) - radians(lng)) + 
                sin(radians(lat)) * 
                sin(radians(d.current_latitude))
            )
        ) <= radius_km
    ORDER BY distance_km
    LIMIT 100;
END;
$$;


ALTER FUNCTION "public"."get_emergency_nearby_drivers"("lat" double precision, "lng" double precision, "radius_km" double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_nearby_drivers"("lat" double precision, "lng" double precision, "radius_km" double precision DEFAULT 5.0) RETURNS TABLE("driver_id" "uuid", "user_id" "uuid", "vehicle_brand" "text", "vehicle_model" "text", "vehicle_year" integer, "vehicle_color" "text", "vehicle_category" "text", "vehicle_plate" "text", "is_online" boolean, "accepts_pet" boolean, "accepts_grocery" boolean, "accepts_condo" boolean, "ac_policy" "text", "custom_price_per_km" numeric, "custom_price_per_minute" numeric, "pet_fee" numeric, "grocery_fee" numeric, "condo_fee" numeric, "stop_fee" numeric, "current_latitude" double precision, "current_longitude" double precision, "average_rating" numeric, "total_trips" integer, "distance_km" double precision, "onesignal_player_id" "text", "player_id" "text", "fcm_token" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id as driver_id,
        d.user_id,
        d.vehicle_brand,
        d.vehicle_model,
        d.vehicle_year,
        d.vehicle_color,
        d.vehicle_category,
        d.vehicle_plate,
        d.is_online,
        d.accepts_pet,
        d.accepts_grocery,
        d.accepts_condo,
        d.ac_policy,
        d.custom_price_per_km,
        d.custom_price_per_minute,
        d.pet_fee,
        d.grocery_fee,
        d.condo_fee,
        d.stop_fee,
        d.current_latitude,
        d.current_longitude,
        d.average_rating,
        d.total_trips,
        (
            6371 * acos(
                cos(radians(lat)) * 
                cos(radians(d.current_latitude)) * 
                cos(radians(d.current_longitude) - radians(lng)) + 
                sin(radians(lat)) * 
                sin(radians(d.current_latitude))
            )
        ) as distance_km,
        au.fcm_token as onesignal_player_id,
        au.fcm_token as player_id,
        au.fcm_token
    FROM drivers d
    INNER JOIN app_users au ON d.user_id = au.id
    WHERE 
        d.is_online = true
        AND (d.approval_status = 'approved' OR d.approval_status IS NULL)
        AND d.current_latitude IS NOT NULL
        AND d.current_longitude IS NOT NULL
        AND d.current_latitude BETWEEN (lat - (radius_km / 111.0)) AND (lat + (radius_km / 111.0))
        AND d.current_longitude BETWEEN (lng - (radius_km / (111.0 * cos(radians(lat))))) AND (lng + (radius_km / (111.0 * cos(radians(lat)))))
    HAVING 
        (
            6371 * acos(
                cos(radians(lat)) * 
                cos(radians(d.current_latitude)) * 
                cos(radians(d.current_longitude) - radians(lng)) + 
                sin(radians(lat)) * 
                sin(radians(d.current_latitude))
            )
        ) <= radius_km
    ORDER BY distance_km
    LIMIT 50;
END;
$$;


ALTER FUNCTION "public"."get_nearby_drivers"("lat" double precision, "lng" double precision, "radius_km" double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."identify_corrupted_users"() RETURNS TABLE("user_id" "uuid", "email" "text", "full_name" "text", "phone" "text", "corruption_type" "text", "corruption_confidence" numeric, "suggested_fix" "text", "created_at" timestamp with time zone)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        au.id,
        au.email,
        au.full_name,
        au.phone,
        CASE 
            -- JSON structures in names
            WHEN au.full_name LIKE '%{%}%' OR au.full_name LIKE '%[%]%' THEN 'json_structure_name'
            -- Specific error messages
            WHEN au.full_name LIKE '%missing_passenger_records%' THEN 'error_message_name'
            WHEN au.full_name LIKE '%error%' OR au.full_name LIKE '%exception%' THEN 'error_keyword_name'
            -- Placeholder data
            WHEN au.full_name LIKE 'PENDENTE_%' THEN 'placeholder_name'
            -- Phone with timestamp
            WHEN au.phone LIKE '%-164%' THEN 'timestamp_phone'
            WHEN au.phone LIKE '%error%' THEN 'error_message_phone'
            ELSE 'unknown'
        END as corruption_type,
        CASE 
            -- High confidence cases
            WHEN au.full_name LIKE '%missing_passenger_records%' THEN 0.95
            WHEN au.full_name LIKE '%{"count"%' THEN 0.95
            WHEN au.phone LIKE '%-164%' THEN 0.95
            -- Medium confidence cases  
            WHEN au.full_name LIKE '%{%}%' THEN 0.80
            WHEN au.full_name LIKE 'PENDENTE_%' THEN 0.75
            -- Low confidence cases
            WHEN au.full_name LIKE '%error%' THEN 0.60
            ELSE 0.50
        END as corruption_confidence,
        CASE 
            -- Suggested fixes based on corruption type
            WHEN au.full_name LIKE '%missing_passenger_records%' 
                THEN 'Usuario ' || SPLIT_PART(au.email, '@', 1)
            WHEN au.full_name LIKE '%{%' 
                THEN 'Usuario ' || SPLIT_PART(au.email, '@', 1)
            WHEN au.full_name LIKE 'PENDENTE_%' 
                THEN 'Usuario ' || SPLIT_PART(au.email, '@', 1)
            WHEN au.phone LIKE '%-164%' 
                THEN SPLIT_PART(au.phone, '-', 1)
            ELSE 'manual_review_needed'
        END as suggested_fix,
        au.created_at
    FROM app_users au
    WHERE 
        -- Only target obviously corrupted data
        (au.full_name LIKE '%{%}%' OR 
         au.full_name LIKE '%[%]%' OR
         au.full_name LIKE '%missing_passenger_records%' OR
         au.full_name LIKE '%error%' OR
         au.full_name LIKE 'PENDENTE_%' OR
         au.phone LIKE '%-164%' OR
         au.phone LIKE '%error%')
    ORDER BY 
        CASE 
            WHEN au.full_name LIKE '%missing_passenger_records%' THEN 1
            WHEN au.phone LIKE '%-164%' THEN 2
            WHEN au.full_name LIKE '%{%' THEN 3
            ELSE 4
        END,
        au.created_at DESC;
END;
$$;


ALTER FUNCTION "public"."identify_corrupted_users"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."increment_driver_cancellations"("driver_user_id" "uuid") RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    current_count INTEGER := 0;
    new_count INTEGER := 0;
BEGIN
    -- Incrementar contador de cancelamentos consecutivos
    UPDATE drivers 
    SET consecutive_cancellations = consecutive_cancellations + 1,
        updated_at = NOW()
    WHERE user_id = driver_user_id
    RETURNING consecutive_cancellations INTO new_count;

    RETURN new_count;
END;
$$;


ALTER FUNCTION "public"."increment_driver_cancellations"("driver_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."increment_passenger_cancellations"("passenger_user_id" "uuid") RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    current_count INTEGER := 0;
    new_count INTEGER := 0;
BEGIN
    -- Verificar se o passageiro existe
    IF NOT EXISTS (SELECT 1 FROM passengers WHERE user_id = passenger_user_id) THEN
        -- Criar registro do passageiro se não existir
        INSERT INTO passengers (user_id, consecutive_cancellations, total_trips, average_rating, created_at, updated_at)
        VALUES (passenger_user_id, 0, 0, 0.0, NOW(), NOW())
        ON CONFLICT (user_id) DO NOTHING;
    END IF;

    -- Incrementar contador de cancelamentos consecutivos
    UPDATE passengers 
    SET consecutive_cancellations = consecutive_cancellations + 1,
        updated_at = NOW()
    WHERE user_id = passenger_user_id
    RETURNING consecutive_cancellations INTO new_count;

    RETURN new_count;
END;
$$;


ALTER FUNCTION "public"."increment_passenger_cancellations"("passenger_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."insert_profile"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    INSERT INTO public.app_users (
        id,
        email,
        full_name,
        phone,
        photo_url,
        user_type,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        COALESCE(NEW.email, ''),  -- Email será preenchido pelo auth
        NEW.nome,
        NEW.telefone,
        NEW.avatar_url,
        CASE 
            WHEN NEW.tipo_usuario = 'Passageiro' THEN 'passenger'
            WHEN NEW.tipo_usuario = 'Motorista' THEN 'driver'
            WHEN NEW.tipo_usuario = 'Admin' THEN 'admin'
            ELSE NEW.tipo_usuario
        END,
        NEW.created_at,
        NEW.updated_at
    );
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."insert_profile"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."insert_profile"() IS 'Função para inserir dados via view profiles';



CREATE OR REPLACE FUNCTION "public"."invalidate_driver_document_urls"("target_driver_id" "uuid" DEFAULT NULL::"uuid", "document_type_filter" "text" DEFAULT NULL::"text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    UPDATE driver_documents 
    SET is_current = false,
        updated_at = NOW()
    WHERE (target_driver_id IS NULL OR driver_id = target_driver_id)
      AND (document_type_filter IS NULL OR document_type = document_type_filter)
      AND is_current = true
      AND file_url IS NOT NULL;
END;
$$;


ALTER FUNCTION "public"."invalidate_driver_document_urls"("target_driver_id" "uuid", "document_type_filter" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_sync_enabled"("feature_name" "text") RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    enabled_status BOOLEAN;
BEGIN
    SELECT enabled INTO enabled_status 
    FROM sync_control 
    WHERE sync_control.feature_name = is_sync_enabled.feature_name;
    
    RETURN COALESCE(enabled_status, FALSE);
END;
$$;


ALTER FUNCTION "public"."is_sync_enabled"("feature_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."monitor_migration_progress"() RETURNS "json"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    current_stats json;
    backup_stats json;
    changes_detected BOOLEAN := FALSE;
    result json;
BEGIN
    -- Stats atuais
    SELECT json_build_object(
        'app_users', (SELECT COUNT(*) FROM app_users),
        'passengers', (SELECT COUNT(*) FROM passengers),
        'drivers', (SELECT COUNT(*) FROM drivers),
        'timestamp', NOW()
    ) INTO current_stats;
    
    -- Stats do backup para comparação
    SELECT json_build_object(
        'app_users', (SELECT COUNT(*) FROM backup_app_users_migration),
        'passengers', (SELECT COUNT(*) FROM backup_passengers_migration),
        'drivers', (SELECT COUNT(*) FROM backup_drivers_migration)
    ) INTO backup_stats;
    
    -- Detectar mudanças
    IF (current_stats->>'app_users')::int != (backup_stats->>'app_users')::int OR
       (current_stats->>'passengers')::int != (backup_stats->>'passengers')::int OR
       (current_stats->>'drivers')::int != (backup_stats->>'drivers')::int THEN
        changes_detected := TRUE;
    END IF;
    
    result := json_build_object(
        'current', current_stats,
        'backup', backup_stats,
        'changes_detected', changes_detected,
        'migration_active', changes_detected
    );
    
    RETURN result;
END;
$$;


ALTER FUNCTION "public"."monitor_migration_progress"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."process_trip_payment"("p_trip_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
DECLARE
   v_driver_id UUID;
   v_driver_earnings DECIMAL;
   v_wallet_id UUID;
   v_trip_code TEXT;
BEGIN
   -- Buscar dados da viagem
   SELECT driver_id, driver_earnings, trip_code
   INTO v_driver_id, v_driver_earnings, v_trip_code
   FROM trips
   WHERE id = p_trip_id AND status = 'completed';
   
   IF NOT FOUND THEN
       RETURN FALSE;
   END IF;
   
   -- Buscar ou criar carteira do motorista
   SELECT id INTO v_wallet_id
   FROM driver_wallets
   WHERE driver_id = v_driver_id;
   
   IF NOT FOUND THEN
       INSERT INTO driver_wallets (driver_id)
       VALUES (v_driver_id)
       RETURNING id INTO v_wallet_id;
   END IF;
   
   -- Atualizar saldo da carteira
   UPDATE driver_wallets
   SET 
       available_balance = available_balance + v_driver_earnings,
       total_earned = total_earned + v_driver_earnings,
       updated_at = NOW()
   WHERE id = v_wallet_id;
   
   -- Registrar transação
   INSERT INTO wallet_transactions (
       wallet_id,
       type,
       amount,
       description,
       reference_type,
       reference_id,
       balance_after
   )
   SELECT 
       v_wallet_id,
       'earning',
       v_driver_earnings,
       'Ganhos da viagem ' || v_trip_code,
       'trip',
       p_trip_id,
       available_balance
   FROM driver_wallets
   WHERE id = v_wallet_id;
   
   -- Atualizar status do pagamento na viagem
   UPDATE trips
   SET 
       payment_status = 'completed',
       payment_completed_at = NOW()
   WHERE id = p_trip_id;
   
   RETURN TRUE;
END;
$$;


ALTER FUNCTION "public"."process_trip_payment"("p_trip_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."reactivate_user"("target_user_id" "uuid", "admin_user_id" "uuid", "reason" "text" DEFAULT NULL::"text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    -- Verificar se o usuário admin tem permissão (apenas usuários com status 'admin')
    IF NOT EXISTS (SELECT 1 FROM app_users WHERE id = admin_user_id AND user_type = 'admin') THEN
        RAISE EXCEPTION 'Usuário não tem permissão para reativar contas';
    END IF;

    -- Reativar usuário
    UPDATE app_users 
    SET status = 'active',
        updated_at = NOW()
    WHERE id = target_user_id AND status = 'suspended';

    -- Resetar cancelamentos consecutivos
    UPDATE passengers 
    SET consecutive_cancellations = 0,
        updated_at = NOW()
    WHERE user_id = target_user_id;

    UPDATE drivers 
    SET consecutive_cancellations = 0,
        updated_at = NOW()
    WHERE user_id = target_user_id;

    -- Log da reativação
    INSERT INTO activity_logs (user_id, action, entity_type, entity_id, metadata, created_at)
    VALUES (admin_user_id, 'user_reactivated', 'user', target_user_id,
            jsonb_build_object('reason', COALESCE(reason, 'Reativação administrativa')),
            NOW());

    RETURN TRUE;
END;
$$;


ALTER FUNCTION "public"."reactivate_user"("target_user_id" "uuid", "admin_user_id" "uuid", "reason" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."reset_cancellations_on_trip_completion"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    -- Se a viagem foi completada, resetar cancelamentos consecutivos
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        -- Resetar cancelamentos do passageiro
        PERFORM reset_passenger_cancellations(NEW.passenger_id);
        
        -- Resetar cancelamentos do motorista
        PERFORM reset_driver_cancellations(NEW.driver_id);
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."reset_cancellations_on_trip_completion"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."reset_driver_cancellations"("driver_user_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    UPDATE drivers 
    SET consecutive_cancellations = 0,
        updated_at = NOW()
    WHERE user_id = driver_user_id;
END;
$$;


ALTER FUNCTION "public"."reset_driver_cancellations"("driver_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."reset_passenger_cancellations"("passenger_user_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    UPDATE passengers 
    SET consecutive_cancellations = 0,
        updated_at = NOW()
    WHERE user_id = passenger_user_id;
END;
$$;


ALTER FUNCTION "public"."reset_passenger_cancellations"("passenger_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."restore_user_data"("target_user_id" "uuid") RETURNS "json"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    backup_record RECORD;
    result json;
BEGIN
    -- Buscar backup mais recente
    SELECT * INTO backup_record
    FROM corrupted_users_backup
    WHERE original_user_id = target_user_id
      AND restored = FALSE
    ORDER BY correction_timestamp DESC
    LIMIT 1;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'status', 'error',
            'message', 'Nenhum backup encontrado para restauração',
            'user_id', target_user_id
        );
    END IF;
    
    -- Restaurar dados originais
    BEGIN
        UPDATE app_users 
        SET 
            full_name = backup_record.original_full_name,
            phone = backup_record.original_phone,
            updated_at = NOW()
        WHERE id = target_user_id;
        
        -- Marcar backup como restaurado
        UPDATE corrupted_users_backup
        SET restored = TRUE, restored_at = NOW()
        WHERE id = backup_record.id;
        
        RAISE NOTICE 'RESTAURAÇÃO: Usuário % restaurado do backup', target_user_id;
        
        RETURN json_build_object(
            'status', 'restored',
            'user_id', target_user_id,
            'restored_data', json_build_object(
                'full_name', backup_record.original_full_name,
                'phone', backup_record.original_phone
            ),
            'backup_timestamp', backup_record.correction_timestamp,
            'restored_at', NOW()
        );
        
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object(
            'status', 'error',
            'message', 'Falha na restauração: ' || SQLERRM,
            'user_id', target_user_id
        );
    END;
END;
$$;


ALTER FUNCTION "public"."restore_user_data"("target_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."safe_correct_user_data"("target_user_id" "uuid", "new_full_name" "text" DEFAULT NULL::"text", "new_phone" "text" DEFAULT NULL::"text", "dry_run" boolean DEFAULT true) RETURNS "json"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    original_record RECORD;
    correction_applied BOOLEAN := FALSE;
    result json;
BEGIN
    -- Buscar registro original
    SELECT * INTO original_record 
    FROM app_users 
    WHERE id = target_user_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'status', 'error',
            'message', 'Usuário não encontrado',
            'user_id', target_user_id
        );
    END IF;
    
    -- Validar se realmente precisa correção
    IF (new_full_name IS NULL AND new_phone IS NULL) THEN
        RETURN json_build_object(
            'status', 'error',
            'message', 'Nenhuma correção especificada',
            'user_id', target_user_id
        );
    END IF;
    
    -- Modo DRY RUN - apenas simular
    IF dry_run THEN
        RETURN json_build_object(
            'status', 'dry_run',
            'user_id', target_user_id,
            'original_data', json_build_object(
                'full_name', original_record.full_name,
                'phone', original_record.phone
            ),
            'proposed_changes', json_build_object(
                'full_name', COALESCE(new_full_name, original_record.full_name),
                'phone', COALESCE(new_phone, original_record.phone)
            ),
            'timestamp', NOW()
        );
    END IF;
    
    -- MODO REAL - aplicar correções
    BEGIN
        -- Backup do registro original
        INSERT INTO corrupted_users_backup (
            original_user_id,
            original_full_name,
            original_phone,
            original_email,
            correction_timestamp,
            correction_reason
        ) VALUES (
            original_record.id,
            original_record.full_name,
            original_record.phone,
            original_record.email,
            NOW(),
            'safe_automatic_correction'
        );
        
        -- Aplicar correções
        UPDATE app_users 
        SET 
            full_name = COALESCE(new_full_name, full_name),
            phone = COALESCE(new_phone, phone),
            updated_at = NOW()
        WHERE id = target_user_id;
        
        correction_applied := TRUE;
        
        RAISE NOTICE 'CORREÇÃO APLICADA: Usuário % corrigido', target_user_id;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'ERRO na correção do usuário %: %', target_user_id, SQLERRM;
        RETURN json_build_object(
            'status', 'error',
            'message', 'Falha ao aplicar correção: ' || SQLERRM,
            'user_id', target_user_id
        );
    END;
    
    -- Resultado da operação
    result := json_build_object(
        'status', 'success',
        'user_id', target_user_id,
        'correction_applied', correction_applied,
        'original_data', json_build_object(
            'full_name', original_record.full_name,
            'phone', original_record.phone
        ),
        'corrected_data', json_build_object(
            'full_name', COALESCE(new_full_name, original_record.full_name),
            'phone', COALESCE(new_phone, original_record.phone)
        ),
        'timestamp', NOW()
    );
    
    RETURN result;
END;
$$;


ALTER FUNCTION "public"."safe_correct_user_data"("target_user_id" "uuid", "new_full_name" "text", "new_phone" "text", "dry_run" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_passenger_wallet_id"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    IF NEW.id IS NULL THEN
        NEW.id := NEW.passenger_id;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_passenger_wallet_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."simple_auth_check"() RETURNS "json"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN json_build_object(
        'timestamp', NOW(),
        'rls_disabled', (
            SELECT COUNT(*) = 0 
            FROM pg_tables 
            WHERE schemaname = 'public' 
            AND rowsecurity = true
        ),
        'policies_count', (
            SELECT COUNT(*) 
            FROM pg_policies 
            WHERE schemaname = 'public'
        ),
        'app_users_count', (
            SELECT COUNT(*) 
            FROM app_users
        ),
        'message', 'RLS completely disabled, ready for native auth'
    );
END;
$$;


ALTER FUNCTION "public"."simple_auth_check"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_app_users_to_auth"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    sync_log_id UUID;
    operation_type TEXT;
BEGIN
    -- Criar log inicial
    INSERT INTO auth_sync_logs (
        event_type,
        user_id,
        operation,
        source_table,
        target_table,
        new_data
    ) VALUES (
        TG_OP || '_app_user',
        COALESCE(NEW.id, OLD.id),
        'sync_pending',
        'app_users',
        'auth.users',
        CASE WHEN NEW IS NOT NULL 
             THEN row_to_json(NEW) 
             ELSE NULL END
    ) RETURNING id INTO sync_log_id;

    -- Processar diferentes tipos de operações
    IF TG_OP = 'UPDATE' THEN
        operation_type := 'sync_updated';
        
        -- Sincronizar apenas campos específicos para auth.users
        IF (OLD.email != NEW.email OR OLD.phone != NEW.phone) THEN
            -- Validar dados antes de sincronizar
            IF validate_sync_data(NEW.email, NEW.full_name, NEW.phone) THEN
                BEGIN
                    UPDATE auth.users 
                    SET 
                        email = NEW.email,
                        phone = NEW.phone,
                        updated_at = NOW()
                    WHERE id = NEW.id;
                    
                    -- Atualizar log de sucesso
                    UPDATE auth_sync_logs 
                    SET operation = operation_type,
                        sync_status = 'completed'
                    WHERE id = sync_log_id;
                    
                EXCEPTION WHEN OTHERS THEN
                    -- Log de erro
                    UPDATE auth_sync_logs 
                    SET operation = 'sync_failed',
                        sync_status = 'failed',
                        error_message = SQLERRM
                    WHERE id = sync_log_id;
                    
                    RAISE WARNING 'Falha na sincronização app_users→auth: %', SQLERRM;
                END;
            ELSE
                -- Dados inválidos - não sincronizar
                UPDATE auth_sync_logs 
                SET operation = 'sync_failed',
                    sync_status = 'failed',
                    error_message = 'Dados corrompidos - sincronização bloqueada'
                WHERE id = sync_log_id;
            END IF;
        END IF;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION "public"."sync_app_users_to_auth"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_status_report"() RETURNS "json"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    result json;
BEGIN
    SELECT json_build_object(
        'sync_features', (
            SELECT json_agg(
                json_build_object(
                    'feature', feature_name,
                    'enabled', enabled,
                    'updated_at', updated_at
                )
            )
            FROM sync_control
        ),
        'recent_sync_events', (
            SELECT json_agg(
                json_build_object(
                    'event_type', event_type,
                    'operation', operation,
                    'sync_status', sync_status,
                    'created_at', created_at
                )
            )
            FROM (
                SELECT * FROM auth_sync_logs 
                ORDER BY created_at DESC 
                LIMIT 10
            ) recent
        ),
        'sync_stats', (
            SELECT json_build_object(
                'total_events', COUNT(*),
                'successful_syncs', COUNT(*) FILTER (WHERE sync_status = 'completed'),
                'failed_syncs', COUNT(*) FILTER (WHERE sync_status = 'failed'),
                'skipped_syncs', COUNT(*) FILTER (WHERE sync_status = 'skipped')
            )
            FROM auth_sync_logs
            WHERE created_at > NOW() - INTERVAL '24 hours'
        ),
        'timestamp', NOW()
    ) INTO result;
    
    RETURN result;
END;
$$;


ALTER FUNCTION "public"."sync_status_report"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."test_automatic_approval_system"() RETURNS TABLE("test_name" "text", "result" "text", "details" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Teste 1: Verificar se triggers existem
    test_name := 'Trigger existe';
    result := CASE WHEN EXISTS(
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trigger_driver_document_approval'
    ) THEN 'PASS' ELSE 'FAIL' END;
    details := 'Trigger trigger_driver_document_approval deve existir';
    RETURN NEXT;
    
    -- Teste 2: Verificar se função existe
    test_name := 'Função existe';
    result := CASE WHEN EXISTS(
        SELECT 1 FROM pg_proc 
        WHERE proname = 'check_and_update_driver_approval_status'
    ) THEN 'PASS' ELSE 'FAIL' END;
    details := 'Função check_and_update_driver_approval_status deve existir';
    RETURN NEXT;
    
    -- Teste 3: Verificar tabela de auditoria
    test_name := 'Tabela auditoria existe';
    result := CASE WHEN EXISTS(
        SELECT 1 FROM pg_tables 
        WHERE tablename = 'driver_approval_audit'
    ) THEN 'PASS' ELSE 'FAIL' END;
    details := 'Tabela driver_approval_audit deve existir';
    RETURN NEXT;
    
    -- Teste 4: Verificar motoristas aprovados automaticamente
    test_name := 'Aprovações automáticas';
    result := CASE WHEN EXISTS(
        SELECT 1 FROM driver_approval_audit 
        WHERE reason LIKE '%AUTOMÁTICA%'
    ) THEN 'PASS' ELSE 'INFO' END;
    details := 'Deve haver registros de aprovação automática (se aplicável)';
    RETURN NEXT;
END;
$$;


ALTER FUNCTION "public"."test_automatic_approval_system"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."test_direct_signup"() RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    test_id uuid := gen_random_uuid();
    test_email text := 'emergency_test_' || extract(epoch from now()) || '@example.com';
    result_msg text;
BEGIN
    -- Tentar inserir diretamente no auth.users sem usar o endpoint
    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        created_at,
        updated_at,
        raw_app_meta_data,
        raw_user_meta_data
    ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        test_id,
        'authenticated',
        'authenticated', 
        test_email,
        crypt('test123456', gen_salt('bf')),
        now(),
        now(),
        now(),
        '{"provider": "email", "providers": ["email"]}',
        '{}'
    );
    
    result_msg := 'SUCCESS: Direct insert to auth.users worked';
    
    -- Limpar teste
    DELETE FROM auth.users WHERE id = test_id;
    
    RETURN result_msg;
EXCEPTION WHEN OTHERS THEN
    -- Tentar limpar
    BEGIN
        DELETE FROM auth.users WHERE email = test_email;
    EXCEPTION WHEN OTHERS THEN
        -- Ignorar
    END;
    
    RETURN 'ERROR: ' || SQLERRM;
END;
$$;


ALTER FUNCTION "public"."test_direct_signup"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."test_problematic_insert"() RETURNS "json"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    result json;
    error_msg text;
    error_detail text;
    error_hint text;
BEGIN
    -- Tentar inserção com os dados exatos que estão falhando
    BEGIN
        INSERT INTO app_users (
            id,
            email,
            full_name,
            phone,
            user_type,
            status
        ) VALUES (
            'e202bc55-61fa-4f18-9003-27dcfb8a12fa',
            'asdfadsf@gmail.com',
            'asdfadsf',
            '(11) 9 9999-9999',
            'passenger',
            'active'
        );
        
        result := json_build_object(
            'success', true,
            'message', 'Inserção bem-sucedida - não deveria haver conflito'
        );
        
        -- Limpar o registro de teste
        DELETE FROM app_users WHERE id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa';
        
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS 
            error_msg = MESSAGE_TEXT,
            error_detail = PG_EXCEPTION_DETAIL,
            error_hint = PG_EXCEPTION_HINT;
            
        result := json_build_object(
            'success', false,
            'error', error_msg,
            'detail', error_detail,
            'hint', error_hint,
            'sqlstate', SQLSTATE,
            'constraint_violated', CASE 
                WHEN SQLSTATE = '23505' THEN 'UNIQUE_VIOLATION'
                WHEN SQLSTATE = '23503' THEN 'FOREIGN_KEY_VIOLATION'
                WHEN SQLSTATE = '23514' THEN 'CHECK_VIOLATION'
                ELSE 'OTHER'
            END
        );
    END;
    
    RETURN result;
END;
$$;


ALTER FUNCTION "public"."test_problematic_insert"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trigger_check_driver_approval"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_result JSON;
BEGIN
    -- Log do trigger
    RAISE NOTICE 'trigger_check_driver_approval: Documento % do driver % teve status alterado para %', 
                 NEW.document_type, NEW.driver_id, NEW.status;
    
    -- Só executar se o documento foi aprovado
    IF NEW.status = 'approved' AND NEW.is_current = true THEN
        RAISE NOTICE 'trigger_check_driver_approval: ✅ Documento aprovado, verificando se motorista pode ser aprovado...';
        
        -- Chamar função de verificação
        SELECT check_and_update_driver_approval_status(NEW.driver_id) INTO v_result;
        
        RAISE NOTICE 'trigger_check_driver_approval: Resultado da verificação: %', v_result;
    ELSE
        RAISE NOTICE 'trigger_check_driver_approval: Documento não aprovado ou não é atual, ignorando';
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."trigger_check_driver_approval"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_average_rating"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
   -- Atualizar rating do motorista
   IF NEW.driver_rating IS NOT NULL THEN
       UPDATE drivers
       SET average_rating = (
           SELECT AVG(driver_rating)::DECIMAL(3,2)
           FROM ratings r
           JOIN trips t ON r.trip_id = t.id
           WHERE t.driver_id = (SELECT driver_id FROM trips WHERE id = NEW.trip_id)
           AND r.driver_rating IS NOT NULL
       )
       WHERE id = (SELECT driver_id FROM trips WHERE id = NEW.trip_id);
   END IF;
   
   -- Atualizar rating do passageiro
   IF NEW.passenger_rating IS NOT NULL THEN
       UPDATE passengers
       SET average_rating = (
           SELECT AVG(passenger_rating)::DECIMAL(3,2)
           FROM ratings r
           JOIN trips t ON r.trip_id = t.id
           WHERE t.passenger_id = (SELECT passenger_id FROM trips WHERE id = NEW.trip_id)
           AND r.passenger_rating IS NOT NULL
       )
       WHERE id = (SELECT passenger_id FROM trips WHERE id = NEW.trip_id);
   END IF;
   
   RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_average_rating"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_driver_operation_zones_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_driver_operation_zones_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_driver_status_on_document_approval"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Se um documento foi aprovado, verificar se todos estão aprovados agora
    IF NEW.status = 'approved' AND OLD.status != 'approved' THEN
        -- Log da aprovação
        RAISE NOTICE 'Documento % do motorista % foi aprovado', NEW.document_type, NEW.driver_id;

        -- Se todos os documentos obrigatórios estão aprovados, log adicional
        IF check_driver_documents_approved(NEW.driver_id) THEN
            RAISE NOTICE 'Todos os documentos do motorista % estão aprovados. Motorista pode ficar online.', NEW.driver_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_driver_status_on_document_approval"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_override_timestamp"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_override_timestamp"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_profile"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    UPDATE public.app_users SET
        full_name = NEW.nome,
        phone = NEW.telefone,
        photo_url = NEW.avatar_url,
        user_type = CASE 
            WHEN NEW.tipo_usuario = 'Passageiro' THEN 'passenger'
            WHEN NEW.tipo_usuario = 'Motorista' THEN 'driver'
            WHEN NEW.tipo_usuario = 'Admin' THEN 'admin'
            ELSE NEW.tipo_usuario
        END,
        updated_at = NEW.updated_at
    WHERE id = NEW.id;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_profile"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."update_profile"() IS 'Função para atualizar dados via view profiles';



CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_user_metrics"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
   v_user_type TEXT;
BEGIN
   IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
       -- Atualizar métricas de sucesso
       UPDATE drivers 
       SET 
           total_trips = total_trips + 1,
           consecutive_cancellations = 0
       WHERE id = NEW.driver_id;
       
       UPDATE passengers
       SET 
           total_trips = total_trips + 1,
           consecutive_cancellations = 0
       WHERE id = NEW.passenger_id;
       
   ELSIF NEW.status = 'cancelled_by_driver' AND OLD.status != 'cancelled_by_driver' THEN
       -- Incrementar cancelamentos do motorista
       UPDATE drivers 
       SET consecutive_cancellations = consecutive_cancellations + 1
       WHERE id = NEW.driver_id;
       
       -- Verificar suspensão
       PERFORM check_and_suspend_user(NEW.driver_id, 'driver');
       
   ELSIF NEW.status = 'cancelled_by_passenger' AND OLD.status != 'cancelled_by_passenger' THEN
       -- Incrementar cancelamentos do passageiro
       UPDATE passengers
       SET consecutive_cancellations = consecutive_cancellations + 1
       WHERE id = NEW.passenger_id;
       
       -- Verificar suspensão
       PERFORM check_and_suspend_user(NEW.passenger_id, 'passenger');
   END IF;
   
   -- Registrar mudança de status
   INSERT INTO trip_status_history (
       trip_id,
       old_status,
       new_status,
       reason
   ) VALUES (
       NEW.id,
       OLD.status,
       NEW.status,
       NEW.cancellation_reason
   );
   
   RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_user_metrics"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_data_integrity"() RETURNS "json"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    total_users INTEGER;
    orphaned_passengers INTEGER;
    orphaned_drivers INTEGER;
    corrupted_names INTEGER;
    missing_auth_users INTEGER;
    result json;
    integrity_score DECIMAL;
    issues text[] := '{}';
BEGIN
    RAISE NOTICE 'VALIDANDO INTEGRIDADE DOS DADOS...';
    
    -- Contar total de usuários
    SELECT COUNT(*) INTO total_users FROM app_users;
    
    -- Verificar passageiros órfãos
    SELECT COUNT(*) INTO orphaned_passengers 
    FROM passengers p 
    WHERE NOT EXISTS (SELECT 1 FROM app_users a WHERE a.id = p.user_id);
    
    -- Verificar motoristas órfãos
    SELECT COUNT(*) INTO orphaned_drivers
    FROM drivers d
    WHERE NOT EXISTS (SELECT 1 FROM app_users a WHERE a.id = d.user_id);
    
    -- Verificar nomes corrompidos
    SELECT COUNT(*) INTO corrupted_names
    FROM app_users 
    WHERE full_name LIKE '%{%}%'
       OR full_name LIKE '%[%]%'
       OR full_name LIKE '%missing_passenger_records%'
       OR full_name LIKE '%issue%'
       OR full_name LIKE '%count%'
       OR full_name LIKE '%error%';
    
    -- Verificar usuários sem auth correspondente (simplificado)
    missing_auth_users := 0; -- Não conseguimos acessar auth.users diretamente
    
    -- Adicionar issues encontrados
    IF orphaned_passengers > 0 THEN
        issues := array_append(issues, orphaned_passengers || ' passageiros órfãos');
    END IF;
    
    IF orphaned_drivers > 0 THEN
        issues := array_append(issues, orphaned_drivers || ' motoristas órfãos');
    END IF;
    
    IF corrupted_names > 0 THEN
        issues := array_append(issues, corrupted_names || ' nomes corrompidos');
    END IF;
    
    -- Calcular score de integridade (0-100)
    IF total_users = 0 THEN
        integrity_score := 0;
    ELSE
        integrity_score := GREATEST(0, 100 - (
            (orphaned_passengers + orphaned_drivers + corrupted_names) * 100.0 / total_users
        ));
    END IF;
    
    result := json_build_object(
        'status', CASE WHEN array_length(issues, 1) = 0 THEN 'healthy' ELSE 'issues_found' END,
        'timestamp', NOW(),
        'total_users', total_users,
        'integrity_score', ROUND(integrity_score, 2),
        'issues', issues,
        'details', json_build_object(
            'orphaned_passengers', orphaned_passengers,
            'orphaned_drivers', orphaned_drivers, 
            'corrupted_names', corrupted_names,
            'missing_auth_users', missing_auth_users
        )
    );
    
    RAISE NOTICE 'INTEGRIDADE: Score %, % issues encontrados', integrity_score, COALESCE(array_length(issues, 1), 0);
    
    RETURN result;
END;
$$;


ALTER FUNCTION "public"."validate_data_integrity"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_sync_data"("email" "text", "full_name" "text" DEFAULT NULL::"text", "phone" "text" DEFAULT NULL::"text") RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Validações básicas
    IF email IS NULL OR email = '' THEN
        RETURN FALSE;
    END IF;
    
    -- Verificar se não é dados corrompidos
    IF full_name IS NOT NULL THEN
        -- Detectar JSON structures
        IF full_name LIKE '%{%}%' OR full_name LIKE '%[%]%' THEN
            RETURN FALSE;
        END IF;
        
        -- Detectar mensagens de erro
        IF full_name LIKE '%missing_passenger_records%' OR 
           full_name LIKE '%error%' OR
           full_name LIKE 'PENDENTE_%' THEN
            RETURN FALSE;
        END IF;
    END IF;
    
    -- Validar telefone
    IF phone IS NOT NULL AND phone LIKE '%-164%' THEN
        RETURN FALSE; -- Telefone com timestamp
    END IF;
    
    RETURN TRUE;
END;
$$;


ALTER FUNCTION "public"."validate_sync_data"("email" "text", "full_name" "text", "phone" "text") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."activity_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "action" "text" NOT NULL,
    "entity_type" "text",
    "entity_id" "uuid",
    "old_values" "jsonb",
    "new_values" "jsonb",
    "metadata" "jsonb",
    "ip_address" "inet",
    "user_agent" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."activity_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."app_users" (
    "id" "uuid" NOT NULL,
    "email" "text" NOT NULL,
    "full_name" "text" NOT NULL,
    "phone" "text" DEFAULT 'pending'::"text" NOT NULL,
    "photo_url" "text",
    "user_type" "text" NOT NULL,
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "fcm_token" "text",
    "device_id" "text",
    "device_platform" "text",
    "last_active_at" timestamp with time zone DEFAULT "now"(),
    "profile_complete" boolean DEFAULT false NOT NULL,
    CONSTRAINT "app_users_device_platform_check" CHECK (("device_platform" = ANY (ARRAY['ios'::"text", 'android'::"text", 'web'::"text"]))),
    CONSTRAINT "app_users_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'suspended'::"text", 'pending'::"text", 'rejected'::"text"]))),
    CONSTRAINT "app_users_user_type_check" CHECK (("user_type" = ANY (ARRAY['passenger'::"text", 'driver'::"text", 'admin'::"text"])))
);


ALTER TABLE "public"."app_users" OWNER TO "postgres";


COMMENT ON COLUMN "public"."app_users"."profile_complete" IS 'Indicates whether user has completed the full registration/stepper process';



CREATE TABLE IF NOT EXISTS "public"."asaas_webhook_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "asaas_event_id" "text" NOT NULL,
    "event_type" "text" NOT NULL,
    "payment_id" "text",
    "payload" "jsonb" NOT NULL,
    "processed_at" timestamp with time zone DEFAULT "now"(),
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."asaas_webhook_events" OWNER TO "postgres";


COMMENT ON TABLE "public"."asaas_webhook_events" IS 'Table to track processed Asaas webhook events for duplicate prevention';



COMMENT ON COLUMN "public"."asaas_webhook_events"."asaas_event_id" IS 'Unique event ID from Asaas webhook payload';



COMMENT ON COLUMN "public"."asaas_webhook_events"."event_type" IS 'Type of webhook event (e.g., PAYMENT_RECEIVED, PAYMENT_CONFIRMED)';



COMMENT ON COLUMN "public"."asaas_webhook_events"."payment_id" IS 'Asaas payment ID associated with the event';



COMMENT ON COLUMN "public"."asaas_webhook_events"."payload" IS 'Complete webhook payload for audit purposes';



CREATE TABLE IF NOT EXISTS "public"."backup_app_users_migration" (
    "id" "uuid",
    "email" "text",
    "full_name" "text",
    "phone" "text",
    "photo_url" "text",
    "user_type" "text",
    "status" "text",
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "user_id" "uuid"
);


ALTER TABLE "public"."backup_app_users_migration" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."backup_conflict_409_removal" (
    "source_table" "text",
    "backup_timestamp" timestamp with time zone,
    "id" "uuid",
    "email" "text",
    "full_name" "text",
    "phone" "text",
    "photo_url" "text",
    "user_type" "text",
    "status" "text",
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);


ALTER TABLE "public"."backup_conflict_409_removal" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."backup_drivers_migration" (
    "id" "uuid",
    "user_id" "uuid",
    "cnh_number" "text",
    "cnh_expiry_date" "date",
    "cnh_photo_url" "text",
    "vehicle_brand" "text",
    "vehicle_model" "text",
    "vehicle_year" integer,
    "vehicle_color" "text",
    "vehicle_plate" "text",
    "vehicle_category" "text",
    "crlv_photo_url" "text",
    "approval_status" "text",
    "approved_by" "uuid",
    "approved_at" timestamp with time zone,
    "is_online" boolean,
    "accepts_pet" boolean,
    "pet_fee" numeric(10,2),
    "accepts_grocery" boolean,
    "grocery_fee" numeric(10,2),
    "accepts_condo" boolean,
    "condo_fee" numeric(10,2),
    "stop_fee" numeric(10,2),
    "ac_policy" "text",
    "custom_price_per_km" numeric(10,2),
    "custom_price_per_minute" numeric(10,2),
    "bank_account_type" "text",
    "bank_code" "text",
    "bank_agency" "text",
    "bank_account" "text",
    "pix_key" "text",
    "pix_key_type" "text",
    "consecutive_cancellations" integer,
    "total_trips" integer,
    "average_rating" numeric(3,2),
    "current_latitude" numeric(10,8),
    "current_longitude" numeric(11,8),
    "last_location_update" timestamp with time zone,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);


ALTER TABLE "public"."backup_drivers_migration" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."backup_passengers_migration" (
    "id" "uuid",
    "user_id" "uuid",
    "consecutive_cancellations" integer,
    "total_trips" integer,
    "average_rating" numeric(3,2),
    "payment_method_id" "text",
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);


ALTER TABLE "public"."backup_passengers_migration" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."corrupted_users_backup" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "original_user_id" "uuid" NOT NULL,
    "original_full_name" "text",
    "original_phone" "text",
    "original_email" "text",
    "correction_timestamp" timestamp with time zone DEFAULT "now"(),
    "correction_reason" "text",
    "restored" boolean DEFAULT false,
    "restored_at" timestamp with time zone
);


ALTER TABLE "public"."corrupted_users_backup" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."driver_approval_audit" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "driver_id" "uuid" NOT NULL,
    "old_status" "text",
    "new_status" "text",
    "reason" "text",
    "approved_documents" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."driver_approval_audit" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."driver_documents" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "driver_id" "uuid" NOT NULL,
    "document_type" "text" NOT NULL,
    "file_url" "text" NOT NULL,
    "file_size" integer,
    "mime_type" "text",
    "expiry_date" "date",
    "rejection_reason" "text",
    "reviewed_by" "uuid",
    "reviewed_at" timestamp with time zone,
    "is_current" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "status" "public"."approval_status_enum" DEFAULT 'pending'::"public"."approval_status_enum" NOT NULL
);


ALTER TABLE "public"."driver_documents" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."driver_current_documents" AS
 SELECT "dd"."id",
    "dd"."driver_id",
    "dd"."document_type",
    "dd"."file_url",
    "dd"."file_size",
    "dd"."mime_type",
    "dd"."expiry_date",
    "dd"."status",
    "dd"."reviewed_at",
    "dd"."is_current",
    "dd"."created_at",
    "dd"."updated_at",
        CASE
            WHEN ("dd"."updated_at" < ("now"() - '01:00:00'::interval)) THEN true
            ELSE false
        END AS "url_might_be_stale"
   FROM "public"."driver_documents" "dd"
  WHERE ("dd"."is_current" = true)
  ORDER BY "dd"."driver_id", "dd"."document_type", "dd"."created_at" DESC;


ALTER TABLE "public"."driver_current_documents" OWNER TO "postgres";


COMMENT ON VIEW "public"."driver_current_documents" IS 'Current driver documents with URL freshness tracking for cache management';



CREATE TABLE IF NOT EXISTS "public"."driver_status" (
    "driver_id" "uuid" NOT NULL,
    "online_intent" boolean DEFAULT false NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."driver_status" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."driver_effective_status" AS
 SELECT "ds"."driver_id",
    "ds"."online_intent",
    "ds"."updated_at" AS "intent_updated_at",
    ((EXISTS ( SELECT 1
           FROM "public"."driver_documents" "dd"
          WHERE (("dd"."driver_id" = "ds"."driver_id") AND ("dd"."document_type" = 'CNH_FRONT'::"text") AND ("dd"."status" = 'approved'::"public"."approval_status_enum") AND ("dd"."is_current" = true)))) AND (EXISTS ( SELECT 1
           FROM "public"."driver_documents" "dd"
          WHERE (("dd"."driver_id" = "ds"."driver_id") AND ("dd"."document_type" = 'CNH_BACK'::"text") AND ("dd"."status" = 'approved'::"public"."approval_status_enum") AND ("dd"."is_current" = true)))) AND (EXISTS ( SELECT 1
           FROM "public"."driver_documents" "dd"
          WHERE (("dd"."driver_id" = "ds"."driver_id") AND ("dd"."document_type" = 'CRLV'::"text") AND ("dd"."status" = 'approved'::"public"."approval_status_enum") AND ("dd"."is_current" = true)))) AND (EXISTS ( SELECT 1
           FROM "public"."driver_documents" "dd"
          WHERE (("dd"."driver_id" = "ds"."driver_id") AND ("dd"."document_type" = 'VEHICLE_FRONT'::"text") AND ("dd"."status" = 'approved'::"public"."approval_status_enum") AND ("dd"."is_current" = true))))) AS "documents_validated",
    ("ds"."online_intent" AND ((EXISTS ( SELECT 1
           FROM "public"."driver_documents" "dd"
          WHERE (("dd"."driver_id" = "ds"."driver_id") AND ("dd"."document_type" = 'CNH_FRONT'::"text") AND ("dd"."status" = 'approved'::"public"."approval_status_enum") AND ("dd"."is_current" = true)))) AND (EXISTS ( SELECT 1
           FROM "public"."driver_documents" "dd"
          WHERE (("dd"."driver_id" = "ds"."driver_id") AND ("dd"."document_type" = 'CNH_BACK'::"text") AND ("dd"."status" = 'approved'::"public"."approval_status_enum") AND ("dd"."is_current" = true)))) AND (EXISTS ( SELECT 1
           FROM "public"."driver_documents" "dd"
          WHERE (("dd"."driver_id" = "ds"."driver_id") AND ("dd"."document_type" = 'CRLV'::"text") AND ("dd"."status" = 'approved'::"public"."approval_status_enum") AND ("dd"."is_current" = true)))) AND (EXISTS ( SELECT 1
           FROM "public"."driver_documents" "dd"
          WHERE (("dd"."driver_id" = "ds"."driver_id") AND ("dd"."document_type" = 'VEHICLE_FRONT'::"text") AND ("dd"."status" = 'approved'::"public"."approval_status_enum") AND ("dd"."is_current" = true)))))) AS "effective_online"
   FROM "public"."driver_status" "ds";


ALTER TABLE "public"."driver_effective_status" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."driver_excluded_zones" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "driver_id" "uuid" NOT NULL,
    "neighborhood_name" "text" NOT NULL,
    "city" "text" NOT NULL,
    "state" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."driver_excluded_zones" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."driver_excluded_zones_stats" AS
 SELECT "driver_excluded_zones"."driver_id",
    "count"(*) AS "total_excluded_zones",
    "array_agg"(DISTINCT "driver_excluded_zones"."city") AS "cities",
    "array_agg"(DISTINCT "driver_excluded_zones"."state") AS "states",
    "min"("driver_excluded_zones"."created_at") AS "first_exclusion_date",
    "max"("driver_excluded_zones"."created_at") AS "last_exclusion_date"
   FROM "public"."driver_excluded_zones"
  GROUP BY "driver_excluded_zones"."driver_id";


ALTER TABLE "public"."driver_excluded_zones_stats" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."driver_offers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "request_id" "uuid" NOT NULL,
    "driver_id" "uuid" NOT NULL,
    "driver_distance_km" numeric(10,2) NOT NULL,
    "driver_eta_minutes" integer NOT NULL,
    "base_fare" numeric(10,2) NOT NULL,
    "additional_fees" numeric(10,2) NOT NULL,
    "total_fare" numeric(10,2) NOT NULL,
    "distance_component" numeric(10,2),
    "time_component" numeric(10,2),
    "is_available" boolean DEFAULT true,
    "was_selected" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."driver_offers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."driver_operation_zones" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "driver_id" "uuid" NOT NULL,
    "zone_name" "text" NOT NULL,
    "polygon_coordinates" "jsonb" NOT NULL,
    "price_multiplier" numeric(4,2) DEFAULT 1.00 NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "driver_operation_zones_price_multiplier_check" CHECK ((("price_multiplier" >= 0.1) AND ("price_multiplier" <= 10.0)))
);


ALTER TABLE "public"."driver_operation_zones" OWNER TO "postgres";


COMMENT ON TABLE "public"."driver_operation_zones" IS 'Áreas de atuação do motorista com fatores de multiplicação de preço';



COMMENT ON COLUMN "public"."driver_operation_zones"."zone_name" IS 'Nome da área definido pelo motorista';



COMMENT ON COLUMN "public"."driver_operation_zones"."polygon_coordinates" IS 'Coordenadas do polígono em formato JSON: [{"lat": -23.5505, "lng": -46.6333}, ...]';



COMMENT ON COLUMN "public"."driver_operation_zones"."price_multiplier" IS 'Fator de multiplicação do preço (1.0 = normal, 1.5 = 50% a mais, etc.)';



COMMENT ON COLUMN "public"."driver_operation_zones"."is_active" IS 'Se a área está ativa para aplicação do multiplicador';



CREATE TABLE IF NOT EXISTS "public"."driver_operational_cities" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "driver_id" "uuid" NOT NULL,
    "city_id" "uuid" NOT NULL,
    "is_primary" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."driver_operational_cities" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."driver_schedule_overrides" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "driver_id" "uuid" NOT NULL,
    "override_start" timestamp with time zone NOT NULL,
    "override_end" timestamp with time zone NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "reason" "text",
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "override_future_start" CHECK (("override_start" >= ("now"() - '01:00:00'::interval))),
    CONSTRAINT "override_max_duration" CHECK (("override_end" <= ("override_start" + '24:00:00'::interval))),
    CONSTRAINT "override_valid_period" CHECK (("override_end" > "override_start"))
);


ALTER TABLE "public"."driver_schedule_overrides" OWNER TO "postgres";


COMMENT ON TABLE "public"."driver_schedule_overrides" IS 'Exceções temporárias aos horários normais de trabalho dos motoristas';



COMMENT ON COLUMN "public"."driver_schedule_overrides"."override_start" IS 'Início da exceção (timestamp UTC)';



COMMENT ON COLUMN "public"."driver_schedule_overrides"."override_end" IS 'Fim da exceção (timestamp UTC)';



COMMENT ON COLUMN "public"."driver_schedule_overrides"."reason" IS 'Motivo da exceção (ex: "Demanda alta na região")';



COMMENT ON COLUMN "public"."driver_schedule_overrides"."created_by" IS 'ID do usuário que criou a exceção (motorista ou admin)';



CREATE TABLE IF NOT EXISTS "public"."driver_schedules" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "driver_id" "uuid" NOT NULL,
    "day_of_week" integer NOT NULL,
    "start_time" time without time zone NOT NULL,
    "end_time" time without time zone NOT NULL,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "driver_schedules_day_of_week_check" CHECK ((("day_of_week" >= 0) AND ("day_of_week" <= 6)))
);


ALTER TABLE "public"."driver_schedules" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."driver_wallets" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "driver_id" "uuid" NOT NULL,
    "available_balance" numeric(10,2) DEFAULT 0,
    "pending_balance" numeric(10,2) DEFAULT 0,
    "total_earned" numeric(10,2) DEFAULT 0,
    "total_withdrawn" numeric(10,2) DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."driver_wallets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."drivers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "vehicle_brand" "text" NOT NULL,
    "vehicle_model" "text" NOT NULL,
    "vehicle_year" integer NOT NULL,
    "vehicle_color" "text" NOT NULL,
    "vehicle_plate" "text" NOT NULL,
    "vehicle_category" "text" NOT NULL,
    "approved_by" "uuid",
    "approved_at" timestamp with time zone,
    "is_online" boolean DEFAULT false,
    "accepts_pet" boolean DEFAULT false,
    "pet_fee" numeric(10,2) DEFAULT 0,
    "accepts_grocery" boolean DEFAULT false,
    "grocery_fee" numeric(10,2) DEFAULT 0,
    "accepts_condo" boolean DEFAULT false,
    "condo_fee" numeric(10,2) DEFAULT 0,
    "stop_fee" numeric(10,2) DEFAULT 0,
    "ac_policy" "text" DEFAULT 'on_request'::"text",
    "custom_price_per_km" numeric(10,2),
    "custom_price_per_minute" numeric(10,2),
    "bank_account_type" "text",
    "bank_code" "text",
    "bank_agency" "text",
    "bank_account" "text",
    "pix_key" "text",
    "pix_key_type" "text",
    "consecutive_cancellations" integer DEFAULT 0,
    "total_trips" integer DEFAULT 0,
    "average_rating" numeric(3,2),
    "current_latitude" numeric(10,8),
    "current_longitude" numeric(11,8),
    "last_location_update" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "fcm_token" "text",
    "device_platform" "text",
    "last_notification_at" timestamp with time zone,
    "approval_status" "public"."approval_status_enum" DEFAULT 'pending'::"public"."approval_status_enum",
    CONSTRAINT "drivers_ac_policy_check" CHECK (("ac_policy" = ANY (ARRAY['always_on'::"text", 'always_off'::"text", 'on_request'::"text"]))),
    CONSTRAINT "drivers_bank_account_type_check" CHECK (("bank_account_type" = ANY (ARRAY['checking'::"text", 'savings'::"text"]))),
    CONSTRAINT "drivers_device_platform_check" CHECK (("device_platform" = ANY (ARRAY['ios'::"text", 'android'::"text", 'web'::"text"]))),
    CONSTRAINT "drivers_pix_key_type_check" CHECK (("pix_key_type" = ANY (ARRAY['cpf'::"text", 'cnpj'::"text", 'email'::"text", 'phone'::"text", 'random'::"text"])))
);


ALTER TABLE "public"."drivers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."location_sharing" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "expires_at" timestamp with time zone NOT NULL,
    "shared_with_users" "uuid"[] DEFAULT '{}'::"uuid"[],
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "ended_at" timestamp with time zone
);


ALTER TABLE "public"."location_sharing" OWNER TO "postgres";


COMMENT ON TABLE "public"."location_sharing" IS 'Manages emergency location sharing sessions';



COMMENT ON COLUMN "public"."location_sharing"."expires_at" IS 'When the location sharing session expires';



COMMENT ON COLUMN "public"."location_sharing"."shared_with_users" IS 'Array of user IDs who can view the shared location';



COMMENT ON COLUMN "public"."location_sharing"."is_active" IS 'Whether the sharing session is currently active';



COMMENT ON COLUMN "public"."location_sharing"."ended_at" IS 'When the sharing session was manually ended';



CREATE TABLE IF NOT EXISTS "public"."location_updates" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "sharing_id" "uuid" NOT NULL,
    "latitude" double precision NOT NULL,
    "longitude" double precision NOT NULL,
    "timestamp" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."location_updates" OWNER TO "postgres";


COMMENT ON TABLE "public"."location_updates" IS 'Stores location updates during active sharing sessions';



CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "title" "text" NOT NULL,
    "body" "text" NOT NULL,
    "type" "text" NOT NULL,
    "data" "jsonb",
    "priority" "text" DEFAULT 'normal'::"text",
    "is_read" boolean DEFAULT false,
    "sent_at" timestamp with time zone DEFAULT "now"(),
    "read_at" timestamp with time zone,
    CONSTRAINT "notifications_priority_check" CHECK (("priority" = ANY (ARRAY['low'::"text", 'normal'::"text", 'high'::"text"]))),
    CONSTRAINT "notifications_type_check" CHECK (("type" = ANY (ARRAY['trip'::"text", 'promotion'::"text", 'system'::"text", 'chat'::"text", 'payment'::"text"])))
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."operational_cities" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "state" "text" NOT NULL,
    "country" "text" DEFAULT 'Brasil'::"text",
    "is_active" boolean DEFAULT true,
    "min_fare" numeric(10,2) DEFAULT 8.00,
    "launch_date" "date",
    "polygon_coordinates" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."operational_cities" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."passenger_promo_code_usage" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "promo_code_id" "uuid" NOT NULL,
    "trip_id" "uuid",
    "original_amount" numeric(10,2) NOT NULL,
    "discount_amount" numeric(10,2) NOT NULL,
    "final_amount" numeric(10,2) NOT NULL,
    "used_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "passenger_promo_code_usage_discount_amount_check" CHECK (("discount_amount" >= (0)::numeric)),
    CONSTRAINT "passenger_promo_code_usage_final_amount_check" CHECK (("final_amount" >= (0)::numeric)),
    CONSTRAINT "passenger_promo_code_usage_original_amount_check" CHECK (("original_amount" > (0)::numeric)),
    CONSTRAINT "valid_amounts_check" CHECK (("original_amount" = ("discount_amount" + "final_amount")))
);


ALTER TABLE "public"."passenger_promo_code_usage" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."passenger_promo_codes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" character varying(50) NOT NULL,
    "type" character varying(50) NOT NULL,
    "value" numeric(10,2) NOT NULL,
    "min_amount" numeric(10,2) DEFAULT 0.00 NOT NULL,
    "max_discount" numeric(10,2),
    "is_active" boolean DEFAULT true NOT NULL,
    "is_first_ride_only" boolean DEFAULT false NOT NULL,
    "usage_limit" integer,
    "usage_count" integer DEFAULT 0 NOT NULL,
    "valid_from" timestamp with time zone DEFAULT "now"() NOT NULL,
    "valid_until" timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "passenger_promo_codes_max_discount_check" CHECK ((("max_discount" IS NULL) OR ("max_discount" > (0)::numeric))),
    CONSTRAINT "passenger_promo_codes_min_amount_check" CHECK (("min_amount" >= (0)::numeric)),
    CONSTRAINT "passenger_promo_codes_type_check" CHECK ((("type")::"text" = ANY ((ARRAY['percentage'::character varying, 'fixed'::character varying, 'free_ride'::character varying])::"text"[]))),
    CONSTRAINT "passenger_promo_codes_usage_count_check" CHECK (("usage_count" >= 0)),
    CONSTRAINT "passenger_promo_codes_usage_limit_check" CHECK ((("usage_limit" IS NULL) OR ("usage_limit" > 0))),
    CONSTRAINT "passenger_promo_codes_value_check" CHECK (("value" > (0)::numeric)),
    CONSTRAINT "valid_dates_check" CHECK (("valid_from" < "valid_until"))
);


ALTER TABLE "public"."passenger_promo_codes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."passenger_wallet_transactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "wallet_id" "uuid" NOT NULL,
    "passenger_id" "uuid" NOT NULL,
    "type" character varying(50) NOT NULL,
    "amount" numeric(10,2) NOT NULL,
    "description" "text" NOT NULL,
    "trip_id" "uuid",
    "payment_method_id" "uuid",
    "asaas_payment_id" character varying(255),
    "status" character varying(50) DEFAULT 'pending'::character varying NOT NULL,
    "metadata" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "processed_at" timestamp with time zone,
    CONSTRAINT "passenger_wallet_transactions_amount_check" CHECK (("amount" > (0)::numeric)),
    CONSTRAINT "passenger_wallet_transactions_status_check" CHECK ((("status")::"text" = ANY ((ARRAY['pending'::character varying, 'processing'::character varying, 'completed'::character varying, 'failed'::character varying, 'cancelled'::character varying])::"text"[]))),
    CONSTRAINT "passenger_wallet_transactions_type_check" CHECK ((("type")::"text" = ANY ((ARRAY['credit'::character varying, 'trip_payment'::character varying, 'cashback'::character varying, 'refund'::character varying, 'cancellation_fee'::character varying])::"text"[])))
);


ALTER TABLE "public"."passenger_wallet_transactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."passenger_wallets" (
    "id" "uuid" NOT NULL,
    "passenger_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "available_balance" numeric(10,2) DEFAULT 0.00 NOT NULL,
    "pending_balance" numeric(10,2) DEFAULT 0.00 NOT NULL,
    "total_spent" numeric(10,2) DEFAULT 0.00 NOT NULL,
    "total_cashback" numeric(10,2) DEFAULT 0.00 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "passenger_wallets_available_balance_check" CHECK (("available_balance" >= (0)::numeric)),
    CONSTRAINT "passenger_wallets_pending_balance_check" CHECK (("pending_balance" >= (0)::numeric)),
    CONSTRAINT "passenger_wallets_total_cashback_check" CHECK (("total_cashback" >= (0)::numeric)),
    CONSTRAINT "passenger_wallets_total_spent_check" CHECK (("total_spent" >= (0)::numeric)),
    CONSTRAINT "wallet_id_equals_passenger_id" CHECK (("id" = "passenger_id"))
);


ALTER TABLE "public"."passenger_wallets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."passengers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "consecutive_cancellations" integer DEFAULT 0,
    "total_trips" integer DEFAULT 0,
    "average_rating" numeric(3,2),
    "payment_method_id" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."passengers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."payment_methods" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "type" character varying(50) NOT NULL,
    "is_default" boolean DEFAULT false NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "card_data" "jsonb",
    "pix_data" "jsonb",
    "asaas_customer_id" character varying(255),
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "payment_methods_type_check" CHECK ((("type")::"text" = ANY ((ARRAY['wallet'::character varying, 'credit_card'::character varying, 'debit_card'::character varying, 'pix'::character varying])::"text"[])))
);


ALTER TABLE "public"."payment_methods" OWNER TO "postgres";


COMMENT ON TABLE "public"."payment_methods" IS 'Métodos de pagamento dos usuários (PIX, Carteira Digital)';



COMMENT ON COLUMN "public"."payment_methods"."pix_data" IS 'JSON com dados do PIX: {"key_type": "cpf|email|phone|random_key", "key_value": "valor_da_chave", "qr_code_data": "dados_qr"}';



CREATE TABLE IF NOT EXISTS "public"."platform_settings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "category" "text" NOT NULL,
    "base_price_per_km" numeric(10,2) NOT NULL,
    "base_price_per_minute" numeric(10,2) NOT NULL,
    "platform_commission_percent" numeric(5,2) NOT NULL,
    "min_fare" numeric(10,2) DEFAULT 8.00,
    "min_cancellation_fee" numeric(10,2) DEFAULT 10.00,
    "cancellation_fee_percent" numeric(5,2) DEFAULT 20.00,
    "no_show_wait_minutes" integer DEFAULT 3,
    "driver_acceptance_timeout_seconds" integer DEFAULT 10,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."platform_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."promo_code_usage" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "promo_code_id" "uuid" NOT NULL,
    "passenger_id" "uuid" NOT NULL,
    "trip_id" "uuid",
    "discount_applied" numeric(10,2),
    "used_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."promo_code_usage" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."promo_codes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text" NOT NULL,
    "description" "text",
    "discount_type" "text" NOT NULL,
    "discount_value" numeric(10,2) NOT NULL,
    "max_discount" numeric(10,2),
    "min_trip_value" numeric(10,2),
    "max_uses_per_user" integer DEFAULT 1,
    "valid_from" timestamp with time zone NOT NULL,
    "valid_until" timestamp with time zone NOT NULL,
    "usage_limit" integer,
    "used_count" integer DEFAULT 0,
    "target_cities" "uuid"[] DEFAULT '{}'::"uuid"[],
    "target_categories" "text"[] DEFAULT '{}'::"text"[],
    "is_first_trip_only" boolean DEFAULT false,
    "is_active" boolean DEFAULT true,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "promo_codes_discount_type_check" CHECK (("discount_type" = ANY (ARRAY['percentage'::"text", 'fixed'::"text"])))
);


ALTER TABLE "public"."promo_codes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ratings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "trip_id" "uuid" NOT NULL,
    "passenger_rating" integer,
    "passenger_rating_tags" "text"[],
    "passenger_rating_comment" "text",
    "passenger_rated_at" timestamp with time zone,
    "driver_rating" integer,
    "driver_rating_tags" "text"[],
    "driver_rating_comment" "text",
    "driver_rated_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "ratings_driver_rating_check" CHECK ((("driver_rating" >= 1) AND ("driver_rating" <= 5))),
    CONSTRAINT "ratings_passenger_rating_check" CHECK ((("passenger_rating" >= 1) AND ("passenger_rating" <= 5)))
);


ALTER TABLE "public"."ratings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."saved_places" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "label" character varying(255) NOT NULL,
    "address" "text" NOT NULL,
    "latitude" numeric(10,8) NOT NULL,
    "longitude" numeric(11,8) NOT NULL,
    "category" character varying(50) DEFAULT 'other'::character varying NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."saved_places" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."trip_chats" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "trip_id" "uuid" NOT NULL,
    "sender_id" "uuid" NOT NULL,
    "message" "text" NOT NULL,
    "is_read" boolean DEFAULT false,
    "read_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."trip_chats" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."trip_code_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."trip_code_seq" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."trip_location_history" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "trip_id" "uuid" NOT NULL,
    "latitude" numeric(10,8) NOT NULL,
    "longitude" numeric(11,8) NOT NULL,
    "speed_kmh" numeric(5,2),
    "heading" numeric(5,2),
    "accuracy_meters" numeric(6,2),
    "recorded_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."trip_location_history" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."trip_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "passenger_id" "uuid" NOT NULL,
    "origin_address" "text" NOT NULL,
    "origin_latitude" numeric(10,8) NOT NULL,
    "origin_longitude" numeric(11,8) NOT NULL,
    "origin_neighborhood" "text",
    "destination_address" "text" NOT NULL,
    "destination_latitude" numeric(10,8) NOT NULL,
    "destination_longitude" numeric(11,8) NOT NULL,
    "destination_neighborhood" "text",
    "vehicle_category" "text" NOT NULL,
    "needs_pet" boolean DEFAULT false,
    "needs_grocery_space" boolean DEFAULT false,
    "needs_ac" boolean DEFAULT false,
    "is_condo_origin" boolean DEFAULT false,
    "is_condo_destination" boolean DEFAULT false,
    "number_of_stops" integer DEFAULT 0,
    "status" "text" DEFAULT 'searching'::"text",
    "selected_offer_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "expires_at" timestamp with time zone DEFAULT ("now"() + '00:00:10'::interval),
    "target_driver_id" "uuid",
    "fallback_drivers" "uuid"[],
    "accepted_by_driver_id" "uuid",
    "accepted_at" timestamp with time zone,
    "current_fallback_index" integer DEFAULT 0,
    "timeout_count" integer DEFAULT 0,
    "estimated_distance_km" numeric,
    "estimated_duration_minutes" integer,
    "estimated_fare" numeric,
    CONSTRAINT "trip_requests_status_check" CHECK (("status" = ANY (ARRAY['searching'::"text", 'driver_selected'::"text", 'expired'::"text", 'cancelled'::"text"]))),
    CONSTRAINT "trip_requests_vehicle_category_check" CHECK (("vehicle_category" = ANY (ARRAY['common_car'::"text", 'freight'::"text", 'tow_truck'::"text"])))
);


ALTER TABLE "public"."trip_requests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."trip_status_history" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "trip_id" "uuid" NOT NULL,
    "old_status" "text",
    "new_status" "text" NOT NULL,
    "changed_by" "uuid",
    "reason" "text",
    "metadata" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."trip_status_history" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."trip_stops" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "trip_id" "uuid" NOT NULL,
    "stop_order" integer NOT NULL,
    "address" "text" NOT NULL,
    "latitude" numeric(10,8) NOT NULL,
    "longitude" numeric(11,8) NOT NULL,
    "arrived_at" timestamp with time zone,
    "departed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."trip_stops" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."trips" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "trip_code" "text" NOT NULL,
    "request_id" "uuid",
    "passenger_id" "uuid" NOT NULL,
    "driver_id" "uuid" NOT NULL,
    "status" "text" NOT NULL,
    "origin_address" "text" NOT NULL,
    "origin_latitude" numeric(10,8) NOT NULL,
    "origin_longitude" numeric(11,8) NOT NULL,
    "origin_neighborhood" "text",
    "destination_address" "text" NOT NULL,
    "destination_latitude" numeric(10,8) NOT NULL,
    "destination_longitude" numeric(11,8) NOT NULL,
    "destination_neighborhood" "text",
    "vehicle_category" "text" NOT NULL,
    "needs_pet" boolean DEFAULT false,
    "needs_grocery_space" boolean DEFAULT false,
    "is_condo_destination" boolean DEFAULT false,
    "is_condo_origin" boolean DEFAULT false,
    "needs_ac" boolean DEFAULT false,
    "number_of_stops" integer DEFAULT 0,
    "route_polyline" "text",
    "estimated_distance_km" numeric(10,2),
    "estimated_duration_minutes" integer,
    "driver_to_pickup_distance_km" numeric(10,2),
    "driver_to_pickup_duration_minutes" integer,
    "actual_distance_km" numeric(10,2),
    "actual_duration_minutes" integer,
    "waiting_time_minutes" integer,
    "driver_distance_traveled_km" numeric(10,2),
    "base_fare" numeric(10,2) NOT NULL,
    "additional_fees" numeric(10,2) DEFAULT 0,
    "surge_multiplier" numeric(3,2) DEFAULT 1.0,
    "total_fare" numeric(10,2) NOT NULL,
    "platform_commission" numeric(10,2),
    "driver_earnings" numeric(10,2),
    "cancellation_reason" "text",
    "cancellation_fee" numeric(10,2),
    "cancelled_by" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "driver_assigned_at" timestamp with time zone,
    "driver_arrived_at" timestamp with time zone,
    "trip_started_at" timestamp with time zone,
    "trip_completed_at" timestamp with time zone,
    "cancelled_at" timestamp with time zone,
    "payment_status" "text" DEFAULT 'pending'::"text",
    "payment_id" "text",
    "payment_completed_at" timestamp with time zone,
    "promo_code_id" "uuid",
    "discount_applied" numeric(10,2),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "start_time" timestamp with time zone,
    "end_time" timestamp with time zone,
    "requested_at" timestamp with time zone,
    "completed_at" timestamp with time zone,
    "assigned_at" timestamp with time zone,
    "arrived_at" timestamp with time zone,
    CONSTRAINT "trips_cancelled_by_check" CHECK (("cancelled_by" = ANY (ARRAY['passenger'::"text", 'driver'::"text", 'system'::"text"]))),
    CONSTRAINT "trips_payment_status_check" CHECK (("payment_status" = ANY (ARRAY['pending'::"text", 'processing'::"text", 'completed'::"text", 'failed'::"text", 'refunded'::"text"]))),
    CONSTRAINT "trips_status_check" CHECK (("status" = ANY (ARRAY['driver_assigned'::"text", 'driver_arriving'::"text", 'waiting_passenger'::"text", 'in_progress'::"text", 'completed'::"text", 'cancelled_by_passenger'::"text", 'cancelled_by_driver'::"text", 'no_show'::"text"])))
);


ALTER TABLE "public"."trips" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_devices" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "device_token" "text" NOT NULL,
    "platform" "text" NOT NULL,
    "device_model" "text",
    "app_version" "text",
    "os_version" "text",
    "is_active" boolean DEFAULT true,
    "last_used_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "user_devices_platform_check" CHECK (("platform" = ANY (ARRAY['ios'::"text", 'android'::"text"])))
);


ALTER TABLE "public"."user_devices" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."wallet_transactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "wallet_id" "uuid" NOT NULL,
    "type" "text" NOT NULL,
    "amount" numeric(10,2) NOT NULL,
    "description" "text",
    "reference_type" "text",
    "reference_id" "uuid",
    "balance_after" numeric(10,2),
    "status" "text" DEFAULT 'completed'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "wallet_transactions_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'completed'::"text", 'failed'::"text", 'reversed'::"text"]))),
    CONSTRAINT "wallet_transactions_type_check" CHECK (("type" = ANY (ARRAY['earning'::"text", 'withdrawal'::"text", 'fee'::"text", 'bonus'::"text", 'penalty'::"text", 'adjustment'::"text"])))
);


ALTER TABLE "public"."wallet_transactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."withdrawals" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "driver_id" "uuid" NOT NULL,
    "wallet_id" "uuid" NOT NULL,
    "amount" numeric(10,2) NOT NULL,
    "withdrawal_method" "text",
    "bank_account_info" "jsonb",
    "asaas_transfer_id" "text",
    "status" "text" DEFAULT 'pending'::"text",
    "failure_reason" "text",
    "requested_at" timestamp with time zone DEFAULT "now"(),
    "processed_at" timestamp with time zone,
    "completed_at" timestamp with time zone,
    CONSTRAINT "withdrawals_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'processing'::"text", 'completed'::"text", 'failed'::"text", 'cancelled'::"text"]))),
    CONSTRAINT "withdrawals_withdrawal_method_check" CHECK (("withdrawal_method" = ANY (ARRAY['pix'::"text", 'bank_transfer'::"text"])))
);


ALTER TABLE "public"."withdrawals" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."working_hours" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "driver_id" "uuid" NOT NULL,
    "day_of_week" integer NOT NULL,
    "start_time" time without time zone NOT NULL,
    "end_time" time without time zone NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "working_hours_day_of_week_check" CHECK ((("day_of_week" >= 0) AND ("day_of_week" <= 6))),
    CONSTRAINT "working_hours_valid_time_range" CHECK (("start_time" < "end_time"))
);


ALTER TABLE "public"."working_hours" OWNER TO "postgres";


ALTER TABLE ONLY "public"."activity_logs"
    ADD CONSTRAINT "activity_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."app_users"
    ADD CONSTRAINT "app_users_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."app_users"
    ADD CONSTRAINT "app_users_phone_key" UNIQUE ("phone");



ALTER TABLE ONLY "public"."app_users"
    ADD CONSTRAINT "app_users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."asaas_webhook_events"
    ADD CONSTRAINT "asaas_webhook_events_asaas_event_id_key" UNIQUE ("asaas_event_id");



ALTER TABLE ONLY "public"."asaas_webhook_events"
    ADD CONSTRAINT "asaas_webhook_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."corrupted_users_backup"
    ADD CONSTRAINT "corrupted_users_backup_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."driver_approval_audit"
    ADD CONSTRAINT "driver_approval_audit_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."driver_documents"
    ADD CONSTRAINT "driver_documents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."driver_excluded_zones"
    ADD CONSTRAINT "driver_excluded_zones_driver_id_neighborhood_name_city_key" UNIQUE ("driver_id", "neighborhood_name", "city");



ALTER TABLE ONLY "public"."driver_excluded_zones"
    ADD CONSTRAINT "driver_excluded_zones_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."driver_offers"
    ADD CONSTRAINT "driver_offers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."driver_offers"
    ADD CONSTRAINT "driver_offers_request_id_driver_id_key" UNIQUE ("request_id", "driver_id");



ALTER TABLE ONLY "public"."driver_operation_zones"
    ADD CONSTRAINT "driver_operation_zones_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."driver_operational_cities"
    ADD CONSTRAINT "driver_operational_cities_driver_id_city_id_key" UNIQUE ("driver_id", "city_id");



ALTER TABLE ONLY "public"."driver_operational_cities"
    ADD CONSTRAINT "driver_operational_cities_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."driver_schedule_overrides"
    ADD CONSTRAINT "driver_schedule_overrides_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."driver_schedules"
    ADD CONSTRAINT "driver_schedules_driver_id_day_of_week_start_time_key" UNIQUE ("driver_id", "day_of_week", "start_time");



ALTER TABLE ONLY "public"."driver_schedules"
    ADD CONSTRAINT "driver_schedules_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."driver_status"
    ADD CONSTRAINT "driver_status_pkey" PRIMARY KEY ("driver_id");



ALTER TABLE ONLY "public"."driver_wallets"
    ADD CONSTRAINT "driver_wallets_driver_id_key" UNIQUE ("driver_id");



ALTER TABLE ONLY "public"."driver_wallets"
    ADD CONSTRAINT "driver_wallets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."drivers"
    ADD CONSTRAINT "drivers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."drivers"
    ADD CONSTRAINT "drivers_user_id_key" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."drivers"
    ADD CONSTRAINT "drivers_vehicle_plate_key" UNIQUE ("vehicle_plate");



ALTER TABLE ONLY "public"."location_sharing"
    ADD CONSTRAINT "location_sharing_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."location_updates"
    ADD CONSTRAINT "location_updates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."operational_cities"
    ADD CONSTRAINT "operational_cities_name_state_key" UNIQUE ("name", "state");



ALTER TABLE ONLY "public"."operational_cities"
    ADD CONSTRAINT "operational_cities_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."passenger_promo_code_usage"
    ADD CONSTRAINT "passenger_promo_code_usage_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."passenger_promo_codes"
    ADD CONSTRAINT "passenger_promo_codes_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."passenger_promo_codes"
    ADD CONSTRAINT "passenger_promo_codes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."passenger_wallet_transactions"
    ADD CONSTRAINT "passenger_wallet_transactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."passenger_wallets"
    ADD CONSTRAINT "passenger_wallets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."passengers"
    ADD CONSTRAINT "passengers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."passengers"
    ADD CONSTRAINT "passengers_user_id_key" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."payment_methods"
    ADD CONSTRAINT "payment_methods_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."platform_settings"
    ADD CONSTRAINT "platform_settings_category_key" UNIQUE ("category");



ALTER TABLE ONLY "public"."platform_settings"
    ADD CONSTRAINT "platform_settings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."promo_code_usage"
    ADD CONSTRAINT "promo_code_usage_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."promo_code_usage"
    ADD CONSTRAINT "promo_code_usage_promo_code_id_trip_id_key" UNIQUE ("promo_code_id", "trip_id");



ALTER TABLE ONLY "public"."promo_codes"
    ADD CONSTRAINT "promo_codes_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."promo_codes"
    ADD CONSTRAINT "promo_codes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ratings"
    ADD CONSTRAINT "ratings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ratings"
    ADD CONSTRAINT "ratings_trip_id_key" UNIQUE ("trip_id");



ALTER TABLE ONLY "public"."saved_places"
    ADD CONSTRAINT "saved_places_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."trip_chats"
    ADD CONSTRAINT "trip_chats_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."trip_location_history"
    ADD CONSTRAINT "trip_location_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."trip_requests"
    ADD CONSTRAINT "trip_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."trip_status_history"
    ADD CONSTRAINT "trip_status_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."trip_stops"
    ADD CONSTRAINT "trip_stops_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."trips"
    ADD CONSTRAINT "trips_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."trips"
    ADD CONSTRAINT "trips_trip_code_key" UNIQUE ("trip_code");



ALTER TABLE ONLY "public"."passenger_wallets"
    ADD CONSTRAINT "unique_passenger_wallet" UNIQUE ("passenger_id");



ALTER TABLE ONLY "public"."passenger_wallets"
    ADD CONSTRAINT "unique_user_wallet" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."user_devices"
    ADD CONSTRAINT "user_devices_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_devices"
    ADD CONSTRAINT "user_devices_user_id_device_token_key" UNIQUE ("user_id", "device_token");



ALTER TABLE ONLY "public"."wallet_transactions"
    ADD CONSTRAINT "wallet_transactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."withdrawals"
    ADD CONSTRAINT "withdrawals_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."working_hours"
    ADD CONSTRAINT "working_hours_no_duplicates" UNIQUE ("driver_id", "day_of_week", "start_time", "end_time", "is_active");



ALTER TABLE ONLY "public"."working_hours"
    ADD CONSTRAINT "working_hours_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_app_users_fcm_token" ON "public"."app_users" USING "btree" ("fcm_token") WHERE ("fcm_token" IS NOT NULL);



CREATE INDEX "idx_app_users_profile_complete" ON "public"."app_users" USING "btree" ("profile_complete");



CREATE INDEX "idx_asaas_webhook_events_event_id" ON "public"."asaas_webhook_events" USING "btree" ("asaas_event_id");



CREATE INDEX "idx_asaas_webhook_events_event_type" ON "public"."asaas_webhook_events" USING "btree" ("event_type");



CREATE INDEX "idx_asaas_webhook_events_payment_id" ON "public"."asaas_webhook_events" USING "btree" ("payment_id");



CREATE INDEX "idx_chat_trip" ON "public"."trip_chats" USING "btree" ("trip_id", "created_at");



CREATE INDEX "idx_corrupted_backup_timestamp" ON "public"."corrupted_users_backup" USING "btree" ("correction_timestamp");



CREATE INDEX "idx_corrupted_backup_user_id" ON "public"."corrupted_users_backup" USING "btree" ("original_user_id");



CREATE INDEX "idx_driver_approval_audit_created_at" ON "public"."driver_approval_audit" USING "btree" ("created_at");



CREATE INDEX "idx_driver_approval_audit_driver_id" ON "public"."driver_approval_audit" USING "btree" ("driver_id");



CREATE INDEX "idx_driver_offers_driver" ON "public"."driver_offers" USING "btree" ("driver_id", "created_at" DESC);



CREATE INDEX "idx_driver_offers_request" ON "public"."driver_offers" USING "btree" ("request_id", "is_available");



CREATE INDEX "idx_driver_operation_zones_active" ON "public"."driver_operation_zones" USING "btree" ("is_active");



CREATE INDEX "idx_driver_operation_zones_created_at" ON "public"."driver_operation_zones" USING "btree" ("created_at");



CREATE INDEX "idx_driver_operation_zones_driver_id" ON "public"."driver_operation_zones" USING "btree" ("driver_id");



CREATE INDEX "idx_driver_overrides_active" ON "public"."driver_schedule_overrides" USING "btree" ("is_active") WHERE ("is_active" = true);



CREATE INDEX "idx_driver_overrides_current" ON "public"."driver_schedule_overrides" USING "btree" ("driver_id", "override_start", "override_end") WHERE ("is_active" = true);



CREATE INDEX "idx_driver_overrides_driver_id" ON "public"."driver_schedule_overrides" USING "btree" ("driver_id");



CREATE INDEX "idx_driver_overrides_period" ON "public"."driver_schedule_overrides" USING "btree" ("override_start", "override_end");



CREATE INDEX "idx_driver_status_online_intent" ON "public"."driver_status" USING "btree" ("online_intent");



CREATE INDEX "idx_drivers_category" ON "public"."drivers" USING "btree" ("vehicle_category", "is_online") WHERE ("is_online" = true);



CREATE INDEX "idx_drivers_fcm_token" ON "public"."drivers" USING "btree" ("fcm_token") WHERE ("fcm_token" IS NOT NULL);



CREATE INDEX "idx_drivers_location" ON "public"."drivers" USING "btree" ("current_latitude", "current_longitude") WHERE ("is_online" = true);



CREATE INDEX "idx_drivers_online" ON "public"."drivers" USING "btree" ("is_online") WHERE ("is_online" = true);



CREATE INDEX "idx_excluded_zones_driver" ON "public"."driver_excluded_zones" USING "btree" ("driver_id");



CREATE INDEX "idx_excluded_zones_location" ON "public"."driver_excluded_zones" USING "btree" ("neighborhood_name", "city");



CREATE INDEX "idx_location_sharing_expires_at" ON "public"."location_sharing" USING "btree" ("expires_at");



CREATE INDEX "idx_location_sharing_is_active" ON "public"."location_sharing" USING "btree" ("is_active");



CREATE INDEX "idx_location_sharing_user_id" ON "public"."location_sharing" USING "btree" ("user_id");



CREATE INDEX "idx_location_updates_sharing_id" ON "public"."location_updates" USING "btree" ("sharing_id");



CREATE INDEX "idx_location_updates_timestamp" ON "public"."location_updates" USING "btree" ("timestamp");



CREATE INDEX "idx_notifications_user" ON "public"."notifications" USING "btree" ("user_id", "is_read", "sent_at" DESC);



CREATE INDEX "idx_passenger_promo_codes_code" ON "public"."passenger_promo_codes" USING "btree" ("code");



CREATE INDEX "idx_passenger_promo_codes_is_active" ON "public"."passenger_promo_codes" USING "btree" ("is_active");



CREATE INDEX "idx_passenger_promo_codes_valid_dates" ON "public"."passenger_promo_codes" USING "btree" ("valid_from", "valid_until");



CREATE INDEX "idx_passenger_wallets_passenger_id" ON "public"."passenger_wallets" USING "btree" ("passenger_id");



CREATE INDEX "idx_passenger_wallets_user_id" ON "public"."passenger_wallets" USING "btree" ("user_id");



CREATE INDEX "idx_payment_methods_is_active" ON "public"."payment_methods" USING "btree" ("is_active");



CREATE INDEX "idx_payment_methods_is_default" ON "public"."payment_methods" USING "btree" ("is_default");



CREATE INDEX "idx_payment_methods_type" ON "public"."payment_methods" USING "btree" ("type");



CREATE INDEX "idx_payment_methods_user_active" ON "public"."payment_methods" USING "btree" ("user_id", "is_active");



CREATE INDEX "idx_payment_methods_user_default" ON "public"."payment_methods" USING "btree" ("user_id", "is_default");



CREATE INDEX "idx_payment_methods_user_id" ON "public"."payment_methods" USING "btree" ("user_id");



CREATE INDEX "idx_ppcu_promo_code_id" ON "public"."passenger_promo_code_usage" USING "btree" ("promo_code_id");



CREATE INDEX "idx_ppcu_trip_id" ON "public"."passenger_promo_code_usage" USING "btree" ("trip_id");



CREATE INDEX "idx_ppcu_used_at" ON "public"."passenger_promo_code_usage" USING "btree" ("used_at");



CREATE INDEX "idx_ppcu_user_id" ON "public"."passenger_promo_code_usage" USING "btree" ("user_id");



CREATE INDEX "idx_pwt_asaas_payment_id" ON "public"."passenger_wallet_transactions" USING "btree" ("asaas_payment_id");



CREATE INDEX "idx_pwt_created_at" ON "public"."passenger_wallet_transactions" USING "btree" ("created_at");



CREATE INDEX "idx_pwt_passenger_id" ON "public"."passenger_wallet_transactions" USING "btree" ("passenger_id");



CREATE INDEX "idx_pwt_status" ON "public"."passenger_wallet_transactions" USING "btree" ("status");



CREATE INDEX "idx_pwt_type" ON "public"."passenger_wallet_transactions" USING "btree" ("type");



CREATE INDEX "idx_pwt_wallet_id" ON "public"."passenger_wallet_transactions" USING "btree" ("wallet_id");



CREATE INDEX "idx_trip_requests_accepted_by" ON "public"."trip_requests" USING "btree" ("accepted_by_driver_id");



CREATE INDEX "idx_trip_requests_passenger" ON "public"."trip_requests" USING "btree" ("passenger_id", "created_at" DESC);



CREATE INDEX "idx_trip_requests_status" ON "public"."trip_requests" USING "btree" ("status", "created_at" DESC);



CREATE INDEX "idx_trip_requests_status_expires" ON "public"."trip_requests" USING "btree" ("status", "expires_at");



CREATE INDEX "idx_trip_requests_target_driver" ON "public"."trip_requests" USING "btree" ("target_driver_id");



CREATE INDEX "idx_trips_created" ON "public"."trips" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_trips_driver" ON "public"."trips" USING "btree" ("driver_id", "created_at" DESC);



CREATE INDEX "idx_trips_passenger" ON "public"."trips" USING "btree" ("passenger_id", "created_at" DESC);



CREATE INDEX "idx_trips_payment_status" ON "public"."trips" USING "btree" ("payment_status") WHERE ("payment_status" <> 'completed'::"text");



CREATE INDEX "idx_trips_status" ON "public"."trips" USING "btree" ("status");



CREATE UNIQUE INDEX "idx_unique_default_payment_method" ON "public"."payment_methods" USING "btree" ("user_id") WHERE (("is_default" = true) AND ("is_active" = true));



CREATE INDEX "idx_wallet_transactions_wallet" ON "public"."wallet_transactions" USING "btree" ("wallet_id", "created_at" DESC);



CREATE INDEX "idx_withdrawals_driver" ON "public"."withdrawals" USING "btree" ("driver_id", "status");



CREATE INDEX "idx_working_hours_active" ON "public"."working_hours" USING "btree" ("is_active") WHERE ("is_active" = true);



CREATE INDEX "idx_working_hours_day_time" ON "public"."working_hours" USING "btree" ("day_of_week", "start_time", "end_time");



CREATE INDEX "idx_working_hours_driver_id" ON "public"."working_hours" USING "btree" ("driver_id");



CREATE OR REPLACE TRIGGER "bi_set_passenger_wallet_id" BEFORE INSERT ON "public"."passenger_wallets" FOR EACH ROW EXECUTE FUNCTION "public"."set_passenger_wallet_id"();



CREATE OR REPLACE TRIGGER "driver_suspension_trigger" AFTER UPDATE OF "consecutive_cancellations" ON "public"."drivers" FOR EACH ROW WHEN (("new"."consecutive_cancellations" >= 3)) EXECUTE FUNCTION "public"."check_suspension_policy"();



CREATE OR REPLACE TRIGGER "passenger_suspension_trigger" AFTER UPDATE OF "consecutive_cancellations" ON "public"."passengers" FOR EACH ROW WHEN (("new"."consecutive_cancellations" >= 3)) EXECUTE FUNCTION "public"."check_suspension_policy"();



CREATE OR REPLACE TRIGGER "trigger_create_passenger_wallet" AFTER INSERT ON "public"."passengers" FOR EACH ROW EXECUTE FUNCTION "public"."create_passenger_wallet_on_passenger_insert"();



CREATE OR REPLACE TRIGGER "trigger_driver_document_approval" AFTER INSERT OR UPDATE ON "public"."driver_documents" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_check_driver_approval"();



CREATE OR REPLACE TRIGGER "trigger_generate_trip_code" BEFORE INSERT ON "public"."trips" FOR EACH ROW EXECUTE FUNCTION "public"."generate_trip_code"();



CREATE OR REPLACE TRIGGER "trigger_update_driver_operation_zones_updated_at" BEFORE UPDATE ON "public"."driver_operation_zones" FOR EACH ROW EXECUTE FUNCTION "public"."update_driver_operation_zones_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_update_driver_status_on_document_approval" AFTER UPDATE ON "public"."driver_documents" FOR EACH ROW WHEN (("old"."status" IS DISTINCT FROM "new"."status")) EXECUTE FUNCTION "public"."update_driver_status_on_document_approval"();



CREATE OR REPLACE TRIGGER "trigger_update_metrics" AFTER UPDATE OF "status" ON "public"."trips" FOR EACH ROW EXECUTE FUNCTION "public"."update_user_metrics"();



CREATE OR REPLACE TRIGGER "trigger_update_override_timestamp" BEFORE UPDATE ON "public"."driver_schedule_overrides" FOR EACH ROW EXECUTE FUNCTION "public"."update_override_timestamp"();



CREATE OR REPLACE TRIGGER "trigger_update_ratings" AFTER INSERT OR UPDATE ON "public"."ratings" FOR EACH ROW EXECUTE FUNCTION "public"."update_average_rating"();



CREATE OR REPLACE TRIGGER "trip_completion_reset_trigger" AFTER UPDATE OF "status" ON "public"."trips" FOR EACH ROW WHEN (("new"."status" = 'completed'::"text")) EXECUTE FUNCTION "public"."reset_cancellations_on_trip_completion"();



CREATE OR REPLACE TRIGGER "update_app_users_updated_at" BEFORE UPDATE ON "public"."app_users" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_driver_documents_updated_at" BEFORE UPDATE ON "public"."driver_documents" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_driver_status_updated_at" BEFORE UPDATE ON "public"."driver_status" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_driver_wallets_updated_at" BEFORE UPDATE ON "public"."driver_wallets" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_drivers_updated_at" BEFORE UPDATE ON "public"."drivers" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_passenger_wallets_updated_at" BEFORE UPDATE ON "public"."passenger_wallets" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_passengers_updated_at" BEFORE UPDATE ON "public"."passengers" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_payment_methods_updated_at" BEFORE UPDATE ON "public"."payment_methods" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_trips_updated_at" BEFORE UPDATE ON "public"."trips" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_working_hours_updated_at" BEFORE UPDATE ON "public"."working_hours" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



ALTER TABLE ONLY "public"."activity_logs"
    ADD CONSTRAINT "activity_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."app_users"("id");



ALTER TABLE ONLY "public"."app_users"
    ADD CONSTRAINT "app_users_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."driver_approval_audit"
    ADD CONSTRAINT "driver_approval_audit_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "public"."drivers"("id");



ALTER TABLE ONLY "public"."driver_documents"
    ADD CONSTRAINT "driver_documents_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "public"."drivers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."driver_documents"
    ADD CONSTRAINT "driver_documents_reviewed_by_fkey" FOREIGN KEY ("reviewed_by") REFERENCES "public"."app_users"("id");



ALTER TABLE ONLY "public"."driver_excluded_zones"
    ADD CONSTRAINT "driver_excluded_zones_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "public"."drivers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."driver_offers"
    ADD CONSTRAINT "driver_offers_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "public"."drivers"("id");



ALTER TABLE ONLY "public"."driver_offers"
    ADD CONSTRAINT "driver_offers_request_id_fkey" FOREIGN KEY ("request_id") REFERENCES "public"."trip_requests"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."driver_operation_zones"
    ADD CONSTRAINT "driver_operation_zones_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "public"."drivers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."driver_operational_cities"
    ADD CONSTRAINT "driver_operational_cities_city_id_fkey" FOREIGN KEY ("city_id") REFERENCES "public"."operational_cities"("id");



ALTER TABLE ONLY "public"."driver_operational_cities"
    ADD CONSTRAINT "driver_operational_cities_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "public"."drivers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."driver_schedule_overrides"
    ADD CONSTRAINT "driver_schedule_overrides_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."drivers"("id");



ALTER TABLE ONLY "public"."driver_schedule_overrides"
    ADD CONSTRAINT "driver_schedule_overrides_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "public"."drivers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."driver_schedules"
    ADD CONSTRAINT "driver_schedules_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "public"."drivers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."driver_status"
    ADD CONSTRAINT "driver_status_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "public"."drivers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."driver_wallets"
    ADD CONSTRAINT "driver_wallets_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "public"."drivers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."drivers"
    ADD CONSTRAINT "drivers_approved_by_fkey" FOREIGN KEY ("approved_by") REFERENCES "public"."app_users"("id");



ALTER TABLE ONLY "public"."drivers"
    ADD CONSTRAINT "drivers_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."app_users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."drivers"
    ADD CONSTRAINT "drivers_vehicle_category_fkey" FOREIGN KEY ("vehicle_category") REFERENCES "public"."platform_settings"("category") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."location_sharing"
    ADD CONSTRAINT "location_sharing_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."app_users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."location_updates"
    ADD CONSTRAINT "location_updates_sharing_id_fkey" FOREIGN KEY ("sharing_id") REFERENCES "public"."location_sharing"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."app_users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."passenger_promo_code_usage"
    ADD CONSTRAINT "passenger_promo_code_usage_promo_code_id_fkey" FOREIGN KEY ("promo_code_id") REFERENCES "public"."passenger_promo_codes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."passenger_promo_code_usage"
    ADD CONSTRAINT "passenger_promo_code_usage_trip_id_fkey" FOREIGN KEY ("trip_id") REFERENCES "public"."trips"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."passenger_promo_code_usage"
    ADD CONSTRAINT "passenger_promo_code_usage_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."passenger_wallet_transactions"
    ADD CONSTRAINT "passenger_wallet_transactions_passenger_id_fkey" FOREIGN KEY ("passenger_id") REFERENCES "public"."passengers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."passenger_wallet_transactions"
    ADD CONSTRAINT "passenger_wallet_transactions_payment_method_id_fkey" FOREIGN KEY ("payment_method_id") REFERENCES "public"."payment_methods"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."passenger_wallet_transactions"
    ADD CONSTRAINT "passenger_wallet_transactions_trip_id_fkey" FOREIGN KEY ("trip_id") REFERENCES "public"."trips"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."passenger_wallet_transactions"
    ADD CONSTRAINT "passenger_wallet_transactions_wallet_id_fkey" FOREIGN KEY ("wallet_id") REFERENCES "public"."passenger_wallets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."passenger_wallets"
    ADD CONSTRAINT "passenger_wallets_passenger_id_fkey" FOREIGN KEY ("passenger_id") REFERENCES "public"."passengers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."passenger_wallets"
    ADD CONSTRAINT "passenger_wallets_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."passengers"
    ADD CONSTRAINT "passengers_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."app_users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."payment_methods"
    ADD CONSTRAINT "payment_methods_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."promo_code_usage"
    ADD CONSTRAINT "promo_code_usage_passenger_id_fkey" FOREIGN KEY ("passenger_id") REFERENCES "public"."passengers"("id");



ALTER TABLE ONLY "public"."promo_code_usage"
    ADD CONSTRAINT "promo_code_usage_promo_code_id_fkey" FOREIGN KEY ("promo_code_id") REFERENCES "public"."promo_codes"("id");



ALTER TABLE ONLY "public"."promo_code_usage"
    ADD CONSTRAINT "promo_code_usage_trip_id_fkey" FOREIGN KEY ("trip_id") REFERENCES "public"."trips"("id");



ALTER TABLE ONLY "public"."promo_codes"
    ADD CONSTRAINT "promo_codes_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."app_users"("id");



ALTER TABLE ONLY "public"."ratings"
    ADD CONSTRAINT "ratings_trip_id_fkey" FOREIGN KEY ("trip_id") REFERENCES "public"."trips"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."saved_places"
    ADD CONSTRAINT "saved_places_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."trip_chats"
    ADD CONSTRAINT "trip_chats_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "public"."app_users"("id");



ALTER TABLE ONLY "public"."trip_chats"
    ADD CONSTRAINT "trip_chats_trip_id_fkey" FOREIGN KEY ("trip_id") REFERENCES "public"."trips"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."trip_location_history"
    ADD CONSTRAINT "trip_location_history_trip_id_fkey" FOREIGN KEY ("trip_id") REFERENCES "public"."trips"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."trip_requests"
    ADD CONSTRAINT "trip_requests_accepted_by_driver_id_fkey" FOREIGN KEY ("accepted_by_driver_id") REFERENCES "public"."drivers"("id");



ALTER TABLE ONLY "public"."trip_requests"
    ADD CONSTRAINT "trip_requests_passenger_id_fkey" FOREIGN KEY ("passenger_id") REFERENCES "public"."passengers"("id");



ALTER TABLE ONLY "public"."trip_requests"
    ADD CONSTRAINT "trip_requests_target_driver_id_fkey" FOREIGN KEY ("target_driver_id") REFERENCES "public"."drivers"("id");



ALTER TABLE ONLY "public"."trip_status_history"
    ADD CONSTRAINT "trip_status_history_changed_by_fkey" FOREIGN KEY ("changed_by") REFERENCES "public"."app_users"("id");



ALTER TABLE ONLY "public"."trip_status_history"
    ADD CONSTRAINT "trip_status_history_trip_id_fkey" FOREIGN KEY ("trip_id") REFERENCES "public"."trips"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."trip_stops"
    ADD CONSTRAINT "trip_stops_trip_id_fkey" FOREIGN KEY ("trip_id") REFERENCES "public"."trips"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."trips"
    ADD CONSTRAINT "trips_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "public"."drivers"("id");



ALTER TABLE ONLY "public"."trips"
    ADD CONSTRAINT "trips_passenger_id_fkey" FOREIGN KEY ("passenger_id") REFERENCES "public"."passengers"("id");



ALTER TABLE ONLY "public"."trips"
    ADD CONSTRAINT "trips_request_id_fkey" FOREIGN KEY ("request_id") REFERENCES "public"."trip_requests"("id");



ALTER TABLE ONLY "public"."user_devices"
    ADD CONSTRAINT "user_devices_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."app_users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wallet_transactions"
    ADD CONSTRAINT "wallet_transactions_wallet_id_fkey" FOREIGN KEY ("wallet_id") REFERENCES "public"."driver_wallets"("id");



ALTER TABLE ONLY "public"."withdrawals"
    ADD CONSTRAINT "withdrawals_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "public"."drivers"("id");



ALTER TABLE ONLY "public"."withdrawals"
    ADD CONSTRAINT "withdrawals_wallet_id_fkey" FOREIGN KEY ("wallet_id") REFERENCES "public"."driver_wallets"("id");



CREATE POLICY "Enable insert for authenticated users only" ON "public"."app_users" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));



COMMENT ON POLICY "Enable insert for authenticated users only" ON "public"."app_users" IS 'Permite inserção apenas para usuários autenticados com seu próprio ID';



CREATE POLICY "Owners can view own photo" ON "public"."app_users" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "id"));



CREATE POLICY "System can insert location updates for active sessions" ON "public"."location_updates" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."location_sharing" "ls"
  WHERE (("ls"."id" = "location_updates"."sharing_id") AND ("ls"."is_active" = true) AND ("ls"."expires_at" > "now"())))));



CREATE POLICY "Users can create their own location sharing sessions" ON "public"."location_sharing" FOR INSERT WITH CHECK ((("auth"."uid"())::"text" = ("user_id")::"text"));



CREATE POLICY "Users can update own profile" ON "public"."app_users" FOR UPDATE USING (("auth"."uid"() = "id"));



COMMENT ON POLICY "Users can update own profile" ON "public"."app_users" IS 'Permite que usuários atualizem apenas seus próprios dados de perfil';



CREATE POLICY "Users can update their own location sharing sessions" ON "public"."location_sharing" FOR UPDATE USING ((("auth"."uid"())::"text" = ("user_id")::"text"));



CREATE POLICY "Users can view location updates for sessions they have access t" ON "public"."location_updates" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."location_sharing" "ls"
  WHERE (("ls"."id" = "location_updates"."sharing_id") AND ((("auth"."uid"())::"text" = ("ls"."user_id")::"text") OR (("auth"."uid"())::"text" = ANY (("ls"."shared_with_users")::"text"[])))))));



CREATE POLICY "Users can view own profile" ON "public"."app_users" FOR SELECT USING (("auth"."uid"() = "id"));



COMMENT ON POLICY "Users can view own profile" ON "public"."app_users" IS 'Permite que usuários vejam apenas seus próprios dados de perfil';



CREATE POLICY "Users can view their own location sharing sessions" ON "public"."location_sharing" FOR SELECT USING (((("auth"."uid"())::"text" = ("user_id")::"text") OR (("auth"."uid"())::"text" = ANY (("shared_with_users")::"text"[]))));



CREATE POLICY "admin can update any driver" ON "public"."drivers" FOR UPDATE TO "service_role" USING (true);



CREATE POLICY "drivers can update own record" ON "public"."drivers" FOR UPDATE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



ALTER TABLE "public"."location_sharing" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."location_updates" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "working_hours_delete_policy" ON "public"."working_hours" FOR DELETE USING (("driver_id" IN ( SELECT "drivers"."id"
   FROM "public"."drivers"
  WHERE ("drivers"."user_id" = "auth"."uid"()))));



CREATE POLICY "working_hours_insert_policy" ON "public"."working_hours" FOR INSERT WITH CHECK (("driver_id" IN ( SELECT "drivers"."id"
   FROM "public"."drivers"
  WHERE ("drivers"."user_id" = "auth"."uid"()))));



CREATE POLICY "working_hours_select_policy" ON "public"."working_hours" FOR SELECT USING (("driver_id" IN ( SELECT "drivers"."id"
   FROM "public"."drivers"
  WHERE ("drivers"."user_id" = "auth"."uid"()))));



CREATE POLICY "working_hours_update_policy" ON "public"."working_hours" FOR UPDATE USING (("driver_id" IN ( SELECT "drivers"."id"
   FROM "public"."drivers"
  WHERE ("drivers"."user_id" = "auth"."uid"())))) WITH CHECK (("driver_id" IN ( SELECT "drivers"."id"
   FROM "public"."drivers"
  WHERE ("drivers"."user_id" = "auth"."uid"()))));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";












REVOKE USAGE ON SCHEMA "public" FROM PUBLIC;
GRANT ALL ON SCHEMA "public" TO PUBLIC;
GRANT USAGE ON SCHEMA "public" TO "authenticated";
























SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



















































GRANT ALL ON FUNCTION "public"."archive_old_trips"() TO "anon";
GRANT ALL ON FUNCTION "public"."archive_old_trips"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."batch_correct_corrupted_users"("max_corrections" integer, "dry_run" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."batch_correct_corrupted_users"("max_corrections" integer, "dry_run" boolean) TO "authenticated";



GRANT ALL ON FUNCTION "public"."calculate_cancellation_fee"("p_trip_id" "uuid", "p_driver_current_lat" numeric, "p_driver_current_lng" numeric) TO "option_admin";
GRANT ALL ON FUNCTION "public"."calculate_cancellation_fee"("p_trip_id" "uuid", "p_driver_current_lat" numeric, "p_driver_current_lng" numeric) TO "option_app";
GRANT ALL ON FUNCTION "public"."calculate_cancellation_fee"("p_trip_id" "uuid", "p_driver_current_lat" numeric, "p_driver_current_lng" numeric) TO "anon";
GRANT ALL ON FUNCTION "public"."calculate_cancellation_fee"("p_trip_id" "uuid", "p_driver_current_lat" numeric, "p_driver_current_lng" numeric) TO "authenticated";



GRANT ALL ON FUNCTION "public"."check_and_suspend_user"("p_profile_id" "uuid", "p_user_type" "text") TO "option_admin";
GRANT ALL ON FUNCTION "public"."check_and_suspend_user"("p_profile_id" "uuid", "p_user_type" "text") TO "option_app";
GRANT ALL ON FUNCTION "public"."check_and_suspend_user"("p_profile_id" "uuid", "p_user_type" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."check_and_suspend_user"("p_profile_id" "uuid", "p_user_type" "text") TO "authenticated";



GRANT ALL ON FUNCTION "public"."check_driver_documents_approved"("driver_uuid" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_driver_documents_approved"("driver_uuid" "uuid") TO "anon";



GRANT ALL ON FUNCTION "public"."check_migration_health"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_migration_health"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."cleanup_expired_requests"() TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_expired_requests"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."cleanup_migration_backup"() TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_migration_backup"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."controlled_sync_auth_to_app"() TO "anon";
GRANT ALL ON FUNCTION "public"."controlled_sync_auth_to_app"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."create_migration_backup"() TO "anon";
GRANT ALL ON FUNCTION "public"."create_migration_backup"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."create_passenger_wallet_on_passenger_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."create_passenger_wallet_on_passenger_insert"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."data_correction_summary"() TO "anon";
GRANT ALL ON FUNCTION "public"."data_correction_summary"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."delete_profile"() TO "anon";
GRANT ALL ON FUNCTION "public"."delete_profile"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."diagnose_signup_issues_safe"() TO "anon";
GRANT ALL ON FUNCTION "public"."diagnose_signup_issues_safe"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."disable_auth_sync"("feature_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."disable_auth_sync"("feature_name" "text") TO "authenticated";



GRANT ALL ON FUNCTION "public"."enable_auth_sync"("feature_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."enable_auth_sync"("feature_name" "text") TO "authenticated";



GRANT ALL ON FUNCTION "public"."execute_migration_rollback"() TO "anon";
GRANT ALL ON FUNCTION "public"."execute_migration_rollback"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."find_available_drivers"("p_request_id" "uuid", "p_origin_lat" numeric, "p_origin_lng" numeric, "p_dest_lat" numeric, "p_dest_lng" numeric, "p_category" "text", "p_needs_pet" boolean, "p_needs_grocery" boolean, "p_needs_ac" boolean, "p_is_condo_origin" boolean, "p_is_condo_dest" boolean, "p_stops" integer, "p_origin_neighborhood" "text", "p_dest_neighborhood" "text") TO "option_admin";
GRANT ALL ON FUNCTION "public"."find_available_drivers"("p_request_id" "uuid", "p_origin_lat" numeric, "p_origin_lng" numeric, "p_dest_lat" numeric, "p_dest_lng" numeric, "p_category" "text", "p_needs_pet" boolean, "p_needs_grocery" boolean, "p_needs_ac" boolean, "p_is_condo_origin" boolean, "p_is_condo_dest" boolean, "p_stops" integer, "p_origin_neighborhood" "text", "p_dest_neighborhood" "text") TO "option_app";
GRANT ALL ON FUNCTION "public"."find_available_drivers"("p_request_id" "uuid", "p_origin_lat" numeric, "p_origin_lng" numeric, "p_dest_lat" numeric, "p_dest_lng" numeric, "p_category" "text", "p_needs_pet" boolean, "p_needs_grocery" boolean, "p_needs_ac" boolean, "p_is_condo_origin" boolean, "p_is_condo_dest" boolean, "p_stops" integer, "p_origin_neighborhood" "text", "p_dest_neighborhood" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."find_available_drivers"("p_request_id" "uuid", "p_origin_lat" numeric, "p_origin_lng" numeric, "p_dest_lat" numeric, "p_dest_lng" numeric, "p_category" "text", "p_needs_pet" boolean, "p_needs_grocery" boolean, "p_needs_ac" boolean, "p_is_condo_origin" boolean, "p_is_condo_dest" boolean, "p_stops" integer, "p_origin_neighborhood" "text", "p_dest_neighborhood" "text") TO "authenticated";



GRANT ALL ON FUNCTION "public"."generate_trip_code"() TO "option_admin";
GRANT ALL ON FUNCTION "public"."generate_trip_code"() TO "option_app";
GRANT ALL ON FUNCTION "public"."generate_trip_code"() TO "anon";
GRANT ALL ON FUNCTION "public"."generate_trip_code"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."get_available_categories_stats"("lat" double precision, "lng" double precision, "radius_km" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."get_available_categories_stats"("lat" double precision, "lng" double precision, "radius_km" double precision) TO "authenticated";



GRANT ALL ON FUNCTION "public"."get_driver_document_signed_url"("doc_id" "uuid", "expires_in" interval) TO "option_app";
GRANT ALL ON FUNCTION "public"."get_driver_document_signed_url"("doc_id" "uuid", "expires_in" interval) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_driver_document_signed_url"("doc_id" "uuid", "expires_in" interval) TO "option_admin";



GRANT ALL ON FUNCTION "public"."identify_corrupted_users"() TO "anon";
GRANT ALL ON FUNCTION "public"."identify_corrupted_users"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."insert_profile"() TO "anon";
GRANT ALL ON FUNCTION "public"."insert_profile"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."invalidate_driver_document_urls"("target_driver_id" "uuid", "document_type_filter" "text") TO "option_app";
GRANT ALL ON FUNCTION "public"."invalidate_driver_document_urls"("target_driver_id" "uuid", "document_type_filter" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."invalidate_driver_document_urls"("target_driver_id" "uuid", "document_type_filter" "text") TO "option_admin";



GRANT ALL ON FUNCTION "public"."is_sync_enabled"("feature_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."is_sync_enabled"("feature_name" "text") TO "authenticated";



GRANT ALL ON FUNCTION "public"."monitor_migration_progress"() TO "anon";
GRANT ALL ON FUNCTION "public"."monitor_migration_progress"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."process_trip_payment"("p_trip_id" "uuid") TO "option_admin";
GRANT ALL ON FUNCTION "public"."process_trip_payment"("p_trip_id" "uuid") TO "option_app";
GRANT ALL ON FUNCTION "public"."process_trip_payment"("p_trip_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."process_trip_payment"("p_trip_id" "uuid") TO "authenticated";



GRANT ALL ON FUNCTION "public"."restore_user_data"("target_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."restore_user_data"("target_user_id" "uuid") TO "authenticated";



GRANT ALL ON FUNCTION "public"."safe_correct_user_data"("target_user_id" "uuid", "new_full_name" "text", "new_phone" "text", "dry_run" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."safe_correct_user_data"("target_user_id" "uuid", "new_full_name" "text", "new_phone" "text", "dry_run" boolean) TO "authenticated";



GRANT ALL ON FUNCTION "public"."set_passenger_wallet_id"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_passenger_wallet_id"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."sync_app_users_to_auth"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_app_users_to_auth"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."sync_status_report"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_status_report"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."update_average_rating"() TO "option_admin";
GRANT ALL ON FUNCTION "public"."update_average_rating"() TO "option_app";
GRANT ALL ON FUNCTION "public"."update_average_rating"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_average_rating"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."update_driver_operation_zones_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_driver_operation_zones_updated_at"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."update_profile"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_profile"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "option_admin";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "option_app";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."update_user_metrics"() TO "option_admin";
GRANT ALL ON FUNCTION "public"."update_user_metrics"() TO "option_app";
GRANT ALL ON FUNCTION "public"."update_user_metrics"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_user_metrics"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."validate_data_integrity"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_data_integrity"() TO "authenticated";



GRANT ALL ON FUNCTION "public"."validate_sync_data"("email" "text", "full_name" "text", "phone" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."validate_sync_data"("email" "text", "full_name" "text", "phone" "text") TO "authenticated";




































GRANT ALL ON TABLE "public"."activity_logs" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."activity_logs" TO "option_app";
GRANT ALL ON TABLE "public"."activity_logs" TO "anon";
GRANT ALL ON TABLE "public"."activity_logs" TO "authenticated";



GRANT ALL ON TABLE "public"."app_users" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."app_users" TO "option_app";
GRANT ALL ON TABLE "public"."app_users" TO "authenticated";
GRANT ALL ON TABLE "public"."app_users" TO "anon";



GRANT ALL ON TABLE "public"."backup_app_users_migration" TO "anon";
GRANT ALL ON TABLE "public"."backup_app_users_migration" TO "authenticated";



GRANT ALL ON TABLE "public"."backup_drivers_migration" TO "anon";
GRANT ALL ON TABLE "public"."backup_drivers_migration" TO "authenticated";



GRANT ALL ON TABLE "public"."backup_passengers_migration" TO "anon";
GRANT ALL ON TABLE "public"."backup_passengers_migration" TO "authenticated";



GRANT ALL ON TABLE "public"."corrupted_users_backup" TO "anon";
GRANT ALL ON TABLE "public"."corrupted_users_backup" TO "authenticated";



GRANT ALL ON TABLE "public"."driver_documents" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."driver_documents" TO "option_app";
GRANT ALL ON TABLE "public"."driver_documents" TO "anon";
GRANT ALL ON TABLE "public"."driver_documents" TO "authenticated";



GRANT SELECT ON TABLE "public"."driver_current_documents" TO "option_app";
GRANT SELECT ON TABLE "public"."driver_current_documents" TO "authenticated";
GRANT SELECT ON TABLE "public"."driver_current_documents" TO "anon";
GRANT SELECT ON TABLE "public"."driver_current_documents" TO "option_admin";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "public"."driver_status" TO "authenticated";
GRANT SELECT ON TABLE "public"."driver_status" TO "anon";



GRANT SELECT ON TABLE "public"."driver_effective_status" TO "authenticated";
GRANT SELECT ON TABLE "public"."driver_effective_status" TO "anon";



GRANT ALL ON TABLE "public"."driver_excluded_zones" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."driver_excluded_zones" TO "option_app";
GRANT ALL ON TABLE "public"."driver_excluded_zones" TO "anon";
GRANT ALL ON TABLE "public"."driver_excluded_zones" TO "authenticated";



GRANT SELECT ON TABLE "public"."driver_excluded_zones_stats" TO "option_app";
GRANT SELECT ON TABLE "public"."driver_excluded_zones_stats" TO "authenticated";
GRANT SELECT ON TABLE "public"."driver_excluded_zones_stats" TO "anon";
GRANT ALL ON TABLE "public"."driver_excluded_zones_stats" TO "option_admin";



GRANT ALL ON TABLE "public"."driver_offers" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."driver_offers" TO "option_app";
GRANT ALL ON TABLE "public"."driver_offers" TO "anon";
GRANT ALL ON TABLE "public"."driver_offers" TO "authenticated";



GRANT ALL ON TABLE "public"."driver_operation_zones" TO "anon";
GRANT ALL ON TABLE "public"."driver_operation_zones" TO "authenticated";



GRANT ALL ON TABLE "public"."driver_operational_cities" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."driver_operational_cities" TO "option_app";
GRANT ALL ON TABLE "public"."driver_operational_cities" TO "anon";
GRANT ALL ON TABLE "public"."driver_operational_cities" TO "authenticated";



GRANT ALL ON TABLE "public"."driver_schedules" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."driver_schedules" TO "option_app";
GRANT ALL ON TABLE "public"."driver_schedules" TO "anon";
GRANT ALL ON TABLE "public"."driver_schedules" TO "authenticated";



GRANT ALL ON TABLE "public"."driver_wallets" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."driver_wallets" TO "option_app";
GRANT ALL ON TABLE "public"."driver_wallets" TO "anon";
GRANT ALL ON TABLE "public"."driver_wallets" TO "authenticated";



GRANT ALL ON TABLE "public"."drivers" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."drivers" TO "option_app";
GRANT ALL ON TABLE "public"."drivers" TO "anon";
GRANT ALL ON TABLE "public"."drivers" TO "authenticated";
GRANT ALL ON TABLE "public"."drivers" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."notifications" TO "option_app";
GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";



GRANT ALL ON TABLE "public"."operational_cities" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."operational_cities" TO "option_app";
GRANT ALL ON TABLE "public"."operational_cities" TO "anon";
GRANT ALL ON TABLE "public"."operational_cities" TO "authenticated";



GRANT ALL ON TABLE "public"."passenger_promo_code_usage" TO "authenticated";
GRANT ALL ON TABLE "public"."passenger_promo_code_usage" TO "anon";



GRANT ALL ON TABLE "public"."passenger_promo_codes" TO "authenticated";
GRANT ALL ON TABLE "public"."passenger_promo_codes" TO "anon";



GRANT ALL ON TABLE "public"."passenger_wallet_transactions" TO "authenticated";
GRANT ALL ON TABLE "public"."passenger_wallet_transactions" TO "anon";



GRANT ALL ON TABLE "public"."passenger_wallets" TO "authenticated";
GRANT ALL ON TABLE "public"."passenger_wallets" TO "anon";



GRANT ALL ON TABLE "public"."passengers" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."passengers" TO "option_app";
GRANT ALL ON TABLE "public"."passengers" TO "anon";
GRANT ALL ON TABLE "public"."passengers" TO "authenticated";



GRANT ALL ON TABLE "public"."payment_methods" TO "authenticated";
GRANT ALL ON TABLE "public"."payment_methods" TO "anon";



GRANT ALL ON TABLE "public"."platform_settings" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."platform_settings" TO "option_app";
GRANT ALL ON TABLE "public"."platform_settings" TO "anon";
GRANT ALL ON TABLE "public"."platform_settings" TO "authenticated";



GRANT ALL ON TABLE "public"."promo_code_usage" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."promo_code_usage" TO "option_app";
GRANT ALL ON TABLE "public"."promo_code_usage" TO "anon";
GRANT ALL ON TABLE "public"."promo_code_usage" TO "authenticated";



GRANT ALL ON TABLE "public"."promo_codes" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."promo_codes" TO "option_app";
GRANT ALL ON TABLE "public"."promo_codes" TO "anon";
GRANT ALL ON TABLE "public"."promo_codes" TO "authenticated";



GRANT ALL ON TABLE "public"."ratings" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."ratings" TO "option_app";
GRANT ALL ON TABLE "public"."ratings" TO "anon";
GRANT ALL ON TABLE "public"."ratings" TO "authenticated";



GRANT ALL ON TABLE "public"."saved_places" TO "anon";
GRANT ALL ON TABLE "public"."saved_places" TO "authenticated";
GRANT ALL ON TABLE "public"."saved_places" TO "service_role";



GRANT ALL ON TABLE "public"."trip_chats" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."trip_chats" TO "option_app";
GRANT ALL ON TABLE "public"."trip_chats" TO "anon";
GRANT ALL ON TABLE "public"."trip_chats" TO "authenticated";



GRANT ALL ON SEQUENCE "public"."trip_code_seq" TO "option_admin";
GRANT USAGE ON SEQUENCE "public"."trip_code_seq" TO "option_app";
GRANT ALL ON SEQUENCE "public"."trip_code_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."trip_code_seq" TO "authenticated";



GRANT ALL ON TABLE "public"."trip_location_history" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."trip_location_history" TO "option_app";
GRANT ALL ON TABLE "public"."trip_location_history" TO "anon";
GRANT ALL ON TABLE "public"."trip_location_history" TO "authenticated";



GRANT ALL ON TABLE "public"."trip_requests" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."trip_requests" TO "option_app";
GRANT ALL ON TABLE "public"."trip_requests" TO "anon";
GRANT ALL ON TABLE "public"."trip_requests" TO "authenticated";



GRANT ALL ON TABLE "public"."trip_status_history" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."trip_status_history" TO "option_app";
GRANT ALL ON TABLE "public"."trip_status_history" TO "anon";
GRANT ALL ON TABLE "public"."trip_status_history" TO "authenticated";



GRANT ALL ON TABLE "public"."trip_stops" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."trip_stops" TO "option_app";
GRANT ALL ON TABLE "public"."trip_stops" TO "anon";
GRANT ALL ON TABLE "public"."trip_stops" TO "authenticated";



GRANT ALL ON TABLE "public"."trips" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."trips" TO "option_app";
GRANT ALL ON TABLE "public"."trips" TO "anon";
GRANT ALL ON TABLE "public"."trips" TO "authenticated";



GRANT ALL ON TABLE "public"."user_devices" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."user_devices" TO "option_app";
GRANT ALL ON TABLE "public"."user_devices" TO "anon";
GRANT ALL ON TABLE "public"."user_devices" TO "authenticated";



GRANT ALL ON TABLE "public"."wallet_transactions" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."wallet_transactions" TO "option_app";
GRANT ALL ON TABLE "public"."wallet_transactions" TO "anon";
GRANT ALL ON TABLE "public"."wallet_transactions" TO "authenticated";



GRANT ALL ON TABLE "public"."withdrawals" TO "option_admin";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."withdrawals" TO "option_app";
GRANT ALL ON TABLE "public"."withdrawals" TO "anon";
GRANT ALL ON TABLE "public"."withdrawals" TO "authenticated";

































RESET ALL;
