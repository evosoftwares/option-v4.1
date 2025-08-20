import 'package:uuid/uuid.dart';

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
  final String vehicleCategory;
  final bool needsPet;
  final bool needsGrocerySpace;
  final bool isCondoDestination;
  final bool isCondoOrigin;
  final bool needsAc;
  final int numberOfStops;
  final double estimatedDistanceKm;
  final int estimatedDurationMinutes;
  final double estimatedFare;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? acceptedAt;
  final String? acceptedByDriverId;

  TripRequest({
    String? id,
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
    required this.needsPet,
    required this.needsGrocerySpace,
    required this.isCondoDestination,
    required this.isCondoOrigin,
    required this.needsAc,
    required this.numberOfStops,
    required this.estimatedDistanceKm,
    required this.estimatedDurationMinutes,
    required this.estimatedFare,
    required this.status,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.acceptedAt,
    this.acceptedByDriverId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory TripRequest.fromJson(Map<String, dynamic> json) {
    return TripRequest(
      id: json['id'] as String,
      passengerId: json['passenger_id'] as String,
      originAddress: json['origin_address'] as String,
      originLatitude: json['origin_latitude']?.toDouble() ?? 0.0,
      originLongitude: json['origin_longitude']?.toDouble() ?? 0.0,
      originNeighborhood: json['origin_neighborhood'] as String?,
      destinationAddress: json['destination_address'] as String,
      destinationLatitude: json['destination_latitude']?.toDouble() ?? 0.0,
      destinationLongitude: json['destination_longitude']?.toDouble() ?? 0.0,
      destinationNeighborhood: json['destination_neighborhood'] as String?,
      vehicleCategory: json['vehicle_category'] as String,
      needsPet: json['needs_pet'] as bool? ?? false,
      needsGrocerySpace: json['needs_grocery_space'] as bool? ?? false,
      isCondoDestination: json['is_condo_destination'] as bool? ?? false,
      isCondoOrigin: json['is_condo_origin'] as bool? ?? false,
      needsAc: json['needs_ac'] as bool? ?? false,
      numberOfStops: json['number_of_stops'] as int? ?? 0,
      estimatedDistanceKm: json['estimated_distance_km']?.toDouble() ?? 0.0,
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int? ?? 0,
      estimatedFare: json['estimated_fare']?.toDouble() ?? 0.0,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      acceptedAt: json['accepted_at'] != null 
          ? DateTime.parse(json['accepted_at'] as String) 
          : null,
      acceptedByDriverId: json['accepted_by_driver_id'] as String?,
    );
  }

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
      'accepted_at': acceptedAt?.toIso8601String(),
      'accepted_by_driver_id': acceptedByDriverId,
    };
  }

  TripRequest copyWith({
    String? id,
    String? passengerId,
    String? originAddress,
    double? originLatitude,
    double? originLongitude,
    String? originNeighborhood,
    String? destinationAddress,
    double? destinationLatitude,
    double? destinationLongitude,
    String? destinationNeighborhood,
    String? vehicleCategory,
    bool? needsPet,
    bool? needsGrocerySpace,
    bool? isCondoDestination,
    bool? isCondoOrigin,
    bool? needsAc,
    int? numberOfStops,
    double? estimatedDistanceKm,
    int? estimatedDurationMinutes,
    double? estimatedFare,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    String? acceptedByDriverId,
  }) {
    return TripRequest(
      id: id ?? this.id,
      passengerId: passengerId ?? this.passengerId,
      originAddress: originAddress ?? this.originAddress,
      originLatitude: originLatitude ?? this.originLatitude,
      originLongitude: originLongitude ?? this.originLongitude,
      originNeighborhood: originNeighborhood ?? this.originNeighborhood,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      destinationLatitude: destinationLatitude ?? this.destinationLatitude,
      destinationLongitude: destinationLongitude ?? this.destinationLongitude,
      destinationNeighborhood: destinationNeighborhood ?? this.destinationNeighborhood,
      vehicleCategory: vehicleCategory ?? this.vehicleCategory,
      needsPet: needsPet ?? this.needsPet,
      needsGrocerySpace: needsGrocerySpace ?? this.needsGrocerySpace,
      isCondoDestination: isCondoDestination ?? this.isCondoDestination,
      isCondoOrigin: isCondoOrigin ?? this.isCondoOrigin,
      needsAc: needsAc ?? this.needsAc,
      numberOfStops: numberOfStops ?? this.numberOfStops,
      estimatedDistanceKm: estimatedDistanceKm ?? this.estimatedDistanceKm,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      acceptedByDriverId: acceptedByDriverId ?? this.acceptedByDriverId,
    );
  }

  // Helper methods for status checking
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isCancelled => status == 'cancelled';
  bool get isExpired => status == 'expired';
}