import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseHelper {
  static bool get isInitialized {
    try {
      // Tenta acessar o cliente para verificar se está inicializado
      final _ = Supabase.instance.client;
      return true;
    } catch (e) {
      return false;
    }
  }

  static SupabaseClient? get client {
    if (!isInitialized) {
      print('❌ Supabase não inicializado. Verifique as variáveis de ambiente.');
      return null;
    }
    return Supabase.instance.client;
  }

  static void ensureInitialized() {
    if (!isInitialized) {
      throw Exception('Supabase não foi inicializado. Verifique as variáveis de ambiente SUPABASE_URL e SUPABASE_ANON_KEY.');
    }
  }
}