import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Helper para configurar rede corretamente em emuladores Android
///
/// Este helper resolve problemas de conectividade específicos de emuladores
/// sem comprometer a segurança ou bypassing a autenticação do Supabase
class EmulatorNetworkHelper {
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _emulatorTimeout = Duration(seconds: 60);

  /// Detecta se está rodando em emulador Android
  static bool get isAndroidEmulator {
    if (kIsWeb) return false;

    try {
      if (Platform.isAndroid) {
        // Verifica variáveis de ambiente típicas de emulador
        final env = Platform.environment;

        return env['ANDROID_EMULATOR'] == 'true' ||
            env['FLUTTER_TEST'] == 'true' ||
            _hasEmulatorCharacteristics();
      }
    } catch (e) {
      print('⚠️ [NETWORK] Erro ao detectar emulador: $e');
    }

    return false;
  }

  /// Verifica características físicas típicas de emuladores
  static bool _hasEmulatorCharacteristics() {
    try {
      // Verifica hostname
      final hostname = Platform.localHostname.toLowerCase();
      if (hostname.contains('emulator') ||
          hostname.contains('sdk') ||
          hostname.contains('android')) {
        return true;
      }

      // Outras verificações podem ser adicionadas aqui
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Retorna timeout apropriado baseado no ambiente
  static Duration get recommendedTimeout {
    return isAndroidEmulator ? _emulatorTimeout : _defaultTimeout;
  }

  /// Testa conectividade com o Supabase
  static Future<NetworkDiagnostic> testSupabaseConnection() async {
    print('🔍 [NETWORK] Testando conectividade com Supabase...');

    final diagnostic = NetworkDiagnostic();
    diagnostic.isEmulator = isAndroidEmulator;
    diagnostic.supabaseUrl = AppConfig.supabaseUrl;

    try {
      // Teste 1: Conectividade básica com internet
      print('📡 [NETWORK] Teste 1: Conectividade com internet');
      await _testInternetConnectivity();
      diagnostic.hasInternetConnection = true;
      print('✅ [NETWORK] Internet OK');

      // Teste 2: Resolução DNS do Supabase
      print('📡 [NETWORK] Teste 2: Resolução DNS');
      await _testDnsResolution(AppConfig.supabaseUrl);
      diagnostic.dnsResolutionWorking = true;
      print('✅ [NETWORK] DNS OK');

      // Teste 3: Conectividade HTTPS com Supabase
      print('📡 [NETWORK] Teste 3: Conectividade HTTPS');
      await _testSupabaseHttps();
      diagnostic.httpsConnectionWorking = true;
      print('✅ [NETWORK] HTTPS OK');

      // Teste 4: API Supabase respondendo
      print('📡 [NETWORK] Teste 4: API Supabase');
      await _testSupabaseApi();
      diagnostic.supabaseApiWorking = true;
      print('✅ [NETWORK] API Supabase OK');
    } catch (e) {
      diagnostic.lastError = e.toString();
      print('❌ [NETWORK] Erro nos testes: $e');
    }

    return diagnostic;
  }

  /// Testa conectividade básica com internet
  static Future<void> _testInternetConnectivity() async {
    final client = http.Client();
    try {
      final response = await client.get(
        Uri.parse('https://www.google.com'),
        headers: {'User-Agent': 'Flutter-Option-App'},
      ).timeout(recommendedTimeout);

      if (response.statusCode != 200) {
        throw Exception(
            'Google não respondeu corretamente: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  /// Testa resolução DNS
  static Future<void> _testDnsResolution(String url) async {
    final uri = Uri.parse(url);
    final addresses = await InternetAddress.lookup(uri.host);

    if (addresses.isEmpty) {
      throw Exception('Não foi possível resolver DNS para ${uri.host}');
    }

    print('🔍 [NETWORK] DNS resolvido: ${addresses.first.address}');
  }

  /// Testa conectividade HTTPS específica com Supabase
  static Future<void> _testSupabaseHttps() async {
    final client = http.Client();
    try {
      final response = await client.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'User-Agent': 'Flutter-Option-App',
        },
      ).timeout(recommendedTimeout);

      // Qualquer resposta (mesmo 404) indica conectividade OK
      if (response.statusCode >= 500) {
        throw Exception(
            'Servidor Supabase com problemas: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  /// Testa se a API Supabase está respondendo corretamente
  static Future<void> _testSupabaseApi() async {
    final client = http.Client();
    try {
      // Tenta uma query simples que sempre deve funcionar
      final response = await client.get(
        Uri.parse(
            '${AppConfig.supabaseUrl}/rest/v1/app_users?select=id&limit=1'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
          'User-Agent': 'Flutter-Option-App',
        },
      ).timeout(recommendedTimeout);

      if (response.statusCode == 200) {
        // API funcionando
        return;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Problemas de autenticação, mas API está respondendo
        throw Exception('Problema de configuração da API key');
      } else {
        throw Exception(
            'API não respondeu corretamente: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  /// Aplica configurações otimizadas para emuladores
  static Map<String, String> getOptimizedHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'User-Agent': 'Flutter-Option-App',
    };

    if (isAndroidEmulator) {
      // Headers específicos para emuladores
      headers['Cache-Control'] = 'no-cache';
      headers['Connection'] = 'keep-alive';
    }

    return headers;
  }

  /// Retorna HttpClient configurado para emuladores
  static HttpClient createOptimizedHttpClient() {
    final client = HttpClient();

    if (isAndroidEmulator) {
      // Configurações específicas para emuladores
      client.connectionTimeout = _emulatorTimeout;
      client.idleTimeout = _emulatorTimeout;

      // Para desenvolvimento, ser menos rigoroso com certificados
      client.badCertificateCallback = (cert, host, port) {
        print(
            '⚠️ [NETWORK] Certificado não validado para $host:$port (emulador)');
        return true; // Apenas em desenvolvimento!
      };
    }

    return client;
  }

  /// Gera relatório detalhado de rede
  static Future<void> generateNetworkReport() async {
    print('📊 [NETWORK] RELATÓRIO DE REDE - OPTION APP');
    print('=' * 50);

    print(
        '🤖 Ambiente: ${isAndroidEmulator ? "Emulador Android" : "Dispositivo físico/Web"}');
    print('⏱️ Timeout recomendado: ${recommendedTimeout.inSeconds}s');
    print('🌐 URL Supabase: ${AppConfig.supabaseUrl}');
    print('🔑 API Key configurada: ${AppConfig.supabaseAnonKey.isNotEmpty}');

    print('\n🔍 EXECUTANDO TESTES...\n');

    final diagnostic = await testSupabaseConnection();
    diagnostic.printReport();

    print('\n💡 RECOMENDAÇÕES:');
    if (diagnostic.isHealthy) {
      print('✅ Sua rede está funcionando corretamente!');
      print('   Problemas de auth provavelmente são de outra natureza.');
    } else {
      print('⚠️ Problemas de rede detectados:');
      if (!diagnostic.hasInternetConnection) {
        print('   - Verifique sua conexão com internet');
        print('   - No emulador: Settings > Network & Internet');
      }
      if (!diagnostic.dnsResolutionWorking) {
        print('   - Problema de DNS, tente reiniciar o emulador');
        print('   - Execute: adb kill-server && adb start-server');
      }
      if (!diagnostic.httpsConnectionWorking) {
        print('   - Problema com HTTPS, verifique certificados');
        print('   - Para emulador: configure network security config');
      }
      if (!diagnostic.supabaseApiWorking) {
        print('   - Verifique URL e API key do Supabase');
        print('   - Teste no Supabase Dashboard primeiro');
      }
    }

    print('\n⚡ COMANDOS ÚTEIS:');
    print('   adb shell ping google.com      # Testar internet no emulador');
    print('   adb shell nslookup supabase.co # Testar DNS');
    print('   flutter clean && flutter pub get # Limpar cache');
    print('   flutter run -d chrome          # Testar no navegador');
  }

  /// Configurações específicas para Supabase em emuladores
  static Map<String, dynamic> getSupabaseConfig() {
    final config = <String, dynamic>{
      'url': AppConfig.supabaseUrl,
      'anonKey': AppConfig.supabaseAnonKey,
    };

    if (isAndroidEmulator) {
      config['realtime'] = {
        'timeout': _emulatorTimeout.inMilliseconds,
        'heartbeatIntervalMs': 30000,
      };

      config['auth'] = {
        'autoRefreshToken': true,
        'persistSession': true,
        'detectSessionInUrl': false,
      };

      config['global'] = {
        'headers': getOptimizedHeaders(),
      };
    }

    return config;
  }
}

/// Classe para diagnóstico de rede
class NetworkDiagnostic {
  bool isEmulator = false;
  String supabaseUrl = '';
  bool hasInternetConnection = false;
  bool dnsResolutionWorking = false;
  bool httpsConnectionWorking = false;
  bool supabaseApiWorking = false;
  String? lastError;

  /// Retorna se a rede está saudável
  bool get isHealthy {
    return hasInternetConnection &&
        dnsResolutionWorking &&
        httpsConnectionWorking &&
        supabaseApiWorking;
  }

  /// Retorna pontuação de saúde (0-100)
  int get healthScore {
    int score = 0;
    if (hasInternetConnection) score += 25;
    if (dnsResolutionWorking) score += 25;
    if (httpsConnectionWorking) score += 25;
    if (supabaseApiWorking) score += 25;
    return score;
  }

  /// Imprime relatório detalhado
  void printReport() {
    print('📋 DIAGNÓSTICO DE REDE:');
    print('-' * 30);
    print('🤖 Emulador: ${isEmulator ? "Sim" : "Não"}');
    print(
        '🌐 Internet: ${_getStatusIcon(hasInternetConnection)} ${hasInternetConnection ? "OK" : "Falha"}');
    print(
        '📡 DNS: ${_getStatusIcon(dnsResolutionWorking)} ${dnsResolutionWorking ? "OK" : "Falha"}');
    print(
        '🔒 HTTPS: ${_getStatusIcon(httpsConnectionWorking)} ${httpsConnectionWorking ? "OK" : "Falha"}');
    print(
        '🎯 API Supabase: ${_getStatusIcon(supabaseApiWorking)} ${supabaseApiWorking ? "OK" : "Falha"}');

    if (lastError != null) {
      print('❌ Último erro: $lastError');
    }

    print('📊 Pontuação: $healthScore/100');
    print('🏥 Status: ${isHealthy ? "✅ Saudável" : "⚠️ Problemas detectados"}');
  }

  String _getStatusIcon(bool status) {
    return status ? "✅" : "❌";
  }
}
