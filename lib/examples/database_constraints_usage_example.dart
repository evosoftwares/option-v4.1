import '../validators/database_constraints_validator.dart';
import '../exceptions/validation_exception.dart';

/// Exemplo de uso do DatabaseConstraintsValidator
/// 
/// Demonstra como integrar as validações de constraints do banco de dados
/// nos serviços e operações da aplicação
class DatabaseConstraintsUsageExample {
  
  /// Exemplo de criação de usuário com validação de constraints
  static Future<Map<String, dynamic>> createUserWithValidation({
    required String userId,
    required String email,
    required String fullName,
    String? phone,
    required String userType,
    String? status,
    String? photoUrl,
    bool? isActive,
    bool? isVerified,
  }) async {
    // Preparar dados para validação
    final userData = {
      'user_id': userId,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'user_type': userType,
      'status': status,
      'photo_url': photoUrl,
      'is_active': isActive,
      'is_verified': isVerified,
    };
    
    try {
      // Validar constraints antes de inserir no banco
      DatabaseConstraintsValidator.validateAppUser(userData);
      
      // Se chegou até aqui, os dados são válidos
      print('✅ Dados do usuário válidos - prosseguindo com inserção no banco');
      
      // Aqui seria feita a inserção real no banco de dados
      // await supabase.from('app_users').insert(userData);
      
      return {
        'success': true,
        'message': 'Usuário criado com sucesso',
        'data': userData,
      };
      
    } on ValidationException catch (e) {
      // Capturar erros de validação e retornar resposta amigável
      print('❌ Erro de validação: ${e.message}');
      
      return {
        'success': false,
        'error': 'validation_error',
        'message': e.message,
        'field': _extractFieldFromError(e.message),
      };
      
    } catch (e) {
      // Capturar outros erros
      print('❌ Erro inesperado: $e');
      
      return {
        'success': false,
        'error': 'unexpected_error',
        'message': 'Erro interno do servidor',
      };
    }
  }
  
  /// Exemplo de criação de motorista com validação de constraints
  static Future<Map<String, dynamic>> createDriverWithValidation({
    required String userId,
    required String cnhNumber,
    required DateTime cnhExpiryDate,
    required String vehicleBrand,
    required String vehicleModel,
    required int vehicleYear,
    required String vehicleColor,
    required String vehiclePlate,
    required String vehicleCategory,
    String? approvalStatus,
    bool? isOnline,
    bool? acceptsPet,
    bool? acceptsGrocery,
    bool? acceptsCondo,
    double? petFee,
    double? groceryFee,
    double? condoFee,
    double? stopFee,
    double? customPricePerKm,
    double? customPricePerMinute,
    String? bankCode,
    String? bankAgency,
    String? bankAccount,
    String? bankAccountType,
    String? pixKey,
    String? pixKeyType,
    double? currentLatitude,
    double? currentLongitude,
    int? consecutiveCancellations,
    int? totalTrips,
    double? averageRating,
  }) async {
    // Preparar dados para validação
    final driverData = {
      'user_id': userId,
      'cnh_number': cnhNumber,
      'cnh_expiry_date': cnhExpiryDate.toIso8601String(),
      'vehicle_brand': vehicleBrand,
      'vehicle_model': vehicleModel,
      'vehicle_year': vehicleYear,
      'vehicle_color': vehicleColor,
      'vehicle_plate': vehiclePlate,
      'vehicle_category': vehicleCategory,
      'approval_status': approvalStatus,
      'is_online': isOnline,
      'accepts_pet': acceptsPet,
      'accepts_grocery': acceptsGrocery,
      'accepts_condo': acceptsCondo,
      'pet_fee': petFee,
      'grocery_fee': groceryFee,
      'condo_fee': condoFee,
      'stop_fee': stopFee,
      'custom_price_per_km': customPricePerKm,
      'custom_price_per_minute': customPricePerMinute,
      'bank_code': bankCode,
      'bank_agency': bankAgency,
      'bank_account': bankAccount,
      'bank_account_type': bankAccountType,
      'pix_key': pixKey,
      'pix_key_type': pixKeyType,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
      'consecutive_cancellations': consecutiveCancellations,
      'total_trips': totalTrips,
      'average_rating': averageRating,
    };
    
    try {
      // Validar constraints antes de inserir no banco
      DatabaseConstraintsValidator.validateDriver(driverData);
      
      // Se chegou até aqui, os dados são válidos
      print('✅ Dados do motorista válidos - prosseguindo com inserção no banco');
      
      // Aqui seria feita a inserção real no banco de dados
      // await supabase.from('drivers').insert(driverData);
      
      return {
        'success': true,
        'message': 'Motorista criado com sucesso',
        'data': driverData,
      };
      
    } on ValidationException catch (e) {
      // Capturar erros de validação e retornar resposta amigável
      print('❌ Erro de validação: ${e.message}');
      
      return {
        'success': false,
        'error': 'validation_error',
        'message': e.message,
        'field': _extractFieldFromError(e.message),
      };
      
    } catch (e) {
      // Capturar outros erros
      print('❌ Erro inesperado: $e');
      
      return {
        'success': false,
        'error': 'unexpected_error',
        'message': 'Erro interno do servidor',
      };
    }
  }
  
