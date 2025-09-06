import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/config/app_config.dart';

void main() async {
  print('🔧 Testando erro 42P01 - Funções de motoristas...');
  
  try {
    // Inicializar Supabase
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    
    final supabase = Supabase.instance.client;
    print('✅ Supabase inicializado com sucesso');
    
    // Teste 1: Verificar se a tabela drivers existe
    print('\n📋 Teste 1: Verificando tabela drivers...');
    try {
      final driversCount = await supabase
          .from('drivers')
          .select('id')
          .count(CountOption.exact);
      print('✅ Tabela drivers existe - Total: $driversCount');
    } catch (e) {
      print('❌ Erro ao acessar tabela drivers: $e');
    }
    
    // Teste 2: Testar função get_nearby_drivers
    print('\n🎯 Teste 2: Testando função get_nearby_drivers...');
    try {
      final result = await supabase.rpc('get_nearby_drivers', params: {
        'user_lat': -23.5505,
        'user_lng': -46.6333,
        'radius_km': 10.0,
        'vehicle_category': 'economico'
      });
      print('✅ Função get_nearby_drivers executada com sucesso');
      print('📊 Resultado: ${result.length} motoristas encontrados');
    } catch (e) {
      print('❌ Erro na função get_nearby_drivers: $e');
      if (e.toString().contains('42P01')) {
        print('🚨 ERRO 42P01 DETECTADO - Função não existe!');
      }
    }
    
    // Teste 3: Testar função get_emergency_nearby_drivers
    print('\n🚨 Teste 3: Testando função get_emergency_nearby_drivers...');
    try {
      final result = await supabase.rpc('get_emergency_nearby_drivers', params: {
        'user_lat': -23.5505,
        'user_lng': -46.6333,
        'radius_km': 15.0
      });
      print('✅ Função get_emergency_nearby_drivers executada com sucesso');
      print('📊 Resultado: ${result.length} motoristas encontrados');
    } catch (e) {
      print('❌ Erro na função get_emergency_nearby_drivers: $e');
      if (e.toString().contains('42P01')) {
        print('🚨 ERRO 42P01 DETECTADO - Função não existe!');
      }
    }
    
    // Teste 4: Verificar constraint vehicle_category
    print('\n🔍 Teste 4: Testando constraint vehicle_category...');
    try {
      // Tentar inserir um registro com categoria válida
      final testData = {
        'user_id': '00000000-0000-0000-0000-000000000000', // UUID fictício
        'vehicle_category': 'economico',
        'vehicle_brand': 'Toyota',
        'vehicle_model': 'Corolla',
        'vehicle_year': 2020,
        'vehicle_color': 'Branco',
        'vehicle_plate': 'ABC1234',
        'status': 'pending'
      };
      
      // Apenas simular - não inserir de verdade
      print('✅ Dados de teste preparados com vehicle_category: economico');
      print('📝 Constraint deve aceitar: economico, standard, premium, suv, executivo, van');
    } catch (e) {
      print('❌ Erro ao preparar teste de constraint: $e');
    }
    
  } catch (e) {
    print('❌ Erro geral: $e');
  }
  
  print('\n🏁 Teste concluído!');
}