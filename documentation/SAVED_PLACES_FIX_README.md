# Correção do Erro de Permissão - Tabela saved_places

## 🚨 Problema Identificado

O erro `PostgrestException permission denied` na tabela `saved_places` ocorre porque:

1. **A tabela `saved_places` não existe no Supabase**
2. A migração `add_category_to_saved_places.sql` tenta fazer `ALTER TABLE` em uma tabela inexistente
3. Faltam políticas RLS (Row Level Security) configuradas

## ✅ Solução Implementada

### 1. Script de Correção Criado

Criamos o arquivo `fix_saved_places_table.sql` que:

- ✅ Cria a tabela `saved_places` com todas as colunas necessárias (incluindo `category`)
- ✅ Adiciona índices para performance
- ✅ Configura trigger para `updated_at`
- ✅ Habilita RLS (Row Level Security)
- ✅ Cria políticas de segurança para SELECT, INSERT, UPDATE, DELETE
- ✅ Adiciona comentários de documentação
- ✅ Inclui verificações de validação

### 2. Migração Obsoleta

O arquivo `database/migrations/add_category_to_saved_places.sql` **NÃO é mais necessário** porque:

- O script `fix_saved_places_table.sql` já cria a tabela com a coluna `category`
- Evita conflitos de constraint duplicadas
- Inclui todas as funcionalidades da migração original

## 🔧 Passos para Correção

### Passo 1: Executar no Supabase

1. Acesse o **Supabase Dashboard**
2. Vá para **SQL Editor**
3. Execute o conteúdo do arquivo `fix_saved_places_table.sql`
4. Verifique se não há erros na execução

### Passo 2: Verificar Criação

Após executar o script, você deve ver:

```sql
-- Verificar estrutura da tabela
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'saved_places'
ORDER BY ordinal_position;

-- Verificar políticas RLS
SELECT policyname, cmd, qual
FROM pg_policies 
WHERE tablename = 'saved_places';
```

### Passo 3: Testar Funcionalidade

1. Reinicie o app Flutter
2. Teste a criação de saved places
3. Verifique se as categorias funcionam corretamente
4. Confirme que não há mais erros de permissão

## 📋 Estrutura da Tabela saved_places

```sql
CREATE TABLE saved_places (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    passenger_id UUID NOT NULL REFERENCES passengers(id) ON DELETE CASCADE,
    label VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    category VARCHAR(50) NOT NULL DEFAULT 'other',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

## 🔒 Políticas RLS Configuradas

- **SELECT**: Usuários podem ver apenas seus próprios saved places
- **INSERT**: Usuários podem criar saved places para si mesmos
- **UPDATE**: Usuários podem atualizar apenas seus próprios saved places
- **DELETE**: Usuários podem deletar apenas seus próprios saved places

## 🎯 Categorias Suportadas

O sistema suporta 21 categorias do enum `LocationType`:

- `home`, `work`, `school`, `gym`, `restaurant`, `shopping`
- `hospital`, `bank`, `pharmacy`, `gasStation`, `park`, `cinema`
- `airport`, `hotel`, `church`, `beach`, `library`, `supermarket`
- `cafe`, `favorite`, `other`

## ⚠️ Importante

- **NÃO execute** `add_category_to_saved_places.sql` após executar `fix_saved_places_table.sql`
- O script de correção já inclui todas as funcionalidades necessárias
- Certifique-se de que o usuário autenticado tem um registro na tabela `passengers`

## 🧪 Próximos Passos

1. ✅ Executar `fix_saved_places_table.sql` no Supabase
2. ⏳ Testar funcionalidade de saved places no app
3. ⏳ Validar que as categorias funcionam corretamente
4. ⏳ Confirmar que não há mais erros de permissão

---

**Status**: Script de correção criado e pronto para execução no Supabase.