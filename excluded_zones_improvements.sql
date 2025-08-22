-- =====================================================
-- MELHORIAS PARA SISTEMA DE ZONAS EXCLUÍDAS
-- =====================================================
-- Este script implementa todas as melhorias recomendadas
-- para tornar o sistema de zonas excluídas mais robusto

-- =====================================================
-- 1. CONSTRAINT UNIQUE COMPOSTA
-- =====================================================
-- Previne duplicatas de zonas excluídas para o mesmo motorista
ALTER TABLE driver_excluded_zones 
ADD CONSTRAINT uk_driver_excluded_zones 
UNIQUE (driver_id, neighborhood_name, city, state);

-- =====================================================
-- 2. ÍNDICES PARA PERFORMANCE
-- =====================================================
-- Índice para consultas por motorista
CREATE INDEX IF NOT EXISTS idx_driver_excluded_zones_driver_id 
ON driver_excluded_zones(driver_id);

-- Índice para consultas por localização
CREATE INDEX IF NOT EXISTS idx_driver_excluded_zones_location 
ON driver_excluded_zones(city, state);

-- Índice composto para verificação de exclusão
CREATE INDEX IF NOT EXISTS idx_driver_excluded_zones_check 
ON driver_excluded_zones(driver_id, neighborhood_name, city, state);

-- =====================================================
-- 3. CAMPOS DE AUDITORIA
-- =====================================================
-- Adiciona campos para rastreamento de mudanças
ALTER TABLE driver_excluded_zones 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

-- =====================================================
-- 4. TRIGGER PARA UPDATED_AT
-- =====================================================
-- Função para atualizar timestamp automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para atualizar updated_at automaticamente
DROP TRIGGER IF EXISTS trigger_update_driver_excluded_zones_updated_at ON driver_excluded_zones;
CREATE TRIGGER trigger_update_driver_excluded_zones_updated_at
    BEFORE UPDATE ON driver_excluded_zones
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 5. FUNÇÃO PARA NORMALIZAÇÃO DE STRINGS
-- =====================================================
-- Função para normalizar nomes de locais
CREATE OR REPLACE FUNCTION normalize_location_name(input_text TEXT)
RETURNS TEXT AS $$
BEGIN
    -- Remove espaços extras, converte para lowercase e remove acentos
    RETURN TRIM(LOWER(UNACCENT(input_text)));
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 6. TRIGGER PARA NORMALIZAÇÃO AUTOMÁTICA
-- =====================================================
-- Função para normalizar dados antes da inserção/atualização
CREATE OR REPLACE FUNCTION normalize_excluded_zone_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Normaliza os campos de localização
    NEW.neighborhood_name = normalize_location_name(NEW.neighborhood_name);
    NEW.city = normalize_location_name(NEW.city);
    NEW.state = normalize_location_name(NEW.state);
    
    -- Define created_by se não estiver definido
    IF NEW.created_by IS NULL THEN
        NEW.created_by = auth.uid();
    END IF;
    
    -- Define updated_by
    NEW.updated_by = auth.uid();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para normalização automática
DROP TRIGGER IF EXISTS trigger_normalize_excluded_zone_data ON driver_excluded_zones;
CREATE TRIGGER trigger_normalize_excluded_zone_data
    BEFORE INSERT OR UPDATE ON driver_excluded_zones
    FOR EACH ROW
    EXECUTE FUNCTION normalize_excluded_zone_data();

-- =====================================================
-- 7. FUNÇÃO PARA VALIDAR LIMITES
-- =====================================================
-- Função para verificar limite máximo de zonas por motorista
CREATE OR REPLACE FUNCTION check_excluded_zones_limit()
RETURNS TRIGGER AS $$
DECLARE
    zone_count INTEGER;
    max_zones INTEGER := 50; -- Limite máximo de zonas por motorista
BEGIN
    -- Conta zonas existentes para o motorista
    SELECT COUNT(*) INTO zone_count
    FROM driver_excluded_zones
    WHERE driver_id = NEW.driver_id;
    
    -- Verifica se excede o limite (apenas para INSERT)
    IF TG_OP = 'INSERT' AND zone_count >= max_zones THEN
        RAISE EXCEPTION 'Limite máximo de % zonas excluídas atingido para este motorista', max_zones;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para validação de limites
DROP TRIGGER IF EXISTS trigger_check_excluded_zones_limit ON driver_excluded_zones;
CREATE TRIGGER trigger_check_excluded_zones_limit
    BEFORE INSERT ON driver_excluded_zones
    FOR EACH ROW
    EXECUTE FUNCTION check_excluded_zones_limit();

-- =====================================================
-- 8. FUNÇÃO PARA VALIDAÇÃO GEOGRÁFICA BÁSICA
-- =====================================================
-- Função para validação básica de dados geográficos
CREATE OR REPLACE FUNCTION validate_geographic_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Validações básicas
    IF LENGTH(TRIM(NEW.neighborhood_name)) < 2 THEN
        RAISE EXCEPTION 'Nome do bairro deve ter pelo menos 2 caracteres';
    END IF;
    
    IF LENGTH(TRIM(NEW.city)) < 2 THEN
        RAISE EXCEPTION 'Nome da cidade deve ter pelo menos 2 caracteres';
    END IF;
    
    IF LENGTH(TRIM(NEW.state)) < 2 THEN
        RAISE EXCEPTION 'Nome do estado deve ter pelo menos 2 caracteres';
    END IF;
    
    -- Verifica se contém apenas caracteres válidos (letras, espaços, hífens)
    IF NEW.neighborhood_name !~ '^[a-zA-ZÀ-ÿ\s\-\.]+$' THEN
        RAISE EXCEPTION 'Nome do bairro contém caracteres inválidos';
    END IF;
    
    IF NEW.city !~ '^[a-zA-ZÀ-ÿ\s\-\.]+$' THEN
        RAISE EXCEPTION 'Nome da cidade contém caracteres inválidos';
    END IF;
    
    IF NEW.state !~ '^[a-zA-ZÀ-ÿ\s\-\.]+$' THEN
        RAISE EXCEPTION 'Nome do estado contém caracteres inválidos';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para validação geográfica
