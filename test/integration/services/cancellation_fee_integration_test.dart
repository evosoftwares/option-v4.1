import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:option/models/supabase/driver.dart';
import 'package:option/models/supabase/trip_request.dart';
import 'package:option/services/cancellation_fee_service.dart';
import '../../helpers/supabase_test_helper.dart';

void main() {
  group('CancellationFeeService Integration Tests', () {
    late SupabaseClient supabase;
    late CancellationFeeService cancellationService;
    
    setUpAll(() async {
      supabase = await SupabaseTestHelper.initialize();
      cancellationService = CancellationFeeService(supabase);
    });

    tearDownAll(() async {
      await SupabaseTestHelper.cleanup();
    });

    group('Cálculo de Taxa de Cancelamento', () {
      test('Não deve cobrar taxa se passageiro cancelar antes da aceitação', () async {
        // Arrange
        final tripRequest = TripRequest(
          passengerId: 'passenger-1',
          originAddress: 'Rua A, 123',
          originLatitude: -23.5505,
          originLongitude: -46.6333,
          destinationAddress: 'Rua B, 456',
          destinationLatitude: -23.5605,
          destinationLongitude: -46.6433,
          vehicleCategory: 'economico',
          needsPet: false,
          needsGrocery: false,
          isCondoDestination: false,
          isCondoOrigin: false,
          needsAc: false,
          numberOfStops: 0,
          estimatedDistanceKm: 5,
          estimatedDurationMinutes: 15,
          estimatedFare: 20,
          status: 'pending',
        );

        final context = CancellationContext(
          tripRequest: tripRequest,
          cancelledBy: 'passenger',
        );

        // Act
        final result = await cancellationService.calculateCancellationFee(context);

        // Assert
        expect(result.shouldChargeFee, isFalse);
        expect(result.feeAmount, equals(0.0));
        expect(result.reason, contains('ainda não aceitou'));
      });

      test('Deve cobrar taxa se passageiro cancelar após aceitação', () async {
        // Arrange
        final tripRequest = TripRequest(
          passengerId: 'passenger-1',
          originAddress: 'Rua A, 123',
          originLatitude: -23.5505,
          originLongitude: -46.6333,
          destinationAddress: 'Rua B, 456',
          destinationLatitude: -23.5605,
          destinationLongitude: -46.6433,
          vehicleCategory: 'economico',
          needsPet: false,
          needsGrocery: false,
          isCondoDestination: false,
          isCondoOrigin: false,
          needsAc: false,
          numberOfStops: 0,
          estimatedDistanceKm: 5,
          estimatedDurationMinutes: 15,
          estimatedFare: 20,
          status: 'accepted',
          acceptedByDriverId: 'driver-1',
          acceptedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );

        final context = CancellationContext(
          tripRequest: tripRequest,
          cancelledBy: 'passenger',
        );

        // Act
        final result = await cancellationService.calculateCancellationFee(context);

        // Assert
        expect(result.shouldChargeFee, isTrue);
        expect(result.feeAmount, greaterThan(0.0));
        expect(result.baseFee, equals(4.0)); // 20% de R$ 20,00 = R$ 4,00
      });

      test('Deve aplicar taxa máxima de R$ 10,00', () async {
        // Arrange - Viagem cara de R$ 100,00
        final tripRequest = TripRequest(
          passengerId: 'passenger-1',
          originAddress: 'Rua A, 123',
          originLatitude: -23.5505,
          originLongitude: -46.6333,
          destinationAddress: 'Rua B, 456',
          destinationLatitude: -23.5605,
          destinationLongitude: -46.6433,
          vehicleCategory: 'executivo',
          needsPet: false,
          needsGrocery: false,
          isCondoDestination: false,
          isCondoOrigin: false,
          needsAc: false,
          numberOfStops: 0,
          estimatedDistanceKm: 50,
          estimatedDurationMinutes: 60,
          estimatedFare: 100,
          status: 'accepted',
          acceptedByDriverId: 'driver-1',
          acceptedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );

        final context = CancellationContext(
          tripRequest: tripRequest,
          cancelledBy: 'passenger',
        );

        // Act
        final result = await cancellationService.calculateCancellationFee(context);

        // Assert
        expect(result.shouldChargeFee, isTrue);
        expect(result.baseFee, equals(10.0)); // Máximo de R$ 10,00
      });

      test('Deve cobrar 100% da taxa em caso de No-Show', () async {
        // Arrange
        final tripRequest = TripRequest(
          passengerId: 'passenger-1',
          originAddress: 'Rua A, 123',
          originLatitude: -23.5505,
          originLongitude: -46.6333,
          destinationAddress: 'Rua B, 456',
          destinationLatitude: -23.5605,
          destinationLongitude: -46.6433,
          vehicleCategory: 'economico',
          needsPet: false,
          needsGrocery: false,
          isCondoDestination: false,
          isCondoOrigin: false,
          needsAc: false,
          numberOfStops: 0,
          estimatedDistanceKm: 5,
          estimatedDurationMinutes: 15,
          estimatedFare: 20,
          status: 'accepted',
          acceptedByDriverId: 'driver-1',
          acceptedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        );

        final context = CancellationContext(
          tripRequest: tripRequest,
          cancelledBy: 'passenger',
          waitTimeMinutes: 5, // No-Show após 5 minutos
        );

        // Act
        final result = await cancellationService.calculateCancellationFee(context);

        // Assert
        expect(result.shouldChargeFee, isTrue);
        expect(result.displacementFactor, equals(1.0)); // 100%
        expect(result.feeAmount, equals(result.baseFee)); // Taxa completa
      });

      test('Não deve cobrar taxa se motorista cancelar', () async {
        // Arrange
        final tripRequest = TripRequest(
          passengerId: 'passenger-1',
          originAddress: 'Rua A, 123',
          originLatitude: -23.5505,
          originLongitude: -46.6333,
          destinationAddress: 'Rua B, 456',
          destinationLatitude: -23.5605,
          destinationLongitude: -46.6433,
          vehicleCategory: 'economico',
          needsPet: false,
          needsGrocery: false,
          isCondoDestination: false,
          isCondoOrigin: false,
          needsAc: false,
          numberOfStops: 0,
          estimatedDistanceKm: 5,
          estimatedDurationMinutes: 15,
          estimatedFare: 20,
          status: 'accepted',
          acceptedByDriverId: 'driver-1',
          acceptedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );

        final context = CancellationContext(
          tripRequest: tripRequest,
          cancelledBy: 'driver',
        );

        // Act
        final result = await cancellationService.calculateCancellationFee(context);

        // Assert
        expect(result.shouldChargeFee, isFalse);
        expect(result.feeAmount, equals(0.0));
        expect(result.reason, contains('Motorista cancelou'));
      });
    });

    group('Fator de Deslocamento', () {
      test('Deve calcular fator baseado na distância percorrida', () async {
        // Arrange
        final driver = Driver(
          id: 'driver-1',
          userId: 'user-1',
          cnhNumber: '123456789',
          cnhExpiryDate: DateTime.now().add(const Duration(days: 365)),
          cnhPhotoUrl: 'url',
          brand: 'Toyota',
          model: 'Corolla',
          year: 2020,
          color: 'Branco',
          plate: 'ABC-1234',
          category: 'economico',
          crlvPhotoUrl: 'url',
          approvalStatus: 'approved',
          isOnline: true,
          acceptsPet: false,
          acceptsGrocery: false,
          acceptsCondo: false,
          fees: {},
          currentLatitude: -23.5525, // Posição atual mais próxima do destino
          currentLongitude: -46.6353,
          ratings: 4.5,
          trips: 10,
          cancellations: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final tripRequest = TripRequest(
          passengerId: 'passenger-1',
          originAddress: 'Rua A, 123',
          originLatitude: -23.5505,
          originLongitude: -46.6333,
          vehicleCategory: 'economico',
          needsPet: false,
          needsGrocery: false,
          isCondoDestination: false,
          isCondoOrigin: false,
          needsAc: false,
          numberOfStops: 0,
          estimatedDistanceKm: 5,
          estimatedDurationMinutes: 15,
          estimatedFare: 20,
          status: 'accepted',
          acceptedByDriverId: 'driver-1',
          acceptedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          destinationAddress: 'Rua B, 456',
          destinationLatitude: -23.5605,
          destinationLongitude: -46.6433,
        );

        final context = CancellationContext(
          tripRequest: tripRequest,
          cancelledBy: 'passenger',
          driver: driver,
        );

        // Act
        final result = await cancellationService.calculateCancellationFee(context);

        // Assert
        expect(result.shouldChargeFee, isTrue);
        expect(result.displacementFactor, greaterThan(0.1));
        expect(result.displacementFactor, lessThanOrEqualTo(1.0));
      });
    });

    group('Processamento Completo de Cancelamento', () {
      test('Deve processar cancelamento com taxa e atualizar banco', () async {
        // Teste que requer mock do Supabase ou ambiente de teste
        // Pulamos por enquanto para não fazer alterações no banco de produção
      }, skip: 'Requer ambiente de teste isolado');
    });

    group('Sistema de Strikes', () {
      test('Deve incrementar cancelamentos consecutivos', () async {
        // Teste que verifica se as funções SQL estão sendo chamadas corretamente
        // Pulamos por enquanto para não fazer alterações no banco de produção
      }, skip: 'Requer ambiente de teste isolado');

      test('Deve suspender usuário após 3 cancelamentos consecutivos', () async {
        // Teste de integração completa do sistema de suspensão
        // Pulamos por enquanto para não fazer alterações no banco de produção
      }, skip: 'Requer ambiente de teste isolado');
    });

    group('Casos Edge', () {
      test('Deve lidar com erro de cálculo graciosamente', () async {
        // Arrange - Dados inválidos
        final tripRequest = TripRequest(
          passengerId: 'passenger-1',
          originAddress: 'Rua A, 123',
          originLatitude: 0, // Coordenada inválida
          originLongitude: 0,
          destinationAddress: 'Rua B, 456',
          destinationLatitude: 0,
          destinationLongitude: 0,
          vehicleCategory: 'economico',
          needsPet: false,
          needsGrocery: false,
          isCondoDestination: false,
          isCondoOrigin: false,
          needsAc: false,
          numberOfStops: 0,
          estimatedDistanceKm: -1, // Valor negativo
          estimatedDurationMinutes: 15,
          estimatedFare: 20,
          status: 'accepted',
          acceptedByDriverId: 'driver-1',
          acceptedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );

        final context = CancellationContext(
          tripRequest: tripRequest,
          cancelledBy: 'passenger',
        );

        // Act - Não deve lançar exceção
        final result = await cancellationService.calculateCancellationFee(context);

        // Assert - Deve retornar resultado seguro
        expect(result, isNotNull);
        expect(result.shouldChargeFee, isFalse);
        expect(result.reason, contains('Erro no cálculo'));
      });

      test('Deve aplicar taxa mínima quando fator de deslocamento é muito baixo', () async {
        // Arrange
        final tripRequest = TripRequest(
          passengerId: 'passenger-1',
          originAddress: 'Rua A, 123',
          originLatitude: -23.5505,
          originLongitude: -46.6333,
          destinationAddress: 'Rua B, 456',
          destinationLatitude: -23.5605,
          destinationLongitude: -46.6433,
          vehicleCategory: 'economico',
          needsPet: false,
          needsGrocery: false,
          isCondoDestination: false,
          isCondoOrigin: false,
          needsAc: false,
          numberOfStops: 0,
          estimatedDistanceKm: 0.1, // Distância muito pequena
          estimatedDurationMinutes: 1,
          estimatedFare: 8, // Tarifa mínima
          status: 'accepted',
          acceptedByDriverId: 'driver-1',
          acceptedAt: DateTime.now().subtract(const Duration(minutes: 2)),
        );

        final context = CancellationContext(
          tripRequest: tripRequest,
          cancelledBy: 'passenger',
        );

        // Act
        final result = await cancellationService.calculateCancellationFee(context);

        // Assert
        expect(result.shouldChargeFee, isTrue);
        expect(result.feeAmount, greaterThan(0.0));
        expect(result.displacementFactor, greaterThanOrEqualTo(0.1)); // Mínimo 10%
      });
    });
  });
}