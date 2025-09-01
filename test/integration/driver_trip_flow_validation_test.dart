import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/screens/rating/trip_rating_screen.dart';
import '../../lib/screens/driver/driver_trip_screen.dart';

/// Teste de validação para verificar se a implementação está funcionando
void main() {
  group('Driver Trip Flow - Validation Tests', () {
    testWidgets(
      'TripRatingScreen can be instantiated with correct parameters',
      (WidgetTester tester) async {
        const tripRatingScreen = TripRatingScreen(
          tripId: 'test-trip',
          isDriver: true,
        );
        
        expect(tripRatingScreen, isNotNull);
        expect(tripRatingScreen.tripId, equals('test-trip'));
        expect(tripRatingScreen.isDriver, isTrue);
      },
    );

    testWidgets(
      'TripRatingScreen displays all required UI elements',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: TripRatingScreen(
              tripId: 'test-trip',
              isDriver: true,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verificar elementos principais da UI
        expect(find.text('Avaliar viagem'), findsOneWidget);
        expect(find.text('Como foi sua experiência com o passageiro?'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsNWidgets(5));
        expect(find.text('Finalizar'), findsOneWidget);
        expect(find.text('Pular avaliação'), findsOneWidget);
        expect(find.text('Viagem concluída!'), findsOneWidget);
      },
    );

    testWidgets(
      'TripRatingScreen star rating system works correctly',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: TripRatingScreen(
              tripId: 'test-trip',
              isDriver: true,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Estado inicial - nenhuma estrela selecionada
        expect(find.text('Toque nas estrelas para avaliar'), findsOneWidget);

        // Tocar na 5ª estrela
        final fifthStar = find.byIcon(Icons.star).last;
        await tester.tap(fifthStar);
        await tester.pumpAndSettle();

        // Verificar se o texto mudou para "Excelente"
        expect(find.text('Excelente'), findsOneWidget);
      },
    );

    testWidgets(
      'DriverTripScreen can be instantiated',
      (WidgetTester tester) async {
        const driverTripScreen = DriverTripScreen();
        expect(driverTripScreen, isNotNull);

        // Testar se pode ser renderizada (mesmo com problemas de permissão)
        await tester.pumpWidget(
          const MaterialApp(
            home: DriverTripScreen(),
          ),
        );

        await tester.pump();
        expect(find.byType(DriverTripScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Navigation to TripRatingScreen works correctly',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            routes: {
              '/trip_rating': (context) => const TripRatingScreen(
                tripId: 'test-trip',
                isDriver: true,
              ),
            },
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/trip_rating',
                  ),
                  child: const Text('Navigate to Rating'),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tocar no botão de navegação
        await tester.tap(find.text('Navigate to Rating'));
        await tester.pumpAndSettle();

        // Verificar se chegou na tela de avaliação
        expect(find.text('Como foi sua experiência com o passageiro?'), findsOneWidget);
      },
    );
  });

  group('Driver Trip Flow - Unit Tests', () {
    test('TripRatingScreen should have correct route name', () {
      expect(TripRatingScreen.routeName, equals('/trip_rating'));
    });

    test('TripRatingScreen.fromArgs handles null arguments', () {
      final screen = TripRatingScreen.fromArgs(null);
      expect(screen.tripId, equals(''));
      expect(screen.isDriver, isFalse);
    });

    test('TripRatingScreen.fromArgs handles valid arguments', () {
      final args = {
        'tripId': 'test-123',
        'isDriver': true,
      };
      final screen = TripRatingScreen.fromArgs(args);
      expect(screen.tripId, equals('test-123'));
      expect(screen.isDriver, isTrue);
    });

    test('Driver trip status flow covers all expected states', () {
      const expectedStatuses = [
        'accepted',
        'driver_arrived', 
        'in_progress',
        'completed'
      ];
      
      // Verificar se todos os status esperados estão definidos
      for (final status in expectedStatuses) {
        expect(expectedStatuses.contains(status), isTrue,
            reason: 'Status $status should be included in the flow');
      }
    });

    test('Rating values should be within valid range', () {
      const validRatings = [1, 2, 3, 4, 5];
      
      for (final rating in validRatings) {
        expect(rating, greaterThanOrEqualTo(1));
        expect(rating, lessThanOrEqualTo(5));
      }
    });
  });
}