import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Status de conectividade
enum ConnectivityStatus {
  online,
  offline,
  unstable,
  unknown,
}

/// Configuração do monitor de conectividade
class ConnectivityConfig {
  const ConnectivityConfig({
    this.heartbeatInterval = const Duration(seconds: 30),
    this.heartbeatTimeout = const Duration(seconds: 10),
    this.heartbeatUrl = 'https://www.google.com',
    this.unstableThreshold = 3,
    this.recoveryThreshold = 2,
    this.enableHeartbeat = true,
  });

  final Duration heartbeatInterval;
  final Duration heartbeatTimeout;
  final String heartbeatUrl;
  final int unstableThreshold;
  final int recoveryThreshold;
  final bool enableHeartbeat;
}

/// Evento de mudança de conectividade
class ConnectivityEvent {
  const ConnectivityEvent({
    required this.status,
    required this.timestamp,
    this.previousStatus,
    this.latency,
    this.error,
  });

  final ConnectivityStatus status;
  final ConnectivityStatus? previousStatus;
  final DateTime timestamp;
  final Duration? latency;
  final String? error;

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'previousStatus': previousStatus?.name,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'latency': latency?.inMilliseconds,
        'error': error,
      };
}

/// Estatísticas de conectividade
class ConnectivityStats {
  ConnectivityStats({
    this.totalChecks = 0,
    this.successfulChecks = 0,
    this.failedChecks = 0,
    this.averageLatency = Duration.zero,
    this.uptime = Duration.zero,
    this.downtime = Duration.zero,
  });

  int totalChecks;
  int successfulChecks;
  int failedChecks;
  Duration averageLatency;
  Duration uptime;
  Duration downtime;

  double get successRate => totalChecks > 0 ? successfulChecks / totalChecks : 0.0;
  double get failureRate => totalChecks > 0 ? failedChecks / totalChecks : 0.0;

  Map<String, dynamic> toJson() => {
        'totalChecks': totalChecks,
        'successfulChecks': successfulChecks,
        'failedChecks': failedChecks,
        'successRate': successRate,
        'failureRate': failureRate,
        'averageLatency': averageLatency.inMilliseconds,
        'uptime': uptime.inMilliseconds,
        'downtime': downtime.inMilliseconds,
      };
}

/// Monitor de conectividade com heartbeat
class ConnectivityMonitor {
  ConnectivityMonitor({
    ConnectivityConfig config = const ConnectivityConfig(),
  }) : _config = config,
       _stats = ConnectivityStats();

  final ConnectivityConfig _config;
  final ConnectivityStats _stats;
  
  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;
  Timer? _heartbeatTimer;
  
  final StreamController<ConnectivityEvent> _eventController = 
      StreamController<ConnectivityEvent>.broadcast();
  
  int _consecutiveFailures = 0;
  int _consecutiveSuccesses = 0;
  DateTime? _lastStatusChange;
  final List<Duration> _latencyHistory = [];

  static ConnectivityMonitor? _instance;
  static ConnectivityMonitor get instance {
    _instance ??= ConnectivityMonitor();
    return _instance!;
  }

  /// Status atual de conectividade
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Stream de eventos de conectividade
  Stream<ConnectivityEvent> get onConnectivityChanged => _eventController.stream;

  /// Verifica se está online
  bool get isOnline => _currentStatus == ConnectivityStatus.online;

  /// Verifica se está offline
  bool get isOffline => _currentStatus == ConnectivityStatus.offline;

  /// Verifica se a conexão está instável
  bool get isUnstable => _currentStatus == ConnectivityStatus.unstable;

  /// Inicializa o monitor
  Future<void> initialize() async {
    // Verifica status inicial
    await _checkConnectivity();

    // Inicia heartbeat se habilitado
    if (_config.enableHeartbeat) {
      _startHeartbeat();
    }
  }

  /// Para o monitor
  void dispose() {
    _heartbeatTimer?.cancel();
    _eventController.close();
  }

  /// Força verificação de conectividade
  Future<ConnectivityStatus> checkConnectivity() async {
    return await _checkConnectivity();
  }

  /// Obtém estatísticas
  ConnectivityStats getStats() => _stats;

  /// Verifica conectividade com heartbeat
  Future<ConnectivityStatus> _checkConnectivity() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      _stats.totalChecks++;
      
