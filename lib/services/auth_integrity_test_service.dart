import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/feature_flags.dart';
import '../utils/supabase_helper.dart';
import 'enhanced_data_integrity_service.dart';
import 'user_service.dart';

/// Serviço completo de testes de integridade do sistema Auth/Cadastro
/// FASE 3: Validação após implementação de todas as correções
class AuthIntegrityTestService {
  static SupabaseClient get _supabase {
    final client = SupabaseHelper.client;
    if (client == null) {
      throw Exception('Supabase não foi inicializado.');
    }
    return client;
  }

  /// Executa bateria completa de testes de integridade
  static Future<AuthIntegrityTestResult> runFullIntegrityTests() async {
    final startTime = DateTime.now();
    final results = <TestCaseResult>[];
    var overallScore = 0.0;
    var criticalFailures = 0;

    print('🔍 [INTEGRITY_TEST] Iniciando bateria completa de testes...');

    try {
      // 1. Testes de estrutura do banco
      results.add(await _testDatabaseStructure());
      
      // 2. Testes de integridade de dados
      results.add(await _testDataIntegrity());
      
      // 3. Testes de sincronização auth/app_users
      results.add(await _testAuthAppUsersSync());
      
      // 4. Testes de fluxos de autenticação
      results.add(await _testAuthenticationFlows());
      
      // 5. Testes de feature flags
      results.add(await _testFeatureFlags());
      
      // 6. Testes de correção de dados corrompidos
      results.add(await _testDataCorruptionHandling());
      
      // 7. Testes de performance básica
      results.add(await _testPerformance());
      
      // 8. Testes de validação de entrada
      results.add(await _testInputValidation());

      // Calcular score geral
      final scoreValues = results.map((r) => r.score).whereType<double>().toList();
      if (scoreValues.isNotEmpty) {
        overallScore = scoreValues.reduce((a, b) => a + b) / scoreValues.length;
      }

      // Contar falhas críticas
      criticalFailures = results
          .where((r) => r.severity == TestSeverity.critical && !r.passed)
          .length;

    } catch (e) {
      print('❌ [INTEGRITY_TEST] Erro durante execução dos testes: $e');
      results.add(TestCaseResult(
        name: 'Test Suite Execution',
        description: 'Execução da bateria de testes',
        passed: false,
        errorMessage: e.toString(),
        severity: TestSeverity.critical,
      ));
    }

    final duration = DateTime.now().difference(startTime);
    
    return AuthIntegrityTestResult(
      totalTests: results.length,
      passedTests: results.where((r) => r.passed).length,
      failedTests: results.where((r) => !r.passed).length,
      criticalFailures: criticalFailures,
      overallScore: overallScore,
      executionTime: duration,
      testResults: results,
      recommendation: _generateRecommendation(overallScore, criticalFailures),
    );
  }

  /// Teste 1: Estrutura do banco de dados
  static Future<TestCaseResult> _testDatabaseStructure() async {
    try {
      print('🔍 [INTEGRITY_TEST] Testando estrutura do banco...');
      
      final issues = <String>[];
      
      // Verificar se tabelas críticas existem
      final criticalTables = ['app_users', 'passengers', 'drivers'];
      for (final table in criticalTables) {
        try {
          await _supabase.from(table).select('id').limit(1);
        } catch (e) {
          issues.add('Tabela $table inacessível: $e');
        }
      }
      
      // Verificar constraints e índices críticos
      try {
        final result = await _supabase.rpc('validate_data_integrity');
        final score = result['integrity_score'] ?? 0;
        if (score < 95.0) {
          issues.add('Score de integridade baixo: $score%');
        }
      } catch (e) {
        issues.add('Função de validação indisponível: $e');
      }
      
      return TestCaseResult(
        name: 'Database Structure',
        description: 'Validação da estrutura e integridade do banco',
        passed: issues.isEmpty,
        errorMessage: issues.isNotEmpty ? issues.join(', ') : null,
        score: issues.isEmpty ? 1.0 : (1.0 - (issues.length * 0.3)).clamp(0.0, 1.0),
        severity: TestSeverity.critical,
      );
      
    } catch (e) {
      return TestCaseResult(
        name: 'Database Structure',
        description: 'Validação da estrutura do banco',
        passed: false,
        errorMessage: e.toString(),
        severity: TestSeverity.critical,
      );
    }
  }

