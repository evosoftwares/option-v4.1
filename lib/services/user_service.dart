import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import '../exceptions/app_exceptions.dart';

class UserService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Cria um novo usuário na tabela app_users
  static Future<User> createUser({
    required String authUserId,
    required String email,
    required String fullName,
    String? phone,
    String? photoUrl,
    required String userType,
  }) async {
    try {
      // Verificar se o usuário já existe
      final existingUser = await getUserById(authUserId);
      if (existingUser != null) {
        throw UserAlreadyExistsException(email);
      }
    } catch (e) {
      if (e is UserAlreadyExistsException) rethrow;
      // Se não encontrou o usuário, continua com a criação
    }

    try {
      final userData = {
        'id': authUserId,
        'user_id': authUserId, // Cópia do UUID do AUTH user
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'photo_url': photoUrl,
        'user_type': userType,
        'status': 'active',
      };

      final response = await _supabase
          .from('app_users')
          .insert(userData)
          .select()
          .single();

      return User.fromMap(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') { // Unique constraint violation
        throw UserAlreadyExistsException(email);
      }
      throw DatabaseException('Erro ao criar usuário. Por favor, verifique os dados e tente novamente.');
    } catch (e) {
      throw DatabaseException('Erro inesperado ao criar usuário. Por favor, tente novamente mais tarde.');
    }
  }

  /// Busca um usuário pelo ID
  static Future<User?> getUserById(String userId) async {
    try {
      final response = await _supabase
          .from('app_users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return User.fromMap(response);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar usuário. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw DatabaseException('Erro inesperado ao buscar usuário. Por favor, tente novamente mais tarde.');
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
    } on PostgrestException catch (e) {
      throw Exception('Erro ao buscar usuário por email. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw Exception('Erro inesperado ao buscar usuário por email. Por favor, tente novamente mais tarde.');
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
    try {
      final updateData = <String, dynamic>{};
      
      if (fullName != null) updateData['full_name'] = fullName;
      if (phone != null) updateData['phone'] = phone;
      if (photoUrl != null) updateData['photo_url'] = photoUrl;
      if (userType != null) updateData['user_type'] = userType;
      if (status != null) updateData['status'] = status;
      
      // Sempre atualiza o updated_at
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('app_users')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      return User.fromMap(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') { // No rows returned
        throw UserNotFoundException(userId);
      }
      throw DatabaseException('Erro ao atualizar usuário. Por favor, verifique os dados e tente novamente.', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado ao atualizar usuário. Por favor, tente novamente mais tarde.');
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
      throw DatabaseException('Erro inesperado ao atualizar tipo de usuário. Por favor, tente novamente mais tarde.');
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
      throw Exception('Erro ao verificar existência do usuário. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw Exception('Erro inesperado ao verificar usuário. Por favor, tente novamente mais tarde.');
    }
  }

  /// Obtém o usuário atual logado
  static Future<User?> getCurrentUser() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) return null;

      return await getUserById(authUser.id);
    } catch (e) {
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
    } on PostgrestException catch (e) {
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

      return response.map((data) => User.fromMap(data)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Erro ao buscar usuários por tipo. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw Exception('Erro inesperado ao buscar usuários. Por favor, tente novamente mais tarde.');
    }
  }
}