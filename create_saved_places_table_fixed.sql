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
  
  -- Foreign key constraint referencing app_users table
  CONSTRAINT fk_saved_places_user_id FOREIGN KEY (user_id) REFERENCES app_users(id) ON DELETE CASCADE
);

-- Indexes para melhorar performance
CREATE INDEX IF NOT EXISTS idx_saved_places_user_id ON saved_places(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_places_type ON saved_places(type);
CREATE INDEX IF NOT EXISTS idx_saved_places_created_at ON saved_places(created_at DESC);

-- RLS (Row Level Security) para proteger os dados
ALTER TABLE saved_places ENABLE ROW LEVEL SECURITY;

-- Policy para usuários só verem seus próprios locais salvos
CREATE POLICY "Users can view own saved places" ON saved_places
  FOR SELECT USING (
    user_id IN (SELECT id FROM app_users WHERE user_id = auth.uid())
  );

-- Policy para usuários criarem seus próprios locais salvos
CREATE POLICY "Users can insert own saved places" ON saved_places
  FOR INSERT WITH CHECK (
    user_id IN (SELECT id FROM app_users WHERE user_id = auth.uid())
  );

-- Policy para usuários atualizarem seus próprios locais salvos
CREATE POLICY "Users can update own saved places" ON saved_places
  FOR UPDATE USING (
    user_id IN (SELECT id FROM app_users WHERE user_id = auth.uid())
  );

-- Policy para usuários deletarem seus próprios locais salvos
CREATE POLICY "Users can delete own saved places" ON saved_places
  FOR DELETE USING (
    user_id IN (SELECT id FROM app_users WHERE user_id = auth.uid())
  );

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