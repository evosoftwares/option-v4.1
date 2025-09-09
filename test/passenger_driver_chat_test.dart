import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:option/models/chat_message.dart';
import 'package:option/models/supabase/trip_chat.dart';
import 'package:option/services/chat_service.dart';

// Mock classes for Supabase
@GenerateMocks([SupabaseClient, PostgrestQueryBuilder, PostgrestFilterBuilder])
import 'passenger_driver_chat_test.mocks.dart';

/// Teste dedicado para funcionalidade de chat entre passageiro e motorista
class PassengerDriverChatTest {
  late MockSupabaseClient mockSupabaseClient;
  late MockPostgrestQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder mockFilterBuilder;
  late ChatService chatService;
  
  // Test data
  final testTripId = 'trip_test_123';
  final testPassengerId = 'passenger_test_456';
  final testDriverId = 'driver_test_789';
  final List<Map<String, dynamic>> testMessages = [];
  
  void setup() {
    dev.log('🔧 Configurando ambiente de teste do chat', name: 'ChatTest');
    
    mockSupabaseClient = MockSupabaseClient();
    mockQueryBuilder = MockPostgrestQueryBuilder();
    mockFilterBuilder = MockPostgrestFilterBuilder();
    chatService = ChatService();
    
    // Setup basic Supabase mocks
    when(mockSupabaseClient.from(any)).thenReturn(mockQueryBuilder);
    
    // Preparar mensagens de teste
    _setupTestMessages();
    
    dev.log('✅ Ambiente de teste configurado', name: 'ChatTest');
  }
  
  /// Prepara mensagens de exemplo para os testes
  void _setupTestMessages() {
    final now = DateTime.now();
    
    testMessages.addAll([
      {
        'id': 'msg_001',
        'trip_id': testTripId,
        'sender_id': testPassengerId,
        'message': 'Olá motorista! Estou esperando no portão principal.',
        'is_read': true,
        'read_at': now.subtract(const Duration(minutes: 8)).toIso8601String(),
        'created_at': now.subtract(const Duration(minutes: 10)).toIso8601String(),
      },
      {
        'id': 'msg_002',
        'trip_id': testTripId,
        'sender_id': testDriverId,
        'message': 'Oi! Estou chegando em 2 minutos. Carro prata placa ABC-1234.',
        'is_read': true,
        'read_at': now.subtract(const Duration(minutes: 6)).toIso8601String(),
        'created_at': now.subtract(const Duration(minutes: 8)).toIso8601String(),
      },
      {
        'id': 'msg_003',
        'trip_id': testTripId,
        'sender_id': testPassengerId,
        'message': 'Perfeito, já estou descendo!',
        'is_read': true,
        'read_at': now.subtract(const Duration(minutes: 4)).toIso8601String(),
        'created_at': now.subtract(const Duration(minutes: 6)).toIso8601String(),
      },
      {
        'id': 'msg_004',
        'trip_id': testTripId,
        'sender_id': testDriverId,
        'message': 'Chegamos! Muito obrigado pela viagem.',
        'is_read': false,
        'read_at': null,
        'created_at': now.subtract(const Duration(minutes: 2)).toIso8601String(),
      },
    ]);
  }
  
  /// Testa a inicialização do chat do passageiro
  Future<void> testPassengerChatInitialization() async {
    dev.log('🧪 TESTE: Inicialização do chat do passageiro', name: 'ChatTest');
    
    try {
      // Mock da estrutura da tabela
      _mockTableStructureCheck();
      
      // Mock do histórico de mensagens
      _mockChatHistory();
      
      // Mock do stream em tempo real
      _mockRealtimeStream();
      
      // Inicializar chat como passageiro
      await chatService.initializeChat(
        tripId: testTripId,
        currentUserId: testPassengerId,
        isPassenger: true,
      );
      
      expect(chatService.isActive, isTrue);
      expect(chatService.currentTripId, equals(testTripId));
      
      dev.log('✅ TESTE: Chat do passageiro inicializado com sucesso', name: 'ChatTest');
    } catch (e) {
      dev.log('❌ TESTE: Falha na inicialização do chat: $e', name: 'ChatTest');
      rethrow;
    }
  }
  
