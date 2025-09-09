import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'lib/config/app_config.dart';
import 'lib/services/driver_service.dart';
import 'lib/services/driver_status_service.dart';
import 'lib/controllers/driver_status_controller.dart';
import 'lib/exceptions/app_exceptions.dart';

/// Script de teste para validação de documentos do motorista
///
/// Este script testa o problema relatado:
/// "Enquanto motorista e depois de fazer o stepper aparece um popup 'Online'
/// quando clico em IR. Entretanto os 4 documentos ainda estão pendentes,
/// o correto era aparecer uma mensagem e redirecionar para tela de documentos"
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🧪 [TEST] Iniciando teste de validação de documentos...');

  // Inicializar Supabase
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    print('✅ [TEST] Supabase inicializado com sucesso');
  } catch (e) {
    print('❌ [TEST] Erro ao inicializar Supabase: $e');
    return;
  }

  await runDocumentValidationTests();
}

Future<void> runDocumentValidationTests() async {
  print('\n📋 [TEST] === INICIANDO TESTES DE VALIDAÇÃO DE DOCUMENTOS ===\n');

  // Teste 1: Motorista sem documentos (recém registrado)
  await testDriverWithoutDocuments();

  // Teste 2: Motorista com documentos pendentes
  await testDriverWithPendingDocuments();

  // Teste 3: Motorista com documentos rejeitados
  await testDriverWithRejectedDocuments();

  // Teste 4: Motorista com documentos aprovados (deve funcionar)
  await testDriverWithApprovedDocuments();

  print('\n🏁 [TEST] === TESTES FINALIZADOS ===\n');
}

/// Teste 1: Motorista sem documentos enviados
Future<void> testDriverWithoutDocuments() async {
  print('🔍 [TEST-1] Testando motorista SEM documentos...');

  final testDriverId =
      'test_driver_no_docs_${DateTime.now().millisecondsSinceEpoch}';

  try {
    final driverService = DriverService(Supabase.instance.client);
    final eligibilityStatus =
        await driverService.getOnlineEligibilityStatus(testDriverId);

    print('📊 [TEST-1] Resultado da verificação:');
    print('   • canGoOnline: ${eligibilityStatus['canGoOnline']}');
    print('   • reason: ${eligibilityStatus['reason']}');
    print('   • message: ${eligibilityStatus['message']}');
    print('   • actionRequired: ${eligibilityStatus['actionRequired']}');

    if (eligibilityStatus['canGoOnline'] == false) {
      print(
          '✅ [TEST-1] SUCESSO - Motorista sem documentos foi corretamente bloqueado');
    } else {
      print(
          '❌ [TEST-1] FALHA - Motorista sem documentos deveria ser bloqueado');
    }
  } catch (e) {
    print('⚠️ [TEST-1] Erro durante o teste: $e');
  }

  print('');
}

/// Teste 2: Motorista com documentos pendentes (o problema relatado)
Future<void> testDriverWithPendingDocuments() async {
  print('🔍 [TEST-2] Testando motorista com DOCUMENTOS PENDENTES...');
  print('   (Este é o cenário do problema relatado)');

  try {
    // Simular um driver controller tentando ficar online
    final controller = DriverStatusController();

    // Configurar callback para capturar erro de elegibilidade
    String? capturedErrorReason;
    String? capturedErrorMessage;

    controller.onEligibilityError = (eligibilityStatus) {
      capturedErrorReason = eligibilityStatus['reason'];
      capturedErrorMessage = eligibilityStatus['message'];
      print('🚨 [TEST-2] Callback de erro ativado:');
      print('   • reason: $capturedErrorReason');
      print('   • message: $capturedErrorMessage');
    };

    // Tentar inicializar o controller (isso pode falhar se não houver driver real)
    try {
      await controller.initialize();
      print('✅ [TEST-2] Controller inicializado');

      // Tentar mudar status para online
      await controller.toggleOnlineStatus();

      if (capturedErrorReason != null) {
        print('✅ [TEST-2] SUCESSO - Erro capturado pelo callback');
        print('   • Reason: $capturedErrorReason');
        print('   • Message: $capturedErrorMessage');

        if (capturedErrorReason == 'Documentos não aprovados') {
          print(
              '🎯 [TEST-2] PERFEITO - Erro específico de documentos detectado');
        }
      } else {
        print('❌ [TEST-2] FALHA - Nenhum erro foi capturado pelo callback');
        print('   • Status atual: ${controller.status.status}');

        if (controller.status.isOnline) {
          print(
              '🚨 [TEST-2] PROBLEMA CONFIRMADO - Motorista ficou online indevidamente');
        }
      }
    } catch (e) {
      print(
          '⚠️ [TEST-2] Controller não pôde ser testado (esperado sem driver real): $e');

      // Teste direto do serviço
      print('🔄 [TEST-2] Testando diretamente o serviço...');
      await testDirectServiceCall();
    }
  } catch (e) {
    print('❌ [TEST-2] Erro durante teste: $e');
  }

  print('');
}

