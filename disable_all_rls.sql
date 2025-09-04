-- Script para desativar todas as políticas RLS
-- Execute este script no Supabase Dashboard > SQL Editor
-- ATENÇÃO: Isso remove toda a segurança a nível de linha

-- 1. Desabilitar RLS em todas as tabelas principais
ALTER TABLE IF EXISTS public.app_users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.sync_control DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.auth_sync_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.trips DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.drivers DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.passengers DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.vehicles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.payments DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.ratings DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.chat_messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.emergency_contacts DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.promo_codes DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.wallet_transactions DISABLE ROW LEVEL SECURITY;

-- 2. Remover todas as políticas existentes
DO $$
DECLARE
    pol_record RECORD;
BEGIN
    -- Buscar e remover todas as políticas RLS
    FOR pol_record IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
                      pol_record.policyname, 
                      pol_record.schemaname, 
                      pol_record.tablename);
        RAISE NOTICE 'Política removida: %.% - %', 
                     pol_record.schemaname, 
                     pol_record.tablename, 
                     pol_record.policyname;
    END LOOP;
END $$;

-- 3. Verificar status final
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    COUNT(policyname) as policy_count
FROM information_schema.tables t
LEFT JOIN pg_policies p ON t.table_name = p.tablename AND t.table_schema = p.schemaname
WHERE t.table_schema = 'public'
  AND t.table_type = 'BASE TABLE'
GROUP BY schemaname, tablename, rowsecurity
ORDER BY tablename;

-- 4. Verificar se ainda existem políticas
SELECT 
    'Políticas restantes:' as status,
    COUNT(*) as total
FROM pg_policies 
WHERE schemaname = 'public';

-- 5. Confirmar que RLS está desabilitado
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN 'RLS ATIVO ⚠️'
        ELSE 'RLS DESABILITADO ✅'
    END as status
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY tablename;

RAISE NOTICE '✅ Script executado com sucesso!';
RAISE NOTICE '⚠️  ATENÇÃO: Todas as políticas RLS foram removidas';
RAISE NOTICE '📝 Recomendação: Implementar validação de segurança no lado da aplicação';