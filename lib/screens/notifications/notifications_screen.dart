import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/notification_service.dart';
import '../../services/user_service.dart';
import '../../widgets/logo_branding.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService(Supabase.instance.client);
  List<NotificationModel> _notifications = [];
  StreamSubscription<List<NotificationModel>>? _notificationsSubscription;
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _navigateToMenu() async {
    final user = await UserService.getCurrentUser();
    if (!mounted) {
      return;
    }
    
    if (user != null) {
      if (user.userType == 'driver') {
        await Navigator.pushNamed(context, '/driver_menu');
      } else {
        await Navigator.pushNamed(context, '/user_menu');
      }
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      final user = await UserService.getCurrentUser();
      if (user != null) {
        setState(() {
          _userId = user.id;
        });
        
        _loadNotifications();
        _subscribeToNotifications();
      }
    } catch (e) {
      debugPrint('Erro ao inicializar notificações: $e');
    }
  }

  Future<void> _loadNotifications() async {
    if (_userId == null) return;
    
    try {
      final notifications = await _notificationService.getUserNotifications(_userId!);
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar notificações: $e')),
        );
      }
    }
  }

  void _subscribeToNotifications() {
    if (_userId == null) return;
    
    _notificationsSubscription = _notificationService
        .streamUserNotifications(_userId!)
        .listen((notifications) {
      setState(() {
        _notifications = notifications;
      });
    });
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      await _notificationService.markAsRead(notification.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao marcar como lida: $e')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    if (_userId == null) return;

    try {
      await _notificationService.markAllAsRead(_userId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todas as notificações foram marcadas como lidas')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao marcar todas como lidas: $e')),
        );
      }
    }
  }

  String _formatNotificationTime(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}min atrás';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h atrás';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d atrás';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'offer':
        return Icons.local_taxi;
      case 'trip':
        return Icons.directions_car;
      case 'chat':
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type, ColorScheme colorScheme) {
    switch (type) {
      case 'offer':
        return colorScheme.primary;
      case 'trip':
        return colorScheme.secondary;
      case 'chat':
        return colorScheme.tertiary;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: StandardAppBar(
        title: 'Notificações',
        showMenuIcon: false,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Marcar todas como lidas',
                style: AppTypography.labelMedium.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState(colorScheme)
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: AppSpacing.paddingLg,
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _NotificationTile(
                        notification: notification,
                        onTap: () => _markAsRead(notification),
                        formatTime: _formatNotificationTime,
                        getIcon: _getNotificationIcon,
                        getColor: _getNotificationColor,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: AppSpacing.iconXxl,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nenhuma notificação',
            style: AppTypography.titleLarge.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Você receberá notificações sobre\ncorridas, mensagens e atualizações aqui.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
}

class _NotificationTile extends StatelessWidget {

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.formatTime,
    required this.getIcon,
    required this.getColor,
  });
  final NotificationModel notification;
  final VoidCallback onTap;
  final String Function(DateTime) formatTime;
  final IconData Function(String) getIcon;
  final Color Function(String, ColorScheme) getColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUnread = !notification.isRead;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isUnread 
            ? colorScheme.primaryContainer.withOpacity(0.1)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isUnread 
              ? colorScheme.primary.withOpacity(0.2)
              : colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: getColor(notification.type, colorScheme).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Icon(
                  getIcon(notification.type),
                  color: getColor(notification.type, colorScheme),
                  size: AppSpacing.iconSm,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTypography.titleMedium.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      notification.message,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      formatTime(notification.createdAt),
                      style: AppTypography.labelSmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}