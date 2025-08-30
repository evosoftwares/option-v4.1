# Solução para Erro de Permissões no Supabase Storage

## 🚨 Problema Identificado

**Erro:** `ERROR: 42501: must be owner of table objects`

**Causa:** O script anterior tentava desabilitar RLS (Row Level Security) nas tabelas `storage.objects` e `storage.buckets`, mas isso requer privilégios de administrador/proprietário que não estão disponíveis em contas padrão do Supabase.

## ✅ Solução Alternativa

Em vez de desabilitar RLS, vamos criar políticas permissivas que permitam o acesso necessário ao bucket `user-photos`.

### Arquivos Criados

1. **`fix_storage_no_admin.sql`** - Script que funciona sem privilégios de administrador
2. **`test_bucket_policies.dart`** - Teste para validar as políticas criadas

## 📋 Instruções de Execução

### Passo 1: Executar Script SQL

1. Acesse o **Supabase Dashboard**
2. Vá para **SQL Editor**
3. Copie e cole o conteúdo do arquivo `fix_storage_no_admin.sql`
4. Execute o script

### Passo 2: Validar Configuração

Execute o teste para verificar se as políticas estão funcionando:

```bash
dart run test_bucket_policies.dart
```

### Passo 3: Testar Upload Real

Após validar as políticas, execute o teste de upload:

```bash
dart run test_upload_real.dart
```

## 🔧 O que o Script Faz

### 1. Configuração do Bucket
- Cria/atualiza o bucket `user-photos`
- Define como público
- Configura limite de 50MB
- Permite tipos MIME de imagem

### 2. Políticas Criadas

#### Para Usuários Anônimos:
- **Upload:** Permite upload de arquivos para `user-photos`
- **Leitura:** Permite leitura pública de todos os arquivos

#### Para Usuários Autenticados:
- **Upload:** Permite upload de arquivos
- **Update:** Permite atualização de arquivos
- **Delete:** Permite exclusão de arquivos
- **Leitura:** Permite leitura de todos os arquivos

### 3. Limpeza
- Remove políticas conflitantes existentes
- Garante que não há conflitos de permissões

## 🧪 Validação

O script de teste verifica:

1. ✅ **Acesso ao Bucket** - Verifica se o bucket existe e está acessível
2. ✅ **Upload Anônimo** - Testa upload com chave anônima
3. ✅ **URL Pública** - Verifica se URLs públicas funcionam
4. ✅ **Listagem** - Testa listagem de arquivos no bucket

## 📊 Resultados Esperados

Após executar o script, você deve ver:

```
✅ Script executado com sucesso!
✅ Bucket user-photos configurado
✅ Políticas permissivas criadas
✅ Upload anônimo habilitado
```

E no teste:

```
✅ Bucket encontrado: user-photos
✅ Upload anônimo bem-sucedido!
✅ URL pública acessível!
✅ Listagem bem-sucedida!
```

## 🔍 Troubleshooting

### Se ainda houver erros:

1. **Verifique as chaves do Supabase** no arquivo de teste
2. **Confirme a URL do projeto** Supabase
3. **Verifique no Dashboard** se o bucket foi criado
4. **Consulte as políticas** na seção Storage > Policies

### Comandos de Diagnóstico:

```sql
-- Verificar bucket
SELECT * FROM storage.buckets WHERE name = 'user-photos';

-- Verificar políticas
SELECT policyname, cmd, roles 
FROM pg_policies 
WHERE schemaname = 'storage' 
AND tablename = 'objects'
AND policyname LIKE '%user-photos%';
```

## 🎯 Próximos Passos

1. Execute o script `fix_storage_no_admin.sql`
2. Valide com `test_bucket_policies.dart`
3. Teste upload real com `test_upload_real.dart`
4. Integre o código Flutter na aplicação

## 📝 Notas Importantes

- ✅ **Sem RLS:** Esta solução usa políticas em vez de desabilitar RLS
- ✅ **Sem Privilégios Admin:** Funciona com contas padrão do Supabase
- ✅ **Seguro:** Mantém controle de acesso através de políticas
- ✅ **Flexível:** Permite uploads anônimos e autenticados

---

**Status:** Pronto para execução
**Última atualização:** $(date)