import '../exceptions/validation_exception.dart';

/// Validador que implementa as constraints do banco de dados
/// 
/// Garante que os dados atendam às regras de integridade antes da inserção
class DatabaseConstraintsValidator {
  
  // =============================================================================
  // CONSTRAINTS DA TABELA APP_USERS
  // =============================================================================
  
  /// Valida constraints da tabela app_users
  static void validateAppUser(Map<String, dynamic> data) {
    _validateUserId(data['user_id']);
    _validateEmail(data['email']);
    _validateFullName(data['full_name']);
    _validatePhone(data['phone']);
    _validateUserType(data['user_type']);
    _validateStatus(data['status']);
    _validatePhotoUrl(data['photo_url']);
    _validateBooleanField(data['is_active'], 'is_active');
    _validateBooleanField(data['is_verified'], 'is_verified');
  }
  
  /// Valida apenas o campo email
  static void validateEmailField(String email) {
    _validateEmail(email);
  }
  
  /// Valida apenas o campo full_name
  static void validateFullNameField(String fullName) {
    _validateFullName(fullName);
  }
  
  /// Valida user_id (UUID, NOT NULL)
  static void _validateUserId(dynamic userId) {
    if (userId == null) {
      throw const ValidationException('user_id é obrigatório');
    }
    
    final userIdStr = userId.toString();
    
    // Validar formato UUID
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false
    );
    
