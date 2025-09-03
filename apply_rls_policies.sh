#!/bin/bash

# Script para aplicar políticas RLS no Supabase Storage
# Execute este script após conectar ao projeto Supabase

echo "🔄 Aplicando políticas RLS para user-photos bucket..."

# Drop políticas existentes
echo "📝 Removendo políticas existentes..."
supabase db query "DROP POLICY IF EXISTS \"user_photos_insert\" ON storage.objects;" --linked
supabase db query "DROP POLICY IF EXISTS \"user_photos_select\" ON storage.objects;" --linked  
supabase db query "DROP POLICY IF EXISTS \"user_photos_update\" ON storage.objects;" --linked
supabase db query "DROP POLICY IF EXISTS \"user_photos_delete\" ON storage.objects;" --linked
supabase db query "DROP POLICY IF EXISTS \"user_photos_public_select\" ON storage.objects;" --linked

# Enable RLS
echo "🔒 Habilitando RLS na tabela storage.objects..."
supabase db query "ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;" --linked

# Criar política INSERT
echo "📝 Criando política INSERT..."
supabase db query "CREATE POLICY \"user_photos_insert\" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'user-photos' AND auth.uid()::text IS NOT NULL);" --linked

# Criar política SELECT para autenticados
echo "📝 Criando política SELECT para usuários autenticados..."
supabase db query "CREATE POLICY \"user_photos_select\" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'user-photos');" --linked

# Criar política UPDATE
echo "📝 Criando política UPDATE..."
supabase db query "CREATE POLICY \"user_photos_update\" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'user-photos' AND auth.uid()::text IS NOT NULL) WITH CHECK (bucket_id = 'user-photos' AND auth.uid()::text IS NOT NULL);" --linked

# Criar política DELETE
echo "📝 Criando política DELETE..."
supabase db query "CREATE POLICY \"user_photos_delete\" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'user-photos' AND auth.uid()::text IS NOT NULL);" --linked

# Criar política SELECT pública
echo "📝 Criando política SELECT pública..."
supabase db query "CREATE POLICY \"user_photos_public_select\" ON storage.objects FOR SELECT TO public USING (bucket_id = 'user-photos');" --linked

# Conceder permissões
echo "🔐 Concedendo permissões para usuários autenticados..."
supabase db query "GRANT ALL ON storage.objects TO authenticated;" --linked

# Verificar se bucket existe
echo "🪣 Verificando bucket user-photos..."
supabase db query "SELECT id, name, public, file_size_limit FROM storage.buckets WHERE id = 'user-photos';" --linked

# Criar bucket se não existir
echo "🪣 Criando/atualizando bucket user-photos..."
supabase db query "INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) VALUES ('user-photos', 'user-photos', true, 10485760, ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']) ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public, file_size_limit = EXCLUDED.file_size_limit, allowed_mime_types = EXCLUDED.allowed_mime_types;" --linked

# Verificar políticas criadas
echo "✅ Verificando políticas criadas..."
supabase db query "SELECT policyname, cmd, roles FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage' AND policyname LIKE 'user_photos%';" --linked

echo "✅ Políticas RLS aplicadas com sucesso!"
echo "🧪 Teste agora o upload de documentos na aplicação."