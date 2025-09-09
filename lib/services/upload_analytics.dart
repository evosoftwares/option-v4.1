import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_preferences_service.dart';

/// Sistema de analytics para monitorar uploads e identificar problemas em produção
class UploadAnalytics {
  static const String _keyUploadStats = 'upload_analytics_stats';
  static const String _keyUploadErrors = 'upload_analytics_errors';
  static const int _maxErrorsStored = 50;

  /// Verifica se o usuário deu consentimento para analytics
  static Future<bool> _hasAnalyticsConsent() async {
    try {
      return await UserPreferencesService().getAnalyticsConsent();
    } catch (e) {
      print('⚠️ Erro ao verificar consentimento de analytics: $e');
      return false; // Default to not collecting if we can't determine consent
    }
  }

  /// Registra início de upload
  static Future<void> recordUploadStart({
    required String uploadId,
    required String type, // 'driver-document' ou 'user-image'
    required int fileSizeBytes,
    required String fileName,
  }) async {
    // Check for user consent before collecting analytics
    final hasConsent = await _hasAnalyticsConsent();
    if (!hasConsent) {
      print('⏭️  Analytics desativados pelo usuário - início de upload não registrado');
      return;
    }

    final event = UploadEvent(
      uploadId: uploadId,
      type: type,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      startTime: DateTime.now(),
      status: UploadStatus.started,
    );
    
    await _saveEvent(event);
    print('📊 [ANALYTICS] Upload iniciado: $uploadId ($type, ${(fileSizeBytes / 1024).toStringAsFixed(1)}KB)');
  }

  /// Registra tentativa de retry
  static Future<void> recordRetryAttempt({
    required String uploadId,
    required int attemptNumber,
    required String errorMessage,
  }) async {
    // Check for user consent before collecting analytics
    final hasConsent = await _hasAnalyticsConsent();
    if (!hasConsent) {
      print('⏭️  Analytics desativados pelo usuário - tentativa de retry não registrada');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final event = await _getEvent(uploadId);
    
    if (event != null) {
      event.retryAttempts++;
      event.lastError = errorMessage;
      event.status = UploadStatus.retrying;
      await _saveEvent(event);
    }
    
    print('📊 [ANALYTICS] Retry #$attemptNumber para $uploadId: $errorMessage');
  }

  /// Registra sucesso do upload
  static Future<void> recordUploadSuccess({
    required String uploadId,
    required String downloadUrl,
    required Duration totalDuration,
    required int finalSizeBytes,
  }) async {
    // Check for user consent before collecting analytics
    final hasConsent = await _hasAnalyticsConsent();
    if (!hasConsent) {
      print('⏭️  Analytics desativados pelo usuário - sucesso de upload não registrado');
      return;
    }

    final event = await _getEvent(uploadId);
    
    if (event != null) {
      event.endTime = DateTime.now();
      event.downloadUrl = downloadUrl;
      event.totalDuration = totalDuration;
      event.finalSizeBytes = finalSizeBytes;
      event.status = UploadStatus.success;
      await _saveEvent(event);
    }
    
    await _updateStats(success: true, duration: totalDuration, size: finalSizeBytes);
    print('📊 [ANALYTICS] Upload concluído com sucesso: $uploadId (${totalDuration.inSeconds}s)');
  }

  /// Registra falha do upload
  static Future<void> recordUploadFailure({
    required String uploadId,
    required String errorMessage,
    required Duration totalDuration,
  }) async {
    // Check for user consent before collecting analytics
    final hasConsent = await _hasAnalyticsConsent();
    if (!hasConsent) {
      print('⏭️  Analytics desativados pelo usuário - falha de upload não registrada');
      return;
    }

    final event = await _getEvent(uploadId);
    
    if (event != null) {
      event.endTime = DateTime.now();
      event.lastError = errorMessage;
      event.totalDuration = totalDuration;
      event.status = UploadStatus.failed;
      await _saveEvent(event);
    }
    
    await _updateStats(success: false, duration: totalDuration);
    await _saveError(uploadId, errorMessage);
    print('📊 [ANALYTICS] Upload falhou: $uploadId - $errorMessage');
  }

  /// Obtém estatísticas de upload
  static Future<UploadStats> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_keyUploadStats);
    
