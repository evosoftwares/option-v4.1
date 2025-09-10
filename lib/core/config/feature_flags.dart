/// Sistema de Feature Flags para controlar rollout de novas funcionalidades
/// Permite ativar/desativar features sem rebuild da aplicação
class FeatureFlags {
  factory FeatureFlags() => _instance;
  FeatureFlags._internal();
  // Singleton pattern for global access
  static final FeatureFlags _instance = FeatureFlags._internal();

  // =============================================
  // FEATURE FLAGS PARA CORREÇÃO DE AUTH/CADASTRO
  // =============================================

  /// Ativa o novo fluxo de registro que cria app_users imediatamente
  /// SIMPLIFICADO: false - usa fluxo padrão (Register → UserType → Stepper)
  static const bool _enableDirectUserCreation = false;

  /// Ativa validação aprimorada de dados corrompidos  
  /// SIMPLIFICADO: false - usa apenas validação básica
  static const bool _enableEnhancedDataValidation = false;

  /// Ativa sincronização automática entre auth.users e app_users
  /// SIMPLIFICADO: false - não necessário para fluxo básico
  static const bool _enableAutoUserSync = false;

  /// Ativa correção automática de dados corrompidos no login
  /// SIMPLIFICADO: false - não necessário para fluxo básico
  static const bool _enableAutoDataRepair = false;

  /// Ativa logs detalhados para debugging da migração
  /// MANTIDO: true - útil para debugging
  static const bool _enableMigrationLogs = true;

  /// Ativa fallback para fluxo legado em caso de erro
  /// SIMPLIFICADO: false - fluxo único, sem fallback complexo
  static const bool _enableLegacyFallback = false;

  // =============================================
  // FEATURE FLAGS PARA SISTEMA DE MATCHING DIRECIONADO
  // =============================================

  /// Habilitar sistema de matching direcionado (vs sistema antigo "primeiro que aceita")
  /// Iniciar com false para rollout seguro
  static const bool _enableDirectedMatching = false;
  
  /// Habilitar sistema de fallback automático quando motorista não responde
  static const bool _enableFallbackSystem = true;
  
  /// Tempo limite em segundos para motorista responder a solicitação
  /// DEPRECATED: Use PlatformSettingsService.getDriverAcceptanceTimeoutSeconds() instead
  @Deprecated('Use PlatformSettingsService.getDriverAcceptanceTimeoutSeconds() for dynamic platform settings')
  static const int _timeoutSeconds = 10;
  
  /// Número máximo de motoristas de fallback por solicitação
  static const int _maxFallbackAttempts = 5;
  
  /// Habilitar logs detalhados do sistema de matching (apenas em debug)
  static const bool _enableMatchingLogs = true;
  
  /// Habilitar notificações push para motoristas
  static const bool _enablePushNotifications = true;
  
  /// Intervalo em segundos para polling quando push notifications falham
  static const int _fallbackPollingSeconds = 3;

  // =============================================
  // GETTERS PÚBLICOS
  // =============================================

  /// Novo fluxo de registro que cria app_users imediatamente
  bool get enableDirectUserCreation => _enableDirectUserCreation;

  /// Validação aprimorada de dados corrompidos
  bool get enableEnhancedDataValidation => _enableEnhancedDataValidation;

  /// Sincronização automática entre auth.users e app_users
  bool get enableAutoUserSync => _enableAutoUserSync;

  /// Correção automática de dados corrompidos
  bool get enableAutoDataRepair => _enableAutoDataRepair;

  /// Logs detalhados para debugging
  bool get enableMigrationLogs => _enableMigrationLogs;

  /// Fallback para fluxo legado
  bool get enableLegacyFallback => _enableLegacyFallback;

  /// Sistema de matching direcionado
  bool get enableDirectedMatching => _enableDirectedMatching;
  
  /// Sistema de fallback automático
  bool get enableFallbackSystem => _enableFallbackSystem;
  
  /// Tempo limite em segundos
  int get timeoutSeconds => _timeoutSeconds;
  
  /// Máximo de motoristas de fallback
  int get maxFallbackAttempts => _maxFallbackAttempts;
  
  /// Logs detalhados do matching
  bool get enableMatchingLogs => _enableMatchingLogs;
  
  /// Notificações push
  bool get enablePushNotifications => _enablePushNotifications;
  
  /// Intervalo de polling fallback
  int get fallbackPollingSeconds => _fallbackPollingSeconds;

  // =============================================
  // CONTROLE DINÂMICO (FUTURO)
  // =============================================

  /// Permite override dinâmico das flags para testing
  final Map<String, bool> _overrides = {};

  /// Override temporário de uma feature flag (apenas para testes)
  void setOverride(String flagName, bool value) {
    _overrides[flagName] = value;
    print('🏁 Feature flag override: $flagName = $value');
  }

