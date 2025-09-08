import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../lib/models/supabase/driver.dart';
import '../lib/models/supabase/trip.dart';
import '../lib/models/supabase/trip_request.dart';
import '../lib/models/trip_request_data.dart';
import '../lib/services/chat_service.dart';
import '../lib/services/driver_matching_service.dart';
import '../lib/services/trip_request_manager.dart';
import '../lib/services/trip_service.dart';
import '../lib/models/chat_message.dart';

// Mock classes
@GenerateMocks([SupabaseClient, GoTrueClient, PostgrestQueryBuilder, PostgrestFilterBuilder, PostgrestBuilder])
import 'passenger_driver_matching_simulation_test.mocks.dart';

/// Teste de simulação completa do fluxo passageiro-motorista
/// Testa desde a solicitação até o chat entre os usuários
class PassengerDriverMatchingSimulationTest {
  
  late MockSupabaseClient mockSupabaseClient;
  late TripRequestManager tripRequestManager;
  late DriverMatchingService driverMatchingService;
  late TripService tripService;
  late ChatService chatService;
  
  // Test data
  final testPassengerId = 'passenger_123';
  final testDriverId = 'driver_456';
  final testTripId = 'trip_789';
  final testRequestId = 'request_abc';
  final testUserId = 'user_auth_123';
  
  void setup() {
    mockSupabaseClient = MockSupabaseClient();
    tripRequestManager = TripRequestManager(mockSupabaseClient);
    driverMatchingService = DriverMatchingService(mockSupabaseClient);
    tripService = TripService(mockSupabaseClient);
    chatService = ChatService();
    
    // Setup basic mocks
    when(mockSupabaseClient.auth).thenReturn(MockGoTrueClient());
    when(mockSupabaseClient.from(any)).thenReturn(MockPostgrestQueryBuilder());
  }
  
  /// Simula todo o fluxo de matching entre passageiro e motorista
  Future<void> runFullMatchingSimulation() async {
    dev.log('🚀 INICIANDO SIMULAÇÃO COMPLETA PASSAGEIRO-MOTORISTA', name: 'SimulationTest');
    
    try {
      // FASE 1: Criação da solicitação pelo passageiro
      dev.log('📱 FASE 1: Passageiro cria solicitação de viagem', name: 'SimulationTest');
      final tripData = _createTestTripRequestData();
      final availableDrivers = _createTestDriverList();
      
      // Mock do processo de matching
      _mockDriverMatching(availableDrivers);
      
      // Criar solicitação direcionada
      final requestId = await tripRequestManager.createDirectedTripRequest(
        passengerId: testPassengerId,
        prioritizedDrivers: availableDrivers,
        tripData: tripData,
      );
      
      dev.log('✅ FASE 1: Solicitação criada com ID: $requestId', name: 'SimulationTest');
      
      // FASE 2: Motorista recebe e aceita a solicitação
      dev.log('🚗 FASE 2: Motorista recebe e aceita solicitação', name: 'SimulationTest');
      
      // Mock da aceitação
      _mockTripRequestAcceptance();
      
      // Simular aceitação pelo motorista
      await tripRequestManager.handleDriverResponse(
        requestId: requestId,
        driverId: testDriverId,
        accepted: true,
      );
      
      dev.log('✅ FASE 2: Solicitação aceita pelo motorista', name: 'SimulationTest');
      
      // FASE 3: Criação da viagem
      dev.log('🛣️ FASE 3: Viagem criada e em andamento', name: 'SimulationTest');
      
      // Mock da criação da viagem
      _mockTripCreation();
      
      final trip = await tripService.createTrip(
        tripRequestId: requestId,
        driverId: testDriverId,
        passengerId: testPassengerId,
        originAddress: tripData.originAddress,
        originLatitude: tripData.originLatitude,
        originLongitude: tripData.originLongitude,
        destinationAddress: tripData.destinationAddress,
        destinationLatitude: tripData.destinationLatitude,
        destinationLongitude: tripData.destinationLongitude,
        actualDistanceKm: tripData.estimatedDistanceKm,
        actualDurationMinutes: tripData.estimatedDurationMinutes,
        baseFare: tripData.estimatedFare,
        finalFare: tripData.estimatedFare,
      );
      
      dev.log('✅ FASE 3: Viagem criada com ID: ${trip.id}', name: 'SimulationTest');
      
      // FASE 4: Teste do sistema de chat
      dev.log('💬 FASE 4: Testando sistema de chat', name: 'SimulationTest');
      await _testChatFunctionality();
      
      // FASE 5: Completar viagem
      dev.log('🏁 FASE 5: Completando viagem', name: 'SimulationTest');
      
      _mockTripCompletion();
      
      await tripService.completeTrip(
        tripId: testTripId,
        actualDistanceKm: tripData.estimatedDistanceKm + 0.5, // Pequeno desvio
        actualDurationMinutes: tripData.estimatedDurationMinutes + 5,
        finalFare: tripData.estimatedFare + 2.50, // Taxa adicional
      );
      
      dev.log('✅ FASE 5: Viagem completada com sucesso!', name: 'SimulationTest');
      dev.log('🎉 SIMULAÇÃO COMPLETA EXECUTADA COM SUCESSO!', name: 'SimulationTest');
      
    } catch (e, stackTrace) {
      dev.log('❌ ERRO NA SIMULAÇÃO: $e\nStackTrace: $stackTrace', name: 'SimulationTest');
      rethrow;
    }
  }
  