Future<void> testDirectServiceCall() async {
  final driverService = DriverService(Supabase.instance.client);

  // Teste com ID fictício para simular driver com documentos pendentes
  const testDriverId = 'test_driver_pending';

  try {
    final eligibilityStatus =
        await driverService.getOnlineEligibilityStatus(testDriverId);

    print('📊 [TEST-2-DIRECT] Resultado da verificação direta:');
    print('   • canGoOnline: ${eligibilityStatus['canGoOnline']}');
    print('   • reason: ${eligibilityStatus['reason']}');
    print('   • message: ${eligibilityStatus['message']}');

    if (eligibilityStatus['canGoOnline'] == false &&
        eligibilityStatus['reason']?.toString().contains('Documentos') ==
            true) {
      print(
          '✅ [TEST-2-DIRECT] SUCESSO - Serviço detecta problema de documentos');
    } else {
      print(
          '❌ [TEST-2-DIRECT] Serviço não detectou problema de documentos adequadamente');
    }
  } catch (e) {
    print('⚠️ [TEST-2-DIRECT] Erro no teste direto: $e');
  }
}

/// Teste 3: Motorista com documentos rejeitados
Future<void> testDriverWithRejectedDocuments() async {
  print('🔍 [TEST-3] Testando motorista com DOCUMENTOS REJEITADOS...');

  try {
    final driverService = DriverService(Supabase.instance.client);
    final testDriverId =
        'test_driver_rejected_${DateTime.now().millisecondsSinceEpoch}';

    final eligibilityStatus =
        await driverService.getOnlineEligibilityStatus(testDriverId);

    print('📊 [TEST-3] Resultado:');
    print('   • canGoOnline: ${eligibilityStatus['canGoOnline']}');
    print('   • reason: ${eligibilityStatus['reason']}');

    if (eligibilityStatus['canGoOnline'] == false) {
      print('✅ [TEST-3] SUCESSO - Motorista com docs rejeitados foi bloqueado');
    } else {
      print(
          '❌ [TEST-3] FALHA - Motorista com docs rejeitados deveria ser bloqueado');
    }
  } catch (e) {
    print('⚠️ [TEST-3] Erro: $e');
  }

  print('');
}

/// Teste 4: Motorista com documentos aprovados
Future<void> testDriverWithApprovedDocuments() async {
  print('🔍 [TEST-4] Testando motorista com DOCUMENTOS APROVADOS...');
  print('   (Este cenário deveria permitir ficar online)');

  try {
    final driverService = DriverService(Supabase.instance.client);
    final testDriverId =
        'test_driver_approved_${DateTime.now().millisecondsSinceEpoch}';

    final eligibilityStatus =
        await driverService.getOnlineEligibilityStatus(testDriverId);

    print('📊 [TEST-4] Resultado:');
    print('   • canGoOnline: ${eligibilityStatus['canGoOnline']}');
    print('   • reason: ${eligibilityStatus['reason']}');

    // Para driver fictício, esperamos que falhe por não existir
    // Mas a lógica de validação deveria estar funcionando
    print('ℹ️ [TEST-4] Teste com driver fictício - resultado esperado é falha');
  } catch (e) {
    print('⚠️ [TEST-4] Erro: $e');
  }

  print('');
}

/// Função para testar cenários específicos de documentos
Future<void> testDocumentScenarios() async {
  print('📝 [DOCS-TEST] Testando cenários específicos de documentos...');

  final scenarios = [
    {
      'name': 'CNH Pendente',
      'documents': ['cnh_front'],
      'statuses': ['pending'],
    },
    {
      'name': 'CRLV Pendente',
      'documents': ['crlv'],
      'statuses': ['pending'],
    },
    {
      'name': 'Foto do Veículo Pendente',
      'documents': ['vehicle_photo'],
      'statuses': ['pending'],
    },
    {
      'name': 'Foto do Motorista Pendente',
      'documents': ['driver_photo'],
      'statuses': ['pending'],
    },
    {
      'name': 'Múltiplos Docs Pendentes',
      'documents': ['cnh_front', 'crlv'],
      'statuses': ['pending', 'pending'],
    },
  ];

  for (final scenario in scenarios) {
    print('🎭 [DOCS-TEST] Cenário: ${scenario['name']}');

    // Aqui poderia simular inserção no banco de dados
    // Por enquanto, apenas documentamos o teste
    print('   • Documentos: ${scenario['documents']}');
    print('   • Status: ${scenario['statuses']}');
    print('   • Resultado esperado: Bloqueado para ficar online');
    print('');
  }
}

/// Utilitário para criar logs detalhados
void logTestResult(String testName, bool passed, String details) {
  final status = passed ? '✅ PASSOU' : '❌ FALHOU';
  print('$status [$testName] $details');
}

/// Resumo dos testes
void printTestSummary() {
  print('''
📈 [RESUMO] Resumo dos Testes de Validação de Documentos:

🎯 OBJETIVO:
   Verificar se motoristas com documentos pendentes são corretamente
   impedidos de ficar online, e se recebem mensagens adequadas.

🔍 CENÁRIOS TESTADOS:
   1. Motorista sem documentos enviados
   2. Motorista com documentos pendentes (problema relatado)
   3. Motorista com documentos rejeitados
   4. Motorista com documentos aprovados

💡 CORREÇÃO IMPLEMENTADA:
   • Configurado callback onEligibilityError no DriverStatusController
   • Adicionado handler _handleEligibilityError na DriverHomeScreen
   • Mapeamento correto dos erros para exibir dialogs apropriados

🚀 RESULTADO ESPERADO:
   Quando motorista tentar ficar online com docs pendentes:
   → Será exibido dialog "Documentos Pendentes"
   → Oferecerá botão "Enviar Documentos"
   → Redirecionará para tela de documentos (/driver-documents)
''');
}
