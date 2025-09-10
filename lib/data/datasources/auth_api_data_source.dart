import 'package:supabase_flutter/supabase_flutter.dart';

/// Data Source responsável apenas pelo acesso aos dados de autenticação
/// Não contém lógica de negócio, apenas operações de acesso aos dados
class AuthApiDataSource {
  final SupabaseClient _supabase;

  AuthApiDataSource(this._supabase);

  /// Cria usuário no sistema de autenticação do Supabase
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: userData,
    );
  }

  /// Faz login com email e senha
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Faz logout do usuário atual
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Envia email para redefinir senha
  Future<void> resetPasswordForEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Atualiza dados do usuário no sistema de auth
  Future<UserResponse> updateUser(UserAttributes attributes) async {
    return await _supabase.auth.updateUser(attributes);
  }

  /// Obtém o usuário atual do sistema de auth
  User? getCurrentAuthUser() {
    return _supabase.auth.currentUser;
  }

  /// Verifica se há um usuário autenticado
  bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  /// Obtém o ID do usuário atual
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  /// Deleta usuário do sistema de auth (admin operation)
  Future<void> deleteUser(String userId) async {
    await _supabase.auth.admin.deleteUser(userId);
  }

  /// Busca dados do usuário na tabela app_users
  Future<Map<String, dynamic>?> getUserFromAppUsers(String userId) async {
    final response = await _supabase
        .from('app_users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    
    return response;
  }

  /// Cria registro na tabela app_users
  Future<Map<String, dynamic>> createUserInAppUsers(Map<String, dynamic> userData) async {
    final response = await _supabase
        .from('app_users')
        .insert(userData)
        .select()
        .single();
    
    return response;
  }

  /// Atualiza dados na tabela app_users
  Future<void> updateUserInAppUsers(String userId, Map<String, dynamic> updateData) async {
    await _supabase
        .from('app_users')
        .update(updateData)
        .eq('id', userId);
  }

  /// Busca user_type de um usuário específico
  Future<String?> getUserType(String userId) async {
    final response = await _supabase
        .from('app_users')
        .select('user_type')
        .eq('id', userId)
        .maybeSingle();

    return response?['user_type'];
  }

  /// Insere log de auditoria
  Future<void> insertAuditLog(Map<String, dynamic> auditData) async {
    await _supabase.from('audit_logs').insert(auditData);
  }
}