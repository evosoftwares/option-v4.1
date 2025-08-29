-- Script para verificar se a tabela saved_places foi criada corretamente
-- Execute este script no Supabase SQL Editor para validar a criação

-- 1. Verificar se a tabela saved_places existe
SELECT 
    table_name,
    table_schema,
    table_type
FROM information_schema.tables 
WHERE table_name = 'saved_places'
AND table_schema = 'public';

-- 2. Verificar estrutura completa da tabela saved_places
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'saved_places'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Verificar constraints da tabela
SELECT 
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'saved_places'
AND table_schema = 'public';

-- 4. Verificar detalhes do check constraint para categorias
SELECT 
    tc.constraint_name,
    cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc 
    ON tc.constraint_name = cc.constraint_name
WHERE tc.table_name = 'saved_places'
AND tc.constraint_type = 'CHECK';

-- 5. Verificar índices criados
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'saved_places'
AND schemaname = 'public';

-- 6. Verificar se RLS está habilitado
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'saved_places'
AND schemaname = 'public';

-- 7. Verificar políticas RLS criadas
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
AND schemaname = 'public';

-- 8. Verificar triggers
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'saved_places'
AND event_object_schema = 'public';

-- 9. Teste de inserção (opcional - descomente para testar)
/*
-- ATENÇÃO: Este teste só funcionará se você tiver um passenger_id válido
-- Substitua 'SEU_PASSENGER_ID_AQUI' por um UUID válido da tabela passengers

INSERT INTO saved_places (
    passenger_id,
    label,
    address,
    latitude,
    longitude,
    category
) VALUES (
    'SEU_PASSENGER_ID_AQUI',
    'Teste Casa',
    'Rua Teste, 123',
    -23.5505,
    -46.6333,
    'home'
);

-- Verificar se foi inserido
SELECT * FROM saved_places WHERE label = 'Teste Casa';

-- Limpar teste
DELETE FROM saved_places WHERE label = 'Teste Casa';
*/

-- 10. Resumo final
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'saved_places' AND table_schema = 'public')
        THEN '✅ Tabela saved_places existe'
        ELSE '❌ Tabela saved_places NÃO existe'
    END as status_tabela,
    
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'saved_places' AND column_name = 'category')
        THEN '✅ Coluna category existe'
        ELSE '❌ Coluna category NÃO existe'
    END as status_category,
    
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'saved_places' AND rowsecurity = true)
        THEN '✅ RLS habilitado'
        ELSE '❌ RLS NÃO habilitado'
    END as status_rls,
    
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'saved_places')
        THEN '✅ Políticas RLS criadas'
        ELSE '❌ Políticas RLS NÃO criadas'
    END as status_policies;