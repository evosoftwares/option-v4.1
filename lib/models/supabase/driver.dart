class Driver {
  final String id;
  final String userId;
  final String vehicleId;
  final String licenseNumber;
  final String licensePlate;
  final String vehicleColor;
  final String vehicleModel;
  final String vehicleBrand;
  final int vehicleYear;
  final String vehicleCategory;
  final bool hasAirConditioning;
  final bool hasPetFriendly;
  final bool hasGrocerySpace;
  final bool acceptsCondo;
  final double rating;
  final int totalTrips;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Driver({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.licenseNumber,
    required this.licensePlate,
    required this.vehicleColor,
    required this.vehicleModel,
    required this.vehicleBrand,
    required this.vehicleYear,
    required this.vehicleCategory,
    required this.hasAirConditioning,
    required this.hasPetFriendly,
    required this.hasGrocerySpace,
    required this.acceptsCondo,
    required this.rating,
    required this.totalTrips,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      licenseNumber: json['license_number'] as String,
      licensePlate: json['license_plate'] as String,
      vehicleColor: json['vehicle_color'] as String,
      vehicleModel: json['vehicle_model'] as String,
      vehicleBrand: json['vehicle_brand'] as String,
      vehicleYear: json['vehicle_year'] as int,
      vehicleCategory: json['vehicle_category'] as String,
      hasAirConditioning: json['has_air_conditioning'] as bool? ?? false,
      hasPetFriendly: json['has_pet_friendly'] as bool? ?? false,
      hasGrocerySpace: json['has_grocery_space'] as bool? ?? false,
      acceptsCondo: json['accepts_condo'] as bool? ?? false,
      rating: json['rating']?.toDouble() ?? 0.0,
      totalTrips: json['total_trips'] as int? ?? 0,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vehicle_id': vehicleId,
      'license_number': licenseNumber,
      'license_plate': licensePlate,
      'vehicle_color': vehicleColor,
      'vehicle_model': vehicleModel,
      'vehicle_brand': vehicleBrand,
      'vehicle_year': vehicleYear,
      'vehicle_category': vehicleCategory,
      'has_air_conditioning': hasAirConditioning,
      'has_pet_friendly': hasPetFriendly,
      'has_grocery_space': hasGrocerySpace,
      'accepts_condo': acceptsCondo,
      'rating': rating,
      'total_trips': totalTrips,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Driver copyWith({
    String? id,
    String? userId,
    String? vehicleId,
    String? licenseNumber,
    String? licensePlate,
    String? vehicleColor,
    String? vehicleModel,
    String? vehicleBrand,
    int? vehicleYear,
    String? vehicleCategory,
    bool? hasAirConditioning,
    bool? hasPetFriendly,
    bool? hasGrocerySpace,
    bool? acceptsCondo,
    double? rating,
    int? totalTrips,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Driver(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licensePlate: licensePlate ?? this.licensePlate,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      vehicleCategory: vehicleCategory ?? this.vehicleCategory,
      hasAirConditioning: hasAirConditioning ?? this.hasAirConditioning,
      hasPetFriendly: hasPetFriendly ?? this.hasPetFriendly,
      hasGrocerySpace: hasGrocerySpace ?? this.hasGrocerySpace,
      acceptsCondo: acceptsCondo ?? this.acceptsCondo,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods for status checking
  bool get isActive => status == 'active';
  bool get isInactive => status == 'inactive';
  bool get isSuspended => status == 'suspended';
}