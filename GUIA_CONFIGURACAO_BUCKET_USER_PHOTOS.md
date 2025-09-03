# Guia de Configuração do Bucket user-photos

## Problema Identificado

O bucket `user-photos` existe na documentação mas não está funcionando corretamente devido a políticas RLS (Row Level Security) que estão bloqueando o acesso via API.

## Solução: Configuração Manual via Supabase Dashboard

### Passo 1: Acessar o Supabase Dashboard

1. Acesse [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Faça login na sua conta
3. Selecione o projeto `option-v4.1`

### Passo 2: Executar Script SQL

1. No painel lateral, clique em **SQL Editor**
2. Clique em **New Query**
3. Cole o script completo abaixo:

```sql
-- ===================================================
-- CONFIGURAÇÃO DO BUCKET USER-PHOTOS SEM RLS
-- Execute este script no Supabase SQL Editor
-- ===================================================

-- 1. Verificar se o bucket já existe
SELECT 
    'VERIFICAÇÃO INICIAL' as status,
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types,
    created_at
FROM storage.buckets 
WHERE id = 'user-photos';

-- 2. Criar bucket user-photos se não existir
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
    true,  -- Público para permitir acesso direto
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 3. DESABILITAR RLS na tabela storage.objects
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- 4. Remover todas as políticas existentes para storage.objects
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

-- 5. Garantir permissões básicas
GRANT SELECT, INSERT, UPDATE, DELETE ON storage.objects TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON storage.objects TO anon;
GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT USAGE ON SCHEMA storage TO anon;

-- 6. Verificar configuração final
SELECT 
    'CONFIGURAÇÃO FINAL' as status,
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types,
    created_at
FROM storage.buckets 
WHERE id = 'user-photos';

-- 7. Verificar se RLS está desabilitado
SELECT 
    'STATUS RLS' as status,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'objects'
AND schemaname = 'storage';

-- 8. Verificar se não há políticas ativas
SELECT 
    'POLÍTICAS ATIVAS' as status,
    COUNT(*) as total_policies
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage';
```

### Passo 3: Executar o Script

1. Clique em **Run** para executar o script
2. Verifique os resultados:
   - **VERIFICAÇÃO INICIAL**: Deve mostrar o bucket se já existir
   - **CONFIGURAÇÃO FINAL**: Deve mostrar o bucket criado/atualizado
   - **STATUS RLS**: `rls_enabled` deve ser `false`
   - **POLÍTICAS ATIVAS**: `total_policies` deve ser `0`

### Passo 4: Verificar no Storage

1. No painel lateral, clique em **Storage**
2. Você deve ver o bucket `user-photos` listado
3. Clique no bucket para verificar se está acessível

## Resultados Esperados

Após executar o script, você deve ver:

```
CONFIGURAÇÃO FINAL:
id: user-photos
name: user-photos
public: true
file_size_limit: 5242880
allowed_mime_types: {image/jpeg,image/png,image/webp,image/jpg}

STATUS RLS:
rls_enabled: false

POLÍTICAS ATIVAS:
total_policies: 0
```

## Teste da Configuração

Após executar o script SQL:

1. Execute o teste Python:
   ```bash
   python3 test_user_photos_bucket.py
   ```

2. Teste na aplicação Flutter:
   - Abra a aplicação
   - Vá para o cadastro de motorista
   - Tente fazer upload de uma CNH
   - Verifique se o upload funciona sem erros

## Troubleshooting

### Se ainda houver erros:

1. **Erro 403 Unauthorized**: 
   - Verifique se o RLS foi realmente desabilitado
   - Execute novamente a parte do script que remove políticas

2. **Bucket não aparece na lista**:
   - Verifique se o script foi executado completamente
   - Recarregue a página do Supabase Dashboard

3. **Upload ainda falha na aplicação**:
   - Verifique se as chaves do Supabase estão corretas
   - Confirme que o usuário está autenticado
   - Verifique os logs do Flutter para erros específicos

## Próximos Passos

Após configurar o bucket:

1. ✅ Bucket `user-photos` configurado
2. ✅ RLS desabilitado
3. ✅ Permissões configuradas
4. 🔄 Testar upload na aplicação
5. 🔄 Validar persistência dos dados
6. 🔄 Confirmar URLs públicas funcionando

---

**Nota**: Esta configuração remove o RLS conforme as diretrizes do projeto. A segurança será gerenciada pela aplicação Flutter através de validações de autenticação, tamanho de arquivo e tipos MIME.