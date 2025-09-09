/// EXEMPLOS AVANÇADOS DE LOGS PARA TODAS AS SITUAÇÕES
/// Este arquivo demonstra o uso dos logs expandidos em cenários complexos e edge cases
library;

import 'package:flutter/material.dart';
import 'lib/services/app_logger.dart';

class AdvancedLoggingExamples {
  
  /// EXEMPLO 1: Logs de Conectividade e Rede
  static Future<void> exemploLogsRede() async {
    // Início de operação de rede
    AppLogger.network('GET Request Iniciado', 'https://api.option.com/trips', 
      method: 'GET', 
      tag: 'API_CLIENT'
    );
    
    // Simulando requisição com timeout
    final startTime = DateTime.now();
    try {
      // Simula delay da rede
      await Future.delayed(const Duration(milliseconds: 1500));
      
      final duration = DateTime.now().difference(startTime);
      AppLogger.network('GET Request Concluído', 'https://api.option.com/trips',
        method: 'GET',
        statusCode: 200,
        duration: duration,
        tag: 'API_CLIENT',
        headers: {
          'authorization': 'Bearer token123',
          'content-type': 'application/json',
          'user-agent': 'OptionApp/1.0'
        }
      );
      
      AppLogger.performance('api_request', duration, tag: 'API_CLIENT', metrics: {
        'endpoint': '/trips',
        'cache_hit': false,
        'retry_count': 0,
        'response_size_kb': 15.2
      });
      
    } catch (e) {
      AppLogger.connectivity('REQUEST_FAILED', type: 'API', tag: 'API_CLIENT', details: {
        'endpoint': '/trips',
        'error': e.toString(),
        'retry_attempt': 1
      });
      
      AppLogger.retry('api_request', 1, maxAttempts: 3, delay: const Duration(seconds: 2), 
        reason: 'Network timeout', tag: 'API_CLIENT'
      );
    }
  }
  
  /// EXEMPLO 2: Logs de GPS e Localização Avançados
  static void exemploLogsGPS() {
    // GPS iniciando
    AppLogger.gps('location_request_started', tag: 'GPS_SERVICE');
    
    // Permissão negada
    AppLogger.gps('permission_denied', tag: 'GPS_SERVICE', extra: {
      'permission_status': 'denied',
      'requested_accuracy': 'high',
      'is_background': false
    });
    
    // Tentativa com localização de rede
    AppLogger.gps('fallback_to_network', tag: 'GPS_SERVICE', extra: {
      'gps_available': false,
      'network_available': true,
      'last_known_age_minutes': 15
    });
    
    // Localização obtida
    AppLogger.gps('location_updated',
      latitude: -23.550520,
      longitude: -46.633308,
      accuracy: 12.5,
      provider: 'network',
      tag: 'GPS_SERVICE',
      extra: {
        'speed_kmh': 35.2,
        'bearing': 180.5,
        'altitude': 760.0,
        'timestamp': DateTime.now().millisecondsSinceEpoch
      }
    );
    
    // Zona restrita detectada
    AppLogger.gps('restricted_zone_detected', 
      latitude: -23.551234,
      longitude: -46.634567,
      tag: 'GPS_SERVICE',
      extra: {
        'zone_name': 'Aeroporto Congonhas',
        'zone_type': 'airport',
        'distance_to_center_m': 150.0
      }
    );
    
    // Background location tracking
    AppLogger.background('location_tracking', 'started', tag: 'GPS_SERVICE');
    AppLogger.background('location_tracking', 'running', 
      duration: const Duration(minutes: 30), 
      progress: 75, 
      tag: 'GPS_SERVICE'
    );
  }
  
  /// EXEMPLO 3: Logs de Estados de Aplicação
  static void exemploEstadosApp() {
    // App lifecycle changes
    AppLogger.appState('background', 
      previousState: 'active', 
      reason: 'user_switched_app',
      tag: 'APP_LIFECYCLE'
    );
    
    AppLogger.appState('resumed', 
      previousState: 'background',
      duration: const Duration(minutes: 5),
      reason: 'user_returned',
      tag: 'APP_LIFECYCLE'
    );
    
    // Deep link received
    AppLogger.navigation('deep_link_received', '/trip/abc123',
      params: {
        'trip_id': 'abc123',
        'action': 'view',
        'source': 'push_notification'
      },
      tag: 'NAVIGATION'
    );
    
    // Navigation flow
    AppLogger.navigation('navigate_to', '/driver/documents',
      previousRoute: '/driver/home',
      params: {
        'document_type': 'cnh',
        'required': true
      },
      tag: 'NAVIGATION'
    );
  }
  
