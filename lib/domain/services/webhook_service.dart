import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/exceptions/app_exceptions.dart';

/// Service for managing webhook processing and duplicate prevention
class WebhookService {
  final SupabaseClient _supabase;

  WebhookService(this._supabase);

  /// Check if a webhook event has already been processed
  Future<bool> isEventProcessed(String eventId) async {
    try {
      final result = await _supabase
          .from('asaas_webhook_events')
          .select('asaas_event_id')
          .eq('asaas_event_id', eventId)
          .maybeSingle();
      
      return result != null;
    } catch (e) {
      print('Error checking webhook event status: $e');
      return false; // Assume not processed if error
    }
  }

  /// Record a webhook event as processed
  Future<void> recordProcessedEvent({
    required String eventId,
    required String eventType,
    required String paymentId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await _supabase.from('asaas_webhook_events').insert({
        'asaas_event_id': eventId,
        'event_type': eventType,
        'payment_id': paymentId,
        'payload': payload,
      });
    } on PostgrestException catch (e) {
      // Handle unique constraint violation (duplicate)
      if (e.code == '23505') {
        print('Webhook event already recorded: $eventId');
        return;
      }
      throw DatabaseException('Erro ao registrar webhook processado', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado ao registrar webhook', e.toString());
    }
  }

  /// Get all webhook events for a specific payment
  Future<List<Map<String, dynamic>>> getPaymentWebhookEvents(String paymentId) async {
    try {
      final data = await _supabase
          .from('asaas_webhook_events')
          .select()
          .eq('payment_id', paymentId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(data);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar eventos de webhook', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado ao buscar eventos de webhook: $e');
    }
  }

  /// Clean old webhook events (maintenance)
  Future<int> cleanOldEvents(int days) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final response = await _supabase
          .from('asaas_webhook_events')
          .delete()
          .lt('created_at', cutoffDate.toIso8601String());
      
      return response.length;
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao limpar webhooks antigos', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado ao limpar webhooks antigos: $e');
    }
  }
}