/// Preferências da viagem para cálculo de preços e matching
class TripPreferences {
  const TripPreferences({
    this.needsPet = false,
    this.needsGrocery = false,
    this.needsCondo = false,
    this.needsAC = false,
    this.numberOfStops = 0,
  });

  factory TripPreferences.fromJson(Map<String, dynamic> json) =>
      TripPreferences(
        needsPet: json['needs_pet'] as bool? ?? false,
        needsGrocery: json['needs_grocery'] as bool? ?? false,
        needsCondo: json['needs_condo'] as bool? ?? false,
        needsAC: json['needs_ac'] as bool? ?? false,
        numberOfStops: json['number_of_stops'] as int? ?? 0,
      );

  final bool needsPet;
  final bool needsGrocery;
  final bool needsCondo;
  final bool needsAC;
  final int numberOfStops;

  TripPreferences copyWith({
    bool? needsPet,
    bool? needsGrocery,
    bool? needsCondo,
    bool? needsAC,
    int? numberOfStops,
  }) =>
      TripPreferences(
        needsPet: needsPet ?? this.needsPet,
        needsGrocery: needsGrocery ?? this.needsGrocery,
        needsCondo: needsCondo ?? this.needsCondo,
        needsAC: needsAC ?? this.needsAC,
        numberOfStops: numberOfStops ?? this.numberOfStops,
      );

  Map<String, dynamic> toJson() => {
        'needs_pet': needsPet,
        'needs_grocery': needsGrocery,
        'needs_condo': needsCondo,
        'needs_ac': needsAC,
        'number_of_stops': numberOfStops,
      };

  @override
  String toString() =>
      'TripPreferences(pet: $needsPet, grocery: $needsGrocery, condo: $needsCondo, AC: $needsAC, stops: $numberOfStops)';
}