      // Faz ping para verificar conectividade real
      if (_config.enableHeartbeat) {
        final client = HttpClient();
        client.connectionTimeout = _config.heartbeatTimeout;
        
        try {
          final request = await client.getUrl(Uri.parse(_config.heartbeatUrl));
          final response = await request.close().timeout(_config.heartbeatTimeout);
          
          stopwatch.stop();
          final latency = stopwatch.elapsed;
          
          await response.drain();
          client.close();
          
          if (response.statusCode == 200) {
            _stats.successfulChecks++;
            _consecutiveFailures = 0;
            _consecutiveSuccesses++;
            
            // Atualiza histórico de latência
            _latencyHistory.add(latency);
            if (_latencyHistory.length > 10) {
              _latencyHistory.removeAt(0);
            }
            
            // Calcula latência média
            final totalLatency = _latencyHistory.fold<int>(
              0, (sum, lat) => sum + lat.inMilliseconds,
            );
            _stats.averageLatency = Duration(
              milliseconds: totalLatency ~/ _latencyHistory.length,
            );
            
            // Determina se a conexão se recuperou
            if (_consecutiveSuccesses >= _config.recoveryThreshold) {
              return _updateStatus(ConnectivityStatus.online, latency);
            } else if (_currentStatus == ConnectivityStatus.unstable) {
              return _currentStatus; // Mantém instável até recuperar completamente
            } else {
              return _updateStatus(ConnectivityStatus.online, latency);
            }
          } else {
            throw HttpException('HTTP ${response.statusCode}');
          }
        } catch (e) {
          client.close();
          throw e;
        }
      } else {
        // Sem heartbeat, faz uma verificação simples
        try {
          final result = await InternetAddress.lookup('google.com');
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            return _updateStatus(ConnectivityStatus.online);
          }
        } catch (e) {
           return _updateStatus(ConnectivityStatus.offline, null, e.toString());
         }
         return _updateStatus(ConnectivityStatus.offline, null, 'Unable to verify connectivity');
       }
    } catch (e) {
      stopwatch.stop();
      _stats.failedChecks++;
      _consecutiveSuccesses = 0;
      _consecutiveFailures++;
      
      // Determina status baseado em falhas consecutivas
      if (_consecutiveFailures >= _config.unstableThreshold) {
        return _updateStatus(ConnectivityStatus.offline, null, e.toString());
      } else {
        return _updateStatus(ConnectivityStatus.unstable, null, e.toString());
      }
    }
  }

  /// Atualiza status e emite evento
  ConnectivityStatus _updateStatus(
    ConnectivityStatus newStatus, [
    Duration? latency,
    String? error,
  ]) {
    final previousStatus = _currentStatus;
    
    if (newStatus != _currentStatus) {
      // Atualiza estatísticas de tempo
      final now = DateTime.now();
      if (_lastStatusChange != null) {
        final duration = now.difference(_lastStatusChange!);
        if (_currentStatus == ConnectivityStatus.online) {
          _stats.uptime = _stats.uptime + duration;
        } else {
          _stats.downtime = _stats.downtime + duration;
        }
      }
      
      _currentStatus = newStatus;
      _lastStatusChange = now;
      
      // Emite evento
      final event = ConnectivityEvent(
        status: newStatus,
        previousStatus: previousStatus,
        timestamp: now,
        latency: latency,
        error: error,
      );
      
      _eventController.add(event);
      
      if (kDebugMode) {
        debugPrint('🌐 Conectividade: ${previousStatus.name} → ${newStatus.name}');
        if (latency != null) {
          debugPrint('📊 Latência: ${latency.inMilliseconds}ms');
        }
        if (error != null) {
          debugPrint('❌ Erro: $error');
        }
      }
    }
    
    return newStatus;
  }



  /// Inicia heartbeat periódico
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      _config.heartbeatInterval,
      (_) => _checkConnectivity(),
    );
  }

  /// Para heartbeat
  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
  }

  /// Reinicia heartbeat
  void restartHeartbeat() {
    if (_config.enableHeartbeat) {
      _startHeartbeat();
    }
  }
}

/// Extensão para facilitar uso do monitor
extension ConnectivityExtension<T> on Future<T> {
  /// Executa apenas se estiver online
  Future<T?> onlyIfOnline() async {
    if (ConnectivityMonitor.instance.isOnline) {
      return await this;
    }
    return null;
  }

  /// Executa com fallback se offline
  Future<T> withOfflineFallback(T Function() fallback) async {
    if (ConnectivityMonitor.instance.isOffline) {
      return fallback();
    }
    return await this;
  }

  /// Aguarda conectividade antes de executar
  Future<T> waitForConnectivity({
    Duration timeout = const Duration(minutes: 1),
  }) async {
    if (ConnectivityMonitor.instance.isOnline) {
      return await this;
    }

    final completer = Completer<T>();
    late StreamSubscription subscription;
    
    subscription = ConnectivityMonitor.instance.onConnectivityChanged.listen(
      (event) {
        if (event.status == ConnectivityStatus.online) {
          subscription.cancel();
          this.then(completer.complete).catchError(completer.completeError);
        }
      },
    );

    // Timeout
    Timer(timeout, () {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.completeError(
          TimeoutException('Timeout waiting for connectivity', timeout),
        );
      }
    });

    return completer.future;
  }
}