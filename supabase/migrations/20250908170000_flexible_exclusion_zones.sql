-- Migration: Flexible exclusion zones with keyword-based matching
-- Adds keyword and zone_type fields to driver_excluded_zones table
-- Maintains backward compatibility with existing records

-- Add new columns to support flexible exclusion zones
ALTER TABLE public.driver_excluded_zones 
ADD COLUMN IF NOT EXISTS keyword TEXT,
ADD COLUMN IF NOT EXISTS zone_type TEXT CHECK (zone_type IN ('rua', 'bairro', 'cidade', 'estado', 'regiao'));

-- Create index for efficient keyword searching
CREATE INDEX IF NOT EXISTS idx_excluded_zones_keyword 
ON public.driver_excluded_zones USING gin (to_tsvector('portuguese', keyword));

-- Create index for zone_type filtering
CREATE INDEX IF NOT EXISTS idx_excluded_zones_type 
ON public.driver_excluded_zones (zone_type);

-- Migrate existing data to new format
-- Convert neighborhood_name to keyword with zone_type 'bairro'
UPDATE public.driver_excluded_zones 
SET 
  keyword = neighborhood_name,
  zone_type = 'bairro'
WHERE keyword IS NULL;

-- Create function to check if address matches excluded keywords
CREATE OR REPLACE FUNCTION check_address_exclusion(
  driver_id_param UUID,
  full_address TEXT
) 
RETURNS BOOLEAN 
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check if any keywords from driver exclusions match the address
  RETURN EXISTS (
    SELECT 1 
    FROM public.driver_excluded_zones dez
    WHERE dez.driver_id = driver_id_param
    AND (
      -- Keyword-based matching (new system)
      (dez.keyword IS NOT NULL AND lower(full_address) LIKE '%' || lower(dez.keyword) || '%')
      OR
      -- Legacy neighborhood matching (backward compatibility)
      (dez.keyword IS NULL AND lower(full_address) LIKE '%' || lower(dez.neighborhood_name) || '%')
    )
  );
END;
$$;

-- Create function to find drivers excluded by address
CREATE OR REPLACE FUNCTION get_excluded_drivers_for_address(
  full_address TEXT
) 
RETURNS TABLE(driver_id UUID, exclusion_reason TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    dez.driver_id,
    CASE 
      WHEN dez.keyword IS NOT NULL 
      THEN 'Palavra-chave: ' || dez.keyword || ' (' || COALESCE(dez.zone_type, 'não especificado') || ')'
      ELSE 'Bairro: ' || dez.neighborhood_name || ' (sistema legado)'
    END as exclusion_reason
  FROM public.driver_excluded_zones dez
  WHERE 
    (dez.keyword IS NOT NULL AND lower(full_address) LIKE '%' || lower(dez.keyword) || '%')
    OR 
    (dez.keyword IS NULL AND lower(full_address) LIKE '%' || lower(dez.neighborhood_name) || '%');
END;
$$;

-- Update the stats view to include new fields
DROP VIEW IF EXISTS public.driver_excluded_zones_stats;
CREATE VIEW public.driver_excluded_zones_stats AS
SELECT 
  dez.driver_id,
  count(*) AS total_excluded_zones,
  array_agg(DISTINCT dez.city) AS cities,
  array_agg(DISTINCT dez.state) AS states,
  array_agg(DISTINCT dez.zone_type) FILTER (WHERE dez.zone_type IS NOT NULL) AS zone_types,
  array_agg(DISTINCT dez.keyword) FILTER (WHERE dez.keyword IS NOT NULL) AS keywords,
  min(dez.created_at) AS first_exclusion_date,
  max(dez.created_at) AS last_exclusion_date,
  -- Count by zone type
  count(*) FILTER (WHERE dez.zone_type = 'rua') AS rua_exclusions,
  count(*) FILTER (WHERE dez.zone_type = 'bairro') AS bairro_exclusions,
  count(*) FILTER (WHERE dez.zone_type = 'cidade') AS cidade_exclusions,
  count(*) FILTER (WHERE dez.zone_type = 'estado') AS estado_exclusions,
  count(*) FILTER (WHERE dez.zone_type = 'regiao') AS regiao_exclusions,
  count(*) FILTER (WHERE dez.zone_type IS NULL) AS legacy_exclusions
FROM public.driver_excluded_zones dez
GROUP BY dez.driver_id;

-- Grant permissions to the view
GRANT SELECT ON public.driver_excluded_zones_stats TO option_app;
GRANT SELECT ON public.driver_excluded_zones_stats TO authenticated;
GRANT SELECT ON public.driver_excluded_zones_stats TO anon;
GRANT ALL ON public.driver_excluded_zones_stats TO option_admin;

-- Comment on new columns
COMMENT ON COLUMN public.driver_excluded_zones.keyword IS 'Palavra-chave para exclusão flexível (ex: "Centro", "Zona Sul", "Av. Brasil")';
COMMENT ON COLUMN public.driver_excluded_zones.zone_type IS 'Tipo da zona: rua, bairro, cidade, estado, regiao';

-- Comment on functions
COMMENT ON FUNCTION check_address_exclusion(UUID, TEXT) IS 'Verifica se um endereço está na lista de exclusões do motorista';
COMMENT ON FUNCTION get_excluded_drivers_for_address(TEXT) IS 'Retorna motoristas que excluíram um endereço específico';

-- Example usage comments
/*
-- Exemplos de uso do novo sistema:

-- 1. Adicionar exclusão por palavra-chave:
INSERT INTO driver_excluded_zones (driver_id, keyword, zone_type, city, state) 
VALUES ('driver-uuid', 'Centro', 'bairro', 'Rio de Janeiro', 'RJ');

-- 2. Verificar se motorista exclui endereço:
SELECT check_address_exclusion('driver-uuid', 'Rua das Flores, 123 - Centro - Rio de Janeiro - RJ');

-- 3. Encontrar motoristas excluídos para um endereço:
SELECT * FROM get_excluded_drivers_for_address('Av. Brasil, 1000 - Centro - Rio de Janeiro - RJ');

-- 4. Buscar exclusões por tipo:
SELECT * FROM driver_excluded_zones WHERE zone_type = 'regiao' AND keyword ILIKE '%zona sul%';
*/