DROP TRIGGER IF EXISTS trigger_validate_geographic_data ON driver_excluded_zones;
CREATE TRIGGER trigger_validate_geographic_data
    BEFORE INSERT OR UPDATE ON driver_excluded_zones
    FOR EACH ROW
    EXECUTE FUNCTION validate_geographic_data();

-- =====================================================
-- 9. POLÍTICAS RLS APRIMORADAS
-- =====================================================
-- Remove políticas existentes se houver
DROP POLICY IF EXISTS driver_excluded_zones_driver_policy ON driver_excluded_zones;
DROP POLICY IF EXISTS driver_excluded_zones_admin_policy ON driver_excluded_zones;

-- Política para motoristas (apenas suas próprias zonas)
CREATE POLICY driver_excluded_zones_driver_policy ON driver_excluded_zones
    FOR ALL
    USING (
        driver_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM app_users 
            WHERE id = auth.uid() 
            AND user_type = 'driver'
            AND status = 'active'
        )
    )
    WITH CHECK (
        driver_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM app_users 
            WHERE id = auth.uid() 
            AND user_type = 'driver'
            AND status = 'active'
        )
    );

-- Política para admins (acesso total)
CREATE POLICY driver_excluded_zones_admin_policy ON driver_excluded_zones
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM app_users 
            WHERE id = auth.uid() 
            AND user_type = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM app_users 
            WHERE id = auth.uid() 
            AND user_type = 'admin'
        )
    );

-- =====================================================
-- 10. COMENTÁRIOS PARA DOCUMENTAÇÃO
-- =====================================================
COMMENT ON TABLE driver_excluded_zones IS 'Zonas excluídas por motorista com validações e auditoria completa';
COMMENT ON COLUMN driver_excluded_zones.neighborhood_name IS 'Nome do bairro (normalizado automaticamente)';
COMMENT ON COLUMN driver_excluded_zones.city IS 'Nome da cidade (normalizado automaticamente)';
COMMENT ON COLUMN driver_excluded_zones.state IS 'Nome do estado (normalizado automaticamente)';
COMMENT ON COLUMN driver_excluded_zones.created_by IS 'Usuário que criou o registro';
COMMENT ON COLUMN driver_excluded_zones.updated_by IS 'Usuário que atualizou o registro pela última vez';
COMMENT ON COLUMN driver_excluded_zones.updated_at IS 'Timestamp da última atualização (automático)';

-- =====================================================
-- 11. FUNÇÃO PARA ESTATÍSTICAS
-- =====================================================
-- Função para obter estatísticas de zonas excluídas
CREATE OR REPLACE FUNCTION get_excluded_zones_stats(driver_uuid UUID DEFAULT NULL)
RETURNS TABLE (
    total_zones INTEGER,
    zones_by_state JSONB,
    zones_by_city JSONB,
    most_excluded_areas JSONB
) AS $$
BEGIN
    RETURN QUERY
    WITH driver_filter AS (
        SELECT CASE 
            WHEN driver_uuid IS NULL THEN auth.uid()
            ELSE driver_uuid
        END as target_driver_id
    ),
    zone_data AS (
        SELECT dez.*
        FROM driver_excluded_zones dez, driver_filter df
        WHERE dez.driver_id = df.target_driver_id
    )
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM zone_data) as total_zones,
        (
            SELECT COALESCE(jsonb_object_agg(state, zone_count), '{}'::jsonb)
            FROM (
                SELECT state, COUNT(*) as zone_count
                FROM zone_data
                GROUP BY state
                ORDER BY zone_count DESC
            ) state_stats
        ) as zones_by_state,
        (
            SELECT COALESCE(jsonb_object_agg(city, zone_count), '{}'::jsonb)
            FROM (
                SELECT city, COUNT(*) as zone_count
                FROM zone_data
                GROUP BY city
                ORDER BY zone_count DESC
                LIMIT 10
            ) city_stats
        ) as zones_by_city,
        (
            SELECT COALESCE(jsonb_agg(jsonb_build_object(
                'neighborhood', neighborhood_name,
                'city', city,
                'state', state,
                'created_at', created_at
            )), '[]'::jsonb)
            FROM (
                SELECT neighborhood_name, city, state, created_at
                FROM zone_data
                ORDER BY created_at DESC
                LIMIT 5
            ) recent_zones
        ) as most_excluded_areas;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FINALIZAÇÃO
-- =====================================================
-- Mensagem de sucesso
DO $$
BEGIN
    RAISE NOTICE 'Melhorias do sistema de zonas excluídas aplicadas com sucesso!';
    RAISE NOTICE 'Funcionalidades implementadas:';
    RAISE NOTICE '✓ Constraint UNIQUE composta';
    RAISE NOTICE '✓ Índices para performance';
    RAISE NOTICE '✓ Campos de auditoria';
    RAISE NOTICE '✓ Normalização automática de dados';
    RAISE NOTICE '✓ Validação de limites';
    RAISE NOTICE '✓ Validação geográfica básica';
    RAISE NOTICE '✓ Políticas RLS aprimoradas';
    RAISE NOTICE '✓ Função de estatísticas';
END $$;