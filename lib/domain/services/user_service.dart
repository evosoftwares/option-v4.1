import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../core/error_handling/postgrest_error_mapper.dart';
import '../core/error_handling/error_logger.dart';
import '../core/error_handling/app_error.dart';
import '../../domain/exceptions/app_exceptions.dart';
import '../../domain/exceptions/validation_exception.dart' as validation;
import '../../data/models/user.dart';
import '../../data/models/vehicle_category.dart';
import '../../core/utils/supabase_helper.dart';
import '../../core/validators/user_data_validator.dart';
import 'app_logger.dart';
import 'platform_settings_service.dart';

class UserService {
  static SupabaseClient get _supabase {
    AppLogger.process('Obtendo cliente Supabase', tag: 'USER_SERVICE');
    final c = SupabaseHelper.client;
    if (c == null) {
      AppLogger.error('SupabaseHelper.client retornou null',
          tag: 'USER_SERVICE');
      AppLogger.debug(
          'SupabaseHelper.isInitialized: ${SupabaseHelper.isInitialized}',
          tag: 'USER_SERVICE');
      throw Exception('Supabase não inicializado');
    }
    AppLogger.success('Cliente Supabase obtido com sucesso',
        tag: 'USER_SERVICE');
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
    final startTime = DateTime.now();
    final timestamp = DateTime.now().toIso8601String();

    AppLogger.process('Iniciando criação de usuário', tag: 'USER_SERVICE');
    AppLogger.create('User Creation Attempt', authUserId,
        tag: 'USER_SERVICE',
        data: {
          'auth_user_id': authUserId,
          'email': email,
          'full_name': fullName,
          'has_phone': phone != null,
          'has_photo_url': photoUrl != null,
          'user_type': userType
        });

    // Telefone é opcional na criação - campo tem DEFAULT 'pending' no banco
    final initialPhone = phone?.trim();
    if (initialPhone != null && initialPhone.isNotEmpty) {
      AppLogger.success('Telefone fornecido na criação', tag: 'USER_SERVICE');
    } else {
      AppLogger.info('Usuário será criado com telefone padrão (pending)',
          tag: 'USER_SERVICE');
    }

    // VALIDAÇÃO SIMPLIFICADA: Apenas validação básica necessária
    try {
      print('🔍 [$timestamp] [USER_SERVICE] Iniciando UserDataValidator...');
      final validatedData = UserDataValidator.validateUserData(
        fullName: fullName,
        email: email,
        userType: userType,
        phone: phone,
        photoUrl: photoUrl,
      );

      print('✅ [$timestamp] [USER_SERVICE] UserDataValidator concluído');
      print('📊 [$timestamp] [USER_SERVICE] Dados antes da validação:');
      print('  - fullName: $fullName');
      print('  - email: $email');
      print('  - phone: $phone');
      print('  - photoUrl: $photoUrl');

      // Usar dados validados
      fullName = validatedData['full_name'];
      email = validatedData['email'];
      userType = validatedData['user_type'];
      phone = validatedData['phone'];
      photoUrl = validatedData['photo_url'];

      print('📊 [$timestamp] [USER_SERVICE] Dados após validação:');
      print('  - fullName: $fullName');
      print('  - email: $email');
      print('  - phone: $phone');
      print('  - photoUrl: $photoUrl');
    } on validation.ValidationException catch (e) {
      print('❌ [$timestamp] [USER_SERVICE] ValidationException: ${e.message}');
      throw DatabaseException('Dados inválidos: ${e.message}');
    }

    try {
      // Verificar se o usuário já existe por ID
      print(
          '🔍 [$timestamp] [USER_SERVICE] Verificando se usuário já existe por ID...');
      final existingUser = await getUserById(authUserId);
      if (existingUser != null) {
        print('❌ [$timestamp] [USER_SERVICE] Usuário já existe por ID: $email');
        throw UserAlreadyExistsException(email);
      }
      print(
          '✅ [$timestamp] [USER_SERVICE] Usuário não existe por ID, continuando...');
    } catch (e) {
      if (e is UserAlreadyExistsException) rethrow;
      print(
          'ℹ️ [$timestamp] [USER_SERVICE] Erro ao verificar usuário existente por ID (normal): $e');
      // Se não encontrou o usuário, continua com a criação
    }

    // Verificar se já existe usuário com o mesmo email
    try {
      print(
          '🔍 [$timestamp] [USER_SERVICE] Verificando se email já existe: $email');
      final existingUserByEmail = await getUserByEmail(email);
      if (existingUserByEmail != null) {
        print(
            '❌ [$timestamp] [USER_SERVICE] Email já existe: $email (ID: ${existingUserByEmail.id})');
        throw UserAlreadyExistsException(email);
      }
      print('✅ [$timestamp] [USER_SERVICE] Email disponível: $email');
    } catch (e) {
      if (e is UserAlreadyExistsException) rethrow;
      print(
          'ℹ️ [$timestamp] [USER_SERVICE] Erro ao verificar email existente (normal): $e');
    }

    // 🔍 VALIDAÇÃO FINAL: Verificar telefone novamente antes da inserção
    print(
        '🔍 [$timestamp] [USER_SERVICE] Telefone antes da inserção: ${phone ?? 'null (usará default pending)'}');
    final finalPhone = phone?.trim();
    if (finalPhone != null && finalPhone.isNotEmpty) {
      print('✅ [$timestamp] [USER_SERVICE] Telefone fornecido: $finalPhone');
    } else {
      print(
          'ℹ️ [$timestamp] [USER_SERVICE] Usuário será criado com telefone padrão (pending)');
    }

    try {
      final userData = {
        'id': authUserId, // PK: UUID do auth.users
        'email': email,
        'full_name': fullName,
        'user_type': userType,
        'status': 'active',
        'profile_complete': false, // New users start with incomplete profile
      };

      // Só incluir phone se fornecido, senão usar DEFAULT 'pending' do banco
      if (finalPhone != null && finalPhone.isNotEmpty) {
        userData['phone'] = finalPhone;
      }

      // Só incluir photo_url se fornecida
      if (photoUrl != null && photoUrl.isNotEmpty) {
        userData['photo_url'] = photoUrl;
      }

      print('📝 [$timestamp] [USER_SERVICE] Usando telefone: $finalPhone');

      print('📝 [$timestamp] [USER_SERVICE] Inserindo dados do usuário:');
      print('  - Dados: $userData');

      final response =
          await _supabase.from('app_users').insert(userData).select().single();

      print('✅ [$timestamp] [USER_SERVICE] Usuário criado com sucesso!');
      print('📄 [$timestamp] [USER_SERVICE] Resposta: $response');

      final user = User.fromMap(response);

      // Create corresponding passenger or driver record
      print(
          '🔄 [$timestamp] [USER_SERVICE] Criando registro específico para ${user.userType}...');
      await _createUserSpecificRecord(user);
      print(
          '✅ [$timestamp] [USER_SERVICE] Processo completo finalizado com sucesso!');

      return user;
    } on PostgrestException catch (e) {
      final context = {
        'operation': 'createUser',
        'authUserId': authUserId,
        'email': email,
        'userType': userType,
        'postgrestCode': e.code,
        'postgrestMessage': e.message,
        'postgrestDetails': e.details,
        'postgrestHint': e.hint
      };

      await ErrorLoggingService.instance.logException(
        e,
        context: context,
        type: AppErrorType.databaseError,
        severity: ErrorSeverity.high,
      );

      throw PostgrestErrorMapper.mapError(e, context: context);
    } catch (e) {
      final context = {
        'operation': 'createUser',
        'authUserId': authUserId,
        'email': email,
        'userType': userType,
        'errorType': e.runtimeType.toString()
      };

      if (e is Exception) {
        await ErrorLoggingService.instance.logException(
          e,
          context: context,
          type: AppErrorType.databaseError,
          severity: ErrorSeverity.high,
        );
      }

      throw DatabaseException(
          'Erro inesperado ao criar usuário: ${e.toString()}');
    }
  }

