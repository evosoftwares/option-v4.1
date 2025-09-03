-- ===================================================
-- DESABILITAR RLS COMPLETAMENTE (CONFORME PROJETO)
-- Execute este script no Supabase SQL Editor
-- ===================================================

-- IMPORTANTE: Este projeto especifica NÃO usar RLS
-- Esta é a solução mais direta para o erro de upload

-- 1. Remover TODAS as políticas RLS existentes na tabela storage.objects
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'storage' AND tablename = 'objects'
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_record.policyname || '" ON storage.objects';
        RAISE NOTICE 'Política removida: %', policy_record.policyname;
    END LOOP;
END $$;

-- 2. DESABILITAR RLS na tabela storage.objects
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- 3. DESABILITAR RLS na tabela storage.buckets (se estiver habilitado)
ALTER TABLE storage.buckets DISABLE ROW LEVEL SECURITY;

-- 4. Conceder permissões completas para usuários autenticados e anônimos
GRANT ALL ON storage.objects TO authenticated;
GRANT ALL ON storage.objects TO anon;
GRANT ALL ON storage.buckets TO authenticated;
GRANT ALL ON storage.buckets TO anon;

-- 5. Garantir que o bucket user-photos existe e está configurado
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'user-photos',
  'user-photos', 
  true,
  52428800, -- 50MB
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) 
DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 6. Verificações finais
SELECT 
  'STATUS RLS STORAGE.OBJECTS' as verificacao,
  CASE 
    WHEN relrowsecurity THEN 'HABILITADO ❌' 
    ELSE 'DESABILITADO ✅' 
  END as status
FROM pg_class 
WHERE relname = 'objects' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'storage');

SELECT 
  'STATUS RLS STORAGE.BUCKETS' as verificacao,
  CASE 
    WHEN relrowsecurity THEN 'HABILITADO ❌' 
    ELSE 'DESABILITADO ✅' 
  END as status
FROM pg_class 
WHERE relname = 'buckets' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'storage');

SELECT 
  'POLÍTICAS RESTANTES' as verificacao,
  COUNT(*) as quantidade
FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects';

SELECT 
  'BUCKET USER-PHOTOS' as verificacao,
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets 
WHERE id = 'user-photos';

-- ===================================================
-- RESULTADO ESPERADO:
-- - RLS desabilitado em storage.objects e storage.buckets
-- - Nenhuma política RLS restante
-- - Bucket user-photos configurado e público
-- - Permissões completas para authenticated e anon
-- ===================================================

-- INSTRUÇÕES DE USO:
-- 1. Copie este script completo
-- 2. Vá para Supabase Dashboard > SQL Editor
-- 3. Cole e execute o script
-- 4. Verifique se todas as verificações mostram status ✅
-- 5. Teste o upload na aplicação Flutter
-- ===================================================