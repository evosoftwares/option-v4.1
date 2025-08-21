/// Exceções customizadas para o aplicativo
library;

/// Exceção base para todas as exceções do aplicativo
abstract class AppException implements Exception {
  
  const AppException(this.message, [this.code]);
  final String message;
  final String? code;
  
  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exceção para erros de banco de dados
class DatabaseException extends AppException {
  const DatabaseException(super.message, [super.code]);
  
  @override
  String toString() => 'DatabaseException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exceção para erros de autenticação
class AuthenticationException extends AppException {
  const AuthenticationException(super.message, [super.code]);
  
  @override
  String toString() => 'AuthenticationException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exceção para erros de rede
class NetworkException extends AppException {
  const NetworkException(super.message, [super.code]);
  
  @override
  String toString() => 'NetworkException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exceção para erros de validação
class ValidationException extends AppException {
  const ValidationException(super.message, [super.code]);
  
  @override
  String toString() => 'ValidationException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exceção para usuário não encontrado
class UserNotFoundException extends DatabaseException {
  const UserNotFoundException([String? userId]) 
      : super('Usuário não encontrado${userId != null ? ': $userId' : ''}', 'USER_NOT_FOUND');
}

/// Exceção para usuário já existente
class UserAlreadyExistsException extends DatabaseException {
  const UserAlreadyExistsException([String? email]) 
      : super('Usuário já existe${email != null ? ': $email' : ''}', 'USER_ALREADY_EXISTS');
}