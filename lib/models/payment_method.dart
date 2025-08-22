class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    required this.isDefault,
    required this.isActive,
    // this.cardData, // Removido: cartões não são mais suportados
    this.pixData,
    this.asaasCustomerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: PaymentMethodType.fromString(map['type'] as String),
      isDefault: map['is_default'] as bool,
      isActive: map['is_active'] as bool,
      // cardData: Removido - cartões não são mais suportados
      pixData: map['pix_data'] != null 
          ? PixData.fromMap(map['pix_data'] as Map<String, dynamic>)
          : null,
      asaasCustomerId: map['asaas_customer_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  final String id;
  final String userId;
  final PaymentMethodType type;
  final bool isDefault;
  final bool isActive;
  // final CardData? cardData; // Removido: cartões não são mais suportados
  final PixData? pixData;
  final String? asaasCustomerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.value,
      'is_default': isDefault,
      'is_active': isActive,
      // 'card_data': cardData?.toMap(), // Removido: cartões não são mais suportados
      'pix_data': pixData?.toMap(),
      'asaas_customer_id': asaasCustomerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PaymentMethod copyWith({
    String? id,
    String? userId,
    PaymentMethodType? type,
    bool? isDefault,
    bool? isActive,
    // CardData? cardData, // Removido: cartões não são mais suportados
    PixData? pixData,
    String? asaasCustomerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      // cardData: cardData ?? this.cardData, // Removido: cartões não são mais suportados
      pixData: pixData ?? this.pixData,
      asaasCustomerId: asaasCustomerId ?? this.asaasCustomerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName {
    switch (type) {
      case PaymentMethodType.wallet:
        return 'Carteira Option';
      // case PaymentMethodType.creditCard: // Removido: não suportado
      // case PaymentMethodType.debitCard: // Removido: não suportado
      case PaymentMethodType.pix:
        return 'Pix';
    }
  }

  String get iconPath {
    switch (type) {
      case PaymentMethodType.wallet:
        return 'assets/icons/wallet.png';
      // case PaymentMethodType.creditCard: // Removido: não suportado
      // case PaymentMethodType.debitCard: // Removido: não suportado
      case PaymentMethodType.pix:
        return 'assets/icons/pix.png';
    }
  }
}

class CardData {
  const CardData({
    required this.lastFourDigits,
    required this.brand,
    required this.holderName,
    this.expiryMonth,
    this.expiryYear,
    this.asaasCardToken,
  });

  factory CardData.fromMap(Map<String, dynamic> map) {
    return CardData(
      lastFourDigits: map['last_four_digits'] as String,
      brand: CardBrand.fromString(map['brand'] as String),
      holderName: map['holder_name'] as String,
      expiryMonth: map['expiry_month'] as int?,
      expiryYear: map['expiry_year'] as int?,
      asaasCardToken: map['asaas_card_token'] as String?,
    );
  }

  final String lastFourDigits;
  final CardBrand brand;
  final String holderName;
  final int? expiryMonth;
  final int? expiryYear;
  final String? asaasCardToken;

  Map<String, dynamic> toMap() {
    return {
      'last_four_digits': lastFourDigits,
      'brand': brand.value,
      'holder_name': holderName,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'asaas_card_token': asaasCardToken,
    };
  }

  String get displayName => '**** **** **** $lastFourDigits';
  
  String get brandIconPath {
    switch (brand) {
      case CardBrand.visa:
        return 'assets/icons/visa.png';
      case CardBrand.mastercard:
        return 'assets/icons/mastercard.png';
      case CardBrand.elo:
        return 'assets/icons/elo.png';
      case CardBrand.amex:
        return 'assets/icons/amex.png';
      case CardBrand.other:
        return 'assets/icons/credit_card.png';
    }
  }
}

class PixData {
  const PixData({
    required this.keyType,
    required this.keyValue,
    this.qrCodeData,
  });

  factory PixData.fromMap(Map<String, dynamic> map) {
    return PixData(
      keyType: PixKeyType.fromString(map['key_type'] as String),
      keyValue: map['key_value'] as String,
      qrCodeData: map['qr_code_data'] as String?,
    );
  }

  final PixKeyType keyType;
  final String keyValue;
  final String? qrCodeData;

  Map<String, dynamic> toMap() {
    return {
      'key_type': keyType.value,
      'key_value': keyValue,
      'qr_code_data': qrCodeData,
    };
  }

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
  // creditCard('credit_card'), // Removido: não suportado
  // debitCard('debit_card'), // Removido: não suportado
  pix('pix');

  const PaymentMethodType(this.value);
  final String value;

  static PaymentMethodType fromString(String value) {
    return values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Unknown payment method type: $value'),
    );
  }

  String get displayName {
    switch (this) {
      case PaymentMethodType.wallet:
        return 'Carteira';
      // case PaymentMethodType.creditCard: // Removido: não suportado
      // case PaymentMethodType.debitCard: // Removido: não suportado
      case PaymentMethodType.pix:
        return 'Pix';
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

  static CardBrand fromString(String value) {
    return values.firstWhere(
      (brand) => brand.value == value,
      orElse: () => CardBrand.other,
    );
  }
}

enum PixKeyType {
  cpf('cpf'),
  email('email'),
  phone('phone'),
  randomKey('random_key');

  const PixKeyType(this.value);
  final String value;

  static PixKeyType fromString(String value) {
    return values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Unknown PIX key type: $value'),
    );
  }

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