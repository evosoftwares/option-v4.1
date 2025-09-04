import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../utils/supabase_helper.dart';
import '../exceptions/app_exceptions.dart';
import '../models/user.dart';
import 'user_service.dart';

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
    return _supabase.auth.currentUser?.id;
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
    return _supabase.auth.currentUser != null;
  }

  /// Verifica se o usuário atual é o proprietário do recurso
  static Future<bool> isUserAuthorized(String resourceUserId) async {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) {
      throw const AuthException('Usuário não autenticado');
    }
    return currentUserId == resourceUserId;
  }

  /// Verifica se o usuário tem uma role específica
  static Future<bool> hasRole(String requiredRole) async {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) {
      throw const AuthException('Usuário não autenticado');
    }

    try {
      final response = await _supabase
          .from('app_users')
          .select('user_type')
          .eq('id', currentUserId)
          .maybeSingle();

      if (response == null) {
        throw const AuthException('Usuário não encontrado');
      }

      return response['user_type'] == requiredRole;
    } catch (e) {
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
    try {
      print('🚀 [AUTH] Iniciando registro de usuário...');
      print('  - Email: $email');
      print('  - Nome: $fullName');
      print('  - Tipo: $userType');

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
        throw const AuthException('Falha ao criar usuário');
      }

      final authUser = response.user!;
      print('✅ [AUTH] Usuário criado no auth: ${authUser.id}');

      // Criar usuário na tabela app_users
      try {
        final appUser = await UserService.createUser(
          authUserId: authUser.id,
          email: email,
          fullName: fullName,
          phone: phone ?? '',
          userType: userType,
        );

        print('✅ [AUTH] Usuário criado na aplicação: ${appUser.id}');

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
        print('❌ [AUTH] Erro ao criar app_user, removendo do auth...');
        try {
          await _supabase.auth.admin.deleteUser(authUser.id);
        } catch (deleteError) {
          print('❌ [AUTH] Erro ao remover usuário do auth: $deleteError');
        }
        rethrow;
      }
    } on AuthException catch (e) {
      print('❌ [AUTH] AuthException: ${e.message}');
      throw AuthException('Erro de autenticação: ${e.message}');
    } catch (e) {
      print('❌ [AUTH] Erro geral: $e');
      throw Exception('Erro ao criar conta: $e');
    }
  }

  /// Faz login do usuário
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔑 [AUTH] Tentando login...');
      print('  - Email: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null || response.session == null) {
        throw const AuthException('Falha no login');
      }

      print('✅ [AUTH] Login realizado com sucesso: ${response.user!.id}');

      // Verificar se o usuário existe na tabela app_users
      final appUser = await UserService.getUserById(response.user!.id);
      if (appUser == null) {
        print('⚠️ [AUTH] Usuário não encontrado em app_users, criando...');
        
        // Criar registro em app_users se não existir
        await UserService.createUser(
          authUserId: response.user!.id,
          email: response.user!.email!,
          fullName: response.user!.userMetadata?['full_name'] ?? 'Usuário',
          phone: response.user!.phone ?? '',
          userType: response.user!.userMetadata?['user_type'] ?? 'passenger',
        );
      }

      return {
        'success': true,
        'user_id': response.user!.id,
        'email': response.user!.email,
        'session': response.session,
        'message': 'Login realizado com sucesso!',
      };
    } on AuthException catch (e) {
      print('❌ [AUTH] AuthException: ${e.message}');
      throw AuthException('Erro de login: ${e.message}');
    } catch (e) {
      print('❌ [AUTH] Erro geral: $e');
      throw Exception('Erro ao fazer login: $e');
    }
  }

  /// Faz logout do usuário
  static Future<void> signOut() async {
    try {
      print('👋 [AUTH] Fazendo logout...');
      await _supabase.auth.signOut();
      print('✅ [AUTH] Logout realizado com sucesso');
    } catch (e) {
      print('❌ [AUTH] Erro ao fazer logout: $e');
      throw Exception('Erro ao fazer logout: $e');
    }
  }

  /// Redefine a senha do usuário
  static Future<void> resetPassword(String email) async {
    try {
      print('🔄 [AUTH] Enviando email de redefinição de senha...');
      print('  - Email: $email');

      await _supabase.auth.resetPasswordForEmail(email);
      print('✅ [AUTH] Email de redefinição enviado com sucesso');
    } on AuthException catch (e) {
      print('❌ [AUTH] AuthException: ${e.message}');
      throw AuthException('Erro ao enviar email: ${e.message}');
    } catch (e) {
      print('❌ [AUTH] Erro geral: $e');
      throw Exception('Erro ao enviar email de redefinição: $e');
    }
  }

  /// Atualiza o perfil do usuário
  static Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? photoUrl,
  }) async {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) {
      throw const AuthException('Usuário não autenticado');
    }

    try {
      print('🔄 [AUTH] Atualizando perfil do usuário: $currentUserId');

      // Atualizar metadados no auth se necessário
      if (fullName != null) {
        await _supabase.auth.updateUser(
          UserAttributes(
            data: {'full_name': fullName},
          ),
        );
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
      }

      print('✅ [AUTH] Perfil atualizado com sucesso');
    } catch (e) {
      print('❌ [AUTH] Erro ao atualizar perfil: $e');
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