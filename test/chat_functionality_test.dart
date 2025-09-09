import 'dart:developer' as dev;

import 'package:flutter_test/flutter_test.dart';

import 'package:option/models/chat_message.dart';
import 'package:option/models/supabase/trip_chat.dart';

/// Teste específico para funcionalidade de chat entre passageiro e motorista
class ChatFunctionalityTest {
  
  final testTripId = 'trip_chat_test_123';
  final testPassengerId = 'passenger_chat_456';
  final testDriverId = 'driver_chat_789';
  
  /// Testa a funcionalidade completa do chat
  void runChatFunctionalityTests() {
    dev.log('💬 INICIANDO TESTES DE FUNCIONALIDADE DO CHAT', name: 'ChatTest');
    
    try {
      // TESTE 1: Estrutura de mensagens
      dev.log('🧪 TESTE 1: Validação da estrutura de mensagens', name: 'ChatTest');
      _testMessageStructure();
      dev.log('✅ TESTE 1: Estrutura de mensagens validada', name: 'ChatTest');
      
      // TESTE 2: Conversação entre passageiro e motorista
      dev.log('🧪 TESTE 2: Simulação de conversação', name: 'ChatTest');
      _testConversationFlow();
      dev.log('✅ TESTE 2: Conversação simulada com sucesso', name: 'ChatTest');
      
      // TESTE 3: Estados das mensagens
      dev.log('🧪 TESTE 3: Validação de estados das mensagens', name: 'ChatTest');
      _testMessageStates();
      dev.log('✅ TESTE 3: Estados das mensagens validados', name: 'ChatTest');
      
      // TESTE 4: Timestamp e ordenação
      dev.log('🧪 TESTE 4: Validação de timestamp e ordenação', name: 'ChatTest');
      _testTimestampAndSorting();
      dev.log('✅ TESTE 4: Timestamp e ordenação validados', name: 'ChatTest');
      
      // TESTE 5: Tipos de remetente
      dev.log('🧪 TESTE 5: Validação de tipos de remetente', name: 'ChatTest');
      _testSenderTypes();
      dev.log('✅ TESTE 5: Tipos de remetente validados', name: 'ChatTest');
      
      // TESTE 6: Modelo TripChat
      dev.log('🧪 TESTE 6: Validação do modelo TripChat', name: 'ChatTest');
      _testTripChatModel();
      dev.log('✅ TESTE 6: Modelo TripChat validado', name: 'ChatTest');
      
      dev.log('🎉 TODOS OS TESTES DE CHAT EXECUTADOS COM SUCESSO!', name: 'ChatTest');
      
    } catch (e, stackTrace) {
      dev.log('❌ ERRO NOS TESTES DE CHAT: $e\nStackTrace: $stackTrace', name: 'ChatTest');
      rethrow;
    }
  }
  
  /// Testa a estrutura básica das mensagens
  void _testMessageStructure() {
    // Criar mensagem do passageiro
    final passengerMessage = ChatMessage(
      id: 'msg_passenger_001',
      tripId: testTripId,
      senderId: testPassengerId,
      message: 'Olá motorista! Estou no local de embarque.',
      senderType: MessageSender.passenger,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      isFromCurrentUser: true,
    );
    
    // Validar campos obrigatórios
    _validateRequiredFields(passengerMessage);
    
    // Criar mensagem do motorista
    final driverMessage = ChatMessage(
      id: 'msg_driver_001',
      tripId: testTripId,
      senderId: testDriverId,
      message: 'Oi! Estou chegando em 2 minutos.',
      senderType: MessageSender.driver,
      timestamp: DateTime.now().add(const Duration(minutes: 1)),
      status: MessageStatus.delivered,
      isFromCurrentUser: false,
    );
    
    _validateRequiredFields(driverMessage);
    
    dev.log('📨 Mensagem do passageiro criada: ${passengerMessage.message}', name: 'ChatTest');
    dev.log('📨 Mensagem do motorista criada: ${driverMessage.message}', name: 'ChatTest');
  }
  