  /// Busca um usuário pelo ID
  static Future<User?> getUserById(String userId) async {
    final startTime = DateTime.now();

    try {
      AppLogger.process('Buscando usuário por ID', tag: 'USER_SERVICE');
      AppLogger.read('User', userId, tag: 'USER_SERVICE');

      final response = await _supabase
          .from('app_users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      AppLogger.debug('Resposta bruta do Supabase',
          tag: 'USER_SERVICE',
          data: {'response_type': response.runtimeType.toString()});

      if (response == null) {
        AppLogger.warning('Usuário não encontrado', tag: 'USER_SERVICE');
        return null;
      }

      final user = User.fromMap(response);
      final duration = DateTime.now().difference(startTime);

      AppLogger.performance('get_user_by_id', duration, tag: 'USER_SERVICE');
      AppLogger.success('Usuário encontrado', tag: 'USER_SERVICE');

      return user;
    } on PostgrestException catch (e) {
      print('❌ [DEBUG] PostgrestException: ${e.message}');
      throw PostgrestErrorMapper.mapError(e,
          context: {'operation': 'getUserById', 'userId': userId});
    } catch (e) {
      print('❌ [DEBUG] Erro inesperado em getUserById: $e');
      throw const DatabaseException(
          'Erro inesperado ao buscar usuário. Por favor, tente novamente mais tarde.');
    }
  }

