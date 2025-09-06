import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:option/services/platform_settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Iniciando verificação da tabela platform_settings...');
  
  try {
    // Usar a instância já inicializada do Supabase
    final supabase = Supabase.instance.client;
    
    // Verificar se já está inicializado
    final user = supabase.auth.currentUser;
    print('👤 Usuário atual: ${user?.id ?? 'Não autenticado'}');
    
    // Teste direto na tabela
    print('\n🔍 TESTE 1: Consulta direta na tabela platform_settings');
    final directResponse = await supabase
        .from('platform_settings')
        .select('*')
        .order('category');
        
    print('📊 Registros encontrados: ${directResponse.length}');
    
    if (directResponse.isEmpty) {
      print('❌ PROBLEMA: Tabela platform_settings está VAZIA!');
      print('💡 SOLUÇÃO: Execute o script SQL para popular a tabela');
    } else {
      print('✅ Dados encontrados:');
      for (var record in directResponse) {
        print('   📋 ${record['category']}: min_fare=${record['min_fare']}');
      }
    }
    
    // Teste com o service
    print('\n🔧 TESTE 2: Usando PlatformSettingsService');
    final service = PlatformSettingsService(supabase);
    final settings = await service.getAllSettings();
    
    print('⚙️ Settings via service: ${settings.length}');
    for (var setting in settings) {
      print('   📋 ${setting.category}: min_fare=${setting.minFare}');
    }
    
    print('\n✅ Verificação concluída com sucesso!');
    
  } catch (e) {
    print('\n❌ ERRO: $e');
    print('❌ Tipo: ${e.runtimeType}');
    
    if (e.toString().contains('permission denied')) {
      print('\n🔒 DIAGNÓSTICO: Problema de permissões RLS');
      print('💡 SOLUÇÃO: Desabilitar RLS na tabela platform_settings');
    }
  }
}