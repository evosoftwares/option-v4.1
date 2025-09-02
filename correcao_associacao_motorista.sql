-- =============================================
-- CORREÇÃO AUTOMÁTICA DE ASSOCIAÇÃO DE PERFIL DE MOTORISTA
-- Execute este script no Supabase SQL Editor
-- =============================================

-- PASSO 1: Criar função para corrigir associações de motorista
CREATE OR REPLACE FUNCTION fix_driver_associations()
RETURNS TABLE(
    user_id UUID,
    email TEXT,
    full_name TEXT,
    action_taken TEXT,
    success BOOLEAN,
    error_message TEXT
) AS $$
DECLARE
    user_record RECORD;
    driver_data JSONB;
    error_msg TEXT;
BEGIN
    -- Iterar sobre usuários com user_type='driver' que não têm registro na tabela drivers
    FOR user_record IN 
        SELECT au.id, au.email, au.full_name, au.created_at
        FROM app_users au
        WHERE au.user_type = 'driver'
            AND NOT EXISTS (
                SELECT 1 FROM drivers d 
                WHERE d.user_id = au.id
            )
        ORDER BY au.created_at
    LOOP
        BEGIN
            -- Preparar dados do motorista com valores placeholder
            driver_data := jsonb_build_object(
                'user_id', user_record.id,
                'cnh_number', 'PENDENTE_CADASTRO',
                'cnh_expiry_date', (CURRENT_DATE + INTERVAL '365 days')::DATE,
                'cnh_photo_url', '',
                'vehicle_brand', 'PENDENTE',
                'vehicle_model', 'PENDENTE',
                'vehicle_year', 2020,
                'vehicle_color', 'PENDENTE',
                'vehicle_plate', 'PENDENTE',
                'vehicle_category', 'standard',
                'crlv_photo_url', '',
                'approval_status', 'pending',
                'approved_by', NULL,
                'approved_at', NULL,
                'is_online', false,
                'accepts_pet', false,
                'pet_fee', 0.0,
                'accepts_grocery', false,
                'grocery_fee', 0.0,
                'accepts_condo', false,
                'condo_fee', 0.0,
                'stop_fee', 0.0,
                'ac_policy', 'on_request',
                'custom_price_per_km', 0.0,
                'custom_price_per_minute', 0.0,
                'bank_account_type', NULL,
                'bank_code', NULL,
                'bank_agency', NULL,
                'bank_account', NULL,
                'pix_key', '',
                'pix_key_type', 'email',
                'consecutive_cancellations', 0,
                'total_trips', 0,
                'average_rating', NULL,
                'current_latitude', NULL,
                'current_longitude', NULL,
                'last_location_update', NULL,
                'created_at', NOW(),
                'updated_at', NOW()
            );
            
            -- Inserir registro de motorista
            INSERT INTO drivers (
                user_id, cnh_number, cnh_expiry_date, cnh_photo_url,
                vehicle_brand, vehicle_model, vehicle_year, vehicle_color, vehicle_plate, vehicle_category,
                crlv_photo_url, approval_status, approved_by, approved_at,
                is_online, accepts_pet, pet_fee, accepts_grocery, grocery_fee,
                accepts_condo, condo_fee, stop_fee, ac_policy,
                custom_price_per_km, custom_price_per_minute,
                bank_account_type, bank_code, bank_agency, bank_account,
                pix_key, pix_key_type, consecutive_cancellations, total_trips,
                average_rating, current_latitude, current_longitude, last_location_update,
                created_at, updated_at
            ) VALUES (
                user_record.id, 'PENDENTE_CADASTRO', (CURRENT_DATE + INTERVAL '365 days')::DATE, '',
                'PENDENTE', 'PENDENTE', 2020, 'PENDENTE', 'PENDENTE', 'standard',
                '', 'pending', NULL, NULL,
                false, false, 0.0, false, 0.0,
                false, 0.0, 0.0, 'on_request',
                0.0, 0.0,
                NULL, NULL, NULL, NULL,
                '', 'email', 0, 0,
                NULL, NULL, NULL, NULL,
                NOW(), NOW()
            );
            
            -- Retornar sucesso
            user_id := user_record.id;
            email := user_record.email;
            full_name := user_record.full_name;
            action_taken := 'DRIVER_RECORD_CREATED';
            success := true;
            error_message := NULL;
            RETURN NEXT;
            
        EXCEPTION WHEN OTHERS THEN
            -- Capturar erro e continuar com próximo usuário
            error_msg := SQLERRM;
            
            user_id := user_record.id;
            email := user_record.email;
            full_name := user_record.full_name;
            action_taken := 'FAILED_TO_CREATE';
            success := false;
            error_message := error_msg;
            RETURN NEXT;
        END;
    END LOOP;
    
    RETURN;
