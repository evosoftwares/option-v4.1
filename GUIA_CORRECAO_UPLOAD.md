# 🚨 GUIA DE CORREÇÃO: Erro de Upload "new row violates row-level security policy"

## 📋 Problema Identificado

O erro `StorageException(message: new row violates row-level security policy, statusCode: 403, error: Unauthorized)` está ocorrendo porque:

1. **RLS está habilitado** nas tabelas de storage do Supabase
2. **Políticas RLS conflitantes** estão bloqueando uploads
3. **Projeto especifica NÃO usar RLS** conforme documentação

## 🛠️ SOLUÇÃO RÁPIDA (Recomendada)

### Passo 1: Acessar Supabase Dashboard
1. Abra [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Faça login na sua conta
3. Selecione o projeto: `qlbwacmavngtonauxnte`

### Passo 2: Executar Script de Correção
1. No dashboard, vá para **SQL Editor** (ícone de banco de dados)
2. Clique em **"New Query"**
3. Copie e cole o conteúdo do arquivo `disable_rls_complete.sql`
4. Clique em **"Run"** para executar

### Passo 3: Verificar Resultados
Após executar, você deve ver:
- ✅ `STATUS RLS STORAGE.OBJECTS: DESABILITADO`
- ✅ `STATUS RLS STORAGE.BUCKETS: DESABILITADO`
- ✅ `POLÍTICAS RESTANTES: 0`
- ✅ `BUCKET USER-PHOTOS: configurado`

## 📁 Arquivos Criados

### 🔧 Scripts de Correção
- `disable_rls_complete.sql` - **Script principal (USE ESTE)**
- `fix_rls_simple.sql` - Script alternativo com RLS
- `fix_rls_upload.py` - Script Python (não funcionou)

## 🧪 TESTE APÓS CORREÇÃO

### No Flutter App:
1. Pare o app atual: `Ctrl+C` no terminal
2. Execute novamente: `flutter run`
3. Vá para a tela de registro de motorista
4. Tente fazer upload de um documento (CNH)
5. Verifique se o upload funciona sem erro

### Logs Esperados:
```
flutter: 🔄 FileUploadService.uploadDriverDocument iniciado
flutter: ✅ Imagem comprimida: XXX bytes
flutter: 🔄 Fazendo upload para Supabase...
flutter: ✅ Upload concluído com sucesso!
flutter: 📄 URL do arquivo: https://qlbwacmavngtonauxnte.supabase.co/storage/v1/object/public/user-photos/...
```

## 🔍 DIAGNÓSTICO ADICIONAL

Se o problema persistir, execute esta query no SQL Editor:

```sql
-- Verificar status atual
SELECT 
  'RLS Objects' as tabela,
  relrowsecurity as rls_habilitado
FROM pg_class 
WHERE relname = 'objects' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'storage')

UNION ALL

SELECT 
  'RLS Buckets' as tabela,
  relrowsecurity as rls_habilitado
FROM pg_class 
WHERE relname = 'buckets' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'storage');

-- Verificar políticas restantes
SELECT policyname, cmd FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects';

-- Verificar bucket
SELECT * FROM storage.buckets WHERE id = 'user-photos';
```

## 📞 SUPORTE

Se ainda houver problemas:
1. Verifique se você tem permissões de admin no projeto Supabase
2. Confirme se está executando no projeto correto (`qlbwacmavngtonauxnte`)
3. Tente executar os scripts em partes menores

## ✅ CHECKLIST DE VERIFICAÇÃO

- [ ] Script `disable_rls_complete.sql` executado no Supabase Dashboard
- [ ] Verificações mostram RLS desabilitado
- [ ] Bucket `user-photos` existe e está público
- [ ] App Flutter reiniciado
- [ ] Upload de documento testado
- [ ] Logs mostram sucesso no upload

---

**⚠️ IMPORTANTE**: Esta solução desabilita completamente o RLS conforme especificado no projeto. A segurança será gerenciada pela aplicação Flutter.