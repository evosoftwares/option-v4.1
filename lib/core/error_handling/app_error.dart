/// Sistema de tratamento de erros consistente para toda a aplicação
/// Baseado nos requisitos de negócio e integração com Supabase

import 'package:flutter/foundation.dart';

/// Tipos de erro da aplicação
enum AppErrorType {
  // Erros de autenticação
  authenticationFailed,
  authorizationDenied,
  sessionExpired,
  
  // Erros de rede
  networkUnavailable,
  connectionTimeout,
  serverError,
  
  // Erros de validação
  validationFailed,
  invalidInput,
  missingRequiredField,
  
  // Erros de negócio
  tripNotFound,
  driverNotAvailable,
  passengerNotFound,
  invalidTripStatus,
  paymentFailed,
  
  // Erros de localização
  locationPermissionDenied,
  locationServiceDisabled,
  addressNotFound,
  
  // Erros do sistema
  databaseError,
  configurationError,
  unknownError,
}

/// Severidade do erro para logging e monitoramento
enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

/// Classe base para todos os erros da aplicação
class AppError implements Exception {
  final AppErrorType type;
  final String message;
  final String? userMessage;
  final String? technicalDetails;
  final ErrorSeverity severity;
  final Map<String, dynamic>? context;
  final DateTime timestamp;
  final StackTrace? stackTrace;

  AppError({
    required this.type,
    required this.message,
    this.userMessage,
    this.technicalDetails,
    this.severity = ErrorSeverity.medium,
    this.context,
    StackTrace? stackTrace,
  }) : timestamp = DateTime.now(),
       stackTrace = stackTrace ?? StackTrace.current;

  /// Mensagem amigável para o usuário
  String get displayMessage {
    if (userMessage != null && userMessage!.isNotEmpty) {
      return userMessage!;
    }
    
    // Mensagens padrão baseadas no tipo de erro
    switch (type) {
      case AppErrorType.authenticationFailed:
        return 'Falha na autenticação. Verifique suas credenciais.';
      case AppErrorType.authorizationDenied:
        return 'Você não tem permissão para realizar esta ação.';
      case AppErrorType.sessionExpired:
        return 'Sua sessão expirou. Faça login novamente.';
      case AppErrorType.networkUnavailable:
        return 'Sem conexão com a internet. Verifique sua conexão.';
      case AppErrorType.connectionTimeout:
        return 'Tempo limite de conexão. Tente novamente.';
      case AppErrorType.serverError:
        return 'Erro no servidor. Tente novamente em alguns minutos.';
      case AppErrorType.validationFailed:
        return 'Dados inválidos. Verifique as informações inseridas.';
      case AppErrorType.invalidInput:
        return 'Informação inválida. Verifique os dados inseridos.';
      case AppErrorType.missingRequiredField:
        return 'Campos obrigatórios não preenchidos.';
      case AppErrorType.tripNotFound:
        return 'Viagem não encontrada.';
      case AppErrorType.driverNotAvailable:
        return 'Nenhum motorista disponível no momento.';
      case AppErrorType.passengerNotFound:
        return 'Passageiro não encontrado.';
      case AppErrorType.invalidTripStatus:
        return 'Status da viagem inválido para esta operação.';
      case AppErrorType.paymentFailed:
        return 'Falha no pagamento. Verifique seus dados de pagamento.';
      case AppErrorType.locationPermissionDenied:
        return 'Permissão de localização negada. Habilite nas configurações.';
      case AppErrorType.locationServiceDisabled:
        return 'Serviço de localização desabilitado. Habilite nas configurações.';
      case AppErrorType.addressNotFound:
        return 'Endereço não encontrado. Verifique o endereço inserido.';
      case AppErrorType.databaseError:
        return 'Erro interno. Tente novamente.';
      case AppErrorType.configurationError:
        return 'Erro de configuração. Entre em contato com o suporte.';
      case AppErrorType.unknownError:
        return 'Erro inesperado. Tente novamente.';
    }
  }

  /// Converte o erro para um mapa para logging
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'message': message,
      'userMessage': userMessage,
      'technicalDetails': technicalDetails,
      'severity': severity.name,
      'context': context,
      'timestamp': timestamp.toIso8601String(),
      'stackTrace': stackTrace?.toString(),
    };
  }

  /// Cria um AppError a partir de uma exceção genérica
  factory AppError.fromException(Exception exception, {
    AppErrorType? type,
    String? userMessage,
    Map<String, dynamic>? context,
    ErrorSeverity severity = ErrorSeverity.medium,
  }) {
    final errorMessage = exception.toString();
    
    // Detectar tipo de erro baseado na mensagem
    AppErrorType detectedType = type ?? _detectErrorType(errorMessage);
    
    return AppError(
      type: detectedType,
      message: errorMessage,
      userMessage: userMessage,
      technicalDetails: errorMessage,
      severity: severity,
      context: context,
      stackTrace: StackTrace.current,
    );
  }

  /// Detecta o tipo de erro baseado na mensagem
  static AppErrorType _detectErrorType(String errorMessage) {
    final lowerMessage = errorMessage.toLowerCase();
    
    if (lowerMessage.contains('permission denied') || 
        lowerMessage.contains('unauthorized')) {
      return AppErrorType.authorizationDenied;
    }
    
    if (lowerMessage.contains('network') || 
        lowerMessage.contains('connection')) {
      return AppErrorType.networkUnavailable;
    }
    
    if (lowerMessage.contains('timeout')) {
      return AppErrorType.connectionTimeout;
    }
    
    if (lowerMessage.contains('validation') || 
        lowerMessage.contains('invalid')) {
      return AppErrorType.validationFailed;
    }
    
    if (lowerMessage.contains('database') || 
        lowerMessage.contains('sql')) {
      return AppErrorType.databaseError;
    }
    
    return AppErrorType.unknownError;
  }

  @override
  String toString() {
    if (kDebugMode) {
      return 'AppError(type: $type, message: $message, severity: $severity, context: $context)';
    }
    return displayMessage;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppError &&
        other.type == type &&
        other.message == message &&
        other.severity == severity;
  }

  @override
  int get hashCode {
    return type.hashCode ^ message.hashCode ^ severity.hashCode;
  }
}