END;
$$ LANGUAGE plpgsql;

-- PASSO 2: Executar a correção e mostrar resultados
SELECT 
    'CORREÇÃO AUTOMÁTICA EXECUTADA' as status,
    COUNT(*) as total_processados,
    COUNT(*) FILTER (WHERE success = true) as sucessos,
    COUNT(*) FILTER (WHERE success = false) as falhas
FROM fix_driver_associations();

-- PASSO 3: Mostrar detalhes da correção
SELECT 
    user_id,
    email,
    full_name,
    action_taken,
    success,
    error_message
FROM fix_driver_associations()
ORDER BY success DESC, email;

-- PASSO 4: Verificar resultado da correção
SELECT 
    'VERIFICAÇÃO PÓS-CORREÇÃO' as status,
    (
        SELECT COUNT(*) FROM app_users 
        WHERE user_type = 'driver'
    ) as total_users_driver,
    (
        SELECT COUNT(*) FROM drivers
    ) as total_registros_drivers,
    (
        SELECT COUNT(*) FROM app_users au
        WHERE au.user_type = 'driver'
            AND NOT EXISTS (
                SELECT 1 FROM drivers d 
                WHERE d.user_id = au.id
            )
    ) as ainda_sem_perfil;

-- PASSO 5: Criar função para correção automática futura (trigger)
CREATE OR REPLACE FUNCTION auto_create_driver_record()
RETURNS TRIGGER AS $$
BEGIN
    -- Se o user_type foi alterado para 'driver' e não existe registro na tabela drivers
    IF NEW.user_type = 'driver' AND (OLD.user_type IS NULL OR OLD.user_type != 'driver') THEN
        -- Verificar se já existe registro de motorista
        IF NOT EXISTS (SELECT 1 FROM drivers WHERE user_id = NEW.id) THEN
            -- Criar registro básico de motorista
            INSERT INTO drivers (
                user_id, cnh_number, cnh_expiry_date, cnh_photo_url,
                vehicle_brand, vehicle_model, vehicle_year, vehicle_color, vehicle_plate, vehicle_category,
                crlv_photo_url, approval_status, approved_by, approved_at,
                is_online, accepts_pet, pet_fee, accepts_grocery, grocery_fee,
                accepts_condo, condo_fee, stop_fee, ac_policy,
                custom_price_per_km, custom_price_per_minute,
                bank_account_type, bank_code, bank_agency, bank_account,
                pix_key, pix_key_type, consecutive_cancellations, total_trips,
                average_rating, current_latitude, current_longitude, last_location_update,
                created_at, updated_at
            ) VALUES (
                NEW.id, 'PENDENTE_CADASTRO', (CURRENT_DATE + INTERVAL '365 days')::DATE, '',
                'PENDENTE', 'PENDENTE', 2020, 'PENDENTE', 'PENDENTE', 'standard',
                '', 'pending', NULL, NULL,
                false, false, 0.0, false, 0.0,
                false, 0.0, 0.0, 'on_request',
                0.0, 0.0,
                NULL, NULL, NULL, NULL,
                '', 'email', 0, 0,
                NULL, NULL, NULL, NULL,
                NOW(), NOW()
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- PASSO 6: Criar trigger para criação automática futura
DROP TRIGGER IF EXISTS auto_create_driver_record_trigger ON app_users;
CREATE TRIGGER auto_create_driver_record_trigger
    AFTER UPDATE OF user_type ON app_users
    FOR EACH ROW
    EXECUTE FUNCTION auto_create_driver_record();

-- PASSO 7: Comentários para documentação
COMMENT ON FUNCTION fix_driver_associations() IS 'Função para corrigir associações de motorista faltantes - execução única';
COMMENT ON FUNCTION auto_create_driver_record() IS 'Função trigger para criar automaticamente registros de motorista quando user_type é alterado para driver';
COMMENT ON TRIGGER auto_create_driver_record_trigger ON app_users IS 'Trigger que garante criação automática de registro de motorista quando user_type é alterado para driver';

-- PASSO 8: Limpeza da função temporária (opcional - descomente se quiser remover após uso)
-- DROP FUNCTION IF EXISTS fix_driver_associations();