    if (statsJson != null) {
      return UploadStats.fromJson(jsonDecode(statsJson));
    }
    
    return UploadStats();
  }

  /// Obtém erros recentes
  static Future<List<UploadError>> getRecentErrors({int limit = 10}) async {
    final prefs = await SharedPreferences.getInstance();
    final errorsJson = prefs.getString(_keyUploadErrors);
    
    if (errorsJson != null) {
      final errorsList = jsonDecode(errorsJson) as List;
      final errors = errorsList
          .map((e) => UploadError.fromJson(e))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return errors.take(limit).toList();
    }
    
    return [];
  }

  /// Limpa dados de analytics antigos
  static Future<void> cleanup({int daysToKeep = 7}) async {
    final prefs = await SharedPreferences.getInstance();
    final cutoff = DateTime.now().subtract(Duration(days: daysToKeep));
    
    // Limpar eventos antigos seria complexo, por agora só limpamos erros
    final errors = await getRecentErrors(limit: _maxErrorsStored);
    final recentErrors = errors.where((e) => e.timestamp.isAfter(cutoff)).toList();
    
    await prefs.setString(_keyUploadErrors, jsonEncode(recentErrors.map((e) => e.toJson()).toList()));
  }

  /// Salva evento de upload
  static Future<void> _saveEvent(UploadEvent event) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('upload_event_${event.uploadId}', jsonEncode(event.toJson()));
  }

  /// Obtém evento de upload
  static Future<UploadEvent?> _getEvent(String uploadId) async {
    final prefs = await SharedPreferences.getInstance();
    final eventJson = prefs.getString('upload_event_$uploadId');
    
    if (eventJson != null) {
      return UploadEvent.fromJson(jsonDecode(eventJson));
    }
    
    return null;
  }

  /// Atualiza estatísticas gerais
  static Future<void> _updateStats({
    required bool success,
    required Duration duration,
    int? size,
  }) async {
    final stats = await getStats();
    
    stats.totalUploads++;
    if (success) {
      stats.successfulUploads++;
      stats.totalUploadTime += duration.inMilliseconds;
      if (size != null) stats.totalBytesUploaded += size;
    } else {
      stats.failedUploads++;
    }
    
    stats.lastUpdated = DateTime.now();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUploadStats, jsonEncode(stats.toJson()));
  }

  /// Salva erro para análise posterior
  static Future<void> _saveError(String uploadId, String errorMessage) async {
    final errors = await getRecentErrors(limit: _maxErrorsStored - 1);
    
    final newError = UploadError(
      uploadId: uploadId,
      errorMessage: errorMessage,
      timestamp: DateTime.now(),
    );
    
    errors.insert(0, newError);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUploadErrors, jsonEncode(errors.map((e) => e.toJson()).toList()));
  }

  /// Gera relatório de diagnóstico
  static Future<String> generateDiagnosticReport() async {
    // Check for user consent before collecting analytics
    final hasConsent = await _hasAnalyticsConsent();
    if (!hasConsent) {
      return '⏭️  Analytics desativados pelo usuário - relatório não disponível';
    }

    final stats = await getStats();
    final errors = await getRecentErrors(limit: 10);
    
    final report = StringBuffer();
    report.writeln('📊 RELATÓRIO DE DIAGNÓSTICO DE UPLOADS');
    report.writeln('=====================================');
    report.writeln('');
    
    // Estatísticas gerais
    report.writeln('📈 ESTATÍSTICAS GERAIS:');
    report.writeln('- Total de uploads: ${stats.totalUploads}');
    report.writeln('- Sucessos: ${stats.successfulUploads} (${stats.successRate.toStringAsFixed(1)}%)');
    report.writeln('- Falhas: ${stats.failedUploads} (${(100 - stats.successRate).toStringAsFixed(1)}%)');
    report.writeln('- Tempo médio: ${stats.averageUploadTime.toStringAsFixed(1)}s');
    report.writeln('- Velocidade média: ${stats.averageUploadSpeed.toStringAsFixed(1)} KB/s');
    report.writeln('- Último update: ${stats.lastUpdated?.toIso8601String() ?? 'nunca'}');
    report.writeln('');
    
    // Erros recentes
    if (errors.isNotEmpty) {
      report.writeln('❌ ERROS RECENTES:');
      for (final error in errors.take(5)) {
        report.writeln('- ${error.timestamp.toIso8601String()}: ${error.errorMessage}');
      }
      report.writeln('');
    }
    
    // Recomendações
    report.writeln('💡 RECOMENDAÇÕES:');
    if (stats.successRate < 90) {
      report.writeln('- Taxa de sucesso baixa (${stats.successRate.toStringAsFixed(1)}%). Verificar conectividade e configurações.');
    }
    if (stats.averageUploadTime > 30) {
      report.writeln('- Uploads lentos (${stats.averageUploadTime.toStringAsFixed(1)}s). Verificar tamanho das imagens e compressão.');
    }
    if (errors.isNotEmpty) {
      final commonErrors = <String, int>{};
      for (final error in errors) {
        final key = error.errorMessage.split(':').first;
        commonErrors[key] = (commonErrors[key] ?? 0) + 1;
      }
      final mostCommon = commonErrors.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      if (mostCommon.isNotEmpty) {
        report.writeln('- Erro mais comum: ${mostCommon.first.key} (${mostCommon.first.value} ocorrências)');
      }
    }
    
    return report.toString();
  }

  // ===================================================================
  // USER CONSENT MANAGEMENT METHODS
  // These methods allow the app to manage user consent for analytics
  // ===================================================================

  /// Checks if the user has given consent for analytics
  static Future<bool> hasAnalyticsConsent() async {
    try {
      return await UserPreferencesService().getAnalyticsConsent();
    } catch (e) {
      print('⚠️ Erro ao verificar consentimento de analytics: $e');
      return false; // Default to not collecting if we can't determine consent
    }
  }

  /// Sets the user's consent for analytics
  static Future<bool> setAnalyticsConsent(bool consent) async {
    try {
      await UserPreferencesService().setAnalyticsConsent(consent);
      return true;
    } catch (e) {
      print('⚠️ Erro ao definir consentimento de analytics: $e');
      return false;
    }
  }

  /// Checks if the user has given consent for marketing communications
  static Future<bool> hasMarketingConsent() async {
    try {
      return await UserPreferencesService().getMarketingConsent();
    } catch (e) {
      print('⚠️ Erro ao verificar consentimento de marketing: $e');
      return false; // Default to not collecting if we can't determine consent
    }
  }

  /// Sets the user's consent for marketing communications
  static Future<bool> setMarketingConsent(bool consent) async {
    try {
      await UserPreferencesService().setMarketingConsent(consent);
      return true;
    } catch (e) {
      print('⚠️ Erro ao definir consentimento de marketing: $e');
      return false;
    }
  }

  /// Checks if the user has accepted the privacy policy
  static Future<bool> hasAcceptedPrivacyPolicy() async {
    try {
      return await UserPreferencesService().getPrivacyPolicyAccepted();
    } catch (e) {
      print('⚠️ Erro ao verificar aceitação da política de privacidade: $e');
      return false; // Default to not collecting if we can't determine consent
    }
  }

  /// Sets the user's acceptance of the privacy policy
  static Future<bool> setPrivacyPolicyAccepted(bool accepted) async {
    try {
      await UserPreferencesService().setPrivacyPolicyAccepted(accepted);
      return true;
    } catch (e) {
      print('⚠️ Erro ao definir aceitação da política de privacidade: $e');
      return false;
    }
  }

  /// Tracks an analytics event, respecting user consent
  static Future<void> trackEvent(String eventName, Map<String, dynamic> properties) async {
    // Check for user consent before tracking
    final hasConsent = await hasAnalyticsConsent();
    if (!hasConsent) {
      print('⏭️  Analytics desativados pelo usuário - evento não registrado');
      return;
    }

    // In a real implementation, this would send the event to an analytics service
    print('📊 [ANALYTICS] Evento rastreado: $eventName');
    properties.forEach((key, value) {
      print('   - $key: $value');
    });
  }
}

