import 'package:supabase_flutter/supabase_flutter.dart';

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
      return testClient;
    }
    
    if (!_initialized) {
      // Avoid triggering Supabase.instance assertion in debug/profile when not initialized.
      print('❌ Supabase não inicializado. Verifique as variáveis de ambiente.');
      return null;
    }
    return Supabase.instance.client;
  }

  static void ensureInitialized() {
    if (!_initialized) {
      throw Exception(
        'Supabase não foi inicializado. Verifique as variáveis de ambiente SUPABASE_URL e SUPABASE_ANON_KEY.',
      );
    }
  }
}