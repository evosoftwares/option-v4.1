# 🧪 Guia Técnico: Testes de Validação do Sistema Option

## 📋 Contexto Técnico

Este documento fornece scripts e procedimentos específicos para validar a implementação dos sistemas críticos do Option, baseado na estrutura de dados completa identificada no schema Supabase.

---

## 🎯 1. Testes de Sistema de Matching Direcionado

### **1.1. Script SQL de Validação da Estrutura**

```sql
-- Verificar se todos os campos críticos existem e têm valores padrão corretos
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'trip_requests' 
  AND column_name IN (
    'target_driver_id',
    'expires_at', 
    'fallback_drivers',
    'accepted_by_driver_id',
    'current_fallback_index',
    'timeout_count'
  )
ORDER BY column_name;

-- Resultado Esperado:
-- expires_at deve ter default: (now() + '00:00:10'::interval)
-- current_fallback_index deve ter default: 0  
-- timeout_count deve ter default: 0
```

### **1.2. Teste de Criação de Trip Request Direcionado**

```sql
-- Teste 1: Criar trip request com motorista específico
INSERT INTO trip_requests (
  passenger_id,
  target_driver_id,
  fallback_drivers,
  origin_address,
  origin_latitude,
  origin_longitude,
  destination_address,
  destination_latitude,
  destination_longitude,
  vehicle_category,
  estimated_distance_km,
  estimated_duration_minutes,
  estimated_fare
) VALUES (
  '550e8400-e29b-41d4-a716-446655440001', -- passenger_id
  '550e8400-e29b-41d4-a716-446655440002', -- target_driver_id
  ARRAY['550e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440004'], -- fallbacks
  'Rua A, 123',
  -23.5505,
  -46.6333,
  'Rua B, 456', 
  -23.5506,
  -46.6334,
  'Carro Comum',
  5.2,
  15,
  25.50
);

-- Verificar se foi criado corretamente
SELECT 
  id,
  target_driver_id,
  expires_at,
  fallback_drivers,
  current_fallback_index,
  timeout_count,
  (expires_at - created_at) as timeout_interval
FROM trip_requests 
WHERE passenger_id = '550e8400-e29b-41d4-a716-446655440001'
ORDER BY created_at DESC 
LIMIT 1;

-- Validações:
-- timeout_interval deve ser aproximadamente 10 segundos
-- fallback_drivers deve conter array com 2 UUIDs
-- current_fallback_index deve ser 0
```

### **1.3. Simulação de Timeout e Fallback**

```sql
-- Simular timeout (em ambiente de teste)
UPDATE trip_requests 
SET 
  expires_at = NOW() - INTERVAL '1 second',
  timeout_count = timeout_count + 1,
  current_fallback_index = current_fallback_index + 1
WHERE id = 'ID_DO_TRIP_REQUEST_TESTE';

-- Verificar estado após timeout
SELECT 
  target_driver_id,
  fallback_drivers[current_fallback_index + 1] as next_target,
  current_fallback_index,
  timeout_count,
  status
FROM trip_requests 
WHERE id = 'ID_DO_TRIP_REQUEST_TESTE';
```

---

## 💰 2. Testes de Sistema de Precificação

### **2.1. Validação da Estrutura de Precificação**

```sql
-- Verificar configurações globais
SELECT 
  category,
  base_price_per_km,
  base_price_per_minute,
  platform_commission_percent
FROM platform_settings;

-- Verificar drivers com preços customizados
SELECT 
  d.id,
  u.full_name,
  d.custom_price_per_km,
  d.custom_price_per_minute,
  d.pet_fee,
  d.grocery_fee,
  d.condo_fee,
  d.stop_fee
FROM drivers d
JOIN app_users u ON d.user_id = u.id
WHERE d.custom_price_per_km IS NOT NULL 
   OR d.custom_price_per_minute IS NOT NULL
LIMIT 5;
```

### **2.2. Teste de Cálculo de Precificação Diferencial**

