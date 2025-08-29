# Análise do Fluxo de Seleção de Motorista

## Resumo Executivo

Este documento mapeia o fluxo completo de seleção de motorista na aplicação atual e identifica discrepâncias críticas em relação ao fluxo de negócio documentado em `Fluxo do negocio.md`.

## Fluxo Atual Implementado

### 1. Tela de Seleção de Motorista (`driver_selection_screen.dart`)

**Entrada:**
- `origin`: Endereço de origem
- `destination`: Endereço de destino  
- `category`: Categoria do veículo
- `needsPet`: Aceita animais
- `needsGrocery`: Aceita compras
- `needsCondo`: Aceita condomínio

**Processo:**
1. Chama `DriverService.getAvailableDriversNearby()` com filtros
2. Exibe lista de motoristas disponíveis
3. Usuário seleciona um motorista
4. Calcula rota usando `LocationService.getDrivingRoute()`
5. Calcula preço usando `VehicleCategoryData.calculateEstimatedPrice()`
6. Cria `TripRequest` via `TripService.createTripRequest()`
7. Navega para `WaitingDriverScreen`

### 2. Serviço de Busca de Motoristas (`driver_service.dart`)

**Método:** `getAvailableDriversNearby()`

**Filtros Aplicados:**
- Localização (bounding box de ±0.01 graus)
- Status online (`is_online = true`)
- Categoria do veículo
- Necessidades específicas (pet, grocery, condo)
- Status de aprovação (`approval_status = 'approved'`)
- Zonas excluídas pelo motorista

**Ordenação:** Por rating médio (descendente)
**Limite:** 20 motoristas

### 3. Cálculo de Preço

**Fórmula Atual:**
```dart
(basePricePerKm * distanceKm) + (basePricePerMinute * durationMinutes) * surgeMultiplier
```

**Problema:** Usa preço base da categoria, não preços individuais dos motoristas.

### 4. Criação da Solicitação (`trip_service.dart`)

**Método:** `createTripRequest()`

**Campos do TripRequest:**
- `passenger_id`
- `origin_address` / `destination_address`
- `origin_lat` / `origin_lng` / `destination_lat` / `destination_lng`
- `vehicle_category_id`
- `needs_pet` / `needs_grocery` / `needs_condo`
- `estimated_distance_km` / `estimated_duration_minutes`
- `estimated_fare`
- `status: 'pending'`

**Problema:** Não especifica motorista destinatário.

### 5. Tela de Espera (`waiting_driver_screen.dart`)

**Processo:**
1. Recebe `tripRequestId`
2. Subscreve a atualizações do `TripRequest`
3. Aguarda mudança de status para `accepted`
4. Navega para `PassengerTripScreen` quando aceito

### 6. Interface do Motorista (LACUNA CRÍTICA)

**Problema:** Não existe interface para motoristas visualizarem solicitações pendentes.

**Arquivos Analisados:**
- `driver_home_screen.dart`: Apenas monitora viagens ativas
- `driver_trip_screen.dart`: Apenas gerencia viagens em andamento

## Fluxo Esperado (Segundo Documentação)

### 1. Seleção de Motorista
- ✅ Passageiro define origem/destino
- ✅ Seleciona categoria e preferências
- ❌ **Sistema deve exibir 10 motoristas mais próximos** (atual: até 20, ordenados por rating)
- ❌ **Cada motorista deve ter preço individual** (atual: preço calculado apenas após seleção)

### 2. Solicitação Direcionada
- ❌ **Passageiro escolhe motorista específico** (atual: funciona)
- ❌ **Sistema envia solicitação EXCLUSIVA ao motorista escolhido** (atual: solicitação genérica)
- ❌ **Motorista tem 10 segundos para aceitar/recusar** (atual: não implementado)

### 3. Sistema de Fallback
- ❌ **Se motorista recusar ou timeout, vai para próximo da lista** (atual: não implementado)
- ❌ **Processo continua até encontrar motorista ou esgotar lista** (atual: não implementado)

