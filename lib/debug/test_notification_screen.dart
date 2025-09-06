import 'package:flutter/material.dart';
import '../services/onesignal_service.dart';

class TestNotificationScreen extends StatefulWidget {
  const TestNotificationScreen({super.key});

  @override
  State<TestNotificationScreen> createState() => _TestNotificationScreenState();
}

class _TestNotificationScreenState extends State<TestNotificationScreen> {
  bool _isSending = false;
  String? _result;

  Future<void> _sendTestNotification() async {
    setState(() {
      _isSending = true;
      _result = null;
    });

    try {
      // Player ID obtido dos logs do app
      const playerId = 'd37526bd-63a5-4239-a955-dcbf3651c1c4';
      
      final success = await OneSignalService().sendNotificationToPlayerId(
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

      setState(() {
        _result = success 
          ? '✅ Notificação enviada com sucesso!\n🔊 Som personalizado configurado para motoristas'
          : '❌ Falha ao enviar notificação';
      });
    } catch (e) {
      setState(() {
        _result = '❌ Erro: $e';
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste Notificação OneSignal'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🧪 Teste de Notificação com Som .mp3',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📱 Player ID:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('d37526bd-63a5-4239-a955-dcbf3651c1c4', style: TextStyle(fontSize: 12)),
                    SizedBox(height: 12),
                    
                    Text('🔊 Sons Configurados:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Android: chegoucorridaoption.mp3'),
                    Text('iOS: chegoucorridaOption.mp3'),
                    SizedBox(height: 12),
                    
                    Text('📋 Tipo de Notificação:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('trip_request (som personalizado ativado)'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: _isSending ? null : _sendTestNotification,
              icon: _isSending 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : const Icon(Icons.send),
              label: Text(_isSending ? 'Enviando...' : 'Enviar Notificação de Teste'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (_result != null)
              Card(
                color: _result!.startsWith('✅') ? Colors.green.shade50 : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _result!,
                    style: TextStyle(
                      color: _result!.startsWith('✅') ? Colors.green.shade800 : Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            
            const Spacer(),
            
            const Card(
              color: Colors.amber,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('👂 Como Verificar:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('1. Certifique-se que o volume do dispositivo está ligado'),
                    Text('2. Clique em "Enviar Notificação de Teste"'),
                    Text('3. Aguarde a notificação aparecer'),
                    Text('4. Verifique se tocou o som personalizado'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}