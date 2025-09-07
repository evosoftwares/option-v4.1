-- Script para completar a migração da funcionalidade Working Hours
-- Este script assume que as tabelas já foram removidas e precisa criar as novas views e funções

-- 1. REMOVER VIEWS ATUAIS QUE DEPENDEM DE WORKING_HOURS (se ainda existirem)
-- =====================================================
DROP VIEW IF EXISTS driver_effective_status;
DROP VIEW IF EXISTS driver_effective_status_with_overrides;

-- 2. CRIAR NOVA VIEW BASEADA APENAS EM APROVAÇÃO DE DOCUMENTOS
-- =====================================================
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

-- 3. CRIAR FUNÇÃO AUXILIAR PARA VERIFICAR DOCUMENTOS APROVADOS
-- =====================================================

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

-- 4. CRIAR TRIGGER PARA ATUALIZAR STATUS AUTOMATICAMENTE
-- =====================================================

-- Função que será chamada quando documentos forem atualizados
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

-- Criar o trigger (remover primeiro se já existir)
DROP TRIGGER IF EXISTS trigger_update_driver_status_on_document_approval ON driver_documents;
CREATE TRIGGER trigger_update_driver_status_on_document_approval
    AFTER UPDATE ON driver_documents
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION update_driver_status_on_document_approval();

-- 5. ATUALIZAR PERMISSÕES
-- =====================================================

-- Garantir que a nova view tem as permissões corretas
GRANT SELECT ON driver_effective_status TO authenticated, anon;
GRANT EXECUTE ON FUNCTION check_driver_documents_approved(UUID) TO authenticated, anon;

-- 6. VERIFICAÇÃO FINAL
-- =====================================================

-- Verificar se a view foi criada corretamente
DO $$
DECLARE
    view_exists BOOLEAN;
    function_exists BOOLEAN;
    sample_count INTEGER;
BEGIN
    -- Verificar view
    SELECT EXISTS (
        SELECT 1 FROM information_schema.views
        WHERE table_name = 'driver_effective_status'
    ) INTO view_exists;

    -- Verificar função
    SELECT EXISTS (
        SELECT 1 FROM information_schema.routines
        WHERE routine_name = 'check_driver_documents_approved'
    ) INTO function_exists;

    -- Contar registros na view (teste básico)
    SELECT COUNT(*) FROM driver_effective_status INTO sample_count;

    IF NOT view_exists THEN
        RAISE EXCEPTION 'ERRO: View driver_effective_status não foi criada corretamente';
    END IF;

    IF NOT function_exists THEN
        RAISE EXCEPTION 'ERRO: Função check_driver_documents_approved não foi criada corretamente';
    END IF;

    RAISE NOTICE '✅ SUCCESS: Migração concluída com sucesso!';
    RAISE NOTICE '📊 View driver_effective_status criada com % registros', sample_count;
    RAISE NOTICE '🔧 Função check_driver_documents_approved disponível';
    RAISE NOTICE '📋 Nova lógica: Motorista online APENAS se todos documentos aprovados';
    RAISE NOTICE '🗑️ Funcionalidade working_hours removida completamente';
END $$;