  /// Valida campos obrigatórios de uma mensagem
  void _validateRequiredFields(ChatMessage message) {
    if (message.id.isEmpty) {
      throw Exception('ID da mensagem não pode estar vazio');
    }
    
    if (message.tripId.isEmpty) {
      throw Exception('Trip ID não pode estar vazio');
    }
    
    if (message.senderId.isEmpty) {
      throw Exception('Sender ID não pode estar vazio');
    }
    
    if (message.message.trim().isEmpty) {
      throw Exception('Conteúdo da mensagem não pode estar vazio');
    }
    
    // Validar que o trip ID está correto
    if (message.tripId != testTripId) {
      throw Exception('Trip ID incorreto: ${message.tripId}');
    }
  }
  
  /// Simula uma conversação completa entre passageiro e motorista
  void _testConversationFlow() {
    final conversation = <ChatMessage>[];
    final now = DateTime.now();
    
    // Mensagem 1: Passageiro inicia conversa
    conversation.add(ChatMessage(
      id: 'conv_001',
      tripId: testTripId,
      senderId: testPassengerId,
      message: 'Olá! Estou esperando no portão principal do prédio.',
      senderType: MessageSender.passenger,
      timestamp: now,
      status: MessageStatus.sent,
      isFromCurrentUser: true,
    ));
    
    // Mensagem 2: Motorista responde
    conversation.add(ChatMessage(
      id: 'conv_002',
      tripId: testTripId,
      senderId: testDriverId,
      message: 'Oi! Estou chegando em 3 minutos. Carro prata placa ABC-1234.',
      senderType: MessageSender.driver,
      timestamp: now.add(const Duration(minutes: 1)),
      status: MessageStatus.delivered,
      isFromCurrentUser: false,
    ));
    
    // Mensagem 3: Passageiro confirma
    conversation.add(ChatMessage(
      id: 'conv_003',
      tripId: testTripId,
      senderId: testPassengerId,
      message: 'Perfeito! Já estou descendo.',
      senderType: MessageSender.passenger,
      timestamp: now.add(const Duration(minutes: 2)),
      status: MessageStatus.read,
      isFromCurrentUser: true,
    ));
    
    // Mensagem 4: Motorista atualiza
    conversation.add(ChatMessage(
      id: 'conv_004',
      tripId: testTripId,
      senderId: testDriverId,
      message: 'Chegando agora! Estou na esquina.',
      senderType: MessageSender.driver,
      timestamp: now.add(const Duration(minutes: 4)),
      status: MessageStatus.sent,
      isFromCurrentUser: false,
    ));
    
    // Mensagem 5: Durante a viagem
    conversation.add(ChatMessage(
      id: 'conv_005',
      tripId: testTripId,
      senderId: testPassengerId,
      message: 'Motorista, pode alterar o destino para o shopping?',
      senderType: MessageSender.passenger,
      timestamp: now.add(const Duration(minutes: 10)),
      status: MessageStatus.delivered,
      isFromCurrentUser: true,
    ));
    
    // Mensagem 6: Motorista confirma
    conversation.add(ChatMessage(
      id: 'conv_006',
      tripId: testTripId,
      senderId: testDriverId,
      message: 'Claro! Shopping Iguatemi, correto?',
      senderType: MessageSender.driver,
      timestamp: now.add(const Duration(minutes: 11)),
      status: MessageStatus.read,
      isFromCurrentUser: false,
    ));
    
    // Mensagem 7: Confirmação final
    conversation.add(ChatMessage(
      id: 'conv_007',
      tripId: testTripId,
      senderId: testPassengerId,
      message: 'Isso mesmo! Obrigado!',
      senderType: MessageSender.passenger,
      timestamp: now.add(const Duration(minutes: 12)),
      status: MessageStatus.sent,
      isFromCurrentUser: true,
    ));
    
    // Validar que todas as mensagens foram criadas
    if (conversation.length != 7) {
      throw Exception('Esperado 7 mensagens, encontradas ${conversation.length}');
    }
    
    // Validar alternância entre passageiro e motorista (não obrigatória, mas comum)
    var passengerMessages = 0;
    var driverMessages = 0;
    
    for (final message in conversation) {
      if (message.senderType == MessageSender.passenger) {
        passengerMessages++;
      } else if (message.senderType == MessageSender.driver) {
        driverMessages++;
      }
    }
    
    if (passengerMessages == 0) {
      throw Exception('Deve haver pelo menos uma mensagem do passageiro');
    }
    
    if (driverMessages == 0) {
      throw Exception('Deve haver pelo menos uma mensagem do motorista');
    }
    
    dev.log('💬 Conversação simulada:', name: 'ChatTest');
    dev.log('   👤 Mensagens do passageiro: $passengerMessages', name: 'ChatTest');
    dev.log('   🚗 Mensagens do motorista: $driverMessages', name: 'ChatTest');
    dev.log('   📊 Total de mensagens: ${conversation.length}', name: 'ChatTest');
  }
  
