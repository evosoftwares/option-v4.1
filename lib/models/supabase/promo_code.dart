class PromoCode {

  PromoCode({
    required this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.maxDiscount,
    this.minTripValue,
    this.maxUsesPerUser,
    required this.validFrom,
    required this.validUntil,
    this.usageLimit,
    this.usedCount,
    this.targetCities,
    this.targetCategories,
    this.isFirstTripOnly,
    required this.isActive,
    this.createdBy,
    required this.createdAt,
  });

  factory PromoCode.fromJson(Map<String, dynamic> json) {
    return PromoCode(
      id: json['id'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      discountType: json['discount_type'] as String,
      discountValue: (json['discount_value'] as num).toDouble(),
      maxDiscount: (json['max_discount'] as num?)?.toDouble(),
      minTripValue: (json['min_trip_value'] as num?)?.toDouble(),
      maxUsesPerUser: json['max_uses_per_user'] as int?,
      validFrom: DateTime.parse(json['valid_from'] as String),
      validUntil: DateTime.parse(json['valid_until'] as String),
      usageLimit: json['usage_limit'] as int?,
      usedCount: json['used_count'] as int? ?? 0,
      targetCities: (json['target_cities'] as List?)?.cast<String>(),
      targetCategories: (json['target_categories'] as List?)?.cast<String>(),
      isFirstTripOnly: json['is_first_trip_only'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  final String id;
  final String code;
  final String? description;
  final String discountType;
  final double discountValue;
  final double? maxDiscount;
  final double? minTripValue;
  final int? maxUsesPerUser;
  final DateTime validFrom;
  final DateTime validUntil;
  final int? usageLimit;
  final int? usedCount;
  final List<String>? targetCities;
  final List<String>? targetCategories;
  final bool? isFirstTripOnly;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
      'id': id,
      'code': code,
      'description': description,
      'discount_type': discountType,
      'discount_value': discountValue,
      'max_discount': maxDiscount,
      'min_trip_value': minTripValue,
      'max_uses_per_user': maxUsesPerUser,
      'valid_from': validFrom.toIso8601String(),
      'valid_until': validUntil.toIso8601String(),
      'usage_limit': usageLimit,
      'used_count': usedCount,
      'target_cities': targetCities,
      'target_categories': targetCategories,
      'is_first_trip_only': isFirstTripOnly,
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };

  PromoCode copyWith({
    String? id,
    String? code,
    String? description,
    String? discountType,
    double? discountValue,
    double? maxDiscount,
    double? minTripValue,
    int? maxUsesPerUser,
    DateTime? validFrom,
    DateTime? validUntil,
    int? usageLimit,
    int? usedCount,
    List<String>? targetCities,
    List<String>? targetCategories,
    bool? isFirstTripOnly,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
  }) => PromoCode(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      minTripValue: minTripValue ?? this.minTripValue,
      maxUsesPerUser: maxUsesPerUser ?? this.maxUsesPerUser,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
      targetCities: targetCities ?? this.targetCities,
      targetCategories: targetCategories ?? this.targetCategories,
      isFirstTripOnly: isFirstTripOnly ?? this.isFirstTripOnly,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );

  // Helper methods
  bool get isValid {
    if (!isActive) return false;
    
    final now = DateTime.now();
    if (now.isBefore(validFrom)) return false;
    if (now.isAfter(validUntil)) return false;
    
    // Check usage limit
    if (usageLimit != null && (usedCount ?? 0) >= usageLimit!) return false;
    
    return true;
  }

  bool canBeUsedForTrip(double tripValue, {List<String>? cities, List<String>? categories}) {
    if (!isValid) return false;
    
    // Check minimum trip value
    if (minTripValue != null && tripValue < minTripValue!) return false;
    
    // Check target cities
    if (targetCities != null && targetCities!.isNotEmpty && cities != null) {
      if (!cities.any((city) => targetCities!.contains(city))) return false;
    }
    
    // Check target categories
    if (targetCategories != null && targetCategories!.isNotEmpty && categories != null) {
      if (!categories.any((category) => targetCategories!.contains(category))) return false;
    }
    
    return true;
  }

  double calculateDiscount(double originalFare) {
    if (!isValid) return 0.0;
    
    double discount;
    if (discountType == 'percentage') {
      discount = originalFare * (discountValue / 100);
    } else if (discountType == 'fixed') {
      discount = discountValue;
    } else {
      return 0.0;
    }
    
    // Apply maximum discount limit
    if (maxDiscount != null && discount > maxDiscount!) {
      discount = maxDiscount!;
    }
    
    return discount;
  }

  String get displayDescription {
    switch (discountType) {
      case 'percentage':
        final maxText = maxDiscount != null ? ' (máx. R\$ ${maxDiscount!.toStringAsFixed(2)})' : '';
        return '${discountValue.toStringAsFixed(0)}% de desconto$maxText';
      case 'fixed':
        return 'R\$ ${discountValue.toStringAsFixed(2)} de desconto';
      default:
        return description ?? 'Desconto especial';
    }
  }
}