import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';

class NotificationIconWidget extends StatefulWidget {
  const NotificationIconWidget({super.key});

  @override
  State<NotificationIconWidget> createState() => _NotificationIconWidgetState();
}

class _NotificationIconWidgetState extends State<NotificationIconWidget> {
  final NotificationService _notificationService = NotificationService(Supabase.instance.client);
  StreamSubscription<int>? _notificationCountSub;
  int _unreadNotificationCount = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  @override
  void dispose() {
    _notificationCountSub?.cancel();
    super.dispose();
  }

  Future<void> _initNotifications() async {
    if (_isInitialized) return;
    
    try {
      final user = await UserService.getCurrentUser();
      if (user != null && mounted) {
        _notificationCountSub = _notificationService
            .streamUnreadCount(user.id)
            .listen((count) {
          if (mounted) {
            setState(() {
              _unreadNotificationCount = count;
            });
          }
        });
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('Erro ao inicializar notificações: $e');
    }
  }

  void _navigateToNotifications() {
    Navigator.pushNamed(context, '/notifications');
  }

  @override
  Widget build(BuildContext context) => Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: _navigateToNotifications,
        ),
        if (_unreadNotificationCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadNotificationCount > 99 ? '99+' : '$_unreadNotificationCount',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onError,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
}