  /// Testa todos os estados possíveis das mensagens
  void _testMessageStates() {
    final allStates = [
      MessageStatus.sending,
      MessageStatus.sent,
      MessageStatus.delivered,
      MessageStatus.read,
      MessageStatus.failed,
    ];
    
    var messageId = 1;
    
    for (final status in allStates) {
      final message = ChatMessage(
        id: 'state_test_${messageId++}',
        tripId: testTripId,
        senderId: testPassengerId,
        message: 'Teste do status: ${status.name}',
        senderType: MessageSender.passenger,
        timestamp: DateTime.now(),
        status: status,
        isFromCurrentUser: true,
      );
      
      // Validar que o status foi definido corretamente
      if (message.status != status) {
        throw Exception('Status da mensagem incorreto: ${message.status} != $status');
      }
      
      dev.log('📋 Status testado: ${status.name}', name: 'ChatTest');
    }
    
    dev.log('✅ Todos os ${allStates.length} estados de mensagem testados', name: 'ChatTest');
  }
  
  /// Testa ordenação por timestamp
  void _testTimestampAndSorting() {
    final baseTime = DateTime.now();
    final messages = <ChatMessage>[];
    
    // Criar mensagens fora de ordem cronológica
    messages.add(_createTestMessage('msg_3', baseTime.add(const Duration(minutes: 10))));
    messages.add(_createTestMessage('msg_1', baseTime));
    messages.add(_createTestMessage('msg_4', baseTime.add(const Duration(minutes: 15))));
    messages.add(_createTestMessage('msg_2', baseTime.add(const Duration(minutes: 5))));
    
    // Validar que estão fora de ordem
    if (messages[0].timestamp.isBefore(messages[1].timestamp)) {
      throw Exception('Mensagens já estão em ordem, teste inválido');
    }
    
    // Ordenar por timestamp
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // Validar que agora estão em ordem
    for (int i = 1; i < messages.length; i++) {
      if (messages[i].timestamp.isBefore(messages[i - 1].timestamp)) {
        throw Exception('Ordenação por timestamp falhou no índice $i');
      }
    }
    
    // Validar ordem específica dos IDs
    final expectedOrder = ['msg_1', 'msg_2', 'msg_3', 'msg_4'];
    for (int i = 0; i < expectedOrder.length; i++) {
      if (messages[i].id != expectedOrder[i]) {
        throw Exception('Ordem incorreta: esperado ${expectedOrder[i]}, encontrado ${messages[i].id}');
      }
    }
    
    dev.log('⏰ Ordenação por timestamp validada:', name: 'ChatTest');
    dev.log('   📊 ${messages.length} mensagens ordenadas corretamente', name: 'ChatTest');
    dev.log('   🔀 Ordem: ${messages.map((m) => m.id).join(' → ')}', name: 'ChatTest');
  }
  
  /// Cria mensagem de teste com timestamp específico
  ChatMessage _createTestMessage(String id, DateTime timestamp) {
    return ChatMessage(
      id: id,
      tripId: testTripId,
      senderId: testPassengerId,
      message: 'Mensagem de teste: $id',
      senderType: MessageSender.passenger,
      timestamp: timestamp,
      status: MessageStatus.sent,
      isFromCurrentUser: true,
    );
  }
  
