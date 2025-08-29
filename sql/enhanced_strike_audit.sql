-- =====================================================
-- Sistema Aprimorado de Auditoria de Strikes
-- Funções adicionais para logging detalhado e relatórios
-- =====================================================

-- 1. Função para log detalhado de cancelamentos
CREATE OR REPLACE FUNCTION log_cancellation_strike(
    user_id UUID,
    user_type TEXT, -- 'passenger' or 'driver'
    trip_request_id UUID,
    cancellation_reason TEXT DEFAULT NULL,
    was_no_show BOOLEAN DEFAULT FALSE,
    driver_distance_traveled NUMERIC DEFAULT 0.0
)
RETURNS INTEGER AS $$
DECLARE
    current_strikes INTEGER := 0;
    trip_data JSONB;
    user_data JSONB;
BEGIN
    -- Buscar dados da viagem para contexto
    SELECT to_jsonb(tr.*) INTO trip_data
    FROM trip_requests tr
    WHERE tr.id = trip_request_id;

    -- Buscar dados do usuário
    SELECT to_jsonb(au.*) INTO user_data
    FROM app_users au
    WHERE au.id = user_id;

    -- Obter contagem atual de strikes
    IF user_type = 'passenger' THEN
        SELECT consecutive_cancellations INTO current_strikes
        FROM passengers p
        WHERE p.user_id = user_id;
        
        -- Incrementar strikes do passageiro
        current_strikes := increment_passenger_cancellations(user_id);
    ELSE
        SELECT consecutive_cancellations INTO current_strikes
        FROM drivers d
        WHERE d.user_id = user_id;
        
        -- Incrementar strikes do motorista
        current_strikes := increment_driver_cancellations(user_id);
    END IF;

    -- Log detalhado do strike
    INSERT INTO activity_logs (
        user_id, 
        action, 
        entity_type, 
        entity_id, 
        metadata, 
        created_at
    )
    VALUES (
        user_id,
        'cancellation_strike_added',
        user_type,
        user_id,
        jsonb_build_object(
            'strike_count', current_strikes,
            'trip_request_id', trip_request_id,
            'cancellation_reason', cancellation_reason,
            'was_no_show', was_no_show,
            'driver_distance_traveled', driver_distance_traveled,
            'trip_context', trip_data,
            'user_context', user_data,
            'risk_level', CASE 
                WHEN current_strikes >= 3 THEN 'critical'
                WHEN current_strikes >= 2 THEN 'high'
                WHEN current_strikes >= 1 THEN 'medium'
                ELSE 'low'
            END,
            'timestamp', NOW()
        ),
        NOW()
    );

    -- Alerta automático para strikes altos
    IF current_strikes >= 2 THEN
        INSERT INTO activity_logs (
            user_id,
            action,
            entity_type,
            entity_id,
            metadata,
            created_at
        )
        VALUES (
            user_id,
            'strike_warning_issued',
            user_type,
            user_id,
            jsonb_build_object(
                'warning_type', CASE 
                    WHEN current_strikes >= 3 THEN 'suspension_triggered'
                    ELSE 'approaching_suspension'
                END,
                'current_strikes', current_strikes,
                'strikes_until_suspension', GREATEST(0, 3 - current_strikes),
                'automatic_alert', true
            ),
            NOW()
        );
    END IF;

    RETURN current_strikes;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Função para log detalhado de reset de strikes
CREATE OR REPLACE FUNCTION log_strike_reset(
    user_id UUID,
    user_type TEXT, -- 'passenger' or 'driver'
    trip_id UUID,
    reset_reason TEXT DEFAULT 'trip_completed'
)
RETURNS VOID AS $$
DECLARE
    old_strike_count INTEGER := 0;
    trip_data JSONB;
