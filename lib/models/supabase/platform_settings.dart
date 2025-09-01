class PlatformSettings {
  const PlatformSettings({
    required this.id,
    required this.category,
    required this.basePricePerKm,
    required this.basePricePerMinute,
    required this.platformCommissionPercent,
    required this.minFare,
    required this.minCancellationFee,
    required this.cancellationFeePercent,
    required this.noShowWaitMinutes,
    required this.driverAcceptanceTimeoutSeconds,
    required this.searchRadiusKm,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlatformSettings.fromJson(Map<String, dynamic> json) {
    double toDoubleOrZero(dynamic v) =>
        (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;
    int toIntOrZero(dynamic v) =>
        (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

    return PlatformSettings(
      id: json['id'] as String,
      category: json['category'] as String,
      basePricePerKm: toDoubleOrZero(json['base_price_per_km']),
      basePricePerMinute: toDoubleOrZero(json['base_price_per_minute']),
      platformCommissionPercent: toDoubleOrZero(json['platform_commission_percent']),
      minFare: toDoubleOrZero(json['min_fare']),
      minCancellationFee: toDoubleOrZero(json['min_cancellation_fee']),
      cancellationFeePercent: toDoubleOrZero(json['cancellation_fee_percent']),
      noShowWaitMinutes: toIntOrZero(json['no_show_wait_minutes']),
      driverAcceptanceTimeoutSeconds: toIntOrZero(json['driver_acceptance_timeout_seconds']),
      searchRadiusKm: toIntOrZero(json['search_radius_km']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String category;
  final double basePricePerKm;
  final double basePricePerMinute;
  final double platformCommissionPercent;
  final double minFare;
  final double minCancellationFee;
  final double cancellationFeePercent;
  final int noShowWaitMinutes;
  final int driverAcceptanceTimeoutSeconds;
  final int searchRadiusKm;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
      'id': id,
      'category': category,
      'base_price_per_km': basePricePerKm,
      'base_price_per_minute': basePricePerMinute,
      'platform_commission_percent': platformCommissionPercent,
      'min_fare': minFare,
      'min_cancellation_fee': minCancellationFee,
      'cancellation_fee_percent': cancellationFeePercent,
      'no_show_wait_minutes': noShowWaitMinutes,
      'driver_acceptance_timeout_seconds': driverAcceptanceTimeoutSeconds,
      'search_radius_km': searchRadiusKm,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

  PlatformSettings copyWith({
    String? id,
    String? category,
    double? basePricePerKm,
    double? basePricePerMinute,
    double? platformCommissionPercent,
    double? minFare,
    double? minCancellationFee,
    double? cancellationFeePercent,
    int? noShowWaitMinutes,
    int? driverAcceptanceTimeoutSeconds,
    int? searchRadiusKm,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PlatformSettings(
      id: id ?? this.id,
      category: category ?? this.category,
      basePricePerKm: basePricePerKm ?? this.basePricePerKm,
      basePricePerMinute: basePricePerMinute ?? this.basePricePerMinute,
      platformCommissionPercent: platformCommissionPercent ?? this.platformCommissionPercent,
      minFare: minFare ?? this.minFare,
      minCancellationFee: minCancellationFee ?? this.minCancellationFee,
      cancellationFeePercent: cancellationFeePercent ?? this.cancellationFeePercent,
      noShowWaitMinutes: noShowWaitMinutes ?? this.noShowWaitMinutes,
      driverAcceptanceTimeoutSeconds: driverAcceptanceTimeoutSeconds ?? this.driverAcceptanceTimeoutSeconds,
      searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
}