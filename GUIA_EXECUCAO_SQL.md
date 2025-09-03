# 🚀 Guia para Executar Script SQL no Supabase Dashboard

## ✅ Status Atual
- ✅ Bucket 'user-photos' existe e está público
- ✅ Script SQL `fix_storage_rls.sql` criado e pronto
- ❌ **PENDENTE**: Executar script no Supabase Dashboard

## 📋 Passo-a-Passo para Executar o Script

### 1. Acessar o Supabase Dashboard
1. Abra seu navegador
2. Acesse: https://supabase.com/dashboard
3. Faça login na sua conta
4. Selecione o projeto: **qlbwacmavngtonauxnte**

### 2. Navegar para o SQL Editor
1. No menu lateral esquerdo, clique em **"SQL Editor"**
2. Clique em **"New query"** ou use uma query existente

### 3. Copiar e Colar o Script SQL
```sql
-- Script para corrigir políticas RLS do Supabase Storage
-- Execute este script no SQL Editor do Supabase Dashboard

-- 1. Habilitar RLS na tabela storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 2. Remover políticas existentes
DROP POLICY IF EXISTS "Allow authenticated users to select files" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to insert files" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to update files" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to delete files" ON storage.objects;

-- 3. Criar política SELECT (necessária para upsert)
CREATE POLICY "Allow authenticated users to select files"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'user-photos');

-- 4. Criar política INSERT (necessária para upsert)
CREATE POLICY "Allow authenticated users to insert files"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'user-photos');

-- 5. Criar política UPDATE (ESSENCIAL para upsert)
CREATE POLICY "Allow authenticated users to update files"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'user-photos')
WITH CHECK (bucket_id = 'user-photos');

-- 6. Criar política DELETE
CREATE POLICY "Allow authenticated users to delete files"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'user-photos');

-- 7. Verificar políticas criadas
SELECT policyname, cmd FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects';
```

### 4. Executar o Script
1. Cole o script completo no editor SQL
2. Clique no botão **"Run"** (▶️) ou pressione **Ctrl+Enter**
3. Aguarde a execução completar

### 5. Verificar Resultado
**Resultado Esperado:**
- ✅ Todas as políticas devem ser criadas sem erro
- ✅ A query de verificação deve mostrar 4 políticas:
  - `Allow authenticated users to select files` (SELECT)
  - `Allow authenticated users to insert files` (INSERT)
  - `Allow authenticated users to update files` (UPDATE)
  - `Allow authenticated users to delete files` (DELETE)

### 6. Possíveis Erros e Soluções

#### Erro: "permission denied"
**Solução:** Certifique-se de estar usando uma conta com permissões de administrador

#### Erro: "relation does not exist"
**Solução:** Verifique se você está no projeto correto

#### Erro: "policy already exists"
**Solução:** Execute primeiro os comandos DROP POLICY para remover políticas existentes

## 🎯 Após Executar o Script

1. **Volte para o Flutter app**
2. **Teste o upload de documentos** na tela de cadastro de motorista
3. **Verifique os logs** para confirmar que o erro de RLS foi resolvido

## 📞 Se Ainda Houver Problemas

Se o erro persistir após executar o script:
1. Verifique se todas as 4 políticas foram criadas
2. Confirme que o usuário está autenticado no app
3. Verifique se o bucket 'user-photos' está sendo usado corretamente

---

**⚠️ IMPORTANTE:** Este script deve ser executado **EXATAMENTE** como mostrado acima no Supabase Dashboard para resolver o erro de RLS.