```sql
-- Criar cenário de teste com 2 motoristas
INSERT INTO driver_offers (request_id, driver_id, driver_distance_km, driver_eta_minutes, base_fare, additional_fees, total_fare, distance_component, time_component)
SELECT 
  'REQUEST_ID_TESTE',
  d.id,
  2.5, -- distancia do motorista
  8,   -- tempo para chegar
  -- Cálculo base_fare
  ((COALESCE(d.custom_price_per_km, ps.base_price_per_km) * 10.0) + -- 10km viagem
   (COALESCE(d.custom_price_per_minute, ps.base_price_per_minute) * 25.0) + -- 25min viagem  
   (COALESCE(d.custom_price_per_km, ps.base_price_per_km) * 2.5) + -- motorista até passageiro
   (COALESCE(d.custom_price_per_minute, ps.base_price_per_minute) * 8.0)) as base_fare, -- tempo motorista até passageiro
  (CASE WHEN 'true'::boolean THEN COALESCE(d.pet_fee, 0) ELSE 0 END) as additional_fees, -- com pet
  -- total_fare = base_fare + additional_fees
  ((COALESCE(d.custom_price_per_km, ps.base_price_per_km) * 12.5) + 
   (COALESCE(d.custom_price_per_minute, ps.base_price_per_minute) * 33.0) +
   (CASE WHEN 'true'::boolean THEN COALESCE(d.pet_fee, 0) ELSE 0 END)) as total_fare,
  -- distance_component
  (COALESCE(d.custom_price_per_km, ps.base_price_per_km) * 12.5) as distance_component,
  -- time_component  
  (COALESCE(d.custom_price_per_minute, ps.base_price_per_minute) * 33.0) as time_component
FROM drivers d
CROSS JOIN platform_settings ps
WHERE d.approval_status = 'approved' 
  AND ps.category = 'Carro Comum'
LIMIT 2;

-- Verificar resultados
SELECT 
  do.driver_id,
  u.full_name,
  d.custom_price_per_km,
  ps.base_price_per_km,
  do.distance_component,
  do.time_component, 
  do.additional_fees,
  do.total_fare
FROM driver_offers do
JOIN drivers d ON do.driver_id = d.id
JOIN app_users u ON d.user_id = u.id
CROSS JOIN platform_settings ps
WHERE do.request_id = 'REQUEST_ID_TESTE'
ORDER BY do.total_fare;
```

### **2.3. Validação da Fórmula de Precificação**

```sql
-- Função para validar cálculo manual vs automático
WITH calculation_test AS (
  SELECT 
    do.*,
    d.custom_price_per_km,
    d.custom_price_per_minute,
    ps.base_price_per_km,
    ps.base_price_per_minute,
    -- Cálculo manual para comparação
    (COALESCE(d.custom_price_per_km, ps.base_price_per_km) * 12.5) as manual_distance,
    (COALESCE(d.custom_price_per_minute, ps.base_price_per_minute) * 33.0) as manual_time,
    d.pet_fee as manual_additional
  FROM driver_offers do
  JOIN drivers d ON do.driver_id = d.id  
  CROSS JOIN platform_settings ps
  WHERE do.request_id = 'REQUEST_ID_TESTE'
)
SELECT 
  driver_id,
  -- Validações
  distance_component = manual_distance as distance_correct,
  time_component = manual_time as time_correct,
  additional_fees = COALESCE(manual_additional, 0) as fees_correct,
  total_fare = (manual_distance + manual_time + COALESCE(manual_additional, 0)) as total_correct
FROM calculation_test;
```

---

## 🚫 3. Testes de Sistema de Cancelamento

### **3.1. Configuração de Teste de Cancelamento**

```sql
-- Verificar configurações de cancelamento
SELECT 
  min_cancellation_fee,
  cancellation_fee_percent,
  no_show_wait_minutes
FROM platform_settings;

-- Resultado esperado:
-- min_cancellation_fee: 10.00
-- cancellation_fee_percent: 20.00  
-- no_show_wait_minutes: 3
```

### **3.2. Teste de Cálculo de Taxa de Cancelamento**