    if (!uuidRegex.hasMatch(userIdStr)) {
      throw ValidationException('user_id deve ser um UUID válido: $userIdStr');
    }
  }
  
  /// Valida email (VARCHAR(255), NOT NULL, UNIQUE)
  static void _validateEmail(dynamic email) {
    if (email == null) {
      throw const ValidationException('email é obrigatório');
    }
    
    final emailStr = email.toString().trim();
    
    if (emailStr.isEmpty) {
      throw const ValidationException('email não pode estar vazio');
    }
    
    if (emailStr.length > 255) {
      throw ValidationException('email não pode ter mais de 255 caracteres: ${emailStr.length}');
    }
    
    // Validar formato de email
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(emailStr)) {
      throw ValidationException('formato de email inválido: $emailStr');
    }
  }
  
  /// Valida full_name (VARCHAR(100), NOT NULL)
  static void _validateFullName(dynamic fullName) {
    if (fullName == null) {
      throw const ValidationException('full_name é obrigatório');
    }
    
    final nameStr = fullName.toString().trim();
    
    if (nameStr.isEmpty) {
      throw const ValidationException('full_name não pode estar vazio');
    }
    
    if (nameStr.length > 100) {
      throw ValidationException('full_name não pode ter mais de 100 caracteres: ${nameStr.length}');
    }
    
    // Validar caracteres permitidos (apenas letras, espaços, acentos)
    final nameRegex = RegExp(r'^[a-zA-ZÀ-ÿ\s]+$');
    if (!nameRegex.hasMatch(nameStr)) {
      throw ValidationException('full_name contém caracteres inválidos: $nameStr');
    }
  }
  
  /// Valida phone (VARCHAR(20), pode ser NULL)
  static void _validatePhone(dynamic phone) {
    if (phone == null) return; // Campo opcional
    
    final phoneStr = phone.toString().trim();
    
    if (phoneStr.isEmpty) return; // Vazio é permitido
    
    if (phoneStr.length > 20) {
      throw ValidationException('phone não pode ter mais de 20 caracteres: ${phoneStr.length}');
    }
    
    // Validar formato brasileiro (apenas números, parênteses, espaços, hífens)
    final phoneRegex = RegExp(r'^[\d\s\(\)\-\+]+$');
    if (!phoneRegex.hasMatch(phoneStr)) {
      throw ValidationException('phone contém caracteres inválidos: $phoneStr');
    }
  }
  
  /// Valida user_type (ENUM: passenger, driver, admin)
  static void _validateUserType(dynamic userType) {
    if (userType == null) {
      throw const ValidationException('user_type é obrigatório');
    }
    
    final typeStr = userType.toString().toLowerCase().trim();
    
    const validTypes = ['passenger', 'driver', 'admin'];
    if (!validTypes.contains(typeStr)) {
      throw ValidationException(
        'user_type inválido: $typeStr. Valores permitidos: ${validTypes.join(", ")}'
      );
    }
  }
  
  /// Valida status (ENUM: active, inactive, suspended, pending)
  static void _validateStatus(dynamic status) {
    if (status == null) return; // Campo opcional com default
    
    final statusStr = status.toString().toLowerCase().trim();
    
    const validStatuses = ['active', 'inactive', 'suspended', 'pending'];
    if (!validStatuses.contains(statusStr)) {
      throw ValidationException(
        'status inválido: $statusStr. Valores permitidos: ${validStatuses.join(", ")}'
      );
    }
  }
  
  /// Valida photo_url (TEXT, pode ser NULL)
  static void _validatePhotoUrl(dynamic photoUrl) {
    if (photoUrl == null) return; // Campo opcional
    
    final urlStr = photoUrl.toString().trim();
    
    if (urlStr.isEmpty) return; // Vazio é permitido
    
    // Validar formato de URL básico
    final urlRegex = RegExp(r'^https?:\/\/.+');
    if (!urlRegex.hasMatch(urlStr)) {
      throw ValidationException('photo_url deve ser uma URL válida: $urlStr');
    }
  }
  
  /// Valida campos booleanos
  static void _validateBooleanField(dynamic value, String fieldName) {
    if (value == null) return; // Campos booleanos têm defaults
    
    if (value is! bool && value.toString().toLowerCase() != 'true' && value.toString().toLowerCase() != 'false') {
      throw ValidationException('$fieldName deve ser um valor booleano: $value');
    }
  }
  
  // =============================================================================
  // CONSTRAINTS DA TABELA DRIVERS
  // =============================================================================
  
  /// Valida constraints da tabela drivers
  static void validateDriver(Map<String, dynamic> data) {
    _validateUserId(data['user_id']); // FK para app_users
    _validateCnhNumber(data['cnh_number']);
    _validateCnhExpiryDate(data['cnh_expiry_date']);
    _validateVehicleData(data);
    _validateApprovalStatus(data['approval_status']);
    _validateDriverBooleans(data);
    _validateDriverFees(data);
    _validateBankData(data);
    _validatePixData(data);
    _validateLocationData(data);
    _validateRatingsAndTrips(data);
  }
  
  /// Valida cnh_number (VARCHAR(20), NOT NULL, UNIQUE)
  static void _validateCnhNumber(dynamic cnhNumber) {
    if (cnhNumber == null) {
      throw const ValidationException('cnh_number é obrigatório');
    }
    
    final cnhStr = cnhNumber.toString().trim();
    
    if (cnhStr.isEmpty) {
      throw const ValidationException('cnh_number não pode estar vazio');
    }
    
    if (cnhStr.length > 20) {
      throw ValidationException('cnh_number não pode ter mais de 20 caracteres: ${cnhStr.length}');
    }
    
    // CNH brasileira tem 11 dígitos
    final digitsOnly = cnhStr.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length != 11) {
      throw ValidationException('cnh_number deve ter 11 dígitos: $cnhStr');
    }
  }
  
  /// Valida cnh_expiry_date (DATE, NOT NULL)
  static void _validateCnhExpiryDate(dynamic expiryDate) {
    if (expiryDate == null) {
      throw const ValidationException('cnh_expiry_date é obrigatório');
    }
    
    DateTime? date;
    
    if (expiryDate is String) {
      try {
        date = DateTime.parse(expiryDate);
      } catch (e) {
        throw ValidationException('cnh_expiry_date deve ser uma data válida: $expiryDate');
      }
    } else if (expiryDate is DateTime) {
      date = expiryDate;
    } else {
      throw ValidationException('cnh_expiry_date deve ser uma data: $expiryDate');
    }
    
    // CNH não pode estar vencida
    if (date.isBefore(DateTime.now())) {
      throw ValidationException('cnh_expiry_date não pode estar vencida: ${date.toIso8601String()}');
    }
  }
  
  /// Valida dados do veículo
  static void _validateVehicleData(Map<String, dynamic> data) {
    _validateVehicleField(data['vehicle_brand'], 'vehicle_brand', 50);
    _validateVehicleField(data['vehicle_model'], 'vehicle_model', 50);
    _validateVehicleYear(data['vehicle_year']);
    _validateVehicleField(data['vehicle_color'], 'vehicle_color', 30);
    _validateVehiclePlate(data['vehicle_plate']);
    _validateVehicleCategory(data['vehicle_category']);
  }
  
  /// Valida campos de texto do veículo
  static void _validateVehicleField(dynamic value, String fieldName, int maxLength) {
    if (value == null) {
      throw ValidationException('$fieldName é obrigatório');
    }
    
    final valueStr = value.toString().trim();
    
    if (valueStr.isEmpty) {
      throw ValidationException('$fieldName não pode estar vazio');
    }
    
    if (valueStr.length > maxLength) {
      throw ValidationException('$fieldName não pode ter mais de $maxLength caracteres: ${valueStr.length}');
    }
  }
  
  /// Valida ano do veículo
  static void _validateVehicleYear(dynamic year) {
    if (year == null) {
      throw const ValidationException('vehicle_year é obrigatório');
    }
    
    int? yearInt;
    
    if (year is String) {
      yearInt = int.tryParse(year);
    } else if (year is int) {
      yearInt = year;
    }
    
    if (yearInt == null) {
      throw ValidationException('vehicle_year deve ser um número: $year');
    }
    
    final currentYear = DateTime.now().year;
    
    if (yearInt < 1990 || yearInt > currentYear + 1) {
      throw ValidationException('vehicle_year deve estar entre 1990 e ${currentYear + 1}: $yearInt');
    }
  }
  
  /// Valida placa do veículo
  static void _validateVehiclePlate(dynamic plate) {
    if (plate == null) {
      throw const ValidationException('Placa é obrigatória');
    }
    
    final plateStr = plate.toString().trim();
    
    if (plateStr.isEmpty) {
      throw const ValidationException('Placa não pode estar vazia');
    }
    
    // Limpar formatação (hífens, espaços) e converter para maiúscula
    final cleanPlate = plateStr.replaceAll(RegExp(r'[^A-Z0-9]'), '').toUpperCase();
    
    if (cleanPlate.length != 7) {
      throw ValidationException('Placa deve ter exatamente 7 caracteres (ex: ABC1234)');
    }
    
    // Formato brasileiro: ABC1234 ou ABC1D23 (Mercosul)
    final plateRegex = RegExp(r'^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$');
    if (!plateRegex.hasMatch(cleanPlate)) {
      throw ValidationException('Formato de placa inválido. Use ABC1234 ou ABC1D23');
    }
  }
  
  /// Valida categoria do veículo
  static void _validateVehicleCategory(dynamic category) {
    if (category == null) {
      throw const ValidationException('vehicle_category é obrigatório');
    }
    
    final categoryStr = category.toString().toLowerCase().trim();
    
    const validCategories = ['economico', 'standard', 'premium', 'suv', 'executivo', 'van'];
    if (!validCategories.contains(categoryStr)) {
      throw ValidationException(
        'vehicle_category inválido: $categoryStr. Valores permitidos: ${validCategories.join(", ")}'
      );
    }
  }
  
  /// Valida approval_status
  static void _validateApprovalStatus(dynamic status) {
    if (status == null) return; // Tem default
    
    final statusStr = status.toString().toLowerCase().trim();
    
    const validStatuses = ['pending', 'approved', 'rejected', 'under_review'];
    if (!validStatuses.contains(statusStr)) {
      throw ValidationException(
        'approval_status inválido: $statusStr. Valores permitidos: ${validStatuses.join(", ")}'
      );
    }
  }
  
  /// Valida campos booleanos do driver
  static void _validateDriverBooleans(Map<String, dynamic> data) {
    _validateBooleanField(data['is_online'], 'is_online');
    _validateBooleanField(data['accepts_pet'], 'accepts_pet');
    _validateBooleanField(data['accepts_grocery'], 'accepts_grocery');
    _validateBooleanField(data['accepts_condo'], 'accepts_condo');
  }
  
  /// Valida taxas do driver
  static void _validateDriverFees(Map<String, dynamic> data) {
    _validateMoneyField(data['pet_fee'], 'pet_fee');
    _validateMoneyField(data['grocery_fee'], 'grocery_fee');
    _validateMoneyField(data['condo_fee'], 'condo_fee');
    _validateMoneyField(data['stop_fee'], 'stop_fee');
    _validateMoneyField(data['custom_price_per_km'], 'custom_price_per_km');
    _validateMoneyField(data['custom_price_per_minute'], 'custom_price_per_minute');
  }
  
  /// Valida campos monetários
  static void _validateMoneyField(dynamic value, String fieldName) {
    if (value == null) return; // Campos monetários são opcionais
    
    double? amount;
    
    if (value is String) {
      amount = double.tryParse(value);
    } else if (value is num) {
      amount = value.toDouble();
    }
    
    if (amount == null) {
      throw ValidationException('$fieldName deve ser um número: $value');
    }
    
    if (amount < 0) {
      throw ValidationException('$fieldName não pode ser negativo: $amount');
    }
    
    if (amount > 999.99) {
      throw ValidationException('$fieldName não pode ser maior que R\$ 999,99: $amount');
    }
  }
  
  /// Valida dados bancários
  static void _validateBankData(Map<String, dynamic> data) {
    final bankCode = data['bank_code'];
    final bankAgency = data['bank_agency'];
    final bankAccount = data['bank_account'];
    final accountType = data['bank_account_type'];
    
    // Se algum campo bancário está preenchido, todos devem estar
    final hasBankData = [bankCode, bankAgency, bankAccount, accountType].any((field) => field != null && field.toString().trim().isNotEmpty);
    
    if (hasBankData) {
      _validateBankCode(bankCode);
      _validateBankAgency(bankAgency);
      _validateBankAccount(bankAccount);
      _validateBankAccountType(accountType);
    }
  }
  
  /// Valida código do banco
  static void _validateBankCode(dynamic bankCode) {
    if (bankCode == null) {
      throw const ValidationException('bank_code é obrigatório quando dados bancários são fornecidos');
    }
    
    final codeStr = bankCode.toString().trim();
    
    if (codeStr.length != 3) {
      throw ValidationException('bank_code deve ter 3 dígitos: $codeStr');
    }
    
    if (!RegExp(r'^\d{3}$').hasMatch(codeStr)) {
      throw ValidationException('bank_code deve conter apenas números: $codeStr');
    }
  }
  
  /// Valida agência bancária
  static void _validateBankAgency(dynamic agency) {
    if (agency == null) {
      throw const ValidationException('bank_agency é obrigatório quando dados bancários são fornecidos');
    }
    
    final agencyStr = agency.toString().trim();
    
    if (agencyStr.length < 3 || agencyStr.length > 6) {
      throw ValidationException('bank_agency deve ter entre 3 e 6 caracteres: $agencyStr');
    }
  }
  
  /// Valida conta bancária
  static void _validateBankAccount(dynamic account) {
    if (account == null) {
      throw const ValidationException('bank_account é obrigatório quando dados bancários são fornecidos');
    }
    
    final accountStr = account.toString().trim();
    
    if (accountStr.length < 5 || accountStr.length > 15) {
      throw ValidationException('bank_account deve ter entre 5 e 15 caracteres: $accountStr');
    }
  }
  
  /// Valida tipo de conta bancária
  static void _validateBankAccountType(dynamic accountType) {
    if (accountType == null) {
      throw const ValidationException('bank_account_type é obrigatório quando dados bancários são fornecidos');
    }
    
    final typeStr = accountType.toString().toLowerCase().trim();
    
    const validTypes = ['corrente', 'poupanca'];
    if (!validTypes.contains(typeStr)) {
      throw ValidationException(
        'bank_account_type inválido: $typeStr. Valores permitidos: ${validTypes.join(", ")}'
      );
    }
  }
  
  /// Valida dados PIX
  static void _validatePixData(Map<String, dynamic> data) {
    final pixKey = data['pix_key'];
    final pixKeyType = data['pix_key_type'];
    
    // Se chave PIX está preenchida, tipo deve estar também
    if (pixKey != null && pixKey.toString().trim().isNotEmpty) {
      _validatePixKey(pixKey, pixKeyType);
      _validatePixKeyType(pixKeyType);
    }
  }
  
  /// Valida chave PIX
  static void _validatePixKey(dynamic pixKey, dynamic pixKeyType) {
    if (pixKey == null) {
      throw const ValidationException('pix_key é obrigatório quando fornecido');
    }
    
    final keyStr = pixKey.toString().trim();
    
    if (keyStr.isEmpty) {
      throw const ValidationException('pix_key não pode estar vazio');
    }
    
    if (keyStr.length > 77) { // Limite do PIX
      throw ValidationException('pix_key não pode ter mais de 77 caracteres: ${keyStr.length}');
    }
    
    // Validação básica baseada no tipo
    if (pixKeyType != null) {
      final typeStr = pixKeyType.toString().toLowerCase().trim();
      
      switch (typeStr) {
        case 'cpf':
          final digitsOnly = keyStr.replaceAll(RegExp(r'[^\d]'), '');
          if (digitsOnly.length != 11) {
            throw ValidationException('pix_key do tipo CPF deve ter 11 dígitos: $keyStr');
          }
          break;
        case 'cnpj':
          final digitsOnly = keyStr.replaceAll(RegExp(r'[^\d]'), '');
          if (digitsOnly.length != 14) {
            throw ValidationException('pix_key do tipo CNPJ deve ter 14 dígitos: $keyStr');
          }
          break;
        case 'email':
          final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
          if (!emailRegex.hasMatch(keyStr)) {
            throw ValidationException('pix_key do tipo email deve ser um email válido: $keyStr');
          }
          break;
        case 'phone':
          final digitsOnly = keyStr.replaceAll(RegExp(r'[^\d]'), '');
          if (digitsOnly.length < 10 || digitsOnly.length > 11) {
            throw ValidationException('pix_key do tipo telefone deve ter 10 ou 11 dígitos: $keyStr');
          }
          break;
      }
    }
  }
  
  /// Valida tipo de chave PIX
  static void _validatePixKeyType(dynamic pixKeyType) {
    if (pixKeyType == null) {
      throw const ValidationException('pix_key_type é obrigatório quando pix_key é fornecido');
    }
    
    final typeStr = pixKeyType.toString().toLowerCase().trim();
    
    const validTypes = ['cpf', 'cnpj', 'email', 'phone', 'random'];
    if (!validTypes.contains(typeStr)) {
      throw ValidationException(
        'pix_key_type inválido: $typeStr. Valores permitidos: ${validTypes.join(", ")}'
      );
    }
  }
  
  /// Valida dados de localização
  static void _validateLocationData(Map<String, dynamic> data) {
    _validateLatitude(data['current_latitude']);
    _validateLongitude(data['current_longitude']);
  }
  
  /// Valida latitude
  static void _validateLatitude(dynamic latitude) {
    if (latitude == null) return; // Campo opcional
    
    double? lat;
    
    if (latitude is String) {
      lat = double.tryParse(latitude);
    } else if (latitude is num) {
      lat = latitude.toDouble();
    }
    
    if (lat == null) {
      throw ValidationException('current_latitude deve ser um número: $latitude');
    }
    
    if (lat < -90 || lat > 90) {
      throw ValidationException('current_latitude deve estar entre -90 e 90: $lat');
    }
  }
  
  /// Valida longitude
  static void _validateLongitude(dynamic longitude) {
    if (longitude == null) return; // Campo opcional
    
    double? lng;
    
    if (longitude is String) {
      lng = double.tryParse(longitude);
    } else if (longitude is num) {
      lng = longitude.toDouble();
    }
    
    if (lng == null) {
      throw ValidationException('current_longitude deve ser um número: $longitude');
    }
    
    if (lng < -180 || lng > 180) {
      throw ValidationException('current_longitude deve estar entre -180 e 180: $lng');
    }
  }
  
  /// Valida dados de avaliações e viagens
  static void _validateRatingsAndTrips(Map<String, dynamic> data) {
    _validateNonNegativeInteger(data['consecutive_cancellations'], 'consecutive_cancellations');
    _validateNonNegativeInteger(data['total_trips'], 'total_trips');
    _validateRating(data['average_rating']);
  }
  
  /// Valida inteiros não negativos
  static void _validateNonNegativeInteger(dynamic value, String fieldName) {
    if (value == null) return; // Campos têm defaults
    
    int? intValue;
    
    if (value is String) {
      intValue = int.tryParse(value);
    } else if (value is int) {
      intValue = value;
    } else if (value is double) {
      intValue = value.toInt();
    }
    
    if (intValue == null) {
      throw ValidationException('$fieldName deve ser um número inteiro: $value');
    }
    
    if (intValue < 0) {
      throw ValidationException('$fieldName não pode ser negativo: $intValue');
    }
  }
  
  /// Valida avaliação média
  static void _validateRating(dynamic rating) {
    if (rating == null) return; // Campo opcional
    
    double? ratingValue;
    
    if (rating is String) {
      ratingValue = double.tryParse(rating);
    } else if (rating is num) {
      ratingValue = rating.toDouble();
    }
    
    if (ratingValue == null) {
      throw ValidationException('average_rating deve ser um número: $rating');
    }
    
    if (ratingValue < 0 || ratingValue > 5) {
      throw ValidationException('average_rating deve estar entre 0 e 5: $ratingValue');
    }
  }
}