class PassengerPromoCode {
  const PassengerPromoCode({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    required this.minAmount,
    required this.maxDiscount,
    required this.isActive,
    required this.isFirstRideOnly,
    required this.usageLimit,
    required this.usageCount,
    required this.validFrom,
    required this.validUntil,
    required this.createdAt,
  });

  factory PassengerPromoCode.fromMap(Map<String, dynamic> map) {
    return PassengerPromoCode(
      id: map['id'] as String,
      code: map['code'] as String,
      type: PromoCodeType.fromString(map['type'] as String),
      value: (map['value'] as num).toDouble(),
      minAmount: (map['min_amount'] as num?)?.toDouble() ?? 0.0,
      maxDiscount: (map['max_discount'] as num?)?.toDouble(),
      isActive: map['is_active'] as bool,
      isFirstRideOnly: map['is_first_ride_only'] as bool? ?? false,
      usageLimit: map['usage_limit'] as int?,
      usageCount: map['usage_count'] as int? ?? 0,
      validFrom: DateTime.parse(map['valid_from'] as String),
      validUntil: DateTime.parse(map['valid_until'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  final String id;
  final String code;
  final PromoCodeType type;
  final double value;
  final double minAmount;
  final double? maxDiscount;
  final bool isActive;
  final bool isFirstRideOnly;
  final int? usageLimit;
  final int usageCount;
  final DateTime validFrom;
  final DateTime validUntil;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'type': type.value,
      'value': value,
      'min_amount': minAmount,
      'max_discount': maxDiscount,
      'is_active': isActive,
      'is_first_ride_only': isFirstRideOnly,
      'usage_limit': usageLimit,
      'usage_count': usageCount,
      'valid_from': validFrom.toIso8601String(),
      'valid_until': validUntil.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isValid {
    final now = DateTime.now();
    return isActive && 
           now.isAfter(validFrom) && 
           now.isBefore(validUntil) &&
           (usageLimit == null || usageCount < usageLimit!);
  }

  bool canBeUsedForAmount(double amount) {
    return amount >= minAmount;
  }

  double calculateDiscount(double amount) {
    if (!isValid || !canBeUsedForAmount(amount)) {
      return 0.0;
    }

    double discount;
    switch (type) {
      case PromoCodeType.percentage:
        discount = amount * (value / 100);
        break;
      case PromoCodeType.fixed:
        discount = value;
        break;
      case PromoCodeType.freeRide:
        discount = amount;
        break;
    }

    if (maxDiscount != null && discount > maxDiscount!) {
      discount = maxDiscount!;
    }

    return discount;
  }

  String get displayDescription {
    switch (type) {
      case PromoCodeType.percentage:
        final maxText = maxDiscount != null ? ' (máx. R\$ ${maxDiscount!.toStringAsFixed(2)})' : '';
        return '${value.toStringAsFixed(0)}% de desconto$maxText';
      case PromoCodeType.fixed:
        return 'R\$ ${value.toStringAsFixed(2)} de desconto';
      case PromoCodeType.freeRide:
        return 'Viagem grátis';
    }
  }

  PassengerPromoCode copyWith({
    String? id,
    String? code,
    PromoCodeType? type,
    double? value,
    double? minAmount,
    double? maxDiscount,
    bool? isActive,
    bool? isFirstRideOnly,
    int? usageLimit,
    int? usageCount,
    DateTime? validFrom,
    DateTime? validUntil,
    DateTime? createdAt,
  }) {
    return PassengerPromoCode(
      id: id ?? this.id,
      code: code ?? this.code,
      type: type ?? this.type,
      value: value ?? this.value,
      minAmount: minAmount ?? this.minAmount,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      isActive: isActive ?? this.isActive,
      isFirstRideOnly: isFirstRideOnly ?? this.isFirstRideOnly,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum PromoCodeType {
  percentage('percentage'),
  fixed('fixed'),
  freeRide('free_ride');

  const PromoCodeType(this.value);
  final String value;

  static PromoCodeType fromString(String value) {
    return values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Unknown promo code type: $value'),
    );
  }

  String get displayName {
    switch (this) {
      case PromoCodeType.percentage:
        return 'Percentual';
      case PromoCodeType.fixed:
        return 'Valor fixo';
      case PromoCodeType.freeRide:
        return 'Viagem grátis';
    }
  }
}

class PassengerPromoCodeUsage {
  const PassengerPromoCodeUsage({
    required this.id,
    required this.userId,
    required this.promoCodeId,
    required this.tripId,
    required this.originalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.usedAt,
  });

  factory PassengerPromoCodeUsage.fromMap(Map<String, dynamic> map) {
    return PassengerPromoCodeUsage(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      promoCodeId: map['promo_code_id'] as String,
      tripId: map['trip_id'] as String?,
      originalAmount: (map['original_amount'] as num).toDouble(),
      discountAmount: (map['discount_amount'] as num).toDouble(),
      finalAmount: (map['final_amount'] as num).toDouble(),
      usedAt: DateTime.parse(map['used_at'] as String),
    );
  }

  final String id;
  final String userId;
  final String promoCodeId;
  final String? tripId;
  final double originalAmount;
  final double discountAmount;
  final double finalAmount;
  final DateTime usedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'promo_code_id': promoCodeId,
      'trip_id': tripId,
      'original_amount': originalAmount,
      'discount_amount': discountAmount,
      'final_amount': finalAmount,
      'used_at': usedAt.toIso8601String(),
    };
  }

  double get savingsPercentage => (discountAmount / originalAmount) * 100;

  String get formattedSavings => 'Você economizou R\$ ${discountAmount.toStringAsFixed(2)} (${savingsPercentage.toStringAsFixed(0)}%)';
}