class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    required this.isDefault,
    required this.isActive,
    this.cardData,
    this.pixData,
    this.asaasCustomerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentMethod.fromMap(Map<String, dynamic> map) => PaymentMethod(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: PaymentMethodType.fromString(map['type'] as String),
      isDefault: map['is_default'] as bool,
      isActive: map['is_active'] as bool,
      cardData: map['card_data'] != null 
          ? CardData.fromMap(map['card_data'] as Map<String, dynamic>)
          : null,
      pixData: map['pix_data'] != null 
          ? PixData.fromMap(map['pix_data'] as Map<String, dynamic>)
          : null,
      asaasCustomerId: map['asaas_customer_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );

  final String id;
  final String userId;
  final PaymentMethodType type;
  final bool isDefault;
  final bool isActive;
  final CardData? cardData;
  final PixData? pixData;
  final String? asaasCustomerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
      'id': id,
      'user_id': userId,
      'type': type.value,
      'is_default': isDefault,
      'is_active': isActive,
      'card_data': cardData?.toMap(),
      'pix_data': pixData?.toMap(),
      'asaas_customer_id': asaasCustomerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

  PaymentMethod copyWith({
    String? id,
    String? userId,
    PaymentMethodType? type,
    bool? isDefault,
    bool? isActive,
    CardData? cardData,
    PixData? pixData,
    String? asaasCustomerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      cardData: cardData ?? this.cardData,
      pixData: pixData ?? this.pixData,
      asaasCustomerId: asaasCustomerId ?? this.asaasCustomerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );

  String get displayName {
    switch (type) {
      case PaymentMethodType.wallet:
        return 'Carteira Option';
      case PaymentMethodType.creditCard:
        return 'Cartão de Crédito';
      case PaymentMethodType.debitCard:
        return 'Cartão de Débito';
      case PaymentMethodType.pix:
        return 'Pix';
      case PaymentMethodType.cash:
        return 'Dinheiro';
    }
  }

  String get iconPath {
    switch (type) {
      case PaymentMethodType.wallet:
        return 'assets/icons/wallet.svg';
      case PaymentMethodType.creditCard:
        return 'assets/icons/credit_card.svg';
      case PaymentMethodType.debitCard:
        return 'assets/icons/debit_card.svg';
      case PaymentMethodType.pix:
        return 'assets/icons/pix.svg';
      case PaymentMethodType.cash:
        return 'assets/icons/cash.svg';
    }
  }
}

class CardData {
  const CardData({
    required this.cardNumber,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
    required this.holderName,
    required this.brand,
  });

  factory CardData.fromMap(Map<String, dynamic> map) => CardData(
      cardNumber: map['card_number'] as String,
      expiryMonth: map['expiry_month'] as int,
      expiryYear: map['expiry_year'] as int,
      cvv: map['cvv'] as String,
      holderName: map['holder_name'] as String,
      brand: CardBrand.fromString(map['brand'] as String),
    );

  final String cardNumber;
  final int expiryMonth;
  final int expiryYear;
  final String cvv;
  final String holderName;
  final CardBrand brand;

  Map<String, dynamic> toMap() => {
      'card_number': cardNumber,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'cvv': cvv,
      'holder_name': holderName,
      'brand': brand.value,
    };

  CardData copyWith({
    String? cardNumber,
    int? expiryMonth,
    int? expiryYear,
    String? cvv,
    String? holderName,
    CardBrand? brand,
  }) => CardData(
      cardNumber: cardNumber ?? this.cardNumber,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      cvv: cvv ?? this.cvv,
      holderName: holderName ?? this.holderName,
      brand: brand ?? this.brand,
    );

  @override
  String toString() => 'CardData(cardNumber: $cardNumber, expiryMonth: $expiryMonth, expiryYear: $expiryYear, cvv: $cvv, holderName: $holderName, brand: $brand)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CardData &&
        other.cardNumber == cardNumber &&
        other.expiryMonth == expiryMonth &&
        other.expiryYear == expiryYear &&
        other.cvv == cvv &&
        other.holderName == holderName &&
        other.brand == brand;
  }

  @override
  int get hashCode => cardNumber.hashCode ^
      expiryMonth.hashCode ^
      expiryYear.hashCode ^
      cvv.hashCode ^
      holderName.hashCode ^
      brand.hashCode;
}

class PixData {
  const PixData({
    required this.keyType,
    required this.keyValue,
    this.qrCodeData,
  });

  factory PixData.fromMap(Map<String, dynamic> map) => PixData(
      keyType: PixKeyType.fromString(map['key_type'] as String),
      keyValue: map['key_value'] as String,
      qrCodeData: map['qr_code_data'] as String?,
    );

  final PixKeyType keyType;
  final String keyValue;
  final String? qrCodeData;

  Map<String, dynamic> toMap() => {
      'key_type': keyType.value,
      'key_value': keyValue,
      'qr_code_data': qrCodeData,
    };

  String get displayName => '${keyType.displayName}: ${_maskedValue()}';

  String _maskedValue() {
    switch (keyType) {
      case PixKeyType.cpf:
        if (keyValue.length == 11) {
          return '***.***.***-${keyValue.substring(9)}';
        }
        return keyValue;
      case PixKeyType.email:
        final parts = keyValue.split('@');
        if (parts.length == 2) {
          final masked = parts[0].length > 2 
              ? '${parts[0].substring(0, 2)}***'
              : parts[0];
          return '$masked@${parts[1]}';
        }
        return keyValue;
      case PixKeyType.phone:
        if (keyValue.length >= 10) {
          return '(${keyValue.substring(0, 2)}) *****.${keyValue.substring(keyValue.length - 4)}';
        }
        return keyValue;
      case PixKeyType.randomKey:
        return '${keyValue.substring(0, 8)}...';
    }
  }
}

enum PaymentMethodType {
  wallet('wallet'),
  pix('pix'),
  creditCard('credit_card'),
  debitCard('debit_card'),
  cash('cash');

  const PaymentMethodType(this.value);
  final String value;

  static PaymentMethodType fromString(String value) {
    switch (value) {
      case 'wallet':
        return PaymentMethodType.wallet;
      case 'pix':
        return PaymentMethodType.pix;
      case 'credit_card':
        return PaymentMethodType.creditCard;
      case 'debit_card':
        return PaymentMethodType.debitCard;
      case 'cash':
        return PaymentMethodType.cash;
      default:
        throw ArgumentError('Tipo de método de pagamento desconhecido: $value');
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethodType.wallet:
        return 'Carteira Digital';
      case PaymentMethodType.pix:
        return 'PIX';
      case PaymentMethodType.creditCard:
        return 'Cartão de Crédito';
      case PaymentMethodType.debitCard:
        return 'Cartão de Débito';
      case PaymentMethodType.cash:
        return 'Dinheiro';
    }
  }
}

enum CardBrand {
  visa('visa'),
  mastercard('mastercard'),
  elo('elo'),
  amex('amex'),
  other('other');

  const CardBrand(this.value);
  final String value;

  static CardBrand fromString(String value) => values.firstWhere(
      (brand) => brand.value == value,
      orElse: () => CardBrand.other,
    );
}

enum PixKeyType {
  cpf('cpf'),
  email('email'),
  phone('phone'),
  randomKey('random_key');

  const PixKeyType(this.value);
  final String value;

  static PixKeyType fromString(String value) => values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Tipo de chave PIX desconhecido: $value'),
    );

  String get displayName {
    switch (this) {
      case PixKeyType.cpf:
        return 'CPF';
      case PixKeyType.email:
        return 'E-mail';
      case PixKeyType.phone:
        return 'Telefone';
      case PixKeyType.randomKey:
        return 'Chave Aleatória';
    }
  }
}