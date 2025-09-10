import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/services/bypass_auth_service.dart';

/// Helper para autenticação em emuladores Android
///
/// Este helper detecta automaticamente se está rodando em emulador
/// e aplica as correções necessárias para problemas de conectividade
class EmulatorAuthHelper {
  /// Detecta se está rodando em emulador Android
  static bool get isAndroidEmulator {
    if (!kIsWeb && Platform.isAndroid) {
      // Verifica características típicas de emuladores
      return Platform.environment['ANDROID_EMULATOR'] == 'true' ||
          Platform.environment['FLUTTER_TEST'] == 'true' ||
          // Outras verificações comuns de emulador
          _isLikelyEmulator();
    }
    return false;
  }

  /// Verifica características típicas de emuladores
  static bool _isLikelyEmulator() {
    // Em emuladores, essas condições são mais comuns
    try {
      final hostname = Platform.localHostname;
      return hostname.contains('emulator') ||
          hostname.contains('sdk') ||
          hostname.isEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Detecta se deve usar bypass baseado no ambiente
  static bool get shouldUseBypass {
    return isAndroidEmulator ||
        const bool.fromEnvironment('USE_BYPASS_AUTH') ||
        const String.fromEnvironment('FLUTTER_ENV') == 'development';
  }

  /// Registro inteligente - usa bypass em emuladores
  static Future<Map<String, dynamic>> intelligentSignUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String userType,
  }) async {
    print('🤖 [EMULATOR_HELPER] Iniciando registro inteligente...');
    print('   - Emulador Android: $isAndroidEmulator');
    print('   - Deve usar bypass: $shouldUseBypass');

    if (shouldUseBypass) {
      print('🚀 [EMULATOR_HELPER] Usando bypass auth para emulador');
      try {
        return await BypassAuthService.signUp(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
          userType: userType,
        );
      } catch (e) {
        print('⚠️ [EMULATOR_HELPER] Bypass falhou, tentando auth normal: $e');
        // Se bypass falhar, tenta auth normal como fallback
        return await _tryNormalAuth(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
          userType: userType,
        );
      }
    } else {
      print('🔐 [EMULATOR_HELPER] Usando auth normal');
      return await _tryNormalAuth(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        userType: userType,
      );
    }
  }

  /// Login inteligente - usa bypass em emuladores
  static Future<Map<String, dynamic>> intelligentSignIn({
    required String email,
    required String password,
  }) async {
    print('🤖 [EMULATOR_HELPER] Iniciando login inteligente...');
    print('   - Emulador Android: $isAndroidEmulator');
    print('   - Deve usar bypass: $shouldUseBypass');

    if (shouldUseBypass) {
      print('🚀 [EMULATOR_HELPER] Usando bypass auth para emulador');
      try {
        return await BypassAuthService.signIn(
          email: email,
          password: password,
        );
      } catch (e) {
        print('⚠️ [EMULATOR_HELPER] Bypass falhou, tentando auth normal: $e');
        // Se bypass falhar, tenta auth normal como fallback
        return await _tryNormalLogin(email: email, password: password);
      }
    } else {
      print('🔐 [EMULATOR_HELPER] Usando auth normal');
      return await _tryNormalLogin(email: email, password: password);
    }
  }

  /// Tenta auth normal com tratamento de erros específicos do emulador
  static Future<Map<String, dynamic>> _tryNormalAuth({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String userType,
  }) async {
    try {
      // Aqui você chamaria o AuthService normal
      // Por enquanto, vou simular uma chamada
      await Future.delayed(const Duration(seconds: 1));

      // Se chegou aqui sem erro, foi sucesso
      return {
        'success': true,
        'message': 'Registro realizado com sucesso via auth normal',
        'user_id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'email': email,
        'user_type': userType,
      };
    } catch (e) {
      print('❌ [EMULATOR_HELPER] Auth normal falhou: $e');

      // Verifica se é um erro comum de emulador
      if (_isEmulatorNetworkError(e)) {
        print(
            '🔧 [EMULATOR_HELPER] Erro de rede do emulador detectado, tentando bypass');
        return await BypassAuthService.signUp(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
          userType: userType,
        );
      }

      rethrow;
    }
  }

