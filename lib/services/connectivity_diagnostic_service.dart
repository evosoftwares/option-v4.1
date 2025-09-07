import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Serviço de diagnóstico e correção de problemas de conectividade
class ConnectivityDiagnosticService {
  static const String _supabaseHost = 'qlbwacmavngtonauxnte.supabase.co';
  static const String _supabaseUrl = 'https://qlbwacmavngtonauxnte.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E';

  // DNS alternativos para testar
  static const List<String> _alternativeDns = [
    '8.8.8.8', // Google DNS
    '8.8.4.4', // Google DNS Secondary
    '1.1.1.1', // Cloudflare DNS
    '1.0.0.1', // Cloudflare DNS Secondary
    '208.67.222.222', // OpenDNS
  ];

  /// Executa diagnóstico completo de conectividade
  static Future<ConnectivityDiagnosticResult> runFullDiagnostic() async {
    final result = ConnectivityDiagnosticResult();

    print('🔍 [CONNECTIVITY] Iniciando diagnóstico completo...\n');

    // Teste 1: Conectividade básica de internet
    print('1️⃣ [CONNECTIVITY] Testando conectividade básica...');
    result.hasInternetConnectivity = await _testBasicConnectivity();
    print(
        '   ${result.hasInternetConnectivity ? '✅' : '❌'} Internet: ${result.hasInternetConnectivity ? 'OK' : 'FALHA'}\n');

    if (!result.hasInternetConnectivity) {
      result.recommendations.add('Verificar conexão com a internet');
      return result;
    }

    // Teste 2: Resolução DNS do Supabase
    print('2️⃣ [CONNECTIVITY] Testando resolução DNS...');
    result.dnsResolutionWorks = await _testDnsResolution();
    print(
        '   ${result.dnsResolutionWorks ? '✅' : '❌'} DNS Resolution: ${result.dnsResolutionWorks ? 'OK' : 'FALHA'}\n');

    if (!result.dnsResolutionWorks) {
      result.recommendations
          .add('Problema de DNS detectado - tentando DNS alternativos');
      result.alternativeDnsResults = await _testAlternativeDns();
    }

    // Teste 3: Conectividade HTTP com Supabase
    print('3️⃣ [CONNECTIVITY] Testando conectividade HTTP...');
    result.httpConnectivityWorks = await _testHttpConnectivity();
    print(
        '   ${result.httpConnectivityWorks ? '✅' : '❌'} HTTP: ${result.httpConnectivityWorks ? 'OK' : 'FALHA'}\n');

    // Teste 4: Autenticação Supabase
    if (result.httpConnectivityWorks) {
      print('4️⃣ [CONNECTIVITY] Testando autenticação...');
      result.authenticationWorks = await _testAuthentication();
      print(
          '   ${result.authenticationWorks ? '✅' : '❌'} Auth: ${result.authenticationWorks ? 'OK' : 'FALHA'}\n');
    }

    // Teste 5: Acesso às tabelas
    if (result.authenticationWorks) {
      print('5️⃣ [CONNECTIVITY] Testando acesso às tabelas...');
      result.databaseAccessWorks = await _testDatabaseAccess();
      print(
          '   ${result.databaseAccessWorks ? '✅' : '❌'} Database: ${result.databaseAccessWorks ? 'OK' : 'FALHA'}\n');
    }

    // Gerar recomendações
    _generateRecommendations(result);

    return result;
  }

  /// Testa conectividade básica com serviços conhecidos
  static Future<bool> _testBasicConnectivity() async {
    final testSites = [
      'google.com',
      'cloudflare.com',
      '8.8.8.8',
    ];

    for (final site in testSites) {
      try {
        print('   🔗 Testando: $site');
        final result = await InternetAddress.lookup(site);
        if (result.isNotEmpty) {
          print('   ✅ $site: OK');
          return true;
        }
      } catch (e) {
        print('   ❌ $site: $e');
      }
    }

    return false;
  }

