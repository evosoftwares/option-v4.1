# Documentação dos Modelos de Viagem

## Visão Geral
Esta documentação descreve os modelos de dados utilizados pelo TripService para representar viagens, solicitações de viagem e localizações no sistema.

## Modelos

### 1. TripRequest
Representa uma solicitação de viagem feita por um passageiro.

#### Estrutura do Banco de Dados (Supabase)

```sql
CREATE TABLE trip_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  passenger_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  origin_address TEXT NOT NULL,
  origin_latitude DOUBLE PRECISION NOT NULL,
  origin_longitude DOUBLE PRECISION NOT NULL,
  origin_neighborhood TEXT,
  destination_address TEXT NOT NULL,
  destination_latitude DOUBLE PRECISION NOT NULL,
  destination_longitude DOUBLE PRECISION NOT NULL,
  destination_neighborhood TEXT,
  vehicle_category TEXT NOT NULL CHECK (vehicle_category IN ('standard', 'comfort', 'premium', 'xl')),
  needs_pet BOOLEAN DEFAULT FALSE,
  needs_grocery_space BOOLEAN DEFAULT FALSE,
  is_condo_destination BOOLEAN DEFAULT FALSE,
  is_condo_origin BOOLEAN DEFAULT FALSE,
  needs_ac BOOLEAN DEFAULT FALSE,
  number_of_stops INTEGER DEFAULT 0 CHECK (number_of_stops >= 0),
  estimated_distance_km DOUBLE PRECISION NOT NULL,
  estimated_duration_minutes INTEGER NOT NULL,
  estimated_fare DOUBLE PRECISION NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'completed', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_trip_requests_passenger_id ON trip_requests(passenger_id);
CREATE INDEX idx_trip_requests_status ON trip_requests(status);
CREATE INDEX idx_trip_requests_created_at ON trip_requests(created_at DESC);
```

#### Modelo Dart

```dart
class TripRequest {
  final String id;
  final String passengerId;
  final String originAddress;
  final double originLatitude;
  final double originLongitude;
  final String? originNeighborhood;
  final String destinationAddress;
  final double destinationLatitude;
  final double destinationLongitude;
  final String? destinationNeighborhood;
  final String vehicleCategory; // 'standard', 'comfort', 'premium', 'xl'
  final bool needsPet;
  final bool needsGrocerySpace;
  final bool isCondoDestination;
  final bool isCondoOrigin;
  final bool needsAc;
  final int numberOfStops;
  final double estimatedDistanceKm;
  final int estimatedDurationMinutes;
  final double estimatedFare;
  final String status; // 'pending', 'accepted', 'completed', 'cancelled'
  final DateTime createdAt;
  final DateTime updatedAt;

  // Construtores
  TripRequest({
    required this.id,
    required this.passengerId,
    required this.originAddress,
    required this.originLatitude,
    required this.originLongitude,
    this.originNeighborhood,
    required this.destinationAddress,
    required this.destinationLatitude,
    required this.destinationLongitude,
    this.destinationNeighborhood,
    required this.vehicleCategory,
    this.needsPet = false,
    this.needsGrocerySpace = false,
    this.isCondoDestination = false,
    this.isCondoOrigin = false,
    this.needsAc = false,
    this.numberOfStops = 0,
    required this.estimatedDistanceKm,
    required this.estimatedDurationMinutes,
    required this.estimatedFare,
    this.status = 'pending',
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory para criar a partir de JSON do Supabase
  factory TripRequest.fromJson(Map<String, dynamic> json) {
    return TripRequest(
      id: json['id'],
      passengerId: json['passenger_id'],
      originAddress: json['origin_address'],
      originLatitude: json['origin_latitude'],
      originLongitude: json['origin_longitude'],
      originNeighborhood: json['origin_neighborhood'],
      destinationAddress: json['destination_address'],
      destinationLatitude: json['destination_latitude'],
      destinationLongitude: json['destination_longitude'],
      destinationNeighborhood: json['destination_neighborhood'],
      vehicleCategory: json['vehicle_category'],
      needsPet: json['needs_pet'] ?? false,
      needsGrocerySpace: json['needs_grocery_space'] ?? false,
      isCondoDestination: json['is_condo_destination'] ?? false,
      isCondoOrigin: json['is_condo_origin'] ?? false,
      needsAc: json['needs_ac'] ?? false,
      numberOfStops: json['number_of_stops'] ?? 0,
      estimatedDistanceKm: json['estimated_distance_km'],
      estimatedDurationMinutes: json['estimated_duration_minutes'],
      estimatedFare: json['estimated_fare'].toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'passenger_id': passengerId,
      'origin_address': originAddress,
      'origin_latitude': originLatitude,
      'origin_longitude': originLongitude,
      'origin_neighborhood': originNeighborhood,
      'destination_address': destinationAddress,
      'destination_latitude': destinationLatitude,
      'destination_longitude': destinationLongitude,
      'destination_neighborhood': destinationNeighborhood,
      'vehicle_category': vehicleCategory,
      'needs_pet': needsPet,
      'needs_grocery_space': needsGrocerySpace,
      'is_condo_destination': isCondoDestination,
      'is_condo_origin': isCondoOrigin,
      'needs_ac': needsAc,
      'number_of_stops': numberOfStops,
      'estimated_distance_km': estimatedDistanceKm,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'estimated_fare': estimatedFare,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Métodos auxiliares
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}
```

