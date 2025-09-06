import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:option/models/supabase/trip.dart';
import 'package:option/models/supabase/trip_request.dart';
import 'package:option/screens/driver/driver_trip_screen.dart';
import 'package:option/screens/trips/trip_history_screen.dart';
import 'package:option/services/trip_service.dart';

import '../helpers/test_constants.dart';

/// Teste de integração para o fluxo completo de conclusão de viagem do motorista
/// Este teste deve FALHAR até implementarmos:
/// 1. Botões de status na DriverTripScreen (chegou, embarcou, finalizou)
/// 2. TripRatingScreen para avaliação pós-viagem
/// 3. Navegação automática entre estados da viagem
class MockTripService extends Mock implements TripService {}

void main() {
  group('Driver Trip Completion Flow Integration Tests', () {
    late MockTripService mockTripService;
    late Trip testTrip;
    late TripRequest testTripRequest;

    setUp(() {
      mockTripService = MockTripService();
      
      // Trip de teste em estado 'accepted' (motorista aceitou)
      testTrip = Trip(
        id: TestConstants.testTripId,
        tripRequestId: TestConstants.testTripRequestId,
        driverId: TestConstants.testDriverId,
        passengerId: TestConstants.testPassengerId,
        originAddress: 'Rua A, 123',
        originLatitude: -23.5505,
        originLongitude: -46.6333,
        destinationAddress: 'Rua B, 456', 
        destinationLatitude: -23.5485,
        destinationLongitude: -46.6343,
        actualDistanceKm: 5.2,
        actualDurationMinutes: 15,
        baseFare: 12.50,
        finalFare: 12.50,
        status: 'accepted', // Motorista aceitou, indo buscar passageiro
        startTime: DateTime.now().subtract(const Duration(minutes: 5)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      testTripRequest = TripRequest(
        id: TestConstants.testTripRequestId,
        passengerId: TestConstants.testPassengerId,
        originAddress: 'Rua A, 123',
        originLatitude: -23.5505,
        originLongitude: -46.6333,
        destinationAddress: 'Rua B, 456',
        destinationLatitude: -23.5485,
        destinationLongitude: -46.6343,
        vehicleCategory: 'standard',
        needsPet: false,
        needsGrocerySpace: false,
        isCondoDestination: false,
        isCondoOrigin: false,
        needsAc: false,
        numberOfStops: 0,
        estimatedDistanceKm: 5,
        estimatedDurationMinutes: 15,
        estimatedFare: 12.50,
        status: 'accepted',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
    });

    testWidgets(
      'FAILING TEST: Driver should complete full trip flow from accepted to rated',
      (tester) async {
        // Configurar mocks para os diferentes estados da viagem
        when(mockTripService.getTrip(TestConstants.testTripId))
            .thenAnswer((_) async => testTrip);
        
        when(mockTripService.subscribeToTrip(TestConstants.testTripId))
            .thenAnswer((_) => Stream.value(testTrip));

        // STEP 1: Motorista está na tela da viagem (status: accepted)
        await tester.pumpWidget(
          const MaterialApp(
            home: DriverTripScreen(),
          ),
        );
        await tester.pumpAndSettle();

        // ❌ ESTE TESTE DEVE FALHAR: Não existe botão "Cheguei ao local"
        expect(find.text('Cheguei ao local'), findsOneWidget,
            reason: 'Driver should have button to mark arrival at pickup location');
        
        // STEP 2: Motorista toca em "Cheguei ao local"
        await tester.tap(find.text('Cheguei ao local'));
        await tester.pumpAndSettle();

        // Simular mudança de status para 'driver_arrived'
        final arrivedTrip = testTrip.copyWith(status: 'driver_arrived');
        when(mockTripService.subscribeToTrip(TestConstants.testTripId))
            .thenAnswer((_) => Stream.value(arrivedTrip));
        
        when(mockTripService.updateTripRequestStatus(
          id: TestConstants.testTripId,
          status: 'driver_arrived',
          driverId: TestConstants.testDriverId,
        )).thenAnswer((_) async => testTripRequest.copyWith(status: 'driver_arrived'));

        await tester.pumpAndSettle();

        // ❌ ESTE TESTE DEVE FALHAR: Não existe botão "Passageiro embarcou"
        expect(find.text('Passageiro embarcou'), findsOneWidget,
            reason: 'Driver should have button to mark passenger pickup');

        // STEP 3: Motorista toca em "Passageiro embarcou"
        await tester.tap(find.text('Passageiro embarcou'));
        await tester.pumpAndSettle();

        // Simular mudança de status para 'in_progress'
        final inProgressTrip = arrivedTrip.copyWith(status: 'in_progress');
        when(mockTripService.subscribeToTrip(TestConstants.testTripId))
            .thenAnswer((_) => Stream.value(inProgressTrip));

        await tester.pumpAndSettle();

        // ❌ ESTE TESTE DEVE FALHAR: Não existe botão "Chegamos ao destino"
        expect(find.text('Chegamos ao destino'), findsOneWidget,
            reason: 'Driver should have button to complete trip');

        // STEP 4: Motorista toca em "Chegamos ao destino"
        await tester.tap(find.text('Chegamos ao destino'));
        await tester.pumpAndSettle();

        // Simular conclusão da viagem
        final completedTrip = inProgressTrip.copyWith(
          status: 'completed',
          endTime: DateTime.now(),
        );
        
        when(mockTripService.completeTrip(
          tripId: TestConstants.testTripId,
          actualDistanceKm: 5.2,
          actualDurationMinutes: 15,
          finalFare: 12.50,
        )).thenAnswer((_) async => completedTrip);

        // ❌ ESTE TESTE DEVE FALHAR: Não existe TripRatingScreen
        // Deveria navegar automaticamente para tela de avaliação
        await tester.pumpAndSettle();
        expect(find.byType(TripRatingScreen), findsOneWidget,
            reason: 'Should navigate to rating screen after trip completion');

        // STEP 5: Tela de avaliação deve aparecer
        // ❌ ESTE TESTE DEVE FALHAR: TripRatingScreen não existe
        expect(find.text('Como foi sua experiência?'), findsOneWidget,
            reason: 'Rating screen should show rating question');
        
        expect(find.byIcon(Icons.star), findsNWidgets(5),
            reason: 'Rating screen should show 5 star rating system');

        // STEP 6: Motorista avalia o passageiro
        // ❌ ESTE TESTE DEVE FALHAR: Não existe sistema de avaliação
        await tester.tap(find.byIcon(Icons.star).at(4)); // 5 estrelas
        await tester.pumpAndSettle();

        // Botão de finalizar avaliação
        expect(find.text('Finalizar'), findsOneWidget);
        await tester.tap(find.text('Finalizar'));
        await tester.pumpAndSettle();

        // Verificar se avaliação foi salva
        when(mockTripService.rateTrip(
          tripId: TestConstants.testTripId,
          passengerRating: 5,
        )).thenAnswer((_) async => completedTrip.copyWith(passengerRating: 5));

        // STEP 7: Deve voltar para tela principal do motorista
        // ❌ ESTE TESTE DEVE FALHAR: Não existe navegação automática
        await tester.pumpAndSettle();
        expect(find.text('Viagem concluída!'), findsOneWidget,
            reason: 'Should show completion message');

        // Verificar se todas as chamadas de API foram feitas
        verify(mockTripService.updateTripRequestStatus(
          id: TestConstants.testTripId,
          status: 'driver_arrived',
          driverId: TestConstants.testDriverId,
        )).called(1);

        verify(mockTripService.completeTrip(
          tripId: TestConstants.testTripId,
          actualDistanceKm: 5.2,
          actualDurationMinutes: 15,
          finalFare: 12.50,
        )).called(1);

        verify(mockTripService.rateTrip(
          tripId: TestConstants.testTripId,
          passengerRating: 5,
        )).called(1);
      },
    );

    testWidgets(
      'FAILING TEST: Driver should be able to cancel trip with reason',
      (tester) async {
        when(mockTripService.getTrip(TestConstants.testTripId))
            .thenAnswer((_) async => testTrip);
        
        when(mockTripService.subscribeToTrip(TestConstants.testTripId))
            .thenAnswer((_) => Stream.value(testTrip));

        await tester.pumpWidget(
          const MaterialApp(
            home: DriverTripScreen(),
          ),
        );
        await tester.pumpAndSettle();

        // ❌ ESTE TESTE DEVE FALHAR: Não existe botão de cancelamento
        expect(find.text('Cancelar viagem'), findsOneWidget,
            reason: 'Driver should have option to cancel trip');

        await tester.tap(find.text('Cancelar viagem'));
        await tester.pumpAndSettle();

        // ❌ ESTE TESTE DEVE FALHAR: Não existe dialog de cancelamento
        expect(find.text('Motivo do cancelamento'), findsOneWidget,
            reason: 'Should show cancellation reason dialog');

        expect(find.text('Passageiro não apareceu'), findsOneWidget);
        expect(find.text('Problema com veículo'), findsOneWidget);
        expect(find.text('Outro motivo'), findsOneWidget);
      },
    );

    testWidgets(
      'FAILING TEST: Driver should see trip history with completed trips',
      (tester) async {
        final completedTrip = testTrip.copyWith(
          status: 'completed',
          endTime: DateTime.now(),
          passengerRating: 4.5,
        );

        // ❌ ESTE TESTE DEVE FALHAR: Histórico não mostra trips completados
        when(mockTripService.getTripHistory(driverId: TestConstants.testDriverId))
            .thenAnswer((_) async => [
              TripHistoryModel(
                id: TestConstants.testTripId,
                tripCode: 'TRIP001',
                status: 'completed',
                originAddress: 'Rua A, 123',
                destinationAddress: 'Rua B, 456',
                baseFare: 12.50,
                additionalFees: 0,
                requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
                completedAt: DateTime.now(),
                paymentStatus: 'paid',
                passengerRating: 4.5,
                otherUserName: 'João Silva',
              ),
            ]);

        await tester.pumpWidget(
          MaterialApp(
            initialRoute: '/trip_history',
            routes: {
              '/trip_history': (context) => const TripHistoryScreen(),
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('TRIP001'), findsOneWidget,
            reason: 'Should show completed trip in history');
        expect(find.text('4.5 ⭐'), findsOneWidget,
            reason: 'Should show passenger rating in history');
      },
    );
  });
}

/// Classe que deveria existir mas não existe ainda
/// ❌ Este arquivo não existe: lib/screens/rating/trip_rating_screen.dart
class TripRatingScreen extends StatefulWidget {
  const TripRatingScreen({
    super.key,
    required this.tripId,
    required this.isDriver,
  });

  final String tripId;
  final bool isDriver;

  @override
  State<TripRatingScreen> createState() => _TripRatingScreenState();
}

class _TripRatingScreenState extends State<TripRatingScreen> {
  @override
  Widget build(BuildContext context) {
    // Esta implementação ainda não existe
    throw UnimplementedError('TripRatingScreen not implemented yet');
  }
}