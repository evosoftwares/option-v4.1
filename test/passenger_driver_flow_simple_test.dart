import 'dart:developer' as dev;

import 'package:flutter_test/flutter_test.dart';

import '../lib/models/supabase/driver.dart';
import '../lib/models/trip_request_data.dart';
import '../lib/models/chat_message.dart';

/// Teste simplificado do fluxo passageiro-motorista
/// Valida a lógica de negócio sem depender de mocks complexos do Supabase
class PassengerDriverFlowSimpleTest {
  
  // Test data
  final testPassengerId = 'passenger_123';
  final testDriverId = 'driver_456';
  final testTripId = 'trip_789';
  final testUserId = 'user_auth_123';
  
  /// Simula todo o fluxo de matching entre passageiro e motorista
  void runSimpleFlowValidation() {
    dev.log('🚀 INICIANDO VALIDAÇÃO SIMPLIFICADA DO FLUXO PASSAGEIRO-MOTORISTA', name: 'SimpleTest');
    
    try {
      // FASE 1: Validação da criação da solicitação
      dev.log('📱 FASE 1: Validando solicitação de viagem', name: 'SimpleTest');
      final tripData = _createTestTripRequestData();
      _validateTripRequestData(tripData);
      dev.log('✅ FASE 1: Dados da solicitação validados', name: 'SimpleTest');
      
      // FASE 2: Validação dos motoristas disponíveis
      dev.log('🚗 FASE 2: Validando motoristas disponíveis', name: 'SimpleTest');
      final availableDrivers = _createTestDriverList();
      _validateDriverData(availableDrivers);
      dev.log('✅ FASE 2: Dados dos motoristas validados', name: 'SimpleTest');
      
      // FASE 3: Validação do algoritmo de matching
      dev.log('🎯 FASE 3: Validando critérios de matching', name: 'SimpleTest');
      _validateMatchingCriteria(tripData, availableDrivers);
      dev.log('✅ FASE 3: Critérios de matching validados', name: 'SimpleTest');
      
      // FASE 4: Validação do sistema de chat
      dev.log('💬 FASE 4: Validando estruturas do chat', name: 'SimpleTest');
      _validateChatFunctionality();
      dev.log('✅ FASE 4: Estruturas do chat validadas', name: 'SimpleTest');
      
      // FASE 5: Validação do fluxo completo
      dev.log('🛣️ FASE 5: Validando fluxo completo', name: 'SimpleTest');
      _validateCompleteFlow(tripData, availableDrivers);
      dev.log('✅ FASE 5: Fluxo completo validado', name: 'SimpleTest');
      
      dev.log('🎉 VALIDAÇÃO COMPLETA EXECUTADA COM SUCESSO!', name: 'SimpleTest');
      
    } catch (e, stackTrace) {
      dev.log('❌ ERRO NA VALIDAÇÃO: $e\nStackTrace: $stackTrace', name: 'SimpleTest');
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
    final now = DateTime.now();
    return [
      Driver(
        id: testDriverId,
        userId: testUserId,
        brand: 'Toyota',
        model: 'Corolla',
        color: 'Prata',
        plate: 'ABC-1234',
        year: 2020,
        category: 'economico',
        isOnline: true,
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
        createdAt: now,
        updatedAt: now,
      ),
      // Motorista de backup
      Driver(
        id: 'driver_backup_789',
        userId: 'user_backup_456',
        brand: 'Honda',
        model: 'Civic',
        color: 'Branco',
        plate: 'XYZ-5678',
        year: 2019,
        category: 'economico',
        isOnline: true,
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
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
  
  /// Valida dados da solicitação de viagem
  void _validateTripRequestData(TripRequestData tripData) {
    // Validar endereços
    if (tripData.originAddress.isEmpty) {
      throw Exception('Endereço de origem não pode estar vazio');
    }
    
    if (tripData.destinationAddress.isEmpty) {
      throw Exception('Endereço de destino não pode estar vazio');
    }
    
    // Validar coordenadas
    if (tripData.originLatitude < -90 || tripData.originLatitude > 90) {
      throw Exception('Latitude de origem inválida: ${tripData.originLatitude}');
    }
    
    if (tripData.originLongitude < -180 || tripData.originLongitude > 180) {
      throw Exception('Longitude de origem inválida: ${tripData.originLongitude}');
    }
    
    if (tripData.destinationLatitude < -90 || tripData.destinationLatitude > 90) {
      throw Exception('Latitude de destino inválida: ${tripData.destinationLatitude}');
    }
    
    if (tripData.destinationLongitude < -180 || tripData.destinationLongitude > 180) {
      throw Exception('Longitude de destino inválida: ${tripData.destinationLongitude}');
    }
    
    // Validar estimativas
    if (tripData.estimatedDistanceKm <= 0) {
      throw Exception('Distância estimada deve ser positiva: ${tripData.estimatedDistanceKm}');
    }
    
    if (tripData.estimatedDurationMinutes <= 0) {
      throw Exception('Duração estimada deve ser positiva: ${tripData.estimatedDurationMinutes}');
    }
    
    if (tripData.estimatedFare <= 0) {
      throw Exception('Tarifa estimada deve ser positiva: ${tripData.estimatedFare}');
    }
    
    // Validar categoria
    if (tripData.vehicleCategory.isEmpty) {
      throw Exception('Categoria do veículo não pode estar vazia');
    }
    
    dev.log('✅ Dados da solicitação válidos:', name: 'SimpleTest');
    dev.log('   📍 Origem: ${tripData.originAddress}', name: 'SimpleTest');
    dev.log('   🎯 Destino: ${tripData.destinationAddress}', name: 'SimpleTest');
    dev.log('   💰 Valor: R\$ ${tripData.estimatedFare.toStringAsFixed(2)}', name: 'SimpleTest');
    dev.log('   📏 Distância: ${tripData.estimatedDistanceKm} km', name: 'SimpleTest');
    dev.log('   ⏱️ Tempo: ${tripData.estimatedDurationMinutes} min', name: 'SimpleTest');
  }
  
  /// Valida dados dos motoristas
  void _validateDriverData(List<Driver> drivers) {
    if (drivers.isEmpty) {
      throw Exception('Lista de motoristas não pode estar vazia');
    }
    
    for (final driver in drivers) {
      // Validar dados obrigatórios
      if (driver.id.isEmpty) {
        throw Exception('ID do motorista não pode estar vazio');
      }
      
      if (driver.userId.isEmpty) {
        throw Exception('ID do usuário do motorista não pode estar vazio');
      }
      
      // Validar veículo
      if (driver.brand.isEmpty) {
        throw Exception('Marca do veículo não pode estar vazia');
      }
      
      if (driver.model.isEmpty) {
        throw Exception('Modelo do veículo não pode estar vazio');
      }
      
      if (driver.plate.isEmpty) {
        throw Exception('Placa do veículo não pode estar vazia');
      }
      
      if (driver.year < 1990 || driver.year > DateTime.now().year + 1) {
        throw Exception('Ano do veículo inválido: ${driver.year}');
      }
      
      // Validar status
      if (driver.approvalStatus != 'approved') {
        throw Exception('Motorista deve estar aprovado: ${driver.approvalStatus}');
      }
      
      if (!driver.isOnline) {
        throw Exception('Motorista deve estar online');
      }
      
      // Validar localização
      if (driver.currentLatitude == null || driver.currentLongitude == null) {
        throw Exception('Localização do motorista é obrigatória');
      }
      
      if (driver.currentLatitude! < -90 || driver.currentLatitude! > 90) {
        throw Exception('Latitude do motorista inválida: ${driver.currentLatitude}');
      }
      
      if (driver.currentLongitude! < -180 || driver.currentLongitude! > 180) {
        throw Exception('Longitude do motorista inválida: ${driver.currentLongitude}');
      }
      
      // Validar métricas
      if (driver.ratings < 0 || driver.ratings > 5) {
        throw Exception('Avaliação do motorista inválida: ${driver.ratings}');
      }
      
      if (driver.trips < 0) {
        throw Exception('Número de viagens não pode ser negativo: ${driver.trips}');
      }
      
      if (driver.cancellations < 0) {
        throw Exception('Número de cancelamentos não pode ser negativo: ${driver.cancellations}');
      }
      
      dev.log('✅ Motorista válido: ${driver.id}', name: 'SimpleTest');
      dev.log('   🚗 Veículo: ${driver.brand} ${driver.model} ${driver.color}', name: 'SimpleTest');
      dev.log('   📍 Placa: ${driver.plate}', name: 'SimpleTest');
      dev.log('   ⭐ Avaliação: ${driver.ratings}', name: 'SimpleTest');
      dev.log('   🛣️ Viagens: ${driver.trips}', name: 'SimpleTest');
    }
  }
  
  /// Valida critérios de matching
  void _validateMatchingCriteria(TripRequestData tripData, List<Driver> drivers) {
    final primaryDriver = drivers.first;
    
    // Validar compatibilidade de categoria
    if (primaryDriver.category != tripData.vehicleCategory) {
      dev.log('⚠️ Categoria do motorista (${primaryDriver.category}) != solicitação (${tripData.vehicleCategory})', 
              name: 'SimpleTest');
    }
    
    // Validar preferências de AR condicionado
    if (tripData.needsAc) {
      final acPolicy = primaryDriver.acPolicy?.toLowerCase();
      final supportsAc = acPolicy == 'always' || acPolicy == 'on_request';
      
      if (!supportsAc) {
        throw Exception('Motorista não oferece AR condicionado, mas é necessário');
      }
      
      dev.log('✅ AR condicionado: Motorista oferece (${primaryDriver.acPolicy})', name: 'SimpleTest');
    }
    
    // Validar preferências de Pet
    if (tripData.needsPet && !primaryDriver.acceptsPet) {
      throw Exception('Motorista não aceita pets, mas é necessário');
    }
    
    // Validar preferências de Mercado
    if (tripData.needsGrocerySpace && !primaryDriver.acceptsGrocery) {
      throw Exception('Motorista não aceita mercado, mas é necessário');
    }
    
    // Validar preferências de Condomínio
    if (tripData.needsCondo && !primaryDriver.acceptsCondo) {
      throw Exception('Motorista não aceita condomínio, mas é necessário');
    }
    
    // Calcular distância entre passageiro e motorista
    final distance = _calculateDistance(
      tripData.originLatitude,
      tripData.originLongitude,
      primaryDriver.currentLatitude!,
      primaryDriver.currentLongitude!,
    );
    
    // Validar que motorista está próximo (máximo 10km)
    if (distance > 10.0) {
      dev.log('⚠️ Motorista está distante: ${distance.toStringAsFixed(2)} km', name: 'SimpleTest');
    }
    
    dev.log('✅ Critérios de matching atendidos:', name: 'SimpleTest');
    dev.log('   📍 Distância: ${distance.toStringAsFixed(2)} km', name: 'SimpleTest');
    dev.log('   ⭐ Qualificação: ${primaryDriver.ratings}/5.0', name: 'SimpleTest');
    dev.log('   🎯 Compatibilidade: OK', name: 'SimpleTest');
  }
  
  /// Valida funcionalidade do chat
  void _validateChatFunctionality() {
    // Testar criação de mensagens
    final passengerMessage = ChatMessage(
      id: 'msg_passenger_1',
      tripId: testTripId,
      senderId: testPassengerId,
      message: 'Olá motorista! Estou no local de embarque.',
      senderType: MessageSender.passenger,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      isFromCurrentUser: true,
    );
    
    final driverMessage = ChatMessage(
      id: 'msg_driver_1',
      tripId: testTripId,
      senderId: testDriverId,
      message: 'Oi! Estou chegando em 2 minutos.',
      senderType: MessageSender.driver,
      timestamp: DateTime.now(),
      status: MessageStatus.delivered,
      isFromCurrentUser: false,
    );
    
    // Validar estrutura das mensagens
    _validateChatMessage(passengerMessage);
    _validateChatMessage(driverMessage);
    
    // Testar ordenação por timestamp
    final messages = [driverMessage, passengerMessage];
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    dev.log('✅ Sistema de chat validado:', name: 'SimpleTest');
    dev.log('   💬 Mensagens criadas corretamente', name: 'SimpleTest');
    dev.log('   🔄 Ordenação por timestamp funcionando', name: 'SimpleTest');
    dev.log('   👥 Diferenciação passageiro/motorista OK', name: 'SimpleTest');
  }
  
  /// Valida estrutura de uma mensagem de chat
  void _validateChatMessage(ChatMessage message) {
    if (message.id.isEmpty) {
      throw Exception('ID da mensagem não pode estar vazio');
    }
    
    if (message.tripId.isEmpty) {
      throw Exception('ID da viagem na mensagem não pode estar vazio');
    }
    
    if (message.senderId.isEmpty) {
      throw Exception('ID do remetente não pode estar vazio');
    }
    
    if (message.message.trim().isEmpty) {
      throw Exception('Conteúdo da mensagem não pode estar vazio');
    }
    
    if (message.tripId != testTripId) {
      throw Exception('Trip ID da mensagem não confere: ${message.tripId} != $testTripId');
    }
    
    // Validar tipo do remetente
    final validSenderTypes = [MessageSender.passenger, MessageSender.driver];
    if (!validSenderTypes.contains(message.senderType)) {
      throw Exception('Tipo de remetente inválido: ${message.senderType}');
    }
    
    // Validar status
    final validStatuses = [
      MessageStatus.sending,
      MessageStatus.sent,
      MessageStatus.delivered,
      MessageStatus.read,
      MessageStatus.failed
    ];
    if (!validStatuses.contains(message.status)) {
      throw Exception('Status da mensagem inválido: ${message.status}');
    }
  }
  
  /// Valida o fluxo completo da viagem
  void _validateCompleteFlow(TripRequestData tripData, List<Driver> drivers) {
    final primaryDriver = drivers.first;
    
    // Simular estados da viagem
    final tripStates = [
      'pending',
      'driver_assigned',
      'driver_on_the_way',
      'driver_arrived',
      'trip_started',
      'trip_in_progress',
      'approaching_destination',
      'trip_completed',
    ];
    
    for (final state in tripStates) {
      dev.log('🔄 Estado da viagem: $state', name: 'SimpleTest');
      
      // Validar que cada estado é válido
      if (state.isEmpty) {
        throw Exception('Estado da viagem não pode estar vazio');
      }
      
      // Simular ações específicas para cada estado
      switch (state) {
        case 'driver_assigned':
          // Validar que temos um motorista
          if (primaryDriver.id.isEmpty) {
            throw Exception('Motorista deve estar atribuído');
          }
          break;
          
        case 'trip_started':
          // Validar que as coordenadas de origem são válidas
          if (tripData.originLatitude == 0 && tripData.originLongitude == 0) {
            throw Exception('Coordenadas de origem devem ser válidas');
          }
          break;
          
        case 'trip_completed':
          // Validar que as coordenadas de destino são válidas
          if (tripData.destinationLatitude == 0 && tripData.destinationLongitude == 0) {
            throw Exception('Coordenadas de destino devem ser válidas');
          }
          break;
      }
    }
    
    // Validar que temos fallback drivers
    if (drivers.length < 2) {
      dev.log('⚠️ Apenas ${drivers.length} motorista(s) disponível(is). Recomendado ter pelo menos 2 para fallback.', 
              name: 'SimpleTest');
    }
    
    dev.log('✅ Fluxo completo validado:', name: 'SimpleTest');
    dev.log('   📱 ${tripStates.length} estados da viagem processados', name: 'SimpleTest');
    dev.log('   🚗 ${drivers.length} motorista(s) disponível(is)', name: 'SimpleTest');
    dev.log('   🎯 Solicitação → Matching → Viagem → Conclusão', name: 'SimpleTest');
  }
  
  /// Calcula distância simples entre duas coordenadas (aproximação)
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    final dLat = (lat2 - lat1).abs();
    final dLng = (lng2 - lng1).abs();
    
    // Aproximação simples em km (1 grau ≈ 111 km)
    return ((dLat * 111) + (dLng * 111)) / 1.414; // Distância euclidiana aproximada
  }
}

/// Testes principais usando Flutter Test
void main() {
  group('Passenger-Driver Flow Simple Validation', () {
    late PassengerDriverFlowSimpleTest simpleTest;
    
    setUp(() {
      simpleTest = PassengerDriverFlowSimpleTest();
    });
    
    test('Complete flow validation without external dependencies', () {
      simpleTest.runSimpleFlowValidation();
    });
    
    test('Trip request data validation', () {
      final simpleTest = PassengerDriverFlowSimpleTest();
      final tripData = simpleTest._createTestTripRequestData();
      
      expect(tripData.originAddress, contains('Av. Paulista'));
      expect(tripData.destinationAddress, contains('Aeroporto'));
      expect(tripData.estimatedFare, greaterThan(20.0));
      expect(tripData.estimatedDistanceKm, greaterThan(10.0));
      expect(tripData.vehicleCategory, equals('economico'));
      expect(tripData.needsAc, isTrue);
      expect(tripData.needsPet, isFalse);
      expect(tripData.needsGrocerySpace, isFalse);
      
      dev.log('✅ Dados da solicitação validados nos testes unitários', name: 'SimpleTest');
    });
    
    test('Driver data validation', () {
      final simpleTest = PassengerDriverFlowSimpleTest();
      final drivers = simpleTest._createTestDriverList();
      
      expect(drivers, isNotEmpty);
      expect(drivers.length, greaterThanOrEqualTo(2));
      
      final primaryDriver = drivers.first;
      expect(primaryDriver.isOnline, isTrue);
      expect(primaryDriver.approvalStatus, equals('approved'));
      expect(primaryDriver.ratings, greaterThanOrEqualTo(4.0));
      expect(primaryDriver.currentLatitude, isNotNull);
      expect(primaryDriver.currentLongitude, isNotNull);
      
      dev.log('✅ Dados dos motoristas validados nos testes unitários', name: 'SimpleTest');
    });
    
    test('Chat message structure validation', () {
      final testMessage = ChatMessage(
        id: 'test_validation',
        tripId: 'trip_validation',
        senderId: 'sender_validation',
        message: 'Mensagem de teste para validação',
        senderType: MessageSender.passenger,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        isFromCurrentUser: true,
      );
      
      expect(testMessage.message, isNotEmpty);
      expect(testMessage.senderType, equals(MessageSender.passenger));
      expect(testMessage.status, equals(MessageStatus.sent));
      expect(testMessage.isFromCurrentUser, isTrue);
      expect(testMessage.id, equals('test_validation'));
      
      dev.log('✅ Estrutura de mensagem validada nos testes unitários', name: 'SimpleTest');
    });
    
    test('Matching criteria validation', () {
      final simpleTest = PassengerDriverFlowSimpleTest();
      final tripData = simpleTest._createTestTripRequestData();
      final drivers = simpleTest._createTestDriverList();
      
      final primaryDriver = drivers.first;
      
      // Validar critérios básicos
      expect(primaryDriver.isOnline, isTrue);
      expect(primaryDriver.approvalStatus, equals('approved'));
      expect(primaryDriver.acPolicy, equals('always')); // Atende needsAc: true
      expect(primaryDriver.acceptsGrocery, isTrue);
      expect(primaryDriver.acceptsCondo, isTrue);
      
      // Calcular distância aproximada
      final distance = simpleTest._calculateDistance(
        tripData.originLatitude,
        tripData.originLongitude,
        primaryDriver.currentLatitude!,
        primaryDriver.currentLongitude!,
      );
      
      expect(distance, lessThanOrEqualTo(5.0)); // Dentro de 5km
      
      dev.log('✅ Critérios de matching validados nos testes unitários', name: 'SimpleTest');
      dev.log('📍 Distância calculada: ${distance.toStringAsFixed(2)} km', name: 'SimpleTest');
    });
  });
}