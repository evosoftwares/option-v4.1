import 'package:flutter/foundation.dart';

/// Sistema de logging inteligente para diferentes ambientes
/// Garante que dados sensíveis não vazem para produção
class AppLogger {
  static const bool _isProduction = kReleaseMode;
  
  /// Log de debug - apenas em desenvolvimento
  static void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    if (!_isProduction) {
      final formattedTag = tag != null ? '[$tag]' : '[DEBUG]';
      print('🐛 $formattedTag $message');
      if (data != null) {
        print('   Data: $data');
      }
    }
  }
  
  /// Log informativo - apenas em desenvolvimento  
  static void info(String message, {String? tag}) {
    if (!_isProduction) {
      final formattedTag = tag != null ? '[$tag]' : '[INFO]';
      print('ℹ️ $formattedTag $message');
    }
  }
  
  /// Log de sucesso - apenas em desenvolvimento
  static void success(String message, {String? tag}) {
    if (!_isProduction) {
      final formattedTag = tag != null ? '[$tag]' : '[SUCCESS]';
      print('✅ $formattedTag $message');
    }
  }
  
  /// Log de processo - apenas em desenvolvimento
  static void process(String message, {String? tag}) {
    if (!_isProduction) {
      final formattedTag = tag != null ? '[$tag]' : '[PROCESS]';
      print('🔄 $formattedTag $message');
    }
  }
  
  /// Log de warning - sempre logado (importante para monitoramento)
  static void warning(String message, {String? tag}) {
    final formattedTag = tag != null ? '[$tag]' : '[WARNING]';
    print('⚠️ $formattedTag $message');
  }
  
  /// Log de erro - sempre logado (crítico)
  static void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    final formattedTag = tag != null ? '[$tag]' : '[ERROR]';
    print('❌ $formattedTag $message');
    if (error != null) print('   Error: $error');
    if (stackTrace != null && !_isProduction) {
      print('   Stack: $stackTrace');
    }
  }
  
  /// Log com mascaramento automático de dados sensíveis
  static void debugSensitive(String message, String sensitiveData, {String? tag}) {
    if (!_isProduction) {
      final masked = _maskSensitiveData(sensitiveData);
      debug('$message (data: $masked)', tag: tag);
    }
  }
  
  /// Mascara dados sensíveis para evitar vazamentos
  static String _maskSensitiveData(String data) {
    if (data.contains('@')) {
      // Email masking
      final parts = data.split('@');
      if (parts[0].length > 2) {
        return '${parts[0].substring(0, 2)}***@${parts[1]}';
      }
      return '***@${parts[1]}';
    }
    
    if (data.length > 4) {
      // ID/Token masking
      return '${data.substring(0, 4)}***';
    }
    
    return '***';
  }
  
  /// Log específico para autenticação
  static void auth(String message, {String? userId}) {
    if (!_isProduction) {
      final maskedId = userId != null ? _maskSensitiveData(userId) : null;
      final userInfo = maskedId != null ? ' [User: $maskedId]' : '';
      print('🔐 [AUTH]$userInfo $message');
    }
  }
  
  /// Log específico para stepper
  static void stepper(String message, {int? step}) {
    if (!_isProduction) {
      final stepInfo = step != null ? ' [Step: $step]' : '';
      print('📋 [STEPPER]$stepInfo $message');
    }
  }
  
  /// Log específico para upload de arquivos
  static void upload(String message, {String? filename}) {
    if (!_isProduction) {
      final fileInfo = filename != null ? ' [File: $filename]' : '';
      print('📤 [UPLOAD]$fileInfo $message');
    }
  }
  
  /// Log específico para persistência
  static void persistence(String message) {
    if (!_isProduction) {
      print('💾 [PERSISTENCE] $message');
    }
  }
  
  /// Configuração para testes - força logs mesmo em release
  static bool _forceDebugMode = false;
  
  /// Força modo debug para testes
  static void enableDebugMode() {
    _forceDebugMode = true;
  }
  
  /// Desabilita modo debug forçado
  static void disableDebugMode() {
    _forceDebugMode = false;
  }
  
  /// Verifica se deve logar (considerando modo forçado)
  static bool get _shouldLog => !_isProduction || _forceDebugMode;
}