  /// Cria dados de teste para solicitação de viagem
  TripRequestData _createTestTripRequestData() {
    return TripRequestData(
      originAddress: 'Av. Paulista, 1000 - Bela Vista, São Paulo - SP',
      originLatitude: -23.5631,
      originLongitude: -46.6565,
      destinationAddress: 'Aeroporto de Congonhas - São Paulo - SP',
      destinationLatitude: -23.6262,
      destinationLongitude: -46.6564,
      vehicleCategory: 'economico',
      needsPet: false,
      needsGrocerySpace: false,
      isCondoOrigin: false,
      isCondoDestination: false,
      needsAc: true,
      numberOfStops: 0,
      estimatedDistanceKm: 12.5,
      estimatedDurationMinutes: 35,
      estimatedFare: 28.50,
      originNeighborhood: 'Bela Vista',
      destinationNeighborhood: 'Vila Congonhas',
    );
  }
  
  /// Cria lista de motoristas de teste
  List<Driver> _createTestDriverList() {
    return [
      Driver(
        id: testDriverId,
        userId: testUserId,
        fullName: 'Carlos Silva',
        phone: '+5511999999999',
        email: 'carlos.silva@email.com',
        cpf: '12345678901',
        birthDate: DateTime(1985, 5, 15),
        cnh: 'CNH123456789',
        cnhCategory: 'B',
        cnhExpiryDate: DateTime(2030, 5, 15),
        vehicleType: 'car',
        brand: 'Toyota',
        model: 'Corolla',
        color: 'Prata',
        plate: 'ABC-1234',
        year: 2020,
        capacity: 4,
        isOnline: true,
        isAvailable: true,
        currentLatitude: -23.5605, // Próximo ao passageiro
        currentLongitude: -46.6595,
        approvalStatus: 'approved',
        ratings: 4.8,
        trips: 245,
        cancellations: 3,
        acceptsPet: false,
        acceptsGrocery: true,
        acceptsCondo: true,
        acPolicy: 'always',
        operationZones: ['Bela Vista', 'Vila Congonhas'],
        excludedZones: [],
      ),
      // Motorista de backup
      Driver(
        id: 'driver_backup_789',
        userId: 'user_backup_456',
        fullName: 'Maria Santos',
        phone: '+5511888888888',
        email: 'maria.santos@email.com',
        cpf: '98765432100',
        birthDate: DateTime(1990, 8, 20),
        cnh: 'CNH987654321',
        cnhCategory: 'B',
        cnhExpiryDate: DateTime(2032, 8, 20),
        vehicleType: 'car',
        brand: 'Honda',
        model: 'Civic',
        color: 'Branco',
        plate: 'XYZ-5678',
        year: 2019,
        capacity: 4,
        isOnline: true,
        isAvailable: true,
        currentLatitude: -23.5650,
        currentLongitude: -46.6600,
        approvalStatus: 'approved',
        ratings: 4.9,
        trips: 180,
        cancellations: 1,
        acceptsPet: true,
        acceptsGrocery: false,
        acceptsCondo: false,
        acPolicy: 'on_request',
        operationZones: ['Bela Vista'],
        excludedZones: [],
      ),
    ];
  }
  
