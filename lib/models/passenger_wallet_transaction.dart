class PassengerWalletTransaction {
  const PassengerWalletTransaction({
    required this.id,
    required this.walletId,
    required this.passengerId,
    required this.type,
    required this.amount,
    required this.description,
    this.tripId,
    this.paymentMethodId,
    this.asaasPaymentId,
    required this.status,
    this.metadata,
    required this.createdAt,
    this.processedAt,
  });

  factory PassengerWalletTransaction.fromMap(Map<String, dynamic> map) {
    return PassengerWalletTransaction(
      id: map['id'] as String,
      walletId: map['wallet_id'] as String,
      passengerId: map['passenger_id'] as String,
      type: TransactionType.fromString(map['type'] as String),
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      tripId: map['trip_id'] as String?,
      paymentMethodId: map['payment_method_id'] as String?,
      asaasPaymentId: map['asaas_payment_id'] as String?,
      status: TransactionStatus.fromString(map['status'] as String),
      metadata: map['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(map['created_at'] as String),
      processedAt: map['processed_at'] != null 
          ? DateTime.parse(map['processed_at'] as String)
          : null,
    );
  }

  final String id;
  final String walletId;
  final String passengerId;
  final TransactionType type;
  final double amount;
  final String description;
  final String? tripId;
  final String? paymentMethodId;
  final String? asaasPaymentId;
  final TransactionStatus status;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? processedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'wallet_id': walletId,
      'passenger_id': passengerId,
      'type': type.value,
      'amount': amount,
      'description': description,
      'trip_id': tripId,
      'payment_method_id': paymentMethodId,
      'asaas_payment_id': asaasPaymentId,
      'status': status.value,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
    };
  }

  PassengerWalletTransaction copyWith({
    String? id,
    String? walletId,
    String? passengerId,
    TransactionType? type,
    double? amount,
    String? description,
    String? tripId,
    String? paymentMethodId,
    String? asaasPaymentId,
    TransactionStatus? status,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? processedAt,
  }) {
    return PassengerWalletTransaction(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      passengerId: passengerId ?? this.passengerId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      tripId: tripId ?? this.tripId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      asaasPaymentId: asaasPaymentId ?? this.asaasPaymentId,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  bool get isCredit => type == TransactionType.credit || type == TransactionType.cashback || type == TransactionType.refund;
  bool get isDebit => type == TransactionType.tripPayment || type == TransactionType.cancellationFee;

  String get formattedAmount {
    final prefix = isCredit ? '+ R\$ ' : '- R\$ ';
    return '$prefix${amount.toStringAsFixed(2)}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is PassengerWalletTransaction &&
        other.id == id &&
        other.walletId == walletId &&
        other.passengerId == passengerId &&
        other.type == type &&
        other.amount == amount &&
        other.description == description &&
        other.tripId == tripId &&
        other.paymentMethodId == paymentMethodId &&
        other.asaasPaymentId == asaasPaymentId &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.processedAt == processedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        walletId.hashCode ^
        passengerId.hashCode ^
        type.hashCode ^
        amount.hashCode ^
        description.hashCode ^
        tripId.hashCode ^
        paymentMethodId.hashCode ^
        asaasPaymentId.hashCode ^
        status.hashCode ^
        createdAt.hashCode ^
        processedAt.hashCode;
  }

  @override
  String toString() {
    return 'PassengerWalletTransaction(id: $id, walletId: $walletId, passengerId: $passengerId, type: $type, amount: $amount, description: $description, status: $status, createdAt: $createdAt)';
  }
}

enum TransactionType {
  credit('credit'),
  tripPayment('trip_payment'),
  cashback('cashback'),
  refund('refund'),
  cancellationFee('cancellation_fee');

  const TransactionType(this.value);
  final String value;

  static TransactionType fromString(String value) {
    return values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Unknown transaction type: $value'),
    );
  }

  String get displayName {
    switch (this) {
      case TransactionType.credit:
        return 'Recarga';
      case TransactionType.tripPayment:
        return 'Pagamento de viagem';
      case TransactionType.cashback:
        return 'Cashback';
      case TransactionType.refund:
        return 'Reembolso';
      case TransactionType.cancellationFee:
        return 'Taxa de cancelamento';
    }
  }
}

enum TransactionStatus {
  pending('pending'),
  processing('processing'),
  completed('completed'),
  failed('failed'),
  cancelled('cancelled');

  const TransactionStatus(this.value);
  final String value;

  static TransactionStatus fromString(String value) {
    return values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Unknown transaction status: $value'),
    );
  }

  String get displayName {
    switch (this) {
      case TransactionStatus.pending:
        return 'Pendente';
      case TransactionStatus.processing:
        return 'Processando';
      case TransactionStatus.completed:
        return 'Concluído';
      case TransactionStatus.failed:
        return 'Falhou';
      case TransactionStatus.cancelled:
        return 'Cancelado';
    }
  }
}