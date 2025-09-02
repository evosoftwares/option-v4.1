import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../exceptions/app_exceptions.dart';
import '../exceptions/validation_exception.dart' as validation;
import '../models/user.dart';
import '../utils/supabase_helper.dart';
import '../validators/user_data_validator.dart';

class UserService {
  static SupabaseClient get _supabase {
    final c = SupabaseHelper.client;
    if (c == null) {
      throw Exception('Supabase não inicializado');
    }
    return c;
  }

  /// Cria um novo usuário na tabela app_users
  static Future<User> createUser({
    required String authUserId,
    required String email,
    required String fullName,
    String? phone,
    String? photoUrl,
    required String userType,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    print('🔄 [$timestamp] [USER_SERVICE] createUser iniciado');
    print('  - authUserId: $authUserId');
    print('  - email: $email');
    print('  - fullName: $fullName');
    print('  - phone: ${phone ?? 'null'}');
    print('  - userType: $userType');

    // VALIDAÇÃO SIMPLIFICADA: Apenas validação básica necessária
    try {
      final validatedData = UserDataValidator.validateUserData(
        fullName: fullName,
        email: email,
        userType: userType,
        phone: phone,
        photoUrl: photoUrl,
      );
      
      // Usar dados validados
      fullName = validatedData['full_name'];
      email = validatedData['email'];
      userType = validatedData['user_type'];
      phone = validatedData['phone'];
      photoUrl = validatedData['photo_url'];
      
    } on validation.ValidationException catch (e) {
      throw DatabaseException('Dados inválidos: ${e.message}');
    }

    try {
      // Verificar se o usuário já existe por ID
      print('🔍 [$timestamp] [USER_SERVICE] Verificando se usuário já existe por ID...');
      final existingUser = await getUserById(authUserId);
      if (existingUser != null) {
        print('❌ [$timestamp] [USER_SERVICE] Usuário já existe por ID: $email');
        throw UserAlreadyExistsException(email);
      }
      print('✅ [$timestamp] [USER_SERVICE] Usuário não existe por ID, continuando...');
    } catch (e) {
      if (e is UserAlreadyExistsException) rethrow;
      print('ℹ️ [$timestamp] [USER_SERVICE] Erro ao verificar usuário existente por ID (normal): $e');
      // Se não encontrou o usuário, continua com a criação
    }

    // Verificar se já existe usuário com o mesmo email
    try {
      print('🔍 [$timestamp] [USER_SERVICE] Verificando se email já existe: $email');
      final existingUserByEmail = await getUserByEmail(email);
      if (existingUserByEmail != null) {
        print('❌ [$timestamp] [USER_SERVICE] Email já existe: $email (ID: ${existingUserByEmail.id})');
        throw UserAlreadyExistsException(email);
      }
      print('✅ [$timestamp] [USER_SERVICE] Email disponível: $email');
    } catch (e) {
      if (e is UserAlreadyExistsException) rethrow;
      print('ℹ️ [$timestamp] [USER_SERVICE] Erro ao verificar email existente (normal): $e');
    }

    // Validação obrigatória do telefone conforme schema Supabase
    if (phone == null || phone.trim().isEmpty) {
      throw const DatabaseException('Telefone é obrigatório para criar usuário', 'PHONE_REQUIRED');
    }
    final finalPhone = phone.trim();

    try {
      final userData = {
        'id': authUserId,  // PK: UUID do auth.users
        'email': email,
        'full_name': fullName,
        'phone': finalPhone,    // Pode ser vazio, será preenchido no stepper
        'photo_url': photoUrl,
        'user_type': userType,
        'status': 'active',
      };

      print('📝 [$timestamp] [USER_SERVICE] Usando telefone: $finalPhone');

      print('📝 [$timestamp] [USER_SERVICE] Inserindo dados do usuário:');
      print('  - Dados: $userData');

      final response = await _supabase
          .from('app_users')
          .insert(userData)
          .select()
          .single();

      print('✅ [$timestamp] [USER_SERVICE] Usuário criado com sucesso!');
      print('📄 [$timestamp] [USER_SERVICE] Resposta: $response');
      
      final user = User.fromMap(response);
      
      // Create corresponding passenger or driver record
      print('🔄 [$timestamp] [USER_SERVICE] Criando registro específico para ${user.userType}...');
      await _createUserSpecificRecord(user);
      print('✅ [$timestamp] [USER_SERVICE] Processo completo finalizado com sucesso!');
      
      return user;
    } on PostgrestException catch (e) {
      print('❌ [$timestamp] [USER_SERVICE] PostgrestException: ${e.code} - ${e.message}');
      print('❌ [$timestamp] [USER_SERVICE] Detalhes do erro: ${e.details}');
      print('❌ [$timestamp] [USER_SERVICE] Hint: ${e.hint}');
      
      if (e.code == '23505') { // Unique constraint violation
        // Analisar qual constraint foi violado
        final message = e.message.toLowerCase() ?? '';
        if (message.contains('phone')) {
          print('❌ [$timestamp] [USER_SERVICE] Constraint violado: telefone duplicado');
          throw DatabaseException('Este telefone já está cadastrado: $phone', 'PHONE_ALREADY_EXISTS');
        } else if (message.contains('email')) {
          print('❌ [$timestamp] [USER_SERVICE] Constraint violado: email duplicado');
          throw UserAlreadyExistsException(email);
        } else {
          print('❌ [$timestamp] [USER_SERVICE] Constraint violado: dados duplicados');
          throw UserAlreadyExistsException(email);
        }
      }
      throw DatabaseException('Erro ao criar usuário: ${e.message}', e.code);
    } catch (e) {
      print('❌ [$timestamp] [USER_SERVICE] Erro inesperado ao criar usuário: $e');
      print('❌ [$timestamp] [USER_SERVICE] Tipo do erro: ${e.runtimeType}');
      throw DatabaseException('Erro inesperado ao criar usuário: ${e.toString()}');
    }
  }

  /// Busca um usuário pelo ID
  static Future<User?> getUserById(String userId) async {
    try {
      print('🔍 [DEBUG] getUserById chamado para ID: $userId');
      final response = await _supabase
          .from('app_users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      print('🔍 [DEBUG] Resposta bruta do Supabase: $response');
      print('🔍 [DEBUG] Tipo da resposta: ${response.runtimeType}');

      if (response == null) {
        print('❌ [DEBUG] Resposta é null - usuário não encontrado');
        return null;
      }
      
      print('✅ [DEBUG] Resposta é um Map válido');
      print('🔍 [DEBUG] full_name na resposta: ${response['full_name']}');
      print('🔍 [DEBUG] email na resposta: ${response['email']}');
      
      final user = User.fromMap(response);
      print('✅ [DEBUG] User criado: ${user.fullName}');
      return user;
        } on PostgrestException catch (e) {
      print('❌ [DEBUG] PostgrestException: ${e.message}');
      throw const DatabaseException('Erro ao buscar usuário. Por favor, tente novamente mais tarde.');
    } catch (e) {
      print('❌ [DEBUG] Erro inesperado em getUserById: $e');
      throw const DatabaseException('Erro inesperado ao buscar usuário. Por favor, tente novamente mais tarde.');
    }
  }

  /// Busca um usuário pelo email
  static Future<User?> getUserByEmail(String email) async {
    try {
      final response = await _supabase
          .from('app_users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (response == null) return null;
      return User.fromMap(response);
    } on PostgrestException {
      throw Exception('Erro ao buscar usuário por email. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw Exception('Erro inesperado ao buscar usuário por email. Por favor, tente novamente mais tarde.');
    }
  }

  /// Busca um usuário pelo telefone
  static Future<User?> _getUserByPhone(String phone) async {
    try {
      final response = await _supabase
          .from('app_users')
          .select()
          .eq('phone', phone)
          .maybeSingle();

      if (response == null) return null;
      return User.fromMap(response);
    } on PostgrestException {
      throw Exception('Erro ao buscar usuário por telefone. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw Exception('Erro inesperado ao buscar usuário por telefone. Por favor, tente novamente mais tarde.');
    }
  }

  /// Atualiza os dados de um usuário
  static Future<User> updateUser({
    required String userId,
    String? fullName,
    String? phone,
    String? photoUrl,
    String? userType,
    String? status,
  }) async {
    // 🚨 VALIDAÇÃO CRÍTICA: NUNCA permitir dados corrompidos
    try {
      if (fullName != null) {
        UserDataValidator.validateAndSanitizeFullName(fullName);
      }
      if (phone != null) {
        UserDataValidator.validatePhone(phone);
      }
      if (userType != null) {
        UserDataValidator.validateUserType(userType);
      }
    } on validation.ValidationException catch (e) {
      throw DatabaseException('Dados inválidos fornecidos para atualização: ${e.message}');
    }

    final updateData = <String, dynamic>{};
    
    if (fullName != null) updateData['full_name'] = fullName;
    if (phone != null) updateData['phone'] = phone;
    if (photoUrl != null) updateData['photo_url'] = photoUrl;
    if (userType != null) updateData['user_type'] = userType;
    if (status != null) updateData['status'] = status;
    
    // Sempre atualiza o updated_at
    updateData['updated_at'] = DateTime.now().toIso8601String();

    try {
      // Try direct update first, but catch sync_control errors
      final response = await _supabase
          .from('app_users')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      return User.fromMap(response);
    } on PostgrestException catch (e) {
      print('❌ [USER_SERVICE] PostgrestException detalhado:');
      print('  - Code: ${e.code}');
      print('  - Message: ${e.message}');
      print('  - Details: ${e.details}');
      print('  - Hint: ${e.hint}');
      
      if (e.code == '42P01' && (e.message.contains('sync_control') ?? false)) {
        // Sync control table doesn't exist - this is the main issue
        throw const DatabaseException('Sistema de sincronização não configurado. Entre em contato com o suporte.', 'SYNC_ERROR');
      }
      if (e.code == 'PGRST116') { // No rows returned
        throw UserNotFoundException(userId);
      }
      throw DatabaseException('Erro ao atualizar usuário. Por favor, verifique os dados e tente novamente.', e.code);
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao atualizar usuário. Por favor, tente novamente mais tarde.');
    }
  }

  /// Atualiza apenas o tipo de usuário
  static Future<User> updateUserType(String userId, String userType) async {
    try {
      final response = await _supabase
          .from('app_users')
          .update({
            'user_type': userType,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();

      return User.fromMap(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') { // No rows returned
        throw UserNotFoundException(userId);
      }
      throw DatabaseException('Erro ao atualizar tipo de usuário. Por favor, verifique os dados e tente novamente.', e.code);
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao atualizar tipo de usuário. Por favor, tente novamente mais tarde.');
    }
  }

  /// Verifica se um usuário existe na tabela app_users
  static Future<bool> userExists(String userId) async {
    try {
      final response = await _supabase
          .from('app_users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      return response != null;
    } on PostgrestException {
      throw Exception('Erro ao verificar existência do usuário. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw Exception('Erro inesperado ao verificar usuário. Por favor, tente novamente mais tarde.');
    }
  }

  /// Obtém o usuário atual logado
  static Future<User?> getCurrentUser() async {
    try {
      print('🔍 [DEBUG] getCurrentUser iniciado');
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        print('❌ [DEBUG] Auth user é null');
        return null;
      }

      print('✅ [DEBUG] Auth user encontrado: ${authUser.id}');
      final user = await getUserById(authUser.id);
      
      if (user != null) {
        print('✅ [DEBUG] Usuário encontrado: ${user.fullName} (${user.email})');
        print('🔍 [DEBUG] Dados completos do usuário: $user');
      } else {
        print('❌ [DEBUG] Usuário não encontrado na tabela app_users');
      }
      
      return user;
    } catch (e) {
      print('❌ [DEBUG] Erro em getCurrentUser: $e');
      throw Exception('Erro ao obter usuário atual. Por favor, tente novamente mais tarde.');
    }
  }

  /// Deleta um usuário (soft delete - marca como inativo)
  static Future<void> deactivateUser(String userId) async {
    try {
      await _supabase
          .from('app_users')
          .update({
            'status': 'inactive',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } on PostgrestException {
      throw Exception('Erro ao desativar usuário. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw Exception('Erro inesperado ao desativar usuário. Por favor, tente novamente mais tarde.');
    }
  }

  /// Lista usuários por tipo (com paginação)
  static Future<List<User>> getUsersByType({
    required String userType,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('app_users')
          .select()
          .eq('user_type', userType)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map(User.fromMap).toList();
    } on PostgrestException {
      throw Exception('Erro ao buscar usuários por tipo. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw Exception('Erro inesperado ao buscar usuários. Por favor, tente novamente mais tarde.');
    }
  }

  /// Creates passenger or driver specific records when a user is created
  static Future<void> _createUserSpecificRecord(User user) async {
    try {
      print('🔄 Criando registro específico para ${user.userType}: ${user.id}');
      
      if (user.userType.toLowerCase() == 'passenger') {
        await _createPassengerRecord(user);
      } else if (user.userType.toLowerCase() == 'driver') {
        await _createDriverRecord(user);
      }
      
      print('✅ Registro específico criado com sucesso');
    } catch (e) {
      print('❌ Erro ao criar registro específico: $e');
      // Log the error but don't throw - the app_user record was already created successfully
      // The wallet service has fallback logic to handle missing passenger records
    }
  }

  /// Creates a passenger record for passenger-type users
  static Future<void> _createPassengerRecord(User user) async {
    try {
      print('📝 Criando registro de passageiro...');
      
      // Check if passenger record already exists
      final existingPassenger = await _supabase
          .from('passengers')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();
          
      if (existingPassenger != null) {
        print('ℹ️ Registro de passageiro já existe');
        return;
      }
      
      final passengerData = {
        'user_id': user.id,
        'consecutive_cancellations': 0,
        'total_trips': 0,
        'average_rating': null,
        'payment_method_id': null,
      };

      await _supabase
          .from('passengers')
          .insert(passengerData);
          
      print('✅ Registro de passageiro criado com sucesso');
    } on PostgrestException catch (e) {
      print('❌ PostgrestException ao criar passageiro: ${e.code} - ${e.message}');
      throw DatabaseException('Erro ao criar registro de passageiro: ${e.message}', e.code);
    } catch (e) {
      print('❌ Erro inesperado ao criar passageiro: $e');
      throw DatabaseException('Erro inesperado ao criar registro de passageiro: ${e.toString()}');
    }
  }

  /// Creates a driver record for driver-type users (basic record, needs completion later)
  static Future<void> _createDriverRecord(User user) async {
    await createDriverRecord(user);
  }

  /// Public method to create driver record when needed (e.g., when user switches to driver type)
  static Future<void> createDriverRecord(User user) async {
    try {
      print('📝 Criando registro básico de motorista...');
      
      // Check if driver record already exists
      final existingDriver = await _supabase
          .from('drivers')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();
          
      if (existingDriver != null) {
        print('ℹ️ Registro de motorista já existe');
        return;
      }
      
      // Create basic driver record with placeholder values - will be filled during driver onboarding
      final driverData = {
        'user_id': user.id,
        'cnh_number': 'PENDENTE_CADASTRO',
        'cnh_expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String().split('T')[0],
        'cnh_photo_url': '',
        'vehicle_brand': 'PENDENTE',
        'vehicle_model': 'PENDENTE', 
        'vehicle_year': 2020,
        'vehicle_color': 'PENDENTE',
        'vehicle_plate': 'PENDENTE',
        'vehicle_category': 'standard',
        'crlv_photo_url': '',
        'approval_status': 'pending',
        'approved_by': null,
        'approved_at': null,
        'is_online': false,
        'accepts_pet': false,
        'pet_fee': 0.0,
        'accepts_grocery': false,
        'grocery_fee': 0.0,
        'accepts_condo': false,
        'condo_fee': 0.0,
        'stop_fee': 0.0,
        'ac_policy': 'on_request',
        'custom_price_per_km': 0.0,
        'custom_price_per_minute': 0.0,
        'bank_account_type': null,
        'bank_code': null,
        'bank_agency': null,
        'bank_account': null,
        'pix_key': '',
        'pix_key_type': 'email',
        'consecutive_cancellations': 0,
        'total_trips': 0,
        'average_rating': null,
        'current_latitude': null,
        'current_longitude': null,
        'last_location_update': null,
      };

      await _supabase
          .from('drivers')
          .insert(driverData);
          
      print('✅ Registro básico de motorista criado com sucesso');
    } on PostgrestException catch (e) {
      print('❌ PostgrestException ao criar motorista: ${e.code} - ${e.message}');
      throw DatabaseException('Erro ao criar registro de motorista: ${e.message}', e.code);
    } catch (e) {
      print('❌ Erro inesperado ao criar motorista: $e');
      throw DatabaseException('Erro inesperado ao criar registro de motorista: ${e.toString()}');
    }
  }
}