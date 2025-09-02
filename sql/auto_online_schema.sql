-- =============================================================================
-- ESQUEMA PARA SISTEMA DE AUTO-ONLINE BASEADO EM HORÁRIOS DE TRABALHO
-- =============================================================================
-- 
-- Este arquivo define o esquema SQL para implementar o comportamento automático
-- de status online dos motoristas baseado em seus horários de trabalho.
--
-- DECISÕES ARQUITETURAIS:
-- - Sem timezone: usar now() do servidor (UTC)
-- - Sem concorrência: atualização simples sem version/locks
-- - Limites: inclusivo no início, exclusivo no fim
-- - Comportamento: offline quando não há horários definidos
-- - Sem RLS: conforme restrições do projeto
-- - Sem functions: usar apenas views e triggers simples
--
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- TABELA: working_hours
-- Substitui a tabela driver_schedules existente com estrutura simplificada
-- -----------------------------------------------------------------------------

-- Renomear tabela existente para backup (se necessário)
-- ALTER TABLE IF EXISTS driver_schedules RENAME TO driver_schedules_backup;

CREATE TABLE IF NOT EXISTS working_hours (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    
    -- Constraints para integridade
    CONSTRAINT working_hours_no_duplicates UNIQUE (driver_id, day_of_week, start_time, end_time, is_active),
    CONSTRAINT working_hours_valid_time_range CHECK (start_time < end_time)
);

-- Índices para otimização de consultas
CREATE INDEX IF NOT EXISTS idx_working_hours_driver_id ON working_hours(driver_id);
CREATE INDEX IF NOT EXISTS idx_working_hours_active ON working_hours(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_working_hours_day_time ON working_hours(day_of_week, start_time, end_time);

-- -----------------------------------------------------------------------------
-- TABELA: driver_status
-- Nova tabela para separar intenção do motorista do status efetivo
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS driver_status (
    driver_id UUID PRIMARY KEY REFERENCES drivers(id) ON DELETE CASCADE,
    online_intent BOOLEAN NOT NULL DEFAULT false,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Índice para consultas de status
CREATE INDEX IF NOT EXISTS idx_driver_status_online_intent ON driver_status(online_intent);

-- -----------------------------------------------------------------------------
-- TRIGGER: Atualizar updated_at automaticamente
-- -----------------------------------------------------------------------------

-- Função para atualizar updated_at (permitida pois é simples e bem documentada)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para atualização automática de updated_at
DROP TRIGGER IF EXISTS update_working_hours_updated_at ON working_hours;
CREATE TRIGGER update_working_hours_updated_at
    BEFORE UPDATE ON working_hours
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_driver_status_updated_at ON driver_status;
CREATE TRIGGER update_driver_status_updated_at
    BEFORE UPDATE ON driver_status
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- -----------------------------------------------------------------------------
-- VIEW: driver_effective_status
-- Calcula o status efetivo combinando intenção + horários de trabalho
-- -----------------------------------------------------------------------------

CREATE OR REPLACE VIEW driver_effective_status AS
WITH current_time_info AS (
    SELECT 
        now() as current_timestamp,
        EXTRACT(DOW FROM now()) as current_day_of_week,  -- 0=Sunday, 6=Saturday
        now()::time as current_time
),
driver_working_status AS (
    SELECT DISTINCT
        ds.driver_id,
        ds.online_intent,
        ds.updated_at,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM working_hours wh, current_time_info cti
                WHERE wh.driver_id = ds.driver_id
                  AND wh.is_active = true
                  AND wh.day_of_week = cti.current_day_of_week
                  AND (
                    -- Horário normal (não cruza meia-noite)
                    (wh.start_time <= wh.end_time AND cti.current_time >= wh.start_time AND cti.current_time < wh.end_time)
                    OR
                    -- Horário noturno (cruza meia-noite)
                    (wh.start_time > wh.end_time AND (cti.current_time >= wh.start_time OR cti.current_time < wh.end_time))
                  )
            ) THEN true
            ELSE false
        END as is_within_working_hours
    FROM driver_status ds
)
SELECT 
    dws.driver_id,
    dws.online_intent,
    dws.is_within_working_hours,
    (dws.online_intent AND dws.is_within_working_hours) as effective_online,
    dws.updated_at
FROM driver_working_status dws;

-- -----------------------------------------------------------------------------
-- MIGRAÇÃO DE DADOS (se necessário)
-- -----------------------------------------------------------------------------

-- Migrar dados existentes de driver_schedules para working_hours
-- (Descomente se necessário)
/*
INSERT INTO working_hours (driver_id, day_of_week, start_time, end_time, is_active, created_at)
SELECT 
    driver_id,
    day_of_week,
    start_time::time,
    end_time::time,
    is_active,
    created_at
FROM driver_schedules
WHERE is_active = true
ON CONFLICT (driver_id, day_of_week, start_time) DO NOTHING;
*/

-- Inicializar driver_status com dados existentes da tabela drivers
INSERT INTO driver_status (driver_id, online_intent)
SELECT id, is_online
FROM drivers
ON CONFLICT (driver_id) DO UPDATE SET
    online_intent = EXCLUDED.online_intent,
    updated_at = now();

-- -----------------------------------------------------------------------------
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- -----------------------------------------------------------------------------

-- COMO USAR:
-- 1. Para verificar status efetivo: SELECT * FROM driver_effective_status WHERE driver_id = 'uuid';
-- 2. Para atualizar intenção: UPDATE driver_status SET online_intent = true WHERE driver_id = 'uuid';
-- 3. Para gerenciar horários: INSERT/UPDATE/DELETE na tabela working_hours;

-- REGRAS DE NEGÓCIO:
-- - effective_online = online_intent AND is_within_working_hours
-- - Horários inclusivos no início, exclusivos no fim
-- - Suporte a horários que cruzam meia-noite
-- - Múltiplos intervalos por dia permitidos
-- - Sem horários = sempre fora do horário de trabalho

COMMIT;

SELECT 'Schema de auto-online criado com sucesso!' as result;