  /// Testa o envio de mensagem pelo passageiro
  Future<void> testPassengerSendMessage() async {
    dev.log('🧪 TESTE: Envio de mensagem pelo passageiro', name: 'ChatTest');
    
    try {
      // Mock da verificação de permissões
      _mockTripPermissionCheck();
      
      // Mock da estrutura da tabela para inserção
      _mockTableStructureForInsert();
      
      // Mock da inserção da mensagem
      _mockMessageInsertion();
      
      // Inicializar chat
      await chatService.initializeChat(
        tripId: testTripId,
        currentUserId: testPassengerId,
        isPassenger: true,
      );
      
      // Enviar mensagem
      final success = await chatService.sendMessage(
        'Motorista, pode alterar o destino para o shopping, por favor?'
      );
      
      expect(success, isTrue);
      
      dev.log('✅ TESTE: Mensagem enviada com sucesso', name: 'ChatTest');
    } catch (e) {
      dev.log('❌ TESTE: Falha no envio de mensagem: $e', name: 'ChatTest');
      rethrow;
    }
  }
  
  /// Testa o recebimento de mensagens do motorista
  Future<void> testReceiveDriverMessages() async {
    dev.log('🧪 TESTE: Recebimento de mensagens do motorista', name: 'ChatTest');
    
    try {
      // Mock para receber mensagens via stream
      _mockDriverMessageStream();
      
      await chatService.initializeChat(
        tripId: testTripId,
        currentUserId: testPassengerId,
        isPassenger: true,
      );
      
      // Aguardar mensagens do stream
      final messagesReceived = Completer<List<ChatMessage>>();
      late StreamSubscription subscription;
      
      subscription = chatService.messagesStream.listen((messages) {
        if (messages.isNotEmpty && !messagesReceived.isCompleted) {
          messagesReceived.complete(messages);
          subscription.cancel();
        }
      });
      
      final messages = await messagesReceived.future.timeout(const Duration(seconds: 5));
      
      expect(messages, isNotEmpty);
      
      // Verificar se há mensagens do motorista
      final driverMessages = messages.where((msg) => 
        msg.senderType == MessageSender.driver && !msg.isFromCurrentUser
      ).toList();
      
      expect(driverMessages, isNotEmpty);
      
      dev.log('✅ TESTE: ${driverMessages.length} mensagens do motorista recebidas', name: 'ChatTest');
      
    } catch (e) {
      dev.log('❌ TESTE: Falha no recebimento de mensagens: $e', name: 'ChatTest');
      rethrow;
    }
  }
  
  /// Testa a marcação de mensagens como lidas
  Future<void> testMarkMessagesAsRead() async {
    dev.log('🧪 TESTE: Marcar mensagens como lidas', name: 'ChatTest');
    
    try {
      // Mock da estrutura da tabela
      _mockTableStructureCheck();
      
      // Mock da query de mensagens não lidas
      _mockUnreadMessagesQuery();
      
      // Mock da atualização para marcar como lidas
      _mockMarkAsReadUpdate();
      
      await chatService.initializeChat(
        tripId: testTripId,
        currentUserId: testPassengerId,
        isPassenger: true,
      );
      
      // Marcar mensagens como lidas
      await chatService.markMessagesAsRead();
      
      dev.log('✅ TESTE: Mensagens marcadas como lidas com sucesso', name: 'ChatTest');
      
    } catch (e) {
      dev.log('❌ TESTE: Falha ao marcar mensagens como lidas: $e', name: 'ChatTest');
      rethrow;
    }
  }
  
  /// Testa a funcionalidade completa de conversação
  Future<void> testFullConversationFlow() async {
    dev.log('🧪 TESTE: Fluxo completo de conversação', name: 'ChatTest');
    
    try {
      // Setup todos os mocks necessários
      _mockCompleteConversation();
      
      // Lista para armazenar mensagens recebidas
      final List<ChatMessage> receivedMessages = [];
      
      // Inicializar chat
      await chatService.initializeChat(
        tripId: testTripId,
        currentUserId: testPassengerId,
        isPassenger: true,
      );
      
      // Listener para capturar mensagens
      final subscription = chatService.messagesStream.listen((messages) {
        receivedMessages.clear();
        receivedMessages.addAll(messages);
        dev.log('📨 Recebidas ${messages.length} mensagens no stream', name: 'ChatTest');
      });
      
      // Simular conversação
      await _simulateConversation();
      
      // Aguardar um pouco para o stream processar
      await Future.delayed(const Duration(seconds: 2));
      
      // Validar que mensagens foram recebidas
      expect(receivedMessages, isNotEmpty);
      
      // Validar que existem mensagens de ambos os usuários
      final passengerMessages = receivedMessages.where((m) => 
        m.senderType == MessageSender.passenger
      ).toList();
      
      final driverMessages = receivedMessages.where((m) => 
        m.senderType == MessageSender.driver
      ).toList();
      
      expect(passengerMessages, isNotEmpty);
      expect(driverMessages, isNotEmpty);
      
      dev.log('✅ TESTE: Conversação completa validada', name: 'ChatTest');
      dev.log('📊 Mensagens do passageiro: ${passengerMessages.length}', name: 'ChatTest');
      dev.log('📊 Mensagens do motorista: ${driverMessages.length}', name: 'ChatTest');
      
      await subscription.cancel();
      
    } catch (e) {
      dev.log('❌ TESTE: Falha no fluxo de conversação: $e', name: 'ChatTest');
      rethrow;
    }
  }
  