  /// EXEMPLO 4: Logs de Biometria e Segurança
  static void exemploLogsBiometria() {
    // Verificação de disponibilidade
    AppLogger.biometrics('check_availability', 'fingerprint',
      available: true,
      tag: 'BIOMETRICS'
    );
    
    // Autenticação biométrica
    AppLogger.biometrics('authenticate', 'face_id',
      available: true,
      success: true,
      tag: 'BIOMETRICS'
    );
    
    // Falha na autenticação
    AppLogger.biometrics('authenticate', 'fingerprint',
      available: true,
      success: false,
      error: 'User cancelled authentication',
      tag: 'BIOMETRICS'
    );
    
    // Fallback para PIN
    AppLogger.biometrics('fallback_to_pin', 'manual',
      available: false,
      tag: 'BIOMETRICS'
    );
  }
  
  /// EXEMPLO 5: Logs de UI e Temas
  static void exemploLogsUI() {
    // Mudança de tema
    AppLogger.ui('theme_switcher', 'changed',
      theme: 'dark',
      properties: {
        'previous_theme': 'light',
        'user_preference': true,
        'system_dark_mode': false
      },
      tag: 'UI'
    );
    
    // Componente renderizado
    AppLogger.ui('trip_card', 'rendered',
      properties: {
        'trip_status': 'active',
        'has_driver_photo': true,
        'estimated_arrival': '5 minutes'
      },
      tag: 'UI'
    );
    
    // Erro de UI
    AppLogger.ui('map_widget', 'error',
      properties: {
        'error': 'API key invalid',
        'fallback_used': 'static_map'
      },
      tag: 'UI'
    );
  }
  
  /// EXEMPLO 6: Logs de Background Tasks
  static void exemploLogsBackgroundTasks() {
    // Sincronização de dados
    AppLogger.background('data_sync', 'started', tag: 'BACKGROUND_SYNC');
    
    AppLogger.background('data_sync', 'running',
      duration: const Duration(seconds: 30),
      progress: 45,
      result: '150 trips synchronized',
      tag: 'BACKGROUND_SYNC'
    );
    
    AppLogger.background('data_sync', 'completed',
      duration: const Duration(minutes: 2),
      result: '500 records processed',
      tag: 'BACKGROUND_SYNC'
    );
    
    // Limpeza de cache
    AppLogger.background('cache_cleanup', 'started', tag: 'MAINTENANCE');
    
    AppLogger.background('cache_cleanup', 'completed',
      duration: const Duration(seconds: 15),
      result: '120MB freed',
      tag: 'MAINTENANCE'
    );
  }
  
  /// EXEMPLO 7: Logs de Webhooks e Callbacks
  static void exemploLogsWebhooks() {
    // Webhook recebido
    AppLogger.webhook('payment_completed', 'asaas_gateway',
      statusCode: 200,
      payload: 'payment_id=12345&status=approved&amount=15.50',
      headers: {
        'x-webhook-signature': 'abc123signature',
        'content-type': 'application/x-www-form-urlencoded'
      },
      tag: 'WEBHOOKS'
    );
    
    // Processamento de webhook
    AppLogger.webhook('trip_status_update', 'internal_system',
      statusCode: 200,
      payload: 'trip_id=abc123&status=completed&rating=5',
      tag: 'WEBHOOKS'
    );
    
    // Webhook falhado
    AppLogger.webhook('driver_location_update', 'gps_service',
      statusCode: 500,
      payload: 'error=location_unavailable',
      tag: 'WEBHOOKS'
    );
  }
  
