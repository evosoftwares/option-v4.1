-- Script para desabilitar RLS completamente na tabela storage.objects
-- Execute este SQL no SQL Editor do Supabase Dashboard

-- 1. Desabilitar RLS na tabela storage.objects
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- 2. Remover todas as políticas existentes
DROP POLICY IF EXISTS "Motoristas podem fazer upload de documentos" ON storage.objects;
DROP POLICY IF EXISTS "Motoristas podem atualizar seus documentos" ON storage.objects;
DROP POLICY IF EXISTS "Allow anonymous uploads to user-photos" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read from user-photos" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated uploads to user-photos" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated updates to user-photos" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated deletes from user-photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own files" ON storage.objects;

-- 3. Verificar se RLS foi desabilitado
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'storage' AND tablename = 'objects';

-- 4. Verificar se não há políticas ativas
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects';

-- Resultado esperado:
-- - rowsecurity deve ser 'f' (false)
-- - Nenhuma política deve aparecer na segunda query