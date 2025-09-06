class Driver {

  const Driver({
    required this.id,
    required this.userId,
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.plate,
    required this.category,
    this.approvalStatus = 'pending',
    this.approvedBy,
    this.approvedAt,
    this.isOnline = false,
    this.acceptsPet = false,
    this.petFee = 0.0,
    this.acceptsGrocery = false,
    this.groceryFee = 0.0,
    this.acceptsCondo = false,
    this.condoFee = 0.0,
    this.stopFee = 0.0,
    this.acPolicy,
    this.customPricePerKm,
    this.customPricePerMinute,
    this.bankAccountType,
    this.bankCode,
    this.bankAgency,
    this.bankAccount,
    this.pixKey,
    this.pixKeyType,
    this.currentLatitude,
    this.currentLongitude,
    this.lastLocationUpdate,
    this.ratings = 0.0,
    this.trips = 0,
    this.cancellations = 0,
    required this.createdAt,
    required this.updatedAt,
    this.fcmToken,
    this.devicePlatform,
    this.lastNotificationAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) => v == null
        ? null
        : (v is num ? v.toDouble() : double.tryParse(v.toString()));
    double toDoubleOrZero(dynamic v) =>
        (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;
    int toIntOrZero(dynamic v) =>
        (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

    return Driver(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      brand: json['vehicle_brand'] as String? ?? '',
      model: json['vehicle_model'] as String? ?? '',
      year: toIntOrZero(json['vehicle_year']),
      color: json['vehicle_color'] as String? ?? '',
      plate: json['vehicle_plate'] as String? ?? '',
      category: json['vehicle_category'] as String? ?? '',
      approvalStatus: json['approval_status'] as String? ?? 'pending',
      isOnline: json['is_online'] as bool? ?? false,
      acceptsPet: json['accepts_pet'] as bool? ?? false,
      acceptsGrocery: json['accepts_grocery'] as bool? ?? false,
      acceptsCondo: json['accepts_condo'] as bool? ?? false,
      petFee: toDoubleOrZero(json['pet_fee']),
      groceryFee: toDoubleOrZero(json['grocery_fee']),
      condoFee: toDoubleOrZero(json['condo_fee']),
      stopFee: toDoubleOrZero(json['stop_fee']),
      acPolicy: json['ac_policy'] as String?,
      customPricePerKm: toDouble(json['custom_price_per_km']),
      customPricePerMinute: toDouble(json['custom_price_per_minute']),
      bankAccountType: json['bank_account_type'] as String?,
      bankCode: json['bank_code'] as String?,
      bankAgency: json['bank_agency'] as String?,
      bankAccount: json['bank_account'] as String?,
      pixKey: json['pix_key'] as String?,
      pixKeyType: json['pix_key_type'] as String?,
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null 
          ? DateTime.parse(json['approved_at'] as String) 
          : null,
      currentLatitude: toDouble(json['current_latitude']),
      currentLongitude: toDouble(json['current_longitude']),
      lastLocationUpdate: json['last_location_update'] != null 
          ? DateTime.parse(json['last_location_update'] as String) 
          : null,
      ratings: toDoubleOrZero(json['average_rating']),
      trips: toIntOrZero(json['total_trips']),
      cancellations: toIntOrZero(json['consecutive_cancellations']),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      fcmToken: json['fcm_token'] as String?,
      devicePlatform: json['device_platform'] as String?,
      lastNotificationAt: json['last_notification_at'] != null 
          ? DateTime.parse(json['last_notification_at'] as String) 
          : null,
    );
  }
  final String id;
  final String userId;
  final String brand;
  final String model;
  final int year;
  final String color;
  final String plate;
  final String category;
  final String approvalStatus;
  final bool isOnline;
  final bool acceptsPet;
  final bool acceptsGrocery;
  final bool acceptsCondo;
  final double petFee;
  final double groceryFee;
  final double condoFee;
  final double stopFee;
  final String? acPolicy;
  final double? customPricePerKm;
  final double? customPricePerMinute;
  final String? bankAccountType;
  final String? bankCode;
  final String? bankAgency;
  final String? bankAccount;
  final String? pixKey;
  final String? pixKeyType;
  final String? approvedBy;
  final DateTime? approvedAt;
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? lastLocationUpdate;
  final double ratings;
  final int trips;
  final int cancellations;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fcmToken;
  final String? devicePlatform;
  final DateTime? lastNotificationAt;

  Map<String, dynamic> toJson() => {
      'id': id,
      'user_id': userId,
      'vehicle_brand': brand,
      'vehicle_model': model,
      'vehicle_year': year,
      'vehicle_color': color,
      'vehicle_plate': plate,
      'vehicle_category': category,
      'approval_status': approvalStatus,
      'is_online': isOnline,
      'accepts_pet': acceptsPet,
      'accepts_grocery': acceptsGrocery,
      'accepts_condo': acceptsCondo,
      'pet_fee': petFee,
      'grocery_fee': groceryFee,
      'condo_fee': condoFee,
      'stop_fee': stopFee,
      'ac_policy': acPolicy,
      'custom_price_per_km': customPricePerKm,
      'custom_price_per_minute': customPricePerMinute,
      'bank_account_type': bankAccountType,
      'bank_code': bankCode,
      'bank_agency': bankAgency,
      'bank_account': bankAccount,
      'pix_key': pixKey,
      'pix_key_type': pixKeyType,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
      'last_location_update': lastLocationUpdate?.toIso8601String(),
      'average_rating': ratings,
      'total_trips': trips,
      'consecutive_cancellations': cancellations,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'fcm_token': fcmToken,
      'device_platform': devicePlatform,
      'last_notification_at': lastNotificationAt?.toIso8601String(),
    };

  Driver copyWith({
    String? id,
    String? userId,
    String? brand,
    String? model,
    int? year,
    String? color,
    String? plate,
    String? category,
    String? approvalStatus,
    String? approvedBy,
    DateTime? approvedAt,
    bool? isOnline,
    bool? acceptsPet,
    double? petFee,
    bool? acceptsGrocery,
    double? groceryFee,
    bool? acceptsCondo,
    double? condoFee,
    double? stopFee,
    String? acPolicy,
    double? customPricePerKm,
    double? customPricePerMinute,
    String? bankAccountType,
    String? bankCode,
    String? bankAgency,
    String? bankAccount,
    String? pixKey,
    String? pixKeyType,
    double? currentLatitude,
    double? currentLongitude,
    DateTime? lastLocationUpdate,
    double? ratings,
    int? trips,
    int? cancellations,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fcmToken,
    String? devicePlatform,
    DateTime? lastNotificationAt,
  }) => Driver(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      plate: plate ?? this.plate,
      category: category ?? this.category,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      isOnline: isOnline ?? this.isOnline,
      acceptsPet: acceptsPet ?? this.acceptsPet,
      petFee: petFee ?? this.petFee,
      acceptsGrocery: acceptsGrocery ?? this.acceptsGrocery,
      groceryFee: groceryFee ?? this.groceryFee,
      acceptsCondo: acceptsCondo ?? this.acceptsCondo,
      condoFee: condoFee ?? this.condoFee,
      stopFee: stopFee ?? this.stopFee,
      acPolicy: acPolicy ?? this.acPolicy,
      customPricePerKm: customPricePerKm ?? this.customPricePerKm,
      customPricePerMinute: customPricePerMinute ?? this.customPricePerMinute,
      bankAccountType: bankAccountType ?? this.bankAccountType,
      bankCode: bankCode ?? this.bankCode,
      bankAgency: bankAgency ?? this.bankAgency,
      bankAccount: bankAccount ?? this.bankAccount,
      pixKey: pixKey ?? this.pixKey,
      pixKeyType: pixKeyType ?? this.pixKeyType,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      ratings: ratings ?? this.ratings,
      trips: trips ?? this.trips,
      cancellations: cancellations ?? this.cancellations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fcmToken: fcmToken ?? this.fcmToken,
      devicePlatform: devicePlatform ?? this.devicePlatform,
      lastNotificationAt: lastNotificationAt ?? this.lastNotificationAt,
    );
}
