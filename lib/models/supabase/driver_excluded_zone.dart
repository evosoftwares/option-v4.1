class DriverExcludedZone {
  const DriverExcludedZone({
    required this.id,
    required this.driverId,
    required this.neighborhoodName,
    required this.city,
    required this.state,
    required this.createdAt,
  });

  factory DriverExcludedZone.fromJson(Map<String, dynamic> json) {
    return DriverExcludedZone(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      neighborhoodName: json['neighborhood_name'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'neighborhood_name': neighborhoodName,
      'city': city,
      'state': state,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'driver_id': driverId,
      'neighborhood_name': neighborhoodName,
      'city': city,
      'state': state,
    };
  }

  final String id;
  final String driverId;
  final String neighborhoodName;
  final String city;
  final String state;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriverExcludedZone &&
        other.id == id &&
        other.driverId == driverId &&
        other.neighborhoodName == neighborhoodName &&
        other.city == city &&
        other.state == state;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      driverId,
      neighborhoodName,
      city,
      state,
    );
  }

  @override
  String toString() {
    return 'DriverExcludedZone(id: $id, driverId: $driverId, neighborhoodName: $neighborhoodName, city: $city, state: $state, createdAt: $createdAt)';
  }

  /// Retorna uma representação legível da zona excluída
  String get displayName => '$neighborhoodName, $city - $state';

  /// Cria uma cópia com campos atualizados
  DriverExcludedZone copyWith({
    String? id,
    String? driverId,
    String? neighborhoodName,
    String? city,
    String? state,
    DateTime? createdAt,
  }) {
    return DriverExcludedZone(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      neighborhoodName: neighborhoodName ?? this.neighborhoodName,
      city: city ?? this.city,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}