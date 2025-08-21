class Trip {

  Trip({
    required this.id,
    required this.tripRequestId,
    required this.driverId,
    required this.passengerId,
    required this.originAddress,
    required this.originLatitude,
    required this.originLongitude,
    required this.destinationAddress,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.actualDistanceKm,
    required this.actualDurationMinutes,
    required this.baseFare,
    required this.finalFare,
    required this.status,
    required this.startTime,
    this.endTime,
    this.driverRating,
    this.passengerRating,
    this.promoCodeId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      tripRequestId: json['trip_request_id'] as String,
      driverId: json['driver_id'] as String,
      passengerId: json['passenger_id'] as String,
      originAddress: json['origin_address'] as String,
      originLatitude: json['origin_latitude']?.toDouble() ?? 0.0,
      originLongitude: json['origin_longitude']?.toDouble() ?? 0.0,
      destinationAddress: json['destination_address'] as String,
      destinationLatitude: json['destination_latitude']?.toDouble() ?? 0.0,
      destinationLongitude: json['destination_longitude']?.toDouble() ?? 0.0,
      actualDistanceKm: json['actual_distance_km']?.toDouble() ?? 0.0,
      actualDurationMinutes: json['actual_duration_minutes'] as int? ?? 0,
      baseFare: json['base_fare']?.toDouble() ?? 0.0,
      finalFare: json['final_fare']?.toDouble() ?? 0.0,
      status: json['status'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null 
          ? DateTime.parse(json['end_time'] as String) 
          : null,
      driverRating: json['driver_rating']?.toDouble(),
      passengerRating: json['passenger_rating']?.toDouble(),
      promoCodeId: json['promo_code_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  final String id;
  final String tripRequestId;
  final String driverId;
  final String passengerId;
  final String originAddress;
  final double originLatitude;
  final double originLongitude;
  final String destinationAddress;
  final double destinationLatitude;
  final double destinationLongitude;
  final double actualDistanceKm;
  final int actualDurationMinutes;
  final double baseFare;
  final double finalFare;
  final String status;
  final DateTime startTime;
  final DateTime? endTime;
  final double? driverRating;
  final double? passengerRating;
  final String? promoCodeId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
      'id': id,
      'trip_request_id': tripRequestId,
      'driver_id': driverId,
      'passenger_id': passengerId,
      'origin_address': originAddress,
      'origin_latitude': originLatitude,
      'origin_longitude': originLongitude,
      'destination_address': destinationAddress,
      'destination_latitude': destinationLatitude,
      'destination_longitude': destinationLongitude,
      'actual_distance_km': actualDistanceKm,
      'actual_duration_minutes': actualDurationMinutes,
      'base_fare': baseFare,
      'final_fare': finalFare,
      'status': status,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'driver_rating': driverRating,
      'passenger_rating': passengerRating,
      'promo_code_id': promoCodeId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

  Trip copyWith({
    String? id,
    String? tripRequestId,
    String? driverId,
    String? passengerId,
    String? originAddress,
    double? originLatitude,
    double? originLongitude,
    String? destinationAddress,
    double? destinationLatitude,
    double? destinationLongitude,
    double? actualDistanceKm,
    int? actualDurationMinutes,
    double? baseFare,
    double? finalFare,
    String? status,
    DateTime? startTime,
    DateTime? endTime,
    double? driverRating,
    double? passengerRating,
    String? promoCodeId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Trip(
      id: id ?? this.id,
      tripRequestId: tripRequestId ?? this.tripRequestId,
      driverId: driverId ?? this.driverId,
      passengerId: passengerId ?? this.passengerId,
      originAddress: originAddress ?? this.originAddress,
      originLatitude: originLatitude ?? this.originLatitude,
      originLongitude: originLongitude ?? this.originLongitude,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      destinationLatitude: destinationLatitude ?? this.destinationLatitude,
      destinationLongitude: destinationLongitude ?? this.destinationLongitude,
      actualDistanceKm: actualDistanceKm ?? this.actualDistanceKm,
      actualDurationMinutes: actualDurationMinutes ?? this.actualDurationMinutes,
      baseFare: baseFare ?? this.baseFare,
      finalFare: finalFare ?? this.finalFare,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      driverRating: driverRating ?? this.driverRating,
      passengerRating: passengerRating ?? this.passengerRating,
      promoCodeId: promoCodeId ?? this.promoCodeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );

  // Helper methods for status checking
  bool get isOngoing => status == 'ongoing';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isRated => driverRating != null && passengerRating != null;
}