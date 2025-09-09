
/// Configuração centralizada da aplicação OPTION
///
/// Utiliza variáveis de ambiente quando disponíveis, com fallback para
/// valores de produção seguros. Para desenvolvimento, defina as variáveis
/// de ambiente ou crie um arquivo .env
class AppConfig {
  // ==========================================================================
  // CONFIGURAÇÕES DO SUPABASE
  // ==========================================================================

  /// URL do projeto Supabase
  /// Obtido em: https://app.supabase.com/project/SEU_PROJETO/settings/api
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qlbwacmavngtonauxnte.supabase.co',
  );

  /// Chave anônima do Supabase (pública, pode ser exposta no frontend)
  /// Obtida em: https://app.supabase.com/project/SEU_PROJETO/settings/api
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E',
  );

  // ==========================================================================
  // CONFIGURAÇÕES DO ASAAS (GATEWAY DE PAGAMENTO)
  // ==========================================================================

  /// URL base da API do Asaas
  /// Produção: https://api.asaas.com/v3
  /// Sandbox: https://sandbox.asaas.com/v3
  static const String asaasBaseUrl = String.fromEnvironment(
    'ASAAS_BASE_URL',
    defaultValue: 'https://api.asaas.com/v3',
  );

  /// Chave da API do Asaas (SENSÍVEL - não deve ser exposta)
  /// Obtida em: https://www.asaas.com/api ou https://sandbox.asaas.com/api
  static const String asaasApiKey = String.fromEnvironment(
    'ASAAS_API_KEY',
    defaultValue:
        'aact_prod_000MzkwODA2MWY2OGM3MWRlMDU2NWM3MzJlNzZmNGZhZGY6Ojg1OTI0YjdiLTk1ODEtNDc0ZS04N2YzLTY0ZDk2MGM4ZDI3Yjo6JGFhY2hfNDhlN2M3OTAtOGY4NC00ZDE2LTk0NWQtNjAwMTU4ODhkMTM3',
  );

  // ==========================================================================
  // CONFIGURAÇÕES DO GOOGLE MAPS
  // ==========================================================================

  /// Chave da API do Google Maps (SENSÍVEL - restringir por domínio/IP)
  /// Obtida em: https://console.cloud.google.com/apis/credentials
  /// APIs necessárias: Maps SDK for Android/iOS, Places API, Geocoding API
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyB1WJiIpqAhWt0P_ZqlkbleZ5hUmqTQHBc',
  );

  // ==========================================================================
  // CONFIGURAÇÕES DE DESENVOLVIMENTO
  // ==========================================================================

  /// Indica se está em ambiente de desenvolvimento
  static bool get isDevelopment =>
      const bool.fromEnvironment('FLUTTER_ENV') == 'development' ||
      const String.fromEnvironment('FLUTTER_ENV') == 'development';

  /// Indica se está em ambiente de produção
  static bool get isProduction => !isDevelopment;

  /// Habilita logs detalhados em desenvolvimento
  static bool get enableVerboseLogs => isDevelopment;

  // ==========================================================================
  // MÉTODOS DE VALIDAÇÃO
  // ==========================================================================

  /// Valida se todas as configurações obrigatórias estão presentes
  static ConfigValidationResult validateConfiguration() {
    final issues = <String>[];
    final warnings = <String>[];

    // Validar Supabase URL
    if (supabaseUrl.isEmpty) {
      issues.add('SUPABASE_URL está vazia');
    } else if (!supabaseUrl.startsWith('https://')) {
      issues.add('SUPABASE_URL deve começar com https://');
    } else if (!supabaseUrl.contains('.supabase.co')) {
      warnings.add('SUPABASE_URL não parece ser um domínio Supabase válido');
    }

    // Validar Supabase Key
    if (supabaseAnonKey.isEmpty) {
      issues.add('SUPABASE_ANON_KEY está vazia');
    } else if (supabaseAnonKey.length < 100) {
      warnings
          .add('SUPABASE_ANON_KEY parece muito curta para ser um JWT válido');
    }

    // Validar Google Maps
    if (googleMapsApiKey.isEmpty) {
      warnings.add(
          'GOOGLE_MAPS_API_KEY está vazia - funcionalidades de mapa não funcionarão');
    } else if (googleMapsApiKey.startsWith('YOUR_') ||
        googleMapsApiKey.contains('PLACEHOLDER')) {
      warnings.add('GOOGLE_MAPS_API_KEY parece ser um placeholder');
    }

    // Validar Asaas
    if (asaasApiKey.isEmpty) {
      warnings.add(
          'ASAAS_API_KEY está vazia - funcionalidades de pagamento não funcionarão');
    }

    return ConfigValidationResult(
      isValid: issues.isEmpty,
      criticalIssues: issues,
      warnings: warnings,
    );
  }

  /// Imprime informações de configuração (sem expor dados sensíveis)
  static void printConfigurationInfo() {
    print('🔧 CONFIGURAÇÃO DA APLICAÇÃO');
    print('=' * 40);
    print('Ambiente: ${isDevelopment ? "Desenvolvimento" : "Produção"}');
    print(
        'Supabase URL: ${supabaseUrl.isNotEmpty ? "✅ Configurada" : "❌ Vazia"}');
    print(
        'Supabase Key: ${supabaseAnonKey.isNotEmpty ? "✅ Configurada" : "❌ Vazia"}');
    print(
        'Google Maps: ${googleMapsApiKey.isNotEmpty ? "✅ Configurada" : "❌ Vazia"}');
    print('Asaas API: ${asaasApiKey.isNotEmpty ? "✅ Configurada" : "❌ Vazia"}');

    if (enableVerboseLogs) {
      print('');
      print('📋 DETALHES (DEV MODE):');
      print('Supabase URL: $supabaseUrl');
      print('Supabase Key: ${supabaseAnonKey.substring(0, 20)}...');
      print('Google Maps: ${googleMapsApiKey.substring(0, 20)}...');
      print('Asaas URL: $asaasBaseUrl');
    }
  }

  /// Extrai informações do projeto Supabase da URL
  static SupabaseProjectInfo getSupabaseProjectInfo() {
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null) {
      throw ArgumentError('URL do Supabase inválida: $supabaseUrl');
    }

    final hostParts = uri.host.split('.');
    if (hostParts.length < 3 || !uri.host.endsWith('.supabase.co')) {
      throw ArgumentError(
          'URL do Supabase não tem o formato esperado: $supabaseUrl');
    }

    return SupabaseProjectInfo(
      projectId: hostParts.first,
      fullUrl: supabaseUrl,
      host: uri.host,
    );
  }

  // ==========================================================================
  // CONFIGURAÇÕES ESPECÍFICAS POR AMBIENTE
  // ==========================================================================

  /// Timeout para requisições HTTP (em segundos)
  static int get httpTimeoutSeconds => isDevelopment ? 30 : 15;

  /// Intervalo de retry para falhas de rede (em milissegundos)
  static int get networkRetryDelayMs => isDevelopment ? 2000 : 1000;

  /// Número máximo de tentativas para requisições que falharam
  static int get maxNetworkRetries => isDevelopment ? 5 : 3;
}

