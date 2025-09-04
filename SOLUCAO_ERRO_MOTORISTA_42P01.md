# Solução para Erro 42P01 - Dados do Motorista

## Problema Identificado

O erro `42P01` (relation does not exist) está ocorrendo porque a função `get_nearby_drivers` no Supabase está tentando acessar um campo `drivers.name` que não existe na tabela `drivers`. O nome do motorista está na tabela `app_users` como `full_name`.

## Causa Raiz

As funções `get_nearby_drivers` e `get_emergency_nearby_drivers` estão mal configuradas e tentam acessar campos inexistentes na tabela `drivers`, causando o erro PostgreSQL 42P01.

## Solução

### Passo 1: Executar Correção no Supabase

1. Acesse o painel do Supabase
2. Vá para **SQL Editor**
3. Execute o script completo do arquivo `CORRIGIR_FUNCAO_GET_NEARBY_DRIVERS.sql`

### Passo 2: Script de Correção

```sql
-- 1. Remover função problemática
DROP FUNCTION IF EXISTS get_nearby_drivers(lat double precision, lng double precision, radius_km double precision);

-- 2. Criar função corrigida
CREATE OR REPLACE FUNCTION get_nearby_drivers(
    lat double precision, 
    lng double precision, 
    radius_km double precision DEFAULT 5.0
)
RETURNS TABLE(
    driver_id uuid,
    user_id uuid,
    driver_name text,
    fcm_token text,
    device_platform text,
    is_online boolean,
    current_latitude numeric,
    current_longitude numeric,
    vehicle_category text,
    distance_km double precision
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id as driver_id,
        d.user_id,
        au.full_name as driver_name,  -- CORREÇÃO: usar au.full_name em vez de d.name
        d.fcm_token,
        d.device_platform,
        d.is_online,
        d.current_latitude,
        d.current_longitude,
        d.vehicle_category,
        (
            6371 * acos(
                cos(radians(lat)) * 
                cos(radians(d.current_latitude::double precision)) * 
                cos(radians(d.current_longitude::double precision) - radians(lng)) + 
                sin(radians(lat)) * 
                sin(radians(d.current_latitude::double precision))
            )
        ) as distance_km
    FROM drivers d
    INNER JOIN app_users au ON d.user_id = au.id  -- CORREÇÃO: JOIN com app_users
    WHERE 
        d.is_online = true
        AND d.approval_status = 'approved'
        AND d.current_latitude IS NOT NULL
        AND d.current_longitude IS NOT NULL
        AND au.status = 'active'
        AND d.current_latitude BETWEEN (lat - radius_km / 111.0) AND (lat + radius_km / 111.0)
        AND d.current_longitude BETWEEN (lng - radius_km / (111.0 * cos(radians(lat)))) AND (lng + radius_km / (111.0 * cos(radians(lat))))
    ORDER BY distance_km ASC
    LIMIT 50;
END;
$$;

-- 3. Dar permissões
GRANT EXECUTE ON FUNCTION get_nearby_drivers(double precision, double precision, double precision) TO authenticated;
GRANT EXECUTE ON FUNCTION get_nearby_drivers(double precision, double precision, double precision) TO anon;
```

### Passo 3: Corrigir Função de Emergência

```sql
-- Corrigir função de emergência também
DROP FUNCTION IF EXISTS get_emergency_nearby_drivers(lat double precision, lng double precision, radius_km double precision);

CREATE OR REPLACE FUNCTION get_emergency_nearby_drivers(
    lat double precision, 
    lng double precision, 
    radius_km double precision DEFAULT 2.0
)
RETURNS TABLE(
    driver_id uuid,
    user_id uuid,
    driver_name text,
    phone text,
    fcm_token text,
    current_latitude numeric,
    current_longitude numeric,
    distance_km double precision
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id as driver_id,
        d.user_id,
        au.full_name as driver_name,  -- CORREÇÃO: usar au.full_name
        au.phone,
        d.fcm_token,
        d.current_latitude,
        d.current_longitude,
        (
            6371 * acos(
                cos(radians(lat)) * 
                cos(radians(d.current_latitude::double precision)) * 
                cos(radians(d.current_longitude::double precision) - radians(lng)) + 
                sin(radians(lat)) * 
                sin(radians(d.current_latitude::double precision))
            )
        ) as distance_km
    FROM drivers d
    INNER JOIN app_users au ON d.user_id = au.id  -- CORREÇÃO: JOIN com app_users
    WHERE 
        d.is_online = true
        AND d.approval_status = 'approved'
        AND d.current_latitude IS NOT NULL
        AND d.current_longitude IS NOT NULL
        AND au.status = 'active'
        AND (
            6371 * acos(
                cos(radians(lat)) * 
                cos(radians(d.current_latitude::double precision)) * 
                cos(radians(d.current_longitude::double precision) - radians(lng)) + 
                sin(radians(lat)) * 
                sin(radians(d.current_latitude::double precision))
            )
        ) <= radius_km
    ORDER BY distance_km ASC
    LIMIT 10;
END;
$$;

GRANT EXECUTE ON FUNCTION get_emergency_nearby_drivers(double precision, double precision, double precision) TO authenticated;
```

### Passo 4: Testar as Funções

```sql
-- Teste básico
SELECT * FROM get_nearby_drivers(-23.5505, -46.6333, 5.0) LIMIT 3;
SELECT * FROM get_emergency_nearby_drivers(-23.5505, -46.6333, 2.0) LIMIT 3;
```

## Serviços Afetados

Os seguintes serviços Flutter estão chamando essas funções:

1. **NotificationSegmentationService** (linha 132)
   - Chama `get_nearby_drivers` para segmentação de notificações

2. **EmergencyService** (linha 200)
   - Chama `get_nearby_drivers` para emergências

## Verificação Pós-Correção

1. Execute o script no Supabase
2. Faça hot reload do aplicativo Flutter
3. Teste funcionalidades que envolvem busca de motoristas próximos
4. Verifique os logs do Flutter para confirmar que não há mais erros 42P01

## Prevenção

Para evitar problemas similares no futuro:

1. Sempre use JOINs explícitos quando precisar de dados de múltiplas tabelas
2. Teste funções SQL antes de usar em produção
3. Documente o schema das funções SQL
4. Use ferramentas de migração para mudanças no banco de dados

## Status

- [x] Problema identificado
- [ ] Script executado no Supabase
- [ ] Funções testadas
- [ ] Aplicativo testado
- [ ] Logs verificados