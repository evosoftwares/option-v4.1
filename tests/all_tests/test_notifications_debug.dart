import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  print('🔍 Iniciando teste de debug das notificações...');
  
  try {
    // Ler variáveis de ambiente do .env
    final envFile = File('.env');
    if (!envFile.existsSync()) {
      print('❌ Arquivo .env não encontrado');
      return;
    }
    
    final envContent = await envFile.readAsString();
    final envLines = envContent.split('\n');
    
    String? supabaseUrl;
    String? supabaseAnonKey;
    
    for (final line in envLines) {
      if (line.startsWith('SUPABASE_URL=')) {
        supabaseUrl = line.split('=')[1].trim();
      } else if (line.startsWith('SUPABASE_ANON_KEY=')) {
        supabaseAnonKey = line.split('=')[1].trim();
      }
    }
    
    if (supabaseUrl == null || supabaseAnonKey == null) {
      print('❌ Variáveis SUPABASE_URL ou SUPABASE_ANON_KEY não encontradas no .env');
      return;
    }
    
    print('✅ Variáveis de ambiente carregadas');
    
    // Inicializar cliente Supabase
    final client = SupabaseClient(supabaseUrl, supabaseAnonKey);
    print('✅ Cliente Supabase inicializado');
    
    // Testar se a tabela existe e está acessível
    print('🔍 Testando acesso à tabela notifications...');
    
    final response = await client
        .from('notifications')
        .select('count')
        .limit(1);
    
    print('✅ Tabela notifications acessível');
    print('📊 Resposta: $response');
    
    // Testar estrutura da tabela
    print('🔍 Testando estrutura da tabela...');
    
    final structureTest = await client
        .from('notifications')
        .select('id, user_id, title, body, type, sent_at, is_read')
        .limit(1);
    
    print('✅ Estrutura da tabela OK');
    print('📊 Estrutura: $structureTest');
    
    // Testar com um user_id fictício
    print('🔍 Testando query com user_id fictício...');
    
    final testQuery = await client
        .from('notifications')
        .select()
        .eq('user_id', 'test-user-id')
        .limit(1);
    
    print('✅ Query com user_id executada com sucesso');
    print('📊 Resultado: $testQuery');
    
  } catch (e, stackTrace) {
    print('❌ Erro durante o teste:');
    print('Erro: $e');
    print('Stack trace: $stackTrace');
  }
  
  print('🏁 Teste finalizado');
}