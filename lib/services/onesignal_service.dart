import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import 'local_notification_service.dart';

/// Serviço completo para gerenciamento de OneSignal
/// Inclui registro de tokens, envio de notificações, segmentação e histórico
class OneSignalService {
  factory OneSignalService() => _instance;
  OneSignalService._internal();
  static final OneSignalService _instance = OneSignalService._internal();

  final Logger _logger = Logger();
  final LocalNotificationService _localNotificationService = LocalNotificationService();
  
  String? _currentPlayerId;
  String? _currentPushToken;
  
  bool _isInitialized = false;
  
  // OneSignal App ID - configurar no seu dashboard
  static const String _appId = '117ec6b9-5a4b-411d-96bd-dd3eb7009600';
  
  // OneSignal REST API constants
  static const String _baseUrl = 'https://onesignal.com/api/v1';
  static const String _restApiKey = 'os_v2_app_cf7mnok2jnar3fv53u7loaewaaaxjc6lppnulmu4pjlen2vkwujlae3m2c4xioyszq7opy7vqvwlh34s5pcx4uv2vtfmrapilf7q6ni';
  
  /// Inicializa o serviço OneSignal
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Ignorar plataformas não suportadas (somente Android/iOS e Web são suportados)
      if (!kIsWeb && !(Platform.isAndroid || Platform.isIOS)) {
        _logger.w('Plataforma não suportada para OneSignal. Ignorando inicialização.');
        _isInitialized = true;
        return;
      }

      // Verificar se é plataforma web
      if (kIsWeb) {
        _logger.i('Inicializando OneSignal para plataforma web');
        // Para web, o OneSignal é inicializado via JavaScript no index.html
        // Apenas configurar handlers básicos
        await _setupWebNotificationHandlers();
      } else {
        // Habilitar debug logging ANTES da inicialização (apenas mobile)
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
        
        // Inicializar OneSignal
        OneSignal.initialize(_appId);
        
        // Solicitar permissões
        await _requestPermissions();
        
        // Configurar handlers de notificação
        await _setupNotificationHandlers();
        
        // Registrar token/player ID
        await _registerPlayerData();
        
        // Configurar listener para mudanças de ID
        _setupPlayerIdListener();
      }
      