/// Status do upload
enum UploadStatus {
  started,
  retrying,
  success,
  failed,
}

/// Evento de upload individual
class UploadEvent {
  String uploadId;
  String type;
  String fileName;
  int fileSizeBytes;
  DateTime startTime;
  DateTime? endTime;
  String? downloadUrl;
  Duration? totalDuration;
  int? finalSizeBytes;
  int retryAttempts;
  String? lastError;
  UploadStatus status;

  UploadEvent({
    required this.uploadId,
    required this.type,
    required this.fileName,
    required this.fileSizeBytes,
    required this.startTime,
    this.endTime,
    this.downloadUrl,
    this.totalDuration,
    this.finalSizeBytes,
    this.retryAttempts = 0,
    this.lastError,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'uploadId': uploadId,
    'type': type,
    'fileName': fileName,
    'fileSizeBytes': fileSizeBytes,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'downloadUrl': downloadUrl,
    'totalDurationMs': totalDuration?.inMilliseconds,
    'finalSizeBytes': finalSizeBytes,
    'retryAttempts': retryAttempts,
    'lastError': lastError,
    'status': status.index,
  };

  factory UploadEvent.fromJson(Map<String, dynamic> json) => UploadEvent(
    uploadId: json['uploadId'],
    type: json['type'],
    fileName: json['fileName'],
    fileSizeBytes: json['fileSizeBytes'],
    startTime: DateTime.parse(json['startTime']),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    downloadUrl: json['downloadUrl'],
    totalDuration: json['totalDurationMs'] != null ? Duration(milliseconds: json['totalDurationMs']) : null,
    finalSizeBytes: json['finalSizeBytes'],
    retryAttempts: json['retryAttempts'] ?? 0,
    lastError: json['lastError'],
    status: UploadStatus.values[json['status'] ?? 0],
  );
}

/// Estatísticas agregadas
class UploadStats {
  int totalUploads;
  int successfulUploads;
  int failedUploads;
  int totalUploadTime; // em milliseconds
  int totalBytesUploaded;
  DateTime? lastUpdated;

