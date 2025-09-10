/// Exceções específicas para o processo de registro de usuário
library;

import 'app_exceptions.dart';

/// Tipos de exceções de registro de usuário
enum UserRegistrationExceptionType {
  emailAlreadyExists,
  phoneAlreadyExists,
  requiredFields,
  photoUpload,
  networkError,
  serverError,
  validationError,
  authenticationError,
  rateLimitError,
  permissionError,
}

/// Classe base para exceções de registro de usuário
class UserRegistrationException extends AppException {
  
  UserRegistrationException(
    super.message,
    String super.code,
    this.type,
  );
  final UserRegistrationExceptionType type;

  @override
  String toString() => 'UserRegistrationException: $message (Code: $code, Type: $type)';
}

/// Exceção para email já existente
class EmailAlreadyExistsException extends UserRegistrationException {
  EmailAlreadyExistsException(String email)
      : super(
          'O email $email já está em uso',
          'EMAIL_ALREADY_EXISTS',
          UserRegistrationExceptionType.emailAlreadyExists,
        );
}

/// Exceção para telefone já existente
class PhoneAlreadyExistsException extends UserRegistrationException {
  PhoneAlreadyExistsException(String phone)
      : super(
          'O telefone $phone já está em uso',
          'PHONE_ALREADY_EXISTS',
          UserRegistrationExceptionType.phoneAlreadyExists,
        );
}

/// Exceção para campos obrigatórios
class RequiredFieldsException extends UserRegistrationException {
  RequiredFieldsException(String message)
      : super(
          message,
          'REQUIRED_FIELDS',
          UserRegistrationExceptionType.requiredFields,
        );
}

/// Exceção para upload de foto
class PhotoUploadException extends UserRegistrationException {
  PhotoUploadException(String message)
      : super(
          message,
          'PHOTO_UPLOAD_ERROR',
          UserRegistrationExceptionType.photoUpload,
        );
}

/// Exceção para problemas de rede
class RegistrationNetworkException extends UserRegistrationException {
  RegistrationNetworkException(String message)
      : super(
          message,
          'NETWORK_ERROR',
          UserRegistrationExceptionType.networkError,
        );
}

/// Exceção para erros do servidor
class RegistrationServerException extends UserRegistrationException {
  RegistrationServerException(String message)
      : super(
          message,
          'SERVER_ERROR',
          UserRegistrationExceptionType.serverError,
        );
}

/// Exceção para erros de validação
class ValidationException extends UserRegistrationException {
  ValidationException(String message)
      : super(
          message,
          'VALIDATION_ERROR',
          UserRegistrationExceptionType.validationError,
        );
}

/// Exceção para erros de autenticação
class AuthenticationException extends UserRegistrationException {
  AuthenticationException(String message)
      : super(
          message,
          'AUTHENTICATION_ERROR',
          UserRegistrationExceptionType.authenticationError,
        );
}

/// Exceção para limite de taxa
class RateLimitException extends UserRegistrationException {
  RateLimitException(String message)
      : super(
          message,
          'RATE_LIMIT_ERROR',
          UserRegistrationExceptionType.rateLimitError,
        );
}

/// Exceção para problemas de permissão
class PermissionException extends UserRegistrationException {
  PermissionException(String message)
      : super(
          message,
          'PERMISSION_ERROR',
          UserRegistrationExceptionType.permissionError,
        );
}

/// Exceção genérica para falha no registro
class RegistrationFailedException extends UserRegistrationException {
  RegistrationFailedException(String message)
      : super(
          message,
          'REGISTRATION_FAILED',
          UserRegistrationExceptionType.serverError,
        );
}

/// Mapeador de exceções para converter erros genéricos em exceções específicas
class UserRegistrationExceptionMapper {
  static UserRegistrationException mapException(String errorMessage) {
    final lowerMessage = errorMessage.toLowerCase();
    
    // Verificar erros de rede
    if (lowerMessage.contains('network') || 
        lowerMessage.contains('connection') ||
        lowerMessage.contains('timeout')) {
      return RegistrationNetworkException(errorMessage);
    }
    
    // Verificar email já existente
    if (lowerMessage.contains('email') && 
        (lowerMessage.contains('já') || lowerMessage.contains('exists') || lowerMessage.contains('duplicate'))) {
      return EmailAlreadyExistsException('email fornecido');
    }
    
    // Verificar telefone já existente
    if (lowerMessage.contains('telefone') && 
        (lowerMessage.contains('já') || lowerMessage.contains('exists') || lowerMessage.contains('duplicate'))) {
      return PhoneAlreadyExistsException('telefone fornecido');
    }
    
    // Verificar erros de autenticação
    if (lowerMessage.contains('auth') || 
        lowerMessage.contains('unauthorized') ||
        lowerMessage.contains('forbidden')) {
      return AuthenticationException(errorMessage);
    }
    
    // Verificar erros de servidor
    if (lowerMessage.contains('server') || 
        lowerMessage.contains('internal') ||
        lowerMessage.contains('500')) {
      return RegistrationServerException(errorMessage);
    }
    
    // Verificar limite de taxa
    if (lowerMessage.contains('rate limit') || 
        lowerMessage.contains('too many requests')) {
      return RateLimitException(errorMessage);
    }
    
    // Verificar erros de permissão
    if (lowerMessage.contains('permission') || 
        lowerMessage.contains('access denied')) {
      return PermissionException(errorMessage);
    }
    
    // Verificar campos obrigatórios
    if (lowerMessage.contains('required') || 
        lowerMessage.contains('obrigatório') ||
        lowerMessage.contains('missing')) {
      return RequiredFieldsException(errorMessage);
    }
    
    // Verificar erros de validação
    if (lowerMessage.contains('validation') || 
        lowerMessage.contains('invalid') ||
        lowerMessage.contains('formato')) {
      return ValidationException(errorMessage);
    }
    
    // Retornar exceção genérica
    return RegistrationFailedException(errorMessage);
  }
}