BEGIN
    -- Obter contagem atual antes do reset
    IF user_type = 'passenger' THEN
        SELECT consecutive_cancellations INTO old_strike_count
        FROM passengers WHERE user_id = user_id;
    ELSE
        SELECT consecutive_cancellations INTO old_strike_count
        FROM drivers WHERE user_id = user_id;
    END IF;

    -- Buscar dados da viagem
    SELECT to_jsonb(t.*) INTO trip_data
    FROM trips t
    WHERE t.id = trip_id;

    -- Log do reset apenas se havia strikes
    IF old_strike_count > 0 THEN
        INSERT INTO activity_logs (
            user_id,
            action,
            entity_type,
            entity_id,
            metadata,
            created_at
        )
        VALUES (
            user_id,
            'strikes_reset',
            user_type,
            user_id,
            jsonb_build_object(
                'previous_strike_count', old_strike_count,
                'new_strike_count', 0,
                'reset_reason', reset_reason,
                'trip_id', trip_id,
                'trip_context', trip_data,
                'reset_method', 'automatic',
                'timestamp', NOW()
            ),
            NOW()
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. View para relatório completo de strikes
CREATE OR REPLACE VIEW strike_audit_report AS
SELECT 
    au.id as user_id,
    au.full_name,
    au.email,
    au.user_type,
    au.status as user_status,
    COALESCE(p.consecutive_cancellations, d.consecutive_cancellations, 0) as current_strikes,
    COALESCE(p.total_trips, d.total_trips, 0) as total_trips,
    
    -- Estatísticas de strikes dos últimos 30 dias
    (SELECT COUNT(*) 
     FROM activity_logs al 
     WHERE al.user_id = au.id 
       AND al.action = 'cancellation_strike_added'
       AND al.created_at >= NOW() - INTERVAL '30 days'
    ) as strikes_last_30_days,
    
    -- Última atividade de strike
    (SELECT al.created_at 
     FROM activity_logs al 
     WHERE al.user_id = au.id 
       AND al.action = 'cancellation_strike_added'
     ORDER BY al.created_at DESC 
     LIMIT 1
    ) as last_strike_date,
    
    -- Data da última suspensão
    (SELECT al.created_at 
     FROM activity_logs al 
     WHERE al.user_id = au.id 
       AND al.action = 'user_suspended'
       AND al.metadata->>'reason' = 'consecutive_cancellations'
     ORDER BY al.created_at DESC 
     LIMIT 1
    ) as last_suspension_date,
    
    -- Número de suspensões por strikes
    (SELECT COUNT(*) 
     FROM activity_logs al 
     WHERE al.user_id = au.id 
       AND al.action = 'user_suspended'
       AND al.metadata->>'reason' = 'consecutive_cancellations'
    ) as total_suspensions,
    
    -- Risk score baseado no histórico
    CASE 
        WHEN COALESCE(p.consecutive_cancellations, d.consecutive_cancellations, 0) >= 3 THEN 'CRITICAL'
        WHEN COALESCE(p.consecutive_cancellations, d.consecutive_cancellations, 0) >= 2 THEN 'HIGH'
        WHEN COALESCE(p.consecutive_cancellations, d.consecutive_cancellations, 0) >= 1 THEN 'MEDIUM'
        ELSE 'LOW'
    END as risk_level,
    
    au.created_at as user_created_at,
    au.updated_at as user_updated_at
FROM app_users au
LEFT JOIN passengers p ON au.id = p.user_id
LEFT JOIN drivers d ON au.id = d.user_id
WHERE au.user_type IN ('passenger', 'driver');

-- 4. Função para obter histórico detalhado de strikes de um usuário
CREATE OR REPLACE FUNCTION get_user_strike_history(target_user_id UUID)
RETURNS TABLE (
    log_date TIMESTAMP WITH TIME ZONE,
    action TEXT,
    strike_count INTEGER,
    reason TEXT,
    trip_context JSONB,
    additional_data JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        al.created_at as log_date,
        al.action,
        (al.metadata->>'strike_count')::INTEGER as strike_count,
        COALESCE(
            al.metadata->>'cancellation_reason',
            al.metadata->>'reset_reason',
            'N/A'
        ) as reason,
        al.metadata->'trip_context' as trip_context,
        al.metadata as additional_data
    FROM activity_logs al
    WHERE al.user_id = target_user_id
      AND al.action IN (
          'cancellation_strike_added',
          'strikes_reset', 
          'user_suspended',
          'user_reactivated',
          'strike_warning_issued'
      )
    ORDER BY al.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Função para alertas automáticos de usuários em risco
CREATE OR REPLACE FUNCTION get_users_at_risk()
RETURNS TABLE (
    user_id UUID,
    full_name TEXT,
    email TEXT,
    user_type TEXT,
    current_strikes INTEGER,
    risk_level TEXT,
    days_since_last_strike INTEGER,
    total_suspensions BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sar.user_id,
        sar.full_name,
        sar.email,
        sar.user_type,
        sar.current_strikes,
        sar.risk_level,
        COALESCE(
            EXTRACT(DAY FROM NOW() - sar.last_strike_date)::INTEGER,
            999
        ) as days_since_last_strike,
        sar.total_suspensions
    FROM strike_audit_report sar
    WHERE sar.current_strikes >= 2  -- Usuários com 2+ strikes
       OR sar.user_status = 'suspended'
    ORDER BY sar.current_strikes DESC, sar.last_strike_date DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Trigger atualizado para usar o novo sistema de logging
CREATE OR REPLACE FUNCTION enhanced_trip_completion_reset()
RETURNS TRIGGER AS $$
BEGIN
    -- Se a viagem foi completada, resetar cancelamentos consecutivos
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        -- Log detalhado do reset para passageiro e motorista
        PERFORM log_strike_reset(NEW.passenger_id, 'passenger', NEW.id, 'trip_completed');
        PERFORM log_strike_reset(NEW.driver_id, 'driver', NEW.id, 'trip_completed');
        
        -- Resetar cancelamentos (as funções log_strike_reset não fazem o reset)
        PERFORM reset_passenger_cancellations(NEW.passenger_id);
        PERFORM reset_driver_cancellations(NEW.driver_id);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Substituir o trigger existente
DROP TRIGGER IF EXISTS trip_completion_reset_trigger ON trips;
CREATE TRIGGER enhanced_trip_completion_reset_trigger
    AFTER UPDATE OF status ON trips
    FOR EACH ROW
    WHEN (NEW.status = 'completed')
    EXECUTE FUNCTION enhanced_trip_completion_reset();

-- 7. Índices para performance das consultas de auditoria
CREATE INDEX IF NOT EXISTS idx_activity_logs_user_strike_actions 
ON activity_logs(user_id, action, created_at) 
WHERE action IN ('cancellation_strike_added', 'strikes_reset', 'user_suspended', 'user_reactivated');

CREATE INDEX IF NOT EXISTS idx_activity_logs_strike_metadata 
ON activity_logs USING GIN(metadata) 
WHERE action IN ('cancellation_strike_added', 'strike_warning_issued');

-- Comentários para documentação
COMMENT ON FUNCTION log_cancellation_strike IS 'Log detalhado quando um usuário recebe um strike por cancelamento';
COMMENT ON FUNCTION log_strike_reset IS 'Log detalhado quando strikes são resetados';
COMMENT ON VIEW strike_audit_report IS 'Relatório completo de strikes e suspensões por usuário';
COMMENT ON FUNCTION get_user_strike_history IS 'Histórico completo de strikes de um usuário específico';
COMMENT ON FUNCTION get_users_at_risk IS 'Lista usuários com alto risco de suspensão';