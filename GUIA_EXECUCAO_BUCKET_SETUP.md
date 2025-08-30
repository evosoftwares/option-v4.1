# 🚀 Guia de Execução: Configuração do Bucket user-photos

## 📋 Diagnóstico Realizado

✅ **Conectividade com Supabase**: OK  
❌ **Bucket user-photos**: NÃO EXISTE  
❌ **Políticas de segurança**: N/A (bucket não existe)  
❌ **Upload de arquivos**: IMPOSSÍVEL (bucket não existe)  

## 🎯 Problema Identificado

O bucket `user-photos` **não existe** no Supabase Storage, impedindo qualquer upload de arquivos.

## 🔧 Solução: Executar Script SQL

### Passo 1: Acessar o Supabase Dashboard

1. Acesse: https://supabase.com/dashboard
2. Faça login na sua conta
3. Selecione o projeto: `qlbwacmavngtonauxnte`

### Passo 2: Abrir o SQL Editor

1. No menu lateral, clique em **"SQL Editor"**
2. Clique em **"New query"** ou **"+ New"**

### Passo 3: Executar o Script

1. Copie todo o conteúdo do arquivo `setup_user_photos_bucket_no_rls.sql`
2. Cole no editor SQL
3. Clique em **"Run"** ou pressione `Ctrl+Enter`

### Passo 4: Verificar a Execução

Após executar o script, você deve ver:

```
✅ Bucket 'user-photos' criado com sucesso!
✅ RLS desabilitado na tabela storage.objects
✅ Políticas antigas removidas
✅ Permissões básicas concedidas
```

## 📁 Conteúdo do Script (setup_user_photos_bucket_no_rls.sql)

O script irá:

1. **Criar o bucket `user-photos`**:
   - Público: `true`
   - Limite: 5MB
   - Tipos MIME: JPEG, PNG, WEBP, JPG

2. **Desabilitar RLS** (conforme restrição do projeto)

3. **Remover políticas existentes** (limpeza)

4. **Conceder permissões básicas**:
   - SELECT para todos
   - INSERT para usuários autenticados e anônimos
   - UPDATE para usuários autenticados e anônimos
   - DELETE para usuários autenticados e anônimos

## 🧪 Validação

Após executar o script:

### Opção 1: Teste via Python
```bash
python3 test_supabase_bucket.py
```

### Opção 2: Verificação Manual no Dashboard

1. Vá para **"Storage"** no menu lateral
2. Verifique se o bucket `user-photos` aparece na lista
3. Clique no bucket para ver suas configurações

### Opção 3: Teste na Aplicação Flutter

Após criar o bucket, teste o upload de uma foto de perfil na aplicação.

## ⚠️ Notas Importantes

### Segurança
- **RLS está DESABILITADO** conforme restrição do projeto
- A segurança será gerenciada pela aplicação Flutter
- Todos os usuários (autenticados e anônimos) podem fazer upload

### Estrutura de Pastas
O bucket usará a estrutura:
```
user-photos/
├── users/
│   ├── {userId}/
│   │   └── profile/
│   │       └── {timestamp}_{filename}
```

### Limitações
- **Tamanho máximo**: 5MB por arquivo
- **Tipos permitidos**: JPEG, PNG, WEBP, JPG
- **Bucket público**: URLs acessíveis sem autenticação

## 🚨 Troubleshooting

### Erro: "insufficient_privilege"
- Verifique se você tem permissões de administrador no projeto
- Entre em contato com o owner do projeto Supabase

### Erro: "relation does not exist"
- O Supabase Storage pode não estar habilitado
- Vá em Settings > API > Storage e verifique se está ativo

### Script não executa
- Verifique se copiou o script completo
- Certifique-se de que não há caracteres especiais
- Tente executar linha por linha

## 📞 Próximos Passos

1. ✅ Execute o script SQL
2. ✅ Valide a criação do bucket
3. ✅ Teste o upload na aplicação
4. ✅ Monitore logs de erro

---

**Data**: $(date)  
**Status**: Aguardando execução do script SQL  
**Prioridade**: 🔴 ALTA - Bloqueando uploads de fotos