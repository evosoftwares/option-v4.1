# Correção dos Problemas de Supabase Storage

## 🚨 Problema Identificado

O erro "Bucket not found" ocorre quando a aplicação tenta fazer upload de fotos para buckets que não existem no Supabase Storage.

### Buckets Necessários:
- `user-photos` - Para fotos de perfil dos usuários
- `driver-documents` - Para documentos dos motoristas

## 🔧 Solução

### Passo 1: Diagnóstico

1. Acesse o **Supabase Dashboard**
2. Vá para **SQL Editor**
3. Execute o arquivo `diagnose_supabase_storage.sql`
4. Analise os resultados:

```sql
-- Se retornar 0 linhas, os buckets não existem
SELECT * FROM storage.buckets WHERE id IN ('user-photos', 'driver-documents');
```

### Passo 2: Criação dos Buckets

1. No **SQL Editor** do Supabase
2. Execute o arquivo `setup_supabase_storage_buckets.sql`
3. Verifique se os buckets foram criados:

```sql
SELECT id, name, public, file_size_limit FROM storage.buckets;
```

### Passo 3: Verificação das Políticas

As políticas de segurança são criadas automaticamente pelo script, mas você pode verificar:

```sql
SELECT policyname, cmd FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage';
```

## 📋 Configurações dos Buckets

### user-photos
- **Público**: Sim
- **Limite de tamanho**: 5MB
- **Tipos permitidos**: JPEG, PNG, WebP
- **Estrutura de pastas**: `users/{userId}/profile/{timestamp}_{filename}`

### driver-documents
- **Público**: Não (privado)
- **Limite de tamanho**: 10MB
- **Tipos permitidos**: JPEG, PNG, WebP, PDF
- **Estrutura de pastas**: `drivers/{driverId}/documents/{documentType}/{timestamp}_{filename}`

## 🔒 Políticas de Segurança

### user-photos
- Usuários podem fazer upload apenas de suas próprias fotos
- Usuários podem visualizar apenas suas próprias fotos
- Usuários podem deletar apenas suas próprias fotos

### driver-documents
- Motoristas podem fazer upload apenas de seus próprios documentos
- Motoristas podem visualizar apenas seus próprios documentos
- Administradores podem visualizar todos os documentos
- Motoristas podem deletar apenas seus próprios documentos

## 🧪 Teste da Configuração

Após executar os scripts, teste o upload:

1. **Abra a aplicação**
2. **Faça login** como usuário
3. **Vá para o fluxo de cadastro**
4. **Tente fazer upload de uma foto**
5. **Verifique se não há mais erros de "Bucket not found"**

## 🐛 Troubleshooting

### Erro: "Bucket not found"
**Causa**: Buckets não foram criados
**Solução**: Execute `setup_supabase_storage_buckets.sql`

### Erro: "Permission denied"
**Causa**: Políticas de segurança não configuradas
**Solução**: Verifique se as políticas foram criadas corretamente

### Erro: "File too large"
**Causa**: Arquivo excede o limite do bucket
**Solução**: Verifique os limites configurados (5MB para fotos, 10MB para documentos)

### Erro: "Invalid file type"
**Causa**: Tipo de arquivo não permitido
**Solução**: Verifique se o arquivo é JPEG, PNG, WebP ou PDF (para documentos)

## 📝 Logs de Debug

Para debugar problemas de upload, verifique os logs no código:

```dart
// Em file_upload_service.dart
print('❌ Erro do Supabase Storage: ${e.message}');

// Em driver_document_service.dart
print('❌ Erro do Supabase Storage: ${e.message}');
```

## ✅ Verificação Final

Após a correção, execute novamente o diagnóstico:

```sql
-- Deve retornar 2 buckets
SELECT COUNT(*) FROM storage.buckets WHERE id IN ('user-photos', 'driver-documents');

-- Deve retornar várias políticas
SELECT COUNT(*) FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage';
```

## 🔄 Próximos Passos

1. ✅ Execute `diagnose_supabase_storage.sql`
2. ✅ Execute `setup_supabase_storage_buckets.sql`
3. ⏳ Teste o upload de fotos na aplicação
4. ⏳ Teste o upload de documentos de motorista
5. ⏳ Verifique se não há mais erros no console

---

**Status**: Scripts de correção criados e prontos para execução no Supabase.
**Arquivos**: `diagnose_supabase_storage.sql`, `setup_supabase_storage_buckets.sql`