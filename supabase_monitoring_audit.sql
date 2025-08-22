-- Sistema de Auditoria e Monitoramento para Driver Operation Zones
-- Este script implementa logs de auditoria, métricas e health checks

-- =====================================================
-- 1. TABELA DE AUDITORIA
-- =====================================================

-- Tabela para logs de auditoria de todas as operações
CREATE TABLE IF NOT EXISTS driver_operation_zones_audit (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    operation_type TEXT NOT NULL CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE')),
    table_name TEXT NOT NULL DEFAULT 'driver_operation_zones',
    record_id UUID NOT NULL,
    old_values JSONB,
    new_values JSONB,
    changed_by UUID REFERENCES auth.users(id),
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    client_ip INET,
    user_agent TEXT,
    session_id TEXT,
    change_reason TEXT,
    metadata JSONB DEFAULT '{}'
);

-- Índices para performance da auditoria
CREATE INDEX IF NOT EXISTS idx_audit_record_id ON driver_operation_zones_audit(record_id);
CREATE INDEX IF NOT EXISTS idx_audit_changed_by ON driver_operation_zones_audit(changed_by);
CREATE INDEX IF NOT EXISTS idx_audit_changed_at ON driver_operation_zones_audit(changed_at);
CREATE INDEX IF NOT EXISTS idx_audit_operation_type ON driver_operation_zones_audit(operation_type);

-- =====================================================
-- 2. TABELA DE LOGS DE APLICAÇÃO
-- =====================================================

-- Tabela para logs estruturados da aplicação
CREATE TABLE IF NOT EXISTS application_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT now(),
    level TEXT NOT NULL CHECK (level IN ('DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL')),
    service TEXT NOT NULL,
    operation TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id),
    driver_id UUID,
    zone_id UUID,
    duration_ms INTEGER,
    status TEXT NOT NULL CHECK (status IN ('success', 'error', 'warning')),
    metadata JSONB DEFAULT '{}',
    error_details JSONB,
    client_ip INET,
    user_agent TEXT,
    app_version TEXT,
    platform TEXT
);

-- Índices para performance dos logs
CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON application_logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_logs_level ON application_logs(level);
CREATE INDEX IF NOT EXISTS idx_logs_service ON application_logs(service);
CREATE INDEX IF NOT EXISTS idx_logs_user_id ON application_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_logs_status ON application_logs(status);

-- =====================================================
-- 3. TABELA DE MÉTRICAS
-- =====================================================

-- Tabela para armazenar métricas agregadas
CREATE TABLE IF NOT EXISTS system_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_name TEXT NOT NULL,
    metric_value NUMERIC NOT NULL,
    metric_type TEXT NOT NULL CHECK (metric_type IN ('counter', 'gauge', 'histogram')),
    labels JSONB DEFAULT '{}',
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT now(),
    retention_days INTEGER DEFAULT 30
);

-- Índices para métricas
CREATE INDEX IF NOT EXISTS idx_metrics_name ON system_metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_metrics_timestamp ON system_metrics(timestamp);
CREATE INDEX IF NOT EXISTS idx_metrics_type ON system_metrics(metric_type);

-- =====================================================
-- 4. FUNÇÃO DE AUDITORIA
-- =====================================================

-- Função para capturar mudanças automaticamente
CREATE OR REPLACE FUNCTION audit_driver_operation_zones()
RETURNS TRIGGER AS $$
DECLARE
    client_ip_addr INET;
    user_agent_str TEXT;
