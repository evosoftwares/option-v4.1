# Documentação do TripService

## Visão Geral
O `TripService` é um serviço Flutter que gerencia operações relacionadas a viagens e solicitações de viagem usando Supabase como backend. Ele fornece métodos para criar, buscar e gerenciar solicitações de viagem e viagens ativas.

## Arquitetura

### Dependências
- `supabase_flutter`: Cliente Supabase para Flutter
- `PostgrestErrorMapper`: Mapeador de erros do PostgREST
- `ErrorLoggingService`: Serviço de registro de erros
- Modelos: `Trip`, `TripRequest`, `Location`

### Estrutura de Classes

```dart
class TripService {
  final SupabaseClient _supabase;
  
  // Métodos de Trip Request
  - createTripRequest()
  - getTripRequests()
  - getTripRequest()
  
  // Métodos de Trip
  - createTrip()
  - getTrip()
  - getTrips()
  - updateTripStatus()
  - updateTripDriver()
  - addTripLocation()
  - getTripLocations()
  - getActiveTripByDriver()
  - getActiveTripByPassenger()
  - getTripRequestsForDriver()
  - acceptTripRequest()
  - startTrip()
  - completeTrip()
  - cancelTrip()
  - getTripHistory()
}
```

## Métodos Detalhados

### 1. createTripRequest()
Cria uma nova solicitação de viagem para passageiros.

**Parâmetros:**
- `passengerId` (String): ID do passageiro
- `originAddress` (String): Endereço de origem
- `originLatitude` (double): Latitude da origem
- `originLongitude` (double): Longitude da origem
- `destinationAddress` (String): Endereço de destino
- `destinationLatitude` (double): Latitude do destino
- `destinationLongitude` (double): Longitude do destino
- `vehicleCategory` (String): Categoria do veículo desejado
- `needsPet` (bool): Se precisa de espaço para pets
- `needsGrocerySpace` (bool): Se precisa de espaço para compras
- `isCondoDestination` (bool): Se o destino é um condomínio
- `isCondoOrigin` (bool): Se a origem é um condomínio
- `needsAc` (bool): Se precisa de ar condicionado
- `numberOfStops` (int): Número de paradas adicionais
- `estimatedDistanceKm` (double): Distância estimada em km
- `estimatedDurationMinutes` (int): Duração estimada em minutos
- `estimatedFare` (double): Tarifa estimada
- `originNeighborhood` (String?, opcional): Bairro de origem
- `destinationNeighborhood` (String?, opcional): Bairro de destino

**Retorno:** `Future<TripRequest>`

**Exemplo de uso:**
```dart
final tripRequest = await tripService.createTripRequest(
  passengerId: 'user-123',
  originAddress: 'Rua Principal, 123',
  originLatitude: -23.5505,
  originLongitude: -46.6333,
  destinationAddress: 'Avenida Secundária, 456',
  destinationLatitude: -23.5605,
  destinationLongitude: -46.6433,
  vehicleCategory: 'standard',
  needsPet: false,
  needsGrocerySpace: true,
  isCondoDestination: true,
  isCondoOrigin: false,
  needsAc: true,
  numberOfStops: 0,
  estimatedDistanceKm: 5.2,
  estimatedDurationMinutes: 25,
  estimatedFare: 25.50,
);
```

### 2. getTripRequests()
Busca solicitações de viagem com filtros opcionais.

**Parâmetros:**
- `passengerId` (String?, opcional): Filtrar por ID do passageiro
- `status` (String?, opcional): Filtrar por status ('pending', 'accepted', 'completed', 'cancelled')
- `limit` (int?, opcional): Limitar número de resultados

**Retorno:** `Future<List<TripRequest>>`

### 3. getTripRequest()
Busca uma solicitação específica por ID.

**Parâmetros:**
- `id` (String): ID da solicitação

**Retorno:** `Future<TripRequest?>` - Retorna null se não encontrado

### 4. createTrip()
Cria uma nova viagem a partir de uma solicitação aceita.

**Parâmetros:**
- `tripRequestId` (String): ID da solicitação de viagem
- `driverId` (String): ID do motorista
- `vehicleId` (String): ID do veículo

**Retorno:** `Future<Trip>`

### 5. getTrip()
Busca detalhes de uma viagem específica.

**Parâmetros:**
- `id` (String): ID da viagem

**Retorno:** `Future<Trip?>`

### 6. updateTripStatus()
Atualiza o status de uma viagem.

**Parâmetros:**
- `tripId` (String): ID da viagem
- `status` (String): Novo status ('accepted', 'in_progress', 'completed', 'cancelled')

**Retorno:** `Future<void>`

### 7. updateTripDriver()
Atualiza o motorista de uma viagem.

**Parâmetros:**
- `tripId` (String): ID da viagem
- `driverId` (String): ID do novo motorista

**Retorno:** `Future<void>`

### 8. addTripLocation()
Adiciona um ponto de localização durante a viagem.

**Parâmetros:**
- `tripId` (String): ID da viagem
- `latitude` (double): Latitude do ponto
- `longitude` (double): Longitude do ponto
- `address` (String): Endereço do ponto
- `timestamp` (DateTime): Timestamp do registro

