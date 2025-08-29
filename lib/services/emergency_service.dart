import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/supabase_helper.dart';
import '../models/emergency_contact.dart';
import '../models/emergency.dart';
import '../models/supabase/app_user.dart';
import '../models/user.dart' as app;
import '../services/location_service.dart';
import '../services/user_service.dart';



/// Serviço de emergência e segurança
class EmergencyService {
  static final SupabaseClient _supabase = SupabaseHelper.client!;
  static final LocationService _locationService = LocationService(
    apiKey: '', // API key será configurada externamente
  );
  // Remover instância do NotificationService por enquanto
  // static final NotificationService _notificationService = NotificationService();

  /// Converte User para AppUser
  static AppUser _convertUserToAppUser(app.User user) => AppUser(
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      phone: user.phone ?? '',
      userType: user.userType,
      status: user.status,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      userId: user.id, // Use id instead of removed userId
    );

  /// Dispara uma emergência
  static Future<Emergency> triggerEmergency({
    EmergencyType type = EmergencyType.panic,
    String? description,
  }) async {
    try {
      // Obter usuário atual
      final user = await UserService.getCurrentUser();
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Converter User para AppUser
      final appUser = _convertUserToAppUser(user);

      // Obter localização atual
      Position? position;
      var address = 'Localização não disponível';
      
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        
        // Implementar busca de endereço posteriormente
        address = 'Localização: ${position.latitude}, ${position.longitude}';
      } catch (e) {
        if (kDebugMode) {
          print('Erro ao obter localização: $e');
        }
      }

      // Criar registro de emergência
      final emergency = await _createEmergencyRecord(
        user: appUser,
        type: type,
        latitude: position?.latitude ?? 0.0,
        longitude: position?.longitude ?? 0.0,
        address: address,
        description: description,
      );

      // Enviar notificações de emergência
      await _sendEmergencyNotifications(emergency, appUser);

      // Ligar para emergência se necessário
      if (type == EmergencyType.medical || type == EmergencyType.accident) {
        await _promptEmergencyCall();
      }

      return emergency;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao disparar emergência: $e');
      }
      rethrow;
    }
  }

  /// Cria registro de emergência no banco
  static Future<Emergency> _createEmergencyRecord({
    required AppUser user,
    required EmergencyType type,
    required double latitude,
    required double longitude,
    required String address,
    String? description,
  }) async {
    final response = await _supabase.from('emergencies').insert({
      'user_id': user.id,
      'type': type.name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'description': description,
      'timestamp': DateTime.now().toIso8601String(),
      'is_resolved': false,
    }).select().single();

    return Emergency.fromJson(response);
  }

  /// Envia notificações de emergência
  static Future<void> _sendEmergencyNotifications(
    Emergency emergency,
    AppUser user,
  ) async {
    try {
      // Notificar contatos de emergência do usuário
      final emergencyContacts = await _getEmergencyContacts(user.id);
      
      for (final contactId in emergencyContacts) {
        // Implementar notificação posteriormente
        print('Notificando contato de emergência: $contactId');
      }

      // Notificar administradores do sistema
      await _notifySystemAdministrators(emergency, user);
      
      // Notificar motoristas próximos se o usuário for passageiro
      if (user.userType == 'passenger') {
        await _notifyNearbyDrivers(emergency, user);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao enviar notificações de emergência: $e');
      }
    }
  }

  /// Obtém contatos de emergência do usuário
  static Future<List<String>> _getEmergencyContacts(String userId) async {
    try {
      final response = await _supabase
          .from('emergency_contacts')
          .select('contact_user_id')
          .eq('user_id', userId)
          .eq('is_active', true);

      return response.map<String>((contact) => contact['contact_user_id']).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao obter contatos de emergência: $e');
      }
      return [];
    }
  }

  /// Notifica administradores do sistema
  static Future<void> _notifySystemAdministrators(
    Emergency emergency,
    AppUser user,
  ) async {
    try {
      // Buscar administradores
      final admins = await _supabase
          .from('app_users')
          .select('id')
          .eq('user_type', 'admin')
          .eq('is_active', true);

      for (final admin in admins) {
        // Implementar notificação para administradores posteriormente
        print('Notificando administrador: ${admin['id']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao notificar administradores: $e');
      }
    }
  }

  /// Notifica motoristas próximos
  static Future<void> _notifyNearbyDrivers(
    Emergency emergency,
    AppUser user,
  ) async {
    try {
      // Buscar motoristas online em um raio de 5km
      final nearbyDrivers = await _supabase.rpc('get_nearby_drivers', params: {
        'user_lat': emergency.latitude,
        'user_lng': emergency.longitude,
        'radius_km': 5,
      });

      for (final driver in nearbyDrivers) {
        // Implementar notificação para motoristas posteriormente
        print('Notificando motorista próximo: ${driver['user_id']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao notificar motoristas próximos: $e');
      }
    }
  }

  /// Solicita ligação para emergência
  static Future<void> _promptEmergencyCall() async {
    try {
      const emergencyNumber = 'tel:192'; // SAMU
      final uri = Uri.parse(emergencyNumber);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao iniciar ligação de emergência: $e');
      }
    }
  }

  /// Adiciona contato de emergência
  static Future<void> addEmergencyContact({
    required String userId,
    required String contactUserId,
    required String contactName,
    required String contactPhone,
  }) async {
    await _supabase.from('emergency_contacts').insert({
      'user_id': userId,
      'contact_user_id': contactUserId,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Remove contato de emergência
  static Future<void> removeEmergencyContact({
    required String userId,
    required String contactUserId,
  }) async {
    await _supabase
        .from('emergency_contacts')
        .update({'is_active': false})
        .eq('user_id', userId)
        .eq('contact_user_id', contactUserId);
  }

  /// Lista contatos de emergência
  static Future<List<EmergencyContact>> getEmergencyContacts(
    String userId,
  ) async {
    final response = await _supabase
        .from('emergency_contacts')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return response
        .map<EmergencyContact>(EmergencyContact.fromJson)
        .toList();
  }

  /// Adiciona contato de emergência simples
  static Future<void> addEmergencyContactSimple({
    required String userId,
    required String name,
    required String phone,
    required String relationship,
  }) async {
    await _supabase.from('emergency_contacts').insert({
      'user_id': userId,
      'contact_user_id': '', // Vazio para contatos externos
      'contact_name': name,
      'contact_phone': phone,
      'relationship': relationship,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Remove contato de emergência por ID
  static Future<void> removeEmergencyContactById(String contactId) async {
    await _supabase
        .from('emergency_contacts')
        .update({'is_active': false})
        .eq('id', contactId);
  }

  /// Resolve uma emergência
  static Future<void> resolveEmergency(String emergencyId) async {
    await _supabase.from('emergencies').update({
      'is_resolved': true,
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', emergencyId);
  }

  /// Lista emergências do usuário
  static Future<List<Emergency>> getUserEmergencies(String userId) async {
    final response = await _supabase
        .from('emergencies')
        .select()
        .eq('user_id', userId)
        .order('timestamp', ascending: false);

    return response.map<Emergency>(Emergency.fromJson).toList();
  }

  /// Compartilha localização em tempo real
  static Future<String> startLocationSharing({
    required String userId,
    required Duration duration,
    List<String>? sharedWithUserIds,
  }) async {
    final response = await _supabase.from('location_sharing').insert({
      'user_id': userId,
      'expires_at': DateTime.now().add(duration).toIso8601String(),
      'shared_with_users': sharedWithUserIds,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    final sharingId = response['id'];

    // Iniciar stream de localização
    _startLocationStream(sharingId, userId);

    return sharingId;
  }

  /// Inicia stream de localização
  static void _startLocationStream(String sharingId, String userId) {
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        // Verificar se o compartilhamento ainda está ativo
        final sharing = await _supabase
            .from('location_sharing')
            .select('is_active, expires_at')
            .eq('id', sharingId)
            .single();

        if (!sharing['is_active'] ||
            DateTime.parse(sharing['expires_at']).isBefore(DateTime.now())) {
          timer.cancel();
          return;
        }

        // Obter localização atual
        final position = await Geolocator.getCurrentPosition();

        // Atualizar localização no banco
        await _supabase.from('location_updates').insert({
          'sharing_id': sharingId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        if (kDebugMode) {
          print('Erro no stream de localização: $e');
        }
        timer.cancel();
      }
    });
  }

  /// Para compartilhamento de localização
  static Future<void> stopLocationSharing(String sharingId) async {
    await _supabase.from('location_sharing').update({
      'is_active': false,
      'ended_at': DateTime.now().toIso8601String(),
    }).eq('id', sharingId);
  }

  /// Obtém localização compartilhada
  static Future<Map<String, dynamic>?> getSharedLocation(
    String sharingId,
  ) async {
    try {
      final response = await _supabase
          .from('location_updates')
          .select()
          .eq('sharing_id', sharingId)
          .order('timestamp', ascending: false)
          .limit(1)
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }
}