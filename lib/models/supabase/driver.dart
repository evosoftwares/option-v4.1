class Driver {

  const Driver({
    required this.id,
    required this.userId,
    required this.cnhNumber,
    required this.cnhExpiryDate,
    this.cnhPhotoUrl,
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.plate,
    required this.category,
    this.crlvPhotoUrl,
    required this.approvalStatus,
    required this.isOnline,
    required this.acceptsPet,
    required this.acceptsGrocery,
    required this.acceptsCondo,
    required this.fees,
    this.acPolicy,
    this.customPricePerKm,
    this.customPricePerMinute,
    this.bankData,
    this.pixData,
    this.currentLatitude,
    this.currentLongitude,
    required this.ratings,
    required this.trips,
    required this.cancellations,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic v) => v == null
        ? null
        : (v is num ? v.toDouble() : double.tryParse(v.toString()));
    double _toDoubleOrZero(dynamic v) =>
        (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;
    int _toIntOrZero(dynamic v) =>
        (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

    return Driver(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cnhNumber: json['cnh_number'] as String,
      cnhExpiryDate: DateTime.parse(json['cnh_expiry_date'] as String),
      cnhPhotoUrl: json['cnh_photo_url'] as String?,
      brand: json['brand'] as String,
      model: json['model'] as String,
      year: _toIntOrZero(json['year']),
      color: json['color'] as String,
      plate: json['plate'] as String,
      category: json['category'] as String,
      crlvPhotoUrl: json['crlv_photo_url'] as String?,
      approvalStatus: json['approval_status'] as String,
      isOnline: json['is_online'] as bool? ?? false,
      acceptsPet: json['accepts_pet'] as bool? ?? false,
      acceptsGrocery: json['accepts_grocery'] as bool? ?? false,
      acceptsCondo: json['accepts_condo'] as bool? ?? false,
      fees: (json['fees'] as Map<String, dynamic>?) ?? const {},
      acPolicy: json['ac_policy'] as String?,
      customPricePerKm: _toDouble(json['custom_price_per_km']),
      customPricePerMinute: _toDouble(json['custom_price_per_minute']),
      bankData: json['bank_data'] as Map<String, dynamic>?,
      pixData: json['pix_data'] as Map<String, dynamic>?,
      currentLatitude: _toDouble(json['current_latitude']),
      currentLongitude: _toDouble(json['current_longitude']),
      ratings: _toDoubleOrZero(json['ratings']),
      trips: _toIntOrZero(json['trips']),
      cancellations: _toIntOrZero(json['cancellations']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  final String id;
  final String userId;
  final String cnhNumber;
  final DateTime cnhExpiryDate;
  final String? cnhPhotoUrl;
  final String brand;
  final String model;
  final int year;
  final String color;
  final String plate;
  final String category;
  final String? crlvPhotoUrl;
  final String approvalStatus;
  final bool isOnline;
  final bool acceptsPet;
  final bool acceptsGrocery;
  final bool acceptsCondo;
  final Map<String, dynamic> fees;
  final String? acPolicy;
  final double? customPricePerKm;
  final double? customPricePerMinute;
  final Map<String, dynamic>? bankData;
  final Map<String, dynamic>? pixData;
  final double? currentLatitude;
  final double? currentLongitude;
  final double ratings;
  final int trips;
  final int cancellations;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
      'id': id,
      'user_id': userId,
      'cnh_number': cnhNumber,
      'cnh_expiry_date': cnhExpiryDate.toIso8601String(),
      'cnh_photo_url': cnhPhotoUrl,
      'brand': brand,
      'model': model,
      'year': year,
      'color': color,
      'plate': plate,
      'category': category,
      'crlv_photo_url': crlvPhotoUrl,
      'approval_status': approvalStatus,
      'is_online': isOnline,
      'accepts_pet': acceptsPet,
      'accepts_grocery': acceptsGrocery,
      'accepts_condo': acceptsCondo,
      'fees': fees,
      'ac_policy': acPolicy,
      'custom_price_per_km': customPricePerKm,
      'custom_price_per_minute': customPricePerMinute,
      'bank_data': bankData,
      'pix_data': pixData,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
      'ratings': ratings,
      'trips': trips,
      'cancellations': cancellations,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

  Driver copyWith({
    String? id,
    String? userId,
    String? cnhNumber,
    DateTime? cnhExpiryDate,
    String? cnhPhotoUrl,
    String? brand,
    String? model,
    int? year,
    String? color,
    String? plate,
    String? category,
    String? crlvPhotoUrl,
    String? approvalStatus,
    bool? isOnline,
    bool? acceptsPet,
    bool? acceptsGrocery,
    bool? acceptsCondo,
    Map<String, dynamic>? fees,
    String? acPolicy,
    double? customPricePerKm,
    double? customPricePerMinute,
    Map<String, dynamic>? bankData,
    Map<String, dynamic>? pixData,
    double? currentLatitude,
    double? currentLongitude,
    double? ratings,
    int? trips,
    int? cancellations,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Driver(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cnhNumber: cnhNumber ?? this.cnhNumber,
      cnhExpiryDate: cnhExpiryDate ?? this.cnhExpiryDate,
      cnhPhotoUrl: cnhPhotoUrl ?? this.cnhPhotoUrl,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      plate: plate ?? this.plate,
      category: category ?? this.category,
      crlvPhotoUrl: crlvPhotoUrl ?? this.crlvPhotoUrl,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      isOnline: isOnline ?? this.isOnline,
      acceptsPet: acceptsPet ?? this.acceptsPet,
      acceptsGrocery: acceptsGrocery ?? this.acceptsGrocery,
      acceptsCondo: acceptsCondo ?? this.acceptsCondo,
      fees: fees ?? this.fees,
      acPolicy: acPolicy ?? this.acPolicy,
      customPricePerKm: customPricePerKm ?? this.customPricePerKm,
      customPricePerMinute: customPricePerMinute ?? this.customPricePerMinute,
      bankData: bankData ?? this.bankData,
      pixData: pixData ?? this.pixData,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      ratings: ratings ?? this.ratings,
      trips: trips ?? this.trips,
      cancellations: cancellations ?? this.cancellations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
}