/// Resultado da validação de configuração
class ConfigValidationResult {
  final bool isValid;
  final List<String> criticalIssues;
  final List<String> warnings;

  const ConfigValidationResult({
    required this.isValid,
    required this.criticalIssues,
    required this.warnings,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasCriticalIssues => criticalIssues.isNotEmpty;

  void printReport() {
    if (isValid && !hasWarnings) {
      print('✅ Configuração válida');
      return;
    }

    print('📋 RELATÓRIO DE CONFIGURAÇÃO:');
    print('');

    if (hasCriticalIssues) {
      print('❌ PROBLEMAS CRÍTICOS:');
      for (final issue in criticalIssues) {
        print('   • $issue');
      }
      print('');
    }

    if (hasWarnings) {
      print('⚠️ AVISOS:');
      for (final warning in warnings) {
        print('   • $warning');
      }
      print('');
    }

    if (hasCriticalIssues) {
      print('🛠️ PARA CORRIGIR:');
      print('   1. Verifique o arquivo .env na raiz do projeto');
      print('   2. Configure as variáveis de ambiente no seu sistema');
      print('   3. Para produção, configure no seu provedor de deploy');
      print('   4. Execute: dart test_supabase_connectivity.dart');
    }
  }
}

/// Informações extraídas do projeto Supabase
class SupabaseProjectInfo {
  final String projectId;
  final String fullUrl;
  final String host;

  const SupabaseProjectInfo({
    required this.projectId,
    required this.fullUrl,
    required this.host,
  });

  @override
  String toString() => 'SupabaseProject(id: $projectId, host: $host)';
}
