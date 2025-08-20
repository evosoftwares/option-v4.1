class PromoCode {
  final String id;
  final String code;
  final String description;
  final double discountAmount;
  final String discountType;
  final double? minimumFare;
  final int? maxUses;
  final int? maxUsesPerUser;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  PromoCode({
    required this.id,
    required this.code,
    required this.description,
    required this.discountAmount,
    required this.discountType,
    this.minimumFare,
    this.maxUses,
    this.maxUsesPerUser,
    this.validFrom,
    this.validUntil,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PromoCode.fromJson(Map<String, dynamic> json) {
    return PromoCode(
      id: json['id'] as String,
      code: json['code'] as String,
      description: json['description'] as String,
      discountAmount: json['discount_amount']?.toDouble() ?? 0.0,
      discountType: json['discount_type'] as String,
      minimumFare: json['minimum_fare']?.toDouble(),
      maxUses: json['max_uses'] as int?,
      maxUsesPerUser: json['max_uses_per_user'] as int?,
      validFrom: json['valid_from'] != null 
          ? DateTime.parse(json['valid_from'] as String) 
          : null,
      validUntil: json['valid_until'] != null 
          ? DateTime.parse(json['valid_until'] as String) 
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'discount_amount': discountAmount,
      'discount_type': discountType,
      'minimum_fare': minimumFare,
      'max_uses': maxUses,
      'max_uses_per_user': maxUsesPerUser,
      'valid_from': validFrom?.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PromoCode copyWith({
    String? id,
    String? code,
    String? description,
    double? discountAmount,
    String? discountType,
    double? minimumFare,
    int? maxUses,
    int? maxUsesPerUser,
    DateTime? validFrom,
    DateTime? validUntil,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PromoCode(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      discountAmount: discountAmount ?? this.discountAmount,
      discountType: discountType ?? this.discountType,
      minimumFare: minimumFare ?? this.minimumFare,
      maxUses: maxUses ?? this.maxUses,
      maxUsesPerUser: maxUsesPerUser ?? this.maxUsesPerUser,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isValid {
    if (!isActive) return false;
    
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    
    return true;
  }

  double calculateDiscount(double originalFare) {
    if (discountType == 'percentage') {
      return originalFare * (discountAmount / 100);
    } else if (discountType == 'fixed') {
      return discountAmount;
    }
    return 0.0;
  }
}