```sql
-- Criar cenário de teste
INSERT INTO trips (
  trip_code,
  passenger_id,
  driver_id,
  status,
  origin_address,
  origin_latitude,
  origin_longitude,
  destination_address,
  destination_latitude, 
  destination_longitude,
  vehicle_category,
  estimated_distance_km,
  estimated_duration_minutes,
  total_fare,
  driver_to_pickup_distance_km,
  driver_assigned_at
) VALUES (
  'TEST001',
  '550e8400-e29b-41d4-a716-446655440001',
  '550e8400-e29b-41d4-a716-446655440002', 
  'driver_assigned',
  'Origem Teste',
  -23.5505,
  -46.6333,
  'Destino Teste',
  -23.5506,
  -46.6334,
  'Carro Comum',
  8.0,
  20,
  30.00,
  5.0, -- motorista precisa percorrer 5km
  NOW() - INTERVAL '2 minutes' -- motorista foi designado há 2 minutos
);

-- Simular cancelamento pelo passageiro (motorista já percorreu 2km de 5km)
WITH cancellation_calc AS (
  SELECT 
    t.id,
    t.total_fare,
    ps.cancellation_fee_percent,
    ps.min_cancellation_fee,
    -- MultaBase = MIN(total_fare * 0.20, 10.00)
    LEAST(t.total_fare * (ps.cancellation_fee_percent / 100), ps.min_cancellation_fee) as multa_base,
    -- FatorDeslocamento (simulado: motorista percorreu 2km de 5km = 0.4)
    0.4 as fator_deslocamento
  FROM trips t
  CROSS JOIN platform_settings ps
  WHERE t.trip_code = 'TEST001'
)
SELECT 
  id,
  total_fare,
  multa_base,
  fator_deslocamento,
  -- Taxa final = MultaBase * FatorDeslocamento
  (multa_base * fator_deslocamento) as taxa_cancelamento_calculada
FROM cancellation_calc;

-- Aplicar cancelamento
UPDATE trips 
SET 
  status = 'cancelled',
  cancelled_by = 'passenger',
  cancellation_reason = 'Cancelamento pelo passageiro',
  cancelled_at = NOW(),
  -- Aplicar taxa calculada (exemplo com FatorDeslocamento = 0.4)
  cancellation_fee = (
    SELECT LEAST(total_fare * 0.20, 10.00) * 0.4 
    FROM platform_settings 
    LIMIT 1
  )
WHERE trip_code = 'TEST001';
```

### **3.3. Teste de Sistema de Strikes**

```sql
-- Simular 3 cancelamentos consecutivos
UPDATE passengers 
SET consecutive_cancellations = 3
WHERE user_id = '550e8400-e29b-41d4-a716-446655440001';

-- Verificar se atingiu limite para suspensão
SELECT 
  p.user_id,
  u.full_name,
  p.consecutive_cancellations,
  CASE 
    WHEN p.consecutive_cancellations >= 3 THEN 'SUSPENSO'
    ELSE 'ATIVO'
  END as status_calculado,
  u.status as status_atual
FROM passengers p
JOIN app_users u ON p.user_id = u.id
WHERE p.user_id = '550e8400-e29b-41d4-a716-446655440001';

-- Reset após viagem completada (teste de reset de strikes)  
UPDATE passengers 
SET consecutive_cancellations = 0
WHERE user_id = '550e8400-e29b-41d4-a716-446655440001';
```

---

## 📱 4. Testes de Sistemas de Comunicação

### **4.1. Teste de Chat por Viagem**

```sql
-- Criar mensagens de teste
INSERT INTO trip_chats (trip_id, sender_id, message) VALUES
('TRIP_ID_TESTE', '550e8400-e29b-41d4-a716-446655440001', 'Olá, estou chegando!'),
('TRIP_ID_TESTE', '550e8400-e29b-41d4-a716-446655440002', 'Ok, estou aguardando na entrada.');

-- Verificar estrutura do chat
SELECT 
  tc.id,
  tc.sender_id,
  CASE 
    WHEN tc.sender_id = t.passenger_id THEN 'Passageiro'
    WHEN tc.sender_id = t.driver_id THEN 'Motorista' 
  END as sender_type,
  tc.message,
  tc.is_read,
  tc.created_at
FROM trip_chats tc
JOIN trips t ON tc.trip_id = t.id
WHERE tc.trip_id = 'TRIP_ID_TESTE'
ORDER BY tc.created_at;

-- Teste de marcação como lida
UPDATE trip_chats 
SET 
  is_read = true,
  read_at = NOW()
WHERE trip_id = 'TRIP_ID_TESTE' 
  AND sender_id != '550e8400-e29b-41d4-a716-446655440001'; -- marcar mensagens do outro como lidas
```

---

## ⭐ 5. Testes de Sistema de Avaliações

### **5.1. Teste de Avaliação Bidirecional**

