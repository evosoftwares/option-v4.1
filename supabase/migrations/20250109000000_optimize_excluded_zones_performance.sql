-- Otimizações de Performance para Sistema de Locais Excluídos
-- Implementa as correções sugeridas no documento INEFFICIENCIES_EXCLUDED_ZONES.md

-- 1. CRIAR ÍNDICES OTIMIZADOS PARA BUSCAS FULL-TEXT

-- Índice GIN para busca full-text em keywords
CREATE INDEX IF NOT EXISTS idx_driver_excluded_zones_keyword_gin 
ON public.driver_excluded_zones 
USING gin(to_tsvector('portuguese', COALESCE(keyword, '')));

-- Índice GIN para busca full-text em neighborhood_name (compatibilidade legada)
CREATE INDEX IF NOT EXISTS idx_driver_excluded_zones_neighborhood_gin 
ON public.driver_excluded_zones 
USING gin(to_tsvector('portuguese', COALESCE(neighborhood_name, '')));

-- Índice composto para filtros por driver_id + busca textual
CREATE INDEX IF NOT EXISTS idx_driver_excluded_zones_driver_keyword 
ON public.driver_excluded_zones (driver_id, keyword);

CREATE INDEX IF NOT EXISTS idx_driver_excluded_zones_driver_neighborhood 
ON public.driver_excluded_zones (driver_id, neighborhood_name);

-- 2. FUNÇÃO OTIMIZADA PARA BUSCAR MOTORISTAS EXCLUÍDOS (COM FILTRO DE DRIVER_IDS)

