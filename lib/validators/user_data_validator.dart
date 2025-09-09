import '../exceptions/validation_exception.dart';

/// Validador rigoroso para dados de usuário
/// 
/// Garante que NUNCA passem dados corrompidos para o banco
class UserDataValidator {
  
  /// Valida e sanitiza o nome completo do usuário
  /// 
  /// Throws [ValidationException] se os dados estiverem corrompidos
  static String validateAndSanitizeFullName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      throw const ValidationException('Nome completo é obrigatório');
    }

    final sanitized = fullName.trim();
    
    // VALIDAÇÃO CRÍTICA: Detecta dados JSON/corrompidos
    if (_isCorruptedData(sanitized)) {
      throw ValidationException('Nome contém dados corrompidos: $sanitized');
    }

    // Validações básicas de formato
    if (sanitized.length < 2) {
      throw const ValidationException('Nome deve ter pelo menos 2 caracteres');
    }

    if (sanitized.length > 100) {
      throw const ValidationException('Nome não pode ter mais de 100 caracteres');
    }

    // Validar caracteres permitidos (não aceita símbolos especiais que indicam corrupção)
    if (sanitized.contains(RegExp(r'[{}[\]<>@#$%^&*()+=|\\`~]'))) {
      throw ValidationException('Nome contém caracteres inválidos: $sanitized');
    }

    return sanitized;
  }

  /// Valida email
  static String validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      throw const ValidationException('Email é obrigatório');
    }

    final sanitized = email.trim().toLowerCase();
    
    if (_isCorruptedData(sanitized)) {
      throw ValidationException('Email contém dados corrompidos: $sanitized');
    }

    // Validação mais rigorosa de email
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(sanitized)) {
      throw ValidationException('Email inválido: $sanitized');
    }
    
    // Validação adicional - não pode conter espaços
    if (sanitized.contains(' ')) {
      throw ValidationException('Email não pode conter espaços: $sanitized');
    }

    return sanitized;
  }

  /// Valida tipo de usuário
  static String validateUserType(String? userType) {
    if (userType == null || userType.trim().isEmpty) {
      throw const ValidationException('Tipo de usuário é obrigatório');
    }

    final sanitized = userType.trim().toLowerCase();
    
    if (_isCorruptedData(sanitized)) {
      throw ValidationException('Tipo de usuário contém dados corrompidos: $sanitized');
    }

    const validTypes = ['passenger', 'driver', 'admin'];
    if (!validTypes.contains(sanitized)) {
      throw ValidationException('Tipo de usuário inválido: $sanitized. Tipos válidos: ${validTypes.join(', ')}');
    }

    return sanitized;
  }

  /// Valida telefone (opcional)
  static String? validatePhone(String? phone) {
    print('📞 [USER_DATA_VALIDATOR] validatePhone iniciado');
    print('📞 [USER_DATA_VALIDATOR] Telefone recebido: ${phone ?? 'null'}');
    
    if (phone == null || phone.trim().isEmpty) {
      print('📞 [USER_DATA_VALIDATOR] Telefone é nulo ou vazio, retornando null');
      return null; // Telefone é opcional
    }

    final sanitized = phone.trim();
    print('📞 [USER_DATA_VALIDATOR] Telefone sanitizado: $sanitized');
    
    if (_isCorruptedData(sanitized)) {
      print('📞 [USER_DATA_VALIDATOR] Telefone corrompido detectado: $sanitized');
      throw ValidationException('Telefone contém dados corrompidos: $sanitized');
    }

    // Remove formatação e valida apenas números
    final digitsOnly = sanitized.replaceAll(RegExp(r'[^\d]'), '');
    print('📞 [USER_DATA_VALIDATOR] Apenas dígitos: $digitsOnly');
    
    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      print('📞 [USER_DATA_VALIDATOR] Comprimento inválido: ${digitsOnly.length} dígitos');
      throw ValidationException('Telefone deve ter entre 10 e 15 dígitos: $sanitized');
    }

    print('📞 [USER_DATA_VALIDATOR] Telefone válido, retornando: $sanitized');
    return sanitized;
  }

  /// Detecção rigorosa de dados corrompidos
  static bool _isCorruptedData(String data) {
    // 1. Detecta JSON
    if (data.contains('{') && data.contains('}')) return true;
    if (data.contains('[') && data.contains(']')) return true;
    
    // 2. Detecta strings de erro específicas
    const errorPatterns = [
      'missing_passenger_records',
      'issue',
      'count',
      'error',
      'exception',
      'null',
      'undefined',
      'NaN',
    ];
    
    final lowerData = data.toLowerCase();
    for (final pattern in errorPatterns) {
      if (lowerData.contains(pattern)) return true;
    }

    // 3. Detecta SQL/Database queries
    const sqlPatterns = [
      'select',
      'from',
      'where',
      'insert',
      'update',
      'delete',
      'drop',
      'alter',
      'create',
    ];
    
    for (final pattern in sqlPatterns) {
      if (lowerData.contains(pattern)) return true;
    }

    // 4. Detecta estruturas de programação
    if (data.contains('function') || 
        data.contains('return') || 
        data.contains('console.log') ||
        data.contains('print(') ||
        data.contains('//') ||
        data.contains('/*')) {
      return true;
    }

    // 5. Detecta códigos de status HTTP ou sistema
    if (RegExp(r'^[0-9]{3}$').hasMatch(data)) return true;  // HTTP status codes
    if (data.startsWith('0x') || data.startsWith('#')) return true; // Hex codes

    return false;
  }

  /// Valida todos os dados de usuário de uma vez
  static Map<String, dynamic> validateUserData({
    required String? fullName,
    required String? email,
    required String? userType,
    String? phone,
    String? photoUrl,
  }) {
    print('🔍 [USER_DATA_VALIDATOR] validateUserData iniciado');
    print('🔍 [USER_DATA_VALIDATOR] Dados recebidos:');
    print('  - fullName: $fullName');
    print('  - email: $email');
    print('  - userType: $userType');
    print('  - phone: ${phone ?? 'null'}');
    print('  - photoUrl: ${photoUrl ?? 'null'}');
    
    try {
      final result = {
        'full_name': validateAndSanitizeFullName(fullName),
        'email': validateEmail(email),
        'user_type': validateUserType(userType),
        'phone': validatePhone(phone),
        'photo_url': photoUrl?.trim(),
      };
      
      print('✅ [USER_DATA_VALIDATOR] validateUserData concluído com sucesso');
      print('✅ [USER_DATA_VALIDATOR] Resultado:');
      print('  - full_name: ${result['full_name']}');
      print('  - email: ${result['email']}');
      print('  - user_type: ${result['user_type']}');
      print('  - phone: ${result['phone'] ?? 'null'}');
      print('  - photo_url: ${result['photo_url'] ?? 'null'}');
      
      return result;
    } catch (e) {
      // Log crítico para investigação
      print('🚨 DADOS CORROMPIDOS DETECTADOS E BLOQUEADOS:');
      print('  - full_name: $fullName');
      print('  - email: $email');
      print('  - user_type: $userType');
      print('  - phone: $phone');
      print('  - erro: $e');
      rethrow;
    }
  }
}