  /// Simula uma conversação completa entre passageiro e motorista
  Future<void> _simulateConversation() async {
    dev.log('🎭 Simulando conversação completa', name: 'ChatTest');
    
    final conversationSteps = [
      {
        'sender': 'passenger',
        'message': 'Oi motorista! Já estou no local de embarque.',
        'delay': 1,
      },
      {
        'sender': 'driver',
        'message': 'Perfeito! Estou chegando em 2 minutos. Carro azul placa XYZ-1234.',
        'delay': 2,
      },
      {
        'sender': 'passenger',
        'message': 'Beleza! Já te vejo aqui.',
        'delay': 1,
      },
      {
        'sender': 'driver',
        'message': 'Consegue confirmar o destino? Aeroporto de Congonhas, correto?',
        'delay': 3,
      },
      {
        'sender': 'passenger',
        'message': 'Isso mesmo! Terminal 1 se possível.',
        'delay': 2,
      },
      {
        'sender': 'driver',
        'message': 'Tranquilo! Vamos seguir pela marginal para evitar trânsito.',
        'delay': 4,
      },
    ];
    
    for (int i = 0; i < conversationSteps.length; i++) {
      final step = conversationSteps[i];
      await Future.delayed(Duration(seconds: step['delay'] as int));
      
      dev.log('💬 ${step['sender']}: ${step['message']}', name: 'ChatTest');
      
      if (step['sender'] == 'passenger') {
        await chatService.sendMessage(step['message'] as String);
      } else {
        // Simular mensagem do motorista via stream update
        _simulateDriverMessageReceived(step['message'] as String);
      }
    }
    
    dev.log('🏁 Conversação simulada concluída', name: 'ChatTest');
  }
  
  /// Simula o recebimento de uma mensagem do motorista
  void _simulateDriverMessageReceived(String message) {
    dev.log('🚗 Simulando recebimento de mensagem do motorista: $message', name: 'ChatTest');
    // Em um teste real, isso seria tratado pelo stream do Supabase
    // Aqui apenas logamos para demonstrar o fluxo
  }
  
  // === MÉTODOS DE MOCK ===
  
