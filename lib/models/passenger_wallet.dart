class PassengerWallet {
  const PassengerWallet({
    required this.id,
    required this.passengerId,
    required this.userId,
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalSpent,
    required this.totalCashback,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PassengerWallet.fromMap(Map<String, dynamic> map) {
    return PassengerWallet(
      id: map['id'] as String,
      passengerId: map['passenger_id'] as String,
      userId: map['user_id'] as String,
      availableBalance: (map['available_balance'] as num).toDouble(),
      pendingBalance: (map['pending_balance'] as num).toDouble(),
      totalSpent: (map['total_spent'] as num).toDouble(),
      totalCashback: (map['total_cashback'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  final String id;
  final String passengerId;
  final String userId;
  final double availableBalance;
  final double pendingBalance;
  final double totalSpent;
  final double totalCashback;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'passenger_id': passengerId,
      'user_id': userId,
      'available_balance': availableBalance,
      'pending_balance': pendingBalance,
      'total_spent': totalSpent,
      'total_cashback': totalCashback,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PassengerWallet copyWith({
    String? id,
    String? passengerId,
    String? userId,
    double? availableBalance,
    double? pendingBalance,
    double? totalSpent,
    double? totalCashback,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PassengerWallet(
      id: id ?? this.id,
      passengerId: passengerId ?? this.passengerId,
      userId: userId ?? this.userId,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      totalSpent: totalSpent ?? this.totalSpent,
      totalCashback: totalCashback ?? this.totalCashback,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is PassengerWallet &&
        other.id == id &&
        other.passengerId == passengerId &&
        other.userId == userId &&
        other.availableBalance == availableBalance &&
        other.pendingBalance == pendingBalance &&
        other.totalSpent == totalSpent &&
        other.totalCashback == totalCashback &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        passengerId.hashCode ^
        userId.hashCode ^
        availableBalance.hashCode ^
        pendingBalance.hashCode ^
        totalSpent.hashCode ^
        totalCashback.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'PassengerWallet(id: $id, passengerId: $passengerId, userId: $userId, availableBalance: $availableBalance, pendingBalance: $pendingBalance, totalSpent: $totalSpent, totalCashback: $totalCashback, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}