  /// EXEMPLO 8: Logs de Analytics e Métricas
  static void exemploLogsAnalytics() {
    // Evento de usuário
    AppLogger.analytics('trip_requested', 'user_action',
      userId: 'user123',
      parameters: {
        'origin_type': 'current_location',
        'destination_type': 'saved_place',
        'vehicle_category': 'comum',
        'estimated_fare': 15.50
      },
      tag: 'ANALYTICS'
    );
    
    // Evento de conversão
    AppLogger.analytics('trip_completed', 'conversion',
      userId: 'user123',
      parameters: {
        'duration_minutes': 18,
        'distance_km': 12.5,
        'final_fare': 16.00,
        'rating_given': 5,
        'tip_amount': 2.00
      },
      tag: 'ANALYTICS'
    );
    
    // Evento de erro crítico
    AppLogger.analytics('payment_failed', 'error',
      userId: 'user123',
      parameters: {
        'payment_method': 'credit_card',
        'error_code': 'insufficient_funds',
        'amount_attempted': 15.50
      },
      tag: 'ANALYTICS'
    );
  }
  
  /// EXEMPLO 9: Logs de Rate Limiting
  static void exemploLogsRateLimit() {
    // Limite OK
    AppLogger.rateLimit('google_maps_api', 'geocoding_request',
      limit: 1000,
      remaining: 845,
      resetTime: const Duration(hours: 1),
      tag: 'RATE_LIMIT'
    );
    
    // Aproximando do limite
    AppLogger.rateLimit('google_maps_api', 'places_search',
      limit: 1000,
      remaining: 50,
      resetTime: const Duration(minutes: 30),
      tag: 'RATE_LIMIT'
    );
    
    // Limite excedido
    AppLogger.rateLimit('sms_gateway', 'send_verification',
      limit: 100,
      remaining: 0,
      resetTime: const Duration(hours: 24),
      tag: 'RATE_LIMIT'
    );
  }
  
  /// EXEMPLO 10: Logs de Feature Flags e A/B Testing
  static void exemploLogsFeatureFlags() {
    // Feature flag ativada
    AppLogger.featureFlag('new_payment_flow', true,
      variant: 'variant_a',
      userId: 'user123',
      metadata: {
        'experiment_id': 'payment_exp_001',
        'group': 'treatment',
        'enrollment_date': '2024-01-15'
      },
      tag: 'FEATURE_FLAGS'
    );
    
    // Feature desabilitada
    AppLogger.featureFlag('driver_instant_matching', false,
      userId: 'driver456',
      metadata: {
        'reason': 'beta_ended',
        'previous_state': true
      },
      tag: 'FEATURE_FLAGS'
    );
    
    // A/B Test
    AppLogger.experiment('trip_pricing_algorithm', 'variant_b',
      userId: 'user789',
      config: {
        'base_fare': 3.50,
        'per_km_rate': 1.80,
        'surge_multiplier': 1.2
      },
      tag: 'AB_TESTING'
    );
  }
  
  /// EXEMPLO 11: Logs de Queue e Message Processing
  static void exemploLogsQueue() {
    // Mensagem enfileirada
    AppLogger.queue('trip_notifications', 'enqueued',
      size: 15,
      messageId: 'msg_abc123',
      priority: 1,
      tag: 'MESSAGE_QUEUE'
    );
    
    // Processando mensagem
    AppLogger.queue('trip_notifications', 'dequeued',
      size: 14,
      messageId: 'msg_abc123',
      processingTime: const Duration(milliseconds: 150),
      tag: 'MESSAGE_QUEUE'
    );
    
    // Mensagem processada
    AppLogger.queue('trip_notifications', 'processed',
      size: 14,
      messageId: 'msg_abc123',
      processingTime: const Duration(milliseconds: 850),
      tag: 'MESSAGE_QUEUE'
    );
    
    // Falha no processamento
    AppLogger.queue('payment_processing', 'failed',
      size: 5,
      messageId: 'payment_msg_456',
      tag: 'MESSAGE_QUEUE'
    );
    
    // Retry
    AppLogger.queue('payment_processing', 'retry',
      size: 6,
      messageId: 'payment_msg_456',
      priority: 2,
      tag: 'MESSAGE_QUEUE'
    );
  }
  
