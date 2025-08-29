import 'dart:async';

import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fcm_service.dart';
import 'notification_segmentation_service.dart';

/// Serviço para agendamento de notificações push
/// Permite programar envios para datas/horários específicos
class NotificationSchedulerService {
  factory NotificationSchedulerService() => _instance;
  NotificationSchedulerService._internal();
  static final NotificationSchedulerService _instance = NotificationSchedulerService._internal();

  final Logger _logger = Logger();
  final FCMService _fcmService = FCMService();
  final NotificationSegmentationService _segmentationService = NotificationSegmentationService();
  
  Timer? _schedulerTimer;
  bool _isRunning = false;
  
  /// Inicia o serviço de agendamento
  Future<void> startScheduler() async {
    if (_isRunning) return;
    
    _isRunning = true;
    _logger.i('Iniciando serviço de agendamento de notificações');
    
    // Verificar notificações pendentes a cada minuto
    _schedulerTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _processPendingNotifications();
    });
    
    // Processar imediatamente ao iniciar
    await _processPendingNotifications();
  }
  
  /// Para o serviço de agendamento
  void stopScheduler() {
    _schedulerTimer?.cancel();
    _schedulerTimer = null;
    _isRunning = false;
    _logger.i('Serviço de agendamento parado');
  }
  
  /// Agenda uma notificação para envio futuro
  Future<String?> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledFor,
    required String audience,
    Map<String, dynamic>? customFilters,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? createdBy,
    int? priority,
  }) async {
    try {
      // Validar data de agendamento
      if (scheduledFor.isBefore(DateTime.now())) {
        throw ArgumentError('Data de agendamento deve ser no futuro');
      }
      
      // Validar audiência
      if (!_isValidAudience(audience)) {
        throw ArgumentError('Tipo de audiência inválido: $audience');
      }
      
      // Calcular estatísticas do segmento
      final segmentStats = await _segmentationService.getSegmentStatistics(
        audience,
        customFilters,
      );
      
      final response = await Supabase.instance.client
          .from('scheduled_notifications')
          .insert({
            'title': title,
            'body': body,
            'scheduled_for': scheduledFor.toIso8601String(),
            'audience': audience,
            'custom_filters': customFilters,
            'data': data,
            'image_url': imageUrl,
            'created_by': createdBy ?? Supabase.instance.client.auth.currentUser?.id,
            'created_at': DateTime.now().toIso8601String(),
            'status': 'pending',
            'priority': priority ?? 1,
            'estimated_recipients': segmentStats['total_users'],
          })
          .select('id')
          .single();
      
      final notificationId = response['id'];
      _logger.i('Notificação agendada: $notificationId para ${scheduledFor.toIso8601String()}');
      
      return notificationId;
      
    } catch (e, stackTrace) {
      _logger.e('Erro ao agendar notificação', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Agenda notificação recorrente
  Future<String?> scheduleRecurringNotification({
    required String title,
    required String body,
    required DateTime firstScheduledFor,
    required String recurrencePattern, // 'daily', 'weekly', 'monthly'
    required String audience,
    Map<String, dynamic>? customFilters,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? createdBy,
    int? priority,
    DateTime? endDate,
    int? maxOccurrences,
  }) async {
    try {
      // Validar padrão de recorrência
      if (!['daily', 'weekly', 'monthly'].contains(recurrencePattern)) {
        throw ArgumentError('Padrão de recorrência inválido: $recurrencePattern');
      }
      
      final response = await Supabase.instance.client
          .from('recurring_notifications')
          .insert({
            'title': title,
            'body': body,
            'first_scheduled_for': firstScheduledFor.toIso8601String(),
            'recurrence_pattern': recurrencePattern,
            'audience': audience,
            'custom_filters': customFilters,
            'data': data,
            'image_url': imageUrl,
            'created_by': createdBy ?? Supabase.instance.client.auth.currentUser?.id,
            'created_at': DateTime.now().toIso8601String(),
            'is_active': true,
            'priority': priority ?? 1,
            'end_date': endDate?.toIso8601String(),
            'max_occurrences': maxOccurrences,
            'current_occurrences': 0,
          })
          .select('id')
          .single();
      
      final recurringId = response['id'];
      
      // Criar primeira ocorrência
      await _createNextRecurringOccurrence(recurringId);
      
      _logger.i('Notificação recorrente criada: $recurringId');
      return recurringId;
      
    } catch (e, stackTrace) {
      _logger.e('Erro ao criar notificação recorrente', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Cancela uma notificação agendada
  Future<bool> cancelScheduledNotification(String notificationId) async {
    try {
      await Supabase.instance.client
          .from('scheduled_notifications')
          .update({
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId)
          .eq('status', 'pending');
      
      _logger.i('Notificação cancelada: $notificationId');
      return true;
      
    } catch (e) {
      _logger.e('Erro ao cancelar notificação', error: e);
      return false;
    }
  }
  
  /// Cancela notificação recorrente
  Future<bool> cancelRecurringNotification(String recurringId) async {
    try {
      // Desativar a notificação recorrente
      await Supabase.instance.client
          .from('recurring_notifications')
          .update({
            'is_active': false,
            'cancelled_at': DateTime.now().toIso8601String(),
          })
          .eq('id', recurringId);
      
      // Cancelar todas as ocorrências pendentes
      await Supabase.instance.client
          .from('scheduled_notifications')
          .update({
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toIso8601String(),
          })
          .eq('recurring_notification_id', recurringId)
          .eq('status', 'pending');
      
      _logger.i('Notificação recorrente cancelada: $recurringId');
      return true;
      
    } catch (e) {
      _logger.e('Erro ao cancelar notificação recorrente', error: e);
      return false;
    }
  }
  
  /// Processa notificações pendentes
  Future<void> _processPendingNotifications() async {
    try {
      final now = DateTime.now();
      
      // Buscar notificações que devem ser enviadas agora
      final pendingNotifications = await Supabase.instance.client
          .from('scheduled_notifications')
          .select()
          .eq('status', 'pending')
          .lte('scheduled_for', now.toIso8601String())
          .order('priority', ascending: false)
          .order('scheduled_for', ascending: true)
          .limit(50); // Processar até 50 por vez
      
      for (final notification in pendingNotifications) {
        await _processScheduledNotification(notification);
      }
      
      // Processar notificações recorrentes
      await _processRecurringNotifications();
      
    } catch (e, stackTrace) {
      _logger.e('Erro ao processar notificações pendentes', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Processa uma notificação agendada específica
  Future<void> _processScheduledNotification(Map<String, dynamic> notification) async {
    final notificationId = notification['id'];
    
    try {
      // Marcar como processando
      await Supabase.instance.client
          .from('scheduled_notifications')
          .update({
            'status': 'processing',
            'processing_started_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
      
      // Obter tokens do segmento
      final tokens = await _segmentationService.getTokensBySegmentation(
        audience: notification['audience'],
        customFilters: notification['custom_filters'],
      );
      
      if (tokens.isEmpty) {
        await _markNotificationCompleted(notificationId, 'no_recipients');
        return;
      }
      
      // Enviar notificação
      final success = await _fcmService.sendBulkNotification(
        tokens: tokens,
        title: notification['title'],
        body: notification['body'],
        data: notification['data'] ?? {},
        imageUrl: notification['image_url'],
      );
      
      // Atualizar status
      if (success) {
        await _markNotificationCompleted(notificationId, 'sent', tokens.length);
      } else {
        await _markNotificationFailed(notificationId, 'send_failed');
      }
      
    } catch (e, stackTrace) {
      _logger.e('Erro ao processar notificação $notificationId', error: e, stackTrace: stackTrace);
      await _markNotificationFailed(notificationId, 'processing_error: ${e.toString()}');
    }
  }
  
  /// Processa notificações recorrentes
  Future<void> _processRecurringNotifications() async {
    try {
      final activeRecurring = await Supabase.instance.client
          .from('recurring_notifications')
          .select()
          .eq('is_active', true);
      
      for (final recurring in activeRecurring) {
        await _processRecurringNotification(recurring);
      }
      
    } catch (e) {
      _logger.e('Erro ao processar notificações recorrentes', error: e);
    }
  }
  
  /// Processa uma notificação recorrente específica
  Future<void> _processRecurringNotification(Map<String, dynamic> recurring) async {
    final recurringId = recurring['id'];
    
    try {
      // Verificar se precisa criar próxima ocorrência
      final lastScheduled = await Supabase.instance.client
          .from('scheduled_notifications')
          .select('scheduled_for')
          .eq('recurring_notification_id', recurringId)
          .order('scheduled_for', ascending: false)
          .limit(1);
      
      if (lastScheduled.isEmpty) {
        // Primeira ocorrência
        await _createNextRecurringOccurrence(recurringId);
        return;
      }
      
      final lastScheduledDate = DateTime.parse(lastScheduled.first['scheduled_for']);
      final nextScheduledDate = _calculateNextOccurrence(
        lastScheduledDate,
        recurring['recurrence_pattern'],
      );
      
      // Verificar se deve criar próxima ocorrência (até 7 dias no futuro)
      final maxFutureDate = DateTime.now().add(const Duration(days: 7));
      if (nextScheduledDate.isBefore(maxFutureDate)) {
        await _createRecurringOccurrence(recurringId, nextScheduledDate);
      }
      
    } catch (e) {
      _logger.e('Erro ao processar notificação recorrente $recurringId', error: e);
    }
  }
  
  /// Cria próxima ocorrência de notificação recorrente
  Future<void> _createNextRecurringOccurrence(String recurringId) async {
    final recurring = await Supabase.instance.client
        .from('recurring_notifications')
        .select()
        .eq('id', recurringId)
        .single();
    
    final firstScheduledFor = DateTime.parse(recurring['first_scheduled_for']);
    await _createRecurringOccurrence(recurringId, firstScheduledFor);
  }
  
  /// Cria uma ocorrência específica de notificação recorrente
  Future<void> _createRecurringOccurrence(String recurringId, DateTime scheduledFor) async {
    try {
      final recurring = await Supabase.instance.client
          .from('recurring_notifications')
          .select()
          .eq('id', recurringId)
          .single();
      
      // Verificar limites
      final maxOccurrences = recurring['max_occurrences'] as int?;
      final currentOccurrences = recurring['current_occurrences'] as int;
      
      if (maxOccurrences != null && currentOccurrences >= maxOccurrences) {
        // Desativar notificação recorrente
        await Supabase.instance.client
            .from('recurring_notifications')
            .update({'is_active': false})
            .eq('id', recurringId);
        return;
      }
      
      // Verificar data limite
      final endDate = recurring['end_date'] as String?;
      if (endDate != null && scheduledFor.isAfter(DateTime.parse(endDate))) {
        await Supabase.instance.client
            .from('recurring_notifications')
            .update({'is_active': false})
            .eq('id', recurringId);
        return;
      }
      
      // Calcular estatísticas do segmento
      final segmentStats = await _segmentationService.getSegmentStatistics(
        recurring['audience'],
        recurring['custom_filters'],
      );
      
      // Criar ocorrência
      await Supabase.instance.client
          .from('scheduled_notifications')
          .insert({
            'title': recurring['title'],
            'body': recurring['body'],
            'scheduled_for': scheduledFor.toIso8601String(),
            'audience': recurring['audience'],
            'custom_filters': recurring['custom_filters'],
            'data': recurring['data'],
            'image_url': recurring['image_url'],
            'created_by': recurring['created_by'],
            'created_at': DateTime.now().toIso8601String(),
            'status': 'pending',
            'priority': recurring['priority'],
            'recurring_notification_id': recurringId,
            'estimated_recipients': segmentStats['total_users'],
          });
      
      // Atualizar contador
      await Supabase.instance.client
          .from('recurring_notifications')
          .update({
            'current_occurrences': currentOccurrences + 1,
            'last_occurrence_created': DateTime.now().toIso8601String(),
          })
          .eq('id', recurringId);
      
    } catch (e) {
      _logger.e('Erro ao criar ocorrência recorrente', error: e);
    }
  }
  
  /// Calcula próxima ocorrência baseada no padrão
  DateTime _calculateNextOccurrence(DateTime lastDate, String pattern) {
    switch (pattern) {
      case 'daily':
        return lastDate.add(const Duration(days: 1));
      case 'weekly':
        return lastDate.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(lastDate.year, lastDate.month + 1, lastDate.day, lastDate.hour, lastDate.minute);
      default:
        throw ArgumentError('Padrão de recorrência inválido: $pattern');
    }
  }
  
  /// Marca notificação como concluída
  Future<void> _markNotificationCompleted(String notificationId, String status, [int? recipientCount]) async {
    await Supabase.instance.client
        .from('scheduled_notifications')
        .update({
          'status': status,
          'completed_at': DateTime.now().toIso8601String(),
          'actual_recipients': recipientCount,
        })
        .eq('id', notificationId);
  }
  
  /// Marca notificação como falhada
  Future<void> _markNotificationFailed(String notificationId, String errorMessage) async {
    await Supabase.instance.client
        .from('scheduled_notifications')
        .update({
          'status': 'failed',
          'failed_at': DateTime.now().toIso8601String(),
          'error_message': errorMessage,
        })
        .eq('id', notificationId);
  }
  
  /// Lista notificações agendadas
  Future<List<Map<String, dynamic>>> getScheduledNotifications({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final query = Supabase.instance.client
          .from('scheduled_notifications')
          .select();
      
      if (status != null) {
        query.eq('status', status);
      }
      
      final response = await query
          .order('scheduled_for', ascending: false)
          .range(offset, offset + limit - 1);
      
      return List<Map<String, dynamic>>.from(response);
      
    } catch (e) {
      _logger.e('Erro ao listar notificações agendadas', error: e);
      return [];
    }
  }
  
  /// Lista notificações recorrentes
  Future<List<Map<String, dynamic>>> getRecurringNotifications({
    bool? isActive,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final query = Supabase.instance.client
          .from('recurring_notifications')
          .select();
      
      if (isActive != null) {
        query.eq('is_active', isActive);
      }
      
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return List<Map<String, dynamic>>.from(response);
      
    } catch (e) {
      _logger.e('Erro ao listar notificações recorrentes', error: e);
      return [];
    }
  }
  
  /// Obtém estatísticas do agendador
  Future<Map<String, dynamic>> getSchedulerStatistics() async {
    try {
      final now = DateTime.now();
      final last24h = now.subtract(const Duration(hours: 24));
      
      // Notificações nas últimas 24h
      final sent24h = await Supabase.instance.client
          .from('scheduled_notifications')
          .select('id')
          .eq('status', 'sent')
          .gte('completed_at', last24h.toIso8601String());
      
      // Notificações pendentes
      final pending = await Supabase.instance.client
          .from('scheduled_notifications')
          .select('id')
          .eq('status', 'pending');
      
      // Notificações falhadas nas últimas 24h
      final failed24h = await Supabase.instance.client
          .from('scheduled_notifications')
          .select('id')
          .eq('status', 'failed')
          .gte('failed_at', last24h.toIso8601String());
      
      // Notificações recorrentes ativas
      final activeRecurring = await Supabase.instance.client
          .from('recurring_notifications')
          .select('id')
          .eq('is_active', true);
      
      return {
        'sent_last_24h': sent24h.length,
        'pending': pending.length,
        'failed_last_24h': failed24h.length,
        'active_recurring': activeRecurring.length,
        'scheduler_running': _isRunning,
        'last_check': now.toIso8601String(),
      };
      
    } catch (e) {
      _logger.e('Erro ao obter estatísticas do agendador', error: e);
      return {
        'error': e.toString(),
        'scheduler_running': _isRunning,
      };
    }
  }
  
  /// Valida tipo de audiência
  bool _isValidAudience(String audience) {
    const validAudiences = [
      'all',
      'drivers',
      'passengers',
      'active_drivers',
      'nearby_drivers',
      'frequent_users',
      'new_users',
      'custom',
    ];
    
    return validAudiences.contains(audience);
  }
}