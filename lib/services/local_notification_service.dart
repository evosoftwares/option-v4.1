import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalNotificationService {
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();
  static final LocalNotificationService _instance = LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Em Web não há suporte para notificações locais por este plugin
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettingsIOS =
        DarwinInitializationSettings(
      requestBadgePermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _createNotificationChannels();
    await _requestPermissions();
    
    _isInitialized = true;
  }

  Future<void> _createNotificationChannels() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      const rideOfferChannel = AndroidNotificationChannel(
        'ride_offers',
        'Ofertas de Corrida',
        description: 'Notificações quando uma nova corrida está disponível',
        importance: Importance.high,
        // vibrationPattern removed to avoid const factory usage in const context
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(rideOfferChannel);
    }
  }

  Future<bool> _requestPermissions() async {
    if (kIsWeb) return true;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      return status == PermissionStatus.granted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final plugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      
      final result = await plugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }
    return true;
  }

  Future<void> showRideOfferNotification({
    required String title,
    required String body,
    String? offerId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (kIsWeb) {
      // Em Web, apenas loga para debug e sai
      if (kDebugMode) {
        print('showRideOfferNotification (web): $title - $body');
      }
      return;
    }

    const androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'ride_offers',
      'Ofertas de Corrida',
      channelDescription: 'Notificações quando uma nova corrida está disponível',
      importance: Importance.high,
      priority: Priority.high,
      // vibrationPattern removed to avoid const factory usage in const context
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,
    );

    const iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      sound: 'chegoucorridaOption.mp3',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'RIDE_OFFER',
    );

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: offerId,
    );
  }

  void _onNotificationResponse(NotificationResponse response) {
    if (kDebugMode) {
      print('Notificação tocada: ${response.payload}');
    }
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
}