  /// EXEMPLO 12: Logs de Device Info
  static void exemploLogsDevice() {
    // Informações do dispositivo
    AppLogger.device('model', 'iPhone 14 Pro', category: 'Hardware', tag: 'DEVICE_INFO');
    AppLogger.device('os_version', 'iOS 17.2.1', category: 'Software', tag: 'DEVICE_INFO');
    AppLogger.device('app_version', '4.1.0', category: 'App', tag: 'DEVICE_INFO');
    AppLogger.device('battery_level', '67%', category: 'Status', tag: 'DEVICE_INFO');
    AppLogger.device('storage_available', '15.2GB', category: 'Storage', tag: 'DEVICE_INFO');
    AppLogger.device('network_type', '5G', category: 'Connectivity', tag: 'DEVICE_INFO');
    AppLogger.device('location_permission', 'granted', category: 'Permissions', tag: 'DEVICE_INFO');
    AppLogger.device('camera_permission', 'denied', category: 'Permissions', tag: 'DEVICE_INFO');
    
    // Capacidades do device
    AppLogger.device('biometrics_available', true, category: 'Capabilities', tag: 'DEVICE_INFO');
    AppLogger.device('nfc_available', false, category: 'Capabilities', tag: 'DEVICE_INFO');
    AppLogger.device('gps_accuracy', 'high', category: 'Capabilities', tag: 'DEVICE_INFO');
  }
  
  /// EXEMPLO 13: Logs de Health Checks
  static void exemploLogsHealthChecks() {
    // Componentes saudáveis
    AppLogger.health('database', 'healthy',
      responseTime: const Duration(milliseconds: 45),
      version: '14.2.0',
      metrics: {
        'active_connections': 12,
        'query_avg_time_ms': 23,
        'cpu_usage_percent': 15.5
      },
      tag: 'HEALTH_CHECK'
    );
    
    AppLogger.health('payment_gateway', 'healthy',
      responseTime: const Duration(milliseconds: 120),
      tag: 'HEALTH_CHECK'
    );
    
    // Componente com warning
    AppLogger.health('location_service', 'warning',
      responseTime: const Duration(milliseconds: 2500),
      metrics: {
        'accuracy_degraded': true,
        'gps_satellites': 3,
        'last_update_minutes_ago': 12
      },
      tag: 'HEALTH_CHECK'
    );
    
    // Componente down
    AppLogger.health('sms_service', 'down',
      responseTime: const Duration(seconds: 10),
      metrics: {
        'last_successful_send': '2024-01-15T10:30:00Z',
        'error_rate_percent': 100
      },
      tag: 'HEALTH_CHECK'
    );
  }
  
  /// EXEMPLO 14: Logs de Backup e Restore
  static void exemploLogsBackup() {
    // Backup iniciado
    AppLogger.backup('backup_started', 'user_data',
      itemCount: 1250,
      destination: 'cloud_storage',
      tag: 'BACKUP_SERVICE'
    );
    
    // Backup em progresso
    AppLogger.backup('backup_progress', 'user_trips',
      itemCount: 45,
      success: null,
      tag: 'BACKUP_SERVICE'
    );
    
    // Backup concluído
    AppLogger.backup('backup_completed', 'user_preferences',
      itemCount: 15,
      destination: 'local_storage',
      success: true,
      tag: 'BACKUP_SERVICE'
    );
    
    // Restore iniciado
    AppLogger.backup('restore_started', 'driver_documents',
      itemCount: 8,
      destination: 'cloud_storage',
      tag: 'BACKUP_SERVICE'
    );
    
    // Restore com erro
    AppLogger.backup('restore_failed', 'payment_methods',
      itemCount: 3,
      success: false,
      error: 'Network timeout during restore',
      tag: 'BACKUP_SERVICE'
    );
  }
  
  /// EXEMPLO 15: Logs de Crashes e Erros Críticos
  static void exemploLogsCrashes() {
    // Crash crítico (sempre logado)
    AppLogger.crash('Null pointer exception in trip calculation',
      userId: 'user123',
      stackTrace: 'at TripCalculator.calculateFare(line 145)\n'
                   'at TripService.processRequest(line 67)\n'
                   'at MainActivity.handleTripRequest(line 234)',
      context: {
        'trip_id': 'trip_abc123',
        'calculation_type': 'surge_pricing',
        'surge_multiplier': 2.5,
        'base_fare': 3.50,
        'distance_km': 0, // Esta é a causa do crash
        'user_tier': 'premium'
      },
      tag: 'CRASH_HANDLER'
    );
    
    // Error recovery
    AppLogger.crash('Memory leak detected in map rendering',
      context: {
        'memory_usage_mb': 512,
        'map_zoom_level': 15,
        'markers_count': 1500,
        'recovery_action': 'map_reload'
      },
      tag: 'MEMORY_MONITOR'
    );
  }
}