CREATE OR REPLACE FUNCTION get_excluded_drivers_for_address_optimized(
  full_address TEXT,
  driver_ids UUID[] DEFAULT NULL
) 
RETURNS TABLE(driver_id UUID, exclusion_reason TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Se não há lista de motoristas, retorna vazio
  IF driver_ids IS NULL OR array_length(driver_ids, 1) IS NULL THEN
    RETURN;
  END IF;

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
    -- Filtro por lista de motoristas (feito no banco)
    dez.driver_id = ANY(driver_ids)
    AND (
      -- Busca otimizada com full-text search para keywords
      (dez.keyword IS NOT NULL AND 
       to_tsvector('portuguese', full_address) @@ to_tsquery('portuguese', 
         regexp_replace(lower(dez.keyword), '[^a-z0-9\s]', '', 'g')
       ))
      OR 
      -- Fallback para sistema legado com LIKE otimizado
      (dez.keyword IS NULL AND lower(full_address) LIKE '%' || lower(dez.neighborhood_name) || '%')
    )
  LIMIT 1000; -- Limite para evitar sobrecarga
END;
$$;

-- 3. FUNÇÃO COMBINADA PARA VERIFICAR ORIGEM E DESTINO EM UMA ÚNICA CHAMADA

CREATE OR REPLACE FUNCTION get_excluded_drivers_for_trip(
  origin_address TEXT,
  destination_address TEXT,
  driver_ids UUID[]
) 
RETURNS TABLE(
  driver_id UUID, 
  exclusion_type TEXT, -- 'origin', 'destination', 'both'
  exclusion_reason TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Se não há lista de motoristas, retorna vazio
  IF driver_ids IS NULL OR array_length(driver_ids, 1) IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH excluded_origins AS (
    SELECT 
      dez.driver_id,
      'origin' as exclusion_type,
      CASE 
        WHEN dez.keyword IS NOT NULL 
        THEN 'Origem - Palavra-chave: ' || dez.keyword || ' (' || COALESCE(dez.zone_type, 'não especificado') || ')'
        ELSE 'Origem - Bairro: ' || dez.neighborhood_name || ' (sistema legado)'
      END as exclusion_reason
    FROM public.driver_excluded_zones dez
    WHERE 
      dez.driver_id = ANY(driver_ids)
      AND origin_address IS NOT NULL 
      AND origin_address != ''
      AND (
        (dez.keyword IS NOT NULL AND 
         to_tsvector('portuguese', origin_address) @@ to_tsquery('portuguese', 
           regexp_replace(lower(dez.keyword), '[^a-z0-9\s]', '', 'g')
         ))
        OR 
        (dez.keyword IS NULL AND lower(origin_address) LIKE '%' || lower(dez.neighborhood_name) || '%')
      )
  ),
  excluded_destinations AS (
    SELECT 
      dez.driver_id,
      'destination' as exclusion_type,
      CASE 
        WHEN dez.keyword IS NOT NULL 
        THEN 'Destino - Palavra-chave: ' || dez.keyword || ' (' || COALESCE(dez.zone_type, 'não especificado') || ')'
        ELSE 'Destino - Bairro: ' || dez.neighborhood_name || ' (sistema legado)'
      END as exclusion_reason
    FROM public.driver_excluded_zones dez
    WHERE 
      dez.driver_id = ANY(driver_ids)
      AND destination_address IS NOT NULL 
      AND destination_address != ''
      AND (
        (dez.keyword IS NOT NULL AND 
         to_tsvector('portuguese', destination_address) @@ to_tsquery('portuguese', 
           regexp_replace(lower(dez.keyword), '[^a-z0-9\s]', '', 'g')
         ))
        OR 
        (dez.keyword IS NULL AND lower(destination_address) LIKE '%' || lower(dez.neighborhood_name) || '%')
      )
  )
  -- Combina resultados de origem e destino
  SELECT 
    COALESCE(eo.driver_id, ed.driver_id) as driver_id,
    CASE 
      WHEN eo.driver_id IS NOT NULL AND ed.driver_id IS NOT NULL THEN 'both'
      WHEN eo.driver_id IS NOT NULL THEN 'origin'
      ELSE 'destination'
    END as exclusion_type,
    CASE 
      WHEN eo.driver_id IS NOT NULL AND ed.driver_id IS NOT NULL 
      THEN eo.exclusion_reason || ' | ' || ed.exclusion_reason
      WHEN eo.driver_id IS NOT NULL THEN eo.exclusion_reason
      ELSE ed.exclusion_reason
    END as exclusion_reason
  FROM excluded_origins eo
  FULL OUTER JOIN excluded_destinations ed ON eo.driver_id = ed.driver_id
  LIMIT 1000; -- Limite para evitar sobrecarga
END;
$$;

-- 4. FUNÇÃO OTIMIZADA PARA VERIFICAÇÃO SIMPLES (BOOLEAN)

CREATE OR REPLACE FUNCTION check_address_exclusion_optimized(
  driver_id_param UUID,
  full_address TEXT
) 
RETURNS BOOLEAN 
LANGUAGE plpgsql
AS $$
BEGIN
  -- Verificação otimizada com índices
  RETURN EXISTS (
    SELECT 1 
    FROM public.driver_excluded_zones dez
    WHERE dez.driver_id = driver_id_param
    AND (
      -- Busca otimizada com full-text search
      (dez.keyword IS NOT NULL AND 
       to_tsvector('portuguese', full_address) @@ to_tsquery('portuguese', 
         regexp_replace(lower(dez.keyword), '[^a-z0-9\s]', '', 'g')
       ))
      OR 
      -- Fallback para sistema legado
      (dez.keyword IS NULL AND lower(full_address) LIKE '%' || lower(dez.neighborhood_name) || '%')
    )
    LIMIT 1 -- Para otimização, só precisa saber se existe
  );
END;
$$;

-- 5. COMENTÁRIOS E DOCUMENTAÇÃO

COMMENT ON FUNCTION get_excluded_drivers_for_address_optimized(TEXT, UUID[]) IS 
'Versão otimizada que aceita lista de driver_ids e faz filtro no banco de dados. Usa índices GIN para busca full-text.';

COMMENT ON FUNCTION get_excluded_drivers_for_trip(TEXT, TEXT, UUID[]) IS 
'Função combinada que verifica origem e destino em uma única chamada, reduzindo tráfego de rede.';

COMMENT ON FUNCTION check_address_exclusion_optimized(UUID, TEXT) IS 
'Versão otimizada da verificação de exclusão usando índices GIN e full-text search.';

-- 6. ESTATÍSTICAS E ANÁLISE DE PERFORMANCE

-- Atualizar estatísticas das tabelas para otimização do query planner
ANALYZE public.driver_excluded_zones;

-- Exemplo de uso das novas funções:
/*
-- 1. Buscar motoristas excluídos para um endereço (com filtro de driver_ids):
SELECT * FROM get_excluded_drivers_for_address_optimized(
  'Rua das Flores, 123 - Centro - Rio de Janeiro - RJ',
  ARRAY['driver-uuid-1', 'driver-uuid-2']::UUID[]
);

-- 2. Verificar exclusões para origem e destino em uma única chamada:
SELECT * FROM get_excluded_drivers_for_trip(
  'Centro - Rio de Janeiro - RJ',
  'Copacabana - Rio de Janeiro - RJ', 
  ARRAY['driver-uuid-1', 'driver-uuid-2']::UUID[]
);

-- 3. Verificação simples otimizada:
SELECT check_address_exclusion_optimized(
  'driver-uuid'::UUID, 
  'Centro - Rio de Janeiro - RJ'
);
*/