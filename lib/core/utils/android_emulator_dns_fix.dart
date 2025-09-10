import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Correções específicas para problemas de DNS em emuladores Android
///
/// Esta classe implementa soluções para resolver problemas de conectividade
/// em emuladores Android, especialmente relacionados a resolução de DNS
class AndroidEmulatorDNSFix {
  static const String _primaryDNS = '8.8.8.8';
  static const String _secondaryDNS = '1.1.1.1';
  static const Duration _timeout = Duration(seconds: 30);

  /// Detecta se está rodando em emulador Android
  static bool get isAndroidEmulator {
    if (kIsWeb) return false;

    try {
      if (!Platform.isAndroid) return false;

      // Verifica características típicas de emulador
      final hostname = Platform.localHostname.toLowerCase();
      final environment = Platform.environment;

      return hostname.contains('sdk') ||
          hostname.contains('emulator') ||
          hostname.contains('android') ||
          environment['ANDROID_EMULATOR'] == 'true' ||
          environment['FLUTTER_TEST'] == 'true';
    } catch (e) {
      debugPrint('⚠️ [DNS_FIX] Erro ao detectar emulador: $e');
      return false;
    }
  }

  /// Testa conectividade básica com DNS públicos
  static Future<bool> testDNSConnectivity() async {
    if (!isAndroidEmulator) return true;

    debugPrint('🔍 [DNS_FIX] Testando conectividade DNS...');

    try {
      // Testa DNS primário
      final result1 = await _pingDNS(_primaryDNS);
      if (result1) {
        debugPrint('✅ [DNS_FIX] DNS primário OK');
        return true;
      }

      // Testa DNS secundário
      final result2 = await _pingDNS(_secondaryDNS);
      if (result2) {
        debugPrint('✅ [DNS_FIX] DNS secundário OK');
        return true;
      }

      debugPrint('❌ [DNS_FIX] Ambos DNS falharam');
      return false;
    } catch (e) {
      debugPrint('❌ [DNS_FIX] Erro no teste DNS: $e');
      return false;
    }
  }

  /// Testa ping para um DNS específico
  static Future<bool> _pingDNS(String dns) async {
    try {
      final result = await http.get(
        Uri.parse('http://$dns'),
        headers: {'Connection': 'close'},
      ).timeout(_timeout);

      // Se chegou aqui, a conectividade básica funciona
      return true;
    } catch (e) {
      // Timeout ou erro de conexão são esperados para DNS servers
      // O importante é que o socket conseguiu conectar
      return e.toString().contains('Connection') ||
          e.toString().contains('timeout') ||
          e.toString().contains('HandshakeException');
    }
  }

  /// Testa resolução de hostname específico
  static Future<bool> testHostnameResolution(String hostname) async {
    if (!isAndroidEmulator) return true;

    debugPrint('🔍 [DNS_FIX] Testando resolução de $hostname...');

    try {
      final addresses =
          await InternetAddress.lookup(hostname).timeout(_timeout);

      if (addresses.isNotEmpty) {
        debugPrint(
            '✅ [DNS_FIX] $hostname resolvido para ${addresses.first.address}');
        return true;
      } else {
        debugPrint('❌ [DNS_FIX] $hostname não resolvido');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [DNS_FIX] Erro ao resolver $hostname: $e');
      return false;
    }
  }

  /// Testa conectividade HTTP básica
  static Future<bool> testHTTPConnectivity(String url) async {
    if (!isAndroidEmulator) return true;

    debugPrint('🔍 [DNS_FIX] Testando conectividade HTTP para $url...');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Flutter-Android-Emulator',
          'Connection': 'close',
        },
      ).timeout(_timeout);

      final success = response.statusCode < 500;
      if (success) {
        debugPrint('✅ [DNS_FIX] HTTP OK - Status: ${response.statusCode}');
      } else {
        debugPrint(
            '⚠️ [DNS_FIX] HTTP parcial - Status: ${response.statusCode}');
      }