## Discrepâncias Identificadas

### 🔴 CRÍTICAS

1. **Ausência de Interface para Motoristas Receberem Solicitações**
   - Motoristas não conseguem ver solicitações pendentes
   - Não há sistema de notificações push
   - Não há interface para aceitar/recusar solicitações

2. **Fluxo de Solicitação Genérica vs. Direcionada**
   - Atual: TripRequest genérico que qualquer motorista pode aceitar
   - Esperado: Solicitação específica ao motorista escolhido

3. **Ausência de Sistema de Timeout e Fallback**
   - Não há timer de 10 segundos
   - Não há fallback automático para próximo motorista

### 🟡 IMPORTANTES

4. **Algoritmo de Seleção de Motoristas**
   - Atual: Bounding box + ordenação por rating + limite 20
   - Esperado: 10 motoristas mais próximos por distância real

5. **Cálculo de Preços Individuais**
   - Atual: Preço calculado após seleção usando preço base da categoria
   - Esperado: Preço individual para cada motorista na lista
   - Nota: Campos `custom_price_per_km` e `custom_price_per_minute` existem na tabela `drivers` mas não são utilizados

## Arquivos Principais Envolvidos

### Frontend
- `/lib/screens/trip/driver_selection_screen.dart` - Tela de seleção
- `/lib/screens/trip/waiting_driver_screen.dart` - Tela de espera
- `/lib/screens/passenger/passenger_trip_screen.dart` - Viagem do passageiro
- `/lib/screens/driver/driver_home_screen.dart` - Home do motorista (sem solicitações)
- `/lib/screens/driver/driver_trip_screen.dart` - Viagem do motorista

### Serviços
- `/lib/services/driver_service.dart` - Busca de motoristas
- `/lib/services/trip_service.dart` - Gerenciamento de viagens
- `/lib/services/location_service.dart` - Cálculo de rotas

### Modelos
- `/lib/models/trip_request.dart` - Modelo de solicitação
- `/lib/models/vehicle_category.dart` - Cálculo de preços

## Recomendações de Implementação

### 1. Implementar Interface de Solicitações para Motoristas
```dart
// Nova tela: driver_requests_screen.dart
// Funcionalidades:
// - Listar solicitações direcionadas ao motorista
// - Timer de 10 segundos
// - Botões aceitar/recusar
// - Notificações push
```

### 2. Modificar Modelo TripRequest
```dart
// Adicionar campos:
// - target_driver_id (motorista específico)
// - expires_at (timestamp de expiração)
// - fallback_drivers (lista de motoristas alternativos)
```

### 3. Implementar Sistema de Fallback
```dart
// Novo serviço: trip_request_manager.dart
// Funcionalidades:
// - Enviar solicitação para motorista específico
// - Monitorar timeout de 10 segundos
// - Fallback automático para próximo motorista
// - Notificações push
```

### 4. Corrigir Algoritmo de Seleção
```dart
// Modificar DriverService.getAvailableDriversNearby():
// - Calcular distância real para cada motorista
// - Ordenar por proximidade
// - Limitar a 10 motoristas
// - Calcular preço individual para cada um
```

### 5. Implementar Cálculo de Preços Individuais
```dart
// Usar campos custom_price_per_km e custom_price_per_minute
// Calcular preço para cada motorista na lista
// Exibir preços individuais na tela de seleção
```

## Conclusão

A implementação atual funciona como um sistema de "primeiro que aceita", onde qualquer motorista pode aceitar uma solicitação genérica. O fluxo de negócio documentado requer um sistema de "seleção direcionada" com fallback automático, representando uma diferença arquitetural significativa que afeta toda a experiência do usuário.

As principais lacunas estão na ausência de:
1. Interface para motoristas receberem solicitações
2. Sistema de timeout e fallback
3. Solicitações direcionadas a motoristas específicos
4. Cálculo de preços individuais
5. Algoritmo de proximidade real

Essas discrepâncias precisam ser endereçadas para alinhar a implementação com o fluxo de negócio documentado.