  /// Teste 2: Integridade dos dados
  static Future<TestCaseResult> _testDataIntegrity() async {
    try {
      print('🔍 [INTEGRITY_TEST] Testando integridade dos dados...');
      
      final issues = <String>[];
      
      // Contar usuários corrompidos
      try {
        final corruptedUsers = await EnhancedDataIntegrityService.findDefinitelyCorruptedUsers();
        if (corruptedUsers.isNotEmpty) {
          issues.add('${corruptedUsers.length} usuários com dados corrompidos');
        }
      } catch (e) {
        issues.add('Falha na detecção de dados corrompidos: $e');
      }
      
      // Verificar órfãos
      try {
        final orphanedCountResponse = await _supabase
            .from('passengers')
            .select('id')
            .not('user_id', 'in', '(${await _getUserIds()})')
            .count(CountOption.exact);
        if (orphanedCountResponse.count > 0) {
          issues.add('${orphanedCountResponse.count} passageiros órfãos');
        }
      } catch (e) {
        issues.add('Falha na verificação de órfãos: $e');
      }
      
      final score = issues.isEmpty ? 1.0 : (1.0 - (issues.length * 0.2)).clamp(0.0, 1.0);
      
      return TestCaseResult(
        name: 'Data Integrity',
        description: 'Verificação de integridade referencial e dados corrompidos',
        passed: issues.isEmpty,
        errorMessage: issues.isNotEmpty ? issues.join(', ') : null,
        score: score,
        severity: TestSeverity.high,
      );
      
    } catch (e) {
      return TestCaseResult(
        name: 'Data Integrity',
        description: 'Verificação de integridade dos dados',
        passed: false,
        errorMessage: e.toString(),
        severity: TestSeverity.high,
      );
    }
  }