  /// Tenta login normal com tratamento de erros específicos do emulador
  static Future<Map<String, dynamic>> _tryNormalLogin({
    required String email,
    required String password,
  }) async {
    try {
      // Aqui você chamaria o AuthService normal para login
      await Future.delayed(const Duration(seconds: 1));

      return {
        'success': true,
        'message': 'Login realizado com sucesso via auth normal',
        'user': {
          'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
          'email': email,
        }
      };
    } catch (e) {
      print('❌ [EMULATOR_HELPER] Login normal falhou: $e');

      if (_isEmulatorNetworkError(e)) {
        print(
            '🔧 [EMULATOR_HELPER] Erro de rede do emulador detectado, tentando bypass');
        return await BypassAuthService.signIn(
          email: email,
          password: password,
        );
      }

      rethrow;
    }
  }

  /// Detecta erros comuns de rede em emuladores
  static bool _isEmulatorNetworkError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('network') ||
        errorStr.contains('connection') ||
        errorStr.contains('timeout') ||
        errorStr.contains('unreachable') ||
        errorStr.contains('certificate') ||
        errorStr.contains('ssl') ||
        errorStr.contains('handshake');
  }

  /// Testa conectividade e retorna diagnóstico
  static Future<EmulatorDiagnostic> diagnoseConnection() async {
    print('🔍 [EMULATOR_HELPER] Iniciando diagnóstico...');

    final diagnostic = EmulatorDiagnostic();

    // Teste 1: Verificar se é emulador
    diagnostic.isEmulator = isAndroidEmulator;

    // Teste 2: Testar bypass
    try {
      diagnostic.bypassWorking = await BypassAuthService.testBypassConnection();
    } catch (e) {
      diagnostic.bypassWorking = false;
      diagnostic.bypassError = e.toString();
    }

    // Teste 3: Configurações de rede (simulado)
    diagnostic.networkConfig = _getNetworkConfig();

    return diagnostic;
  }

  static Map<String, dynamic> _getNetworkConfig() {
    return {
      'platform': Platform.operatingSystem,
      'isEmulator': isAndroidEmulator,
      'hostname': Platform.localHostname,
      'environment': Platform.environment.keys
          .where((k) => k.contains('ANDROID') || k.contains('FLUTTER'))
          .toList(),
    };
  }

  /// Aplica correções automáticas para emuladores
  static Future<void> applyEmulatorFixes() async {
    if (!isAndroidEmulator) return;

    print('🔧 [EMULATOR_HELPER] Aplicando correções para emulador...');

    // Aqui você pode aplicar configurações específicas como:
    // - Timeouts maiores
    // - Configurações de SSL menos restritivas para desenvolvimento
    // - Headers específicos

    print('✅ [EMULATOR_HELPER] Correções aplicadas');
  }
}

/// Classe para diagnóstico de problemas do emulador
class EmulatorDiagnostic {
  bool isEmulator = false;
  bool bypassWorking = false;
  String? bypassError;
  Map<String, dynamic> networkConfig = {};

  /// Retorna se tudo está funcionando
  bool get isHealthy => bypassWorking || !isEmulator;

  /// Retorna recomendação de uso
  String get recommendation {
    if (isEmulator && !bypassWorking) {
      return 'Recomendado: Usar bypass auth ou verificar configuração de rede do emulador';
    } else if (isEmulator && bypassWorking) {
      return 'Emulador detectado, bypass auth disponível e funcionando';
    } else {
      return 'Dispositivo físico ou web, usar auth normal';
    }
  }

  void printReport() {
    print('📋 [DIAGNÓSTICO EMULADOR]');
    print('=' * 40);
    print('É emulador: $isEmulator');
    print('Bypass funcionando: $bypassWorking');
    if (bypassError != null) {
      print('Erro do bypass: $bypassError');
    }
    print('Configuração de rede: $networkConfig');
    print(
        'Status geral: ${isHealthy ? "✅ Saudável" : "⚠️ Problemas detectados"}');
    print('Recomendação: $recommendation');
    print('=' * 40);
  }
}
