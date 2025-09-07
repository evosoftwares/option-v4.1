-- =====================================================
-- MIGRAÇÃO: REMOVER FUNCIONALIDADE WORKING_HOURS
-- =====================================================
-- Data: 2024-12-19
-- Descrição: Remove completamente a funcionalidade de working_hours
-- Nova regra: Motorista só fica online se TODOS os documentos obrigatórios estão aprovados
-- =====================================================

BEGIN;

-- 1. REMOVER VIEWS ATUAIS QUE DEPENDEM DE WORKING_HOURS
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

-- 3. REMOVER TABELAS RELACIONADAS A WORKING_HOURS
-- =====================================================

-- Remover tabela de overrides de horários se existir
DROP TABLE IF EXISTS driver_schedule_overrides CASCADE;

-- Remover tabela principal de horários de trabalho
DROP TABLE IF EXISTS working_hours CASCADE;

-- Remover tabela de schedules se existir (pode ser nome alternativo)
DROP TABLE IF EXISTS driver_schedules CASCADE;

-- 4. REMOVER FUNÇÕES RELACIONADAS A WORKING_HOURS
-- =====================================================

-- Remover funções que dependem de working_hours
DROP FUNCTION IF EXISTS check_driver_working_hours(uuid);
DROP FUNCTION IF EXISTS get_driver_effective_status_with_hours(uuid);
DROP FUNCTION IF EXISTS is_driver_within_working_hours(uuid);
DROP FUNCTION IF EXISTS validate_working_hours(uuid);

-- 5. LIMPAR TRIGGERS RELACIONADOS A WORKING_HOURS
-- =====================================================

-- Remover triggers relacionados a working_hours
DROP TRIGGER IF EXISTS update_working_hours_updated_at ON working_hours;
DROP TRIGGER IF EXISTS trigger_update_working_hours_timestamp ON working_hours;
DROP TRIGGER IF EXISTS trigger_validate_working_hours ON working_hours;

-- 6. CRIAR FUNÇÃO AUXILIAR PARA VERIFICAR DOCUMENTOS APROVADOS
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

-- 7. CRIAR TRIGGER PARA ATUALIZAR STATUS AUTOMATICAMENTE
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

-- Criar o trigger
DROP TRIGGER IF EXISTS trigger_update_driver_status_on_document_approval ON driver_documents;
CREATE TRIGGER trigger_update_driver_status_on_document_approval
    AFTER UPDATE ON driver_documents
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION update_driver_status_on_document_approval();

-- 8. DOCUMENTAÇÃO DA NOVA LÓGICA
-- =====================================================

COMMENT ON VIEW driver_effective_status IS
'View que determina o status efetivo do motorista baseado APENAS na aprovação de documentos.

Campos:
- driver_id: ID do motorista
- online_intent: intenção do motorista de ficar online (da tabela driver_status)
- intent_updated_at: quando a intenção foi atualizada pela última vez
- documents_validated: se TODOS os documentos obrigatórios estão aprovados
- effective_online: resultado final (online_intent AND documents_validated)

Documentos obrigatórios para ficar online:
1. CNH_FRONT com status = approved e is_current = true
2. CNH_BACK com status = approved e is_current = true
3. CRLV com status = approved e is_current = true
4. VEHICLE_FRONT com status = approved e is_current = true

Lógica simplificada:
- Se motorista quer ficar online (online_intent = true) E todos documentos estão aprovados = effective_online = true
- Caso contrário = effective_online = false

Não há mais dependência de:
- working_hours (removido completamente)
- approval_status na tabela drivers (focamos apenas nos documentos)
- horários de trabalho ou restrições de tempo';

COMMENT ON FUNCTION check_driver_documents_approved(UUID) IS
'Função que verifica se todos os documentos obrigatórios de um motorista estão aprovados.
Documentos obrigatórios: CNH_FRONT, CNH_BACK, CRLV, VEHICLE_FRONT.
Retorna TRUE apenas se todos estão com status = approved e is_current = true.';

-- 9. ATUALIZAR PERMISSÕES
-- =====================================================

-- Garantir que a nova view tem as permissões corretas
GRANT SELECT ON driver_effective_status TO authenticated, anon;
GRANT EXECUTE ON FUNCTION check_driver_documents_approved(UUID) TO authenticated, anon;

-- 10. VERIFICAÇÃO FINAL E LOGS
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

COMMIT;

-- =====================================================
-- NOTAS IMPORTANTES PARA DESENVOLVEDORES:
-- =====================================================
--
-- 1. MUDANÇA FUNDAMENTAL:
--    - ANTES: effective_online = online_intent AND is_within_working_hours
--    - AGORA: effective_online = online_intent AND documents_validated
--
-- 2. DOCUMENTOS OBRIGATÓRIOS:
--    - CNH_FRONT (status = 'approved', is_current = true)
--    - CNH_BACK (status = 'approved', is_current = true)
--    - CRLV (status = 'approved', is_current = true)
--    - VEHICLE_FRONT (status = 'approved', is_current = true)
--
-- 3. CÓDIGO DART A ATUALIZAR:
--    - Remover campo 'is_within_working_hours' dos modelos
--    - Adicionar campo 'documents_validated' aos modelos
--    - Atualizar mensagens de erro para focar em documentos
--    - Remover lógica de working_hours dos serviços
--
-- 4. ESTA MIGRAÇÃO É IRREVERSÍVEL:
--    - Tabelas working_hours, driver_schedules, etc. serão removidas
--    - Dados de horários de trabalho serão perdidos
--    - Teste em desenvolvimento antes de aplicar em produção
--
-- 5. BENEFÍCIOS:
--    - Lógica muito mais simples
--    - Foco no que realmente importa: documentos aprovados
--    - Menos complexidade para motoristas
--    - Menos bugs relacionados a horários
--
-- =====================================================
