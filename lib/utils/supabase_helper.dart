import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class SupabaseHelper {
  // We cannot safely "probe" Supabase.instance because it asserts when not initialized.
  // So we keep an internal flag toggled from main.dart once initialization succeeds.
  static bool _initialized = false;
  
  // Test client for mocking in tests
  static SupabaseClient? testClient;

  static void markInitialized() {
    _initialized = true;
  }

  static bool get isInitialized => _initialized;

  static SupabaseClient? get client {
    // Return test client if set (for testing)
    if (testClient != null) {
      print('🧪 [SUPABASE_HELPER] Usando testClient para testes');
      return testClient;
    }
    
    print('🔍 [SUPABASE_HELPER] Verificando inicialização do Supabase...');
    print('🔍 [SUPABASE_HELPER] _initialized: $_initialized');
    print('🔍 [SUPABASE_HELPER] AppConfig.supabaseUrl está vazio: ${AppConfig.supabaseUrl.isEmpty}');
    print('🔍 [SUPABASE_HELPER] AppConfig.supabaseAnonKey está vazio: ${AppConfig.supabaseAnonKey.isEmpty}');
    
    if (!_initialized) {
      // Avoid triggering Supabase.instance assertion in debug/profile when not initialized.
      print('❌ [SUPABASE_HELPER] Supabase não inicializado. Verifique as variáveis de ambiente.');
      print('❌ [SUPABASE_HELPER] SUPABASE_URL: ${AppConfig.supabaseUrl}');
      print('❌ [SUPABASE_HELPER] SUPABASE_ANON_KEY: ${AppConfig.supabaseAnonKey.isNotEmpty ? AppConfig.supabaseAnonKey.substring(0, 20) + "..." : "VAZIO"}');
      
      // Log adicional para debug
      print('❌ [SUPABASE_HELPER] DIAGNÓSTICO:');
      print('❌ [SUPABASE_HELPER] - Variáveis de ambiente carregadas: ${AppConfig.supabaseUrl.isNotEmpty && AppConfig.supabaseAnonKey.isNotEmpty}');
      print('❌ [SUPABASE_HELPER] - URL tem formato válido: ${AppConfig.supabaseUrl.startsWith("http")}');
      
      return null;
    }
    
    try {
      print('🔍 [SUPABASE_HELPER] Tentando acessar Supabase.instance.client...');
      final client = Supabase.instance.client;
      print('✅ [SUPABASE_HELPER] Supabase.instance.client acessado com sucesso');
      return client;
    } catch (e) {
      print('❌ [SUPABASE_HELPER] Erro ao acessar Supabase.instance.client: $e');
      print('❌ [SUPABASE_HELPER] Tipo do erro: ${e.runtimeType}');
      return null;
    }
  }

  static void ensureInitialized() {
    if (!_initialized) {
      throw Exception(
        'Supabase não foi inicializado. Verifique as variáveis de ambiente SUPABASE_URL e SUPABASE_ANON_KEY.',
      );
    }
  }
}