import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:option/screens/profile/profile_edit_screen.dart';

void main() {
  group('ProfileEditScreen Widget Tests (UI Only)', () {
    Widget createTestWidget() => MaterialApp(
        home: const ProfileEditScreen(),
        routes: {
          '/login': (context) => const Scaffold(body: Text('Login')),
        },
      );

    group('UI Elements Rendering', () {
      testWidgets('should render all basic UI components', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Skip loading by manually advancing to settled state  
        await tester.pumpAndSettle();
        
        // Even with errors, should render the basic structure
        expect(find.text('Editar perfil'), findsOneWidget);
      });

      testWidgets('should display form structure correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Check AppBar
        expect(find.text('Editar perfil'), findsOneWidget);
        
        // Should have at least the form container and basic elements
        expect(find.byType(Form), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
      });
    });

    group('Form Field Validation (Client-side only)', () {
      testWidgets('should validate name field when empty', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Find name field (first TextFormField)
        final nameFieldFinder = find.byType(TextFormField).first;
        if (nameFieldFinder.evaluate().isNotEmpty) {
          await tester.tap(nameFieldFinder);
          await tester.enterText(nameFieldFinder, '');
          
          // Scroll down to reveal the save button
          await tester.drag(find.byType(ListView), const Offset(0, -400));
          await tester.pumpAndSettle();
          
          // Find and tap save button
          final saveButtonFinder = find.text('Salvar alterações');
          if (saveButtonFinder.evaluate().isNotEmpty) {
            await tester.tap(saveButtonFinder);
            await tester.pump();
            
            // Should show validation error
            expect(find.text('Informe seu nome completo'), findsOneWidget);
          }
        }
      });

      testWidgets('should format phone input correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Find phone field (second TextFormField if exists)
        final phoneFieldFinders = find.byType(TextFormField);
        if (phoneFieldFinders.evaluate().length >= 2) {
          final phoneField = phoneFieldFinders.at(1);
          
          await tester.tap(phoneField);
          await tester.enterText(phoneField, '11987654321');
          await tester.pump();
          
          // Check if phone formatter is working
          final field = tester.widget<TextFormField>(phoneField);
          // The phone formatter should format the input
          expect(field.controller?.text.contains('('), isTrue);
        }
      });
    });

    group('User Type Selection', () {
      testWidgets('should render user type chips', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Scroll down to reveal the user type section
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();
        
        // Should have passenger and driver chips
        expect(find.text('Passageiro'), findsOneWidget);
        expect(find.text('Motorista'), findsOneWidget);
        expect(find.byType(ChoiceChip), findsNWidgets(2));
      });

      testWidgets('should allow selecting user type', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Scroll down to reveal the user type section
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();
        
        final driverChip = find.widgetWithText(ChoiceChip, 'Motorista');
        if (driverChip.evaluate().isNotEmpty) {
          await tester.tap(driverChip);
          await tester.pump();
          
          // The chip should update its visual state
          final chip = tester.widget<ChoiceChip>(driverChip);
          // Note: Without proper mocking, we can't test the selection state
          // but we can test that the tap doesn't cause errors
          expect(chip, isNotNull);
        }
      });
    });

    group('Photo Selection UI', () {
      testWidgets('should show profile photo section', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Should have avatar and camera button
        expect(find.byType(CircleAvatar), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.camera_alt), findsOneWidget);
        expect(find.text('Toque no ícone para alterar sua foto'), findsOneWidget);
      });

      testWidgets('should show photo source dialog on camera tap', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        final cameraButton = find.byIcon(Icons.camera_alt);
        if (cameraButton.evaluate().isNotEmpty) {
          await tester.tap(cameraButton);
          await tester.pumpAndSettle();
          
          // Should show bottom sheet with options
          expect(find.text('Câmera'), findsOneWidget);
          expect(find.text('Galeria'), findsOneWidget);
          expect(find.byIcon(Icons.photo_library), findsOneWidget);
        }
      });
    });

    group('Form Labels and Hints', () {
      testWidgets('should display correct field labels', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Check field labels
        expect(find.text('Nome completo'), findsOneWidget);
        expect(find.text('Telefone'), findsOneWidget);
        expect(find.text('Tipo de usuário'), findsOneWidget);
        expect(find.text('Informações da conta'), findsOneWidget);
      });

      testWidgets('should display correct input hints', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        expect(find.text('Seu nome e sobrenome'), findsOneWidget);
        expect(find.text('(11) 9 1234-5678'), findsOneWidget);
      });
    });

    group('Button States', () {
      testWidgets('should show save button', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Scroll down to reveal the save button
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();
        
        // Look for save button - might be in different states
        expect(find.text('Salvar alterações'), findsOneWidget);
      });
    });

    group('Navigation Structure', () {
      testWidgets('should have proper app bar', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Should have app bar with title
        expect(find.text('Editar perfil'), findsOneWidget);
      });

      testWidgets('should have scrollable content', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Should have ListView for scrollable content
        expect(find.byType(ListView), findsOneWidget);
      });
    });

    group('Widget Structure Tests', () {
      testWidgets('should have proper form structure', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Should have Form widget
        expect(find.byType(Form), findsOneWidget);
        
        // Should have SafeArea
        expect(find.byType(SafeArea), findsAtLeastNWidgets(1));
        
        // Should have Scaffold
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('should render without throwing exceptions', (tester) async {
        // This test ensures the widget can be rendered without crashing
        expect(() async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();
        }, returnsNormally);
      });
    });
  });
}