  /// Busca um usuário pelo email
  static Future<User?> getUserByEmail(String email) async {
    final startTime = DateTime.now();

    try {
      AppLogger.process('Buscando usuário por email', tag: 'USER_SERVICE');
      AppLogger.query('app_users', 1,
          tag: 'USER_SERVICE', filters: {'email': email});

      final response = await _supabase
          .from('app_users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (response == null) {
        AppLogger.warning('Usuário não encontrado por email',
            tag: 'USER_SERVICE');
        return null;
      }

      final user = User.fromMap(response);
      final duration = DateTime.now().difference(startTime);

      AppLogger.performance('get_user_by_email', duration, tag: 'USER_SERVICE');
      AppLogger.success('Usuário encontrado por email', tag: 'USER_SERVICE');

      return user;
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e,
          context: {'operation': 'getUserByEmail', 'email': email});
    } catch (e) {
      throw Exception(
          'Erro inesperado ao buscar usuário por email. Por favor, tente novamente mais tarde.');
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
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e,
          context: {'operation': 'getUserByPhone', 'phone': phone});
    } catch (e) {
      throw Exception(
          'Erro inesperado ao buscar usuário por telefone. Por favor, tente novamente mais tarde.');
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
    final startTime = DateTime.now();

    AppLogger.process('Iniciando atualização de usuário', tag: 'USER_SERVICE');
    AppLogger.update('User', userId, tag: 'USER_SERVICE', changes: {
      'full_name': fullName != null,
      'phone': phone != null,
      'photo_url': photoUrl != null,
      'user_type': userType != null,
      'status': status != null
    });

    // 🚨 VALIDAÇÃO CRÍTICA: NUNCA permitir dados corrompidos
    try {
      if (fullName != null) {
        UserDataValidator.validateAndSanitizeFullName(fullName);
        AppLogger.validation('full_name', true, entity: 'User');
      }
      if (phone != null) {
        UserDataValidator.validatePhone(phone);
        AppLogger.validation('phone', true, entity: 'User');
      }
      if (userType != null) {
        UserDataValidator.validateUserType(userType);
        AppLogger.validation('user_type', true, entity: 'User');
      }
    } on validation.ValidationException catch (e) {
      AppLogger.validation('user_data', false,
          entity: 'User', error: e.message);
      throw DatabaseException(
          'Dados inválidos fornecidos para atualização: ${e.message}');
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

      // Tratamento específico para sync_control antes do mapeamento geral
      if (e.code == '42P01' && (e.message.contains('sync_control') ?? false)) {
        throw const DatabaseException(
            'Sistema de sincronização não configurado. Entre em contato com o suporte.',
            'SYNC_ERROR');
      }

      throw PostgrestErrorMapper.mapError(e, context: {
        'operation': 'updateUser',
        'userId': userId,
        'updateFields': updateData.keys.toList()
      });
    } catch (e) {
      throw const DatabaseException(
          'Erro inesperado ao atualizar usuário. Por favor, tente novamente mais tarde.');
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
      throw PostgrestErrorMapper.mapError(e, context: {
        'operation': 'updateUserType',
        'userId': userId,
        'userType': userType
      });
    } catch (e) {
      throw const DatabaseException(
          'Erro inesperado ao atualizar tipo de usuário. Por favor, tente novamente mais tarde.');
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
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e,
          context: {'operation': 'userExists', 'userId': userId});
    } catch (e) {
      throw Exception(
          'Erro inesperado ao verificar usuário. Por favor, tente novamente mais tarde.');
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
      throw Exception(
          'Erro ao obter usuário atual. Por favor, tente novamente mais tarde.');
    }
  }

  /// Deleta um usuário (soft delete - marca como inativo)
  static Future<void> deactivateUser(String userId) async {
    try {
      await _supabase.from('app_users').update({
        'status': 'inactive',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e,
          context: {'operation': 'deactivateUser', 'userId': userId});
    } catch (e) {
      throw Exception(
          'Erro inesperado ao desativar usuário. Por favor, tente novamente mais tarde.');
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
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e, context: {
        'operation': 'getUsersByType',
        'userType': userType,
        'limit': limit,
        'offset': offset
      });
    } catch (e) {
      throw Exception(
          'Erro inesperado ao buscar usuários. Por favor, tente novamente mais tarde.');
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

      await _supabase.from('passengers').insert(passengerData);

      print('✅ Registro de passageiro criado com sucesso');
    } on PostgrestException catch (e) {
      print(
          '❌ PostgrestException ao criar passageiro: ${e.code} - ${e.message}');
      throw PostgrestErrorMapper.mapError(e,
          context: {'operation': 'createPassengerRecord', 'userId': user.id});
    } catch (e) {
      print('❌ Erro inesperado ao criar passageiro: $e');
      throw DatabaseException(
          'Erro inesperado ao criar registro de passageiro: ${e.toString()}');
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

      // Get first available category from platform_settings instead of hardcoded value
      String defaultCategory = VehicleCategory.commonCar.id; // fallback
      try {
        final platformSettingsService = PlatformSettingsService(_supabase);
        final availableSettings = await platformSettingsService.getAllSettings();
        if (availableSettings.isNotEmpty) {
          defaultCategory = availableSettings.first.category;
          print('✅ Usando categoria do platform_settings: $defaultCategory');
        } else {
          print('⚠️ Platform_settings vazio, usando fallback: $defaultCategory');
        }
      } catch (e) {
        print('⚠️ Erro ao buscar platform_settings, usando fallback: $e');
      }

      // Create basic driver record with placeholder values - will be filled during driver onboarding
      final driverData = {
        'user_id': user.id,
        'vehicle_brand': 'PENDENTE',
        'vehicle_model': 'PENDENTE',
        'vehicle_year': 2020,
        'vehicle_color': 'PENDENTE',
        'vehicle_plate': 'PENDENTE_${user.id.substring(0, 8)}',
        'vehicle_category': defaultCategory, // Usar categoria do platform_settings
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

      await _supabase.from('drivers').insert(driverData);

      print('✅ Registro básico de motorista criado com sucesso');
    } on PostgrestException catch (e) {
      print(
          '❌ PostgrestException ao criar motorista: ${e.code} - ${e.message}');
      throw PostgrestErrorMapper.mapError(e,
          context: {'operation': 'createDriverRecord', 'userId': user.id});
    } catch (e) {
      print('❌ Erro inesperado ao criar motorista: $e');
      throw DatabaseException(
          'Erro inesperado ao criar registro de motorista: ${e.toString()}');
    }
  }

  /// Marca o perfil do usuário como completo
  static Future<void> markProfileComplete(String userId) async {
    final timestamp = DateTime.now().toIso8601String();
    print(
        '🏁 [$timestamp] [USER_SERVICE] Marcando perfil como completo para usuário: $userId');

    try {
      await _supabase.from('app_users').update({
        'profile_complete': true,
        'updated_at': timestamp,
      }).eq('id', userId);

      print(
          '✅ [$timestamp] [USER_SERVICE] Perfil marcado como completo com sucesso');
    } on PostgrestException catch (e) {
      print(
          '❌ [$timestamp] [USER_SERVICE] PostgrestException ao marcar perfil: ${e.code} - ${e.message}');
      throw PostgrestErrorMapper.mapError(e,
          context: {'operation': 'markProfileComplete', 'userId': userId});
    } catch (e) {
      print(
          '❌ [$timestamp] [USER_SERVICE] Erro ao marcar perfil como completo: $e');
      throw DatabaseException(
          'Erro ao marcar perfil como completo: ${e.toString()}');
    }
  }

  /// Verifica se o perfil do usuário está completo
  static Future<bool> isProfileComplete(String userId) async {
    try {
      final user = await getUserById(userId);
      return user?.profileComplete ?? false;
    } catch (e) {
      print('❌ [USER_SERVICE] Erro ao verificar completude do perfil: $e');
      return false; // Em caso de erro, assume que não está completo
    }
  }
}