  /// Testa diferenciação entre tipos de remetente
  void _testSenderTypes() {
    final senderTypes = [MessageSender.passenger, MessageSender.driver];
    
    for (final senderType in senderTypes) {
      final senderId = senderType == MessageSender.passenger ? testPassengerId : testDriverId;
      final isCurrentUser = senderType == MessageSender.passenger; // Assumindo perspectiva do passageiro
      
      final message = ChatMessage(
        id: 'sender_test_${senderType.name}',
        tripId: testTripId,
        senderId: senderId,
        message: 'Teste do tipo de remetente: ${senderType.name}',
        senderType: senderType,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        isFromCurrentUser: isCurrentUser,
      );
      
      // Validar que o tipo de remetente está correto
      if (message.senderType != senderType) {
        throw Exception('Tipo de remetente incorreto: ${message.senderType} != $senderType');
      }
      
      // Validar coerência entre sender ID e tipo
      if (senderType == MessageSender.passenger && message.senderId != testPassengerId) {
        throw Exception('Sender ID incoerente para passageiro: ${message.senderId}');
      }
      
      if (senderType == MessageSender.driver && message.senderId != testDriverId) {
        throw Exception('Sender ID incoerente para motorista: ${message.senderId}');
      }
      
      dev.log('👥 Tipo de remetente testado: ${senderType.name}', name: 'ChatTest');
      dev.log('   📍 Sender ID: ${message.senderId}', name: 'ChatTest');
      dev.log('   🎭 É usuário atual: ${message.isFromCurrentUser}', name: 'ChatTest');
    }
  }
  
  /// Testa o modelo TripChat
  void _testTripChatModel() {
    final now = DateTime.now();
    
    // Testar criação via fromJson
    final jsonData = {
      'id': 'trip_chat_001',
      'trip_id': testTripId,
      'sender_id': testPassengerId,
      'message': 'Mensagem de teste do modelo TripChat',
      'is_read': false,
      'read_at': null,
      'created_at': now.toIso8601String(),
    };
    
    final tripChat = TripChat.fromJson(jsonData);
    
    // Validar campos
    if (tripChat.id != 'trip_chat_001') {
      throw Exception('ID do TripChat incorreto: ${tripChat.id}');
    }
    
    if (tripChat.tripId != testTripId) {
      throw Exception('Trip ID do TripChat incorreto: ${tripChat.tripId}');
    }
    
    if (tripChat.senderId != testPassengerId) {
      throw Exception('Sender ID do TripChat incorreto: ${tripChat.senderId}');
    }
    
    if (tripChat.message != 'Mensagem de teste do modelo TripChat') {
      throw Exception('Mensagem do TripChat incorreta: ${tripChat.message}');
    }
    
    if (tripChat.isRead) {
      throw Exception('TripChat deveria estar como não lido');
    }
    
    if (tripChat.readAt != null) {
      throw Exception('ReadAt deveria ser null');
    }
    
    // Testar conversão para JSON
    final jsonOutput = tripChat.toJson();
    
    if (jsonOutput['id'] != tripChat.id) {
      throw Exception('Conversão toJson falhou para ID');
    }
    
    if (jsonOutput['trip_id'] != tripChat.tripId) {
      throw Exception('Conversão toJson falhou para trip_id');
    }
    
    // Testar conversão para inserção (sem ID)
    final insertJson = tripChat.toInsertJson();
    
    if (insertJson.containsKey('id')) {
      throw Exception('InsertJson não deveria conter ID');
    }
    
    if (insertJson['trip_id'] != tripChat.tripId) {
      throw Exception('InsertJson trip_id incorreto');
    }
    
    // Testar copyWith
    final updatedTripChat = tripChat.copyWith(
      isRead: true,
      readAt: now.add(const Duration(minutes: 5)),
    );
    
    if (!updatedTripChat.isRead) {
      throw Exception('CopyWith falhou para isRead');
    }
    
    if (updatedTripChat.readAt == null) {
      throw Exception('CopyWith falhou para readAt');
    }
    
    // Validar que outros campos não mudaram
    if (updatedTripChat.id != tripChat.id) {
      throw Exception('CopyWith alterou ID incorretamente');
    }
    
    if (updatedTripChat.message != tripChat.message) {
      throw Exception('CopyWith alterou message incorretamente');
    }
    
    dev.log('📦 Modelo TripChat validado:', name: 'ChatTest');
    dev.log('   ✅ Criação via fromJson', name: 'ChatTest');
    dev.log('   ✅ Conversão toJson', name: 'ChatTest');
    dev.log('   ✅ Conversão toInsertJson', name: 'ChatTest');
    dev.log('   ✅ Método copyWith', name: 'ChatTest');
  }
}

