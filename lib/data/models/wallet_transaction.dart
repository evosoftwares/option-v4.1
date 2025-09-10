class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.description,
    this.referenceType,
    this.referenceId,
    this.balanceAfter,
    required this.status,
    required this.createdAt,
  });

  factory WalletTransaction.fromMap(Map<String, dynamic> map) => WalletTransaction(
      id: map['id'] as String,
      walletId: map['wallet_id'] as String,
      type: WalletTransactionType.fromString(map['type'] as String),
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      referenceType: map['reference_type'] as String?,
      referenceId: map['reference_id'] as String?,
      balanceAfter: map['balance_after'] != null 
          ? (map['balance_after'] as num).toDouble() 
          : null,
      status: WalletTransactionStatus.fromString(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );

  final String id;
  final String walletId;
  final WalletTransactionType type;
  final double amount;
  final String description;
  final String? referenceType;
  final String? referenceId;
  final double? balanceAfter;
  final WalletTransactionStatus status;
  final DateTime createdAt;

  /// Indica se a transação é um crédito (valor positivo)
  bool get isCredit => amount > 0;

  /// Indica se a transação é um débito (valor negativo)
  bool get isDebit => amount < 0;

  Map<String, dynamic> toMap() => {
      'id': id,
      'wallet_id': walletId,
      'type': type.value,
      'amount': amount,
      'description': description,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'balance_after': balanceAfter,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
    };

  WalletTransaction copyWith({
    String? id,
    String? walletId,
    WalletTransactionType? type,
    double? amount,
    String? description,
    String? referenceType,
    String? referenceId,
    double? balanceAfter,
    WalletTransactionStatus? status,
    DateTime? createdAt,
  }) => WalletTransaction(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );

  @override
  String toString() => 'WalletTransaction(id: $id, walletId: $walletId, type: $type, amount: $amount, description: $description, status: $status)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WalletTransaction &&
        other.id == id &&
        other.walletId == walletId &&
        other.type == type &&
        other.amount == amount &&
        other.description == description &&
        other.referenceType == referenceType &&
        other.referenceId == referenceId &&
        other.balanceAfter == balanceAfter &&
        other.status == status &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
      id,
      walletId,
      type,
      amount,
      description,
      referenceType,
      referenceId,
      balanceAfter,
      status,
      createdAt,
    );
}

enum WalletTransactionType {
  credit('credit'),
  debit('debit'),
  tripEarning('trip_earning'),
  cancellationCompensation('cancellation_compensation'),
  withdrawal('withdrawal'),
  commission('commission'),
  refund('refund'),
  bonus('bonus'),
  penalty('penalty');

  const WalletTransactionType(this.value);
  final String value;

  static WalletTransactionType fromString(String value) => values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Tipo de transação da carteira desconhecido: $value'),
    );

  String get displayName {
    switch (this) {
      case WalletTransactionType.credit:
        return 'Crédito';
      case WalletTransactionType.debit:
        return 'Débito';
      case WalletTransactionType.tripEarning:
        return 'Ganho de viagem';
      case WalletTransactionType.cancellationCompensation:
        return 'Compensação de cancelamento';
      case WalletTransactionType.withdrawal:
        return 'Saque';
      case WalletTransactionType.commission:
        return 'Comissão';
      case WalletTransactionType.refund:
        return 'Reembolso';
      case WalletTransactionType.bonus:
        return 'Bônus';
      case WalletTransactionType.penalty:
        return 'Penalidade';
    }
  }
}

enum WalletTransactionStatus {
  pending('pending'),
  processing('processing'),
  completed('completed'),
  failed('failed'),
  cancelled('cancelled');

  const WalletTransactionStatus(this.value);
  final String value;

  static WalletTransactionStatus fromString(String value) => values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Status de transação da carteira desconhecido: $value'),
    );

  String get displayName {
    switch (this) {
      case WalletTransactionStatus.pending:
        return 'Pendente';
      case WalletTransactionStatus.processing:
        return 'Processando';
      case WalletTransactionStatus.completed:
        return 'Concluído';
      case WalletTransactionStatus.failed:
        return 'Falhou';
      case WalletTransactionStatus.cancelled:
        return 'Cancelado';
    }
  }
}