# Relatório de Discrepâncias - Modelos Flutter vs Schema Supabase

## Resumo Executivo

Este relatório identifica discrepâncias críticas entre os modelos Dart do projeto Flutter e as especificações documentadas no `supabase.md`. Foram encontradas inconsistências significativas em nomes de campos, tipos de dados e campos faltantes que podem causar problemas de sincronização com o banco de dados.

## 🔴 Discrepâncias Críticas Encontradas

### 1. **AppUser Model** vs **app_users Table**

#### ❌ Campos Faltantes no Modelo:
- `email` (text) - Campo obrigatório
- `full_name` (text) - Campo obrigatório  
- `photo_url` (text) - Campo opcional
- `status` (text) - Campo obrigatório

#### ❌ Campos Extras no Modelo (não existem no schema):
- `isActive` (bool) - Não existe na tabela
- `isVerified` (bool) - Não existe na tabela

#### ✅ Campos Corretos:
- `id`, `userId` (user_id), `phone`, `userType` (user_type), `createdAt`, `updatedAt`

---

### 2. **Driver Model** vs **drivers Table**

#### ❌ Campos Faltantes no Modelo:
- `approved_by` (uuid)
- `approved_at` (timestamptz)
- `pet_fee` (numeric) - Agrupado em `fees`
- `grocery_fee` (numeric) - Agrupado em `fees`
- `condo_fee` (numeric) - Agrupado em `fees`
- `stop_fee` (numeric) - Agrupado em `fees`
- `bank_account_type` (text) - Agrupado em `bankData`
- `bank_code` (text) - Agrupado em `bankData`
- `bank_agency` (text) - Agrupado em `bankData`
- `bank_account` (text) - Agrupado em `bankData`
- `pix_key` (text) - Agrupado em `pixData`
- `pix_key_type` (text) - Agrupado em `pixData`
- `last_location_update` (timestamptz)

#### ⚠️ Campos Agrupados (precisam ser desmembrados):
- `fees` → Deveria ser campos individuais: `pet_fee`, `grocery_fee`, `condo_fee`, `stop_fee`
- `bankData` → Deveria ser campos individuais: `bank_account_type`, `bank_code`, `bank_agency`, `bank_account`
- `pixData` → Deveria ser campos individuais: `pix_key`, `pix_key_type`

#### ✅ Campos Corretos:
- Maioria dos campos de veículo e localização estão corretos

---

### 3. **Passenger Model** vs **passengers Table**

#### ❌ Campos Faltantes no Modelo:
- `consecutive_cancellations` (int)
- `payment_method_id` (text)

#### ❌ Nome de Campo Incorreto:
- `rating` → Deveria ser `average_rating`

#### ✅ Campos Corretos:
- `id`, `userId` (user_id), `totalTrips` (total_trips), `createdAt`, `updatedAt`

---

### 4. **Trip Model** vs **trips Table**

#### ❌ Campos Faltantes Críticos no Modelo:
- `trip_code` (text)
- `request_id` (uuid) - Mapeado incorretamente como `tripRequestId`
- `origin_neighborhood` (text)
- `destination_neighborhood` (text)
- `vehicle_category` (text)
- `needs_pet` (boolean)
- `needs_grocery_space` (boolean)
- `is_condo_destination` (boolean)
- `is_condo_origin` (boolean)
- `needs_ac` (boolean)
- `number_of_stops` (int)
- `route_polyline` (text)
- `estimated_distance_km` (numeric)
- `estimated_duration_minutes` (int)
- `driver_to_pickup_distance_km` (numeric)
- `driver_to_pickup_duration_minutes` (int)
- `waiting_time_minutes` (int)
- `driver_distance_traveled_km` (numeric)
- `additional_fees` (numeric)
- `surge_multiplier` (numeric)
- `total_fare` (numeric) - Mapeado incorretamente como `finalFare`
- `platform_commission` (numeric)
- `driver_earnings` (numeric)
- `cancellation_reason` (text)
- `cancellation_fee` (numeric)
- `cancelled_by` (text)
- `driver_assigned_at` (timestamptz)
- `driver_arrived_at` (timestamptz)
- `trip_started_at` (timestamptz) - Mapeado incorretamente como `startTime`
- `trip_completed_at` (timestamptz) - Mapeado incorretamente como `endTime`
- `cancelled_at` (timestamptz)
- `payment_status` (text)
- `payment_id` (text)
- `payment_completed_at` (timestamptz)
- `discount_applied` (numeric)