  /// Exemplo de atualização de dados com validação parcial
  static Future<Map<String, dynamic>> updateUserDataWithValidation(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      // Para atualizações, validamos apenas os campos que estão sendo alterados
      // Primeiro, buscar dados atuais do usuário (simulado)
      final currentUserData = await _getCurrentUserData(userId);
      
      // Mesclar dados atuais com atualizações
      final mergedData = {...currentUserData, ...updates};
      
      // Validar dados completos após mesclagem
      DatabaseConstraintsValidator.validateAppUser(mergedData);
      
      print('✅ Atualização de dados válida - prosseguindo com update no banco');
      
      // Aqui seria feita a atualização real no banco de dados
      // await supabase.from('app_users').update(updates).eq('user_id', userId);
      
      return {
        'success': true,
        'message': 'Dados atualizados com sucesso',
        'updated_fields': updates.keys.toList(),
      };
      
    } on ValidationException catch (e) {
      print('❌ Erro de validação na atualização: ${e.message}');
      
      return {
        'success': false,
        'error': 'validation_error',
        'message': e.message,
        'field': _extractFieldFromError(e.message),
      };
    }
  }
  
  /// Exemplo de validação em lote (batch validation)
  static Future<Map<String, dynamic>> validateBatchUsers(
    List<Map<String, dynamic>> usersData,
  ) async {
    final results = <Map<String, dynamic>>[];
    final errors = <Map<String, dynamic>>[];
    
    for (var i = 0; i < usersData.length; i++) {
      final userData = usersData[i];
      
      try {
        DatabaseConstraintsValidator.validateAppUser(userData);
        
        results.add({
          'index': i,
          'status': 'valid',
          'data': userData,
        });
        
      } on ValidationException catch (e) {
        errors.add({
          'index': i,
          'status': 'invalid',
          'error': e.message,
          'field': _extractFieldFromError(e.message),
          'data': userData,
        });
      }
    }
    
    return {
      'total_processed': usersData.length,
      'valid_count': results.length,
      'error_count': errors.length,
      'valid_users': results,
      'invalid_users': errors,
      'success_rate': (results.length / usersData.length * 100).toStringAsFixed(2),
    };
  }
  
  /// Exemplo de integração com formulários
  static Map<String, dynamic> validateFormData(
    Map<String, dynamic> formData,
    String formType,
  ) {
    try {
      switch (formType.toLowerCase()) {
        case 'user_registration':
          DatabaseConstraintsValidator.validateAppUser(formData);
          break;
          
        case 'driver_registration':
          DatabaseConstraintsValidator.validateDriver(formData);
          break;
          
        default:
          throw ValidationException('Tipo de formulário não suportado: $formType');
      }
      
      return {
        'valid': true,
        'message': 'Dados do formulário são válidos',
      };
      
    } on ValidationException catch (e) {
      return {
        'valid': false,
        'error': e.message,
        'field': _extractFieldFromError(e.message),
        'suggestions': _getFieldSuggestions(e.message),
      };
    }
  }
  
  /// Exemplo de middleware para APIs
  static Future<Map<String, dynamic>> apiValidationMiddleware(
    Map<String, dynamic> requestData,
    String endpoint,
  ) async {
    try {
      // Determinar tipo de validação baseado no endpoint
      switch (endpoint) {
        case '/api/users':
        case '/api/auth/register':
          DatabaseConstraintsValidator.validateAppUser(requestData);
          break;
          
        case '/api/drivers':
        case '/api/drivers/register':
          DatabaseConstraintsValidator.validateDriver(requestData);
          break;
          
        default:
          // Para outros endpoints, pular validação ou implementar validação específica
          break;
      }
      
      return {
        'validation_passed': true,
        'proceed': true,
      };
      
    } on ValidationException catch (e) {
      return {
        'validation_passed': false,
        'proceed': false,
        'error': {
          'type': 'validation_error',
          'message': e.message,
          'field': _extractFieldFromError(e.message),
          'code': 400,
        },
      };
    }
  }
  
  // =============================================================================
  // MÉTODOS AUXILIARES
  // =============================================================================
  
  /// Simula busca de dados atuais do usuário
  static Future<Map<String, dynamic>> _getCurrentUserData(String userId) async {
    // Em uma implementação real, isso buscaria do banco de dados
    // await supabase.from('app_users').select().eq('user_id', userId).single();
    
    return {
      'user_id': userId,
      'email': 'current@example.com',
      'full_name': 'Nome Atual',
      'phone': '(11) 99999-9999',
      'user_type': 'passenger',
      'status': 'active',
      'photo_url': null,
      'is_active': true,
      'is_verified': false,
    };
  }
  
  /// Extrai o nome do campo do erro de validação
  static String? _extractFieldFromError(String errorMessage) {
    // Tentar extrair o nome do campo da mensagem de erro
    final patterns = [
      RegExp(r'(\w+) é obrigatório'),
      RegExp(r'(\w+) deve ser'),
      RegExp(r'(\w+) não pode'),
      RegExp(r'(\w+) inválido'),
      RegExp(r'(\w+) contém'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(errorMessage);
      if (match != null) {
        return match.group(1);
      }
    }
    
    return null;
  }
  
  /// Fornece sugestões baseadas no erro de validação
  static List<String> _getFieldSuggestions(String errorMessage) {
    final suggestions = <String>[];
    
    if (errorMessage.contains('email')) {
      suggestions.addAll([
        'Verifique se o email contém @ e um domínio válido',
        'Exemplo: usuario@exemplo.com',
        'Email não pode ter mais de 255 caracteres',
      ]);
    }
    
    if (errorMessage.contains('full_name')) {
      suggestions.addAll([
        'Nome deve conter apenas letras e espaços',
        'Nome não pode ter mais de 100 caracteres',
        'Evite números e caracteres especiais',
      ]);
    }
    
    if (errorMessage.contains('phone')) {
      suggestions.addAll([
        'Use formato brasileiro: (11) 99999-9999',
        'Telefone não pode ter mais de 20 caracteres',
        'Apenas números, parênteses, espaços e hífens são permitidos',
      ]);
    }
    
    if (errorMessage.contains('user_type')) {
      suggestions.addAll([
        'Tipos válidos: passenger, driver, admin',
        'Use apenas letras minúsculas',
      ]);
    }
    
    if (errorMessage.contains('cnh_number')) {
      suggestions.addAll([
        'CNH deve ter exatamente 11 dígitos',
        'Apenas números são permitidos',
      ]);
    }
    
    if (errorMessage.contains('vehicle_plate')) {
      suggestions.addAll([
        'Use formato brasileiro: ABC1234 ou ABC1D23',
        'Três letras seguidas de números',
      ]);
    }
    
    if (errorMessage.contains('pix_key')) {
      suggestions.addAll([
        'Chave PIX deve corresponder ao tipo informado',
        'CPF: 11 dígitos, Email: formato válido, etc.',
      ]);
    }
    
    return suggestions;
  }
}

