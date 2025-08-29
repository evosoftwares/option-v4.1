-- Script para corrigir problemas da tabela saved_places
-- Execute este script no Supabase SQL Editor
-- Data: 2025-01-21

-- 1. Criar a tabela saved_places (se não existir)
CREATE TABLE IF NOT EXISTS saved_places (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    passenger_id UUID NOT NULL REFERENCES passengers(id) ON DELETE CASCADE,
    label VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    category VARCHAR(50) NOT NULL DEFAULT 'other',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    -- Constraint para categorias válidas
    CONSTRAINT check_category_valid 
    CHECK (category IN (
        'home', 'work', 'school', 'gym', 'restaurant', 'shopping',
        'hospital', 'bank', 'pharmacy', 'gasStation', 'park', 'cinema',
        'airport', 'hotel', 'church', 'beach', 'library', 'supermarket',
        'cafe', 'favorite', 'other'
    )),
    
    -- Evitar locais duplicados para o mesmo passageiro
    CONSTRAINT unique_passenger_label UNIQUE (passenger_id, label)
);

-- 2. Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_saved_places_passenger_id ON saved_places(passenger_id);
CREATE INDEX IF NOT EXISTS idx_saved_places_category ON saved_places(category);
CREATE INDEX IF NOT EXISTS idx_saved_places_created_at ON saved_places(created_at);

-- 3. Criar função e trigger para updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_saved_places_updated_at ON saved_places;
CREATE TRIGGER update_saved_places_updated_at 
    BEFORE UPDATE ON saved_places 
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- 4. Habilitar RLS (Row Level Security)
ALTER TABLE saved_places ENABLE ROW LEVEL SECURITY;

-- 5. Criar políticas RLS para saved_places

-- Política para SELECT: usuários podem ver apenas seus próprios saved_places
DROP POLICY IF EXISTS "Users can view own saved places" ON saved_places;
CREATE POLICY "Users can view own saved places" ON saved_places
    FOR SELECT USING (
        passenger_id = auth.uid() OR 
        passenger_id IN (
            SELECT id FROM passengers WHERE user_id = auth.uid()
        )
    );

-- Política para INSERT: usuários podem criar saved_places para si mesmos
DROP POLICY IF EXISTS "Users can insert own saved places" ON saved_places;
CREATE POLICY "Users can insert own saved places" ON saved_places
    FOR INSERT WITH CHECK (
        passenger_id = auth.uid() OR 
        passenger_id IN (
            SELECT id FROM passengers WHERE user_id = auth.uid()
        )
    );

-- Política para UPDATE: usuários podem atualizar apenas seus próprios saved_places
DROP POLICY IF EXISTS "Users can update own saved places" ON saved_places;
CREATE POLICY "Users can update own saved places" ON saved_places
    FOR UPDATE USING (
        passenger_id = auth.uid() OR 
        passenger_id IN (
            SELECT id FROM passengers WHERE user_id = auth.uid()
        )
    ) WITH CHECK (
        passenger_id = auth.uid() OR 
        passenger_id IN (
            SELECT id FROM passengers WHERE user_id = auth.uid()
        )
    );

-- Política para DELETE: usuários podem deletar apenas seus próprios saved_places
DROP POLICY IF EXISTS "Users can delete own saved places" ON saved_places;
CREATE POLICY "Users can delete own saved places" ON saved_places
    FOR DELETE USING (
        passenger_id = auth.uid() OR 
        passenger_id IN (
            SELECT id FROM passengers WHERE user_id = auth.uid()
        )
    );

-- 6. Adicionar comentários para documentação
COMMENT ON TABLE saved_places IS 'Stores user favorite locations with categories';
COMMENT ON COLUMN saved_places.passenger_id IS 'Reference to the passenger who owns this location';
COMMENT ON COLUMN saved_places.label IS 'User-friendly name for the location';
COMMENT ON COLUMN saved_places.address IS 'Full address of the location';
COMMENT ON COLUMN saved_places.latitude IS 'Latitude coordinate';
COMMENT ON COLUMN saved_places.longitude IS 'Longitude coordinate';
COMMENT ON COLUMN saved_places.category IS 'LocationType category (home, work, etc.)';

-- 7. Verificar se a tabela foi criada corretamente
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'saved_places'
ORDER BY ordinal_position;

-- 8. Verificar políticas RLS
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'saved_places';

-- Mensagem de sucesso
SELECT 'Tabela saved_places criada/atualizada com sucesso!' as status;