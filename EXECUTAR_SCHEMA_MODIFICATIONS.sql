-- EXECUTAR NO SUPABASE SQL EDITOR
-- ⚠️  FAZER BACKUP ANTES DE EXECUTAR ⚠️

-- =============================================================================
-- SCRIPT 1: CAMPOS TRIP_REQUESTS PARA SISTEMA DE MATCHING DIRECIONADO
-- =============================================================================

BEGIN;

-- Verificar estrutura atual antes das modificações
SELECT 'BEFORE MODIFICATIONS - trip_requests columns:' as info;
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'trip_requests' 
ORDER BY ordinal_position;

-- Adicionar campos para sistema de matching direcionado
ALTER TABLE trip_requests 
ADD COLUMN IF NOT EXISTS target_driver_id UUID REFERENCES drivers(id),
ADD COLUMN IF NOT EXISTS fallback_drivers UUID[],
ADD COLUMN IF NOT EXISTS accepted_by_driver_id UUID REFERENCES drivers(id),
ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS current_fallback_index INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS timeout_count INTEGER DEFAULT 0;

-- Adicionar campos de estimativas que faltam
ALTER TABLE trip_requests
ADD COLUMN IF NOT EXISTS estimated_distance_km NUMERIC,
ADD COLUMN IF NOT EXISTS estimated_duration_minutes INTEGER,
ADD COLUMN IF NOT EXISTS estimated_fare NUMERIC;

-- Criar índices para performance otimizada
CREATE INDEX IF NOT EXISTS idx_trip_requests_target_driver 
    ON trip_requests(target_driver_id);
    
CREATE INDEX IF NOT EXISTS idx_trip_requests_status_expires 
    ON trip_requests(status, expires_at);
    
CREATE INDEX IF NOT EXISTS idx_trip_requests_accepted_by 
    ON trip_requests(accepted_by_driver_id);

-- Ajustar default do expires_at para 10 segundos (sistema de matching)
ALTER TABLE trip_requests 
    ALTER COLUMN expires_at SET DEFAULT (now() + '00:00:10'::interval);

-- Verificar que campos foram criados
SELECT 'AFTER MODIFICATIONS - new trip_requests columns:' as info;
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'trip_requests' 
AND column_name IN ('target_driver_id', 'fallback_drivers', 'accepted_by_driver_id', 
                   'accepted_at', 'current_fallback_index', 'timeout_count',
                   'estimated_distance_km', 'estimated_duration_minutes', 'estimated_fare')
ORDER BY ordinal_position;

SELECT 'SUCCESS: Script 1 completed - trip_requests fields added' as result;

COMMIT;

-- =============================================================================
-- SCRIPT 2: PUSH NOTIFICATIONS INFRASTRUCTURE  
-- =============================================================================

BEGIN;

-- Verificar estrutura atual
SELECT 'BEFORE FCM MODIFICATIONS - drivers columns with fcm:' as info;
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'drivers' 
AND column_name LIKE '%fcm%';

-- Adicionar FCM tokens para drivers
ALTER TABLE drivers
ADD COLUMN IF NOT EXISTS fcm_token TEXT,
ADD COLUMN IF NOT EXISTS device_platform TEXT 
    CHECK (device_platform IN ('ios', 'android', 'web')),
ADD COLUMN IF NOT EXISTS last_notification_at TIMESTAMP WITH TIME ZONE;

-- Adicionar FCM tokens para app_users (passageiros)  
ALTER TABLE app_users
ADD COLUMN IF NOT EXISTS fcm_token TEXT,
ADD COLUMN IF NOT EXISTS device_id TEXT,
ADD COLUMN IF NOT EXISTS device_platform TEXT 
    CHECK (device_platform IN ('ios', 'android', 'web')),
ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- Índices para otimizar queries de notificação
CREATE INDEX IF NOT EXISTS idx_drivers_fcm_token 
    ON drivers(fcm_token) WHERE fcm_token IS NOT NULL;
    
CREATE INDEX IF NOT EXISTS idx_app_users_fcm_token 
    ON app_users(fcm_token) WHERE fcm_token IS NOT NULL;

-- Verificar que campos FCM foram criados
SELECT 'AFTER FCM MODIFICATIONS - FCM fields created:' as info;
SELECT 'drivers' as table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'drivers' AND column_name = 'fcm_token'
UNION
SELECT 'app_users' as table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'app_users' AND column_name = 'fcm_token';

SELECT 'SUCCESS: Script 2 completed - FCM tokens added' as result;

COMMIT;

-- =============================================================================
-- SCRIPT 3: VALIDAÇÃO FINAL
-- =============================================================================

-- Validação completa dos campos críticos
SELECT 'FINAL VALIDATION - Critical fields check:' as info;

SELECT 
    'trip_requests' as table_name,
    COUNT(*) as total_columns,
    COUNT(CASE WHEN column_name = 'target_driver_id' THEN 1 END) as has_target_driver,
    COUNT(CASE WHEN column_name = 'fallback_drivers' THEN 1 END) as has_fallback_drivers,
    COUNT(CASE WHEN column_name = 'accepted_by_driver_id' THEN 1 END) as has_accepted_by,
    COUNT(CASE WHEN column_name = 'estimated_distance_km' THEN 1 END) as has_estimated_distance,
    COUNT(CASE WHEN column_name = 'estimated_fare' THEN 1 END) as has_estimated_fare
FROM information_schema.columns 
WHERE table_name = 'trip_requests';

SELECT 
    'drivers' as table_name,
    COUNT(*) as total_columns,
    COUNT(CASE WHEN column_name = 'fcm_token' THEN 1 END) as has_fcm_token,
    COUNT(CASE WHEN column_name = 'custom_price_per_km' THEN 1 END) as has_custom_pricing
FROM information_schema.columns 
WHERE table_name = 'drivers';

SELECT 
    'app_users' as table_name,
    COUNT(*) as total_columns,
    COUNT(CASE WHEN column_name = 'fcm_token' THEN 1 END) as has_fcm_token
FROM information_schema.columns 
WHERE table_name = 'app_users';

-- Verificar índices criados
SELECT 
    indexname,
    tablename,
    indexdef
FROM pg_indexes 
WHERE tablename IN ('trip_requests', 'drivers', 'app_users')
AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;

SELECT '✅ SCHEMA MODIFICATIONS COMPLETED SUCCESSFULLY! ✅' as final_status;
SELECT 'Next step: Update RECOMENDACOES_IMPLEMENTACAO_MATCHING_V2.md and proceed with TripRequestManager implementation' as next_action;