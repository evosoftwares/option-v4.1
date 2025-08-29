-- ===============================================
-- CORREÇÃO SEGURA DE DADOS CORROMPIDOS
-- FASE 2: Migração Incremental Reversível
-- ===============================================

-- =============================================
-- 1. FUNÇÃO PARA IDENTIFICAR DADOS CORROMPIDOS
-- =============================================

CREATE OR REPLACE FUNCTION identify_corrupted_users()
RETURNS TABLE(
    user_id UUID,
    email TEXT,
    full_name TEXT,
    phone TEXT,
    corruption_type TEXT,
    corruption_confidence DECIMAL,
    suggested_fix TEXT,
    created_at TIMESTAMPTZ
) AS $$
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
$$ LANGUAGE plpgsql;

-- =============================================
-- 2. FUNÇÃO DE CORREÇÃO SEGURA (COM BACKUP)
-- =============================================

CREATE OR REPLACE FUNCTION safe_correct_user_data(
    target_user_id UUID,
    new_full_name TEXT DEFAULT NULL,
    new_phone TEXT DEFAULT NULL,
    dry_run BOOLEAN DEFAULT TRUE
)
RETURNS json AS $$
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
$$ LANGUAGE plpgsql;

-- =============================================
-- 3. TABELA DE BACKUP PARA DADOS CORROMPIDOS
-- =============================================

CREATE TABLE IF NOT EXISTS corrupted_users_backup (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    original_user_id UUID NOT NULL,
    original_full_name TEXT,
    original_phone TEXT,
    original_email TEXT,
    correction_timestamp TIMESTAMPTZ DEFAULT NOW(),
    correction_reason TEXT,
    restored BOOLEAN DEFAULT FALSE,
    restored_at TIMESTAMPTZ NULL
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_corrupted_backup_user_id ON corrupted_users_backup(original_user_id);
CREATE INDEX IF NOT EXISTS idx_corrupted_backup_timestamp ON corrupted_users_backup(correction_timestamp);

-- =============================================
-- 4. FUNÇÃO DE CORREÇÃO EM LOTE (SEGURA)
-- =============================================

CREATE OR REPLACE FUNCTION batch_correct_corrupted_users(
    max_corrections INTEGER DEFAULT 10,
    dry_run BOOLEAN DEFAULT TRUE
)
RETURNS json AS $$
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
$$ LANGUAGE plpgsql;

-- =============================================
-- 5. FUNÇÃO DE RESTAURAÇÃO (ROLLBACK)
-- =============================================

CREATE OR REPLACE FUNCTION restore_user_data(
    target_user_id UUID
)
RETURNS json AS $$
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
$$ LANGUAGE plpgsql;

-- =============================================
-- 6. RELATÓRIOS E MONITORAMENTO
-- =============================================

-- View para monitoramento de correções
CREATE OR REPLACE VIEW data_correction_monitoring AS
SELECT 
    DATE(correction_timestamp) as correction_date,
    COUNT(*) as corrections_made,
    COUNT(*) FILTER (WHERE restored = TRUE) as corrections_restored,
    COUNT(*) FILTER (WHERE restored = FALSE) as corrections_active,
    correction_reason
FROM corrupted_users_backup
GROUP BY DATE(correction_timestamp), correction_reason
ORDER BY correction_date DESC;

-- Função de relatório resumido
CREATE OR REPLACE FUNCTION data_correction_summary()
RETURNS json AS $$
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
$$ LANGUAGE plpgsql;

-- =============================================
-- EXEMPLO DE USO
-- =============================================

/*
-- 1. IDENTIFICAR usuários corrompidos
SELECT * FROM identify_corrupted_users();

-- 2. TESTAR correção individual (DRY RUN)
SELECT safe_correct_user_data(
    'user-uuid-here',
    'Nome Corrigido',
    '11999887766',
    TRUE  -- dry_run
);

-- 3. APLICAR correção individual
SELECT safe_correct_user_data(
    'user-uuid-here',
    'Nome Corrigido', 
    '11999887766',
    FALSE  -- aplicar real
);

-- 4. CORREÇÃO EM LOTE (teste)
SELECT batch_correct_corrupted_users(5, TRUE);

-- 5. CORREÇÃO EM LOTE (aplicar)
SELECT batch_correct_corrupted_users(5, FALSE);

-- 6. RESTAURAR dados se necessário
SELECT restore_user_data('user-uuid-here');

-- 7. MONITORAR progresso
SELECT * FROM data_correction_monitoring;
SELECT data_correction_summary();
*/