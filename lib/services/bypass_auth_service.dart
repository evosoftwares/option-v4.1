import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_helper.dart';

/// Serviço temporário de bypass para auth enquanto resolvemos o erro 500
class BypassAuthService {
  static SupabaseClient get _supabase {
    final c = SupabaseHelper.client;
    if (c == null) {
      throw Exception('Supabase não inicializado');
    }
    return c;
  }

  /// Registra usuário usando função de bypass no Supabase
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String userType,
  }) async {
    try {
      print('🚀 [BYPASS] Tentando registro via bypass...');
      print('  - Email: $email');
      print('  - Nome: $fullName');
      print('  - Tipo: $userType');

      // Chamar função de bypass via RPC
      final response = await _supabase.rpc('bypass_signup', params: {
        'p_email': email,
        'p_password': password,
        'p_full_name': fullName,
        'p_phone': phone,
        'p_user_type': userType,
      });

      print('📊 [BYPASS] Resposta: $response');

      if (response == null) {
        throw Exception('Resposta nula do servidor');
      }

      // Verificar se a resposta é um Map ou precisa ser convertida
      Map<String, dynamic> result;
      if (response is Map<String, dynamic>) {
        result = response;
      } else if (response is Map) {
        result = Map<String, dynamic>.from(response);
      } else {
        throw Exception('Formato de resposta inválido: ${response.runtimeType}');
      }

      if (result['success'] == true) {
        print('✅ [BYPASS] Registro realizado com sucesso!');
        return {
          'success': true,
          'user_id': result['user_id'],
          'email': result['email'],
          'user_type': result['user_type'],
          'message': 'Conta criada com sucesso!'
        };
      } else {
        final error = result['error'] ?? 'Erro desconhecido';
        print('❌ [BYPASS] Erro no registro: $error');
        throw Exception(error);
      }
    } catch (e) {
      print('❌ [BYPASS] Exceção durante registro: $e');
      rethrow;
    }
  }

  /// Login usando função de bypass no Supabase
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 [BYPASS] Tentando login via bypass...');
      print('  - Email: $email');

      // Chamar função de bypass via RPC
      final response = await _supabase.rpc('bypass_login', params: {
        'p_email': email,
        'p_password': password,
      });

      print('📊 [BYPASS] Resposta do login: $response');

      if (response == null) {
        throw Exception('Resposta nula do servidor');
      }

      // Verificar se a resposta é um Map ou precisa ser convertida
      Map<String, dynamic> result;
      if (response is Map<String, dynamic>) {
        result = response;
      } else if (response is Map) {
        result = Map<String, dynamic>.from(response);
      } else {
        throw Exception('Formato de resposta inválido: ${response.runtimeType}');
      }

      if (result['success'] == true) {
        print('✅ [BYPASS] Login realizado com sucesso!');
        return {
          'success': true,
          'user': result['user'],
          'message': 'Login realizado com sucesso!'
        };
      } else {
        final error = result['error'] ?? 'Credenciais inválidas';
        print('❌ [BYPASS] Erro no login: $error');
        throw Exception(error);
      }
    } catch (e) {
      print('❌ [BYPASS] Exceção durante login: $e');
      rethrow;
    }
  }

  /// Verifica se o bypass está funcionando
  static Future<bool> testBypassConnection() async {
    try {
      print('🧪 [BYPASS] Testando conexão...');
      
      // Tentar uma consulta simples
      final response = await _supabase
          .from('app_users')
          .select('id')
          .count(CountOption.exact);
      
      print('✅ [BYPASS] Conexão funcionando: ${response.count}');
      return true;
    } catch (e) {
      print('❌ [BYPASS] Falha na conexão: $e');
      return false;
    }
  }
}