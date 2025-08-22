import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverOperationZone {
  const DriverOperationZone({
    required this.id,
    required this.driverId,
    required this.zoneName,
    required this.polygonCoordinates,
    required this.priceMultiplier,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverOperationZone.fromJson(Map<String, dynamic> json) {
    // Parse polygon coordinates from JSON
    final coordinatesJson = json['polygon_coordinates'] as List<dynamic>;
    final coordinates = coordinatesJson
        .map((coord) => LatLng(
              (coord['lat'] as num).toDouble(),
              (coord['lng'] as num).toDouble(),
            ))
        .toList();

    return DriverOperationZone(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      zoneName: json['zone_name'] as String,
      polygonCoordinates: coordinates,
      priceMultiplier: (json['price_multiplier'] as num).toDouble(),
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'zone_name': zoneName,
      'polygon_coordinates': polygonCoordinates
          .map((coord) => {
                'lat': coord.latitude,
                'lng': coord.longitude,
              })
          .toList(),
      'price_multiplier': priceMultiplier,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'driver_id': driverId,
      'zone_name': zoneName,
      'polygon_coordinates': polygonCoordinates
          .map((coord) => {
                'lat': coord.latitude,
                'lng': coord.longitude,
              })
          .toList(),
      'price_multiplier': priceMultiplier,
      'is_active': isActive,
    };
  }

  final String id;
  final String driverId;
  final String zoneName;
  final List<LatLng> polygonCoordinates;
  final double priceMultiplier;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriverOperationZone &&
        other.id == id &&
        other.driverId == driverId &&
        other.zoneName == zoneName &&
        other.priceMultiplier == priceMultiplier &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      driverId,
      zoneName,
      priceMultiplier,
      isActive,
    );
  }

  @override
  String toString() {
    return 'DriverOperationZone(id: $id, driverId: $driverId, zoneName: $zoneName, '
        'priceMultiplier: ${priceMultiplier}x, isActive: $isActive, '
        'coordinates: ${polygonCoordinates.length} points)';
  }

  /// Retorna uma representação legível da zona
  String get displayName => zoneName;

  /// Retorna a descrição do multiplicador
  String get multiplierDescription {
    if (priceMultiplier == 1.0) {
      return 'Preço normal';
    } else if (priceMultiplier > 1.0) {
      final percentage = ((priceMultiplier - 1.0) * 100).round();
      return '+$percentage% do preço base';
    } else {
      final percentage = ((1.0 - priceMultiplier) * 100).round();
      return '-$percentage% do preço base';
    }
  }

  /// Retorna o fator formatado como string
  String get formattedMultiplier => '${priceMultiplier.toStringAsFixed(1)}x';

  /// Cria uma cópia com campos atualizados
  DriverOperationZone copyWith({
    String? id,
    String? driverId,
    String? zoneName,
    List<LatLng>? polygonCoordinates,
    double? priceMultiplier,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DriverOperationZone(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      zoneName: zoneName ?? this.zoneName,
      polygonCoordinates: polygonCoordinates ?? this.polygonCoordinates,
      priceMultiplier: priceMultiplier ?? this.priceMultiplier,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Verifica se um ponto está dentro do polígono usando Ray Casting Algorithm
  bool containsPoint(LatLng point) {
    if (polygonCoordinates.length < 3) return false;

    bool inside = false;
    int j = polygonCoordinates.length - 1;

    for (int i = 0; i < polygonCoordinates.length; i++) {
      final xi = polygonCoordinates[i].latitude;
      final yi = polygonCoordinates[i].longitude;
      final xj = polygonCoordinates[j].latitude;
      final yj = polygonCoordinates[j].longitude;

      if (((yi > point.longitude) != (yj > point.longitude)) &&
          (point.latitude < (xj - xi) * (point.longitude - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  /// Calcula a área aproximada do polígono em km²
  double get approximateAreaKm2 {
    if (polygonCoordinates.length < 3) return 0.0;

    double area = 0.0;
    final int n = polygonCoordinates.length;

    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      final lat1 = polygonCoordinates[i].latitude;
      final lng1 = polygonCoordinates[i].longitude;
      final lat2 = polygonCoordinates[j].latitude;
      final lng2 = polygonCoordinates[j].longitude;

      area += (lng2 - lng1) * (lat2 + lat1);
    }

    area = (area.abs() / 2.0);
    
    // Conversão aproximada de graus para km² (simplificada)
    // 1 grau de latitude ≈ 111 km
    // 1 grau de longitude varia com a latitude, mas usamos aproximação
    return area * 111 * 111;
  }

  /// Retorna o centro aproximado do polígono
  LatLng get center {
    if (polygonCoordinates.isEmpty) return const LatLng(0, 0);

    double sumLat = 0.0;
    double sumLng = 0.0;

    for (final coord in polygonCoordinates) {
      sumLat += coord.latitude;
      sumLng += coord.longitude;
    }

    return LatLng(
      sumLat / polygonCoordinates.length,
      sumLng / polygonCoordinates.length,
    );
  }
}