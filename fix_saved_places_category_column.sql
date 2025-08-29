-- Script para corrigir a tabela saved_places adicionando a coluna 'category'
-- Este script resolve o problema crítico identificado na investigação

-- 1. Adicionar a coluna category com valor padrão
ALTER TABLE saved_places 
ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT 'favorite';

-- 2. Adicionar constraint de validação para os tipos de categoria permitidos
ALTER TABLE saved_places 
ADD CONSTRAINT IF NOT EXISTS check_category_valid 
CHECK (category IN (
  'home', 
  'work', 
  'favorite', 
  'other', 
  'school', 
  'gym', 
  'hospital', 
  'shopping', 
  'restaurant', 
  'airport', 
  'hotel', 
  'park'
));

-- 3. Atualizar registros existentes (se houver) para ter categoria 'favorite'
UPDATE saved_places 
SET category = 'favorite' 
WHERE category IS NULL;

-- 4. Tornar a coluna NOT NULL após atualizar os registros existentes
ALTER TABLE saved_places 
ALTER COLUMN category SET NOT NULL;

-- 5. Criar índice para melhorar performance de consultas por categoria
CREATE INDEX IF NOT EXISTS idx_saved_places_category 
ON saved_places(category);

-- 6. Criar índice composto para consultas por usuário e categoria
CREATE INDEX IF NOT EXISTS idx_saved_places_passenger_category 
ON saved_places(passenger_id, category);

-- 7. Verificar se a estrutura está correta
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'saved_places' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 8. Verificar constraints
SELECT 
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'saved_places' 
AND table_schema = 'public';

-- Comentários:
-- Este script resolve o problema crítico onde o código Flutter espera
-- uma coluna 'category' que não existia na tabela saved_places.
-- Após executar este script, o salvamento de locais favoritos
-- funcionará corretamente com as categorias (LocationType).