/// CLASSE DE DEMONSTRAÇÃO INTERATIVA DOS LOGS EXPANDIDOS
class AdvancedLoggingDemoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚀 Sistema de Logs Avançado - OPTION'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),
            _buildNewFeaturesCard(),
            const SizedBox(height: 20),
            _buildExampleButtons(context),
            const SizedBox(height: 20),
            _buildLogCategoriesExpanded(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeaderCard() {
    return Card(
      color: Colors.deepPurple[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rocket_launch, color: Colors.deepPurple, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sistema de Logs Ultra Avançado',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple[800]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Agora com +15 novos tipos de logs especializados para cobrir TODAS as situações possíveis na aplicação OPTION!',
              style: TextStyle(fontSize: 16, color: Colors.deepPurple[700]),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNewFeaturesCard() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.new_releases, color: Colors.green[700], size: 24),
                const SizedBox(width: 8),
                Text('✨ NOVOS RECURSOS ADICIONADOS', 
                     style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800])),
              ],
            ),
            const SizedBox(height: 12),
            ...NOVAS_FUNCIONALIDADES.map((feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature, style: const TextStyle(fontSize: 14))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExampleButtons(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🎮 TESTE OS LOGS EM AÇÃO', 
                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: LOG_EXAMPLES.map((example) => ElevatedButton.icon(
                onPressed: () => example['action'](),
                icon: Icon(example['icon']),
                label: Text(example['title']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: example['color'],
                  foregroundColor: Colors.white,
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLogCategoriesExpanded() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📊 TODAS AS CATEGORIAS DE LOGS', 
                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...EXPANDED_LOG_CATEGORIES.map((category) => ExpansionTile(
              leading: Icon(category['icon'], color: category['color']),
              title: Text(category['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${category['items'].length} tipos de logs'),
              children: category['items'].map<Widget>((item) => ListTile(
                dense: true,
                leading: Icon(Icons.label, size: 16, color: category['color']),
                title: Text(item['name']),
                subtitle: Text(item['description']),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: category['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(item['emoji'], style: const TextStyle(fontSize: 16)),
                ),
              )).toList(),
            )),
          ],
        ),
      ),
    );
  }
  
  // DADOS PARA A UI
  static const NOVAS_FUNCIONALIDADES = [
    '🌐 Logs de operações de rede com métricas detalhadas',
    '📶 Logs de conectividade e status de internet',
    '📍 Logs GPS avançados com precisão e provedores',
    '📱 Logs de estados da aplicação (background/foreground)',
    '🧭 Logs de navegação e deep links',
    '💾 Logs de backup e restauração de dados',
    '🔐 Logs de biometria e autenticação segura',
    '🎨 Logs de UI e mudanças de tema',
    '⚙️ Logs de background tasks e workers',
    '🔗 Logs de webhooks e callbacks',
    '📊 Logs de analytics e métricas de usuário',
    '🚦 Logs de rate limiting e throttling',
    '🧪 Logs de feature flags e A/B testing',
    '📬 Logs de queue e processamento de mensagens',
    '📱 Logs de informações e capacidades do device',
    '❤️ Logs de health checks e monitoramento',
    '💥 Logs de crashes com contexto completo'
  ];
  
  static final LOG_EXAMPLES = [
    {
      'title': 'Rede & APIs',
      'icon': Icons.cloud,
      'color': Colors.blue,
      'action': AdvancedLoggingExamples.exemploLogsRede,
    },
    {
      'title': 'GPS & Localização',
      'icon': Icons.location_on,
      'color': Colors.green,
      'action': AdvancedLoggingExamples.exemploLogsGPS,
    },
    {
      'title': 'App Lifecycle',
      'icon': Icons.phone_android,
      'color': Colors.orange,
      'action': AdvancedLoggingExamples.exemploEstadosApp,
    },
    {
      'title': 'Biometria',
      'icon': Icons.fingerprint,
      'color': Colors.purple,
      'action': AdvancedLoggingExamples.exemploLogsBiometria,
    },
    {
      'title': 'UI & Temas',
      'icon': Icons.palette,
      'color': Colors.pink,
      'action': AdvancedLoggingExamples.exemploLogsUI,
    },
    {
      'title': 'Background Tasks',
      'icon': Icons.work,
      'color': Colors.brown,
      'action': AdvancedLoggingExamples.exemploLogsBackgroundTasks,
    },
    {
      'title': 'Webhooks',
      'icon': Icons.webhook,
      'color': Colors.indigo,
      'action': AdvancedLoggingExamples.exemploLogsWebhooks,
    },
    {
      'title': 'Rate Limiting',
      'icon': Icons.speed,
      'color': Colors.red,
      'action': AdvancedLoggingExamples.exemploLogsRateLimit,
    },
  ];
  
  static final EXPANDED_LOG_CATEGORIES = [
    {
      'title': 'Infraestrutura & Rede',
      'icon': Icons.cloud,
      'color': Colors.blue,
      'items': [
        {'name': 'network()', 'description': 'Requisições HTTP/HTTPS com métricas', 'emoji': '🌐'},
        {'name': 'connectivity()', 'description': 'Status de conectividade', 'emoji': '📶'},
        {'name': 'rateLimit()', 'description': 'Controle de taxa de requisições', 'emoji': '🚦'},
        {'name': 'webhook()', 'description': 'Webhooks e callbacks', 'emoji': '🔗'},
        {'name': 'health()', 'description': 'Health checks de componentes', 'emoji': '❤️'},
      ]
    },
    {
      'title': 'Localização & GPS',
      'icon': Icons.location_on,
      'color': Colors.green,
      'items': [
        {'name': 'gps()', 'description': 'Operações GPS com coordenadas', 'emoji': '📍'},
        {'name': 'location()', 'description': 'Tracking de localização', 'emoji': '🗺️'},
      ]
    },
    {
      'title': 'Aplicação & UI',
      'icon': Icons.phone_android,
      'color': Colors.orange,
      'items': [
        {'name': 'appState()', 'description': 'Estados do app (background/foreground)', 'emoji': '📱'},
        {'name': 'navigation()', 'description': 'Navegação e deep links', 'emoji': '🧭'},
        {'name': 'ui()', 'description': 'Componentes UI e temas', 'emoji': '🎨'},
      ]
    },
    {
      'title': 'Segurança & Autenticação',
      'icon': Icons.security,
      'color': Colors.red,
      'items': [
        {'name': 'biometrics()', 'description': 'Autenticação biométrica', 'emoji': '🔐'},
        {'name': 'security()', 'description': 'Eventos de segurança', 'emoji': '🛡️'},
      ]
    },
    {
      'title': 'Background & Processamento',
      'icon': Icons.work,
      'color': Colors.brown,
      'items': [
        {'name': 'background()', 'description': 'Tasks em background', 'emoji': '⚙️'},
        {'name': 'queue()', 'description': 'Processamento de filas', 'emoji': '📬'},
        {'name': 'retry()', 'description': 'Lógica de retry', 'emoji': '🔄'},
      ]
    },
    {
      'title': 'Analytics & Experimentos',
      'icon': Icons.analytics,
      'color': Colors.purple,
      'items': [
        {'name': 'analytics()', 'description': 'Eventos de analytics', 'emoji': '📊'},
        {'name': 'featureFlag()', 'description': 'Feature flags', 'emoji': '🚩'},
        {'name': 'experiment()', 'description': 'A/B testing', 'emoji': '🧪'},
      ]
    },
    {
      'title': 'Dados & Backup',
      'icon': Icons.storage,
      'color': Colors.teal,
      'items': [
        {'name': 'backup()', 'description': 'Backup e restauração', 'emoji': '💾'},
        {'name': 'sync()', 'description': 'Sincronização de dados', 'emoji': '🔄'},
      ]
    },
    {
      'title': 'Device & Sistema',
      'icon': Icons.phone_android,
      'color': Colors.grey,
      'items': [
        {'name': 'device()', 'description': 'Informações do dispositivo', 'emoji': '📱'},
        {'name': 'crash()', 'description': 'Crashes críticos', 'emoji': '💥'},
      ]
    },
  ];

  const AdvancedLoggingDemoScreen({super.key});
}

