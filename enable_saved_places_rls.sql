-- Script para habilitar RLS e criar políticas de segurança para saved_places
-- Execute este script no Supabase SQL Editor após confirmar que a tabela existe

-- 1. Conceder permissões básicas para o role 'authenticated'
GRANT SELECT, INSERT, UPDATE, DELETE ON saved_places TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;

-- 2. Habilitar Row Level Security na tabela saved_places
ALTER TABLE saved_places ENABLE ROW LEVEL SECURITY;

-- 3. Criar política para SELECT - usuários só podem ver seus próprios saved_places
CREATE POLICY "Users can view own saved places" ON saved_places
    FOR SELECT USING (passenger_id = auth.uid());

-- 4. Criar política para INSERT - usuários só podem inserir saved_places para si mesmos
CREATE POLICY "Users can insert own saved places" ON saved_places
    FOR INSERT WITH CHECK (passenger_id = auth.uid());

-- 5. Criar política para UPDATE - usuários só podem atualizar seus próprios saved_places
CREATE POLICY "Users can update own saved places" ON saved_places
    FOR UPDATE USING (passenger_id = auth.uid())
    WITH CHECK (passenger_id = auth.uid());

-- 6. Criar política para DELETE - usuários só podem deletar seus próprios saved_places
CREATE POLICY "Users can delete own saved places" ON saved_places
    FOR DELETE USING (passenger_id = auth.uid());

-- 7. Verificar se RLS foi habilitado corretamente
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'saved_places'
AND schemaname = 'public';

-- 8. Verificar se as políticas foram criadas
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'saved_places'
AND schemaname = 'public'
ORDER BY policyname;

-- 9. Teste de verificação final
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'saved_places' AND rowsecurity = true)
        THEN '✅ RLS habilitado com sucesso'
        ELSE '❌ RLS NÃO foi habilitado'
    END as status_rls,
    
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'saved_places') >= 4
        THEN '✅ Políticas RLS criadas (' || (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'saved_places') || ' políticas)'
        ELSE '❌ Políticas RLS incompletas (' || (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'saved_places') || ' políticas)'
    END as status_policies;

-- COMENTÁRIOS IMPORTANTES:
-- 
-- 1. Este script deve ser executado APÓS confirmar que a tabela saved_places existe
-- 2. As políticas RLS garantem que cada usuário só acesse seus próprios dados
-- 3. passenger_id deve corresponder ao auth.uid() do usuário autenticado
-- 4. Após executar este script, teste a funcionalidade no app Flutter
-- 5. Se houver erros, verifique se o usuário está autenticado corretamente