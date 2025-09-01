class TripRequestData {

  TripRequestData({
    required this.originAddress,
    required this.originLatitude,
    required this.originLongitude,
    required this.destinationAddress,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.vehicleCategory,
    required this.needsPet,
    required this.needsGrocerySpace,
    required this.isCondoOrigin,
    required this.isCondoDestination,
    required this.estimatedDistanceKm,
    required this.estimatedDurationMinutes,
    required this.estimatedFare,
    this.originNeighborhood,
    this.destinationNeighborhood,
    this.needsAc = false,
    this.numberOfStops = 0,
  });

  /// Factory constructor para criar TripRequestData a partir de um TripRequest existente
  factory TripRequestData.fromRequest(Map<String, dynamic> request) => TripRequestData(
      originAddress: request['origin_address'] as String,
      originLatitude: (request['origin_latitude'] as num).toDouble(),
      originLongitude: (request['origin_longitude'] as num).toDouble(),
      destinationAddress: request['destination_address'] as String,
      destinationLatitude: (request['destination_latitude'] as num).toDouble(),
      destinationLongitude: (request['destination_longitude'] as num).toDouble(),
      vehicleCategory: request['vehicle_category'] as String,
      needsPet: request['needs_pet'] as bool? ?? false,
      needsGrocerySpace: request['needs_grocery_space'] as bool? ?? false,
      isCondoOrigin: request['is_condo_origin'] as bool? ?? false,
      isCondoDestination: request['is_condo_destination'] as bool? ?? false,
      estimatedDistanceKm: (request['estimated_distance_km'] as num?)?.toDouble() ?? 0.0,
      estimatedDurationMinutes: request['estimated_duration_minutes'] as int? ?? 0,
      estimatedFare: (request['estimated_fare'] as num?)?.toDouble() ?? 0.0,
      originNeighborhood: request['origin_neighborhood'] as String?,
      destinationNeighborhood: request['destination_neighborhood'] as String?,
      needsAc: request['needs_ac'] as bool? ?? false,
      numberOfStops: request['number_of_stops'] as int? ?? 0,
    );
  final String originAddress;
  final double originLatitude;
  final double originLongitude;
  final String destinationAddress;
  final double destinationLatitude;
  final double destinationLongitude;
  final String vehicleCategory;
  final bool needsPet;
  final bool needsGrocerySpace;
  final bool isCondoOrigin;
  final bool isCondoDestination;
  final double estimatedDistanceKm;
  final int estimatedDurationMinutes;
  final double estimatedFare;
  final String? originNeighborhood;
  final String? destinationNeighborhood;
  final bool needsAc;
  final int numberOfStops;

  // Computed property for backward compatibility
  bool get needsCondo => isCondoOrigin || isCondoDestination;
  bool get needsGrocery => needsGrocerySpace;

  /// Converter para Map para inserção no database
  Map<String, dynamic> toDatabase({
    required String passengerId,
    String? targetDriverId,
    List<String>? fallbackDrivers,
  }) => {
      'passenger_id': passengerId,
      'target_driver_id': targetDriverId,
      'fallback_drivers': fallbackDrivers,
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
      'is_condo_origin': isCondoOrigin,
      'is_condo_destination': isCondoDestination,
      'needs_ac': needsAc,
      'number_of_stops': numberOfStops,
      'estimated_distance_km': estimatedDistanceKm,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'estimated_fare': estimatedFare,
      'status': 'pending',
      'expires_at': DateTime.now().add(const Duration(seconds: 10)).toIso8601String(),
      'current_fallback_index': 0,
      'timeout_count': 0,
    };

  /// Copy method para facilitar modificações
  TripRequestData copyWith({
    String? originAddress,
    double? originLatitude,
    double? originLongitude,
    String? destinationAddress,
    double? destinationLatitude,
    double? destinationLongitude,
    String? vehicleCategory,
    bool? needsPet,
    bool? needsGrocerySpace,
    bool? isCondoOrigin,
    bool? isCondoDestination,
    double? estimatedDistanceKm,
    int? estimatedDurationMinutes,
    double? estimatedFare,
    String? originNeighborhood,
    String? destinationNeighborhood,
    bool? needsAc,
    int? numberOfStops,
  }) => TripRequestData(
      originAddress: originAddress ?? this.originAddress,
      originLatitude: originLatitude ?? this.originLatitude,
      originLongitude: originLongitude ?? this.originLongitude,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      destinationLatitude: destinationLatitude ?? this.destinationLatitude,
      destinationLongitude: destinationLongitude ?? this.destinationLongitude,
      vehicleCategory: vehicleCategory ?? this.vehicleCategory,
      needsPet: needsPet ?? this.needsPet,
      needsGrocerySpace: needsGrocerySpace ?? this.needsGrocerySpace,
      isCondoOrigin: isCondoOrigin ?? this.isCondoOrigin,
      isCondoDestination: isCondoDestination ?? this.isCondoDestination,
      estimatedDistanceKm: estimatedDistanceKm ?? this.estimatedDistanceKm,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      originNeighborhood: originNeighborhood ?? this.originNeighborhood,
      destinationNeighborhood: destinationNeighborhood ?? this.destinationNeighborhood,
      needsAc: needsAc ?? this.needsAc,
      numberOfStops: numberOfStops ?? this.numberOfStops,
    );

  @override
  String toString() => 'TripRequestData(from: $originAddress, to: $destinationAddress, fare: R\$ ${estimatedFare.toStringAsFixed(2)})';
}