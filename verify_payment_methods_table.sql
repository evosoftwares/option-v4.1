-- Script para verificar se a tabela payment_methods foi criada corretamente
-- Execute este script no SQL Editor do Supabase para verificar

-- 1. Verificar se a tabela existe
SELECT 
    table_name, 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'payment_methods'
ORDER BY ordinal_position;

-- 2. Verificar índices criados
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public' 
AND tablename = 'payment_methods';

-- 3. Verificar políticas RLS
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'payment_methods';

-- 4. Testar inserção de dados (descomente se quiser testar)
/*
INSERT INTO public.payment_methods (user_id, type, is_default, pix_data) 
VALUES (
    auth.uid(),  -- Vai usar o usuário logado
    'pix',
    true,
    '{"key_type": "email", "key_value": "test@example.com"}'::jsonb
);

-- Ver o que foi inserido
SELECT * FROM public.payment_methods WHERE user_id = auth.uid();
*/