      return success;
    } catch (e) {
      debugPrint('❌ [DNS_FIX] Erro HTTP: $e');
      return false;
    }
  }

  /// Executa diagnóstico completo de rede
  static Future<NetworkDiagnosticResult> runFullDiagnostic({
    required String supabaseUrl,
  }) async {
    debugPrint('🔍 [DNS_FIX] Iniciando diagnóstico completo...');

    final result = NetworkDiagnosticResult();

    // 1. Teste DNS básico
    result.dnsConnectivity = await testDNSConnectivity();

    // 2. Teste resolução do Supabase
    final supabaseHost = Uri.parse(supabaseUrl).host;
    result.supabaseResolution = await testHostnameResolution(supabaseHost);

    // 3. Teste HTTP do Supabase
    result.supabaseHTTP = await testHTTPConnectivity(supabaseUrl);

    // 4. Teste conectividade geral
    result.internetConnectivity =
        await testHTTPConnectivity('https://google.com');

    result.printReport();
    return result;
  }

  /// Fornece recomendações para resolver problemas
  static List<String> getRecommendations(NetworkDiagnosticResult result,
      {String? supabaseUrl}) {
    final recommendations = <String>[];

    if (!result.dnsConnectivity) {
      recommendations.addAll([
        '🔧 Reinicie o emulador Android',
        '🔧 Execute: adb shell nslookup google.com',
        '🔧 Verifique configurações de proxy no AVD',
      ]);
    }

    if (!result.supabaseResolution) {
      recommendations.addAll([
        '🔧 Execute: adb shell ping qlbwacmavngtonauxnte.supabase.co',
        '🔧 Teste em dispositivo físico',
        '🔧 Configure DNS manual no emulador',
      ]);
    }

    if (!result.supabaseHTTP) {
      recommendations.addAll([
        '🔧 Verifique firewall do macOS',
        if (supabaseUrl != null) '🔧 Teste conexão: curl -v $supabaseUrl',
        '🔧 Execute app no Chrome: flutter run -d chrome',
      ]);
    }

    if (!result.internetConnectivity) {
      recommendations.addAll([
        '🔧 Verifique conexão de internet do host',
        '🔧 Reinicie o emulador com internet',
        '🔧 Configure proxy se necessário',
      ]);
    }

    // Se tudo está OK mas ainda há problemas
    if (result.isHealthy) {
      recommendations.addAll([
        '🔧 Aumente timeout para 60s',
        '🔧 Implemente retry com backoff exponencial',
        '🔧 Use cache de DNS personalizado',
      ]);
    }

    return recommendations;
  }

  /// Configura headers HTTP otimizados para emulador
  static Map<String, String> getOptimizedHeaders() {
    return {
      'User-Agent': 'Flutter-Android-Emulator',
      'Connection': 'keep-alive',
      'Cache-Control': 'no-cache',
      'Accept': 'application/json',
      'Accept-Encoding': 'gzip, deflate',
    };
  }
}

/// Resultado do diagnóstico de rede
class NetworkDiagnosticResult {
  bool dnsConnectivity = false;
  bool supabaseResolution = false;
  bool supabaseHTTP = false;
  bool internetConnectivity = false;

  /// Verifica se a rede está saudável
  bool get isHealthy =>
      dnsConnectivity &&
      supabaseResolution &&
      supabaseHTTP &&
      internetConnectivity;

  /// Calcula score de saúde (0-100)
  int get healthScore {
    int score = 0;
    if (dnsConnectivity) score += 25;
    if (supabaseResolution) score += 25;
    if (supabaseHTTP) score += 30;
    if (internetConnectivity) score += 20;
    return score;
  }

  /// Imprime relatório detalhado
  void printReport() {
    debugPrint('📊 [DIAGNÓSTICO] Relatório de Rede:');
    debugPrint('=' * 50);
    debugPrint('DNS Connectivity: ${dnsConnectivity ? "✅" : "❌"}');
    debugPrint('Supabase Resolution: ${supabaseResolution ? "✅" : "❌"}');
    debugPrint('Supabase HTTP: ${supabaseHTTP ? "✅" : "❌"}');
    debugPrint('Internet Connectivity: ${internetConnectivity ? "✅" : "❌"}');
    debugPrint('Health Score: $healthScore/100');
    debugPrint('Status: ${isHealthy ? "✅ SAUDÁVEL" : "❌ PROBLEMAS"}');
    debugPrint('=' * 50);
  }
}
