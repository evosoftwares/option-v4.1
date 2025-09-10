import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';
import '../../data/models/user_model.dart';
import '../datasources/auth_api_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApiDataSource _authDataSource;

  AuthRepositoryImpl(this._authDataSource);

  @override
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String userType = 'passenger',
  }) async {
    try {
      // 1. Criar usuário no sistema de auth
      final authResponse = await _authDataSource.signUp(
        email: email,
        password: password,
        userData: {
          'full_name': fullName,
          'user_type': userType,
        },
      );

      if (authResponse.user == null) {
        throw Exception('Falha ao criar usuário no sistema de autenticação');
      }

      final authUser = authResponse.user!;

      // 2. Criar usuário na tabela app_users
      try {
        final appUserData = {
          'id': authUser.id,
          'email': email,
          'full_name': fullName,
          'phone': phone ?? '',
          'user_type': userType,
          'status': 'active',
          'profile_complete': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await _authDataSource.createUserInAppUsers(appUserData);

        return {
          'success': true,
          'user_id': authUser.id,
          'email': authUser.email,
          'needs_confirmation': authResponse.session == null,
          'message': authResponse.session == null
              ? 'Verifique seu email para confirmar a conta'
              : 'Conta criada com sucesso!',
        };
      } catch (e) {
        // Rollback: remover usuário do auth se app_users falhar
        try {
          await _authDataSource.deleteUser(authUser.id);
        } catch (deleteError) {
          // Log erro de rollback mas não falha
        }
        rethrow;
      }
    } on AuthException catch (e) {
      throw Exception('Erro de autenticação: ${e.message}');
    } catch (e) {
      throw Exception('Erro ao criar conta: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final authResponse = await _authDataSource.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null || authResponse.session == null) {
        throw Exception('Credenciais inválidas');
      }

      final userId = authResponse.user!.id;

      // Verificar se o usuário existe na tabela app_users
      final appUser = await _authDataSource.getUserFromAppUsers(userId);
      if (appUser == null) {
        // Criar registro em app_users se não existir
        final appUserData = {
          'id': userId,
          'email': authResponse.user!.email!,
          'full_name': authResponse.user!.userMetadata?['full_name'] ?? 'Usuário',
          'phone': authResponse.user!.phone ?? '',
          'user_type': authResponse.user!.userMetadata?['user_type'] ?? 'passenger',
          'status': 'active',
          'profile_complete': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await _authDataSource.createUserInAppUsers(appUserData);
      }

      return {
        'success': true,
        'user_id': userId,
        'email': authResponse.user!.email,
        'session': authResponse.session,
        'message': 'Login realizado com sucesso!',
      };
    } on AuthException catch (e) {
      throw Exception('Erro de login: ${e.message}');
    } catch (e) {
      throw Exception('Erro ao fazer login: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _authDataSource.signOut();
    } catch (e) {
      throw Exception('Erro ao fazer logout: $e');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _authDataSource.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception('Erro ao enviar email: ${e.message}');
    } catch (e) {
      throw Exception('Erro ao enviar email de redefinição: $e');
    }
  }

  @override
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? photoUrl,
  }) async {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      // Atualizar metadados no auth se necessário
      if (fullName != null) {
        await _authDataSource.updateUser(
          UserAttributes(data: {'full_name': fullName}),
        );
      }

      // Atualizar dados em app_users
      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['full_name'] = fullName;
      if (phone != null) updateData['phone'] = phone;
      if (photoUrl != null) updateData['photo_url'] = photoUrl;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      if (updateData.isNotEmpty) {
        await _authDataSource.updateUserInAppUsers(currentUserId, updateData);
      }
    } catch (e) {
      throw Exception('Erro ao atualizar perfil: $e');
    }
  }

  @override
  String? getCurrentUserId() {
    return _authDataSource.getCurrentUserId();
  }

  @override
  bool isAuthenticated() {
    return _authDataSource.isAuthenticated();
  }

  @override
  Future<bool> hasRole(String requiredRole) async {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      final userType = await _authDataSource.getUserType(currentUserId);
      return userType == requiredRole;
    } catch (e) {
      throw Exception('Erro ao verificar role do usuário: $e');
    }
  }

  /// Método adicional para obter o usuário completo
  Future<User?> getCurrentUser() async {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) {
      return null;
    }

    try {
      final userData = await _authDataSource.getUserFromAppUsers(currentUserId);
      if (userData == null) {
        return null;
      }

      final userModel = UserModel.fromMap(userData);
      return userModel.toEntity();
    } catch (e) {
      return null;
    }
  }

  /// Método para validar acesso do usuário
  Future<void> validateUserAccess({
    required String resourceUserId,
    String? requiredRole,
  }) async {
    if (!isAuthenticated()) {
      throw Exception('Usuário não autenticado');
    }

    final currentUserId = getCurrentUserId()!;

    // Verificar se é o próprio usuário
    if (currentUserId == resourceUserId) {
      return;
    }

    // Verificar role se necessário
    if (requiredRole != null) {
      final hasRequiredRole = await hasRole(requiredRole);
      if (hasRequiredRole) {
        return;
      }
    }

    // Verificar se é admin
    final isAdmin = await hasRole('admin');
    if (isAdmin) {
      return;
    }

    throw Exception('Acesso negado: você não tem permissão para acessar este recurso');
  }

  /// Método para registrar log de auditoria
  Future<void> logSecurityEvent({
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

      await _authDataSource.insertAuditLog(auditData);
    } catch (e) {
      // Não falha a operação principal se o log falhar
    }
  }
}