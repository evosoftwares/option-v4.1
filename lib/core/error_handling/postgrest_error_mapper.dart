/// Mapeador central para traduzir PostgrestException em exceções específicas
/// Preserva contexto e códigos de erro para melhor debugging e UX
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../exceptions/app_exceptions.dart' as app_exc;
import '../../exceptions/user_registration_exception.dart';
import 'app_error.dart';

/// Mapeador central para erros do Postgrest/Supabase
class PostgrestErrorMapper {
  /// Mapeia PostgrestException para exceções específicas da aplicação
  static Exception mapError(PostgrestException error, {Map<String, dynamic>? context}) {
    final code = error.code;
    final message = error.message;
    final details = error.details;
    
    // Log do erro original para debugging
    final errorContext = {
      'postgrest_code': code,
      'postgrest_message': message,
      'postgrest_details': details,
      'hint': error.hint,
      ...?context,
    };
    
    // Mapear códigos específicos do PostgreSQL
    switch (code) {
      // Violação de constraint única (duplicação)
      case '23505':
        return _handleUniqueViolation(message, details?.toString(), errorContext);
      
      // Nenhuma linha encontrada (PGRST116)
      case 'PGRST116':
        return _handleNoRowsFound(message, errorContext);
      
      // Erro de permissão/RLS (42501)
      case '42501':
        return _handlePermissionDenied(message, errorContext);
      
      // Violação de constraint de chave estrangeira
      case '23503':
        return _handleForeignKeyViolation(message, details?.toString(), errorContext);
      
      // Violação de constraint NOT NULL
      case '23502':
        return _handleNotNullViolation(message, details?.toString(), errorContext);
      
      // Erro de sintaxe SQL
      case '42601':
        return const app_exc.DatabaseException('Erro de sintaxe na consulta', 'SQL_SYNTAX_ERROR');
      
      // Tabela ou coluna não existe
      case '42P01':
      case '42703':
        return app_exc.DatabaseException('Estrutura de banco inválida: $message', 'SCHEMA_ERROR');
      
      // Timeout de conexão
      case 'PGRST001':
        return const app_exc.NetworkException('Timeout de conexão com o banco', 'CONNECTION_TIMEOUT');
      
      // Erro de autenticação JWT
      case 'PGRST301':
        return const app_exc.AuthenticationException('Token de autenticação inválido', 'INVALID_JWT');
      
      // Sessão expirada
      case 'PGRST302':
        return const app_exc.AuthenticationException('Sessão expirada', 'SESSION_EXPIRED');
      
      default:
        return _handleGenericError(error, errorContext);
    }
  }
  
  /// Trata violações de constraint única (duplicação)
  static Exception _handleUniqueViolation(String message, String? details, Map<String, dynamic> context) {
    final lowerMessage = message.toLowerCase();
    final lowerDetails = details?.toLowerCase() ?? '';
    
    // Detectar tipo específico de duplicação
    if (lowerMessage.contains('email') || lowerDetails.contains('email')) {
      return EmailAlreadyExistsException('email');
    }
    
    if (lowerMessage.contains('phone') || lowerDetails.contains('telefone')) {
      return PhoneAlreadyExistsException('telefone');
    }
    
    if (lowerMessage.contains('license_plate') || lowerDetails.contains('placa')) {
      return const app_exc.DatabaseException('Esta placa já está cadastrada por outro motorista', 'DUPLICATE_LICENSE_PLATE');
    }
    
    if (lowerMessage.contains('cpf')) {
      return const app_exc.DatabaseException('Este CPF já está cadastrado', 'DUPLICATE_CPF');
    }
    
    if (lowerMessage.contains('cnpj')) {
      return const app_exc.DatabaseException('Este CNPJ já está cadastrado', 'DUPLICATE_CNPJ');
    }
    
    // Duplicação genérica
    return app_exc.DatabaseException('Dados duplicados: $message', 'DUPLICATE_ENTRY');
  }
  
