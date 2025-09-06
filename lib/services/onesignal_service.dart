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
    if (_isInitialized) {
      _logger.w('🔵 [ONESIGNAL] Tentativa de inicialização dupla detectada - ignorando');
      return;
    }
    
    _logger.i('🚀 [ONESIGNAL] Iniciando processo de inicialização...');
    _logger.i('🔍 [ONESIGNAL] App ID: $_appId');
    _logger.i('🔍 [ONESIGNAL] Platform: ${kIsWeb ? 'Web' : Platform.operatingSystem}');
    
    try {
      // Ignorar plataformas não suportadas (somente Android/iOS e Web são suportados)
      if (!kIsWeb && !(Platform.isAndroid || Platform.isIOS)) {
        _logger.w('❌ [ONESIGNAL] Plataforma ${Platform.operatingSystem} não suportada para OneSignal');
        _logger.w('⚠️ [ONESIGNAL] Plataformas suportadas: Android, iOS, Web');
        _isInitialized = true;
        return;
      }

      _logger.i('✅ [ONESIGNAL] Plataforma suportada confirmada');

      // Verificar se é plataforma web
      if (kIsWeb) {
        _logger.i('🌐 [ONESIGNAL] Detectada plataforma WEB - configurando handlers web');
        await _setupWebNotificationHandlers();
      } else {
        _logger.i('📱 [ONESIGNAL] Detectada plataforma MOBILE - configuração completa');
        
        // Habilitar debug logging ANTES da inicialização (apenas mobile)
        _logger.i('🔧 [ONESIGNAL] Habilitando debug logging verbose...');
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
        _logger.i('✅ [ONESIGNAL] Debug logging configurado com sucesso');
        
        // Inicializar OneSignal
        _logger.i('🔧 [ONESIGNAL] Inicializando OneSignal SDK...');
        OneSignal.initialize(_appId);
        _logger.i('✅ [ONESIGNAL] OneSignal SDK inicializado com App ID: $_appId');
        
        // Solicitar permissões
        _logger.i('🔧 [ONESIGNAL] Solicitando permissões de notificação...');
        await _requestPermissions();
        _logger.i('✅ [ONESIGNAL] Permissões processadas');
        
        // Configurar handlers de notificação
        _logger.i('🔧 [ONESIGNAL] Configurando handlers de notificação...');
        await _setupNotificationHandlers();
        _logger.i('✅ [ONESIGNAL] Handlers de notificação configurados');
        
        // Registrar token/player ID
        _logger.i('🔧 [ONESIGNAL] Registrando dados do player...');
        await _registerPlayerData();
        _logger.i('✅ [ONESIGNAL] Registro de dados do player iniciado');
        
        // Configurar listener para mudanças de ID
        _logger.i('🔧 [ONESIGNAL] Configurando listeners de mudança de Player ID...');
        _setupPlayerIdListener();
        _logger.i('✅ [ONESIGNAL] Listeners de Player ID configurados');
      }
      
      _isInitialized = true;
      _logger.i('🎉 [ONESIGNAL] OneSignalService inicializado com SUCESSO!');
      _logger.i('📊 [ONESIGNAL] Status: Inicializado=${_isInitialized}, Platform=${kIsWeb ? 'Web' : Platform.operatingSystem}');
      
    } catch (e, stackTrace) {
      _logger.e('💥 [ONESIGNAL] ERRO CRÍTICO ao inicializar OneSignalService', error: e, stackTrace: stackTrace);
      _logger.e('🔍 [ONESIGNAL] Error details: $e');
      _logger.e('📍 [ONESIGNAL] Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Solicita permissões necessárias para notificações
  Future<void> _requestPermissions() async {
    _logger.i('🔐 [ONESIGNAL] Iniciando processo de solicitação de permissões');
    
    try {
      // Verificar se não é web antes de solicitar permissões
      if (!kIsWeb) {
        _logger.i('🔐 [ONESIGNAL] Solicitando permissões via OneSignal SDK...');
        
        // OneSignal vai solicitar permissões automaticamente, mas podemos forçar
        final granted = await OneSignal.Notifications.requestPermission(true);
        _logger.i('🔐 [ONESIGNAL] Resultado permissão OneSignal: $granted');
        
        // Permissões adicionais para Android
        if (Platform.isAndroid) {
          _logger.i('🔐 [ONESIGNAL] Android detectado - solicitando permissões adicionais...');
          final androidPermission = await Permission.notification.request();
          _logger.i('🔐 [ONESIGNAL] Permissão Android status: ${androidPermission.name}');
          
          // Verificar permissões específicas do Android
          final notificationStatus = await Permission.notification.status;
          _logger.i('🔐 [ONESIGNAL] Status final permissão notificação: ${notificationStatus.name}');
          
          if (notificationStatus.isPermanentlyDenied) {
            _logger.w('⚠️ [ONESIGNAL] Permissões permanentemente negadas pelo usuário');
          } else if (notificationStatus.isDenied) {
            _logger.w('⚠️ [ONESIGNAL] Permissões negadas pelo usuário');
          } else if (notificationStatus.isGranted) {
            _logger.i('✅ [ONESIGNAL] Permissões Android concedidas com sucesso');
          }
        } else if (Platform.isIOS) {
          _logger.i('🍎 [ONESIGNAL] iOS detectado - permissões gerenciadas pelo sistema');
        }
        
        // Verificar estado final das permissões
        _logger.i('🔍 [ONESIGNAL] Verificando estado final das permissões...');
        
        // Log do estado atual das permissões do OneSignal
        _logger.i('📊 [ONESIGNAL] Permission granted: $granted');
        
      } else {
        _logger.i('🌐 [ONESIGNAL] Web platform - permissões gerenciadas pelo browser');
      }
      
      _logger.i('✅ [ONESIGNAL] Processo de permissões concluído');
      
    } catch (e, stackTrace) {
      _logger.e('💥 [ONESIGNAL] ERRO ao solicitar permissões', error: e, stackTrace: stackTrace);
      _logger.e('🔍 [ONESIGNAL] Permissões error details: $e');
    }
  }
  
  /// Configura handlers de notificação específicos para web
  Future<void> _setupWebNotificationHandlers() async {
    _logger.i('🌐 [ONESIGNAL] Iniciando configuração de handlers WEB');
    
    try {
      _logger.i('🌐 [ONESIGNAL] Configurando handlers de notificação para plataforma web');
      _logger.i('🌐 [ONESIGNAL] Web SDK deve estar carregado via index.html');
      
      // Para web, as notificações são gerenciadas pelo OneSignal Web SDK
      // que foi configurado no index.html
      
      // Aguardar dados do usuário OneSignal
      _logger.i('💡 [ONESIGNAL] Aguardando dados do usuário OneSignal Web SDK...');
      _logger.i('📝 [ONESIGNAL] Web handlers configurados via JavaScript (index.html)');
      
      _logger.i('✅ [ONESIGNAL] Handlers web configurados com sucesso');
      
    } catch (e, stackTrace) {
      _logger.e('💥 [ONESIGNAL] ERRO ao configurar handlers web', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Configura os handlers para diferentes tipos de notificações
  Future<void> _setupNotificationHandlers() async {
    _logger.i('🔔 [ONESIGNAL] Configurando handlers de notificações mobile');
    
    // Handler para quando notificação é recebida (em foreground)
    _logger.i('🔔 [ONESIGNAL] Configurando ForegroundWillDisplayListener...');
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      final notificationId = event.notification.notificationId;
      final title = event.notification.title;
      final body = event.notification.body;
      
      _logger.i('📬 [ONESIGNAL] NOTIFICAÇÃO RECEBIDA EM FOREGROUND');
      _logger.i('📬 [ONESIGNAL] ID: $notificationId');
      _logger.i('📬 [ONESIGNAL] Título: $title');
      _logger.i('📬 [ONESIGNAL] Body: $body');
      _logger.i('📬 [ONESIGNAL] Additional Data: ${event.notification.additionalData}');
      _logger.i('📬 [ONESIGNAL] Timestamp: ${DateTime.now().toIso8601String()}');
      
      _handleForegroundNotification(event);
    });
    _logger.i('✅ [ONESIGNAL] ForegroundWillDisplayListener configurado');
    
    // Handler para quando notificação é clicada
    _logger.i('🔔 [ONESIGNAL] Configurando ClickListener...');
    OneSignal.Notifications.addClickListener((event) {
      final notificationId = event.notification.notificationId;
      final title = event.notification.title;
      final actionId = event.result.actionId;
      
      _logger.i('👆 [ONESIGNAL] NOTIFICAÇÃO CLICADA');
      _logger.i('👆 [ONESIGNAL] ID: $notificationId');
      _logger.i('👆 [ONESIGNAL] Título: $title');
      _logger.i('👆 [ONESIGNAL] Action ID: $actionId');
      _logger.i('👆 [ONESIGNAL] Additional Data: ${event.notification.additionalData}');
      _logger.i('👆 [ONESIGNAL] Timestamp: ${DateTime.now().toIso8601String()}');
      
      _handleNotificationClick(event);
    });
    _logger.i('✅ [ONESIGNAL] ClickListener configurado');
    
    // Handler para mudanças na permissão
    _logger.i('🔔 [ONESIGNAL] Configurando PermissionObserver...');
    OneSignal.Notifications.addPermissionObserver((permission) {
      _logger.i('🔐 [ONESIGNAL] PERMISSÃO DE NOTIFICAÇÃO ALTERADA');
      _logger.i('🔐 [ONESIGNAL] Nova permissão: $permission');
      _logger.i('🔐 [ONESIGNAL] Timestamp: ${DateTime.now().toIso8601String()}');
    });
    _logger.i('✅ [ONESIGNAL] PermissionObserver configurado');
    
    _logger.i('🎉 [ONESIGNAL] Todos os handlers de notificação configurados com sucesso!');
  }
  
  /// Registra o Player ID e Push Token no Supabase
  Future<void> _registerPlayerData() async {
    _logger.i('🆔 [ONESIGNAL] Iniciando processo de registro de Player Data');
    
    try {
      // Verificar se não é web antes de acessar dados do player
      if (!kIsWeb) {
        _logger.i('📱 [ONESIGNAL] Plataforma mobile detectada - configurando observers');
        
        // Usar observer para obter dados quando disponíveis
        // Os valores podem ser null se chamados antes da inicialização
        _logger.i('⏳ [ONESIGNAL] Aguardando dados do usuário OneSignal via observers...');
        _logger.i('📝 [ONESIGNAL] Player ID e Push Token serão obtidos via callbacks');
        
        // Configurar observers para capturar dados quando disponíveis
        _logger.i('🔧 [ONESIGNAL] Configurando PlayerIdListener...');
        _setupPlayerIdListener();
        
        _logger.i('🔧 [ONESIGNAL] Configurando PushSubscriptionListener...');
        _setupPushSubscriptionListener();
        
        _logger.i('✅ [ONESIGNAL] Observers de Player Data configurados');
      } else {
        _logger.i('🌐 [ONESIGNAL] Web platform - registro de dados gerenciado pelo Web SDK');
        _logger.i('📝 [ONESIGNAL] Player data será capturado via JavaScript SDK');
      }
      
      _logger.i('🎉 [ONESIGNAL] Processo de registro de Player Data iniciado com sucesso');
      
    } catch (e, stackTrace) {
      _logger.e('💥 [ONESIGNAL] ERRO ao registrar dados do player', error: e, stackTrace: stackTrace);
      _logger.e('🔍 [ONESIGNAL] Player data error details: $e');
    }
  }
  
  /// Salva o Player ID no Supabase
  Future<void> _savePlayerIdToSupabase(String playerId) async {
    _logger.i('💾 [ONESIGNAL] Iniciando salvamento de Player ID no Supabase');
    _logger.i('💾 [ONESIGNAL] Player ID: ${playerId.substring(0, 12)}...');
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _logger.w('⚠️ [ONESIGNAL] Usuário não autenticado - Player ID não pode ser salvo');
        _logger.w('💾 [ONESIGNAL] User auth status: null');
        return;
      }
      
      _logger.i('💾 [ONESIGNAL] Usuário autenticado: ${user.id.substring(0, 8)}...');
      final platform = Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'web';
      _logger.i('💾 [ONESIGNAL] Platform detectada: $platform');
      
      // Verificar se é motorista ou passageiro
      _logger.i('💾 [ONESIGNAL] Verificando tipo de usuário (motorista/passageiro)...');
      final driverResponse = await Supabase.instance.client
          .from('drivers')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (driverResponse != null) {
        // É um motorista
        _logger.i('🚗 [ONESIGNAL] Usuário identificado como MOTORISTA');
        _logger.i('💾 [ONESIGNAL] Salvando Player ID na tabela drivers...');
        
        await Supabase.instance.client
            .from('drivers')
            .update({
              'onesignal_player_id': playerId,
              'device_platform': platform,
              'token_updated_at': DateTime.now().toIso8601String(),
              'token_active': true,
            })
            .eq('user_id', user.id);
            
        _logger.i('✅ [ONESIGNAL] Player ID salvo na tabela drivers com sucesso');
      } else {
        // É um passageiro
        _logger.i('👤 [ONESIGNAL] Usuário identificado como PASSAGEIRO');
        _logger.i('💾 [ONESIGNAL] Salvando Player ID na tabela app_users...');
        
        await Supabase.instance.client
            .from('app_users')
            .update({
              'onesignal_player_id': playerId,
              'token_updated_at': DateTime.now().toIso8601String(),
              'token_active': true,
              'last_active_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', user.id);
            
        _logger.i('✅ [ONESIGNAL] Player ID salvo na tabela app_users com sucesso');
      }
      
      _logger.i('🎉 [ONESIGNAL] Player ID salvo no Supabase com SUCESSO TOTAL!');
      _logger.i('📊 [ONESIGNAL] Dados salvos: Player ID, Platform, Timestamp, Status ativo');
      
    } catch (e, stackTrace) {
      _logger.e('💥 [ONESIGNAL] ERRO CRÍTICO ao salvar Player ID no Supabase', error: e, stackTrace: stackTrace);
      _logger.e('🔍 [ONESIGNAL] Player ID: ${playerId.substring(0, 12)}...');
      _logger.e('🔍 [ONESIGNAL] Error details: $e');
    }
  }
  
  /// Salva o Push Token no Supabase
  Future<void> _savePushTokenToSupabase(String pushToken) async {
    _logger.i('🔑 [ONESIGNAL] Iniciando salvamento de Push Token no Supabase');
    _logger.i('🔑 [ONESIGNAL] Push Token: ${pushToken.substring(0, 20)}...');
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _logger.w('⚠️ [ONESIGNAL] Usuário não autenticado - Push Token não pode ser salvo');
        _logger.w('🔑 [ONESIGNAL] User auth status: null');
        return;
      }
      
      _logger.i('🔑 [ONESIGNAL] Usuário autenticado: ${user.id.substring(0, 8)}...');
      
      // Verificar se é motorista ou passageiro
      _logger.i('🔑 [ONESIGNAL] Verificando tipo de usuário para Push Token...');
      final driverResponse = await Supabase.instance.client
          .from('drivers')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (driverResponse != null) {
        // É um motorista
        _logger.i('🚗 [ONESIGNAL] Usuário identificado como MOTORISTA - salvando Push Token');
        _logger.i('🔑 [ONESIGNAL] Salvando Push Token na tabela drivers...');
        
        await Supabase.instance.client
            .from('drivers')
            .update({
              'push_token': pushToken,
              'token_updated_at': DateTime.now().toIso8601String(),
              'token_active': true,
            })
            .eq('user_id', user.id);
            
        _logger.i('✅ [ONESIGNAL] Push Token salvo na tabela drivers com sucesso');
      } else {
        // É um passageiro
        _logger.i('👤 [ONESIGNAL] Usuário identificado como PASSAGEIRO - salvando Push Token');
        _logger.i('🔑 [ONESIGNAL] Salvando Push Token na tabela app_users...');
        
        await Supabase.instance.client
            .from('app_users')
            .update({
              'push_token': pushToken,
              'token_updated_at': DateTime.now().toIso8601String(),
              'token_active': true,
              'last_active_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', user.id);
            
        _logger.i('✅ [ONESIGNAL] Push Token salvo na tabela app_users com sucesso');
      }
      
      _logger.i('🎉 [ONESIGNAL] Push Token salvo no Supabase com SUCESSO TOTAL!');
      _logger.i('📊 [ONESIGNAL] Dados salvos: Push Token, Timestamp, Status ativo');
      
    } catch (e, stackTrace) {
      _logger.e('💥 [ONESIGNAL] ERRO CRÍTICO ao salvar Push Token no Supabase', error: e, stackTrace: stackTrace);
      _logger.e('🔍 [ONESIGNAL] Push Token: ${pushToken.substring(0, 20)}...');
      _logger.e('🔍 [ONESIGNAL] Error details: $e');
    }
  }
  
  /// Salva o Player ID localmente
  Future<void> _savePlayerIdLocally(String playerId) async {
    _logger.i('💽 [ONESIGNAL] Salvando Player ID localmente (SharedPreferences)');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().toIso8601String();
      
      _logger.i('💽 [ONESIGNAL] Salvando Player ID: ${playerId.substring(0, 12)}...');
      await prefs.setString('onesignal_player_id', playerId);
      
      _logger.i('💽 [ONESIGNAL] Salvando timestamp: $timestamp');
      await prefs.setString('onesignal_player_id_timestamp', timestamp);
      
      _logger.i('✅ [ONESIGNAL] Player ID salvo localmente com sucesso');
    } catch (e, stackTrace) {
      _logger.e('💥 [ONESIGNAL] ERRO ao salvar Player ID localmente', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Salva o Push Token localmente
  Future<void> _savePushTokenLocally(String pushToken) async {
    _logger.i('💽 [ONESIGNAL] Salvando Push Token localmente (SharedPreferences)');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().toIso8601String();
      
      _logger.i('💽 [ONESIGNAL] Salvando Push Token: ${pushToken.substring(0, 20)}...');
      await prefs.setString('onesignal_push_token', pushToken);
      
      _logger.i('💽 [ONESIGNAL] Salvando timestamp: $timestamp');
      await prefs.setString('onesignal_push_token_timestamp', timestamp);
      
      _logger.i('✅ [ONESIGNAL] Push Token salvo localmente com sucesso');
    } catch (e, stackTrace) {
      _logger.e('💥 [ONESIGNAL] ERRO ao salvar Push Token localmente', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Configura listener para mudanças no Player ID
  void _setupPlayerIdListener() {
    _logger.i('🔗 [ONESIGNAL] Configurando Player ID Listener');
    
    // Verificar se não é web antes de configurar listeners
    if (!kIsWeb) {
      _logger.i('🔗 [ONESIGNAL] Adicionando User Observer para mudanças de Player ID...');
      
      OneSignal.User.addObserver((state) {
        final userState = state.jsonRepresentation();
        _logger.i('🔄 [ONESIGNAL] USER STATE CHANGED!');
        _logger.i('🔄 [ONESIGNAL] Current user state: $userState');
        _logger.i('🔄 [ONESIGNAL] Timestamp: ${DateTime.now().toIso8601String()}');
        
        // Tentar obter o OneSignal ID do estado atual
        try {
          final playerId = state.current.onesignalId;
          _logger.i('🔍 [ONESIGNAL] Extraindo Player ID do estado...');
          _logger.i('🔍 [ONESIGNAL] Player ID atual: ${playerId != null ? '${playerId.substring(0, 12)}...' : 'null'}');
          _logger.i('🔍 [ONESIGNAL] Player ID anterior: ${_currentPlayerId != null ? '${_currentPlayerId!.substring(0, 12)}...' : 'null'}');
          
          if (playerId != null && playerId != _currentPlayerId) {
            _logger.i('🆔 [ONESIGNAL] NOVO PLAYER ID DETECTADO!');
            _logger.i('🆔 [ONESIGNAL] Player ID atualizado: ${playerId.substring(0, 12)}...');
            _logger.i('🆔 [ONESIGNAL] Player ID completo length: ${playerId.length}');
            
            _currentPlayerId = playerId;
            
            _logger.i('💾 [ONESIGNAL] Salvando novo Player ID no Supabase...');
            _savePlayerIdToSupabase(playerId);
            
            _logger.i('💽 [ONESIGNAL] Salvando novo Player ID localmente...');
            _savePlayerIdLocally(playerId);
          } else if (playerId == null) {
            _logger.w('⚠️ [ONESIGNAL] Player ID é null - aguardando inicialização');
          } else {
            _logger.i('🔄 [ONESIGNAL] Player ID não mudou - mantendo atual');
          }
        } catch (e, stackTrace) {
          _logger.e('💥 [ONESIGNAL] ERRO ao obter OneSignal ID do estado', error: e, stackTrace: stackTrace);
          _logger.e('🔍 [ONESIGNAL] Estado completo: $userState');
        }
      });
      
      _logger.i('✅ [ONESIGNAL] Player ID Listener configurado com sucesso');
    } else {
      _logger.i('🌐 [ONESIGNAL] Web platform - Player ID listener não necessário');
    }
  }
  
  /// Configura listener para mudanças na subscription de push
  void _setupPushSubscriptionListener() {
    _logger.i('🔔 [ONESIGNAL] Configurando Push Subscription Listener');
    _logger.i('🔔 [ONESIGNAL] Adicionando observer para mudanças de subscription...');
    
    OneSignal.User.pushSubscription.addObserver((state) {
      _logger.i('🔔 [ONESIGNAL] PUSH SUBSCRIPTION STATE CHANGED!');
      
      // Log detalhado do estado da subscription
      final optedIn = OneSignal.User.pushSubscription.optedIn;
      final subscriptionId = OneSignal.User.pushSubscription.id;
      final pushToken = OneSignal.User.pushSubscription.token;
      
      _logger.i('🔔 [ONESIGNAL] Opted in: $optedIn');
      _logger.i('🔔 [ONESIGNAL] Subscription ID: $subscriptionId');
      _logger.i('🔔 [ONESIGNAL] Push token: ${pushToken != null ? '${pushToken.substring(0, 20)}...' : 'null'}');
      _logger.i('🔔 [ONESIGNAL] Timestamp: ${DateTime.now().toIso8601String()}');
      
      // Log do estado completo
      _logger.i('📊 [ONESIGNAL] Push subscription state JSON: ${state.jsonRepresentation()}');
      
      if (pushToken != null && pushToken != _currentPushToken) {
        _logger.i('🔑 [ONESIGNAL] NOVO PUSH TOKEN DETECTADO!');
        _logger.i('🔑 [ONESIGNAL] Push Token atualizado: ${pushToken.substring(0, 20)}...');
        _logger.i('🔑 [ONESIGNAL] Push Token length: ${pushToken.length}');
        _logger.i('🔑 [ONESIGNAL] Push Token anterior: ${_currentPushToken != null ? '${_currentPushToken!.substring(0, 20)}...' : 'null'}');
        
        _currentPushToken = pushToken;
        
        _logger.i('💾 [ONESIGNAL] Salvando novo Push Token no Supabase...');
        _savePushTokenToSupabase(pushToken);
        
        _logger.i('💽 [ONESIGNAL] Salvando novo Push Token localmente...');
        _savePushTokenLocally(pushToken);
      } else if (pushToken == null) {
        _logger.w('⚠️ [ONESIGNAL] Push Token é null - aguardando subscription');
      } else {
        _logger.i('🔄 [ONESIGNAL] Push Token não mudou - mantendo atual');
      }
      
      // Log adicional sobre permissões
      if (optedIn == false) {
        _logger.w('⚠️ [ONESIGNAL] Usuario não optou por notificações push');
      } else if (optedIn == true) {
        _logger.i('✅ [ONESIGNAL] Usuario optou por receber notificações push');
      } else {
        _logger.w('⚠️ [ONESIGNAL] Status de opt-in desconhecido: $optedIn');
      }
    });
    
    _logger.i('✅ [ONESIGNAL] Push Subscription Listener configurado com sucesso');
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
    _logger.i('🔍 [ONESIGNAL] Processando notificação recebida em foreground');
    
    try {
      final notification = event.notification;
      final notificationId = notification.notificationId;
      final title = notification.title;
      final body = notification.body;
      final additionalData = notification.additionalData;
      
      _logger.i('🔍 [ONESIGNAL] Detalhes da notificação foreground:');
      _logger.i('🔍 [ONESIGNAL] - ID: $notificationId');
      _logger.i('🔍 [ONESIGNAL] - Título: $title');
      _logger.i('🔍 [ONESIGNAL] - Body: $body');
      _logger.i('🔍 [ONESIGNAL] - Additional Data: $additionalData');
      
      // Registrar no histórico
      _logger.i('📝 [ONESIGNAL] Registrando notificação no histórico...');
      _logNotificationReceived(notification);
      
      // Verificar se é motorista
      _logger.i('🔍 [ONESIGNAL] Verificando tipo de usuário (driver/passenger)...');
      final isDriver = await _isCurrentUserDriver();
      _logger.i('🔍 [ONESIGNAL] Tipo de usuário: ${isDriver ? 'MOTORISTA' : 'PASSAGEIRO'}');
      
      // Exibir notificação local
      _logger.i('🔔 [ONESIGNAL] Exibindo notificação local personalizada...');
      _localNotificationService.showRideOfferNotification(
        title: title ?? 'Nova notificação',
        body: body ?? '',
        offerId: additionalData?['offer_id'],
        isDriver: isDriver,
      );
      _logger.i('✅ [ONESIGNAL] Notificação local exibida');
      
      // Permitir que a notificação seja exibida
      _logger.i('📱 [ONESIGNAL] Permitindo exibição da notificação nativa...');
      event.notification.display();
      _logger.i('✅ [ONESIGNAL] Notificação nativa permitida');
      
      _logger.i('🎉 [ONESIGNAL] Processamento de notificação foreground CONCLUÍDO');
      
    } catch (e, stackTrace) {
      _logger.e('💥 [ONESIGNAL] ERRO ao processar notificação em foreground', error: e, stackTrace: stackTrace);
      _logger.e('🔍 [ONESIGNAL] Notification ID: ${event.notification.notificationId}');
    }
  }
  
  /// Manipula clique em notificação
  void _handleNotificationClick(OSNotificationClickEvent event) {
    _logger.i('🖱️ [ONESIGNAL] Processando CLIQUE em notificação');
    
    try {
      final notification = event.notification;
      final notificationId = notification.notificationId;
      final title = notification.title;
      final additionalData = notification.additionalData ?? {};
      final actionId = event.result.actionId;
      
      _logger.i('🖱️ [ONESIGNAL] Detalhes do clique:');
      _logger.i('🖱️ [ONESIGNAL] - Notification ID: $notificationId');
      _logger.i('🖱️ [ONESIGNAL] - Título: $title');
      _logger.i('🖱️ [ONESIGNAL] - Action ID: $actionId');
      _logger.i('🖱️ [ONESIGNAL] - Additional Data: $additionalData');
      _logger.i('🖱️ [ONESIGNAL] - Timestamp: ${DateTime.now().toIso8601String()}');
      
      // Processar ação baseada no tipo de notificação
      final notificationType = additionalData['type'];
      _logger.i('🔍 [ONESIGNAL] Tipo de notificação detectado: $notificationType');
      
      switch (notificationType) {
        case 'trip_request':
          _logger.i('🚗 [ONESIGNAL] Processando notificação de TRIP REQUEST');
          _handleTripRequestNotification(additionalData);
          break;
        case 'trip_update':
          _logger.i('🔄 [ONESIGNAL] Processando notificação de TRIP UPDATE');
          _handleTripUpdateNotification(additionalData);
          break;
        case 'chat_message':
          _logger.i('💬 [ONESIGNAL] Processando notificação de CHAT MESSAGE');
          _handleChatNotification(additionalData);
          break;
        default:
          _logger.w('⚠️ [ONESIGNAL] Tipo de notificação DESCONHECIDO: $notificationType');
          _logger.w('⚠️ [ONESIGNAL] Dados completos: $additionalData');
      }
      
      _logger.i('✅ [ONESIGNAL] Processamento de clique em notificação CONCLUÍDO');
      
    } catch (e, stackTrace) {
      _logger.e('💥 [ONESIGNAL] ERRO ao processar clique em notificação', error: e, stackTrace: stackTrace);
      _logger.e('🔍 [ONESIGNAL] Event details: ${event.toString()}');
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
    _logger.i('📤 [ONESIGNAL] ENVIANDO NOTIFICAÇÃO via REST API');
    _logger.i('📤 [ONESIGNAL] Player ID: ${playerId.substring(0, 12)}...');
    _logger.i('📤 [ONESIGNAL] Título: $title');
    _logger.i('📤 [ONESIGNAL] Body: $body');
    _logger.i('📤 [ONESIGNAL] Data: $data');
    _logger.i('📤 [ONESIGNAL] Image URL: $imageUrl');
    
    try {
      // Validar Player ID primeiro
      _logger.i('🔍 [ONESIGNAL] Validando formato do Player ID...');
      if (!_isValidPlayerId(playerId)) {
        _logger.e('❌ [ONESIGNAL] Player ID INVÁLIDO: $playerId');
        _logger.e('❌ [ONESIGNAL] Formato esperado: UUID com hífens (36 chars)');
        return false;
      }
      _logger.i('✅ [ONESIGNAL] Player ID validado com sucesso');
      
      // Preparar payload da notificação
      _logger.i('🔧 [ONESIGNAL] Preparando payload da notificação...');
      final payload = {
        'app_id': _appId,
        'include_player_ids': [playerId],
        'headings': {'en': title, 'pt': title},
        'contents': {'en': body, 'pt': body},
        'data': data ?? {},
      };
      _logger.i('🔧 [ONESIGNAL] Payload base criado');
      
      // Adicionar imagem se fornecida
      if (imageUrl != null && imageUrl.isNotEmpty) {
        _logger.i('🖼️ [ONESIGNAL] Adicionando imagem ao payload: $imageUrl');
        payload['large_icon'] = imageUrl;
        payload['big_picture'] = imageUrl;
      }
      
      // Configurar som personalizado para motoristas (detectado pelos dados)
      if (data != null && data['type'] == 'trip_request') {
        _logger.i('🔊 [ONESIGNAL] Configurando som personalizado para TRIP REQUEST');
        payload['android_sound'] = 'chegoucorridaoption';
        payload['ios_sound'] = 'chegoucorridaOption.mp3';
        payload['priority'] = 10; // Alta prioridade
        payload['android_channel_id'] = 'ride_offers';
        _logger.i('🔊 [ONESIGNAL] Som personalizado configurado');
      }
      
      _logger.i('📡 [ONESIGNAL] Enviando para OneSignal REST API...');
      _logger.i('📡 [ONESIGNAL] URL: $_baseUrl/notifications');
      _logger.i('📡 [ONESIGNAL] Payload completo: ${jsonEncode(payload)}');
      
      // Fazer chamada HTTP para OneSignal REST API
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $_restApiKey',
        },
        body: jsonEncode(payload),
      );
      
      _logger.i('📡 [ONESIGNAL] Resposta recebida da API');
      _logger.i('📡 [ONESIGNAL] Status Code: ${response.statusCode}');
      _logger.i('📡 [ONESIGNAL] Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final notificationId = responseData['id'];
        final recipients = responseData['recipients'];
        final errors = responseData['errors'];
        
        _logger.i('🎉 [ONESIGNAL] NOTIFICAÇÃO ENVIADA COM SUCESSO!');
        _logger.i('🎉 [ONESIGNAL] Notification ID: $notificationId');
        _logger.i('🎉 [ONESIGNAL] Recipients: $recipients');
        _logger.i('🎉 [ONESIGNAL] Errors (if any): $errors');
        _logger.i('🎉 [ONESIGNAL] Timestamp: ${DateTime.now().toIso8601String()}');
        
        // Registrar no histórico com sucesso
        _logger.i('📝 [ONESIGNAL] Registrando envio no histórico...');
        await _logNotificationSent({
          'player_id': playerId,
          'notification_id': notificationId,
          'title': title,
          'body': body,
          'data': data ?? {},
          'image': imageUrl,
          'status': 'sent',
          'recipients': recipients,
          'timestamp': DateTime.now().toIso8601String(),
        });
        _logger.i('✅ [ONESIGNAL] Histórico registrado');
        
        return true;
      } else {
        _logger.e('❌ [ONESIGNAL] ERRO DA API OneSignal');
        _logger.e('❌ [ONESIGNAL] Status Code: ${response.statusCode}');
        _logger.e('❌ [ONESIGNAL] Response Body: ${response.body}');
        _logger.e('❌ [ONESIGNAL] Request Payload: ${jsonEncode(payload)}');
        
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
      _logger.e('💥 [ONESIGNAL] ERRO CRÍTICO ao enviar notificação', error: e, stackTrace: stackTrace);
      _logger.e('💥 [ONESIGNAL] Player ID: ${playerId.substring(0, 12)}...');
      _logger.e('💥 [ONESIGNAL] Título: $title');
      _logger.e('💥 [ONESIGNAL] Error details: $e');
      
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