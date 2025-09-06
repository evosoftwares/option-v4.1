import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/config/app_config.dart';

void main() async {
  print('🔧 Testando conectividade com Supabase...');
  print('🌐 URL: ${AppConfig.supabaseUrl}');
  print('🔑 Key: ${AppConfig.supabaseAnonKey.substring(0, 20)}...');
  
  try {
    // Inicializar Supabase
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    
    print('✅ Supabase inicializado com sucesso!');
    
    // Testar uma consulta simples
    final client = Supabase.instance.client;
    
    print('🔍 Testando consulta simples...');
    final response = await client
        .from('app_users')
        .select('count')
        .count();
    
    print('✅ Consulta executada com sucesso!');
    print('📊 Resultado: $response');
    
  } catch (e) {
    print('❌ Erro: $e');
    print('🔍 Tipo do erro: ${e.runtimeType}');
    
    if (e.toString().contains('Failed host lookup')) {
      print('🌐 Problema de DNS detectado');
      print('💡 Possíveis soluções:');
      print('   1. Verificar conexão com internet');
      print('   2. Limpar cache DNS: flutter clean');
      print('   3. Reiniciar emulador/dispositivo');
      print('   4. Verificar configurações de proxy');
    }
  }
}