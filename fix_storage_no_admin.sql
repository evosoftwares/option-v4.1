-- Script para configurar storage sem privilégios de administrador
-- Execute este script no SQL Editor do Supabase Dashboard

-- 1. Verificar estado atual do bucket
SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types,
    created_at
FROM storage.buckets 
WHERE name = 'user-photos';

-- 2. Criar ou atualizar o bucket user-photos
INSERT INTO storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
)
VALUES (
    'user-photos',
    'user-photos',
    true,
    52428800, -- 50MB
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 3. Remover políticas existentes que podem estar causando conflito
DROP POLICY IF EXISTS "Give anon users access to JPG images in folder 1oj01fe_0" ON storage.objects;
DROP POLICY IF EXISTS "Give anon users access to PNG images in folder 1oj01fe_1" ON storage.objects;
DROP POLICY IF EXISTS "Give users access to own folder 1oj01fe_0" ON storage.objects;
DROP POLICY IF EXISTS "Give users access to own folder 1oj01fe_1" ON storage.objects;
DROP POLICY IF EXISTS "Give users access to own folder 1oj01fe_2" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read access" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to upload" ON storage.objects;
DROP POLICY IF EXISTS "Allow public uploads" ON storage.objects;
DROP POLICY IF EXISTS "Public bucket access" ON storage.buckets;

-- 4. Criar políticas permissivas para o bucket user-photos
-- Política para permitir uploads anônimos
CREATE POLICY "Allow anonymous uploads to user-photos"
ON storage.objects
FOR INSERT
TO anon
WITH CHECK (bucket_id = 'user-photos');

-- Política para permitir leitura pública
CREATE POLICY "Allow public read from user-photos"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'user-photos');

-- Política para permitir uploads de usuários autenticados
CREATE POLICY "Allow authenticated uploads to user-photos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'user-photos');

-- Política para permitir updates de usuários autenticados
CREATE POLICY "Allow authenticated updates to user-photos"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'user-photos')
WITH CHECK (bucket_id = 'user-photos');

-- Política para permitir deletes de usuários autenticados
CREATE POLICY "Allow authenticated deletes from user-photos"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'user-photos');

-- 5. Verificar políticas criadas
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
WHERE schemaname = 'storage' 
AND tablename = 'objects'
AND policyname LIKE '%user-photos%';

-- 6. Verificar configuração final do bucket
SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types,
    created_at
FROM storage.buckets 
WHERE name = 'user-photos';

-- 7. Resumo final
SELECT 
    '✅ Script executado com sucesso!' as status,
    'Bucket user-photos configurado' as bucket_status,
    'Políticas permissivas criadas' as policies_status,
    'Upload anônimo habilitado' as anonymous_status;

-- 8. Instruções finais
SELECT 
    'PRÓXIMOS PASSOS:' as instrucoes,
    '1. Execute o teste Dart novamente' as passo_1,
    '2. Upload deve funcionar com chave anônima' as passo_2,
    '3. URLs públicas devem ser acessíveis' as passo_3,
    '4. Se ainda houver erro, verifique no Dashboard do Supabase' as passo_4;