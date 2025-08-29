# Correção da Tabela saved_places

## Problema
O erro mostra que a tabela `saved_places` não existe no banco de dados, causando o erro:
```
Could not find the 'name' column of 'saved_places' in the schema cache
```

## Solução
Execute o SQL abaixo no Supabase para criar a tabela correta:

```sql
-- 1. Executar no SQL Editor do Supabase
\i create_saved_places_table_fixed.sql
```

Ou execute o conteúdo diretamente:

### SQL para criar a tabela saved_places

```sql
-- Criar tabela saved_places com todas as colunas necessárias
CREATE TABLE IF NOT EXISTS saved_places (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'other',
  latitude NUMERIC,
  longitude NUMERIC,
  place_id TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  -- Foreign key constraint
  CONSTRAINT fk_saved_places_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Indexes para melhorar performance
CREATE INDEX IF NOT EXISTS idx_saved_places_user_id ON saved_places(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_places_type ON saved_places(type);
CREATE INDEX IF NOT EXISTS idx_saved_places_created_at ON saved_places(created_at DESC);

-- RLS (Row Level Security) para proteger os dados
ALTER TABLE saved_places ENABLE ROW LEVEL SECURITY;

-- Policies de segurança
CREATE POLICY "Users can view own saved places" ON saved_places
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own saved places" ON saved_places
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own saved places" ON saved_places
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own saved places" ON saved_places
  FOR DELETE USING (auth.uid() = user_id);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_saved_places_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_saved_places_updated_at
  BEFORE UPDATE ON saved_places
  FOR EACH ROW
  EXECUTE FUNCTION update_saved_places_updated_at();
```

## Alterações feitas no código
Também foram corrigidos os seguintes arquivos:

1. **lib/models/favorite_location.dart**:
   - Corrigido `toInsertJson()` para incluir o campo `type`
   - Corrigido `fromJson()` para tratar `place_id` corretamente
   - Corrigido `toJson()` para consistência com o banco

## Teste após execução
Após executar o SQL, teste novamente o salvamento de locais favoritos. O erro deve ser resolvido.

## Verificação
Para verificar se a tabela foi criada corretamente:

```sql
-- Verificar estrutura da tabela
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'saved_places' 
ORDER BY ordinal_position;
```