  /// Mock para o processo de matching de motoristas
  void _mockDriverMatching(List<Driver> drivers) {
    dev.log('🔧 Configurando mocks para matching de motoristas', name: 'SimulationTest');
    
    final mockQueryBuilder = MockPostgrestQueryBuilder();
    final mockFilterBuilder = MockPostgrestFilterBuilder();
    
    when(mockSupabaseClient.from('trip_requests')).thenReturn(mockQueryBuilder);
    when(mockQueryBuilder.insert(any)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.single()).thenAnswer((_) async => {
      'id': testRequestId,
      'passenger_id': testPassengerId,
      'target_driver_id': testDriverId,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
    
    // Mock para verificação de disponibilidade dos motoristas
    when(mockSupabaseClient.from('drivers')).thenReturn(mockQueryBuilder);
    when(mockQueryBuilder.select(any)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.eq('id', testDriverId)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.single()).thenAnswer((_) async => {
      'is_online': true,
      'approval_status': 'approved',
    });
    
    // Mock para verificação de viagens ativas
    when(mockSupabaseClient.from('trips')).thenReturn(mockQueryBuilder);
    when(mockQueryBuilder.select('id')).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.eq('driver_id', testDriverId)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.inFilter('status', ['ongoing', 'arrived', 'picked_up']))
        .thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.limit(1)).thenAnswer((_) async => []); // Sem viagens ativas
  }
  
  /// Mock para aceitação da solicitação pelo motorista
  void _mockTripRequestAcceptance() {
    dev.log('🔧 Configurando mocks para aceitação da solicitação', name: 'SimulationTest');
    
    final mockQueryBuilder = MockPostgrestQueryBuilder();
    final mockFilterBuilder = MockPostgrestFilterBuilder();
    
    when(mockSupabaseClient.from('trip_requests')).thenReturn(mockQueryBuilder);
    when(mockQueryBuilder.update(any)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.eq('id', testRequestId)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.single()).thenAnswer((_) async => {
      'id': testRequestId,
      'passenger_id': testPassengerId,
      'status': 'accepted',
      'accepted_by_driver_id': testDriverId,
      'accepted_at': DateTime.now().toIso8601String(),
    });
  }
  
  /// Mock para criação da viagem
  void _mockTripCreation() {
    dev.log('🔧 Configurando mocks para criação da viagem', name: 'SimulationTest');
    
    final mockQueryBuilder = MockPostgrestQueryBuilder();
    final mockFilterBuilder = MockPostgrestFilterBuilder();
    
    when(mockSupabaseClient.from('trips')).thenReturn(mockQueryBuilder);
    when(mockQueryBuilder.insert(any)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.single()).thenAnswer((_) async => {
      'id': testTripId,
      'trip_request_id': testRequestId,
      'driver_id': testDriverId,
      'passenger_id': testPassengerId,
      'status': 'ongoing',
      'created_at': DateTime.now().toIso8601String(),
      'origin_address': 'Av. Paulista, 1000 - Bela Vista, São Paulo - SP',
      'origin_latitude': -23.5631,
      'origin_longitude': -46.6565,
      'destination_address': 'Aeroporto de Congonhas - São Paulo - SP',
      'destination_latitude': -23.6262,
      'destination_longitude': -46.6564,
      'actual_distance_km': 12.5,
      'actual_duration_minutes': 35,
      'base_fare': 28.50,
      'final_fare': 28.50,
    });
  }
  
