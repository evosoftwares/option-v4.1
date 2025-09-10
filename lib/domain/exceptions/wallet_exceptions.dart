/// Exceções específicas para operações de carteira
/// Permite tratamento mais granular de erros
library;

/// Enum para tipos de erro de carteira
enum WalletErrorType {
  insufficientBalance('Saldo insuficiente'),
  invalidPixKey('Chave PIX inválida'),
  invalidAmount('Valor inválido'),
  walletNotFound('Carteira não encontrada'),
  networkError('Erro de conexão'),
  serverError('Erro interno do servidor'),
  rateLimitExceeded('Muitas tentativas. Tente novamente em alguns minutos'),
  withdrawalLimitExceeded('Limite de saque excedido'),
  pixKeyNotVerified('Chave PIX não verificada'),
  maintenanceMode('Sistema em manutenção'),
  suspiciousActivity('Atividade suspeita detectada'),
  unknownError('Erro desconhecido');

  const WalletErrorType(this.message);
  final String message;
}

/// Exceção base para operações de carteira
class WalletException implements Exception {
  const WalletException({
    required this.type,
    this.details,
    this.originalError,
  });

  final WalletErrorType type;
  final String? details;
  final dynamic originalError;

  String get message => details ?? type.message;

  @override
  String toString() {
    if (details != null) {
      return 'WalletException: ${type.message} - $details';
    }
    return 'WalletException: ${type.message}';
  }
}

/// Exceção específica para operações de saque
class WithdrawalException extends WalletException {
  const WithdrawalException({
    required super.type,
    super.details,
    super.originalError,
    this.amount,
    this.pixKey,
  });

  final double? amount;
  final String? pixKey;

  @override
  String toString() {
    final baseMessage = super.toString();
    if (amount != null && pixKey != null) {
      return '$baseMessage (Valor: R\$ ${amount!.toStringAsFixed(2)}, PIX: $pixKey)';
    }
    return baseMessage;
  }
}

/// Exceção específica para operações de PIX
class PixException extends WalletException {
  const PixException({
    required super.type,
    super.details,
    super.originalError,
    this.qrCode,
    this.pixCopyPaste,
  });

  final String? qrCode;
  final String? pixCopyPaste;
}

/// Utilitário para converter erros genéricos em WalletException
class WalletErrorHandler {
  /// Converte um erro genérico em WalletException
  static WalletException handleError(dynamic error) {
    if (error is WalletException) {
      return error;
    }

    final errorMessage = error.toString().toLowerCase();

    // Mapear erros comuns baseado na mensagem
    if (errorMessage.contains('saldo insuficiente') || 
        errorMessage.contains('insufficient balance')) {
      return WalletException(
        type: WalletErrorType.insufficientBalance,
        originalError: error,
      );
    }

    if (errorMessage.contains('chave pix') || 
        errorMessage.contains('pix key')) {
      return WalletException(
        type: WalletErrorType.invalidPixKey,
        originalError: error,
      );
    }

    if (errorMessage.contains('carteira não encontrada') || 
        errorMessage.contains('wallet not found')) {
      return WalletException(
        type: WalletErrorType.walletNotFound,
        originalError: error,
      );
    }

    if (errorMessage.contains('network') || 
        errorMessage.contains('connection') ||
        errorMessage.contains('timeout')) {
      return WalletException(
        type: WalletErrorType.networkError,
        originalError: error,
      );
    }

    if (errorMessage.contains('rate limit') || 
        errorMessage.contains('too many requests')) {
      return WalletException(
        type: WalletErrorType.rateLimitExceeded,
        originalError: error,
      );
    }

    if (errorMessage.contains('maintenance') || 
        errorMessage.contains('manutenção')) {
      return WalletException(
        type: WalletErrorType.maintenanceMode,
        originalError: error,
      );
    }

    // Erro genérico
    return WalletException(
      type: WalletErrorType.unknownError,
      details: error.toString(),
      originalError: error,
    );
  }

  /// Retorna uma mensagem amigável para o usuário
  static String getUserFriendlyMessage(WalletException exception) {
    switch (exception.type) {
      case WalletErrorType.insufficientBalance:
        return 'Você não possui saldo suficiente para esta operação.';
      case WalletErrorType.invalidPixKey:
        return 'A chave PIX informada é inválida. Verifique e tente novamente.';
      case WalletErrorType.invalidAmount:
        return 'O valor informado é inválido. Digite um valor maior que zero.';
      case WalletErrorType.walletNotFound:
        return 'Não foi possível encontrar sua carteira. Tente novamente.';
      case WalletErrorType.networkError:
        return 'Problema de conexão. Verifique sua internet e tente novamente.';
      case WalletErrorType.serverError:
        return 'Erro interno do sistema. Tente novamente em alguns minutos.';
      case WalletErrorType.rateLimitExceeded:
        return 'Muitas tentativas realizadas. Aguarde alguns minutos antes de tentar novamente.';
      case WalletErrorType.withdrawalLimitExceeded:
        return 'Limite de saque diário excedido. Tente novamente amanhã.';
      case WalletErrorType.pixKeyNotVerified:
        return 'Sua chave PIX precisa ser verificada antes de realizar saques.';
      case WalletErrorType.maintenanceMode:
        return 'Sistema temporariamente indisponível para manutenção. Tente novamente mais tarde.';
      case WalletErrorType.suspiciousActivity:
        return 'Atividade suspeita detectada. Por segurança, aguarde alguns minutos antes de tentar novamente.';
      case WalletErrorType.unknownError:
        return exception.details ?? 'Ocorreu um erro inesperado. Tente novamente.';
    }
  }

  /// Determina se o erro permite retry
  static bool canRetry(WalletException exception) {
    switch (exception.type) {
      case WalletErrorType.networkError:
      case WalletErrorType.serverError:
      case WalletErrorType.maintenanceMode:
      case WalletErrorType.unknownError:
        return true;
      case WalletErrorType.insufficientBalance:
      case WalletErrorType.invalidPixKey:
      case WalletErrorType.invalidAmount:
      case WalletErrorType.walletNotFound:
      case WalletErrorType.suspiciousActivity:
      case WalletErrorType.rateLimitExceeded:
      case WalletErrorType.withdrawalLimitExceeded:
      case WalletErrorType.pixKeyNotVerified:
        return false;
    }
  }
}