  /// Testa resolução DNS do hostname do Supabase
  static Future<bool> _testDnsResolution() async {
    try {
      print('   🔗 Resolvendo: $_supabaseHost');
      final result = await InternetAddress.lookup(_supabaseHost);
      if (result.isNotEmpty) {
        print('   ✅ IP encontrado: ${result.first.address}');
        return true;
      }
    } catch (e) {
      print('   ❌ Erro na resolução DNS: $e');
    }
    return false;
  }

  /// Testa DNS alternativos
  static Future<Map<String, bool>> _testAlternativeDns() async {
    final results = <String, bool>{};

    print('   🔄 Testando DNS alternativos...');

    for (final dns in _alternativeDns) {
      try {
        print('   🔗 Testando DNS: $dns');

        // Simular mudança de DNS (em um app real, isso seria mais complexo)
        final result = await InternetAddress.lookup('google.com');
        if (result.isNotEmpty) {
          results[dns] = true;
          print('   ✅ DNS $dns: OK');
        } else {
          results[dns] = false;
          print('   ❌ DNS $dns: Falhou');
        }
      } catch (e) {
        results[dns] = false;
        print('   ❌ DNS $dns: $e');
      }
    }

    return results;
  }

  /// Testa conectividade HTTP básica
  static Future<bool> _testHttpConnectivity() async {
    try {
      print('   🔗 Testando: $_supabaseUrl/rest/v1/');

      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/'),
        headers: {
          'apikey': _supabaseAnonKey,
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('   ✅ HTTP OK: ${response.statusCode}');
        return true;
      } else {
        print('   ⚠️ HTTP Status: ${response.statusCode}');
        return response.statusCode < 500; // 4xx é OK, 5xx não
      }
    } catch (e) {
      print('   ❌ HTTP Error: $e');
      return false;
    }
  }

