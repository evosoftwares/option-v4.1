import 'dart:io';

void main() async {
  print('🚗 Executando Testes do Fluxo do Motorista...\n');
  
  final tests = [
    'driver_flow_unit_test.dart',
    'driver_flow_integration_test.dart', 
    'driver_flow_e2e_test.dart',
  ];

  int passed = 0;
  int failed = 0;

  for (final test in tests) {
    print('Executando: $test');
    
    try {
      final result = await Process.run('flutter', ['test', 'test/$test']);
      
      if (result.exitCode == 0) {
        print('✅ $test - PASSOU');
        passed++;
      } else {
        print('❌ $test - FALHOU');
        print(result.stderr);
        failed++;
      }
    } catch (e) {
      print('❌ $test - ERRO: $e');
      failed++;
    }
    
    print(''); // Linha em branco entre testes
  }

  print('📊 Resumo dos Testes:');
  print('Total: ${tests.length}');
  print('Passaram: $passed');
  print('Falharam: $failed');
  
  if (failed == 0) {
    print('\n🎉 Todos os testes passaram!');
  } else {
    print('\n⚠️  $failed teste(s) falharam. Verifique os logs acima.');
  }
}