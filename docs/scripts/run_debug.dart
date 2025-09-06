import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'debug_button_ir_crash.dart';

/// Script para executar o debug do travamento do botão IR
void main() async {
  print('🔍 Iniciando diagnóstico do travamento do botão IR...');
  print('=' * 60);
  
  try {
    // Configurar Supabase (você precisa substituir pelas suas credenciais)
    print('🔧 Configurando Supabase...');
    
    // Verificar se as variáveis de ambiente estão definidas
    final supabaseUrl = Platform.environment['SUPABASE_URL'];
    final supabaseAnonKey = Platform.environment['SUPABASE_ANON_KEY'];
    
    if (supabaseUrl == null || supabaseAnonKey == null) {
      print('❌ ERRO: Variáveis de ambiente não configuradas!');
      print('   Configure SUPABASE_URL e SUPABASE_ANON_KEY');
      print('   Exemplo:');
      print('   export SUPABASE_URL="https://seu-projeto.supabase.co"');
      print('   export SUPABASE_ANON_KEY="sua-chave-anonima"');
      exit(1);
    }
    
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    
    print('✅ Supabase configurado com sucesso!');
    
    // Solicitar ID do motorista
    print('\n📝 Digite o ID do motorista que está enfrentando o problema:');
    final driverId = stdin.readLineSync();
    
    if (driverId == null || driverId.trim().isEmpty) {
      print('❌ ID do motorista é obrigatório!');
      exit(1);
    }
    
    print('\n🚀 Executando diagnóstico para o motorista: $driverId');
    print('=' * 60);
    
    // Executar diagnóstico completo
    await ButtonIrCrashDebugger.runFullDiagnostic(driverId.trim());
    
    print('\n✅ Diagnóstico concluído com sucesso!');
    print('📊 Verifique os logs acima para identificar possíveis problemas.');
    
  } catch (e, stackTrace) {
    print('\n❌ ERRO DURANTE O DIAGNÓSTICO:');
    print('Erro: $e');
    print('Stack trace:');
    print(stackTrace);
    
    // Sugestões baseadas no tipo de erro
    if (e.toString().contains('TimeoutException')) {
      print('\n💡 SUGESTÕES:');
      print('- Verifique a conectividade com o banco de dados');
      print('- Considere otimizar as queries de documentação');
      print('- Adicione índices nas tabelas relevantes');
    } else if (e.toString().contains('PostgrestException')) {
      print('\n💡 SUGESTÕES:');
      print('- Verifique se todas as tabelas existem');
      print('- Confirme as permissões de acesso ao banco');
      print('- Verifique a estrutura das tabelas');
    } else if (e.toString().contains('DocumentationRequiredException')) {
      print('\n💡 SUGESTÕES:');
      print('- Complete a documentação obrigatória do motorista');
      print('- Verifique se os documentos estão aprovados');
      print('- Confirme se os documentos não estão expirados');
    }
    
    exit(1);
  }
}