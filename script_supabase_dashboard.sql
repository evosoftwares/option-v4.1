-- Script simplificado para executar no Supabase Dashboard
-- Etapa 1: Remover views existentes
DROP VIEW IF EXISTS driver_effective_status;
DROP VIEW IF EXISTS driver_effective_status_with_overrides;

-- Etapa 2: Criar nova view baseada em aprovação de documentos
CREATE OR REPLACE VIEW driver_effective_status AS
SELECT
    ds.driver_id,
    ds.online_intent,
    ds.updated_at as intent_updated_at,
    -- Verificar se TODOS os documentos obrigatórios estão aprovados
    (
        -- Verificar se existe documento CNH_FRONT aprovado
        EXISTS (
            SELECT 1 FROM driver_documents dd
            WHERE dd.driver_id = ds.driver_id
            AND dd.document_type = 'CNH_FRONT'
            AND dd.status = 'approved'
            AND dd.is_current = true
        )
        AND
        -- Verificar se existe documento CNH_BACK aprovado
        EXISTS (
            SELECT 1 FROM driver_documents dd
            WHERE dd.driver_id = ds.driver_id
            AND dd.document_type = 'CNH_BACK'
            AND dd.status = 'approved'
            AND dd.is_current = true
        )
        AND
        -- Verificar se existe documento CRLV aprovado
        EXISTS (
            SELECT 1 FROM driver_documents dd
            WHERE dd.driver_id = ds.driver_id
            AND dd.document_type = 'CRLV'
            AND dd.status = 'approved'
            AND dd.is_current = true
        )
        AND
        -- Verificar se existe documento VEHICLE_FRONT aprovado
        EXISTS (
            SELECT 1 FROM driver_documents dd
            WHERE dd.driver_id = ds.driver_id
            AND dd.document_type = 'VEHICLE_FRONT'
            AND dd.status = 'approved'
            AND dd.is_current = true
        )
    ) as documents_validated,
    -- Status efetivo: intenção online E todos documentos aprovados
    (
        ds.online_intent
        AND
        (
            -- Mesma lógica de validação de documentos
            EXISTS (
                SELECT 1 FROM driver_documents dd
                WHERE dd.driver_id = ds.driver_id
                AND dd.document_type = 'CNH_FRONT'
                AND dd.status = 'approved'
                AND dd.is_current = true
            )
            AND
            EXISTS (
                SELECT 1 FROM driver_documents dd
                WHERE dd.driver_id = ds.driver_id
                AND dd.document_type = 'CNH_BACK'
                AND dd.status = 'approved'
                AND dd.is_current = true
            )
            AND
            EXISTS (
                SELECT 1 FROM driver_documents dd
                WHERE dd.driver_id = ds.driver_id
                AND dd.document_type = 'CRLV'
                AND dd.status = 'approved'
                AND dd.is_current = true
            )
            AND
            EXISTS (
                SELECT 1 FROM driver_documents dd
                WHERE dd.driver_id = ds.driver_id
                AND dd.document_type = 'VEHICLE_FRONT'
                AND dd.status = 'approved'
                AND dd.is_current = true
            )
        )
    ) as effective_online
FROM driver_status ds;

-- Etapa 3: Remover tabelas relacionadas a working_hours
DROP TABLE IF EXISTS driver_schedule_overrides CASCADE;
DROP TABLE IF EXISTS working_hours CASCADE;
DROP TABLE IF EXISTS driver_schedules CASCADE;

-- Etapa 4: Remover funções relacionadas a working_hours
DROP FUNCTION IF EXISTS check_driver_working_hours(uuid);
DROP FUNCTION IF EXISTS get_driver_effective_status_with_hours(uuid);
DROP FUNCTION IF EXISTS is_driver_within_working_hours(uuid);
DROP FUNCTION IF EXISTS validate_working_hours(uuid);

-- Etapa 5: Limpar triggers relacionados a working_hours
DROP TRIGGER IF EXISTS update_working_hours_updated_at ON working_hours;
DROP TRIGGER IF EXISTS trigger_update_working_hours_timestamp ON working_hours;
DROP TRIGGER IF EXISTS trigger_validate_working_hours ON working_hours;

-- Etapa 6: Criar função auxiliar para verificar documentos aprovados
CREATE OR REPLACE FUNCTION check_driver_documents_approved(driver_uuid UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
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

-- Etapa 7: Criar trigger para atualizar status automaticamente
DROP TRIGGER IF EXISTS trigger_update_driver_status_on_document_approval ON driver_documents;

CREATE OR REPLACE FUNCTION update_driver_status_on_document_approval()
RETURNS TRIGGER
LANGUAGE plpgsql
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

CREATE TRIGGER trigger_update_driver_status_on_document_approval
    AFTER UPDATE ON driver_documents
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION update_driver_status_on_document_approval();

-- Etapa 8: Atualizar permissões
GRANT SELECT ON driver_effective_status TO authenticated, anon;
GRANT EXECUTE ON FUNCTION check_driver_documents_approved(UUID) TO authenticated, anon;

-- Etapa 9: Verificação final
SELECT COUNT(*) as total_drivers FROM driver_effective_status;