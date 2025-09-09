import 'dart:math' as math;
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
  
  // CRUD OPERATIONS LOGGING
  
  /// Log para operações de CREATE
  static void create(String entity, String id, {String? tag, Map<String, dynamic>? data}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[CREATE]';
      final maskedId = _maskSensitiveData(id);
      print('➕ $formattedTag $entity criado [ID: $maskedId]');
      if (data != null) {
        print('   Dados: ${_sanitizeLogData(data)}');
      }
    }
  }
  
  /// Log para operações de READ
  static void read(String entity, String id, {String? tag, Map<String, dynamic>? filters}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[READ]';
      final maskedId = _maskSensitiveData(id);
      print('👁️ $formattedTag $entity consultado [ID: $maskedId]');
      if (filters != null) {
        print('   Filtros: ${_sanitizeLogData(filters)}');
      }
    }
  }
  
  /// Log para operações de UPDATE
  static void update(String entity, String id, {String? tag, Map<String, dynamic>? changes}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[UPDATE]';
      final maskedId = _maskSensitiveData(id);
      print('✏️ $formattedTag $entity atualizado [ID: $maskedId]');
      if (changes != null) {
        print('   Alterações: ${_sanitizeLogData(changes)}');
      }
    }
  }
  
  /// Log para operações de DELETE
  static void delete(String entity, String id, {String? tag, String? reason}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[DELETE]';
      final maskedId = _maskSensitiveData(id);
      final reasonInfo = reason != null ? ' - Motivo: $reason' : '';
      print('🗑️ $formattedTag $entity excluído [ID: $maskedId]$reasonInfo');
    }
  }
  
  /// Log para operações de QUERY (busca múltipla)
  static void query(String entity, int count, {String? tag, Map<String, dynamic>? filters}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[QUERY]';
      print('🔍 $formattedTag Consulta $entity retornou $count registros');
      if (filters != null) {
        print('   Filtros: ${_sanitizeLogData(filters)}');
      }
    }
  }
  
  // BUSINESS OPERATIONS LOGGING
  
  /// Log para transações financeiras
  static void transaction(String type, String amount, String userId, {String? tag, Map<String, dynamic>? details}) {
    final formattedTag = tag != null ? '[$tag]' : '[TRANSACTION]';
    final maskedUserId = _maskSensitiveData(userId);
    print('💰 $formattedTag $type - R\$ $amount [User: $maskedUserId]');
    if (details != null && _shouldLog) {
      print('   Detalhes: ${_sanitizeLogData(details)}');
    }
  }
  
  /// Log para viagens
  static void trip(String action, String tripId, {String? driverId, String? passengerId, Map<String, dynamic>? data}) {
    if (_shouldLog) {
      final maskedTripId = _maskSensitiveData(tripId);
      final driverInfo = driverId != null ? ' [Motorista: ${_maskSensitiveData(driverId)}]' : '';
      final passengerInfo = passengerId != null ? ' [Passageiro: ${_maskSensitiveData(passengerId)}]' : '';
      print('🚗 [TRIP] $action - Viagem: $maskedTripId$driverInfo$passengerInfo');
      if (data != null) {
        print('   Dados: ${_sanitizeLogData(data)}');
      }
    }
  }
  
  /// Log para localização
  static void location(String action, {String? userId, Map<String, dynamic>? coordinates}) {
    if (_shouldLog) {
      final userInfo = userId != null ? ' [User: ${_maskSensitiveData(userId)}]' : '';
      print('📍 [LOCATION] $action$userInfo');
      if (coordinates != null) {
        print('   Coordenadas: ${_sanitizeLogData(coordinates)}');
      }
    }
  }
  
  /// Log para notificações
  static void notification(String type, String userId, {String? title, bool success = true}) {
    if (_shouldLog) {
      final maskedUserId = _maskSensitiveData(userId);
      final status = success ? '✅' : '❌';
      final titleInfo = title != null ? ' [$title]' : '';
      print('🔔 [NOTIFICATION] $status $type enviado para $maskedUserId$titleInfo');
    }
  }
  
  /// Log para segurança
  static void security(String event, {String? userId, String? details, String? ipAddress}) {
    final maskedUserId = userId != null ? _maskSensitiveData(userId) : 'Anônimo';
    final maskedIp = ipAddress != null ? _maskSensitiveData(ipAddress) : '';
    final ipInfo = maskedIp.isNotEmpty ? ' [IP: $maskedIp]' : '';
    final detailsInfo = details != null ? ' - $details' : '';
    print('🔐 [SECURITY] $event [User: $maskedUserId]$ipInfo$detailsInfo');
  }
  
  /// Log para performance
  static void performance(String operation, Duration duration, {String? tag, Map<String, dynamic>? metrics}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[PERFORMANCE]';
      final ms = duration.inMilliseconds;
      final emoji = ms > 2000 ? '🐌' : ms > 1000 ? '⚡' : '🚀';
      print('$emoji $formattedTag $operation executado em ${ms}ms');
      if (metrics != null) {
        print('   Métricas: ${_sanitizeLogData(metrics)}');
      }
    }
  }
  
  /// Log para validações
  static void validation(String field, bool isValid, {String? entity, String? error}) {
    if (_shouldLog) {
      final status = isValid ? '✅' : '❌';
      final entityInfo = entity != null ? ' [$entity]' : '';
      final errorInfo = error != null && !isValid ? ' - $error' : '';
      print('🔍 [VALIDATION] $status $field$entityInfo$errorInfo');
    }
  }
  
  /// Log para cache
  static void cache(String action, String key, {bool hit = false, String? tag}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[CACHE]';
      final maskedKey = _maskSensitiveData(key);
      final emoji = action == 'HIT' ? '🎯' : action == 'MISS' ? '❌' : '💾';
      print('$emoji $formattedTag $action - Key: $maskedKey');
    }
  }
  
  /// Log para sincronização
  static void sync(String entity, String action, {int? count, String? direction}) {
    if (_shouldLog) {
      final countInfo = count != null ? ' ($count registros)' : '';
      final directionInfo = direction != null ? ' [$direction]' : '';
      print('🔄 [SYNC] $entity $action$countInfo$directionInfo');
    }
  }
  
  // EXPANDED LOGGING METHODS FOR MORE SITUATIONS
  
  /// Log para operações de rede
  static void network(String operation, String url, {String? method, int? statusCode, Duration? duration, String? tag, Map<String, dynamic>? headers}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[NETWORK]';
      final methodInfo = method != null ? '$method ' : '';
      final statusInfo = statusCode != null ? ' [Status: $statusCode]' : '';
      final durationInfo = duration != null ? ' [${duration.inMilliseconds}ms]' : '';
      final maskedUrl = url.length > 50 ? '${url.substring(0, 50)}...' : url;
      
      String emoji = '🌐';
      if (statusCode != null) {
        emoji = statusCode < 300 ? '✅' : statusCode < 500 ? '⚠️' : '❌';
      }
      
      print('$emoji $formattedTag $methodInfo$maskedUrl$statusInfo$durationInfo');
      if (headers != null) {
        print('   Headers: ${_sanitizeLogData(headers)}');
      }
    }
  }
  
  /// Log para connectivity e internet
  static void connectivity(String status, {String? type, String? tag, Map<String, dynamic>? details}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[CONNECTIVITY]';
      final typeInfo = type != null ? ' [$type]' : '';
      final emoji = status.toLowerCase().contains('connected') ? '📶' : 
                   status.toLowerCase().contains('disconnected') ? '📵' : '🔄';
      
      print('$emoji $formattedTag $status$typeInfo');
      if (details != null) {
        print('   Detalhes: ${_sanitizeLogData(details)}');
      }
    }
  }
  
  /// Log para GPS e localização avançado
  static void gps(String action, {double? latitude, double? longitude, double? accuracy, String? provider, String? tag, Map<String, dynamic>? extra}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[GPS]';
      final coordsInfo = (latitude != null && longitude != null) ? 
        ' [${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}]' : '';
      final accuracyInfo = accuracy != null ? ' [±${accuracy.toStringAsFixed(1)}m]' : '';
      final providerInfo = provider != null ? ' [$provider]' : '';
      
      print('📍 $formattedTag $action$coordsInfo$accuracyInfo$providerInfo');
      if (extra != null) {
        print('   Extra: ${_sanitizeLogData(extra)}');
      }
    }
  }
  
  /// Log para estados de aplicação
  static void appState(String state, {String? previousState, String? reason, Duration? duration, String? tag}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[APP_STATE]';
      final prevInfo = previousState != null ? ' (from: $previousState)' : '';
      final reasonInfo = reason != null ? ' - $reason' : '';
      final durationInfo = duration != null ? ' [${duration.inMilliseconds}ms]' : '';
      
      String emoji = '📱';
      switch (state.toLowerCase()) {
        case 'active': case 'foreground': emoji = '🟢'; break;
        case 'background': emoji = '🟡'; break;
        case 'paused': case 'inactive': emoji = '⏸️'; break;
        case 'resumed': emoji = '▶️'; break;
        case 'terminated': case 'closed': emoji = '🔴'; break;
      }
      
      print('$emoji $formattedTag $state$prevInfo$reasonInfo$durationInfo');
    }
  }
  
  /// Log para deep links e navegação
  static void navigation(String action, String route, {String? previousRoute, Map<String, dynamic>? params, String? tag}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[NAVIGATION]';
      final prevInfo = previousRoute != null ? ' (from: $previousRoute)' : '';
      
      print('🧭 $formattedTag $action: $route$prevInfo');
      if (params != null) {
        print('   Params: ${_sanitizeLogData(params)}');
      }
    }
  }
  
  /// Log para backup e restore
  static void backup(String operation, String dataType, {int? itemCount, String? destination, bool? success, String? error, String? tag}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[BACKUP]';
      final countInfo = itemCount != null ? ' [$itemCount items]' : '';
      final destInfo = destination != null ? ' -> $destination' : '';
      final statusEmoji = success == true ? '✅' : success == false ? '❌' : '🔄';
      
      print('$statusEmoji $formattedTag $operation: $dataType$countInfo$destInfo');
      if (error != null) {
        print('   Erro: $error');
      }
    }
  }
  
  /// Log para biometria e autenticação segura
  static void biometrics(String action, String type, {bool? available, bool? success, String? error, String? tag}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[BIOMETRICS]';
      final typeInfo = ' [$type]';
      final availInfo = available != null ? (available ? ' [Available]' : ' [Not Available]') : '';
      
      String emoji = '🔐';
      if (success == true) {
        emoji = '✅';
      } else if (success == false) emoji = '❌';
      else if (available == false) emoji = '🚫';
      
      print('$emoji $formattedTag $action$typeInfo$availInfo');
      if (error != null) {
        print('   Erro: $error');
      }
    }
  }
  
  /// Log para temas e UI
  static void ui(String component, String action, {String? theme, Map<String, dynamic>? properties, String? tag}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[UI]';
      final themeInfo = theme != null ? ' [$theme]' : '';
      
      print('🎨 $formattedTag $component: $action$themeInfo');
      if (properties != null) {
        print('   Properties: ${_sanitizeLogData(properties)}');
      }
    }
  }
  
  /// Log para workers e background tasks
  static void background(String taskName, String status, {Duration? duration, String? result, int? progress, String? tag}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[BACKGROUND]';
      final durationInfo = duration != null ? ' [${duration.inSeconds}s]' : '';
      final progressInfo = progress != null ? ' [$progress%]' : '';
      final resultInfo = result != null ? ' -> $result' : '';
      
      String emoji = '⚙️';
      switch (status.toLowerCase()) {
        case 'started': case 'running': emoji = '🔄'; break;
        case 'completed': case 'success': emoji = '✅'; break;
        case 'failed': case 'error': emoji = '❌'; break;
        case 'cancelled': emoji = '⏹️'; break;
        case 'paused': emoji = '⏸️'; break;
      }
      
      print('$emoji $formattedTag $taskName: $status$durationInfo$progressInfo$resultInfo');
    }
  }
  
  /// Log para webhooks e callbacks
  static void webhook(String event, String source, {int? statusCode, String? payload, Map<String, dynamic>? headers, String? tag}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[WEBHOOK]';
      final statusInfo = statusCode != null ? ' [HTTP $statusCode]' : '';
      final maskedPayload = payload != null ? _maskSensitiveData(payload) : null;
      
      print('🔗 $formattedTag $event from $source$statusInfo');
      if (maskedPayload != null) {
        print('   Payload: $maskedPayload');
      }
      if (headers != null) {
        print('   Headers: ${_sanitizeLogData(headers)}');
      }
    }
  }
  
  /// Log para analytics e métricas de usuário
  static void analytics(String event, String category, {Map<String, dynamic>? parameters, String? userId, String? tag}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[ANALYTICS]';
      final userInfo = userId != null ? ' [User: ${_maskSensitiveData(userId)}]' : '';
      
      print('📊 $formattedTag $category: $event$userInfo');
      if (parameters != null) {
        print('   Parameters: ${_sanitizeLogData(parameters)}');
      }
    }
  }
  
  /// Log para crashes e erros críticos
  static void crash(String error, {String? stackTrace, Map<String, dynamic>? context, String? userId, String? tag}) {
    final formattedTag = tag != null ? '[$tag]' : '[CRASH]';
    final userInfo = userId != null ? ' [User: ${_maskSensitiveData(userId)}]' : '';
    
    // Crashes sempre são logados, mesmo em produção
    print('💥 $formattedTag CRITICAL ERROR$userInfo');
    print('   Error: $error');
    if (context != null) {
      print('   Context: ${_sanitizeLogData(context)}');
    }
    if (stackTrace != null && !_isProduction) {
      print('   Stack: ${stackTrace.substring(0, math.min(stackTrace.length, 500))}...');
    }
  }
  
  /// Log para rate limiting e throttling
  static void rateLimit(String resource, String action, {int? limit, int? remaining, Duration? resetTime, String? tag}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[RATE_LIMIT]';
      final limitInfo = limit != null ? ' [Limit: $limit]' : '';
      final remainingInfo = remaining != null ? ' [Remaining: $remaining]' : '';
      final resetInfo = resetTime != null ? ' [Reset: ${resetTime.inMinutes}min]' : '';
      
      String emoji = '🚦';
      if (remaining != null) {
        emoji = remaining > (limit ?? 10) * 0.5 ? '🟢' : remaining > 0 ? '🟡' : '🔴';
      }
      
      print('$emoji $formattedTag $resource: $action$limitInfo$remainingInfo$resetInfo');
    }
  }
  
  /// Log para feature flags e A/B testing
  static void featureFlag(String flag, bool enabled, {String? variant, String? userId, Map<String, dynamic>? metadata, String? tag}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[FEATURE_FLAG]';
      final statusEmoji = enabled ? '🟢' : '🔴';
      final variantInfo = variant != null ? ' [Variant: $variant]' : '';
      final userInfo = userId != null ? ' [User: ${_maskSensitiveData(userId)}]' : '';
      
      print('$statusEmoji $formattedTag $flag: ${enabled ? 'ENABLED' : 'DISABLED'}$variantInfo$userInfo');
      if (metadata != null) {
        print('   Metadata: ${_sanitizeLogData(metadata)}');
      }
    }
  }
  
  /// Log para queue e message processing
  static void queue(String queueName, String action, {int? size, String? messageId, int? priority, Duration? processingTime, String? tag}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[QUEUE]';
      final sizeInfo = size != null ? ' [Size: $size]' : '';
      final msgInfo = messageId != null ? ' [Msg: ${_maskSensitiveData(messageId)}]' : '';
      final priorityInfo = priority != null ? ' [P$priority]' : '';
      final timeInfo = processingTime != null ? ' [${processingTime.inMilliseconds}ms]' : '';
      
      String emoji = '📬';
      switch (action.toLowerCase()) {
        case 'enqueued': case 'added': emoji = '📥'; break;
        case 'dequeued': case 'processed': emoji = '📤'; break;
        case 'failed': emoji = '❌'; break;
        case 'retry': emoji = '🔄'; break;
      }
      
      print('$emoji $formattedTag $queueName: $action$sizeInfo$msgInfo$priorityInfo$timeInfo');
    }
  }
  
  /// Log para device info e capabilities
  static void device(String property, dynamic value, {String? category, String? tag}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[DEVICE]';
      final categoryInfo = category != null ? ' [$category]' : '';
      final maskedValue = value is String ? _maskSensitiveData(value.toString()) : value.toString();
      
      print('📱 $formattedTag $property$categoryInfo: $maskedValue');
    }
  }
  
  /// Log para experiments e testes
  static void experiment(String name, String group, {String? userId, Map<String, dynamic>? config, String? tag}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[EXPERIMENT]';
      final userInfo = userId != null ? ' [User: ${_maskSensitiveData(userId)}]' : '';
      
      print('🧪 $formattedTag $name: $group$userInfo');
      if (config != null) {
        print('   Config: ${_sanitizeLogData(config)}');
      }
    }
  }
  
  /// Log para health checks e status
  static void health(String component, String status, {Duration? responseTime, String? version, Map<String, dynamic>? metrics, String? tag}) {
    final formattedTag = tag != null ? '[$tag]' : '[HEALTH]';
    final timeInfo = responseTime != null ? ' [${responseTime.inMilliseconds}ms]' : '';
    final versionInfo = version != null ? ' [v$version]' : '';
    
    String emoji = '❤️';
    switch (status.toLowerCase()) {
      case 'healthy': case 'ok': case 'up': emoji = '💚'; break;
      case 'warning': case 'degraded': emoji = '💛'; break;
      case 'unhealthy': case 'down': case 'error': emoji = '❤️‍🩹'; break;
      case 'checking': emoji = '🔄'; break;
    }
    
    // Health checks sempre visíveis para monitoramento
    print('$emoji $formattedTag $component: $status$timeInfo$versionInfo');
    if (metrics != null && _shouldLog) {
      print('   Metrics: ${_sanitizeLogData(metrics)}');
    }
  }
  
  /// Log para retry logic e circuit breakers
  static void retry(String operation, int attempt, {int? maxAttempts, Duration? delay, String? reason, String? tag}) {
    if (_shouldLog) {
      final formattedTag = tag != null ? '[$tag]' : '[RETRY]';
      final attemptInfo = maxAttempts != null ? ' [$attempt/$maxAttempts]' : ' [Attempt: $attempt]';
      final delayInfo = delay != null ? ' [Delay: ${delay.inSeconds}s]' : '';
      final reasonInfo = reason != null ? ' - $reason' : '';
      
      print('🔄 $formattedTag $operation$attemptInfo$delayInfo$reasonInfo');
    }
  }
  
  /// Sanitiza dados para log removendo informações sensíveis
  static Map<String, dynamic> _sanitizeLogData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    
    data.forEach((key, value) {
      final lowerKey = key.toLowerCase();
      
      // Lista expandida de campos sensíveis
      if (lowerKey.contains('password') || 
          lowerKey.contains('token') ||
          lowerKey.contains('secret') ||
          lowerKey.contains('key') ||
          lowerKey.contains('cpf') ||
          lowerKey.contains('card') ||
          lowerKey.contains('payment') ||
          lowerKey.contains('credit') ||
          lowerKey.contains('bank') ||
          lowerKey.contains('account') ||
          lowerKey.contains('pin') ||
          lowerKey.contains('otp') ||
          lowerKey.contains('auth') ||
          lowerKey.contains('session') ||
          lowerKey.contains('cookie')) {
        sanitized[key] = '***MASKED***';
      } else if (value is String) {
        if (value.contains('@') || value.length > 15) {
          sanitized[key] = _maskSensitiveData(value);
        } else {
          sanitized[key] = value;
        }
      } else {
        sanitized[key] = value;
      }
    });
    
    return sanitized;
  }
}