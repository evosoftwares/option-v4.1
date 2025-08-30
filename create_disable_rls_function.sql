-- Criar função para desabilitar RLS via RPC
CREATE OR REPLACE FUNCTION disable_all_rls()
RETURNS json AS $$
DECLARE
    r RECORD;
    result json;
    tables_disabled integer := 0;
    policies_dropped integer := 0;
BEGIN
    -- Desabilitar RLS em todas as tabelas do schema public
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public')
    LOOP
        EXECUTE format('ALTER TABLE IF EXISTS %I DISABLE ROW LEVEL SECURITY', r.tablename);
        tables_disabled := tables_disabled + 1;
    END LOOP;
    
    -- Remover todas as políticas RLS
    FOR r IN (SELECT schemaname, tablename, policyname 
              FROM pg_policies 
              WHERE schemaname = 'public')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
                      r.policyname, r.schemaname, r.tablename);
        policies_dropped := policies_dropped + 1;
    END LOOP;
    
    -- Retornar resultado
    result := json_build_object(
        'success', true,
        'timestamp', NOW(),
        'tables_disabled', tables_disabled,
        'policies_dropped', policies_dropped,
        'message', 'All RLS disabled successfully'
    );
    
    RETURN result;
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'timestamp', NOW()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Dar permissões para executar a função
GRANT EXECUTE ON FUNCTION disable_all_rls() TO anon;
GRANT EXECUTE ON FUNCTION disable_all_rls() TO authenticated;
GRANT EXECUTE ON FUNCTION disable_all_rls() TO service_role;