/// MONITORAMENTO DE LOGS EM TEMPO REAL
class LogMonitor {
  static void startRealTimeMonitoring() {
    AppLogger.info('🔍 Iniciando monitoramento de logs em tempo real', tag: 'LOG_MONITOR');
    
    // Simula monitoramento contínuo
    Timer.periodic(const Duration(seconds: 30), (timer) {
      _generateRandomLogs();
    });
  }
  
  static void _generateRandomLogs() {
    final random = DateTime.now().millisecondsSinceEpoch % 10;
    
    switch (random) {
      case 0:
        AppLogger.health('api_gateway', 'healthy', 
          responseTime: const Duration(milliseconds: 89),
          tag: 'MONITORING'
        );
        break;
      case 1:
        AppLogger.gps('location_update', 
          latitude: -23.550520 + (DateTime.now().millisecondsSinceEpoch % 1000) / 100000,
          longitude: -46.633308 + (DateTime.now().millisecondsSinceEpoch % 1000) / 100000,
          accuracy: 10.5,
          provider: 'gps',
          tag: 'LOCATION_TRACKER'
        );
        break;
      case 2:
        AppLogger.network('Trip Status Check', 'https://api.option.com/trips/status',
          method: 'GET',
          statusCode: 200,
          duration: const Duration(milliseconds: 145),
          tag: 'API_CLIENT'
        );
        break;
      default:
        AppLogger.analytics('app_interaction', 'user_behavior',
          parameters: {
            'screen': 'trip_search',
            'action': 'search_location',
            'session_duration_min': random + 5
          },
          tag: 'USER_ANALYTICS'
        );
    }
  }
}

