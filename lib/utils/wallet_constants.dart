/// Constantes para operações de carteira
/// Centraliza valores mágicos e configurações importantes
library;

class WalletConstants {
  // Valores monetários
  static const double minWithdrawalAmount = 1;
  static const double defaultBalance = 0;
  
  // Formatação de valores
  static const int decimalPlaces = 2;
  static const String currencySymbol = r'R$';
  static const String defaultAmountHint = '0,00';
  
  // Timeouts e durações
  static const Duration snackBarDuration = Duration(seconds: 5);
  static const Duration qrCodeDisplayDuration = Duration(seconds: 2);
  static const Duration withdrawalProcessingTime = Duration(hours: 2);
  
  // Dimensões de UI
  static const double qrCodeSize = 200;
  static const double buttonMinHeight = 48;
  static const double iconSize = 48;
  static const double smallIconSize = 16;
  static const double progressIndicatorSize = 20;
  static const double progressIndicatorStroke = 2;
  
  // Bordas e espaçamentos
  static const double borderWidth = 1;
  static const double selectedBorderWidth = 2;
  static const double borderRadius = 8;
  static const double containerPadding = 12;
  static const double smallSpacing = 4;
  static const double mediumSpacing = 8;
  static const double largeSpacing = 16;
  
  // Opacidades
  static const double backgroundOpacity = 0.1;
  static const double disabledOpacity = 0.5;
  static const double shimmerOpacity = 0.3;
  static const double lightShimmerOpacity = 0.2;
  
  // Limites de texto
  static const int maxDescriptionLines = 3;
  static const int singleLine = 1;
  static const int shimmerItemCount = 3;
  
  // Mensagens padrão
  static const String withdrawalSuccessMessage = 'Saque solicitado com sucesso!\nProcessamento em até 2 horas úteis.';
  static const String processingTimeInfo = '• O processamento pode levar até 2 horas úteis';
  static const String balancePrefix = 'Saldo disponível: ';
  
  // Formatação de tempo
  static const String timeFormat = 'HH:mm';
  static const String todayPrefix = 'Hoje ';
  static const String yesterdayPrefix = 'Ontem ';
  static const int timePadLength = 2;
  static const String timePadChar = '0';
  
  // Configurações PIX
  static const String pixKeyHint = 'Digite sua chave PIX';
  static const String pixKeyLabel = 'Chave PIX';
  
  // Configurações de segurança
  static const int maxWithdrawalAttemptsPerHour = 3;
  static const int maxWithdrawalAttemptsPerDay = 10;
  static const Duration withdrawalCooldownPeriod = Duration(minutes: 15);
  
  // Configurações de auditoria
  static const String auditLogTable = 'audit_logs';
  static const String withdrawalAttemptTable = 'withdrawal_attempts';
  
  // Valores padrão para cálculos
  static const double zeroBalance = 0;
  static const double minimumPositiveAmount = 0;
  static const int yesterdayOffset = 1;
  
  // Configurações de QR Code
  static const String qrCodeDataSeparator = ',';
  static const int qrCodeDataIndex = 1;
  
  // Espaçamentos específicos
  static const double verticalSpacing2 = 2;
  static const double verticalSpacing4 = 4;
  static const double verticalSpacing8 = 8;
  static const double verticalSpacing16 = 16;
  
  // Configurações de shimmer
  static const int shimmerListCount = 3;
  static const double shimmerContainerWidth = 120;
  static const double shimmerContainerHeight = 16;
  static const double shimmerLargeHeight = 32;
  static const double shimmerMediumHeight = 60;
  static const double shimmerSmallHeight = 12;
  static const double shimmerIconSize = 40;
  static const double shimmerSmallWidth = 80;
  static const double shimmerMediumWidth = 100;
  static const double shimmerLargeWidth = 200;
  static const double shimmerButtonHeight = 48;
  
  // Opacidades específicas
  static const double borderOpacity = 0.3;
  static const double shimmerLightOpacity = 0.2;
  static const double shimmerMediumOpacity = 0.3;
  
  // Cores de referência (índices)
  static const int greyColorIndex = 300;
  
  // === CACHE E PERFORMANCE ===
  
  /// Duração de expiração do cache de transações
  static const Duration cacheExpiration = Duration(minutes: 10);
  
  /// Intervalo de limpeza automática do cache
  static const Duration cacheCleanupInterval = Duration(minutes: 5);
  
  /// Número máximo de entradas no cache
  static const int maxCacheEntries = 100;
  
  /// Tamanho da página para paginação de transações
  static const int transactionPageSize = 20;
  
  /// Número de páginas para pré-carregamento
  static const int preloadPages = 2;
}