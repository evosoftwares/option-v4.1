-- =====================================================
-- Tabela para sistema de locks pessimistas
-- Garante transações atômicas em operações críticas
-- =====================================================

CREATE TABLE IF NOT EXISTS system_locks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    lock_key TEXT NOT NULL UNIQUE,
    lock_id TEXT NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Índices para performance
    CONSTRAINT system_locks_unique_key UNIQUE (lock_key),
    CONSTRAINT system_locks_expires_check CHECK (expires_at > created_at)
);

-- Índice para cleanup de locks expirados
CREATE INDEX IF NOT EXISTS idx_system_locks_expires_at ON system_locks(expires_at);

-- Índice composto para queries de lock
CREATE INDEX IF NOT EXISTS idx_system_locks_key_id ON system_locks(lock_key, lock_id);

-- Política RLS para system_locks (apenas sistema pode acessar)
ALTER TABLE system_locks ENABLE ROW LEVEL SECURITY;

-- Política para permitir apenas operações do sistema
CREATE POLICY "System only access" ON system_locks
    FOR ALL 
    USING (true)
    WITH CHECK (true);

-- Função para limpeza automática de locks expirados (executar via cron)
CREATE OR REPLACE FUNCTION cleanup_expired_locks()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM system_locks 
    WHERE expires_at < NOW();
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Log da limpeza se houve remoções
    IF deleted_count > 0 THEN
        INSERT INTO activity_logs (user_id, action, entity_type, metadata)
        VALUES (
            NULL,
            'cleanup_expired_locks',
            'system_locks',
            jsonb_build_object(
                'deleted_count', deleted_count,
                'cleanup_time', NOW()
            )
        );
    END IF;
    
    RETURN deleted_count;
END;
$$;

-- Comentários para documentação
COMMENT ON TABLE system_locks IS 'Sistema de locks pessimistas para transações atômicas';
COMMENT ON COLUMN system_locks.lock_key IS 'Chave única do lock (ex: driver_selection_123)';
COMMENT ON COLUMN system_locks.lock_id IS 'ID único da instância que possui o lock';
COMMENT ON COLUMN system_locks.expires_at IS 'Timestamp de expiração do lock';
COMMENT ON FUNCTION cleanup_expired_locks() IS 'Limpa locks expirados - executar via cron a cada minuto';