BEGIN
    -- Tentar obter IP do cliente (pode não estar disponível em todos os contextos)
    BEGIN
        client_ip_addr := inet_client_addr();
    EXCEPTION WHEN OTHERS THEN
        client_ip_addr := NULL;
    END;

    -- Tentar obter user agent (implementação futura)
    user_agent_str := current_setting('request.headers', true);

    IF TG_OP = 'DELETE' THEN
        INSERT INTO driver_operation_zones_audit (
            operation_type,
            record_id,
            old_values,
            changed_by,
            client_ip,
            user_agent,
            metadata
        ) VALUES (
            'DELETE',
            OLD.id,
            to_jsonb(OLD),
            auth.uid(),
            client_ip_addr,
            user_agent_str,
            jsonb_build_object(
                'table_name', TG_TABLE_NAME,
                'schema_name', TG_TABLE_SCHEMA
            )
        );
        RETURN OLD;
        
    ELSIF TG_OP = 'UPDATE' THEN
        -- Só auditar se houve mudanças significativas
        IF OLD.zone_name != NEW.zone_name OR 
           OLD.polygon_coordinates != NEW.polygon_coordinates OR
           OLD.price_multiplier != NEW.price_multiplier OR
           OLD.is_active != NEW.is_active THEN
            
            INSERT INTO driver_operation_zones_audit (
                operation_type,
                record_id,
                old_values,
                new_values,
                changed_by,
                client_ip,
                user_agent,
                metadata
            ) VALUES (
                'UPDATE',
                NEW.id,
                to_jsonb(OLD),
                to_jsonb(NEW),
                auth.uid(),
                client_ip_addr,
                user_agent_str,
                jsonb_build_object(
                    'table_name', TG_TABLE_NAME,
                    'schema_name', TG_TABLE_SCHEMA,
                    'changes', jsonb_build_object(
                        'zone_name', CASE WHEN OLD.zone_name != NEW.zone_name THEN jsonb_build_object('old', OLD.zone_name, 'new', NEW.zone_name) END,
                        'price_multiplier', CASE WHEN OLD.price_multiplier != NEW.price_multiplier THEN jsonb_build_object('old', OLD.price_multiplier, 'new', NEW.price_multiplier) END,
                        'is_active', CASE WHEN OLD.is_active != NEW.is_active THEN jsonb_build_object('old', OLD.is_active, 'new', NEW.is_active) END
                    )
                )
            );
        END IF;
        RETURN NEW;
        
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO driver_operation_zones_audit (
            operation_type,
            record_id,
            new_values,
            changed_by,
            client_ip,
            user_agent,
            metadata
        ) VALUES (
            'INSERT',
            NEW.id,
            to_jsonb(NEW),
            auth.uid(),
            client_ip_addr,
            user_agent_str,
            jsonb_build_object(
                'table_name', TG_TABLE_NAME,
                'schema_name', TG_TABLE_SCHEMA
            )
        );
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 5. TRIGGERS DE AUDITORIA
-- =====================================================

-- Remover trigger existente se houver
DROP TRIGGER IF EXISTS trigger_audit_driver_operation_zones ON driver_operation_zones;

-- Criar trigger de auditoria
CREATE TRIGGER trigger_audit_driver_operation_zones
    AFTER INSERT OR UPDATE OR DELETE ON driver_operation_zones
    FOR EACH ROW
    EXECUTE FUNCTION audit_driver_operation_zones();

-- =====================================================
-- 6. FUNÇÕES DE HEALTH CHECK
-- =====================================================

-- Função de health check geral do sistema
CREATE OR REPLACE FUNCTION system_health_check()
RETURNS JSON AS $$
DECLARE
    result JSON;
    db_status TEXT;
    zones_count INTEGER;
    active_drivers INTEGER;
    recent_errors INTEGER;
    avg_response_time NUMERIC;