```sql
-- Criar avaliação completa
INSERT INTO ratings (
  trip_id,
  passenger_rating,
  passenger_rating_tags,
  passenger_rating_comment,
  passenger_rated_at,
  driver_rating,  
  driver_rating_tags,
  driver_rating_comment,
  driver_rated_at
) VALUES (
  'TRIP_ID_TESTE',
  5, -- passageiro dá 5 estrelas para o motorista
  ARRAY['Pontual', 'Educado', 'Veículo Limpo'],
  'Excelente motorista!',
  NOW(),
  4, -- motorista dá 4 estrelas para o passageiro  
  ARRAY['Educado', 'Pontual'],
  'Passageiro cordial',
  NOW()
);

-- Verificar estrutura de avaliação
SELECT 
  trip_id,
  passenger_rating,
  array_to_string(passenger_rating_tags, ', ') as passenger_tags,
  passenger_rating_comment,
  driver_rating,
  array_to_string(driver_rating_tags, ', ') as driver_tags, 
  driver_rating_comment,
  CASE 
    WHEN passenger_rated_at IS NOT NULL AND driver_rated_at IS NOT NULL 
    THEN 'Avaliação Completa'
    ELSE 'Avaliação Parcial'
  END as status_avaliacao
FROM ratings 
WHERE trip_id = 'TRIP_ID_TESTE';
```

---

## 📊 6. Script de Validação Completa

### **6.1. Checklist Automatizado**

```sql
-- Script master de validação de estrutura
WITH validation_results AS (
  SELECT 'Matching: target_driver_id' as test_name,
         CASE WHEN COUNT(*) > 0 THEN '✅ PASS' ELSE '❌ FAIL' END as result
  FROM information_schema.columns 
  WHERE table_name = 'trip_requests' AND column_name = 'target_driver_id'
  
  UNION ALL
  
  SELECT 'Matching: expires_at default',
         CASE WHEN column_default LIKE '%00:00:10%' THEN '✅ PASS' ELSE '❌ FAIL' END
  FROM information_schema.columns 
  WHERE table_name = 'trip_requests' AND column_name = 'expires_at'
  
  UNION ALL
  
  SELECT 'Pricing: custom_price_per_km',
         CASE WHEN COUNT(*) > 0 THEN '✅ PASS' ELSE '❌ FAIL' END
  FROM information_schema.columns 
  WHERE table_name = 'drivers' AND column_name = 'custom_price_per_km'
  
  UNION ALL
  
  SELECT 'Cancellation: fee fields',
         CASE WHEN COUNT(*) >= 3 THEN '✅ PASS' ELSE '❌ FAIL' END
  FROM information_schema.columns 
  WHERE table_name = 'trips' 
    AND column_name IN ('cancellation_fee', 'cancelled_by', 'cancelled_at')
    
  UNION ALL
  
  SELECT 'Chat: trip_chats table',
         CASE WHEN COUNT(*) > 0 THEN '✅ PASS' ELSE '❌ FAIL' END
  FROM information_schema.tables 
  WHERE table_name = 'trip_chats'
  
  UNION ALL
  
  SELECT 'Rating: bidirectional fields',
         CASE WHEN COUNT(*) >= 2 THEN '✅ PASS' ELSE '❌ FAIL' END  
  FROM information_schema.columns 
  WHERE table_name = 'ratings' 
    AND column_name IN ('passenger_rating', 'driver_rating')
)
SELECT test_name, result FROM validation_results ORDER BY test_name;
```

---

## 🎯 Resumo de Execução

### **Ordem de Execução Recomendada:**
1. **Validação de Estrutura** (Scripts 6.1): Confirmar que todos os campos existem
2. **Teste de Matching** (Scripts 1.1-1.3): Validar criação e fallback  
3. **Teste de Precificação** (Scripts 2.1-2.3): Validar cálculos personalizados
4. **Teste de Cancelamento** (Scripts 3.1-3.3): Validar taxas e strikes
5. **Teste de Comunicação** (Scripts 4.1): Validar chat por viagem
6. **Teste de Avaliações** (Scripts 5.1): Validar avaliações bidirecionais

### **Critérios de Sucesso:**
- [ ] Todos os scripts executam sem erro
- [ ] Resultados matemáticos conferem com especificações  
- [ ] Transições de estado funcionam corretamente
- [ ] Performance adequada (< 2s para queries críticas)

---

**Data:** Janeiro 2025  
**Versão:** 1.0  
**Pré-requisito:** Acesso ao banco Supabase de desenvolvimento/teste