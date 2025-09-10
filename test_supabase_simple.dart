import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  print('🔄 Testando acesso ao Supabase...');
  
  try {
    // Carregar .env.clean
    final envFile = File('.env.clean');
    if (await envFile.exists()) {
      final lines = await envFile.readAsLines();
      String? url, anonKey, serviceKey;
      
      for (final line in lines) {
        if (line.startsWith('SUPABASE_URL=')) {
          url = line.split('=')[1];
        } else if (line.startsWith('SUPABASE_ANON_KEY=')) {
          anonKey = line.split('=')[1];
        } else if (line.startsWith('SUPABASE_SERVICE_ROLE_KEY=')) {
          serviceKey = line.split('=')[1];
        }
      }
      
      if (url != null && serviceKey != null) {
        print('✅ Configurações carregadas');
        
        // Agora que RLS foi desabilitado, testar com anon key primeiro
        if (anonKey != null) {
          print('🔍 Testando platform_settings com anon key (RLS desabilitado)...');
          final anonClient = SupabaseClient(url, anonKey);
          final anonResponse = await anonClient
              .from('platform_settings')
              .select();
              
          print('📊 Resposta anon: ${anonResponse.toString()}');
          print('📊 Quantidade anon: ${anonResponse.length}');
          
          if (anonResponse.isNotEmpty) {
            print('✅ RLS desabilitado com sucesso! Dados:');
            for (final item in anonResponse) {
              print('  - ${item['category']}: R\$ ${item['base_price_per_km']}/km, mín: R\$ ${item['min_fare']}');
            }
          } else {
            print('⚠️ Resposta vazia com anon key');
          }
        }
        
        // Também testar com service key se necessário
        print('🔍 Testando também com service key...');
        final client = SupabaseClient(url, serviceKey);
        final response = await client
            .from('platform_settings')
            .select();
            
        print('📊 Resposta service: ${response.toString()}');
        print('📊 Quantidade service: ${response.length}');
        
      } else {
        print('❌ Variáveis não encontradas');
      }
    } else {
      print('❌ .env.clean não encontrado');
    }
    
  } catch (e) {
    print('❌ Erro: $e');
  }
  
  exit(0);
}