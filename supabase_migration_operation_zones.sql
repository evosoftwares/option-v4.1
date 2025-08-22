-- Criar tabela para áreas de atuação do motorista com fatores de multiplicação
CREATE TABLE driver_operation_zones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    zone_name TEXT NOT NULL,
    polygon_coordinates JSONB NOT NULL, -- Array de objetos {lat: number, lng: number}
    price_multiplier NUMERIC(4,2) NOT NULL DEFAULT 1.00 CHECK (price_multiplier >= 0.1 AND price_multiplier <= 10.0),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Índices para performance
CREATE INDEX idx_driver_operation_zones_driver_id ON driver_operation_zones(driver_id);
CREATE INDEX idx_driver_operation_zones_active ON driver_operation_zones(is_active);
CREATE INDEX idx_driver_operation_zones_created_at ON driver_operation_zones(created_at);

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_driver_operation_zones_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para atualizar updated_at
CREATE TRIGGER trigger_update_driver_operation_zones_updated_at
    BEFORE UPDATE ON driver_operation_zones
    FOR EACH ROW
    EXECUTE FUNCTION update_driver_operation_zones_updated_at();

-- Comentários
COMMENT ON TABLE driver_operation_zones IS 'Áreas de atuação do motorista com fatores de multiplicação de preço';
COMMENT ON COLUMN driver_operation_zones.zone_name IS 'Nome da área definido pelo motorista';
COMMENT ON COLUMN driver_operation_zones.polygon_coordinates IS 'Coordenadas do polígono em formato JSON: [{"lat": -23.5505, "lng": -46.6333}, ...]';
COMMENT ON COLUMN driver_operation_zones.price_multiplier IS 'Fator de multiplicação do preço (1.0 = normal, 1.5 = 50% a mais, etc.)';
COMMENT ON COLUMN driver_operation_zones.is_active IS 'Se a área está ativa para aplicação do multiplicador';

-- Políticas RLS (Row Level Security)
ALTER TABLE driver_operation_zones ENABLE ROW LEVEL SECURITY;

-- Política para motoristas verem apenas suas próprias áreas
CREATE POLICY driver_operation_zones_driver_policy ON driver_operation_zones
    FOR ALL
    USING (driver_id = auth.uid())
    WITH CHECK (driver_id = auth.uid());

-- Política para admins (se necessário no futuro)
CREATE POLICY driver_operation_zones_admin_policy ON driver_operation_zones
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM app_users 
            WHERE id = auth.uid() 
            AND user_type = 'admin'
        )
    );