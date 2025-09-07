import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import 'android_emulator_dns_fix.dart';

/// Configuração simplificada do Supabase compatível com versão atual
class SupabaseEmulatorConfig {
  static bool _isInitialized = false;

  /// Inicializa o Supabase com configurações básicas
  static Future<void> initializeWithEmulatorSupport() async {
    if (_isInitialized) {
      print('✅ [SUPABASE] Já inicializado');
      return;
    }

    print('🚀 [SUPABASE] Iniciando configuração...');

    // Diagnóstico específico para emulador Android
    if (AndroidEmulatorDNSFix.isAndroidEmulator) {
      print(
          '🤖 [SUPABASE] Emulador Android detectado - executando diagnóstico...');

      final diagnostic = await AndroidEmulatorDNSFix.runFullDiagnostic(
        supabaseUrl: AppConfig.supabaseUrl,
      );

      if (!diagnostic.isHealthy) {
        print(
            '⚠️ [SUPABASE] Problemas de rede detectados (Score: ${diagnostic.healthScore}/100)');
        final recommendations = AndroidEmulatorDNSFix.getRecommendations(
          diagnostic,
          supabaseUrl: AppConfig.supabaseUrl,
        );

        print('💡 [SUPABASE] Recomendações:');
        for (final rec in recommendations) {
          print('   $rec');
        }

        if (diagnostic.healthScore < 50) {
          throw Exception(
              'Conectividade insuficiente para Supabase (Score: ${diagnostic.healthScore}/100)');
        }

        print('⚠️ [SUPABASE] Prosseguindo com conectividade parcial...');
      } else {
        print('✅ [SUPABASE] Diagnóstico de rede OK');
      }
    }

    try {
      // Inicialização básica do Supabase
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        debug: kDebugMode,
      );

      _isInitialized = true;
      print('✅ [SUPABASE] Inicializado com sucesso');

      // Configurar listener de auth
      _setupAuthListener();
    } catch (e) {
      print('❌ [SUPABASE] Falha na inicialização: $e');
      rethrow;
    }
  }

  /// Configura listener de autenticação
  static void _setupAuthListener() {
    try {
      final supabase = Supabase.instance.client;

      supabase.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        final event = data.event;

        if (kDebugMode) {
          print('🔐 [AUTH] Evento: $event');
          if (session != null) {
            print('🔐 [AUTH] Sessão ativa: ${session.user.email}');
          } else {
            print('🔐 [AUTH] Sem sessão ativa');
          }
        }
      });
    } catch (e) {
      print('⚠️ [AUTH] Erro ao configurar listener: $e');
    }
  }

  /// Registro com retry específico para emulador Android
  static Future<AuthResponse> signUpWithRetry({
    required String email,
    required String password,
    Map<String, dynamic>? data,
    String? emailRedirectTo,
  }) async {
    final maxAttempts = AndroidEmulatorDNSFix.isAndroidEmulator ? 5 : 3;
    Exception? lastException;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        if (kDebugMode) {
          print('🔄 [SIGNUP] Tentativa $attempt/$maxAttempts');
        }

        final response = await Supabase.instance.client.auth
            .signUp(
              email: email,
              password: password,
              data: data,
            )
            .timeout(
              AndroidEmulatorDNSFix.isAndroidEmulator
                  ? const Duration(seconds: 60)
                  : const Duration(seconds: 30),
              onTimeout: () => throw TimeoutException(
                'Timeout na criação de conta após ${AndroidEmulatorDNSFix.isAndroidEmulator ? 60 : 30}s',
                AndroidEmulatorDNSFix.isAndroidEmulator
                    ? const Duration(seconds: 60)
                    : const Duration(seconds: 30),
              ),
            );

        if (kDebugMode) {
          print('✅ [SIGNUP] Sucesso na tentativa $attempt');
        }
        return response;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        if (kDebugMode) {
          print('❌ [SIGNUP] Tentativa $attempt falhou: $e');
        }

        if (attempt < maxAttempts) {
          // Backoff exponencial para emulador Android
          final baseDelay = AndroidEmulatorDNSFix.isAndroidEmulator ? 3 : 2;
          final delay = Duration(seconds: attempt * baseDelay);
          if (kDebugMode) {
            print(
                '⏳ [SIGNUP] Aguardando ${delay.inSeconds}s antes da próxima tentativa...');
          }
          await Future.delayed(delay);
        }
      }
    }

    throw lastException ??
        Exception('Falha no registro após $maxAttempts tentativas');
  }

  /// Login com retry específico para emulador Android
  static Future<AuthResponse> signInWithRetry({
    required String email,
    required String password,
  }) async {
    final maxAttempts = AndroidEmulatorDNSFix.isAndroidEmulator ? 5 : 3;
    Exception? lastException;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        if (kDebugMode) {
          print('🔄 [SIGNIN] Tentativa $attempt/$maxAttempts');
        }

        final response = await Supabase.instance.client.auth
            .signInWithPassword(
              email: email,
              password: password,
            )
            .timeout(
              AndroidEmulatorDNSFix.isAndroidEmulator
                  ? const Duration(seconds: 60)
                  : const Duration(seconds: 30),
              onTimeout: () => throw TimeoutException(
                'Timeout no login após ${AndroidEmulatorDNSFix.isAndroidEmulator ? 60 : 30}s',
                AndroidEmulatorDNSFix.isAndroidEmulator
                    ? const Duration(seconds: 60)
                    : const Duration(seconds: 30),
              ),
            );

        if (kDebugMode) {
          print('✅ [SIGNIN] Sucesso na tentativa $attempt');
        }
        return response;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        if (kDebugMode) {
          print('❌ [SIGNIN] Tentativa $attempt falhou: $e');
        }

        // Não fazer retry em erros de credenciais
        if (e.toString().contains('Invalid login credentials') ||
            e.toString().contains('Email not confirmed')) {
          if (kDebugMode) {
            print('🚫 [SIGNIN] Erro de credenciais, não fazendo retry');
          }
          break;
        }

        if (attempt < maxAttempts) {
          // Backoff exponencial para emulador Android
          final baseDelay = AndroidEmulatorDNSFix.isAndroidEmulator ? 3 : 2;
          final delay = Duration(seconds: attempt * baseDelay);
          if (kDebugMode) {
            print(
                '⏳ [SIGNIN] Aguardando ${delay.inSeconds}s antes da próxima tentativa...');
          }
          await Future.delayed(delay);
        }
      }
    }

    throw lastException ??
        Exception('Falha no login após $maxAttempts tentativas');
  }

  /// Verifica se foi inicializado
  static bool get isInitialized => _isInitialized;

  /// Diagnóstico básico
  static Future<void> runDiagnostics() async {
    print('🔍 [DIAGNOSTICS] Iniciando diagnóstico...');
    print('=' * 50);

    // 1. Status da inicialização
    print('1️⃣ Inicialização: ${isInitialized ? "✅ OK" : "❌ Falha"}');

    // 2. Configuração
    final hasUrl = AppConfig.supabaseUrl.isNotEmpty;
    final hasKey = AppConfig.supabaseAnonKey.isNotEmpty;
    print('2️⃣ Configuração: ${hasUrl && hasKey ? "✅ OK" : "❌ Faltando"}');

    // 3. Diagnóstico de rede (se emulador Android)
    if (AndroidEmulatorDNSFix.isAndroidEmulator) {
      print('3️⃣ Testando rede do emulador...');
      final networkDiag = await AndroidEmulatorDNSFix.runFullDiagnostic(
        supabaseUrl: AppConfig.supabaseUrl,
      );
      print('   Score de rede: ${networkDiag.healthScore}/100');
    }

    // 4. Auth status
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      final hasSession = client.auth.currentSession != null;

      print('4️⃣ Usuário: ${user?.email ?? "Nenhum"}');
      print('5️⃣ Sessão: ${hasSession ? "✅ Ativa" : "❌ Inativa"}');
    } catch (e) {
      print('4️⃣ Auth: ❌ Erro - $e');
    }

    print('=' * 50);
    print('🏁 [DIAGNOSTICS] Concluído');
  }
}

/// Exception para timeout
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  const TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message';
}
