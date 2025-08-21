import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:option/models/favorite_location.dart';
import 'package:option/screens/place_picker_screen.dart';

void main() {
  group('PlacePickerScreen Favorites Tests', () {
    testWidgets('should use favorite type when isForFavorites is true', (WidgetTester tester) async {
      // Arrange
      const testApp = MaterialApp(
        home: PlacePickerScreen(
          isForFavorites: true,
          title: 'Test Favorites',
        ),
      );

      // Act
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Favorites'), findsOneWidget);
      expect(find.byType(PlacePickerScreen), findsOneWidget);
    });

    testWidgets('should show type selection when isForFavorites is false', (WidgetTester tester) async {
      // Arrange
      const testApp = MaterialApp(
        home: PlacePickerScreen(
          isForFavorites: false,
          title: 'Test Regular',
        ),
      );

      // Act
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Regular'), findsOneWidget);
      expect(find.byType(PlacePickerScreen), findsOneWidget);
    });

    test('LocationType.favorite should have correct properties', () {
      // Arrange & Act
      const favoriteType = LocationType.favorite;

      // Assert
      expect(favoriteType.label, equals('Favorito'));
      expect(favoriteType.description, equals('Local favorito'));
      expect(favoriteType.icon, equals(Icons.favorite));
    });
  });
}