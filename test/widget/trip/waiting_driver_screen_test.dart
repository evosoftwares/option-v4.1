import 'package:flutter_test/flutter_test.dart';
import 'package:option/screens/trip/waiting_driver_screen.dart';

void main() {
  group('WaitingDriverScreen - Testes Básicos', () {
    testWidgets('deve instanciar sem crash fatal', (tester) async {
      // Arrange
      const tripRequestId = 'test-trip-id';
      var hasFatalCrash = false;

      // Act
      try {
        const widget = WaitingDriverScreen(tripRequestId: tripRequestId);
        expect(widget, isNotNull);
        expect(widget.tripRequestId, equals(tripRequestId));
      } catch (e) {
        hasFatalCrash = true;
        print('Erro durante instanciação: $e');
      }

      // Assert
      expect(hasFatalCrash, isFalse, reason: 'Widget não deve ter crash fatal durante instanciação');
    });

    testWidgets('deve aceitar diferentes IDs', (tester) async {
      // Arrange
      const tripRequestIds = ['id1', 'id2', 'test-123', 'expired-trip'];
      var hasFatalCrash = false;

      // Act
      try {
        for (final id in tripRequestIds) {
          final widget = WaitingDriverScreen(tripRequestId: id);
          expect(widget, isNotNull);
          expect(widget.tripRequestId, equals(id));
        }
      } catch (e) {
        hasFatalCrash = true;
        print('Erro durante teste de IDs: $e');
      }

      // Assert
      expect(hasFatalCrash, isFalse, reason: 'Widget deve aceitar diferentes IDs sem crash');
    });

    testWidgets('deve ter propriedades básicas', (tester) async {
      // Arrange
      const tripRequestId = 'property-test-id';
      var hasFatalCrash = false;

      // Act
      try {
        const widget = WaitingDriverScreen(tripRequestId: tripRequestId);
        
        // Verificar propriedades básicas
        expect(widget.tripRequestId, isA<String>());
        expect(widget.tripRequestId.isNotEmpty, isTrue);
        expect(widget.key, isNull); // Key padrão é null
      } catch (e) {
        hasFatalCrash = true;
        print('Erro durante teste de propriedades: $e');
      }

      // Assert
      expect(hasFatalCrash, isFalse, reason: 'Widget deve ter propriedades básicas acessíveis');
    });
  });
}