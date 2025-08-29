import 'dart:async';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço para gerenciamento de histórico e analytics de notificações
/// Registra, consulta e analisa dados de notificações enviadas e recebidas
class NotificationHistoryService {
  factory NotificationHistoryService() => _instance;
  NotificationHistoryService._internal();
  static final NotificationHistoryService _instance = NotificationHistoryService._internal();

  final Logger _logger = Logger();
  
  /// Registra notificação enviada no histórico
  Future<String?> logNotificationSent({
    required String title,
    required String body,
    required List<String> recipients,
    required String audience,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? campaignId,
    String? senderId,
    Map<String, dynamic>? segmentationCriteria,
  }) async {
    try {
      final response = await Supabase.instance.client
          .from('notification_history')
          .insert({
            'title': title,
            'body': body,
            'recipient_count': recipients.length,
            'audience': audience,
            'data': data,
            'image_url': imageUrl,
            'campaign_id': campaignId,
            'sender_id': senderId ?? Supabase.instance.client.auth.currentUser?.id,
            'sent_at': DateTime.now().toIso8601String(),
            'platform': Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'web',
            'status': 'sent',
            'segmentation_criteria': segmentationCriteria,
            'type': 'outbound',
          })
          .select('id')
          .single();
      
      final historyId = response['id'];
      
      // Registrar destinatários individuais
      await _logRecipients(historyId, recipients);
      
      _logger.i('Notificação registrada no histórico: $historyId');
      return historyId;
      
    } catch (e, stackTrace) {
      _logger.e('Erro ao registrar notificação no histórico', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Registra notificação recebida no histórico
  Future<String?> logNotificationReceived({
    required String title,
    required String body,
    String? messageId,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? userId,
  }) async {
    try {
      final response = await Supabase.instance.client
          .from('notification_history')
          .insert({
            'title': title,
            'body': body,
            'message_id': messageId,
            'data': data,
            'image_url': imageUrl,
            'user_id': userId ?? Supabase.instance.client.auth.currentUser?.id,
            'received_at': DateTime.now().toIso8601String(),
            'platform': Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'web',
            'status': 'received',
            'type': 'inbound',
          })
          .select('id')
          .single();
      
      final historyId = response['id'];
      _logger.i('Notificação recebida registrada: $historyId');
      return historyId;
      
    } catch (e) {
      _logger.e('Erro ao registrar notificação recebida', error: e);
      return null;
    }
  }
  
  /// Registra interação com notificação (tap, dismiss, etc.)
  Future<bool> logNotificationInteraction({
    required String historyId,
    required String interactionType, // 'opened', 'dismissed', 'action_clicked'
    String? actionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await Supabase.instance.client
          .from('notification_interactions')
          .insert({
            'notification_history_id': historyId,
            'interaction_type': interactionType,
            'action_id': actionId,
            'metadata': metadata,
            'user_id': Supabase.instance.client.auth.currentUser?.id,
            'interacted_at': DateTime.now().toIso8601String(),
            'platform': Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'web',
          });
      
      // Atualizar estatísticas na tabela principal
      await _updateNotificationStats(historyId, interactionType);
      
      _logger.i('Interação registrada: $interactionType para $historyId');
      return true;
      
    } catch (e) {
      _logger.e('Erro ao registrar interação', error: e);
      return false;
    }
  }
  
  /// Registra falha no envio de notificação
  Future<bool> logNotificationFailure({
    required String historyId,
    required String errorMessage,
    String? errorCode,
    Map<String, dynamic>? errorDetails,
  }) async {
    try {
      await Supabase.instance.client
          .from('notification_history')
          .update({
            'status': 'failed',
            'error_message': errorMessage,
            'error_code': errorCode,
            'error_details': errorDetails,
            'failed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', historyId);
      
      _logger.w('Falha de notificação registrada: $historyId - $errorMessage');
      return true;
      
    } catch (e) {
      _logger.e('Erro ao registrar falha de notificação', error: e);
      return false;
    }
  }
  
  /// Obtém histórico de notificações com filtros
  Future<List<Map<String, dynamic>>> getNotificationHistory({
    String? type, // 'inbound', 'outbound'
    String? status, // 'sent', 'received', 'failed'
    String? audience,
    String? campaignId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final query = Supabase.instance.client
          .from('notification_history')
          .select();
      
      if (type != null) {
        query.eq('type', type);
      }
      
      if (status != null) {
        query.eq('status', status);
      }
      
      if (audience != null) {
        query.eq('audience', audience);
      }
      
      if (campaignId != null) {
        query.eq('campaign_id', campaignId);
      }
      
      if (startDate != null) {
        query.gte('sent_at', startDate.toIso8601String());
      }
      
      if (endDate != null) {
        query.lte('sent_at', endDate.toIso8601String());
      }
      
      final response = await query
          .order('sent_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return List<Map<String, dynamic>>.from(response);
      
    } catch (e) {
      _logger.e('Erro ao obter histórico de notificações', error: e);
      return [];
    }
  }
  
  /// Obtém analytics detalhados de notificações
  Future<Map<String, dynamic>> getNotificationAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? audience,
    String? campaignId,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();
      
      // Estatísticas básicas
      final basicStats = await _getBasicStats(start, end, audience, campaignId);
      
      // Taxa de abertura
      final openRates = await _getOpenRates(start, end, audience, campaignId);
      
      // Estatísticas por plataforma
      final platformStats = await _getPlatformStats(start, end, audience, campaignId);
      
      // Estatísticas por audiência
      final audienceStats = await _getAudienceStats(start, end);
      
      // Tendências temporais
      final timeSeriesData = await _getTimeSeriesData(start, end, audience, campaignId);
      
      // Top campanhas
      final topCampaigns = await _getTopCampaigns(start, end);
      
      return {
        'period': {
          'start_date': start.toIso8601String(),
          'end_date': end.toIso8601String(),
        },
        'basic_stats': basicStats,
        'open_rates': openRates,
        'platform_stats': platformStats,
        'audience_stats': audienceStats,
        'time_series': timeSeriesData,
        'top_campaigns': topCampaigns,
        'generated_at': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      _logger.e('Erro ao gerar analytics', error: e);
      return {
        'error': e.toString(),
        'generated_at': DateTime.now().toIso8601String(),
      };
    }
  }
  
  /// Obtém estatísticas de uma campanha específica
  Future<Map<String, dynamic>> getCampaignStats(String campaignId) async {
    try {
      // Notificações da campanha
      final notifications = await Supabase.instance.client
          .from('notification_history')
          .select()
          .eq('campaign_id', campaignId);
      
      if (notifications.isEmpty) {
        return {'error': 'Campanha não encontrada'};
      }
      
      final totalSent = notifications.length;
      final totalRecipients = notifications.fold<int>(
        0,
        (sum, notification) => sum + (notification['recipient_count'] as int? ?? 0),
      );
      
      // Interações da campanha
      final interactions = await Supabase.instance.client
          .rpc('get_campaign_interactions', params: {
            'campaign_id_param': campaignId,
          });
      
      final opens = interactions.where((i) => i['interaction_type'] == 'opened').length;
      final dismissals = interactions.where((i) => i['interaction_type'] == 'dismissed').length;
      
      final openRate = totalRecipients > 0 ? (opens / totalRecipients * 100) : 0.0;
      
      return {
        'campaign_id': campaignId,
        'total_notifications': totalSent,
        'total_recipients': totalRecipients,
        'total_opens': opens,
        'total_dismissals': dismissals,
        'open_rate': openRate,
        'first_sent': notifications.isNotEmpty ? notifications.last['sent_at'] : null,
        'last_sent': notifications.isNotEmpty ? notifications.first['sent_at'] : null,
      };
      
    } catch (e) {
      _logger.e('Erro ao obter estatísticas da campanha', error: e);
      return {'error': e.toString()};
    }
  }
  
  /// Registra destinatários individuais
  Future<void> _logRecipients(String historyId, List<String> recipients) async {
    try {
      final recipientData = recipients.map((token) => {
        'notification_history_id': historyId,
        'fcm_token': token,
        'created_at': DateTime.now().toIso8601String(),
      }).toList();
      
      // Inserir em lotes de 100
      for (var i = 0; i < recipientData.length; i += 100) {
        final batch = recipientData.skip(i).take(100).toList();
        await Supabase.instance.client
            .from('notification_recipients')
            .insert(batch);
      }
      
    } catch (e) {
      _logger.e('Erro ao registrar destinatários', error: e);
    }
  }
  
  /// Atualiza estatísticas de notificação
  Future<void> _updateNotificationStats(String historyId, String interactionType) async {
    try {
      final currentStats = await Supabase.instance.client
          .from('notification_history')
          .select('opens_count, dismissals_count, actions_count')
          .eq('id', historyId)
          .single();
      
      final updates = <String, dynamic>{};
      
      switch (interactionType) {
        case 'opened':
          updates['opens_count'] = (currentStats['opens_count'] as int? ?? 0) + 1;
          break;
        case 'dismissed':
          updates['dismissals_count'] = (currentStats['dismissals_count'] as int? ?? 0) + 1;
          break;
        case 'action_clicked':
          updates['actions_count'] = (currentStats['actions_count'] as int? ?? 0) + 1;
          break;
      }
      
      if (updates.isNotEmpty) {
        await Supabase.instance.client
            .from('notification_history')
            .update(updates)
            .eq('id', historyId);
      }
      
    } catch (e) {
      _logger.e('Erro ao atualizar estatísticas', error: e);
    }
  }
  
  /// Obtém estatísticas básicas
  Future<Map<String, dynamic>> _getBasicStats(
    DateTime start,
    DateTime end,
    String? audience,
    String? campaignId,
  ) async {
    final query = Supabase.instance.client
        .from('notification_history')
        .select('status, recipient_count')
        .gte('sent_at', start.toIso8601String())
        .lte('sent_at', end.toIso8601String());
    
    if (audience != null) {
      query.eq('audience', audience);
    }
    
    if (campaignId != null) {
      query.eq('campaign_id', campaignId);
    }
    
    final notifications = await query;
    
    final totalSent = notifications.where((n) => n['status'] == 'sent').length;
    final totalFailed = notifications.where((n) => n['status'] == 'failed').length;
    final totalRecipients = notifications.fold<int>(
      0,
      (sum, n) => sum + (n['recipient_count'] as int? ?? 0),
    );
    
    return {
      'total_notifications': notifications.length,
      'total_sent': totalSent,
      'total_failed': totalFailed,
      'total_recipients': totalRecipients,
      'success_rate': notifications.isNotEmpty ? (totalSent / notifications.length * 100) : 0.0,
    };
  }
  
  /// Obtém taxas de abertura
  Future<Map<String, dynamic>> _getOpenRates(
    DateTime start,
    DateTime end,
    String? audience,
    String? campaignId,
  ) async {
    // Implementar usando função SQL personalizada
    final result = await Supabase.instance.client
        .rpc('get_open_rates', params: {
          'start_date': start.toIso8601String(),
          'end_date': end.toIso8601String(),
          'audience_filter': audience,
          'campaign_filter': campaignId,
        });
    
    return Map<String, dynamic>.from(result.first ?? {});
  }
  
  /// Obtém estatísticas por plataforma
  Future<List<Map<String, dynamic>>> _getPlatformStats(
    DateTime start,
    DateTime end,
    String? audience,
    String? campaignId,
  ) async {
    final query = Supabase.instance.client
        .from('notification_history')
        .select('platform, status')
        .gte('sent_at', start.toIso8601String())
        .lte('sent_at', end.toIso8601String());
    
    if (audience != null) {
      query.eq('audience', audience);
    }
    
    if (campaignId != null) {
      query.eq('campaign_id', campaignId);
    }
    
    final notifications = await query;
    
    final platformGroups = <String, Map<String, int>>{};
    
    for (final notification in notifications) {
      final platform = notification['platform'] as String;
      final status = notification['status'] as String;
      
      platformGroups[platform] ??= {'sent': 0, 'failed': 0};
      platformGroups[platform]![status] = (platformGroups[platform]![status] ?? 0) + 1;
    }
    
    return platformGroups.entries.map((entry) => {
      'platform': entry.key,
      'sent': entry.value['sent'] ?? 0,
      'failed': entry.value['failed'] ?? 0,
      'total': (entry.value['sent'] ?? 0) + (entry.value['failed'] ?? 0),
    }).toList();
  }
  
  /// Obtém estatísticas por audiência
  Future<List<Map<String, dynamic>>> _getAudienceStats(
    DateTime start,
    DateTime end,
  ) async {
    final notifications = await Supabase.instance.client
        .from('notification_history')
        .select('audience, status, recipient_count')
        .gte('sent_at', start.toIso8601String())
        .lte('sent_at', end.toIso8601String());
    
    final audienceGroups = <String, Map<String, dynamic>>{};
    
    for (final notification in notifications) {
      final audience = notification['audience'] as String;
      final status = notification['status'] as String;
      final recipients = notification['recipient_count'] as int? ?? 0;
      
      audienceGroups[audience] ??= {
        'sent': 0,
        'failed': 0,
        'total_recipients': 0,
      };
      
      audienceGroups[audience]![status] = (audienceGroups[audience]![status] ?? 0) + 1;
      audienceGroups[audience]!['total_recipients'] = 
          (audienceGroups[audience]!['total_recipients'] ?? 0) + recipients;
    }
    
    return audienceGroups.entries.map((entry) => {
      'audience': entry.key,
      'sent': entry.value['sent'] ?? 0,
      'failed': entry.value['failed'] ?? 0,
      'total_recipients': entry.value['total_recipients'] ?? 0,
    }).toList();
  }
  
  /// Obtém dados de série temporal
  Future<List<Map<String, dynamic>>> _getTimeSeriesData(
    DateTime start,
    DateTime end,
    String? audience,
    String? campaignId,
  ) async {
    // Implementar usando função SQL para agrupar por dia/hora
    final result = await Supabase.instance.client
        .rpc('get_notification_time_series', params: {
          'start_date': start.toIso8601String(),
          'end_date': end.toIso8601String(),
          'audience_filter': audience,
          'campaign_filter': campaignId,
        });
    
    return List<Map<String, dynamic>>.from(result);
  }
  
  /// Obtém top campanhas
  Future<List<Map<String, dynamic>>> _getTopCampaigns(
    DateTime start,
    DateTime end,
  ) async {
    final notifications = await Supabase.instance.client
        .from('notification_history')
        .select('campaign_id, recipient_count, opens_count')
        .gte('sent_at', start.toIso8601String())
        .lte('sent_at', end.toIso8601String())
        .not('campaign_id', 'is', null);
    
    final campaignGroups = <String, Map<String, dynamic>>{};
    
    for (final notification in notifications) {
      final campaignId = notification['campaign_id'] as String;
      final recipients = notification['recipient_count'] as int? ?? 0;
      final opens = notification['opens_count'] as int? ?? 0;
      
      campaignGroups[campaignId] ??= {
        'total_recipients': 0,
        'total_opens': 0,
        'notification_count': 0,
      };
      
      campaignGroups[campaignId]!['total_recipients'] = 
          (campaignGroups[campaignId]!['total_recipients'] ?? 0) + recipients;
      campaignGroups[campaignId]!['total_opens'] = 
          (campaignGroups[campaignId]!['total_opens'] ?? 0) + opens;
      campaignGroups[campaignId]!['notification_count'] = 
          (campaignGroups[campaignId]!['notification_count'] ?? 0) + 1;
    }
    
    final campaigns = campaignGroups.entries.map((entry) {
      final totalRecipients = entry.value['total_recipients'] as int;
      final totalOpens = entry.value['total_opens'] as int;
      
      return {
        'campaign_id': entry.key,
        'total_recipients': totalRecipients,
        'total_opens': totalOpens,
        'notification_count': entry.value['notification_count'],
        'open_rate': totalRecipients > 0 ? (totalOpens / totalRecipients * 100) : 0.0,
      };
    }).toList();
    
    // Ordenar por taxa de abertura
    campaigns.sort((a, b) => (b['open_rate'] as double).compareTo(a['open_rate'] as double));
    
    return campaigns.take(10).toList();
  }
  
  /// Limpa histórico antigo
  Future<int> cleanupOldHistory({int daysToKeep = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      final deletedRows = await Supabase.instance.client
          .from('notification_history')
          .delete()
          .lt('sent_at', cutoffDate.toIso8601String());
      
      _logger.i('Histórico limpo: registros anteriores a ${cutoffDate.toIso8601String()}');
      return deletedRows.length;
      
    } catch (e) {
      _logger.e('Erro ao limpar histórico antigo', error: e);
      return 0;
    }
  }
  
  /// Exporta dados de analytics
  Future<Map<String, dynamic>> exportAnalytics({
    required DateTime startDate,
    required DateTime endDate,
    String? format, // 'json', 'csv'
  }) async {
    try {
      final analytics = await getNotificationAnalytics(
        startDate: startDate,
        endDate: endDate,
      );
      
      final exportData = {
        'export_info': {
          'generated_at': DateTime.now().toIso8601String(),
          'period_start': startDate.toIso8601String(),
          'period_end': endDate.toIso8601String(),
          'format': format ?? 'json',
        },
        'analytics': analytics,
      };
      
      _logger.i('Analytics exportados para período: ${startDate.toIso8601String()} - ${endDate.toIso8601String()}');
      return exportData;
      
    } catch (e) {
      _logger.e('Erro ao exportar analytics', error: e);
      return {'error': e.toString()};
    }
  }
}