      _isInitialized = true;
      _logger.i('OneSignalService inicializado com sucesso');
      
    } catch (e, stackTrace) {
      _logger.e('Erro ao inicializar OneSignalService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Solicita permissões necessárias para notificações
  Future<void> _requestPermissions() async {
    try {
      // Verificar se não é web antes de solicitar permissões
      if (!kIsWeb) {
        // OneSignal vai solicitar permissões automaticamente, mas podemos forçar
        await OneSignal.Notifications.requestPermission(true);
        
        // Permissões adicionais para Android
        if (Platform.isAndroid) {
          await Permission.notification.request();
        }
      }
      
      _logger.i('Permissões de notificação solicitadas');
      
    } catch (e) {
      _logger.e('Erro ao solicitar permissões', error: e);
    }
  }
  
  /// Configura handlers de notificação específicos para web
  Future<void> _setupWebNotificationHandlers() async {
    try {
      _logger.i('Configurando handlers de notificação para web');
      // Para web, as notificações são gerenciadas pelo OneSignal Web SDK
      // que foi configurado no index.html
      
      // Aguardar dados do usuário OneSignal
      _logger.i('💡 Aguardando dados do usuário OneSignal...');
      
    } catch (e) {
      _logger.e('Erro ao configurar handlers web', error: e);
    }
  }
  
  /// Configura os handlers para diferentes tipos de notificações
  Future<void> _setupNotificationHandlers() async {
    // Handler para quando notificação é recebida (em foreground)
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      _logger.i('Notificação recebida em foreground: ${event.notification.notificationId}');
      _handleForegroundNotification(event);
    });
    
    // Handler para quando notificação é clicada
    OneSignal.Notifications.addClickListener((event) {
      _logger.i('Notificação clicada: ${event.notification.notificationId}');
      _handleNotificationClick(event);
    });
    
    // Handler para mudanças na permissão
    OneSignal.Notifications.addPermissionObserver((permission) {
      _logger.i('Permissão de notificação alterada: $permission');
    });
  }
  
  /// Registra o Player ID e Push Token no Supabase
  Future<void> _registerPlayerData() async {
    try {
      // Verificar se não é web antes de acessar dados do player
      if (!kIsWeb) {
        // Usar observer para obter dados quando disponíveis
        // Os valores podem ser null se chamados antes da inicialização
        _logger.i('Aguardando dados do usuário OneSignal...');
        
        // Configurar observers para capturar dados quando disponíveis
        _setupPlayerIdListener();
        _setupPushSubscriptionListener();
      } else {
        _logger.i('Registro de dados do player ignorado na web - gerenciado pelo Web SDK');
      }
      
    } catch (e) {
      _logger.e('Erro ao registrar dados do player', error: e);
    }
  }
  
  /// Salva o Player ID no Supabase
  Future<void> _savePlayerIdToSupabase(String playerId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _logger.w('Usuário não autenticado, Player ID não salvo no Supabase');
        return;
      }
      
      final platform = Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'web';
      
      // Verificar se é motorista ou passageiro
      final driverResponse = await Supabase.instance.client
          .from('drivers')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (driverResponse != null) {
        // É um motorista
        await Supabase.instance.client
            .from('drivers')
            .update({
              'onesignal_player_id': playerId,
              'device_platform': platform,
              'token_updated_at': DateTime.now().toIso8601String(),
              'token_active': true,
            })
            .eq('user_id', user.id);
      } else {
        // É um passageiro
        await Supabase.instance.client
            .from('app_users')
            .update({
              'onesignal_player_id': playerId,
              'token_updated_at': DateTime.now().toIso8601String(),
              'token_active': true,
              'last_active_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', user.id);
      }
      
      _logger.i('Player ID salvo no Supabase com sucesso');
      
    } catch (e) {
      _logger.e('Erro ao salvar Player ID no Supabase', error: e);
    }
  }
  
  /// Salva o Push Token no Supabase
  Future<void> _savePushTokenToSupabase(String pushToken) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _logger.w('Usuário não autenticado, Push Token não salvo no Supabase');
        return;
      }
      
      // Verificar se é motorista ou passageiro
      final driverResponse = await Supabase.instance.client
          .from('drivers')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (driverResponse != null) {
        // É um motorista
        await Supabase.instance.client
            .from('drivers')
            .update({
              'push_token': pushToken,
              'token_updated_at': DateTime.now().toIso8601String(),
              'token_active': true,
            })
            .eq('user_id', user.id);
      } else {
        // É um passageiro
        await Supabase.instance.client
            .from('app_users')
            .update({
              'push_token': pushToken,
              'token_updated_at': DateTime.now().toIso8601String(),
              'token_active': true,
              'last_active_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', user.id);
      }
      
      _logger.i('Push Token salvo no Supabase com sucesso');
      
    } catch (e) {
      _logger.e('Erro ao salvar Push Token no Supabase', error: e);
    }
  }
  
  /// Salva o Player ID localmente
  Future<void> _savePlayerIdLocally(String playerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('onesignal_player_id', playerId);
      await prefs.setString('onesignal_player_id_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      _logger.e('Erro ao salvar Player ID localmente', error: e);
    }
  }
  
  /// Salva o Push Token localmente
  Future<void> _savePushTokenLocally(String pushToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('onesignal_push_token', pushToken);
      await prefs.setString('onesignal_push_token_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      _logger.e('Erro ao salvar Push Token localmente', error: e);
    }
  }
  
  /// Configura listener para mudanças no Player ID
  void _setupPlayerIdListener() {
    // Verificar se não é web antes de configurar listeners
    if (!kIsWeb) {
      OneSignal.User.addObserver((state) {
        final userState = state.jsonRepresentation();
        _logger.i('OneSignal user state changed: $userState');
        
        // Tentar obter o OneSignal ID do estado atual
        try {
          final playerId = state.current.onesignalId;
          if (playerId != null && playerId != _currentPlayerId) {
            _logger.i('Player ID atualizado: ${playerId.substring(0, 20)}...');
            _currentPlayerId = playerId;
            _savePlayerIdToSupabase(playerId);
            _savePlayerIdLocally(playerId);
          }
        } catch (e) {
          _logger.w('Erro ao obter OneSignal ID do estado: $e');
        }
      });
    }
  }
  
  /// Configura listener para mudanças na subscription de push
  void _setupPushSubscriptionListener() {
    OneSignal.User.pushSubscription.addObserver((state) {
      _logger.i('Push subscription state changed');
      _logger.i('Opted in: ${OneSignal.User.pushSubscription.optedIn}');
      _logger.i('Subscription ID: ${OneSignal.User.pushSubscription.id}');
      _logger.i('Push token: ${OneSignal.User.pushSubscription.token}');
      
      final pushToken = OneSignal.User.pushSubscription.token;
      if (pushToken != null && pushToken != _currentPushToken) {
        _logger.i('Push Token atualizado: ${pushToken.substring(0, 20)}...');
        _currentPushToken = pushToken;
        _savePushTokenToSupabase(pushToken);
        _savePushTokenLocally(pushToken);
      }
    });
  }
  
  /// Verifica se o usuário atual é motorista
  Future<bool> _isCurrentUserDriver() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;
      
      final driverResponse = await Supabase.instance.client
          .from('drivers')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();
      
      return driverResponse != null;
    } catch (e) {
      _logger.e('Erro ao verificar se usuário é motorista', error: e);
      return false;
    }
  }

  /// Manipula notificações recebidas em foreground
  Future<void> _handleForegroundNotification(OSNotificationWillDisplayEvent event) async {
    try {
      final notification = event.notification;
      
      // Registrar no histórico
      _logNotificationReceived(notification);
      
      // Verificar se é motorista
      final isDriver = await _isCurrentUserDriver();
      
      // Exibir notificação local
      _localNotificationService.showRideOfferNotification(
        title: notification.title ?? 'Nova notificação',
        body: notification.body ?? '',
        offerId: notification.additionalData?['offer_id'],
        isDriver: isDriver,
      );
      
      // Permitir que a notificação seja exibida
      event.notification.display();
      
    } catch (e) {
      _logger.e('Erro ao processar notificação em foreground', error: e);
    }
  }
  
  /// Manipula clique em notificação
  void _handleNotificationClick(OSNotificationClickEvent event) {
    try {
      final notification = event.notification;
      _logger.i('Notificação clicada: ${notification.additionalData}');
      
      // Processar ação baseada no tipo de notificação
      final notificationType = notification.additionalData?['type'];
      switch (notificationType) {
        case 'trip_request':
          _handleTripRequestNotification(notification.additionalData ?? {});
          break;
        case 'trip_update':
          _handleTripUpdateNotification(notification.additionalData ?? {});
          break;
        case 'chat_message':
          _handleChatNotification(notification.additionalData ?? {});
          break;
        default:
          _logger.w('Tipo de notificação desconhecido: $notificationType');
      }
      
    } catch (e) {
      _logger.e('Erro ao processar clique em notificação', error: e);
    }
  }
  
  /// Navega para tela de solicitações do motorista
  void _navigateToDriverRequests(BuildContext context, Map<String, dynamic> data) {
    try {
      _logger.i('Navegando para tela de solicitações do motorista');
      
      // Navegar para rota de solicitações
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/driver-requests',
        (route) => route.settings.name == '/driver-home' || route.isFirst,
      );
    } catch (e) {
      _logger.e('Erro ao navegar para solicitações: $e');
    }
  }
  
  /// Salva solicitação de navegação para execução posterior
  Future<void> _saveNavigationRequest(String route, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_navigation_route', route);
      await prefs.setString('pending_navigation_data', jsonEncode(data));
      await prefs.setString('pending_navigation_timestamp', DateTime.now().toIso8601String());
      _logger.i('Solicitação de navegação salva: $route');
    } catch (e) {
      _logger.e('Erro ao salvar solicitação de navegação: $e');
    }
  }
  
  /// Verifica e executa navegação pendente
  Future<void> checkPendingNavigation(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final route = prefs.getString('pending_navigation_route');
      final dataString = prefs.getString('pending_navigation_data');
      final timestampString = prefs.getString('pending_navigation_timestamp');
      
      if (route != null && dataString != null && timestampString != null) {
        final timestamp = DateTime.parse(timestampString);
        final now = DateTime.now();
        
        // Navegar apenas se a solicitação for recente (até 5 minutos)
        if (now.difference(timestamp).inMinutes <= 5) {
          final data = jsonDecode(dataString) as Map<String, dynamic>;
          
          switch (route) {
            case 'driver_requests':
              _navigateToDriverRequests(context, data);
              break;
            default:
              _logger.w('Rota de navegação desconhecida: $route');
          }
        }
        
        // Limpar dados de navegação pendente
        await prefs.remove('pending_navigation_route');
        await prefs.remove('pending_navigation_data');
        await prefs.remove('pending_navigation_timestamp');
      }
    } catch (e) {
      _logger.e('Erro ao verificar navegação pendente: $e');
    }
  }

  /// Manipula notificação de solicitação de viagem
  void _handleTripRequestNotification(Map<String, dynamic> data) {
    _logger.i('Processando notificação de solicitação de viagem: $data');
    
    // Tentar obter contexto do navigator global
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      _navigateToDriverRequests(context, data);
    } else {
      _logger.w('Context não disponível para navegação automática');
      // Salvar dados para navegação posterior
      _saveNavigationRequest('driver_requests', data);
    }
  }
  
  /// Manipula notificação de atualização de viagem
  void _handleTripUpdateNotification(Map<String, dynamic> data) {
    // Implementar navegação para tela de viagem ativa
    _logger.i('Processando notificação de atualização de viagem');
  }
  
  /// Manipula notificação de chat
  void _handleChatNotification(Map<String, dynamic> data) {
    // Implementar navegação para tela de chat
    _logger.i('Processando notificação de chat');
  }
  
  /// Registra notificação recebida no histórico
  Future<void> _logNotificationReceived(OSNotification notification) async {
    try {
      await Supabase.instance.client.from('notification_history').insert({
        'notification_id': notification.notificationId,
        'title': notification.title,
        'body': notification.body,
        'data': notification.additionalData,
        'received_at': DateTime.now().toIso8601String(),
        'user_id': Supabase.instance.client.auth.currentUser?.id,
        'platform': Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'web',
      });
    } catch (e) {
      _logger.e('Erro ao registrar notificação no histórico', error: e);
    }
  }
  
  /// Envia notificação para um usuário específico
  Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      // Buscar Player ID do usuário
      final playerId = await _getUserPlayerId(userId);
      if (playerId == null) {
        _logger.w('Player ID não encontrado para usuário: $userId');
        return false;
      }
      
      return await sendNotificationToPlayerId(
        playerId: playerId,
        title: title,
        body: body,
        data: data,
        imageUrl: imageUrl,
      );
      
    } catch (e) {
      _logger.e('Erro ao enviar notificação para usuário', error: e);
      return false;
    }
  }
  
  /// Valida se o Player ID tem formato válido do OneSignal
  bool _isValidPlayerId(String playerId) {
    if (playerId.isEmpty) return false;
    
    // OneSignal Player IDs são UUIDs de 36 caracteres com hífens
    // Exemplo: 12345678-1234-1234-1234-123456789012
    final playerIdRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    );
    
    return playerIdRegex.hasMatch(playerId);
  }

  /// Envia notificação para um Player ID específico usando OneSignal REST API
  Future<bool> sendNotificationToPlayerId({
    required String playerId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      // Validar Player ID primeiro
      if (!_isValidPlayerId(playerId)) {
        _logger.w('Player ID inválido: $playerId');
        return false;
      }
      
      // Preparar payload da notificação
      final payload = {
        'app_id': _appId,
        'include_player_ids': [playerId],
        'headings': {'en': title, 'pt': title},
        'contents': {'en': body, 'pt': body},
        'data': data ?? {},
      };
      
      // Adicionar imagem se fornecida
      if (imageUrl != null && imageUrl.isNotEmpty) {
        payload['large_icon'] = imageUrl;
        payload['big_picture'] = imageUrl;
      }
      
      // Configurar som personalizado para motoristas (detectado pelos dados)
      if (data != null && data['type'] == 'trip_request') {
        payload['android_sound'] = 'chegoucorridaoption';
        payload['ios_sound'] = 'chegoucorridaOption.mp3';
        payload['priority'] = 10; // Alta prioridade
        payload['android_channel_id'] = 'ride_offers';
      }
      
      _logger.i('Enviando notificação OneSignal para: ${playerId.substring(0, 8)}...');
      _logger.d('Payload: ${jsonEncode(payload)}');
      
      // Fazer chamada HTTP para OneSignal REST API
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $_restApiKey',
        },
        body: jsonEncode(payload),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final notificationId = responseData['id'];
        
        _logger.i('✅ OneSignal notification sent successfully');
        _logger.i('   Notification ID: $notificationId');
        _logger.i('   Recipients: ${responseData['recipients']}');
        
        // Registrar no histórico com sucesso
        await _logNotificationSent({
          'player_id': playerId,
          'notification_id': notificationId,
          'title': title,
          'body': body,
          'data': data ?? {},
          'image': imageUrl,
          'status': 'sent',
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        return true;
      } else {
        _logger.e('❌ OneSignal API Error: ${response.statusCode}');
        _logger.e('   Response: ${response.body}');
        
        // Registrar falha no histórico
        await _logNotificationSent({
          'player_id': playerId,
          'title': title,
          'body': body,
          'status': 'failed',
          'error': 'HTTP ${response.statusCode}: ${response.body}',
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        return false;
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Erro ao enviar notificação OneSignal', error: e, stackTrace: stackTrace);
      
      // Registrar falha no histórico
      await _logNotificationSent({
        'player_id': playerId,
        'title': title,
        'body': body,
        'status': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      return false;
    }
  }
  
  /// Busca Player ID de um usuário
  Future<String?> _getUserPlayerId(String userId) async {
    try {
      // Verificar se é motorista
      final driverResponse = await Supabase.instance.client
          .from('drivers')
          .select('onesignal_player_id')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (driverResponse != null && driverResponse['onesignal_player_id'] != null) {
        return driverResponse['onesignal_player_id'];
      }
      
      // Verificar se é passageiro
      final userResponse = await Supabase.instance.client
          .from('app_users')
          .select('onesignal_player_id')
          .eq('user_id', userId)
          .maybeSingle();
      
      return userResponse?['onesignal_player_id'];
      
    } catch (e) {
      _logger.e('Erro ao buscar Player ID do usuário', error: e);
      return null;
    }
  }
  
  /// Registra notificação enviada no histórico
  Future<void> _logNotificationSent(Map<String, dynamic> notificationData) async {
    try {
      await Supabase.instance.client.from('notification_history').insert({
        'title': notificationData['title'],
        'body': notificationData['body'],
        'data': notificationData['data'],
        'sent_at': notificationData['timestamp'],
        'sender_id': Supabase.instance.client.auth.currentUser?.id,
        'platform': 'onesignal',
        'status': notificationData['status'] ?? 'sent',
        'notification_id': notificationData['notification_id'],
        'player_id': notificationData['player_id'],
        'error_message': notificationData['error'],
      });
    } catch (e) {
      _logger.e('Erro ao registrar notificação enviada', error: e);
    }
  }
  
  /// Envia notificação para múltiplos Player IDs
  Future<bool> sendBulkNotification({
    required List<String> playerIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      if (playerIds.isEmpty) {
        _logger.w('Lista de Player IDs vazia para envio em lote');
        return false;
      }
      
      var successCount = 0;
      
      // Enviar para cada Player ID
      for (final playerId in playerIds) {
        final success = await sendNotificationToPlayerId(
          playerId: playerId,
          title: title,
          body: body,
          data: data,
          imageUrl: imageUrl,
        );
        
        if (success) successCount++;
      }
      
      _logger.i('Notificações em lote enviadas: $successCount/${playerIds.length}');
      return successCount > 0;
      
    } catch (e) {
      _logger.e('Erro ao enviar notificações em lote', error: e);
      return false;
    }
  }
  
  /// Define tags para segmentação
  Future<void> setUserTags(Map<String, dynamic> tags) async {
    try {
      OneSignal.User.addTags(tags);
      _logger.i('Tags do usuário definidas: $tags');
    } catch (e) {
      _logger.e('Erro ao definir tags do usuário', error: e);
    }
  }
  
  /// Define email para segmentação
  Future<void> setUserEmail(String email) async {
    try {
      OneSignal.User.addEmail(email);
      _logger.i('Email do usuário definido');
    } catch (e) {
      _logger.e('Erro ao definir email do usuário', error: e);
    }
  }
  
  /// Obtém o Player ID atual
  String? get currentPlayerId => _currentPlayerId;
  
  /// Obtém o Push Token atual
  String? get currentPushToken => _currentPushToken;
  
  /// Verifica se o serviço está inicializado
  bool get isInitialized => _isInitialized;
  
  /// Limpa recursos
  Future<void> dispose() async {
    // OneSignal não precisa de cleanup manual
    _isInitialized = false;
  }
}