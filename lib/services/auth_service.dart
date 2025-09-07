import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../utils/supabase_helper.dart';
import '../exceptions/app_exceptions.dart';
import '../models/user.dart';
import 'user_service.dart';
import 'app_logger.dart';

/// Serviço de autenticação com validação de segurança sem RLS
/// Implementa todas as verificações de ownership e autorização no lado da aplicação
class AuthService {
  static SupabaseClient get _supabase {
    final client = SupabaseHelper.client;
    if (client == null) {
      throw Exception('Supabase não foi inicializado.');
    }
    return client;
  }

  /// Obtém o ID do usuário atual autenticado
  static String? getCurrentUserId() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      AppLogger.read('AuthUser', userId, tag: 'AUTH');
    }
    return userId;
  }

  /// Obtém o usuário atual autenticado
  static User? getCurrentAuthUser() {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;
    
    return User(
      id: authUser.id,
      email: authUser.email ?? '',
      fullName: authUser.userMetadata?['full_name'] ?? '',
      phone: authUser.phone ?? '',
      photoUrl: authUser.userMetadata?['photo_url'],
      userType: authUser.userMetadata?['user_type'] ?? 'passenger',
      status: 'active',
      createdAt: DateTime.parse(authUser.createdAt),
      updatedAt: DateTime.now(),
    );
  }

  /// Verifica se o usuário está autenticado
  static bool isAuthenticated() {
    final isAuth = _supabase.auth.currentUser != null;
    AppLogger.validation('authentication_status', isAuth, entity: 'AuthService');
    return isAuth;
  }

  /// Verifica se o usuário atual é o proprietário do recurso
  static Future<bool> isUserAuthorized(String resourceUserId) async {
    final startTime = DateTime.now();
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) {
      AppLogger.security('unauthorized_access_attempt', details: 'User not authenticated for resource: $resourceUserId');
      throw const AuthException('Usuário não autenticado');
    }
    
    final isAuthorized = currentUserId == resourceUserId;
    final duration = DateTime.now().difference(startTime);
    
    AppLogger.performance('user_authorization_check', duration, tag: 'AUTH');
    AppLogger.security('authorization_check', 
      userId: currentUserId, 
      details: 'Resource: $resourceUserId, Authorized: $isAuthorized'
    );
    
    return isAuthorized;
  }

  /// Verifica se o usuário tem uma role específica
  static Future<bool> hasRole(String requiredRole) async {
    final startTime = DateTime.now();
    final currentUserId = getCurrentUserId();
    
    if (currentUserId == null) {
      AppLogger.security('role_check_unauthorized', details: 'Required role: $requiredRole');
      throw const AuthException('Usuário não autenticado');
    }

    try {
      AppLogger.query('app_users', 1, tag: 'AUTH', filters: {'role_check': requiredRole, 'user_id': currentUserId});
      
      final response = await _supabase
          .from('app_users')
          .select('user_type')
          .eq('id', currentUserId)
          .maybeSingle();

      if (response == null) {
        AppLogger.security('user_not_found_in_role_check', userId: currentUserId, details: 'Required role: $requiredRole');
        throw const AuthException('Usuário não encontrado');
      }

      final hasRequiredRole = response['user_type'] == requiredRole;
      final duration = DateTime.now().difference(startTime);
      
      AppLogger.performance('role_verification', duration, tag: 'AUTH');
      AppLogger.security('role_check_completed', 
        userId: currentUserId, 
        details: 'Required: $requiredRole, Has role: $hasRequiredRole'
      );
      
      return hasRequiredRole;
    } catch (e) {
      AppLogger.error('Erro ao verificar role do usuário', tag: 'AUTH', error: e);
      throw DatabaseException('Erro ao verificar role do usuário: $e');
    }
  }

  /// Obtém o usuário completo da aplicação
  static Future<User?> getCurrentUser() async {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) {
      return null;
    }

    try {
      return await UserService.getUserById(currentUserId);
    } catch (e) {
      print('❌ Erro ao buscar usuário atual: $e');
      return null;
    }
  }

  /// Valida se o usuário pode acessar um recurso específico
  static Future<void> validateUserAccess({
    required String resourceUserId,
    String? requiredRole,
    String? operation,
  }) async {
    // Verificar autenticação
    if (!isAuthenticated()) {
      throw const AuthException('Usuário não autenticado');
    }

    final currentUserId = getCurrentUserId()!;
    
    // Log da tentativa de acesso
    print('🔒 [AUTH] Validando acesso:');
    print('  - Usuário atual: $currentUserId');
    print('  - Recurso: $resourceUserId');
    print('  - Role requerida: ${requiredRole ?? 'nenhuma'}');
    print('  - Operação: ${operation ?? 'não especificada'}');

    // Verificar se é o próprio usuário
    if (currentUserId == resourceUserId) {
      print('✅ [AUTH] Acesso autorizado: próprio usuário');
      return;
    }

    // Verificar role se necessário
    if (requiredRole != null) {
      final hasRequiredRole = await hasRole(requiredRole);
      if (hasRequiredRole) {
        print('✅ [AUTH] Acesso autorizado: role $requiredRole');
        return;
      }
    }

    // Verificar se é admin (sempre tem acesso)
    final isAdmin = await hasRole('admin');
    if (isAdmin) {
      print('✅ [AUTH] Acesso autorizado: usuário admin');
      return;
    }

    print('❌ [AUTH] Acesso negado');
    throw const AuthException('Acesso negado: você não tem permissão para acessar este recurso');
  }

  /// Registra um novo usuário
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String userType = 'passenger',
  }) async {
    final startTime = DateTime.now();
    
    try {
      AppLogger.process('Iniciando registro de usuário', tag: 'AUTH');
      AppLogger.create('User Registration Attempt', email, tag: 'AUTH', data: {
        'email': email,
        'full_name': fullName,
        'user_type': userType,
        'has_phone': phone != null
      });

      // Criar usuário no auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'user_type': userType,
        },
      );

      if (response.user == null) {
        AppLogger.error('Falha ao criar usuário no auth', tag: 'AUTH');
        throw const AuthException('Falha ao criar usuário');
      }

      final authUser = response.user!;
      AppLogger.success('Usuário criado no auth', tag: 'AUTH');
      AppLogger.create('AuthUser', authUser.id, tag: 'AUTH');

      // Criar usuário na tabela app_users
      try {
        final appUser = await UserService.createUser(
          authUserId: authUser.id,
          email: email,
          fullName: fullName,
          phone: phone ?? '',
          userType: userType,
        );

        AppLogger.success('Usuário criado na aplicação', tag: 'AUTH');
        AppLogger.create('AppUser', appUser.id, tag: 'AUTH');
        
        final duration = DateTime.now().difference(startTime);
        AppLogger.performance('user_registration', duration, tag: 'AUTH');
        
        AppLogger.security('user_registration_success', 
          userId: authUser.id, 
          details: 'Type: $userType, Needs confirmation: ${response.session == null}'
        );

        return {
          'success': true,
          'user_id': authUser.id,
          'email': authUser.email,
          'needs_confirmation': response.session == null,
          'message': response.session == null
              ? 'Verifique seu email para confirmar a conta'
              : 'Conta criada com sucesso!',
        };
      } catch (e) {
        // Se falhar ao criar app_user, remover do auth
        AppLogger.warning('Erro ao criar app_user, iniciando rollback', tag: 'AUTH');
        AppLogger.delete('AuthUser', authUser.id, tag: 'AUTH', reason: 'Rollback due to app_user creation failure');
        
        try {
          await _supabase.auth.admin.deleteUser(authUser.id);
          AppLogger.success('Rollback concluído - usuário removido do auth', tag: 'AUTH');
        } catch (deleteError) {
          AppLogger.error('Erro ao remover usuário do auth durante rollback', tag: 'AUTH', error: deleteError);
        }
        rethrow;
      }
    } on AuthException catch (e) {
      AppLogger.error('AuthException durante registro', tag: 'AUTH', error: e);
      AppLogger.security('user_registration_failed', details: 'AuthException: ${e.message}');
      throw AuthException('Erro de autenticação: ${e.message}');
    } catch (e) {
      AppLogger.error('Erro geral durante registro', tag: 'AUTH', error: e);
      AppLogger.security('user_registration_failed', details: 'General error: $e');
      throw Exception('Erro ao criar conta: $e');
    }
  }

  /// Faz login do usuário
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final startTime = DateTime.now();
    
    try {
      AppLogger.process('Tentando login', tag: 'AUTH');
      AppLogger.security('login_attempt', details: 'Email: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null || response.session == null) {
        AppLogger.security('login_failed', details: 'Invalid credentials for: $email');
        throw const AuthException('Falha no login');
      }

      final userId = response.user!.id;
      AppLogger.success('Login realizado com sucesso', tag: 'AUTH');
      AppLogger.security('login_success', userId: userId);

      // Verificar se o usuário existe na tabela app_users
      final appUser = await UserService.getUserById(userId);
      if (appUser == null) {
        AppLogger.warning('Usuário não encontrado em app_users, criando registro', tag: 'AUTH');
        
        // Criar registro em app_users se não existir
        await UserService.createUser(
          authUserId: userId,
          email: response.user!.email!,
          fullName: response.user!.userMetadata?['full_name'] ?? 'Usuário',
          phone: response.user!.phone ?? '',
          userType: response.user!.userMetadata?['user_type'] ?? 'passenger',
        );
        
        AppLogger.create('AppUser', userId, tag: 'AUTH', data: {'reason': 'Missing app_users record'});
      } else {
        AppLogger.read('AppUser', userId, tag: 'AUTH');
      }

      final duration = DateTime.now().difference(startTime);
      AppLogger.performance('user_login', duration, tag: 'AUTH');

      return {
        'success': true,
        'user_id': userId,
        'email': response.user!.email,
        'session': response.session,
        'message': 'Login realizado com sucesso!',
      };
    } on AuthException catch (e) {
      AppLogger.error('AuthException durante login', tag: 'AUTH', error: e);
      AppLogger.security('login_failed', details: 'AuthException: ${e.message}');
      throw AuthException('Erro de login: ${e.message}');
    } catch (e) {
      AppLogger.error('Erro geral durante login', tag: 'AUTH', error: e);
      AppLogger.security('login_failed', details: 'General error: $e');
      throw Exception('Erro ao fazer login: $e');
    }
  }

  /// Faz logout do usuário
  static Future<void> signOut() async {
    final startTime = DateTime.now();
    final userId = getCurrentUserId();
    
    try {
      AppLogger.process('Fazendo logout', tag: 'AUTH');
      AppLogger.security('logout_attempt', userId: userId);
      
      await _supabase.auth.signOut();
      
      final duration = DateTime.now().difference(startTime);
      AppLogger.performance('user_logout', duration, tag: 'AUTH');
      AppLogger.success('Logout realizado com sucesso', tag: 'AUTH');
      AppLogger.security('logout_success', userId: userId);
    } catch (e) {
      AppLogger.error('Erro ao fazer logout', tag: 'AUTH', error: e);
      AppLogger.security('logout_failed', userId: userId, details: 'Error: $e');
      throw Exception('Erro ao fazer logout: $e');
    }
  }

  /// Redefine a senha do usuário
  static Future<void> resetPassword(String email) async {
    final startTime = DateTime.now();
    
    try {
      AppLogger.process('Enviando email de redefinição de senha', tag: 'AUTH');
      AppLogger.security('password_reset_attempt', details: 'Email: $email');

      await _supabase.auth.resetPasswordForEmail(email);
      
      final duration = DateTime.now().difference(startTime);
      AppLogger.performance('password_reset_email', duration, tag: 'AUTH');
      AppLogger.success('Email de redefinição enviado com sucesso', tag: 'AUTH');
      AppLogger.security('password_reset_email_sent', details: 'Email: $email');
    } on AuthException catch (e) {
      AppLogger.error('AuthException durante reset de senha', tag: 'AUTH', error: e);
      AppLogger.security('password_reset_failed', details: 'AuthException: ${e.message}');
      throw AuthException('Erro ao enviar email: ${e.message}');
    } catch (e) {
      AppLogger.error('Erro geral durante reset de senha', tag: 'AUTH', error: e);
      AppLogger.security('password_reset_failed', details: 'General error: $e');
      throw Exception('Erro ao enviar email de redefinição: $e');
    }
  }

  /// Atualiza o perfil do usuário
  static Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? photoUrl,
  }) async {
    final startTime = DateTime.now();
    final currentUserId = getCurrentUserId();
    
    if (currentUserId == null) {
      AppLogger.security('profile_update_unauthorized', details: 'User not authenticated');
      throw const AuthException('Usuário não autenticado');
    }

    try {
      AppLogger.process('Atualizando perfil do usuário', tag: 'AUTH');
      AppLogger.update('UserProfile', currentUserId, tag: 'AUTH', changes: {
        'full_name': fullName != null,
        'phone': phone != null,
        'photo_url': photoUrl != null
      });

      // Atualizar metadados no auth se necessário
      if (fullName != null) {
        await _supabase.auth.updateUser(
          UserAttributes(
            data: {'full_name': fullName},
          ),
        );
        AppLogger.update('AuthUserMetadata', currentUserId, tag: 'AUTH', changes: {'full_name': fullName});
      }

      // Atualizar dados em app_users
      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['full_name'] = fullName;
      if (phone != null) updateData['phone'] = phone;
      if (photoUrl != null) updateData['photo_url'] = photoUrl;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      if (updateData.isNotEmpty) {
        await _supabase
            .from('app_users')
            .update(updateData)
            .eq('id', currentUserId);
        
        AppLogger.update('AppUser', currentUserId, tag: 'AUTH', changes: updateData);
      }

      final duration = DateTime.now().difference(startTime);
      AppLogger.performance('profile_update', duration, tag: 'AUTH');
      AppLogger.success('Perfil atualizado com sucesso', tag: 'AUTH');
      AppLogger.security('profile_updated', userId: currentUserId, details: 'Fields updated: ${updateData.keys.join(', ')}');
    } catch (e) {
      AppLogger.error('Erro ao atualizar perfil', tag: 'AUTH', error: e);
      AppLogger.security('profile_update_failed', userId: currentUserId, details: 'Error: $e');
      throw Exception('Erro ao atualizar perfil: $e');
    }
  }

  /// Registra evento de auditoria
  static Future<void> logSecurityEvent({
    required String eventType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return;

    try {
      final auditData = {
        'user_id': currentUserId,
        'event_type': eventType,
        'description': description,
        'metadata': metadata ?? {},
        'ip_address': 'mobile_app',
        'user_agent': 'Flutter Mobile App',
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('audit_logs').insert(auditData);
      print('✅ [AUTH] Evento de auditoria registrado: $eventType');
    } catch (e) {
      print('❌ [AUTH] Erro ao registrar evento de auditoria: $e');
      // Não falha a operação principal se o log falhar
    }
  }
}