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

  factory DriverWallet.fromMap(Map<String, dynamic> map) => DriverWallet(
      id: map['id'] as String,
      driverId: map['driver_id'] as String,
      availableBalance: (map['available_balance'] as num).toDouble(),
      pendingBalance: (map['pending_balance'] as num).toDouble(),
      totalEarned: (map['total_earned'] as num).toDouble(),
      totalWithdrawn: (map['total_withdrawn'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );

  final String id;
  final String driverId;
  final double availableBalance;
  final double pendingBalance;
  final double totalEarned;
  final double totalWithdrawn;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
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

  @override
  String toString() => 'DriverWallet(id: $id, driverId: $driverId, availableBalance: $availableBalance, pendingBalance: $pendingBalance, totalEarned: $totalEarned, totalWithdrawn: $totalWithdrawn)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriverWallet &&
        other.id == id &&
        other.driverId == driverId &&
        other.availableBalance == availableBalance &&
        other.pendingBalance == pendingBalance &&
        other.totalEarned == totalEarned &&
        other.totalWithdrawn == totalWithdrawn &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
      id,
      driverId,
      availableBalance,
      pendingBalance,
      totalEarned,
      totalWithdrawn,
      createdAt,
      updatedAt,
    );
}