  /// Trata casos onde nenhuma linha foi encontrada
  static Exception _handleNoRowsFound(String message, Map<String, dynamic> context) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('user') || lowerMessage.contains('usuario')) {
      return const app_exc.UserNotFoundException();
    }
    
    if (lowerMessage.contains('trip') || lowerMessage.contains('viagem')) {
      return const app_exc.DatabaseException('Viagem não encontrada', 'TRIP_NOT_FOUND');
    }
    
    if (lowerMessage.contains('driver') || lowerMessage.contains('motorista')) {
      return const app_exc.DatabaseException('Motorista não encontrado', 'DRIVER_NOT_FOUND');
    }
    
    return const app_exc.DatabaseException('Registro não encontrado', 'NOT_FOUND');
  }
  
  /// Trata erros de permissão/RLS
  static Exception _handlePermissionDenied(String message, Map<String, dynamic> context) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('rls') || lowerMessage.contains('row level security')) {
      return const app_exc.AuthenticationException('Acesso negado: verifique suas permissões', 'RLS_VIOLATION');
    }
    
    if (lowerMessage.contains('policy')) {
      return const app_exc.AuthenticationException('Política de segurança violada', 'POLICY_VIOLATION');
    }
    
    return app_exc.AuthenticationException('Permissão negado: $message', 'PERMISSION_DENIED');
  }
  
  /// Trata violações de chave estrangeira
  static Exception _handleForeignKeyViolation(String message, String? details, Map<String, dynamic> context) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('vehicle_category')) {
      return const app_exc.ValidationException('Categoria de veículo inválida', 'INVALID_VEHICLE_CATEGORY');
    }
    
    if (lowerMessage.contains('user_id')) {
      return const app_exc.ValidationException('Usuário inválido ou não existe', 'INVALID_USER_REFERENCE');
    }
    
    return app_exc.ValidationException('Referência inválida: $message', 'FOREIGN_KEY_VIOLATION');
  }
  
  /// Trata violações de constraint NOT NULL
  static Exception _handleNotNullViolation(String message, String? details, Map<String, dynamic> context) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('phone') || lowerMessage.contains('telefone')) {
      return const app_exc.ValidationException('Telefone é obrigatório para criar usuário', 'PHONE_REQUIRED');
    }
    
    if (lowerMessage.contains('email')) {
      return const app_exc.ValidationException('Email é obrigatório', 'EMAIL_REQUIRED');
    }
    
    if (lowerMessage.contains('name') || lowerMessage.contains('nome')) {
      return const app_exc.ValidationException('Nome é obrigatório', 'NAME_REQUIRED');
    }
    
    return app_exc.ValidationException('Campo obrigatório não preenchido: $message', 'REQUIRED_FIELD_MISSING');
  }
  
  /// Trata erros genéricos preservando contexto
  static Exception _handleGenericError(PostgrestException error, Map<String, dynamic> context) {
    final message = error.message;
    final code = error.code ?? 'UNKNOWN';
    
    // Tentar detectar tipo baseado na mensagem
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('network') || lowerMessage.contains('connection')) {
      return app_exc.NetworkException('Erro de conexão: $message', code);
    }
    
    if (lowerMessage.contains('timeout')) {
      return app_exc.NetworkException('Timeout: $message', code);
    }
    
    if (lowerMessage.contains('authentication') || lowerMessage.contains('unauthorized')) {
      return app_exc.AuthenticationException('Erro de autenticação: $message', code);
    }
    
    if (lowerMessage.contains('validation') || lowerMessage.contains('invalid')) {
      return app_exc.ValidationException('Erro de validação: $message', code);
    }
    
    // Erro genérico de banco preservando contexto
    return app_exc.DatabaseException('Erro de banco: $message', code);
  }
  
  /// Converte exceção mapeada para AppError para telemetria
  static AppError toAppError(Exception exception, {Map<String, dynamic>? additionalContext}) {
    AppErrorType type;
    ErrorSeverity severity;
    
    if (exception is app_exc.AuthenticationException) {
      type = AppErrorType.authenticationFailed;
      severity = ErrorSeverity.high;
    } else if (exception is app_exc.NetworkException) {
      type = AppErrorType.networkUnavailable;
      severity = ErrorSeverity.medium;
    } else if (exception is app_exc.ValidationException) {
      type = AppErrorType.validationFailed;
      severity = ErrorSeverity.low;
    } else if (exception is app_exc.UserNotFoundException) {
      type = AppErrorType.authenticationFailed;
      severity = ErrorSeverity.medium;
    } else if (exception is EmailAlreadyExistsException) {
       type = AppErrorType.validationFailed;
       severity = ErrorSeverity.medium;
     } else if (exception is PhoneAlreadyExistsException) {
       type = AppErrorType.validationFailed;
       severity = ErrorSeverity.medium;
     } else {
       type = AppErrorType.databaseError;
       severity = ErrorSeverity.high;
     }
    
    return AppError(
      type: type,
      message: exception.toString(),
      severity: severity,
      context: additionalContext,
    );
  }
}