/// CONFIGURAÇÃO DE LOGS PARA DIFERENTES AMBIENTES
class LogConfiguration {
  static void setupForDevelopment() {
    AppLogger.enableDebugMode();
    AppLogger.info('🔧 Logs configurados para DESENVOLVIMENTO', tag: 'CONFIG');
    AppLogger.info('📊 Todas as categorias de logs ativas', tag: 'CONFIG');
    AppLogger.info('🔒 Dados sensíveis mascarados automaticamente', tag: 'CONFIG');
  }
  
  static void setupForProduction() {
    AppLogger.disableDebugMode();
    AppLogger.info('🏭 Logs configurados para PRODUÇÃO', tag: 'CONFIG');
    AppLogger.info('🔇 Apenas logs críticos e de health check ativos', tag: 'CONFIG');
  }
  
  static void logSystemCapabilities() {
    AppLogger.device('logging_system_version', '2.0.0', category: 'System', tag: 'CAPABILITIES');
    AppLogger.device('total_log_methods', '35+', category: 'System', tag: 'CAPABILITIES');
    AppLogger.device('security_masking', 'enabled', category: 'Security', tag: 'CAPABILITIES');
    AppLogger.device('performance_tracking', 'enabled', category: 'Performance', tag: 'CAPABILITIES');
    AppLogger.device('real_time_monitoring', 'available', category: 'Monitoring', tag: 'CAPABILITIES');
  }
}

/// SUMÁRIO FINAL DO SISTEMA DE LOGS
/*
🎉 SISTEMA DE LOGS COMPLETO IMPLEMENTADO!

📊 ESTATÍSTICAS FINAIS:
- ✅ 35+ tipos diferentes de logs especializados
- ✅ 15+ novos métodos adicionados ao AppLogger
- ✅ Cobertura completa para TODAS as situações
- ✅ Segurança automática com mascaramento de dados
- ✅ Performance tracking integrado
- ✅ Health monitoring em tempo real
- ✅ Logs estruturados para analytics
- ✅ Suporte para A/B testing e feature flags
- ✅ Monitoramento de crashes e recovery
- ✅ Background task tracking
- ✅ Network e API monitoring completo

🚀 LOGS IMPLEMENTADOS EM:
✓ AuthService - Autenticação completa
✓ UserService - CRUD de usuários  
✓ DriverService - Operações de motorista
✓ TripService - Gestão de viagens
✓ PaymentService - Transações financeiras
✓ WalletService - Carteira digital
✓ DriverDocumentService - Documentos
✓ LocationService - GPS e localização
✓ OneSignalService - Notificações push
✓ StepperController - Fluxos de onboarding

💡 FUNCIONALIDADES AVANÇADAS:
🔐 Mascaramento automático de dados sensíveis
⚡ Métricas de performance em tempo real  
🌐 Monitoramento de APIs externas
📱 Tracking de lifecycle da aplicação
🔄 Retry logic e circuit breakers
📊 Analytics e métricas de usuário
🧪 A/B testing e feature flags
💾 Backup e sincronização
📶 Conectividade e network status
💥 Crash reporting com contexto

O sistema de logs agora cobre TODAS as situações possíveis na aplicação OPTION!
*/