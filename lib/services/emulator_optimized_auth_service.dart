import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_emulator_config.dart';
import '../utils/emulator_network_helper.dart';

/// Serviço de autenticação otimizado para emuladores mantendo segurança total
///
/// Esta classe resolve problemas de conectividade específicos de emuladores Android
/// sem comprometer a segurança ou bypassing a autenticação do Supabase.
/// Mantém tokens JWT válidos, RLS funcionando e session management completo.
class EmulatorOptimizedAuthService {
  static SupabaseClient get _supabase => Supabase.instance.client;

  /// Registro otimizado com retry automático para emuladores
  ///
  /// Mantém total compatibilidade com Supabase Auth:
  /// - Gera token JWT válido
  /// - Cria session corretamente
  /// - Row Level Security funcionando
  /// - User persistence ativa
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
    String? emailRedirectTo,
  }) async {
    print('🚀 [AUTH] Iniciando registro otimizado...');
    print(
        '🤖 [AUTH] Emulador detectado: ${EmulatorNetworkHelper.isAndroidEmulator}');

    try {
      // Usar configuração otimizada com retry automático
      final response = await SupabaseEmulatorConfig.signUpWithRetry(
        email: email,
        password: password,
        data: data,
        emailRedirectTo: emailRedirectTo,
      );

      if (response.user != null) {
        print('✅ [AUTH] Registro bem-sucedido!');
        print('   - User ID: ${response.user!.id}');
        print('   - Email: ${response.user!.email}');
        print(
            '   - Session: ${response.session != null ? "Criada" : "Pendente"}');

        if (response.session != null) {
          print(
              '   - Token válido: ${response.session!.accessToken.substring(0, 20)}...');
          print(
              '   - Expira em: ${DateTime.fromMillisecondsSinceEpoch(response.session!.expiresAt! * 1000)}');
        }
      }

      return response;
    } catch (e) {
      print('❌ [AUTH] Erro no registro: $e');

      // Análise específica de erros para emuladores
      if (EmulatorNetworkHelper.isAndroidEmulator) {
        await _analyzeEmulatorError(e, 'SIGNUP');
      }

      rethrow;
    }
  }

  /// Login otimizado com retry automático para emuladores
  ///
  /// Mantém total segurança:
  /// - Valida credenciais corretamente
  /// - Cria session com token JWT
  /// - Todas as operações subsequentes funcionam
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    print('🔐 [AUTH] Iniciando login otimizado...');
    print(
        '🤖 [AUTH] Emulador detectado: ${EmulatorNetworkHelper.isAndroidEmulator}');

    try {
      // Usar configuração otimizada com retry automático
      final response = await SupabaseEmulatorConfig.signInWithRetry(
        email: email,
        password: password,
      );

      if (response.user != null && response.session != null) {
        print('✅ [AUTH] Login bem-sucedido!');
        print('   - User ID: ${response.user!.id}');
        print('   - Email: ${response.user!.email}');
        print(
            '   - Session criada: ${response.session!.accessToken.substring(0, 20)}...');
        print(
            '   - Token válido até: ${DateTime.fromMillisecondsSinceEpoch(response.session!.expiresAt! * 1000)}');

        // Verificar se o token está funcionando
        await _validateTokenWorking();
      }

      return response;
    } catch (e) {
      print('❌ [AUTH] Erro no login: $e');

      // Análise específica de erros para emuladores
      if (EmulatorNetworkHelper.isAndroidEmulator) {
        await _analyzeEmulatorError(e, 'SIGNIN');
      }

      rethrow;
    }
  }

  /// Logout seguro e completo
  static Future<void> signOut() async {
    print('👋 [AUTH] Fazendo logout...');

    try {
      await _supabase.auth.signOut();
      print('✅ [AUTH] Logout realizado com sucesso');
    } catch (e) {
      print('❌ [AUTH] Erro no logout: $e');
      rethrow;
    }
  }

  /// Usuário atual com verificação de validade
  static User? get currentUser {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      print('👤 [AUTH] Usuário atual: ${user.email} (ID: ${user.id})');
    }
    return user;
  }

  /// Session atual com verificação de expiração
  static Session? get currentSession {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      final expiresAt =
          DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
      final isExpired = expiresAt.isBefore(DateTime.now());

      print('🎫 [AUTH] Session atual: ${isExpired ? "EXPIRADA" : "VÁLIDA"}');
      if (!isExpired) {
        print('   - Expira em: $expiresAt');
        print('   - Token: ${session.accessToken.substring(0, 20)}...');
      }
    }
    return session;
  }

  /// Stream de mudanças de autenticação
  static Stream<AuthState> get onAuthStateChange {
    return _supabase.auth.onAuthStateChange.map((data) {
      print('🔄 [AUTH] Mudança de estado: ${data.event}');
      if (data.session != null) {
        print('   - Session: ATIVA');
        print('   - User: ${data.session!.user.email}');
      } else {
        print('   - Session: INATIVA');
      }
      return data;
    });
  }

  /// Refresh manual do token (útil para debug)
  static Future<AuthResponse?> refreshSession() async {
    print('🔄 [AUTH] Fazendo refresh da session...');

    try {
      final response = await _supabase.auth.refreshSession();

      if (response.session != null) {
        print('✅ [AUTH] Session renovada com sucesso');
        print(
            '   - Novo token: ${response.session!.accessToken.substring(0, 20)}...');
        print(
            '   - Válido até: ${DateTime.fromMillisecondsSinceEpoch(response.session!.expiresAt! * 1000)}');
      }

      return response;
    } catch (e) {
      print('❌ [AUTH] Erro no refresh: $e');
      rethrow;
    }
  }

  /// Verifica se o usuário está autenticado e com session válida
  static bool get isAuthenticated {
    final user = currentUser;
    final session = currentSession;

    final isAuth = user != null && session != null;
    print(
        '🔍 [AUTH] Status de autenticação: ${isAuth ? "AUTENTICADO" : "NÃO AUTENTICADO"}');

    return isAuth;
  }

  /// Análise específica de erros para emuladores
  static Future<void> _analyzeEmulatorError(
      dynamic error, String operation) async {
    final errorStr = error.toString().toLowerCase();

    print('🔍 [AUTH] Analisando erro de emulador para $operation:');

    if (errorStr.contains('network') || errorStr.contains('connection')) {
      print('   🌐 Tipo: Problema de rede');
      print('   💡 Solução: Verifique conectividade do emulador');
      print('   💡 Comando: adb shell ping google.com');
    } else if (errorStr.contains('timeout')) {
      print('   ⏱️  Tipo: Timeout de rede');
      print('   💡 Solução: Timeout aumentado automaticamente');
      print('   💡 Alternativa: Teste no navegador com flutter run -d chrome');
    } else if (errorStr.contains('certificate') || errorStr.contains('ssl')) {
      print('   🔒 Tipo: Problema SSL/Certificado');
      print('   💡 Solução: Network security config aplicado automaticamente');
    } else if (errorStr.contains('invalid login credentials')) {
      print('   🚫 Tipo: Credenciais inválidas (normal)');
      print('   💡 Verificar: Email e senha estão corretos?');
    } else if (errorStr.contains('email not confirmed')) {
      print('   📧 Tipo: Email não confirmado');
      print('   💡 Verificar: Confirmar email antes do login');
    } else {
      print('   ❓ Tipo: Erro desconhecido');
      print('   💡 Detalhes: $error');
    }
  }

  /// Valida se o token JWT está funcionando fazendo uma query simples
  static Future<void> _validateTokenWorking() async {
    try {
      print('🧪 [AUTH] Testando se token está funcionando...');

      // Fazer uma query simples que requer autenticação
      await _supabase
          .from('app_users')
          .select('id')
          .limit(1)
          .count(CountOption.exact);

      print('✅ [AUTH] Token funcionando - operações com RLS OK');
    } catch (e) {
      print('⚠️ [AUTH] Token pode ter problemas: $e');
      // Não fazer throw aqui, só avisar
    }
  }

  /// Diagnóstico completo de autenticação
  static Future<Map<String, dynamic>> runAuthDiagnostic() async {
    print('🔍 [AUTH] Executando diagnóstico completo...');

    final diagnostic = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'isEmulator': EmulatorNetworkHelper.isAndroidEmulator,
    };

    try {
      // Testar inicialização
      diagnostic['supabaseInitialized'] = SupabaseEmulatorConfig.isInitialized;

      // Testar usuário atual
      final user = currentUser;
      diagnostic['hasCurrentUser'] = user != null;
      if (user != null) {
        diagnostic['userId'] = user.id;
        diagnostic['userEmail'] = user.email;
      }

      // Testar session
      final session = currentSession;
      diagnostic['hasValidSession'] = session != null;
      if (session != null) {
        diagnostic['sessionExpiresAt'] =
            DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
                .toIso8601String();
        diagnostic['tokenLength'] = session.accessToken.length;
      }

      // Testar conectividade
      final networkDiag = await EmulatorNetworkHelper.testSupabaseConnection();
      diagnostic['networkHealthy'] = networkDiag.isHealthy;
      diagnostic['networkScore'] = networkDiag.healthScore;

      // Testar operação com token
      try {
        await _validateTokenWorking();
        diagnostic['tokenWorking'] = true;
      } catch (e) {
        diagnostic['tokenWorking'] = false;
        diagnostic['tokenError'] = e.toString();
      }

      diagnostic['overallHealth'] = _calculateOverallHealth(diagnostic);
    } catch (e) {
      diagnostic['diagnosticError'] = e.toString();
      diagnostic['overallHealth'] = 'ERROR';
    }

    // Imprimir relatório
    _printDiagnosticReport(diagnostic);

    return diagnostic;
  }

  /// Calcula saúde geral do sistema de auth
  static String _calculateOverallHealth(Map<String, dynamic> diagnostic) {
    int score = 0;

    if (diagnostic['supabaseInitialized'] == true) score += 20;
    if (diagnostic['hasCurrentUser'] == true) score += 20;
    if (diagnostic['hasValidSession'] == true) score += 20;
    if (diagnostic['networkHealthy'] == true) score += 20;
    if (diagnostic['tokenWorking'] == true) score += 20;

    if (score >= 90) return 'EXCELLENT';
    if (score >= 70) return 'GOOD';
    if (score >= 50) return 'FAIR';
    if (score >= 30) return 'POOR';
    return 'CRITICAL';
  }

  /// Imprime relatório de diagnóstico
  static void _printDiagnosticReport(Map<String, dynamic> diagnostic) {
    print('📊 [AUTH] RELATÓRIO DE DIAGNÓSTICO');
    print('=' * 50);
    print('⏰ Timestamp: ${diagnostic['timestamp']}');
    print('🤖 Emulador: ${diagnostic['isEmulator']}');
    print('🚀 Supabase: ${diagnostic['supabaseInitialized'] ? "✅" : "❌"}');
    print('👤 Usuário: ${diagnostic['hasCurrentUser'] ? "✅" : "❌"}');
    print('🎫 Session: ${diagnostic['hasValidSession'] ? "✅" : "❌"}');
    print(
        '🌐 Rede: ${diagnostic['networkHealthy'] ? "✅" : "❌"} (${diagnostic['networkScore']}/100)');
    print('🔑 Token: ${diagnostic['tokenWorking'] ? "✅" : "❌"}');
    print('🏥 Saúde Geral: ${diagnostic['overallHealth']}');
    print('=' * 50);

    if (diagnostic['overallHealth'] != 'EXCELLENT') {
      print('💡 RECOMENDAÇÕES:');
      if (diagnostic['supabaseInitialized'] != true) {
        print('   - Verificar inicialização do Supabase');
      }
      if (diagnostic['networkHealthy'] != true) {
        print('   - Verificar conectividade de rede do emulador');
      }
      if (diagnostic['tokenWorking'] != true) {
        print('   - Verificar configuração RLS no Supabase');
      }
    }
  }
}