### 2. Trip
Representa uma viagem ativa ou concluída.

#### Estrutura do Banco de Dados (Supabase)

```sql
CREATE TABLE trips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_request_id UUID REFERENCES trip_requests(id) ON DELETE CASCADE,
  driver_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  vehicle_id UUID REFERENCES vehicles(id) ON DELETE CASCADE,
  passenger_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  origin_address TEXT NOT NULL,
  origin_latitude DOUBLE PRECISION NOT NULL,
  origin_longitude DOUBLE PRECISION NOT NULL,
  destination_address TEXT NOT NULL,
  destination_latitude DOUBLE PRECISION NOT NULL,
  destination_longitude DOUBLE PRECISION NOT NULL,
  estimated_distance_km DOUBLE PRECISION NOT NULL,
  estimated_duration_minutes INTEGER NOT NULL,
  estimated_fare DOUBLE PRECISION NOT NULL,
  final_fare DOUBLE PRECISION,
  status TEXT NOT NULL CHECK (status IN ('accepted', 'in_progress', 'completed', 'cancelled')),
  started_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  cancelled_at TIMESTAMP WITH TIME ZONE,
  cancellation_reason TEXT,
  cancelled_by TEXT CHECK (cancelled_by IN ('driver', 'passenger')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_trips_driver_id ON trips(driver_id);
CREATE INDEX idx_trips_passenger_id ON trips(passenger_id);
CREATE INDEX idx_trips_status ON trips(status);
CREATE INDEX idx_trips_trip_request_id ON trips(trip_request_id);
CREATE INDEX idx_trips_created_at ON trips(created_at DESC);

-- Índice para buscar viagens ativas
CREATE INDEX idx_trips_active ON trips(driver_id, passenger_id) 
WHERE status IN ('accepted', 'in_progress');
```

#### Modelo Dart

```dart
class Trip {
  final String id;
  final String tripRequestId;
  final String driverId;
  final String vehicleId;
  final String passengerId;
  final String originAddress;
  final double originLatitude;
  final double originLongitude;
  final String destinationAddress;
  final double destinationLatitude;
  final double destinationLongitude;
  final double estimatedDistanceKm;
  final int estimatedDurationMinutes;
  final double estimatedFare;
  final double? finalFare;
  final String status; // 'accepted', 'in_progress', 'completed', 'cancelled'
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? cancelledBy; // 'driver' or 'passenger'
  final DateTime createdAt;
  final DateTime updatedAt;

  // Construtores
  Trip({
    required this.id,
    required this.tripRequestId,
    required this.driverId,
    required this.vehicleId,
    required this.passengerId,
    required this.originAddress,
    required this.originLatitude,
    required this.originLongitude,
    required this.destinationAddress,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.estimatedDistanceKm,
    required this.estimatedDurationMinutes,
    required this.estimatedFare,
    this.finalFare,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.cancelledBy,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory para criar a partir de JSON
  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      tripRequestId: json['trip_request_id'],
      driverId: json['driver_id'],
      vehicleId: json['vehicle_id'],
      passengerId: json['passenger_id'],
      originAddress: json['origin_address'],
      originLatitude: json['origin_latitude'],
      originLongitude: json['origin_longitude'],
      destinationAddress: json['destination_address'],
      destinationLatitude: json['destination_latitude'],
      destinationLongitude: json['destination_longitude'],
      estimatedDistanceKm: json['estimated_distance_km'],
      estimatedDurationMinutes: json['estimated_duration_minutes'],
      estimatedFare: json['estimated_fare'].toDouble(),
      finalFare: json['final_fare']?.toDouble(),
      status: json['status'],
      startedAt: json['started_at'] != null 
          ? DateTime.parse(json['started_at']) 
          : null,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      cancelledAt: json['cancelled_at'] != null 
          ? DateTime.parse(json['cancelled_at']) 
          : null,
      cancellationReason: json['cancellation_reason'],
      cancelledBy: json['cancelled_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Métodos auxiliares
  bool get isAccepted => status == 'accepted';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  
  bool get hasStarted => startedAt != null;
  bool get hasCompleted => completedAt != null;
  bool get hasBeenCancelled => cancelledAt != null;
  
  Duration? get duration {
    if (startedAt == null || completedAt == null) return null;
    return completedAt!.difference(startedAt!);
  }
  
  double? get actualFare => finalFare;
}
```

