# 🚨 SOLUÇÃO: Erro "Operação não suportada no namespace CNH"

## 📋 Diagnóstico

O erro "Operação não suportada no namespace CNH ${_namespace}" está ocorrendo porque:

✅ **CAUSA IDENTIFICADA**: O bucket `driver-documents` **NÃO EXISTE** no Supabase Storage

## 🔧 Solução Imediata

### Passo 1: Acessar o Painel do Supabase

1. Acesse: https://supabase.com/dashboard
2. Faça login na sua conta
3. Selecione o projeto: `qlbwacmavngtonauxnte`

### Passo 2: Criar o Bucket via Interface

1. No menu lateral, clique em **"Storage"**
2. Clique em **"Create bucket"**
3. Configure o bucket:
   ```
   Bucket name: driver-documents
   Public bucket: ❌ (deixe desmarcado - privado)
   File size limit: 10 MB
   Allowed MIME types: 
   - image/jpeg
   - image/png
   - image/webp
   - image/jpg
   - application/pdf
   ```
4. Clique em **"Create bucket"**

### Passo 3: Configurar Políticas (Método Simples)

1. Vá para **"Storage" > "Policies"**
2. Encontre a tabela `objects`
3. **DESABILITE RLS** temporariamente:
   - Clique no botão "RLS" para desabilitá-lo
   - Isso permitirá uploads sem restrições

### Passo 4: Alternativa via SQL Editor

Se preferir usar SQL:

1. Vá para **"SQL Editor"**
2. Cole e execute este script:

```sql
-- Criar bucket driver-documents
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'driver-documents',
    'driver-documents',
    false,
    10485760,
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg', 'application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- Desabilitar RLS para simplificar
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- Conceder permissões básicas
GRANT SELECT, INSERT, UPDATE, DELETE ON storage.objects TO authenticated, anon;

-- Verificar se foi criado
SELECT id, name, public, file_size_limit, allowed_mime_types 
FROM storage.buckets 
WHERE id = 'driver-documents';
```

## 🧪 Teste da Solução

Após criar o bucket, teste no aplicativo:

1. Abra o aplicativo Flutter
2. Vá para o cadastro de motorista
3. Tente fazer upload da CNH
4. O erro "namespace CNH" deve desaparecer

## 🔍 Verificação

Para confirmar que o bucket foi criado:

```bash
# Execute este script de teste
python3 test_cnh_error.py
```

Deve mostrar:
```
✅ 1 buckets encontrados:
   - driver-documents (público: False)
     ✅ Bucket driver-documents encontrado!
```

## 📚 Explicação Técnica

### Por que o erro ocorreu?

1. **Bucket ausente**: O código Flutter tenta fazer upload para `driver-documents`
2. **Supabase Storage**: Retorna erro quando bucket não existe
3. **Mensagem confusa**: O erro "namespace CNH" é uma mensagem interna do Supabase

### Estrutura esperada:

```
supabase-storage/
├── driver-documents/          ← ESTE BUCKET ESTAVA FALTANDO
│   ├── user123/
│   │   ├── cnh_front.jpg
│   │   ├── cnh_back.jpg
│   │   └── crlv.pdf
│   └── user456/
│       └── cnh_front.jpg
└── user-photos/
    ├── user123_profile.jpg
    └── user456_profile.jpg
```

## 🚀 Próximos Passos

1. ✅ Criar bucket `driver-documents`
2. ✅ Testar upload de CNH
3. ✅ Verificar se erro foi resolvido
4. 🔄 Configurar políticas RLS adequadas (opcional)
5. 📝 Documentar processo para outros desenvolvedores

## 🆘 Se ainda houver problemas

1. Verifique se o bucket aparece na lista do Storage
2. Confirme que as permissões estão corretas
3. Teste com um arquivo pequeno primeiro
4. Verifique os logs do Flutter para outros erros

---

**💡 Dica**: Mantenha o RLS desabilitado durante o desenvolvimento para evitar problemas de permissão. Configure adequadamente apenas em produção.