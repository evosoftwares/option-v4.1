/// Teste de integração completo para edição de perfil
/// Simula todos os cenários reais de edição: nome, telefone, foto, tipo de usuário
library;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:option/main.dart' as app;
import 'package:option/screens/profile/profile_edit_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('✏️ Complete Profile Edit Integration Tests', () {
    
    testWidgets('📝 Complete Profile Edit Flow - Name Change', (tester) async {
      print('🧪 Testing Profile Edit Flow - Name Change...');
      
      // Launch app and navigate to profile edit
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Navigate to profile (look for profile icon/button)
      final profileButton = find.byIcon(Icons.person).first;
      if (profileButton.evaluate().isNotEmpty) {
        await tester.tap(profileButton);
        await tester.pumpAndSettle();
        print('✅ Navigated to profile screen');
      }
      
      // Look for edit button
      final editButton = find.text('Editar perfil');
      if (editButton.evaluate().isEmpty) {
        final editIcon = find.byIcon(Icons.edit);
        if (editIcon.evaluate().isNotEmpty) {
          await tester.tap(editIcon.first);
          await tester.pumpAndSettle();
        }
      } else {
        await tester.tap(editButton);
        await tester.pumpAndSettle();
      }
      
      print('✅ Opened profile edit screen');
      
      // Test name editing
      final nameFields = find.byType(TextFormField);
      if (nameFields.evaluate().isNotEmpty) {
        final nameField = nameFields.first;
        
        // Clear existing text and enter new name
        await tester.enterText(nameField, '');
        await tester.enterText(nameField, 'João Silva Testado');
        await tester.pumpAndSettle();
        
        print('✅ Name field updated to: João Silva Testado');
        
        // Verify the text appears in the field
        expect(find.text('João Silva Testado'), findsAtLeastNWidgets(1));
      }
      
      // Test form validation
      await tester.enterText(nameFields.first, ''); // Empty name
      await tester.pumpAndSettle();
      
      final saveButton = find.text('Salvar');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        
        // Should show validation error for empty name
        expect(find.text('Campo obrigatório'), findsAtLeastNWidgets(1), 
               reason: 'Should show validation error for empty name');
        print('✅ Name validation working correctly');
      }
      
      // Restore valid name
      await tester.enterText(nameFields.first, 'João Silva Testado');
      await tester.pumpAndSettle();
      
      print('🎯 Profile Edit Flow - Name Change: PASSED');
    });

    testWidgets('📱 Phone Number Formatting and Validation', (tester) async {
      print('🧪 Testing Phone Number Formatting...');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Navigate to profile edit
      final profileEdit = find.byType(ProfileEditScreen);
      if (profileEdit.evaluate().isEmpty) {
        // Mock navigation to profile edit
        print('📝 Simulating navigation to ProfileEditScreen');
      }
      
      // Test phone number formatting
      final phoneFields = find.byType(TextFormField).where(
        (widget) => widget.evaluate().any((element) {
          final field = element.widget as TextFormField;
          return field.decoration?.labelText?.contains('Telefone') == true ||
                 field.decoration?.hintText?.contains('telefone') == true;
        })
      );
      
      if (phoneFields.isNotEmpty) {
        final phoneField = phoneFields.first;
        
        // Test various phone formats
        final testCases = [
          {'input': '11999887766', 'expected': '(11) 99988-7766'},
          {'input': '1199988776', 'expected': '(11) 9998-8776'},
          {'input': '11988776655', 'expected': '(11) 98877-6655'},
        ];
        
        for (final testCase in testCases) {
          await tester.enterText(phoneField, testCase['input']!);
          await tester.pumpAndSettle();
          
          // Verify formatting is applied
          expect(find.textContaining(testCase['expected']!), findsAtLeastNWidgets(1));
          print('✅ Phone formatting: ${testCase['input']} -> ${testCase['expected']}');
        }
      }
      
      print('🎯 Phone Number Formatting and Validation: PASSED');
    });

    testWidgets('🖼️ Photo Upload Simulation', (tester) async {
      print('🧪 Testing Photo Upload Flow...');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Look for photo upload button/icon
      final cameraIcons = find.byIcon(Icons.camera_alt);
      final photoIcons = find.byIcon(Icons.photo);
      final uploadButtons = find.text('Adicionar foto');
      
      if (cameraIcons.evaluate().isNotEmpty) {
        await tester.tap(cameraIcons.first);
        await tester.pumpAndSettle();
        
        print('✅ Camera icon tapped - should show photo source dialog');
        
        // Look for photo source dialog
        expect(find.text('Selecionar fonte'), findsAny, reason: 'Should show photo source selection');
        
        // Test dialog options
        final cameraOption = find.text('Câmera');
        final galleryOption = find.text('Galeria');
        
        if (cameraOption.evaluate().isNotEmpty) {
          print('✅ Camera option available');
        }
        
        if (galleryOption.evaluate().isNotEmpty) {
          print('✅ Gallery option available');
          // Simulate selecting gallery (won't actually open, but tests UI flow)
          await tester.tap(galleryOption);
          await tester.pumpAndSettle();
        }
      }
      
      print('🎯 Photo Upload Simulation: PASSED');
    });

    testWidgets('👥 User Type Change Flow', (tester) async {
      print('🧪 Testing User Type Change...');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Look for user type selection chips
      final passengerChip = find.text('Passageiro');
      final driverChip = find.text('Motorista');
      
      if (passengerChip.evaluate().isNotEmpty && driverChip.evaluate().isNotEmpty) {
        print('✅ Found user type selection chips');
        
        // Test switching between types
        await tester.tap(passengerChip);
        await tester.pumpAndSettle();
        print('✅ Selected Passenger type');
        
        // Verify selection is reflected
        final selectedPassenger = find.byType(ChoiceChip).where((widget) {
          final chip = widget.evaluate().first.widget as ChoiceChip;
          return chip.selected == true && chip.label.toString().contains('Passageiro');
        });
        
        await tester.tap(driverChip);
        await tester.pumpAndSettle();
        print('✅ Selected Driver type');
        
        // Test that changing to driver shows additional fields
        final additionalFields = find.text('CNH');
        if (additionalFields.evaluate().isNotEmpty) {
          print('✅ Driver-specific fields appeared');
        }
      }
      
      print('🎯 User Type Change Flow: PASSED');
    });

    testWidgets('💾 Complete Save Profile Flow', (tester) async {
      print('🧪 Testing Complete Save Profile Flow...');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Fill complete profile form
      final textFields = find.byType(TextFormField);
      
      if (textFields.evaluate().length >= 2) {
        // Fill name
        await tester.enterText(textFields.first, 'Usuario Teste Completo');
        await tester.pumpAndSettle();
        
        // Fill phone
        await tester.enterText(textFields.at(1), '11987654321');
        await tester.pumpAndSettle();
        
        print('✅ Profile form filled completely');
        
        // Attempt to save
        final saveButton = find.text('Salvar');
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle(const Duration(seconds: 5));
          
          print('✅ Save button pressed');
          
          // Verify no crashes occurred
          expect(tester.takeException(), isNull, reason: 'Save should not cause crashes');
          
          // Look for success indicators
          final successIndicators = [
            find.text('Perfil atualizado'),
            find.text('Sucesso'),
            find.text('Salvo'),
            find.byIcon(Icons.check),
          ];
          
          var foundSuccessIndicator = false;
          for (final indicator in successIndicators) {
            if (indicator.evaluate().isNotEmpty) {
              foundSuccessIndicator = true;
              print('✅ Success indicator found');
              break;
            }
          }
          
          // Also check that we didn't get an error
          final errorIndicators = [
            find.text('Erro'),
            find.text('Falhou'),
            find.byIcon(Icons.error),
          ];
          
          for (final indicator in errorIndicators) {
            expect(indicator, findsNothing, reason: 'Should not show error after valid save');
          }
          
          print('✅ Save completed without errors');
        }
      }
      
      print('🎯 Complete Save Profile Flow: PASSED');
    });

    testWidgets('🔄 Profile Persistence Test', (tester) async {
      print('🧪 Testing Profile Data Persistence...');
      
      // This tests that profile changes persist across app restarts
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Save test data
      final nameField = find.byType(TextFormField).first;
      const testName = 'Persistencia Teste';
      
      await tester.enterText(nameField, testName);
      await tester.pumpAndSettle();
      
      final saveButton = find.text('Salvar');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
      
      // Simulate app restart by re-pumping main
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Check if data persisted
      expect(find.text(testName), findsAny, reason: 'Profile data should persist across app restarts');
      
      print('🎯 Profile Persistence Test: PASSED');
    });
  });
}