import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  print('🔧 Corrigindo categorias no platform_settings...');
  
  try {
    // Carregar .env.clean
    final envFile = File('.env.clean');
    if (await envFile.exists()) {
      final lines = await envFile.readAsLines();
      String? url, anonKey;
      
      for (final line in lines) {
        if (line.startsWith('SUPABASE_URL=')) {
          url = line.split('=')[1];
        } else if (line.startsWith('SUPABASE_ANON_KEY=')) {
          anonKey = line.split('=')[1];
        }
      }
      
      if (url != null && anonKey != null) {
        print('✅ Configurações carregadas');
        
        final client = SupabaseClient(url, anonKey);
        
        // 1. Buscar configuração atual com categoria 'Comum'
        print('🔍 Buscando categoria "Comum"...');
        final response = await client
            .from('platform_settings')
            .select()
            .eq('category', 'Comum')
            .maybeSingle();
            
        if (response != null) {
          print('📋 Encontrou categoria "Comum": ${response['id']}');
          
          // 2. Verificar se já existe 'common_car'
          final existing = await client
              .from('platform_settings')
              .select()
              .eq('category', 'common_car')
              .maybeSingle();
              
          if (existing != null) {
            print('⚠️ Categoria "common_car" já existe. Removendo "Comum"...');
            await client
                .from('platform_settings')
                .delete()
                .eq('id', response['id']);
            print('✅ Categoria "Comum" removida');
          } else {
            print('🔄 Atualizando "Comum" para "common_car"...');
            await client
                .from('platform_settings')
                .update({'category': 'common_car'})
                .eq('id', response['id']);
            print('✅ Categoria atualizada para "common_car"');
          }
        } else {
          print('ℹ️ Categoria "Comum" não encontrada');
        }
        
        // 3. Verificar resultado final
        print('🔍 Verificando categorias finais...');
        final finalResponse = await client
            .from('platform_settings')
            .select('category, base_price_per_km, min_fare')
            .order('category');
            
        print('📊 Categorias atuais:');
        for (final item in finalResponse) {
          print('  - ${item['category']}: R\$ ${item['base_price_per_km']}/km, mín: R\$ ${item['min_fare']}');
        }
        
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