class Vehicle {
  final String id;
  final String? driverId;
  final String? make;
  final String? model;
  final int? year;
  final String? color;
  final String? licensePlate;
  final String? category;
  final bool? hasAc;
  final bool? hasPetFriendly;
  final bool? hasGrocerySpace;
  final String? photoUrl;
  final DateTime? createdAt;

  Vehicle({
    required this.id,
    this.driverId,
    this.make,
    this.model,
    this.year,
    this.color,
    this.licensePlate,
    this.category,
    this.hasAc,
    this.hasPetFriendly,
    this.hasGrocerySpace,
    this.photoUrl,
    this.createdAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      driverId: json['driver_id'] as String?,
      make: json['make'] as String?,
      model: json['model'] as String?,
      year: json['year'] as int?,
      color: json['color'] as String?,
      licensePlate: json['license_plate'] as String?,
      category: json['category'] as String?,
      hasAc: json['has_ac'] as bool?,
      hasPetFriendly: json['has_pet_friendly'] as bool?,
      hasGrocerySpace: json['has_grocery_space'] as bool?,
      photoUrl: json['photo_url'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'license_plate': licensePlate,
      'category': category,
      'has_ac': hasAc,
      'has_pet_friendly': hasPetFriendly,
      'has_grocery_space': hasGrocerySpace,
      'photo_url': photoUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Vehicle copyWith({
    String? id,
    String? driverId,
    String? make,
    String? model,
    int? year,
    String? color,
    String? licensePlate,
    String? category,
    bool? hasAc,
    bool? hasPetFriendly,
    bool? hasGrocerySpace,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      licensePlate: licensePlate ?? this.licensePlate,
      category: category ?? this.category,
      hasAc: hasAc ?? this.hasAc,
      hasPetFriendly: hasPetFriendly ?? this.hasPetFriendly,
      hasGrocerySpace: hasGrocerySpace ?? this.hasGrocerySpace,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}