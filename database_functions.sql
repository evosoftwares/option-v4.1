-- Função RPC para buscar estatísticas das categorias de veículos disponíveis em uma região
-- Usada pelo DriverService.getAvailableCategoriesInRegion()

CREATE OR REPLACE FUNCTION get_available_categories_stats(
  lat float8,
  lng float8,
  radius_km float8 DEFAULT 10.0
)
RETURNS TABLE (
  vehicle_category text,
  driver_count integer,
  avg_price_per_km numeric,
  avg_price_per_minute numeric,
  avg_distance_km numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  lat_delta float8;
  lng_delta float8;
BEGIN
  -- Calcula deltas aproximados para bounding box (aproximação rápida)
  lat_delta := radius_km / 111.0; -- ~111km por grau de latitude
  lng_delta := radius_km / (111.0 * cos(radians(lat))); -- ajustado pela longitude
  
  RETURN QUERY
  SELECT 
    d.vehicle_category,
    COUNT(*)::integer as driver_count,
    AVG(CASE 
      WHEN d.custom_price_per_km IS NOT NULL AND d.custom_price_per_km > 0 
      THEN d.custom_price_per_km 
      ELSE 1.5 -- preço padrão 
    END)::numeric as avg_price_per_km,
    AVG(CASE 
      WHEN d.custom_price_per_minute IS NOT NULL AND d.custom_price_per_minute > 0 
      THEN d.custom_price_per_minute 
      ELSE 0.20 -- preço padrão 
    END)::numeric as avg_price_per_minute,
    -- Distância média aproximada (pode ser melhorada com cálculo real de distância)
    AVG(
      SQRT(
        POW((d.current_latitude - lat) * 111.0, 2) + 
        POW((d.current_longitude - lng) * 111.0 * cos(radians(lat)), 2)
      )
    )::numeric as avg_distance_km
  FROM drivers d
  WHERE 
    d.is_online = true 
    AND (d.approval_status = 'approved' OR d.approval_status IS NULL)
    AND d.current_latitude IS NOT NULL 
    AND d.current_longitude IS NOT NULL
    AND d.vehicle_category IS NOT NULL
    -- Bounding box filter
    AND d.current_latitude BETWEEN (lat - lat_delta) AND (lat + lat_delta)
    AND d.current_longitude BETWEEN (lng - lng_delta) AND (lng + lng_delta)
  GROUP BY d.vehicle_category
  HAVING COUNT(*) > 0
  ORDER BY driver_count DESC;
END;
$$;

-- Comentário explicativo
COMMENT ON FUNCTION get_available_categories_stats(float8, float8, float8) IS 
'Retorna estatísticas das categorias de veículos disponíveis em uma região específica. Usado pela app para mostrar motoristas disponíveis por categoria em tempo real.';