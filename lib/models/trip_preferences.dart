/// Preferências da viagem para cálculo de preços e matching
class TripPreferences {
  const TripPreferences({
    this.needsPet = false,
    this.needsGrocerySpace = false,
    this.isCondoOrigin = false,
    this.isCondoDestination = false,
    this.needsAc = false,
    this.numberOfStops = 0,
  });

  factory TripPreferences.fromJson(Map<String, dynamic> json) {
    return TripPreferences(
      needsPet: json['needs_pet'] as bool? ?? false,
      needsGrocerySpace: json['needs_grocery_space'] as bool? ?? false,
      isCondoOrigin: json['is_condo_origin'] as bool? ?? false,
      isCondoDestination: json['is_condo_destination'] as bool? ?? false,
      needsAc: json['needs_ac'] as bool? ?? false,
      numberOfStops: json['number_of_stops'] as int? ?? 0,
    );
  }

  final bool needsPet;
  final bool needsGrocerySpace;
  final bool isCondoOrigin;
  final bool isCondoDestination;
  final bool needsAc;
  final int numberOfStops;

  // Computed property for backward compatibility
  bool get needsCondo => isCondoOrigin || isCondoDestination;

  TripPreferences copyWith({
    bool? needsPet,
    bool? needsGrocerySpace,
    bool? isCondoOrigin,
    bool? isCondoDestination,
    bool? needsAc,
    int? numberOfStops,
  }) {
    return TripPreferences(
      needsPet: needsPet ?? this.needsPet,
      needsGrocerySpace: needsGrocerySpace ?? this.needsGrocerySpace,
      isCondoOrigin: isCondoOrigin ?? this.isCondoOrigin,
      isCondoDestination: isCondoDestination ?? this.isCondoDestination,
      needsAc: needsAc ?? this.needsAc,
      numberOfStops: numberOfStops ?? this.numberOfStops,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'needs_pet': needsPet,
      'needs_grocery_space': needsGrocerySpace,
      'is_condo_origin': isCondoOrigin,
      'is_condo_destination': isCondoDestination,
      'needs_ac': needsAc,
      'number_of_stops': numberOfStops,
    };
  }

  @override
  String toString() {
    return 'TripPreferences(pet: $needsPet, grocery: $needsGrocerySpace, condoOrigin: $isCondoOrigin, condoDestination: $isCondoDestination, AC: $needsAc, stops: $numberOfStops)';
  }
}