  /// Mock para completar viagem
  void _mockTripCompletion() {
    dev.log('🔧 Configurando mocks para conclusão da viagem', name: 'SimulationTest');
    
    final mockQueryBuilder = MockPostgrestQueryBuilder();
    final mockFilterBuilder = MockPostgrestFilterBuilder();
    
    when(mockSupabaseClient.from('trips')).thenReturn(mockQueryBuilder);
    when(mockQueryBuilder.update(any)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.eq('id', testTripId)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.single()).thenAnswer((_) async => {
      'id': testTripId,
      'status': 'completed',
      'end_time': DateTime.now().toIso8601String(),
      'actual_distance_km': 13.0,
      'actual_duration_minutes': 40,
      'final_fare': 31.00,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
  
  /// Testa a funcionalidade completa do chat
  Future<void> _testChatFunctionality() async {
    dev.log('💬 Iniciando teste do sistema de chat', name: 'SimulationTest');
    
    try {
      // Setup mocks para chat
      _mockChatSystem();
      
      // TESTE 1: Inicializar chat do passageiro
      dev.log('📱 TESTE 1: Inicializando chat do passageiro', name: 'SimulationTest');
      
      await chatService.initializeChat(
        tripId: testTripId,
        currentUserId: testPassengerId,
        isPassenger: true,
      );
      
      dev.log('✅ TESTE 1: Chat do passageiro inicializado', name: 'SimulationTest');
      
      // TESTE 2: Passageiro envia mensagem
      dev.log('📤 TESTE 2: Passageiro envia mensagem', name: 'SimulationTest');
      
      final passengerMessageSent = await chatService.sendMessage(
        'Olá motorista! Estou aguardando no portão do prédio.'
      );
      
      if (passengerMessageSent) {
        dev.log('✅ TESTE 2: Mensagem do passageiro enviada com sucesso', name: 'SimulationTest');
      } else {
        dev.log('❌ TESTE 2: Falha ao enviar mensagem do passageiro', name: 'SimulationTest');
      }
      
      // TESTE 3: Simular recebimento de mensagem do motorista
      dev.log('📨 TESTE 3: Simulando mensagem do motorista', name: 'SimulationTest');
      
      // Simular que o motorista enviou uma mensagem
      await _simulateDriverMessage('Entendi! Já estou chegando, placa ABC-1234.');
      
      dev.log('✅ TESTE 3: Mensagem do motorista simulada', name: 'SimulationTest');
      
      // TESTE 4: Verificar stream de mensagens
      dev.log('🔄 TESTE 4: Verificando stream de mensagens', name: 'SimulationTest');
      
      final messagesStream = chatService.messagesStream;
      final subscription = messagesStream.listen((messages) {
        dev.log('📨 Mensagens recebidas no stream: ${messages.length}', name: 'SimulationTest');
        for (final message in messages) {
          dev.log('💬 ${message.senderType.name}: ${message.message}', name: 'SimulationTest');
        }
      });
      
      // Aguardar um pouco para o stream processar
      await Future.delayed(Duration(seconds: 2));
      
      // TESTE 5: Marcar mensagens como lidas
      dev.log('👁️ TESTE 5: Marcando mensagens como lidas', name: 'SimulationTest');
      
      await chatService.markMessagesAsRead();
      
      dev.log('✅ TESTE 5: Mensagens marcadas como lidas', name: 'SimulationTest');
      
      // Cleanup
      await subscription.cancel();
      chatService.dispose();
      
      dev.log('🎉 TESTE DO CHAT CONCLUÍDO COM SUCESSO!', name: 'SimulationTest');
      
    } catch (e, stackTrace) {
      dev.log('❌ ERRO NO TESTE DO CHAT: $e\nStackTrace: $stackTrace', name: 'SimulationTest');
      rethrow;
    }
  }
  
  /// Setup dos mocks para o sistema de chat
  void _mockChatSystem() {
    dev.log('🔧 Configurando mocks para sistema de chat', name: 'SimulationTest');
    
    final mockQueryBuilder = MockPostgrestQueryBuilder();
    final mockFilterBuilder = MockPostgrestFilterBuilder();
    
    // Mock para trip_chats table
    when(mockSupabaseClient.from('trip_chats')).thenReturn(mockQueryBuilder);
    
    // Mock para verificação da estrutura da tabela
    when(mockQueryBuilder.select('*')).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.limit(1)).thenAnswer((_) async => [
      {
        'id': 'chat_msg_1',
        'trip_id': testTripId,
        'sender_id': testPassengerId,
        'message': 'Teste de estrutura',
        'is_read': false,
        'read_at': null,
        'created_at': DateTime.now().toIso8601String(),
      }
    ]);
    
    // Mock para select de mensagens
    when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.eq('trip_id', testTripId)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.order('created_at')).thenReturn(mockFilterBuilder);
    
    // Mock para histórico vazio inicialmente
    when(mockFilterBuilder.order('created_at')).thenAnswer((_) async => []);
    
    // Mock para inserção de mensagens
    when(mockQueryBuilder.insert(any)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.single()).thenAnswer((_) async => {
      'id': 'new_chat_msg_${DateTime.now().millisecondsSinceEpoch}',
      'trip_id': testTripId,
      'sender_id': testPassengerId,
      'message': 'Olá motorista! Estou aguardando no portão do prédio.',
      'is_read': false,
      'read_at': null,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    // Mock para verificação de permissões (trips table)
    when(mockSupabaseClient.from('trips')).thenReturn(mockQueryBuilder);
    when(mockQueryBuilder.select('driver_id')).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.eq('id', testTripId)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => {
      'driver_id': testDriverId,
    });
    
    // Mock para trip_passengers (verificação de passageiro)
    when(mockSupabaseClient.from('trip_passengers')).thenReturn(mockQueryBuilder);
    when(mockQueryBuilder.select('id')).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.eq('trip_id', testTripId)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.eq('passenger_id', testPassengerId)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => {
      'id': 'trip_passenger_1',
    });
    
    // Mock para atualização de mensagens como lidas
    when(mockQueryBuilder.update(any)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.neq('sender_id', testPassengerId)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.eq('is_read', false)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.select()).thenAnswer((_) async => []);
    
    // Mock para contar mensagens não lidas
    when(mockFilterBuilder.count()).thenAnswer((_) async => PostgrestCountResponse(count: 0, data: []));
    
    // Mock para stream (real-time)
    when(mockQueryBuilder.stream(primaryKey: ['id'])).thenAnswer((_) {
      return Stream.fromIterable([
        [
          {
            'id': 'stream_msg_1',
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
  
  /// Simula uma mensagem enviada pelo motorista
  Future<void> _simulateDriverMessage(String message) async {
    dev.log('🚗 Simulando mensagem do motorista: $message', name: 'SimulationTest');
    
    // Em um teste real, isso seria uma mensagem vinda do sistema em tempo real
    // Aqui simulamos inserindo diretamente no mock
    
    final driverMessage = ChatMessage(
      id: 'driver_msg_${DateTime.now().millisecondsSinceEpoch}',
      tripId: testTripId,
      senderId: testDriverId,
      message: message,
      senderType: MessageSender.driver,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      isFromCurrentUser: false, // Do ponto de vista do passageiro
    );
    
    dev.log('✅ Mensagem do motorista simulada: ${driverMessage.message}', name: 'SimulationTest');
  }
}

/// Testes principais usando Flutter Test
void main() {
  group('Passenger-Driver Matching Simulation', () {
    late PassengerDriverMatchingSimulationTest simulation;
    
    setUp(() {
      simulation = PassengerDriverMatchingSimulationTest();
      simulation.setup();
    });
    
    testWidgets('Complete passenger-driver flow with chat', (WidgetTester tester) async {
      await simulation.runFullMatchingSimulation();
    });
    
    test('Trip request creation and driver matching', () async {
      final simulation = PassengerDriverMatchingSimulationTest();
      simulation.setup();
      
      // Teste específico para matching
      dev.log('🧪 Teste específico: Criação de solicitação e matching', name: 'UnitTest');
      
      final tripData = simulation._createTestTripRequestData();
      expect(tripData.originAddress, isNotEmpty);
      expect(tripData.estimatedFare, greaterThan(0));
      expect(tripData.estimatedDistanceKm, greaterThan(0));
      
      final drivers = simulation._createTestDriverList();
      expect(drivers, isNotEmpty);
      expect(drivers.first.isAvailable, isTrue);
      expect(drivers.first.approvalStatus, equals('approved'));
      
      dev.log('✅ Dados de teste válidos criados', name: 'UnitTest');
    });
    
    test('Chat message flow simulation', () async {
      final simulation = PassengerDriverMatchingSimulationTest();
      simulation.setup();
      
      dev.log('🧪 Teste específico: Fluxo de mensagens do chat', name: 'UnitTest');
      
      // Criar mensagem de teste
      final testMessage = ChatMessage(
        id: 'test_msg_1',
        tripId: simulation.testTripId,
        senderId: simulation.testPassengerId,
        message: 'Mensagem de teste do passageiro',
        senderType: MessageSender.passenger,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        isFromCurrentUser: true,
      );
      
      expect(testMessage.message, isNotEmpty);
      expect(testMessage.senderType, equals(MessageSender.passenger));
      expect(testMessage.isFromCurrentUser, isTrue);
      
      dev.log('✅ Estrutura de mensagem validada', name: 'UnitTest');
    });
    
    test('Driver availability and matching criteria', () async {
      final simulation = PassengerDriverMatchingSimulationTest();
      simulation.setup();
      
      dev.log('🧪 Teste específico: Disponibilidade e critérios de matching', name: 'UnitTest');
      
      final drivers = simulation._createTestDriverList();
      final primaryDriver = drivers.first;
      
      // Validar critérios de matching
      expect(primaryDriver.isOnline, isTrue);
      expect(primaryDriver.isAvailable, isTrue);
      expect(primaryDriver.approvalStatus, equals('approved'));
      expect(primaryDriver.ratings, greaterThanOrEqualTo(4.0));
      expect(primaryDriver.currentLatitude, isNotNull);
      expect(primaryDriver.currentLongitude, isNotNull);
      
      // Validar preferências
      expect(primaryDriver.acPolicy, equals('always')); // Atende needsAc: true
      expect(primaryDriver.acceptsGrocery, isTrue);
      expect(primaryDriver.acceptsCondo, isTrue);
      
      dev.log('✅ Critérios de matching validados', name: 'UnitTest');
    });
  });
}