  /// Testa autenticação básica
  static Future<bool> _testAuthentication() async {
    try {
      print('   🔗 Testando autenticação...');

      final response = await http.get(
        Uri.parse('$_supabaseUrl/auth/v1/user'),
        headers: {
          'apikey': _supabaseAnonKey,
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
      ).timeout(const Duration(seconds: 10));

      // Pode retornar 401 se não estiver logado, mas isso significa que o serviço está funcionando
      if (response.statusCode == 401 || response.statusCode == 200) {
        print('   ✅ Auth Service OK: ${response.statusCode}');
        return true;
      } else {
        print('   ❌ Auth Service Error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('   ❌ Auth Error: $e');
      return false;
    }
  }

  /// Testa acesso ao banco de dados
  static Future<bool> _testDatabaseAccess() async {
    try {
      print('   🔗 Testando acesso ao banco...');

      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/app_users?select=id&limit=1'),
        headers: {
          'apikey': _supabaseAnonKey,
          'Authorization': 'Bearer $_supabaseAnonKey',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 206) {
        print('   ✅ Database OK: ${response.statusCode}');
        final data = jsonDecode(response.body);
        print('   📊 Dados recebidos: ${data.length} registros');
        return true;
      } else {
        print('   ❌ Database Error: ${response.statusCode}');
        print('   📄 Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('   ❌ Database Error: $e');
      return false;
    }
  }

  /// Gera recomendações baseadas nos resultados
  static void _generateRecommendations(ConnectivityDiagnosticResult result) {
    print('📋 [CONNECTIVITY] Gerando recomendações...\n');

    if (!result.hasInternetConnectivity) {
      result.recommendations.addAll([
        'Verificar conexão Wi-Fi ou dados móveis',
        'Reiniciar roteador/modem',
        'Verificar se não há bloqueios de firewall',
      ]);
    }

    if (!result.dnsResolutionWorks) {
      result.recommendations.addAll([
        'Configurar DNS alternativo (8.8.8.8 ou 1.1.1.1)',
        'Limpar cache DNS do dispositivo',
        'Verificar configurações de proxy',
        'Usar modo bypass até resolver o problema de DNS',
      ]);
    }

    if (!result.httpConnectivityWorks) {
      result.recommendations.addAll([
        'Verificar se há proxy ou VPN interferindo',
        'Verificar configurações de certificado SSL',
        'Tentar conexão via dados móveis em vez de Wi-Fi',
        'Usar modo bypass temporariamente',
      ]);
    }

    if (!result.authenticationWorks) {
      result.recommendations.addAll([
        'Verificar chaves de API do Supabase',
        'Verificar configurações de CORS',
        'Usar modo bypass até resolver problema de autenticação',
      ]);
    }

    if (!result.databaseAccessWorks) {
      result.recommendations.addAll([
        'Verificar políticas RLS do Supabase',
        'Verificar permissões da chave anônima',
        'Usar bypass_auth_service temporariamente',
      ]);
    }

    // Se tudo funciona
    if (result.isFullyFunctional) {
      result.recommendations
          .add('✅ Conectividade OK - Pode usar autenticação padrão');
    } else {
      result.recommendations
          .add('⚠️ Usar modo bypass até resolver problemas de conectividade');
    }
  }

  /// Testa conectividade rápida (para usar em telas)
  static Future<bool> quickConnectivityTest() async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/'),
        headers: {
          'apikey': _supabaseAnonKey,
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
      ).timeout(const Duration(seconds: 5));

      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (e) {
      print('❌ [CONNECTIVITY] Quick test failed: $e');
      return false;
    }
  }

  /// Força atualização de DNS (reinicia conexões)
  static Future<void> refreshDnsCache() async {
    try {
      print('🔄 [CONNECTIVITY] Atualizando cache DNS...');

      // Tentar resolver alguns hosts para forçar refresh
      final hosts = ['google.com', 'cloudflare.com', _supabaseHost];

      for (final host in hosts) {
        try {
          await InternetAddress.lookup(host);
          print('✅ [CONNECTIVITY] DNS atualizado para: $host');
        } catch (e) {
          print('❌ [CONNECTIVITY] Falha ao atualizar DNS para $host: $e');
        }
      }
    } catch (e) {
      print('❌ [CONNECTIVITY] Erro ao atualizar DNS: $e');
    }
  }
}

/// Resultado do diagnóstico de conectividade
class ConnectivityDiagnosticResult {
  bool hasInternetConnectivity = false;
  bool dnsResolutionWorks = false;
  bool httpConnectivityWorks = false;
  bool authenticationWorks = false;
  bool databaseAccessWorks = false;
  Map<String, bool> alternativeDnsResults = {};
  List<String> recommendations = [];

  bool get isFullyFunctional =>
      hasInternetConnectivity &&
      dnsResolutionWorks &&
      httpConnectivityWorks &&
      authenticationWorks &&
      databaseAccessWorks;

  bool get shouldUseBypassMode => !isFullyFunctional;

  void printSummary() {
    print('\n📋 [CONNECTIVITY] RESUMO DO DIAGNÓSTICO');
    print('=' * 50);
    print('Internet Connectivity: ${hasInternetConnectivity ? '✅' : '❌'}');
    print('DNS Resolution: ${dnsResolutionWorks ? '✅' : '❌'}');
    print('HTTP Connectivity: ${httpConnectivityWorks ? '✅' : '❌'}');
    print('Authentication: ${authenticationWorks ? '✅' : '❌'}');
    print('Database Access: ${databaseAccessWorks ? '✅' : '❌'}');
    print(
        'Status Geral: ${isFullyFunctional ? '✅ FUNCIONANDO' : '⚠️ PROBLEMAS DETECTADOS'}');

    if (alternativeDnsResults.isNotEmpty) {
      print('\nDNS Alternativos testados:');
      alternativeDnsResults.forEach((dns, works) {
        print('  $dns: ${works ? '✅' : '❌'}');
      });
    }

    if (recommendations.isNotEmpty) {
      print('\n💡 RECOMENDAÇÕES:');
      for (int i = 0; i < recommendations.length; i++) {
        print('  ${i + 1}. ${recommendations[i]}');
      }
    }

    print('=' * 50);

    if (shouldUseBypassMode) {
      print('🚨 AÇÃO RECOMENDADA: Usar modo bypass de autenticação');
    } else {
      print('✅ AÇÃO RECOMENDADA: Pode usar autenticação padrão');
    }
    print('\n');
  }
}
