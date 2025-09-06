import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

void main() async {
  print('🔄 Testando acesso direto ao Supabase...');
  
  try {
    // Carregar .env.clean
    final envFile = File('.env.clean');
    if (await envFile.exists()) {
      final lines = await envFile.readAsLines();
      String? url, serviceKey;
      
      for (final line in lines) {
        if (line.startsWith('SUPABASE_URL=')) {
          url = line.split('=')[1];
        } else if (line.startsWith('SUPABASE_SERVICE_ROLE_KEY=')) {
          serviceKey = line.split('=')[1];
        }
      }
      
      if (url != null && serviceKey != null) {
        print('✅ Configurações carregadas');
        
        // Inicializar Supabase
        await Supabase.initialize(url: url, anonKey: serviceKey);
        final client = Supabase.instance.client;
        
        // Testar platform_settings
        print('🔍 Testando platform_settings...');
        final platformResponse = await client
            .from('platform_settings')
            .select('category')
            .limit(10);
            
        print('Platform categories:');
        for (final item in platformResponse) {
          print('  - ${item['category']}');
        }
        
        // Testar drivers
        print('\n🔍 Testando drivers...');
        final driversResponse = await client
            .from('drivers')  
            .select('vehicle_category')
            .limit(10);
            
        final usedCategories = <String>{};
        for (final driver in driversResponse) {
          final cat = driver['vehicle_category'];
          if (cat != null) usedCategories.add(cat);
        }
        
        print('Driver categories:');
        for (final cat in usedCategories) {
          print('  - $cat');
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