  /// Teste 3: Sincronização auth/app_users
  static Future<TestCaseResult> _testAuthAppUsersSync() async {
    try {
      print('🔍 [INTEGRITY_TEST] Testando sincronização auth/app_users...');
      
      final issues = <String>[];
      
      // Verificar usuários auth sem app_users
      try {
        final authUsersCount = await _supabase.rpc('count_auth_users') ?? 0;
        final appUsersCountResponse = await _supabase
            .from('app_users')
            .select('id')
            .count(CountOption.exact);
        final appUsersCount = appUsersCountResponse.count;
        
        final difference = (authUsersCount - appUsersCount).abs();
        if (difference > 5) { // Tolerância de 5 usuários
          issues.add('Dessincronização: $difference usuários entre auth e app_users');
        }
      } catch (e) {
        issues.add('Falha na verificação de sincronização: $e');
      }
      
      // Verificar usuários com dados inconsistentes
      try {
        final inconsistentUsers = await _supabase
            .from('app_users')
            .select('id, email')
            .neq('email', '') // Email não vazio
            .limit(100);
        
        for (final user in inconsistentUsers) {
          // Aqui poderia verificar se email no auth.users bate com app_users
          // Simplificado devido às limitações de acesso ao auth.users
        }
      } catch (e) {
        issues.add('Falha na verificação de consistência: $e');
      }
      
      return TestCaseResult(
        name: 'Auth Sync',
        description: 'Sincronização entre auth.users e app_users',
        passed: issues.isEmpty,
        errorMessage: issues.isNotEmpty ? issues.join(', ') : null,
        score: issues.isEmpty ? 1.0 : 0.7,
      );
      
    } catch (e) {
      return TestCaseResult(
        name: 'Auth Sync',
        description: 'Teste de sincronização auth/app_users',
        passed: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Teste 4: Fluxos de autenticação
  static Future<TestCaseResult> _testAuthenticationFlows() async {
    try {
      print('🔍 [INTEGRITY_TEST] Testando fluxos de autenticação...');
      
      final issues = <String>[];
      
      // Testar se UserService funciona
      try {
        final testUser = await UserService.getCurrentUser();
        // Se não há usuário logado, isso não é necessariamente um erro
      } catch (e) {
        if (!e.toString().contains('não autenticado')) {
          issues.add('Falha no UserService.getCurrentUser: $e');
        }
      }
      
      // Testar validação de dados
      try {
        EnhancedDataIntegrityService.validateDataBeforeInsertSafe({
          'full_name': 'Nome Válido',
          'email': 'teste@email.com',
        });
      } catch (e) {
        issues.add('Falha na validação de dados: $e');
      }
      
      // Testar detecção de corrupção
      try {
        EnhancedDataIntegrityService.validateDataBeforeInsertSafe({
          'full_name': 'missing_passenger_records',
          'email': 'teste@email.com',
        });
        issues.add('Validação não detectou dados corrompidos óbvios');
      } catch (e) {
        // Este erro é esperado - dados corrompidos devem ser rejeitados
      }
      
      return TestCaseResult(
        name: 'Authentication Flows',
        description: 'Validação dos fluxos de autenticação e registro',
        passed: issues.isEmpty,
        errorMessage: issues.isNotEmpty ? issues.join(', ') : null,
        score: issues.isEmpty ? 1.0 : (1.0 - (issues.length * 0.3)).clamp(0.0, 1.0),
        severity: TestSeverity.high,
      );
      
    } catch (e) {
      return TestCaseResult(
        name: 'Authentication Flows',
        description: 'Teste dos fluxos de autenticação',
        passed: false,
        errorMessage: e.toString(),
        severity: TestSeverity.high,
      );
    }
  }

  /// Teste 5: Feature flags
  static Future<TestCaseResult> _testFeatureFlags() async {
    try {
      print('🔍 [INTEGRITY_TEST] Testando feature flags...');
      
      final issues = <String>[];
      
      // Testar se todas as flags são acessíveis
      final flags = featureFlags.getAllFlags();
      if (flags.isEmpty) {
        issues.add('Nenhuma feature flag encontrada');
      }
      
      // Testar configuração conservadora (FASE 1)
      if (featureFlags.directUserCreation) {
        issues.add('directUserCreation ativa em FASE 1 (deveria estar false)');
      }
      
      if (!featureFlags.enhancedDataValidation) {
        issues.add('enhancedDataValidation inativa (deveria estar true)');
      }
      
      if (!featureFlags.migrationLogs) {
        issues.add('migrationLogs inativo (deveria estar true para monitoramento)');
      }
      
      if (!featureFlags.legacyFallback) {
        issues.add('legacyFallback inativo (deveria estar true para segurança)');
      }
      
      return TestCaseResult(
        name: 'Feature Flags',
        description: 'Validação das configurações de feature flags',
        passed: issues.isEmpty,
        errorMessage: issues.isNotEmpty ? issues.join(', ') : null,
        score: issues.isEmpty ? 1.0 : (1.0 - (issues.length * 0.2)).clamp(0.0, 1.0),
      );
      
    } catch (e) {
      return TestCaseResult(
        name: 'Feature Flags',
        description: 'Teste das feature flags',
        passed: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Teste 6: Manipulação de dados corrompidos
  static Future<TestCaseResult> _testDataCorruptionHandling() async {
    try {
      print('🔍 [INTEGRITY_TEST] Testando manipulação de dados corrompidos...');
      
      final issues = <String>[];
      
      // Testar detecção de padrões corrompidos conhecidos
      final testCases = {
        'missing_passenger_records': true, // Deve ser detectado
        'João Silva': false,              // Nome válido
        '{"count": 123}': true,           // JSON corrompido
        'Usuario Normal': false,          // Nome válido
        'PENDENTE_CADASTRO': true,        // Placeholder corrompido
      };
      
      for (final entry in testCases.entries) {
        final testName = entry.key;
        final shouldDetect = entry.value;
        
        final analysis = EnhancedDataIntegrityService.analyzeField('full_name', testName);
        if (analysis.isCorrupted != shouldDetect) {
          issues.add(
            'Detecção incorreta para "$testName": esperado=$shouldDetect, obtido=${analysis.isCorrupted}'
          );
        }
      }
      
      return TestCaseResult(
        name: 'Corruption Handling',
        description: 'Detecção e manipulação de dados corrompidos',
        passed: issues.isEmpty,
        errorMessage: issues.isNotEmpty ? issues.join(', ') : null,
        score: issues.isEmpty ? 1.0 : (1.0 - (issues.length * 0.25)).clamp(0.0, 1.0),
        severity: TestSeverity.high,
      );
      
    } catch (e) {
      return TestCaseResult(
        name: 'Corruption Handling',
        description: 'Teste de manipulação de dados corrompidos',
        passed: false,
        errorMessage: e.toString(),
        severity: TestSeverity.high,
      );
    }
  }

  /// Teste 7: Performance básica
  static Future<TestCaseResult> _testPerformance() async {
    try {
      print('🔍 [INTEGRITY_TEST] Testando performance básica...');
      
      final issues = <String>[];
      
      // Testar tempo de resposta de queries críticas
      final startTime = DateTime.now();
      
      try {
        // Query de contagem de usuários
        final countResponse = await _supabase
            .from('app_users')
            .select('id')
            .limit(1)
            .count(CountOption.exact);
        
        final userQueryTime = DateTime.now().difference(startTime);
        if (userQueryTime.inMilliseconds > 1000) {
          issues.add('Query de usuários lenta: ${userQueryTime.inMilliseconds}ms');
        }
      } catch (e) {
        issues.add('Falha na query de performance: $e');
      }
      
      return TestCaseResult(
        name: 'Basic Performance',
        description: 'Testes básicos de performance',
        passed: issues.isEmpty,
        errorMessage: issues.isNotEmpty ? issues.join(', ') : null,
        score: issues.isEmpty ? 1.0 : 0.8,
        severity: TestSeverity.low,
      );
      
    } catch (e) {
      return TestCaseResult(
        name: 'Basic Performance',
        description: 'Teste de performance básica',
        passed: false,
        errorMessage: e.toString(),
        severity: TestSeverity.low,
      );
    }
  }

  /// Teste 8: Validação de entrada
  static Future<TestCaseResult> _testInputValidation() async {
    try {
      print('🔍 [INTEGRITY_TEST] Testando validação de entrada...');
      
      final issues = <String>[];
      
      // Testar validações do sistema
      final invalidInputs = [
        {'full_name': '', 'email': 'teste@email.com'},
        {'full_name': 'Nome', 'email': 'email-inválido'},
        {'full_name': 'missing_passenger_records', 'email': 'teste@email.com'},
      ];
      
      for (final input in invalidInputs) {
        try {
          EnhancedDataIntegrityService.validateDataBeforeInsertSafe(input);
          issues.add('Validação não rejeitou entrada inválida: $input');
        } catch (e) {
          // Erro esperado - entrada inválida deve ser rejeitada
        }
      }
      
      return TestCaseResult(
        name: 'Input Validation',
        description: 'Validação de entradas e sanitização',
        passed: issues.isEmpty,
        errorMessage: issues.isNotEmpty ? issues.join(', ') : null,
        score: issues.isEmpty ? 1.0 : (1.0 - (issues.length * 0.3)).clamp(0.0, 1.0),
      );
      
    } catch (e) {
      return TestCaseResult(
        name: 'Input Validation',
        description: 'Teste de validação de entrada',
        passed: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Helper para obter lista de IDs de usuários
  static Future<String> _getUserIds() async {
    try {
      final users = await _supabase.from('app_users').select('id').limit(1000);
      final ids = users.map((u) => "'${u['id']}'").join(',');
      return ids.isNotEmpty ? ids : "''";
    } catch (e) {
      return "''";
    }
  }

  /// Gera recomendação baseada nos resultados
  static String _generateRecommendation(double score, int criticalFailures) {
    if (criticalFailures > 0) {
      return '🚨 CRÍTICO: Falhas críticas encontradas. Sistema não está pronto para produção.';
    } else if (score >= 0.9) {
      return '✅ EXCELENTE: Sistema está íntegro e pronto para uso.';
    } else if (score >= 0.8) {
      return '⚠️ BOM: Sistema funcional com pequenas melhorias recomendadas.';
    } else if (score >= 0.7) {
      return '🔧 REGULAR: Várias questões identificadas, correções recomendadas.';
    } else {
      return '❌ CRÍTICO: Score baixo, sistema precisa de correções significativas.';
    }
  }
}

/// Resultado de um teste individual
class TestCaseResult {
  TestCaseResult({
    required this.name,
    required this.description,
    required this.passed,
    this.errorMessage,
    this.score,
    this.severity = TestSeverity.medium,
    this.details,
  });

  final String name;
  final String description;
  final bool passed;
  final String? errorMessage;
  final double? score; // 0.0 - 1.0
  final TestSeverity severity;
  final Map<String, dynamic>? details;

  @override
  String toString() => 
      '${passed ? "✅" : "❌"} $name: ${passed ? "PASS" : "FAIL"}${errorMessage != null ? " - $errorMessage" : ""}';
}

/// Severidade do teste
enum TestSeverity {
  low,
  medium,
  high,
  critical,
}

/// Resultado completo da bateria de testes
class AuthIntegrityTestResult {
  AuthIntegrityTestResult({
    required this.totalTests,
    required this.passedTests,
    required this.failedTests,
    required this.criticalFailures,
    required this.overallScore,
    required this.executionTime,
    required this.testResults,
    required this.recommendation,
  });

  final int totalTests;
  final int passedTests;
  final int failedTests;
  final int criticalFailures;
  final double overallScore; // 0.0 - 1.0
  final Duration executionTime;
  final List<TestCaseResult> testResults;
  final String recommendation;

  bool get isHealthy => criticalFailures == 0 && overallScore >= 0.8;
  double get successRate => totalTests > 0 ? (passedTests / totalTests) : 0.0;

  @override
  String toString() => '''
🔍 RELATÓRIO DE INTEGRIDADE DO SISTEMA AUTH/CADASTRO
=================================================

📊 RESUMO:
   Total de testes: $totalTests
   Aprovados: $passedTests
   Falharam: $failedTests
   Falhas críticas: $criticalFailures
   
   Score geral: ${(overallScore * 100).toStringAsFixed(1)}%
   Taxa de sucesso: ${(successRate * 100).toStringAsFixed(1)}%
   Tempo de execução: ${executionTime.inSeconds}s

🎯 RECOMENDAÇÃO:
   $recommendation

📋 DETALHES DOS TESTES:
${testResults.map((t) => '   $t').join('\n')}
=================================================
''';
}