  /// Remove override de uma feature flag
  void clearOverride(String flagName) {
    _overrides.remove(flagName);
    print('🏁 Feature flag override cleared: $flagName');
  }

  /// Limpa todos os overrides
  void clearAllOverrides() {
    _overrides.clear();
    print('🏁 All feature flag overrides cleared');
  }

  /// Obtém valor de uma flag com possível override
  bool _getFlagWithOverride(String flagName, bool defaultValue) => _overrides[flagName] ?? defaultValue;

  // =============================================
  // GETTERS COM OVERRIDE SUPPORT
  // =============================================

  /// Novo fluxo de registro (com override)
  bool get directUserCreation => _getFlagWithOverride(
    'enableDirectUserCreation', 
    _enableDirectUserCreation,
  );

  /// Validação aprimorada (com override)
  bool get enhancedDataValidation => _getFlagWithOverride(
    'enableEnhancedDataValidation', 
    _enableEnhancedDataValidation,
  );

  /// Auto sincronização (com override)
  bool get autoUserSync => _getFlagWithOverride(
    'enableAutoUserSync', 
    _enableAutoUserSync,
  );

  /// Auto reparo (com override)
  bool get autoDataRepair => _getFlagWithOverride(
    'enableAutoDataRepair', 
    _enableAutoDataRepair,
  );

  /// Logs de migração (com override)
  bool get migrationLogs => _getFlagWithOverride(
    'enableMigrationLogs', 
    _enableMigrationLogs,
  );

  /// Fallback legado (com override)
  bool get legacyFallback => _getFlagWithOverride(
    'enableLegacyFallback', 
    _enableLegacyFallback,
  );

  // =============================================
  // HELPERS PARA DESENVOLVIMENTO
  // =============================================

  /// Lista todas as flags e seus valores atuais
  Map<String, bool> getAllFlags() => {
      'enableDirectUserCreation': directUserCreation,
      'enableEnhancedDataValidation': enhancedDataValidation,
      'enableAutoUserSync': autoUserSync,
      'enableAutoDataRepair': autoDataRepair,
      'enableMigrationLogs': migrationLogs,
      'enableLegacyFallback': legacyFallback,
    };

  /// Imprime status atual de todas as flags
  void printStatus() {
    print('🏁 Feature Flags Status:');
    getAllFlags().forEach((key, value) {
      final override = _overrides[key];
      final status = value ? '✅ ON' : '❌ OFF';
      final overrideInfo = override != null ? ' (OVERRIDE)' : '';
      print('   $key: $status$overrideInfo');
    });
  }

  /// Configuração para TESTE - ativa tudo para validação
  void enableTestMode() {
    setOverride('enableDirectUserCreation', true);
    setOverride('enableEnhancedDataValidation', true);
    setOverride('enableAutoUserSync', true);
    setOverride('enableAutoDataRepair', true);
    setOverride('enableMigrationLogs', true);
    setOverride('enableLegacyFallback', true);
    print('🧪 Test mode activated - all flags enabled');
  }

  /// Configuração CONSERVADORA - apenas monitoramento
  void enableSafeMode() {
    setOverride('enableDirectUserCreation', false);
    setOverride('enableEnhancedDataValidation', true);
    setOverride('enableAutoUserSync', false);
    setOverride('enableAutoDataRepair', false);
    setOverride('enableMigrationLogs', true);
    setOverride('enableLegacyFallback', true);
    print('🛡️ Safe mode activated - only monitoring enabled');
  }

  /// Configuração de PRODUÇÃO FASE 1
  void enablePhase1() {
    clearAllOverrides(); // Usa valores padrão definidos nas constantes
    print('🚀 Phase 1 configuration - validation only');
  }
}

/// Helper global para acesso rápido às feature flags
final featureFlags = FeatureFlags();

/// Decorator para funções que dependem de feature flags
class FeatureGated {
  const FeatureGated(this.flagName);
  final String flagName;
}

/// Mixin para classes que usam feature flags
mixin FeatureFlagMixin {
  /// Acesso conveniente às feature flags
  FeatureFlags get flags => FeatureFlags();

  /// Executa código apenas se a flag estiver ativa
  T? ifFlagEnabled<T>(bool flag, T Function() callback) => flag ? callback() : null;

  /// Executa um callback ou outro baseado na flag
  T flagBasedExecution<T>(
    bool flag, 
    T Function() onEnabled, 
    T Function() onDisabled,
  ) => flag ? onEnabled() : onDisabled();

  /// Log condicional baseado na flag de migration logs
  void migrationLog(String message) {
    if (flags.migrationLogs) {
      print('🔄 [MIGRATION] $message');
    }
  }
}