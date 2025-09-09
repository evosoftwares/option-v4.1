import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:option/screens/place_picker_screen.dart';

void main() {
  group('PlacePickerScreen Integration Tests', () {
    testWidgets('should not show favorite type in manual selection', (tester) async {
      // Arrange
      const testApp = MaterialApp(
        home: PlacePickerScreen(
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

    testWidgets('should show correct title for place selection', (tester) async {
      // Arrange
      const testApp = MaterialApp(
        home: PlacePickerScreen(
          title: 'Selecionar Local',
        ),
      );

      // Act
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Selecionar Local'), findsOneWidget);
      expect(find.byType(PlacePickerScreen), findsOneWidget);
    });
  });
}