### 3. Location
Representa um ponto de localização durante uma viagem.

#### Estrutura do Banco de Dados (Supabase)

```sql
CREATE TABLE trip_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID REFERENCES trips(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  address TEXT,
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_trip_locations_trip_id ON trip_locations(trip_id);
CREATE INDEX idx_trip_locations_timestamp ON trip_locations(timestamp);
```

#### Modelo Dart

```dart
class Location {
  final String id;
  final String tripId;
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;
  final DateTime createdAt;

  Location({
    required this.id,
    required this.tripId,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.timestamp,
    required this.createdAt,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      tripId: json['trip_id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      address: json['address'],
      timestamp: DateTime.parse(json['timestamp']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Métodos auxiliares
  LatLng toLatLng() => LatLng(latitude, longitude);
}
```

## Relacionamentos entre Modelos

### Diagrama de Relacionamentos

```
User (passenger) 1---* TripRequest 1---1 Trip *---* Location
User (driver)    1---* Trip
Vehicle          1---* Trip
```

### Fluxo de Dados

1. **TripRequest criada** → Usuário cria solicitação
2. **TripRequest aceita** → Cria Trip vinculado
3. **Trip iniciada** → Trip.status = 'in_progress'
4. **Locations adicionadas** → Registra pontos durante viagem
5. **Trip completada** → Trip.status = 'completed'

## Validações e Constraints

### Validações no Modelo

```dart
class TripRequestValidator {
  static void validate(TripRequest request) {
    if (request.originLatitude < -90 || request.originLatitude > 90) {
      throw ValidationException('Latitude de origem inválida');
    }
    
    if (request.originLongitude < -180 || request.originLongitude > 180) {
      throw ValidationException('Longitude de origem inválida');
    }
    
    if (request.estimatedDistanceKm <= 0) {
      throw ValidationException('Distância estimada deve ser positiva');
    }
    
    if (request.estimatedFare <= 0) {
      throw ValidationException('Tarifa estimada deve ser positiva');
    }
    
    if (!['standard', 'comfort', 'premium', 'xl'].contains(request.vehicleCategory)) {
      throw ValidationException('Categoria de veículo inválida');
    }
  }
}
```

## Exemplos de Uso

### Criar e vincular modelos

```dart
// 1. Criar TripRequest
final tripRequest = TripRequest(
  id: 'uuid-123',
  passengerId: 'user-123',
  originAddress: 'Rua A, 123',
  originLatitude: -23.5505,
  originLongitude: -46.6333,
  destinationAddress: 'Rua B, 456',
  destinationLatitude: -23.5605,
  destinationLongitude: -46.6433,
  vehicleCategory: 'standard',
  estimatedDistanceKm: 5.2,
  estimatedDurationMinutes: 25,
  estimatedFare: 25.50,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// 2. Criar Trip a partir do TripRequest
final trip = Trip(
  id: 'uuid-456',
  tripRequestId: tripRequest.id,
  driverId: 'driver-789',
  vehicleId: 'vehicle-111',
  passengerId: tripRequest.passengerId,
  originAddress: tripRequest.originAddress,
  originLatitude: tripRequest.originLatitude,
  originLongitude: tripRequest.originLongitude,
  destinationAddress: tripRequest.destinationAddress,
  destinationLatitude: tripRequest.destinationLatitude,
  destinationLongitude: tripRequest.destinationLongitude,
  estimatedDistanceKm: tripRequest.estimatedDistanceKm,
  estimatedDurationMinutes: tripRequest.estimatedDurationMinutes,
  estimatedFare: tripRequest.estimatedFare,
  status: 'accepted',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// 3. Adicionar localizações durante a viagem
final location = Location(
  id: 'uuid-789',
  tripId: trip.id,
  latitude: -23.5555,
  longitude: -46.6388,
  address: 'Avenida Central, 100',
  timestamp: DateTime.now(),
  createdAt: DateTime.now(),
);