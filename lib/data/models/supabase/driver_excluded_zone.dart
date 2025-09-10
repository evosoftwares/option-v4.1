class DriverExcludedZone {
  const DriverExcludedZone({
    required this.id,
    required this.driverId,
    required this.neighborhoodName,
    required this.city,
    required this.state,
    required this.createdAt,
    this.keyword,
    this.zoneType,
  });

  factory DriverExcludedZone.fromJson(Map<String, dynamic> json) => DriverExcludedZone(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      neighborhoodName: json['neighborhood_name'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      keyword: json['keyword'] as String?,
      zoneType: json['zone_type'] as String?,
    );

  Map<String, dynamic> toJson() => {
      'id': id,
      'driver_id': driverId,
      'neighborhood_name': neighborhoodName,
      'city': city,
      'state': state,
      'created_at': createdAt.toIso8601String(),
      if (keyword != null) 'keyword': keyword,
      if (zoneType != null) 'zone_type': zoneType,
    };

  Map<String, dynamic> toInsertJson() => {
      'driver_id': driverId,
      'neighborhood_name': neighborhoodName,
      'city': city,
      'state': state,
      if (keyword != null) 'keyword': keyword,
      if (zoneType != null) 'zone_type': zoneType,
    };

  final String id;
  final String driverId;
  final String neighborhoodName;
  final String city;
  final String state;
  final DateTime createdAt;
  final String? keyword;
  final String? zoneType;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriverExcludedZone &&
        other.id == id &&
        other.driverId == driverId &&
        other.neighborhoodName == neighborhoodName &&
        other.city == city &&
        other.state == state &&
        other.keyword == keyword &&
        other.zoneType == zoneType;
  }

  @override
  int get hashCode => Object.hash(
      id,
      driverId,
      neighborhoodName,
      city,
      state,
      keyword,
      zoneType,
    );

  @override
  String toString() => 'DriverExcludedZone(id: $id, driverId: $driverId, neighborhoodName: $neighborhoodName, city: $city, state: $state, keyword: $keyword, zoneType: $zoneType, createdAt: $createdAt)';

  /// Retorna uma representação legível da zona excluída
  String get displayName {
    if (keyword != null && zoneType != null) {
      final typeLabel = _getTypeLabel(zoneType!);
      return '$keyword ($typeLabel)';
    }
    return '$neighborhoodName, $city - $state';
  }

  /// Converte tipo de zona para label legível
  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'rua': return 'Rua/Avenida';
      case 'bairro': return 'Bairro';
      case 'cidade': return 'Cidade';
      case 'estado': return 'Estado';
      case 'regiao': return 'Região';
      default: return type;
    }
  }

  /// Verifica se é uma exclusão baseada em palavra-chave
  bool get isKeywordBased => keyword != null && keyword!.isNotEmpty;

  /// Retorna a palavra-chave de exclusão ou o nome do bairro como fallback
  String get exclusionTerm => keyword ?? neighborhoodName;

  /// Cria uma cópia com campos atualizados
  DriverExcludedZone copyWith({
    String? id,
    String? driverId,
    String? neighborhoodName,
    String? city,
    String? state,
    DateTime? createdAt,
    String? keyword,
    String? zoneType,
  }) => DriverExcludedZone(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      neighborhoodName: neighborhoodName ?? this.neighborhoodName,
      city: city ?? this.city,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      keyword: keyword ?? this.keyword,
      zoneType: zoneType ?? this.zoneType,
    );
}