/// Testes principais usando Flutter Test
void main() {
  group('Chat Functionality Tests', () {
    late ChatFunctionalityTest chatTest;
    
    setUp(() {
      chatTest = ChatFunctionalityTest();
    });
    
    test('Complete chat functionality validation', () {
      chatTest.runChatFunctionalityTests();
    });
    
    test('ChatMessage model validation', () {
      final message = ChatMessage(
        id: 'test_model_validation',
        tripId: 'trip_model_test',
        senderId: 'sender_model_test',
        message: 'Validação do modelo ChatMessage',
        senderType: MessageSender.passenger,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        isFromCurrentUser: true,
      );
      
      expect(message.id, equals('test_model_validation'));
      expect(message.tripId, equals('trip_model_test'));
      expect(message.senderId, equals('sender_model_test'));
      expect(message.message, equals('Validação do modelo ChatMessage'));
      expect(message.senderType, equals(MessageSender.passenger));
      expect(message.status, equals(MessageStatus.sent));
      expect(message.isFromCurrentUser, isTrue);
      
      dev.log('✅ Modelo ChatMessage validado nos testes unitários', name: 'ChatTest');
    });
    
    test('TripChat model fromJson validation', () {
      final now = DateTime.now();
      final jsonData = {
        'id': 'test_trip_chat',
        'trip_id': 'trip_test',
        'sender_id': 'sender_test',
        'message': 'Mensagem de teste',
        'is_read': true,
        'read_at': now.toIso8601String(),
        'created_at': now.toIso8601String(),
      };
      
      final tripChat = TripChat.fromJson(jsonData);
      
      expect(tripChat.id, equals('test_trip_chat'));
      expect(tripChat.tripId, equals('trip_test'));
      expect(tripChat.senderId, equals('sender_test'));
      expect(tripChat.message, equals('Mensagem de teste'));
      expect(tripChat.isRead, isTrue);
      expect(tripChat.readAt, isNotNull);
      expect(tripChat.createdAt, isNotNull);
      
      dev.log('✅ Modelo TripChat fromJson validado nos testes unitários', name: 'ChatTest');
    });
    
    test('Message status transitions', () {
      final message = ChatMessage(
        id: 'status_transition_test',
        tripId: 'trip_status_test',
        senderId: 'sender_status_test',
        message: 'Teste de transição de status',
        senderType: MessageSender.passenger,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
        isFromCurrentUser: true,
      );
      
      // Simular transições de status
      var updatedMessage = message.copyWith(status: MessageStatus.sent);
      expect(updatedMessage.status, equals(MessageStatus.sent));
      
      updatedMessage = updatedMessage.copyWith(status: MessageStatus.delivered);
      expect(updatedMessage.status, equals(MessageStatus.delivered));
      
      updatedMessage = updatedMessage.copyWith(status: MessageStatus.read);
      expect(updatedMessage.status, equals(MessageStatus.read));
      
      dev.log('✅ Transições de status validadas nos testes unitários', name: 'ChatTest');
    });
    
    test('Message sorting by timestamp', () {
      final baseTime = DateTime.now();
      final messages = [
        ChatMessage(
          id: 'sort_3',
          tripId: 'trip_sort_test',
          senderId: 'sender_sort',
          message: 'Terceira mensagem',
          senderType: MessageSender.passenger,
          timestamp: baseTime.add(const Duration(minutes: 10)),
          status: MessageStatus.sent,
          isFromCurrentUser: true,
        ),
        ChatMessage(
          id: 'sort_1',
          tripId: 'trip_sort_test',
          senderId: 'sender_sort',
          message: 'Primeira mensagem',
          senderType: MessageSender.passenger,
          timestamp: baseTime,
          status: MessageStatus.sent,
          isFromCurrentUser: true,
        ),
        ChatMessage(
          id: 'sort_2',
          tripId: 'trip_sort_test',
          senderId: 'sender_sort',
          message: 'Segunda mensagem',
          senderType: MessageSender.passenger,
          timestamp: baseTime.add(const Duration(minutes: 5)),
          status: MessageStatus.sent,
          isFromCurrentUser: true,
        ),
      ];
      
      // Ordenar por timestamp
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      expect(messages[0].id, equals('sort_1'));
      expect(messages[1].id, equals('sort_2'));
      expect(messages[2].id, equals('sort_3'));
      
      dev.log('✅ Ordenação por timestamp validada nos testes unitários', name: 'ChatTest');
    });
  });
}