#### ❌ Campos com Nomes Incorretos:
- `tripRequestId` → Deveria ser `request_id`
- `finalFare` → Deveria ser `total_fare`
- `startTime` → Deveria ser `trip_started_at`
- `endTime` → Deveria ser `trip_completed_at`

---

### 5. **TripRequest Model** vs **trip_requests Table**

#### ❌ Campos Faltantes no Modelo:
- `selected_offer_id` (uuid)
- `expires_at` (timestamptz)

#### ❌ Campos Extras no Modelo (não existem no schema):
- `estimatedDistanceKm` - Não existe na tabela
- `estimatedDurationMinutes` - Não existe na tabela
- `estimatedFare` - Não existe na tabela
- `acceptedAt` - Não existe na tabela
- `acceptedByDriverId` - Não existe na tabela

---

### 6. **FavoriteLocation Model** vs **saved_places Table**

#### ❌ Nome de Campo Incorreto:
- `name` → Deveria ser `label`
- `type` → Deveria ser `category` (varchar)

#### ❌ Campos Extras no Modelo:
- `placeId` - Não existe na tabela

#### ✅ Campos Corretos:
- `id`, `userId` (user_id), `address`, `latitude`, `longitude`, `createdAt`, `updatedAt`

---

## 🟢 Modelos Corretos

### ✅ **PaymentMethod Model** vs **payment_methods Table**
- **Status**: Perfeitamente alinhado
- Todos os campos correspondem exatamente ao schema

### ✅ **PassengerWallet Model** vs **passenger_wallets Table**
- **Status**: Perfeitamente alinhado
- Todos os campos correspondem exatamente ao schema

---

## 📋 Modelos Não Encontrados (Precisam ser Criados)

Os seguintes modelos estão faltando no projeto:

1. **OperationalCity** (operational_cities)
2. **DriverOperationalCity** (driver_operational_cities)
3. **DriverExcludedZone** (driver_excluded_zones) - ✅ Existe
4. **DriverSchedule** (driver_schedules)
5. **PlatformSettings** (platform_settings)
6. **DriverOffer** (driver_offers) - ✅ Existe
7. **TripStop** (trip_stops)
8. **TripLocationHistory** (trip_location_history)
9. **TripStatusHistory** (trip_status_history)
10. **DriverWallet** (driver_wallets)
11. **WalletTransaction** (wallet_transactions)
12. **Withdrawal** (withdrawals)
13. **TripChat** (trip_chats)
14. **Rating** (ratings)
15. **PromoCode** (promo_codes) - ✅ Existe
16. **PromoCodeUsage** (promo_code_usage)
17. **Notification** (notifications)
18. **UserDevice** (user_devices)
19. **DriverDocument** (driver_documents) - ✅ Existe
20. **ActivityLog** (activity_logs)
21. **PassengerPromoCode** (passenger_promo_codes) - ✅ Existe
22. **PassengerWalletTransaction** (passenger_wallet_transactions) - ✅ Existe
23. **PassengerPromoCodeUsage** (passenger_promo_code_usage)
24. **DriverOperationZone** (driver_operation_zones) - ✅ Existe

---

## 🔧 Recomendações de Correção

### Prioridade Alta:
1. **Corrigir modelo AppUser** - Adicionar campos obrigatórios faltantes
2. **Reestruturar modelo Driver** - Desmembrar objetos agrupados em campos individuais
3. **Corrigir modelo Trip** - Adicionar todos os campos faltantes críticos
4. **Corrigir modelo Passenger** - Adicionar campos faltantes e corrigir nomes

### Prioridade Média:
5. **Corrigir modelo TripRequest** - Remover campos extras e adicionar faltantes
6. **Corrigir modelo FavoriteLocation** - Alinhar nomes de campos

### Prioridade Baixa:
7. **Criar modelos faltantes** - Para funcionalidades futuras

---

## 💡 Próximos Passos

1. **Backup dos modelos atuais** antes de fazer alterações
2. **Implementar correções por prioridade** começando pelos modelos críticos
3. **Testar integração** com Supabase após cada correção
4. **Atualizar validações** nos formulários conforme necessário
5. **Documentar mudanças** para a equipe de desenvolvimento

---

*Relatório gerado em: " + DateTime.now().toString() + "*
*Versão do Schema: supabase.md*