/// Exemplo de uso prático
void main() async {
  print('=== Exemplo de Uso do DatabaseConstraintsValidator ===\n');
  
  // Exemplo 1: Criação de usuário válido
  print('1. Criando usuário válido...');
  final userResult = await DatabaseConstraintsUsageExample.createUserWithValidation(
    userId: '123e4567-e89b-12d3-a456-426614174000',
    email: 'joao@example.com',
    fullName: 'João Silva',
    phone: '(11) 99999-9999',
    userType: 'passenger',
    status: 'active',
    isActive: true,
    isVerified: false,
  );
  print('Resultado: ${userResult['success'] ? "✅ Sucesso" : "❌ Erro"} - ${userResult['message']}\n');
  
  // Exemplo 2: Criação de usuário inválido
  print('2. Tentando criar usuário com email inválido...');
  final invalidUserResult = await DatabaseConstraintsUsageExample.createUserWithValidation(
    userId: '123e4567-e89b-12d3-a456-426614174000',
    email: 'email-inválido', // Email inválido
    fullName: 'João Silva',
    userType: 'passenger',
  );
  print('Resultado: ${invalidUserResult['success'] ? "✅ Sucesso" : "❌ Erro"} - ${invalidUserResult['message']}\n');
  
  // Exemplo 3: Validação de formulário
  print('3. Validando dados de formulário...');
  final formData = {
    'user_id': '123e4567-e89b-12d3-a456-426614174000',
    'email': 'maria@example.com',
    'full_name': 'Maria Santos',
    'user_type': 'driver',
  };
  final formResult = DatabaseConstraintsUsageExample.validateFormData(formData, 'user_registration');
  print('Resultado: ${formResult['valid'] ? "✅ Válido" : "❌ Inválido"} - ${formResult['message'] ?? formResult['error']}\n');
  
  // Exemplo 4: Validação em lote
  print('4. Validando múltiplos usuários...');
  final batchData = [
    {
      'user_id': '123e4567-e89b-12d3-a456-426614174001',
      'email': 'user1@example.com',
      'full_name': 'Usuário Um',
      'user_type': 'passenger',
    },
    {
      'user_id': 'invalid-uuid', // UUID inválido
      'email': 'user2@example.com',
      'full_name': 'Usuário Dois',
      'user_type': 'passenger',
    },
    {
      'user_id': '123e4567-e89b-12d3-a456-426614174003',
      'email': 'user3@example.com',
      'full_name': 'Usuário Três',
      'user_type': 'passenger',
    },
  ];
  final batchResult = await DatabaseConstraintsUsageExample.validateBatchUsers(batchData);
  print('Resultado: ${batchResult['valid_count']}/${batchResult['total_processed']} usuários válidos (${batchResult['success_rate']}%)\n');
  
  print('=== Fim dos Exemplos ===');
}