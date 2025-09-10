class DriverWallet {
  const DriverWallet({
    required this.id,
    required this.driverId,
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalEarned,
    required this.totalWithdrawn,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverWallet.fromJson(Map<String, dynamic> json) {
    double toDoubleOrZero(dynamic v) =>
        (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

    return DriverWallet(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      availableBalance: toDoubleOrZero(json['available_balance']),
      pendingBalance: toDoubleOrZero(json['pending_balance']),
      totalEarned: toDoubleOrZero(json['total_earned']),
      totalWithdrawn: toDoubleOrZero(json['total_withdrawn']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String driverId;
  final double availableBalance;
  final double pendingBalance;
  final double totalEarned;
  final double totalWithdrawn;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
      'id': id,
      'driver_id': driverId,
      'available_balance': availableBalance,
      'pending_balance': pendingBalance,
      'total_earned': totalEarned,
      'total_withdrawn': totalWithdrawn,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

  DriverWallet copyWith({
    String? id,
    String? driverId,
    double? availableBalance,
    double? pendingBalance,
    double? totalEarned,
    double? totalWithdrawn,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DriverWallet(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      totalEarned: totalEarned ?? this.totalEarned,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
}