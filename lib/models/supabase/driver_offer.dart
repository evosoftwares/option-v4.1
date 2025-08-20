class DriverOffer {
  final String id;
  final String? tripId;
  final String? driverId;
  final double? driverEtaMinutes;
  final double? baseFare;
  final double? additionalFees;
  final double? totalFare;
  final double? distanceComponent;
  final double? timeComponent;
  final bool? isAvailable;
  final bool? wasSelected;
  final String? notes;
  final DateTime? createdAt;

  DriverOffer({
    required this.id,
    this.tripId,
    this.driverId,
    this.driverEtaMinutes,
    this.baseFare,
    this.additionalFees,
    this.totalFare,
    this.distanceComponent,
    this.timeComponent,
    this.isAvailable,
    this.wasSelected,
    this.notes,
    this.createdAt,
  });

  factory DriverOffer.fromJson(Map<String, dynamic> json) {
    return DriverOffer(
      id: json['id'] as String,
      tripId: json['trip_id'] as String?,
      driverId: json['driver_id'] as String?,
      driverEtaMinutes: (json['driver_eta_minutes'] as num?)?.toDouble(),
      baseFare: (json['base_fare'] as num?)?.toDouble(),
      additionalFees: (json['additional_fees'] as num?)?.toDouble(),
      totalFare: (json['total_fare'] as num?)?.toDouble(),
      distanceComponent: (json['distance_component'] as num?)?.toDouble(),
      timeComponent: (json['time_component'] as num?)?.toDouble(),
      isAvailable: json['is_available'] as bool?,
      wasSelected: json['was_selected'] as bool?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'driver_id': driverId,
      'driver_eta_minutes': driverEtaMinutes,
      'base_fare': baseFare,
      'additional_fees': additionalFees,
      'total_fare': totalFare,
      'distance_component': distanceComponent,
      'time_component': timeComponent,
      'is_available': isAvailable,
      'was_selected': wasSelected,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  DriverOffer copyWith({
    String? id,
    String? tripId,
    String? driverId,
    double? driverEtaMinutes,
    double? baseFare,
    double? additionalFees,
    double? totalFare,
    double? distanceComponent,
    double? timeComponent,
    bool? isAvailable,
    bool? wasSelected,
    String? notes,
    DateTime? createdAt,
  }) {
    return DriverOffer(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      driverId: driverId ?? this.driverId,
      driverEtaMinutes: driverEtaMinutes ?? this.driverEtaMinutes,
      baseFare: baseFare ?? this.baseFare,
      additionalFees: additionalFees ?? this.additionalFees,
      totalFare: totalFare ?? this.totalFare,
      distanceComponent: distanceComponent ?? this.distanceComponent,
      timeComponent: timeComponent ?? this.timeComponent,
      isAvailable: isAvailable ?? this.isAvailable,
      wasSelected: wasSelected ?? this.wasSelected,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}