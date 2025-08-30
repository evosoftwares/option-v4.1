-- ===================================================
-- IMPORTANTE: Execute este SQL no Supabase SQL Editor
-- ===================================================
-- 
-- O fluxo do stepper não está salvando os locais favoritos porque 
-- a tabela 'saved_places' não existe no banco de dados.
-- 
-- Execute os comandos abaixo no Supabase Dashboard > SQL Editor
-- para criar a tabela necessária.

-- 1. Criar a tabela saved_places
CREATE TABLE IF NOT EXISTS saved_places (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    label VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    category VARCHAR(50) NOT NULL DEFAULT 'other',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    -- Add check constraint para categorias válidas
    CONSTRAINT check_category_valid 
    CHECK (category IN (
        'home', 'work', 'school', 'gym', 'restaurant', 'shopping',
        'hospital', 'bank', 'pharmacy', 'gasStation', 'park', 'cinema',
        'airport', 'hotel', 'church', 'beach', 'library', 'supermarket',
        'cafe', 'favorite', 'other'
    )),
    
    -- Evitar locais duplicados para o mesmo usuário
    CONSTRAINT unique_user_label UNIQUE (user_id, label)
);

-- 2. Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_saved_places_user_id ON saved_places(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_places_category ON saved_places(category);
CREATE INDEX IF NOT EXISTS idx_saved_places_created_at ON saved_places(created_at);

-- 3. Criar trigger para updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Remover trigger existente se houver e criar novamente
DROP TRIGGER IF EXISTS update_saved_places_updated_at ON saved_places;
CREATE TRIGGER update_saved_places_updated_at BEFORE UPDATE ON saved_places 
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- 4. Verificar se a tabela foi criada corretamente
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'saved_places' 
ORDER BY ordinal_position;

-- 5. Verificar se há usuários para testar
SELECT COUNT(*) as total_users FROM auth.users;

-- ===================================================
-- INSTRUÇÕES:
-- ===================================================
-- 1. Vá para seu dashboard do Supabase
-- 2. Clique em "SQL Editor" no menu lateral
-- 3. Cole este código completo
-- 4. Clique em "Run" para executar
-- 5. Verifique se a última query retorna as colunas da tabela saved_places
-- 6. Teste o fluxo de cadastro novamente no app
-- ===================================================