**Retorno:** `Future<void>`

### 9. getTripLocations()
Busca todos os pontos de localização de uma viagem.

**Parâmetros:**
- `tripId` (String): ID da viagem

**Retorno:** `Future<List<Location>>`

### 10. getActiveTripByDriver()
Busca a viagem ativa de um motorista.

**Parâmetros:**
- `driverId` (String): ID do motorista

**Retorno:** `Future<Trip?>` - Retorna null se não houver viagem ativa

### 11. getActiveTripByPassenger()
Busca a viagem ativa de um passageiro.

**Parâmetros:**
- `passengerId` (String): ID do passageiro

**Retorno:** `Future<Trip?>` - Retorna null se não houver viagem ativa

### 12. getTripRequestsForDriver()
Busca solicitações de viagem disponíveis para um motorista baseado em critérios.

**Parâmetros:**
- `driverId` (String): ID do motorista
- `vehicleCategory` (String): Categoria do veículo do motorista
- `latitude` (double): Latitude atual do motorista
- `longitude` (double): Longitude atual do motorista
- `radiusKm` (double): Raio de busca em km

**Retorno:** `Future<List<TripRequest>>`

### 13. acceptTripRequest()
Aceita uma solicitação de viagem e cria a viagem.

**Parâmetros:**
- `tripRequestId` (String): ID da solicitação
- `driverId` (String): ID do motorista
- `vehicleId` (String): ID do veículo

**Retorno:** `Future<Trip>`

### 14. startTrip()
Inicia uma viagem aceita.

**Parâmetros:**
- `tripId` (String): ID da viagem

**Retorno:** `Future<void>`

### 15. completeTrip()
Completa uma viagem em andamento.

**Parâmetros:**
- `tripId` (String): ID da viagem
- `finalFare` (double): Tarifa final da viagem

**Retorno:** `Future<void>`

### 16. cancelTrip()
Cancela uma viagem.

**Parâmetros:**
- `tripId` (String): ID da viagem
- `reason` (String): Motivo do cancelamento
- `cancelledBy` (String): Quem cancelou ('driver' ou 'passenger')

**Retorno:** `Future<void>`

### 17. getTripHistory()
Busca histórico de viagens de um usuário.

**Parâmetros:**
- `userId` (String): ID do usuário
- `limit` (int?, opcional): Número máximo de resultados
- `offset` (int?, opcional): Pular primeiros N resultados

**Retorno:** `Future<List<Trip>>`

## Tratamento de Erros

O serviço implementa tratamento de erros robusto através de:

1. **PostgrestErrorMapper**: Mapeia erros do Supabase para exceções específicas
2. **ErrorLoggingService**: Registra erros para monitoramento
3. **Exceções customizadas**: 
   - `DatabaseException`: Erros de banco de dados
   - `ValidationException`: Erros de validação
   - `AuthenticationException`: Erros de autenticação
   - `NetworkException`: Erros de rede

## Exemplos de Uso

### Criar e aceitar uma viagem completa

```dart
// 1. Passageiro cria solicitação
final request = await tripService.createTripRequest(
  passengerId: 'passenger-123',
  originAddress: 'Rua A, 123',
  originLatitude: -23.5505,
  originLongitude: -46.6333,
  destinationAddress: 'Rua B, 456',
  destinationLatitude: -23.5605,
  destinationLongitude: -46.6433,
  vehicleCategory: 'standard',
  needsPet: false,
  needsGrocerySpace: false,
  isCondoDestination: false,
  isCondoOrigin: false,
  needsAc: true,
  numberOfStops: 0,
  estimatedDistanceKm: 3.5,
  estimatedDurationMinutes: 15,
  estimatedFare: 18.50,
);

// 2. Motorista busca solicitações próximas
final nearbyRequests = await tripService.getTripRequestsForDriver(
  driverId: 'driver-456',
  vehicleCategory: 'standard',
  latitude: -23.5500,
  longitude: -46.6330,
  radiusKm: 5.0,
);

// 3. Motorista aceita solicitação
final trip = await tripService.acceptTripRequest(
  tripRequestId: request.id,
  driverId: 'driver-456',
  vehicleId: 'vehicle-789',
);

// 4. Motorista inicia a viagem
await tripService.startTrip(trip.id);

// 5. Motorista completa a viagem
await tripService.completeTrip(
  tripId: trip.id,
  finalFare: 20.00,
);
```

## Considerações de Segurança

- Todas as operações respeitam as políticas RLS (Row Level Security) do Supabase
- Validações de entrada são realizadas antes de enviar para o banco
- Logs de erro não expõem informações sensíveis
- Transações são usadas para operações críticas

## Performance

- Índices no banco para campos frequentemente consultados
- Paginação implementada para grandes conjuntos de dados
- Cache de consultas frequentes pode ser implementado no futuro
- Limite de resultados configurável

## Testes

O serviço deve ser testado com:
- Mock do SupabaseClient para testes unitários
- Cenários de erro (network, validação, autenticação)
- Testes de integração com banco de dados de teste
- Testes de concorrência para operações simultâneas