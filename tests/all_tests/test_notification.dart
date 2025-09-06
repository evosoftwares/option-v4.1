import 'dart:io';
import 'lib/services/onesignal_service.dart';

/// Script para testar notificações OneSignal com som .mp3
void main() async {
  print('🧪 Testando notificação OneSignal com som personalizado...');
  
  // Player ID obtido dos logs do app
  const playerId = 'd37526bd-63a5-4239-a955-dcbf3651c1c4';
  
  // Inicializar OneSignal Service
  final oneSignalService = OneSignalService();
  
  // Enviar notificação de teste para motorista com som personalizado
  final success = await oneSignalService.sendNotificationToPlayerId(
    playerId: playerId,
    title: '🚗 Nova Solicitação de Viagem - TESTE',
    body: 'De: Shopping Center\nPara: Aeroporto Internacional\nValor: R\$ 25,00',
    data: {
      'type': 'trip_request',
      'request_id': 'test-request-123',
      'origin': 'Shopping Center',
      'destination': 'Aeroporto Internacional',
      'estimated_fare': '25.00',
      'expires_at': DateTime.now().add(Duration(minutes: 5)).toIso8601String(),
    },
  );
  
  if (success) {
    print('✅ Notificação de teste enviada com sucesso!');
    print('🔊 Som personalizado: chegoucorridaoption.mp3 (Android)');
    print('🔊 Som personalizado: chegoucorridaOption.mp3 (iOS)');
    print('');
    print('👂 Agora verifique se o celular do motorista tocou o som personalizado!');
  } else {
    print('❌ Falha ao enviar notificação de teste.');
  }
  
  exit(0);
}