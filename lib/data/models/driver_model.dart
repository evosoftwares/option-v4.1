import '../../domain/entities/driver.dart';

class DriverModel extends Driver {
  final String brand;
  final String model;
  final int year;
  final String color;
  final String plate;
  final String approvalStatus;
  final String? approvedBy;
  final DateTime? approvedAt;
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
  final double ratings;
  final int trips;
  final int cancellations;
  final String? fcmToken;
  final String? devicePlatform;
  final DateTime? lastNotificationAt;
  final DateTime? lastLocationUpdate;

  DriverModel({
    required super.id,
    required super.userId,
    required super.fullName,
    required super.email,
    required super.phone,
    required super.licenseNumber,
    required super.licensePlate,
    required super.category,
    required super.isOnline,
    required super.latitude,
    required super.longitude,
    required super.createdAt,
    required super.updatedAt,
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.plate,
    required this.approvalStatus,
    this.approvedBy,
    this.approvedAt,
    required this.acceptsPet,
    required this.acceptsGrocery,
    required this.acceptsCondo,
    required this.petFee,
    required this.groceryFee,
    required this.condoFee,
    required this.stopFee,
    this.acPolicy,
    this.customPricePerKm,
    this.customPricePerMinute,
    this.bankAccountType,
    this.bankCode,
    this.bankAgency,
    this.bankAccount,
    this.pixKey,
    this.pixKeyType,
    required this.ratings,
    required this.trips,
    required this.cancellations,
    this.fcmToken,
    this.devicePlatform,
    this.lastNotificationAt,
    this.lastLocationUpdate,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) => v == null
        ? null
        : (v is num ? v.toDouble() : double.tryParse(v.toString()));
    double toDoubleOrZero(dynamic v) =>
        (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;
    int toIntOrZero(dynamic v) =>
        (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

    return DriverModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      licenseNumber: json['license_number'] as String? ?? '',
      licensePlate: json['license_plate'] as String? ?? '',
      category: json['vehicle_category'] as String? ?? '',
      isOnline: json['is_online'] as bool? ?? false,
      latitude: toDouble(json['current_latitude']) ?? 0.0,
      longitude: toDouble(json['current_longitude']) ?? 0.0,
      brand: json['vehicle_brand'] as String? ?? '',
      model: json['vehicle_model'] as String? ?? '',
      year: toIntOrZero(json['vehicle_year']),
      color: json['vehicle_color'] as String? ?? '',
      plate: json['vehicle_plate'] as String? ?? '',
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
      currentLatitude: toDouble(json['current_latitude']) ?? 0.0,
      currentLongitude: toDouble(json['current_longitude']) ?? 0.0,
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

  Map<String, dynamic> toJson() => {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'license_number': licenseNumber,
      'license_plate': licensePlate,
      'vehicle_category': category,
      'is_online': isOnline,
      'current_latitude': latitude,
      'current_longitude': longitude,
      'vehicle_brand': brand,
      'vehicle_model': model,
      'vehicle_year': year,
      'vehicle_color': color,
      'vehicle_plate': plate,
      'approval_status': approvalStatus,
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
      'average_rating': ratings,
      'total_trips': trips,
      'consecutive_cancellations': cancellations,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'fcm_token': fcmToken,
      'device_platform': devicePlatform,
      'last_notification_at': lastNotificationAt?.toIso8601String(),
    };

  DriverModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? email,
    String? phone,
    String? licenseNumber,
    String? licensePlate,
    String? category,
    bool? isOnline,
    double? latitude,
    double? longitude,
    String? brand,
    String? model,
    int? year,
    String? color,
    String? plate,
    String? approvalStatus,
    String? approvedBy,
    DateTime? approvedAt,
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
    double? ratings,
    int? trips,
    int? cancellations,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fcmToken,
    String? devicePlatform,
    DateTime? lastNotificationAt,
    DateTime? lastLocationUpdate,
  }) => DriverModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licensePlate: licensePlate ?? this.licensePlate,
      category: category ?? this.category,
      isOnline: isOnline ?? this.isOnline,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      plate: plate ?? this.plate,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
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
      ratings: ratings ?? this.ratings,
      trips: trips ?? this.trips,
      cancellations: cancellations ?? this.cancellations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fcmToken: fcmToken ?? this.fcmToken,
      devicePlatform: devicePlatform ?? this.devicePlatform,
      lastNotificationAt: lastNotificationAt ?? this.lastNotificationAt,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
    );
    
  /// Converte para entidade de domínio
  Driver toEntity() => Driver(
    id: id,
    userId: userId,
    fullName: fullName,
    email: email,
    phone: phone,
    licenseNumber: licenseNumber,
    licensePlate: licensePlate,
    category: category,
    isOnline: isOnline,
    latitude: latitude,
    longitude: longitude,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}