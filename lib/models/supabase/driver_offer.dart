class DriverOffer {

  DriverOffer({
    required this.id,
    this.tripId,
    this.driverId,
    this.driverDistanceKm,
    this.driverEtaMinutes,
    this.baseFare,
    this.additionalFees,
    this.totalFare,
    this.isAvailable,
    this.wasSelected,
    this.notes,
    this.createdAt,
  });

  factory DriverOffer.fromJson(Map<String, dynamic> json) {
    return DriverOffer(
      id: json['id'] as String,
      tripId: (json['request_id'] as String?) ?? (json['trip_id'] as String?),
      driverId: json['driver_id'] as String?,
      driverDistanceKm: (json['driver_distance_km'] as num?)?.toDouble(),
      driverEtaMinutes: json['driver_eta_minutes'] as int?,
      baseFare: (json['base_fare'] as num?)?.toDouble(),
      additionalFees: (json['additional_fees'] as num?)?.toDouble(),
      totalFare: (json['total_fare'] as num?)?.toDouble(),
      isAvailable: json['is_available'] as bool?,
      wasSelected: json['was_selected'] as bool?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
  final String id;
  final String? tripId; // request_id (fallback trip_id)
  final String? driverId;
  final double? driverDistanceKm;
  final int? driverEtaMinutes;
  final double? baseFare;
  final double? additionalFees;
  final double? totalFare;
  final bool? isAvailable;
  final bool? wasSelected;
  final String? notes;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
      'id': id,
      'request_id': tripId,
      'driver_id': driverId,
      'driver_distance_km': driverDistanceKm,
      'driver_eta_minutes': driverEtaMinutes,
      'base_fare': baseFare,
      'additional_fees': additionalFees,
      'total_fare': totalFare,
      'is_available': isAvailable,
      'was_selected': wasSelected,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
    };

  DriverOffer copyWith({
    String? id,
    String? tripId,
    String? driverId,
    double? driverDistanceKm,
    int? driverEtaMinutes,
    double? baseFare,
    double? additionalFees,
    double? totalFare,
    bool? isAvailable,
    bool? wasSelected,
    String? notes,
    DateTime? createdAt,
  }) => DriverOffer(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      driverId: driverId ?? this.driverId,
      driverDistanceKm: driverDistanceKm ?? this.driverDistanceKm,
      driverEtaMinutes: driverEtaMinutes ?? this.driverEtaMinutes,
      baseFare: baseFare ?? this.baseFare,
      additionalFees: additionalFees ?? this.additionalFees,
      totalFare: totalFare ?? this.totalFare,
      isAvailable: isAvailable ?? this.isAvailable,
      wasSelected: wasSelected ?? this.wasSelected,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
}
