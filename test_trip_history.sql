-- Script para inserir dados de teste na tabela trips
-- Primeiro, vamos inserir alguns usuários de teste se não existirem

-- Inserir passageiro de teste
INSERT INTO app_users (id, email, full_name, phone, user_type, status) 
VALUES (
  '123e4567-e89b-12d3-a456-426614174001', 
  'passenger@test.com', 
  'João Silva', 
  '11999999991', 
  'passenger', 
  'active'
) ON CONFLICT (id) DO NOTHING;

-- Inserir motorista de teste  
INSERT INTO app_users (id, email, full_name, phone, user_type, status)
VALUES (
  '123e4567-e89b-12d3-a456-426614174002',
  'driver@test.com',
  'Maria Santos',
  '11999999992', 
  'driver',
  'active'
) ON CONFLICT (id) DO NOTHING;

-- Inserir passageiro na tabela passengers
INSERT INTO passengers (id, user_id, consecutive_cancellations, total_trips)
VALUES (
  '223e4567-e89b-12d3-a456-426614174001',
  '123e4567-e89b-12d3-a456-426614174001',
  0,
  0
) ON CONFLICT (id) DO NOTHING;

-- Inserir motorista na tabela drivers
INSERT INTO drivers (
  id, user_id, cnh_number, cnh_expiry_date, cnh_photo_url, 
  vehicle_brand, vehicle_model, vehicle_year, vehicle_color, 
  vehicle_plate, vehicle_category, crlv_photo_url, approval_status,
  is_online, total_trips
) VALUES (
  '323e4567-e89b-12d3-a456-426614174002',
  '123e4567-e89b-12d3-a456-426614174002', 
  '12345678901',
  '2025-12-31',
  'https://example.com/cnh.jpg',
  'Toyota',
  'Corolla',
  2020,
  'Branco',
  'ABC-1234',
  'sedan',
  'https://example.com/crlv.jpg',
  'approved',
  true,
  0
) ON CONFLICT (id) DO NOTHING;

-- Inserir algumas viagens de teste
INSERT INTO trips (
  id, trip_code, passenger_id, driver_id, status,
  origin_address, origin_latitude, origin_longitude,
  destination_address, destination_latitude, destination_longitude,
  vehicle_category, base_fare, additional_fees, 
  requested_at, completed_at, payment_status,
  actual_distance_km, created_at
) VALUES
(
  '423e4567-e89b-12d3-a456-426614174001',
  'TRIP001',
  '223e4567-e89b-12d3-a456-426614174001',
  '323e4567-e89b-12d3-a456-426614174002',
  'completed',
  'Rua A, 123 - Centro, São Paulo - SP',
  -23.5505,
  -46.6333,
  'Rua B, 456 - Vila Madalena, São Paulo - SP', 
  -23.5449,
  -46.6868,
  'sedan',
  25.50,
  2.00,
  NOW() - INTERVAL '2 days',
  NOW() - INTERVAL '2 days' + INTERVAL '25 minutes',
  'paid',
  8.5,
  NOW() - INTERVAL '2 days'
),
(
  '423e4567-e89b-12d3-a456-426614174002',
  'TRIP002', 
  '223e4567-e89b-12d3-a456-426614174001',
  '323e4567-e89b-12d3-a456-426614174002',
  'completed',
  'Av. Paulista, 1000 - Bela Vista, São Paulo - SP',
  -23.5614,
  -46.6565,
  'Shopping Ibirapuera, São Paulo - SP',
  -23.5875,
  -46.6530,
  'sedan', 
  18.00,
  0.00,
  NOW() - INTERVAL '1 day',
  NOW() - INTERVAL '1 day' + INTERVAL '15 minutes',
  'paid',
  5.2,
  NOW() - INTERVAL '1 day'
),
(
  '423e4567-e89b-12d3-a456-426614174003',
  'TRIP003',
  '223e4567-e89b-12d3-a456-426614174001', 
  '323e4567-e89b-12d3-a456-426614174002',
  'cancelled',
  'Rua C, 789 - Moema, São Paulo - SP',
  -23.6013,
  -46.6590,
  'Aeroporto de Congonhas, São Paulo - SP',
  -23.6266,
  -46.6569,
  'sedan',
  35.00,
  0.00,
  NOW() - INTERVAL '3 hours',
  NULL,
  'pending',
  NULL,
  NOW() - INTERVAL '3 hours'
);

-- Verificar se os dados foram inseridos
SELECT 
  t.id,
  t.trip_code,
  t.status,
  t.origin_address,
  t.destination_address,
  t.base_fare,
  t.additional_fees,
  t.requested_at,
  p_user.full_name as passenger_name,
  d_user.full_name as driver_name
FROM trips t
JOIN passengers p ON t.passenger_id = p.id
JOIN app_users p_user ON p.user_id = p_user.id
JOIN drivers d ON t.driver_id = d.id  
JOIN app_users d_user ON d.user_id = d_user.id
ORDER BY t.created_at DESC;