  UploadStats({
    this.totalUploads = 0,
    this.successfulUploads = 0,
    this.failedUploads = 0,
    this.totalUploadTime = 0,
    this.totalBytesUploaded = 0,
    this.lastUpdated,
  });

  double get successRate => totalUploads > 0 ? (successfulUploads / totalUploads) * 100 : 0;
  double get averageUploadTime => successfulUploads > 0 ? (totalUploadTime / 1000) / successfulUploads : 0;
  double get averageUploadSpeed => totalUploadTime > 0 ? (totalBytesUploaded / 1024) / (totalUploadTime / 1000) : 0;

  Map<String, dynamic> toJson() => {
    'totalUploads': totalUploads,
    'successfulUploads': successfulUploads,
    'failedUploads': failedUploads,
    'totalUploadTime': totalUploadTime,
    'totalBytesUploaded': totalBytesUploaded,
    'lastUpdated': lastUpdated?.toIso8601String(),
  };

  factory UploadStats.fromJson(Map<String, dynamic> json) => UploadStats(
    totalUploads: json['totalUploads'] ?? 0,
    successfulUploads: json['successfulUploads'] ?? 0,
    failedUploads: json['failedUploads'] ?? 0,
    totalUploadTime: json['totalUploadTime'] ?? 0,
    totalBytesUploaded: json['totalBytesUploaded'] ?? 0,
    lastUpdated: json['lastUpdated'] != null ? DateTime.parse(json['lastUpdated']) : null,
  );
}

/// Erro de upload
class UploadError {
  String uploadId;
  String errorMessage;
  DateTime timestamp;

  UploadError({
    required this.uploadId,
    required this.errorMessage,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'uploadId': uploadId,
    'errorMessage': errorMessage,
    'timestamp': timestamp.toIso8601String(),
  };

  factory UploadError.fromJson(Map<String, dynamic> json) => UploadError(
    uploadId: json['uploadId'],
    errorMessage: json['errorMessage'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}