BEGIN
    -- Verificar status do banco
    BEGIN
        SELECT COUNT(*) INTO zones_count FROM driver_operation_zones;
        SELECT COUNT(DISTINCT driver_id) INTO active_drivers 
        FROM driver_operation_zones WHERE is_active = true;
        
        -- Contar erros recentes (últimas 24 horas)
        SELECT COUNT(*) INTO recent_errors 
        FROM application_logs 
        WHERE level = 'ERROR' 
        AND timestamp > now() - interval '24 hours';
        
        -- Calcular tempo médio de resposta (últimas 24 horas)
        SELECT AVG(duration_ms) INTO avg_response_time
        FROM application_logs 
        WHERE duration_ms IS NOT NULL 
        AND timestamp > now() - interval '24 hours';
        
        db_status := 'healthy';
    EXCEPTION WHEN OTHERS THEN
        db_status := 'unhealthy';
        zones_count := -1;
        active_drivers := -1;
        recent_errors := -1;
        avg_response_time := -1;
    END;
    
    result := json_build_object(
        'status', CASE 
            WHEN db_status = 'healthy' AND recent_errors < 100 THEN 'healthy'
            WHEN db_status = 'healthy' AND recent_errors < 500 THEN 'degraded'
            ELSE 'unhealthy'
        END,
        'timestamp', now(),
        'database', db_status,
        'metrics', json_build_object(
            'total_zones', zones_count,
            'active_drivers', active_drivers,
            'recent_errors_24h', recent_errors,
            'avg_response_time_ms', COALESCE(avg_response_time, 0)
        ),
        'version', '1.0.0',
        'environment', current_setting('app.environment', true)
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 7. FUNÇÕES DE MÉTRICAS
-- =====================================================

-- Função para registrar métricas
CREATE OR REPLACE FUNCTION record_metric(
    p_metric_name TEXT,
    p_metric_value NUMERIC,
    p_metric_type TEXT DEFAULT 'gauge',
    p_labels JSONB DEFAULT '{}'
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO system_metrics (metric_name, metric_value, metric_type, labels)
    VALUES (p_metric_name, p_metric_value, p_metric_type, p_labels);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para obter métricas agregadas
CREATE OR REPLACE FUNCTION get_metrics_summary(
    p_hours INTEGER DEFAULT 24
)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    WITH metric_stats AS (
        SELECT 
            metric_name,
            metric_type,
            COUNT(*) as count,
            AVG(metric_value) as avg_value,
            MIN(metric_value) as min_value,
            MAX(metric_value) as max_value,
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY metric_value) as p50,
            PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY metric_value) as p95
        FROM system_metrics 
        WHERE timestamp > now() - (p_hours || ' hours')::interval
        GROUP BY metric_name, metric_type
    )
    SELECT json_agg(
        json_build_object(
            'metric_name', metric_name,
            'metric_type', metric_type,
            'count', count,
            'avg_value', avg_value,
            'min_value', min_value,
            'max_value', max_value,
            'p50', p50,
            'p95', p95
        )
    ) INTO result
    FROM metric_stats;
    
    RETURN COALESCE(result, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 8. FUNÇÕES DE LIMPEZA
-- =====================================================

-- Função para limpar logs antigos
CREATE OR REPLACE FUNCTION cleanup_old_logs()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Limpar logs de aplicação mais antigos que 90 dias
    DELETE FROM application_logs 
    WHERE timestamp < now() - interval '90 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Limpar métricas baseado na retenção configurada
    DELETE FROM system_metrics 
    WHERE timestamp < now() - (retention_days || ' days')::interval;
    
    -- Manter auditoria por 2 anos (compliance)
    DELETE FROM driver_operation_zones_audit 
    WHERE changed_at < now() - interval '2 years';
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 9. POLÍTICAS RLS
-- =====================================================

-- Habilitar RLS nas tabelas de monitoramento
ALTER TABLE application_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_operation_zones_audit ENABLE ROW LEVEL SECURITY;

-- Política para logs - usuários veem apenas seus próprios logs
CREATE POLICY application_logs_user_policy ON application_logs
    FOR SELECT
    USING (user_id = auth.uid());

-- Política para admins verem todos os logs
CREATE POLICY application_logs_admin_policy ON application_logs
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM app_users 
            WHERE id = auth.uid() 
            AND user_type = 'admin'
        )
    );

-- Política para auditoria - apenas admins
CREATE POLICY audit_admin_policy ON driver_operation_zones_audit
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM app_users 
            WHERE id = auth.uid() 
            AND user_type = 'admin'
        )
    );

-- Política para métricas - apenas admins
CREATE POLICY metrics_admin_policy ON system_metrics
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM app_users 
            WHERE id = auth.uid() 
            AND user_type = 'admin'
        )
    );

-- =====================================================
-- 10. JOBS DE MANUTENÇÃO
-- =====================================================

-- Criar extensão para jobs agendados (se disponível)
-- CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Agendar limpeza diária (descomente se pg_cron estiver disponível)
-- SELECT cron.schedule('cleanup-logs', '0 2 * * *', 'SELECT cleanup_old_logs();');

-- =====================================================
-- 11. COMENTÁRIOS E DOCUMENTAÇÃO
-- =====================================================

COMMENT ON TABLE driver_operation_zones_audit IS 'Tabela de auditoria para rastrear todas as mudanças nas zonas de operação';
COMMENT ON TABLE application_logs IS 'Logs estruturados da aplicação para monitoramento e debugging';
COMMENT ON TABLE system_metrics IS 'Métricas do sistema para monitoramento de performance';

COMMENT ON FUNCTION system_health_check() IS 'Retorna status de saúde do sistema com métricas básicas';
COMMENT ON FUNCTION record_metric(TEXT, NUMERIC, TEXT, JSONB) IS 'Registra uma métrica no sistema';
COMMENT ON FUNCTION get_metrics_summary(INTEGER) IS 'Retorna resumo das métricas agregadas';
COMMENT ON FUNCTION cleanup_old_logs() IS 'Remove logs antigos baseado na política de retenção';

-- =====================================================
-- 12. DADOS INICIAIS
-- =====================================================

-- Registrar métricas iniciais
SELECT record_metric('system_initialized', 1, 'counter', '{"version": "1.0.0"}');

-- Inserir log de inicialização
INSERT INTO application_logs (
    level, service, operation, status, metadata
) VALUES (
    'INFO', 'monitoring_system', 'initialize', 'success',
    '{"message": "Monitoring system initialized", "version": "1.0.0"}'
);

PRINT 'Sistema de monitoramento e auditoria instalado com sucesso!';