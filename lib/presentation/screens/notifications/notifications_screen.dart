import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/notification_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/supabase_helper.dart';
import '../../widgets/logo_branding.dart';

enum NotificationScreenState {
  initial,
  loading,
  loaded,
  empty,
  error,
  refreshing,
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationService? _notificationService;
  List<NotificationModel> _notifications = [];
  StreamSubscription<List<NotificationModel>>? _notificationsSubscription;
  NotificationScreenState _screenState = NotificationScreenState.initial;
  String? _userId;
  String? _errorMessage;
  DateTime? _lastRefresh;
  Timer? _debounceTimer;
  
  static const Duration _cacheValidDuration = Duration(minutes: 5);
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    _debounceTimer?.cancel();
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
      final client = SupabaseHelper.client;
      if (client != null) {
        _notificationService = NotificationService(client);
        
        final user = await UserService.getCurrentUser();
        if (user != null) {
          setState(() {
            _userId = user.id;
          });
          
          _loadNotifications();
          _subscribeToNotifications();
        } else {
          setState(() {
            _screenState = NotificationScreenState.error;
            _errorMessage = 'Usuário não autenticado';
          });
        }
      } else {
        setState(() {
          _screenState = NotificationScreenState.error;
          _errorMessage = 'Serviço de notificações indisponível';
        });
      }
    } catch (e) {
      setState(() {
        _screenState = NotificationScreenState.error;
        _errorMessage = _getErrorMessage(e);
      });
    }
  }

  Future<void> _loadNotifications() async {
    if (_userId == null || _notificationService == null) return;
    
    // Verificar se precisa recarregar baseado no cache
    if (!_shouldRefresh() && _notifications.isNotEmpty) {
      return;
    }
    
    setState(() {
      _screenState = _notifications.isEmpty 
          ? NotificationScreenState.loading 
          : NotificationScreenState.refreshing;
      _errorMessage = null;
    });
    
    try {
      final notifications = await _notificationService!.getUserNotifications(_userId!);
      
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _screenState = notifications.isEmpty 
              ? NotificationScreenState.empty 
              : NotificationScreenState.loaded;
          _lastRefresh = DateTime.now();
        });
        
        // Salvar no cache
        await _saveNotificationsToCache(notifications);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _screenState = NotificationScreenState.error;
          _errorMessage = _getErrorMessage(e);
        });
      }
    }
  }

  Future<void> _refresh() async {
    try {
      final user = await UserService.getCurrentUser();
      if (user != null) {
        final notifications = await _notificationService!.getUserNotifications(user.id);
        setState(() {
          _notifications = notifications;
          _screenState = notifications.isEmpty 
              ? NotificationScreenState.empty 
              : NotificationScreenState.loaded;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _screenState = NotificationScreenState.error;
        _errorMessage = _getErrorMessage(e);
      });
    }
  }

  void _subscribeToNotifications() {
    if (_userId == null || _notificationService == null) return;
    
    _notificationsSubscription = _notificationService!
        .streamUserNotifications(_userId!)
        .listen((notifications) {
      // Implementar debounce para evitar múltiplas atualizações
      _debounceTimer?.cancel();
      _debounceTimer = Timer(_debounceDelay, () {
        if (mounted) {
          setState(() {
            _notifications = notifications;
            _screenState = notifications.isEmpty 
                ? NotificationScreenState.empty 
                : NotificationScreenState.loaded;
          });
        }
      });
    });
  }
  
  bool _shouldRefresh() {
    if (_lastRefresh == null) return true;
    return DateTime.now().difference(_lastRefresh!) > _cacheValidDuration;
  }
  
  Future<void> _saveNotificationsToCache(List<NotificationModel> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = notifications.map((n) => n.toJson()).toList();
      await prefs.setString('cached_notifications_$_userId', 
          notifications.map((n) => n.toJson()).toString());
    } catch (e) {
      // Falha silenciosa no cache
      debugPrint('Erro ao salvar cache de notificações: $e');
    }
  }
  
  Future<void> _loadNotificationsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_notifications_$_userId');
      if (cachedData != null && cachedData.isNotEmpty) {
        // Implementar deserialização se necessário
        // Por simplicidade, vamos apenas verificar se existe cache
      }
    } catch (e) {
      debugPrint('Erro ao carregar cache de notificações: $e');
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      await _notificationService!.markAsRead(notification.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao marcar como lida: ${_getErrorMessage(e)}')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    if (_userId == null || _notificationService == null) return;

    try {
      await _notificationService!.markAllAsRead(_userId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todas as notificações foram marcadas como lidas')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao marcar todas como lidas: ${_getErrorMessage(e)}')),
        );
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('network')) {
      return 'Verifique sua conexão com a internet';
    } else if (error.toString().contains('timeout')) {
      return 'Tempo limite excedido. Tente novamente';
    } else if (error.toString().contains('unauthorized')) {
      return 'Acesso não autorizado';
    } else if (error.toString().contains('not found')) {
      return 'Dados não encontrados';
    } else {
      return 'Erro inesperado. Tente novamente mais tarde';
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
      body: _buildBody(colorScheme),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    switch (_screenState) {
      case NotificationScreenState.initial:
      case NotificationScreenState.loading:
        return _buildLoadingSkeleton();
      case NotificationScreenState.loaded:
      case NotificationScreenState.refreshing:
        return _buildNotificationsList();
      case NotificationScreenState.empty:
        return _buildEmptyState(colorScheme);
      case NotificationScreenState.error:
        return _buildErrorState(colorScheme);
    }
  }
  
  Widget _buildLoadingSkeleton() => ListView.builder(
      padding: AppSpacing.paddingLg,
      itemCount: 6,
      itemBuilder: (context, index) => _NotificationSkeleton(),
    );
  
  Widget _buildNotificationsList() => RefreshIndicator(
      onRefresh: () async {
        await _loadNotifications();
      },
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
    );
  
  Widget _buildEmptyState(ColorScheme colorScheme) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nenhuma notificação',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Você não possui notificações no momento',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar'),
          ),
        ],
      ),
    );
  
  Widget _buildErrorState(ColorScheme colorScheme) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Erro ao carregar',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _errorMessage ?? 'Ocorreu um erro inesperado',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
}

class _NotificationSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    height: 14,
                    width: AppSpacing.avatarXl * 1.67,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    height: AppSpacing.xs * 3,
                    width: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
                            width: AppSpacing.sm,
                            height: AppSpacing.sm,
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