  void _mockTableStructureCheck() {
    when(mockQueryBuilder.select('*')).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.limit(1)).thenAnswer((_) async => [
      {
        'id': 'test_structure',
        'trip_id': testTripId,
        'sender_id': testPassengerId,
        'message': 'test',
        'is_read': false,
        'read_at': null,
        'created_at': DateTime.now().toIso8601String(),
      }
    ]);
  }
  
  void _mockChatHistory() {
    when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.eq('trip_id', testTripId)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.order('created_at')).thenAnswer((_) async => testMessages);
  }
  
  void _mockRealtimeStream() {
    when(mockQueryBuilder.stream(primaryKey: ['id'])).thenAnswer((_) {
      return Stream.fromIterable([testMessages]);
    });
    when(mockFilterBuilder.eq('trip_id', testTripId)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.order('created_at')).thenReturn(mockFilterBuilder);
  }
  
  void _mockTripPermissionCheck() {
    // Mock para verificação da viagem
    when(mockSupabaseClient.from('trips')).thenReturn(mockQueryBuilder);
    when(mockQueryBuilder.select('driver_id')).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.eq('id', testTripId)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => {
      'driver_id': testDriverId,
    });
    
    // Mock para verificação do passageiro
    when(mockSupabaseClient.from('trip_passengers')).thenReturn(mockQueryBuilder);
    when(mockQueryBuilder.select('id')).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.eq('trip_id', testTripId)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.eq('passenger_id', testPassengerId)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => {
      'id': 'trip_passenger_relation',
    });
  }
  
  void _mockTableStructureForInsert() {
    when(mockQueryBuilder.select('id, trip_id, sender_id, message, created_at, is_read, read_at'))
        .thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.limit(1)).thenAnswer((_) async => [
      {
        'id': 'structure_test',
        'trip_id': testTripId,
        'sender_id': testPassengerId,
        'message': 'test',
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
        'read_at': null,
      }
    ]);
  }
  
  void _mockMessageInsertion() {
    when(mockQueryBuilder.insert(any)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.single()).thenAnswer((_) async => {
      'id': 'new_msg_${DateTime.now().millisecondsSinceEpoch}',
      'trip_id': testTripId,
      'sender_id': testPassengerId,
      'message': 'Motorista, pode alterar o destino para o shopping, por favor?',
      'is_read': false,
      'read_at': null,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
  
  void _mockDriverMessageStream() {
    // Stream que simula mensagens chegando em tempo real
    when(mockQueryBuilder.stream(primaryKey: ['id'])).thenAnswer((_) {
      return Stream.fromIterable([
        testMessages, // Mensagens iniciais
        [
          ...testMessages,
          {
            'id': 'new_driver_msg',
            'trip_id': testTripId,
            'sender_id': testDriverId,
            'message': 'Mensagem em tempo real do motorista',
            'is_read': false,
            'read_at': null,
            'created_at': DateTime.now().toIso8601String(),
          }
        ]
      ]);
    });
  }
  
  void _mockUnreadMessagesQuery() {
    when(mockQueryBuilder.select('id, is_read, read_at')).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.neq('sender_id', testPassengerId)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.eq('is_read', false)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.count()).thenAnswer((_) async => 
      PostgrestCountResponse(count: 1, data: []));
  }
  
  void _mockMarkAsReadUpdate() {
    // Mock para verificar campo read_at
    when(mockQueryBuilder.select('read_at')).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.limit(1)).thenAnswer((_) async => [
      {'read_at': null}
    ]);
    
    // Mock para update
    when(mockQueryBuilder.update(any)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.neq('sender_id', testPassengerId)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.eq('is_read', false)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.select()).thenAnswer((_) async => [
      {
        'id': 'updated_msg',
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }
    ]);
  }
  
  void _mockCompleteConversation() {
    // Combinar todos os mocks necessários para conversação completa
    _mockTableStructureCheck();
    _mockChatHistory();
    _mockTripPermissionCheck();
    _mockTableStructureForInsert();
    _mockMessageInsertion();
    _mockDriverMessageStream();
    _mockUnreadMessagesQuery();
    _mockMarkAsReadUpdate();
  }
}

/// Testes principais
void main() {
  group('Passenger-Driver Chat Tests', () {
    late PassengerDriverChatTest chatTest;
    
    setUp(() {
      chatTest = PassengerDriverChatTest();
      chatTest.setup();
    });
    
    tearDown(() {
      chatTest.chatService.dispose();
    });
    
    test('Initialize passenger chat successfully', () async {
      await chatTest.testPassengerChatInitialization();
    });
    
    test('Passenger can send messages', () async {
      await chatTest.testPassengerSendMessage();
    });
    
    test('Receive messages from driver', () async {
      await chatTest.testReceiveDriverMessages();
    });
    
    test('Mark messages as read', () async {
      await chatTest.testMarkMessagesAsRead();
    });
    
    test('Complete conversation flow', () async {
      await chatTest.testFullConversationFlow();
    });
    
    test('Chat message validation', () {
      // Teste de validação da estrutura de mensagens
      final testMessage = ChatMessage(
        id: 'validation_test',
        tripId: 'trip_validation',
        senderId: 'sender_validation',
        message: 'Teste de validação de mensagem',
        senderType: MessageSender.passenger,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        isFromCurrentUser: true,
      );
      
      expect(testMessage.message, isNotEmpty);
      expect(testMessage.senderType, equals(MessageSender.passenger));
      expect(testMessage.status, equals(MessageStatus.sent));
      expect(testMessage.isFromCurrentUser, isTrue);
      
      dev.log('✅ Estrutura de mensagem validada nos testes', name: 'ChatTest');
    });
    
    test('TripChat model conversion', () {
      // Teste de conversão do modelo TripChat
      final tripChatData = {
        'id': 'tripchar_test',
        'trip_id': 'trip_conversion_test',
        'sender_id': 'sender_conversion_test',
        'message': 'Mensagem de teste para conversão',
        'is_read': false,
        'read_at': null,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      final tripChat = TripChat.fromJson(tripChatData);
      
      expect(tripChat.id, equals('tripchar_test'));
      expect(tripChat.tripId, equals('trip_conversion_test'));
      expect(tripChat.message, equals('Mensagem de teste para conversão'));
      expect(tripChat.isRead, isFalse);
      expect(tripChat.readAt, isNull);
      
      dev.log('✅ Conversão TripChat validada nos testes', name: 'ChatTest');
    });
  });
}