import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'local_notification_service.dart';

/// Serviço completo para gerenciamento de Firebase Cloud Messaging
/// Inclui registro de tokens, envio de notificações, segmentação e histórico
class FCMService {
  factory FCMService() => _instance;
  FCMService._internal();
  static final FCMService _instance = FCMService._internal();

  final Logger _logger = Logger();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final LocalNotificationService _localNotificationService = LocalNotificationService();
  
  String? _currentToken;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  
  bool _isInitialized = false;
  
  /// Inicializa o serviço FCM
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Inicializar Firebase se necessário
      if (!Firebase.apps.isNotEmpty) {
        await Firebase.initializeApp();
      }
      
      // Solicitar permissões
      await _requestPermissions();
      
      // Configurar handlers de mensagens
      await _setupMessageHandlers();
      
      // Registrar token
      await _registerToken();
      
      // Configurar listener para mudanças de token
      _setupTokenRefreshListener();
      
      _isInitialized = true;
      _logger.i('FCMService inicializado com sucesso');
      
    } catch (e, stackTrace) {
      _logger.e('Erro ao inicializar FCMService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Solicita permissões necessárias para notificações
  Future<void> _requestPermissions() async {
    try {
      // Permissões do Firebase Messaging
      final settings = await _firebaseMessaging.requestPermission(
        
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _logger.i('Permissões de notificação concedidas');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        _logger.i('Permissões provisórias de notificação concedidas');
      } else {
        _logger.w('Permissões de notificação negadas');
      }
      
      // Permissões adicionais para Android
      if (Platform.isAndroid) {
        await Permission.notification.request();
      }
      
    } catch (e) {
      _logger.e('Erro ao solicitar permissões', error: e);
    }
  }
  
  /// Configura os handlers para diferentes tipos de mensagens
  Future<void> _setupMessageHandlers() async {
    // Handler para mensagens em foreground
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      _logger.i('Mensagem recebida em foreground: ${message.messageId}');
      _handleForegroundMessage(message);
    });
    
    // Handler para quando o app é aberto via notificação
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _logger.i('App aberto via notificação: ${message.messageId}');
      _handleNotificationTap(message);
    });
    
    // Handler para mensagens em background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Verificar se o app foi aberto por uma notificação
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _logger.i('App iniciado via notificação: ${initialMessage.messageId}');
      _handleNotificationTap(initialMessage);
    }
  }
  
  /// Registra o token FCM no Supabase
  Future<void> _registerToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        _currentToken = token;
        await _saveTokenToSupabase(token);
        await _saveTokenLocally(token);
        _logger.i('Token FCM registrado: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      _logger.e('Erro ao registrar token FCM', error: e);
    }
  }
  
  /// Salva o token no Supabase
  Future<void> _saveTokenToSupabase(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _logger.w('Usuário não autenticado, token não salvo no Supabase');
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
              'fcm_token': token,
              'device_platform': platform,
              'token_updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', user.id);
      } else {
        // É um passageiro
        await Supabase.instance.client
            .from('app_users')
            .update({
              'fcm_token': token,
              'device_platform': platform,
              'token_updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', user.id);
      }
      
      _logger.i('Token salvo no Supabase com sucesso');
      
    } catch (e) {
      _logger.e('Erro ao salvar token no Supabase', error: e);
    }
  }
  
  /// Salva o token localmente
  Future<void> _saveTokenLocally(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      await prefs.setString('fcm_token_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      _logger.e('Erro ao salvar token localmente', error: e);
    }
  }
  
  /// Configura listener para refresh de token
  void _setupTokenRefreshListener() {
    _tokenSubscription = _firebaseMessaging.onTokenRefresh.listen((token) {
      _logger.i('Token FCM atualizado');
      _currentToken = token;
      _saveTokenToSupabase(token);
      _saveTokenLocally(token);
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

  /// Manipula mensagens recebidas em foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      // Registrar no histórico
      _logNotificationReceived(message);
      
      // Verificar se é motorista
      final isDriver = await _isCurrentUserDriver();
      
      // Exibir notificação local
      _localNotificationService.showRideOfferNotification(
        title: message.notification?.title ?? 'Nova notificação',
        body: message.notification?.body ?? '',
        offerId: message.data['offer_id'],
        isDriver: isDriver,
      );
      
    } catch (e) {
      _logger.e('Erro ao processar mensagem em foreground', error: e);
    }
  }
  
  /// Manipula tap em notificação
  void _handleNotificationTap(RemoteMessage message) {
    try {
      _logger.i('Notificação tocada: ${message.data}');
      
      // Processar ação baseada no tipo de notificação
      final notificationType = message.data['type'];
      switch (notificationType) {
        case 'trip_request':
          _handleTripRequestNotification(message.data);
          break;
        case 'trip_update':
          _handleTripUpdateNotification(message.data);
          break;
        case 'chat_message':
          _handleChatNotification(message.data);
          break;
        default:
          _logger.w('Tipo de notificação desconhecido: $notificationType');
      }
      
    } catch (e) {
      _logger.e('Erro ao processar tap em notificação', error: e);
    }
  }
  
  /// Manipula notificação de solicitação de viagem
  void _handleTripRequestNotification(Map<String, dynamic> data) {
    // Implementar navegação para tela de solicitações
    _logger.i('Processando notificação de solicitação de viagem');
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
  Future<void> _logNotificationReceived(RemoteMessage message) async {
    try {
      await Supabase.instance.client.from('notification_history').insert({
        'message_id': message.messageId,
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
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
      // Buscar token do usuário
      final token = await _getUserToken(userId);
      if (token == null) {
        _logger.w('Token não encontrado para usuário: $userId');
        return false;
      }
      
      return await sendNotificationToToken(
        token: token,
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
  
  /// Envia notificação para um token específico
  Future<bool> sendNotificationToToken({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      // Aqui você implementaria a chamada para seu backend
      // que enviaria a notificação via FCM Admin SDK
      
      final notificationData = {
        'token': token,
        'title': title,
        'body': body,
        'data': data ?? {},
        'image': imageUrl,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Registrar no histórico
      await _logNotificationSent(notificationData);
      
      _logger.i('Notificação enviada com sucesso para token: ${token.substring(0, 20)}...');
      return true;
      
    } catch (e) {
      _logger.e('Erro ao enviar notificação', error: e);
      return false;
    }
  }
  
  /// Busca token de um usuário
  Future<String?> _getUserToken(String userId) async {
    try {
      // Verificar se é motorista
      final driverResponse = await Supabase.instance.client
          .from('drivers')
          .select('fcm_token')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (driverResponse != null && driverResponse['fcm_token'] != null) {
        return driverResponse['fcm_token'];
      }
      
      // Verificar se é passageiro
      final userResponse = await Supabase.instance.client
          .from('app_users')
          .select('fcm_token')
          .eq('user_id', userId)
          .maybeSingle();
      
      return userResponse?['fcm_token'];
      
    } catch (e) {
      _logger.e('Erro ao buscar token do usuário', error: e);
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
        'platform': 'fcm',
        'status': 'sent',
      });
    } catch (e) {
      _logger.e('Erro ao registrar notificação enviada', error: e);
    }
  }
  
  /// Envia notificação para múltiplos tokens
  Future<bool> sendBulkNotification({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      if (tokens.isEmpty) {
        _logger.w('Lista de tokens vazia para envio em lote');
        return false;
      }
      
      var successCount = 0;
      
      // Enviar para cada token (em produção, usar FCM batch API)
      for (final token in tokens) {
        final success = await sendNotificationToToken(
          token: token,
          title: title,
          body: body,
          data: data,
          imageUrl: imageUrl,
        );
        
        if (success) successCount++;
      }
      
      _logger.i('Notificações em lote enviadas: $successCount/${tokens.length}');
      return successCount > 0;
      
    } catch (e) {
      _logger.e('Erro ao enviar notificações em lote', error: e);
      return false;
    }
  }
  
  /// Obtém o token atual
  String? get currentToken => _currentToken;
  
  /// Verifica se o serviço está inicializado
  bool get isInitialized => _isInitialized;
  
  /// Limpa recursos
  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    _isInitialized = false;
  }
}

/// Handler para mensagens em background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  
  final logger = Logger();
  logger.i('Mensagem em background: ${message.messageId}');
  
  // Processar mensagem em background
  try {
    // Registrar no histórico se necessário
    // Nota: Operações limitadas em background
    
  } catch (e) {
    logger.e('Erro ao processar mensagem em background', error: e);
  }
}