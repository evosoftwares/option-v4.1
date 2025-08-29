-- Script para testar se a tabela saved_places está funcionando corretamente

-- 1. Verificar se a tabela existe e sua estrutura
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'saved_places' 
ORDER BY ordinal_position;

-- 2. Verificar se existem registros na tabela passengers
SELECT COUNT(*) as passenger_count FROM passengers;

-- 3. Mostrar alguns passengers de exemplo (para pegar um ID válido para teste)
SELECT id, user_id, created_at FROM passengers LIMIT 3;

-- 4. Testar inserção manual de um local salvo (substitua o passenger_id por um ID real)
-- DESCOMENTE E SUBSTITUA O passenger_id antes de executar:
/*
INSERT INTO saved_places (passenger_id, label, address, latitude, longitude, category)
VALUES (
    'SUBSTITUA_POR_UM_ID_REAL_DA_QUERY_ACIMA',
    'Local de Teste',
    'Endereço de Teste, 123',
    -23.5505,
    -46.6333,
    'other'
);
*/

-- 5. Verificar os registros inseridos
SELECT * FROM saved_places ORDER BY created_at DESC LIMIT 5;

-- 6. Verificar permissões RLS (se habilitado)
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'saved_places';

-- 7. Verificar políticas RLS
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'saved_places';