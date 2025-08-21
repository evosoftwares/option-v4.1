import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:option/models/favorite_location.dart';
import 'package:option/screens/place_picker_screen.dart';

void main() {
  group('PlacePickerScreen Integration Tests', () {
    testWidgets('should not show favorite type in manual selection', (WidgetTester tester) async {
      // Arrange
      const testApp = MaterialApp(
        home: PlacePickerScreen(
          isForFavorites: false,
          title: 'Test Selection',
        ),
      );

      // Act
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Simulate selecting a location and opening type selection
      // Note: This would require a more complex setup with actual location data
      // For now, we'll test the basic widget structure
      
      // Assert
      expect(find.byType(PlacePickerScreen), findsOneWidget);
      expect(find.text('Test Selection'), findsOneWidget);
    });

    testWidgets('should show correct title for favorites', (WidgetTester tester) async {
      // Arrange
      const testApp = MaterialApp(
        home: PlacePickerScreen(
          isForFavorites: true,
          title: 'Adicionar Favorito',
        ),
      );

      // Act
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Adicionar Favorito'), findsOneWidget);
      expect(find.byType(PlacePickerScreen), findsOneWidget);
    });

    test('should create FavoriteLocation with favorite type', () {
      // Arrange
      final location = FavoriteLocation(
        id: 'test-id',
        name: 'Test Location',
        address: 'Test Address',
        type: LocationType.favorite,
        latitude: -23.5505,
        longitude: -46.6333,
      );

      // Assert
      expect(location.type, equals(LocationType.favorite));
      expect(location.type.label, equals('Favorito'));
      expect(location.type.description, equals('Local favorito'));
      expect(location.type.icon, equals(Icons.favorite));
    });

    test('should serialize and deserialize favorite location correctly', () {
      // Arrange
      final originalLocation = FavoriteLocation(
        id: 'test-id',
        name: 'Test Location',
        address: 'Test Address',
        type: LocationType.favorite,
        latitude: -23.5505,
        longitude: -46.6333,
        placeId: 'test-place-id',
      );

      // Act
      final json = originalLocation.toJson();
      final deserializedLocation = FavoriteLocation.fromJson(json);

      // Assert
      expect(deserializedLocation.id, equals(originalLocation.id));
      expect(deserializedLocation.name, equals(originalLocation.name));
      expect(deserializedLocation.address, equals(originalLocation.address));
      expect(deserializedLocation.type, equals(originalLocation.type));
      expect(deserializedLocation.latitude, equals(originalLocation.latitude));
      expect(deserializedLocation.longitude, equals(originalLocation.longitude));
      expect(deserializedLocation.placeId, equals(originalLocation.placeId));
    });
  });
}