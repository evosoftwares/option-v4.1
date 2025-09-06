import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_helper.dart';

/// Serviço de auth extremamente simplificado para contornar erro 500
class SimpleAuthService {
  static SupabaseClient get _supabase {
    print('🔍 [SIMPLE_AUTH] Obtendo cliente Supabase...');
    final c = SupabaseHelper.client;
    if (c == null) {
      print('❌ [SIMPLE_AUTH] SupabaseHelper.client retornou null!');
      print('❌ [SIMPLE_AUTH] SupabaseHelper.isInitialized: ${SupabaseHelper.isInitialized}');
      throw Exception('Supabase não inicializado');
    }
    print('✅ [SIMPLE_AUTH] Cliente Supabase obtido com sucesso');
    return c;
  }

  /// Registro direto sem complicações
  static Future<Map<String, dynamic>> signUpDirect({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      print('🚀 [SIMPLE AUTH] Tentando signup direto...');
      
      // Tentar primeiro método mais simples possível
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        }
      );

      if (response.user != null) {
        print('✅ [SIMPLE AUTH] Usuário criado: ${response.user!.id}');
        
        return {
          'success': true,
          'user_id': response.user!.id,
          'email': response.user!.email,
          'needs_confirmation': response.session == null,
          'message': response.session == null 
            ? 'Verifique seu email para confirmar a conta'
            : 'Conta criada com sucesso!'
        };
      } else {
        throw Exception('Falha na criação do usuário');
      }
      
    } on AuthException catch (e) {
      print('❌ [SIMPLE AUTH] AuthException: ${e.message}');
      throw Exception('Erro de autenticação: ${e.message}');
    } catch (e) {
      print('❌ [SIMPLE AUTH] Erro geral: $e');
      throw Exception('Erro ao criar conta: $e');
    }
  }

  /// Login direto sem complicações
  static Future<Map<String, dynamic>> signInDirect({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 [SIMPLE AUTH] Tentando login direto...');
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null && response.user != null) {
        print('✅ [SIMPLE AUTH] Login realizado: ${response.user!.id}');
        
        return {
          'success': true,
          'user_id': response.user!.id,
          'email': response.user!.email,
          'session': response.session,
          'message': 'Login realizado com sucesso!'
        };
      } else {
        throw Exception('Credenciais inválidas');
      }
      
    } on AuthException catch (e) {
      print('❌ [SIMPLE AUTH] Login AuthException: ${e.message}');
      throw Exception('Erro de login: ${e.message}');
    } catch (e) {
      print('❌ [SIMPLE AUTH] Login erro geral: $e');
      throw Exception('Erro ao fazer login: $e');
    }
  }

  /// Verificar se usuário está logado
  static bool isLoggedIn() => _supabase.auth.currentSession != null;

  /// Obter usuário atual
  static User? getCurrentUser() => _supabase.auth.currentUser;

  /// Logout
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Testar conectividade básica
  static Future<bool> testConnection() async {
    try {
      // Tentar uma operação simples que não depende de tabelas
      final response = await _supabase.from('app_users').select('id').count(CountOption.exact);
      print('✅ [SIMPLE AUTH] Conexão OK: ${response.count}');
      return true;
    } catch (e) {
      print('❌ [SIMPLE AUTH] Conexão falhou: $e');
      return false;
    }
  }
}