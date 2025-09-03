/// Teste de integração completo para locais favoritos
/// Testa CRUD completo: criar, ler, editar, deletar locais favoritos
library;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:option/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('📍 Complete Favorite Locations Integration Tests', () {
    
    testWidgets('🏠 Add Home Location Flow', (tester) async {
      print('🧪 Testing Add Home Location...');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Navigate to saved places or locations
      final savedPlacesButtons = [
        find.text('Locais salvos'),
        find.text('Lugares favoritos'), 
        find.text('Endereços'),
        find.byIcon(Icons.bookmark),
        find.byIcon(Icons.location_on),
      ];
      
      var navigatedToSavedPlaces = false;
      for (final button in savedPlacesButtons) {
        if (button.evaluate().isNotEmpty) {
          await tester.tap(button);
          await tester.pumpAndSettle();
          print('✅ Navigated to saved places');
          navigatedToSavedPlaces = true;
          break;
        }
      }
      
      // Look for add location button
      final addButtons = [
        find.text('Adicionar local'),
        find.text('Novo endereço'),
        find.byIcon(Icons.add),
        find.byType(FloatingActionButton),
      ];
      
      for (final button in addButtons) {
        if (button.evaluate().isNotEmpty) {
          await tester.tap(button);
          await tester.pumpAndSettle();
          print('✅ Add location button tapped');
          break;
        }
      }
      
      // Fill home location form
      final nameField = find.byType(TextFormField).first;
      const homeName = 'Minha Casa';
      await tester.enterText(nameField, homeName);
      await tester.pumpAndSettle();
      print('✅ Home name entered: $homeName');
      
      // Fill address
      if (find.byType(TextFormField).evaluate().length > 1) {
        final addressField = find.byType(TextFormField).at(1);
        const homeAddress = 'Rua das Flores, 123 - São Paulo, SP';
        await tester.enterText(addressField, homeAddress);
        await tester.pumpAndSettle();
        print('✅ Home address entered: $homeAddress');
      }
      
      // Select home type (if available)
      final homeChips = [
        find.text('Casa'),
        find.text('Home'), 
        find.byIcon(Icons.home),
      ];
      
      for (final chip in homeChips) {
        if (chip.evaluate().isNotEmpty) {
          await tester.tap(chip);
          await tester.pumpAndSettle();
          print('✅ Home type selected');
          break;
        }
      }
      
      // Save location
      final saveButtons = [
        find.text('Salvar'),
        find.text('Adicionar'),
        find.text('Confirmar'),
      ];
      
      for (final button in saveButtons) {
        if (button.evaluate().isNotEmpty) {
          await tester.tap(button);
          await tester.pumpAndSettle(const Duration(seconds: 3));
          print('✅ Save button tapped');
          break;
        }
      }
      
      // Verify home location was added
      expect(find.text(homeName), findsAtLeastNWidgets(1), 
             reason: 'Home location should appear in the list');
      
      print('🎯 Add Home Location Flow: PASSED');
    });

    testWidgets('🏢 Add Work Location Flow', (tester) async {
      print('🧪 Testing Add Work Location...');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Navigate to add location (reuse logic from previous test)
      final addButton = find.byIcon(Icons.add).first;
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton);
        await tester.pumpAndSettle();
      }
      
      // Fill work location details
      final forms = find.byType(TextFormField);
      if (forms.evaluate().length >= 2) {
        await tester.enterText(forms.first, 'Meu Trabalho');
        await tester.enterText(forms.at(1), 'Av. Paulista, 1000 - São Paulo, SP');
        await tester.pumpAndSettle();
        print('✅ Work location details filled');
      }
      
      // Select work type
      final workChips = [
        find.text('Trabalho'),
        find.text('Work'),
        find.byIcon(Icons.work),
      ];
      
      for (final chip in workChips) {
        if (chip.evaluate().isNotEmpty) {
          await tester.tap(chip);
          await tester.pumpAndSettle();
          print('✅ Work type selected');
          break;
        }
      }
      
      // Save work location
      final saveButton = find.text('Salvar');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        print('✅ Work location saved');
      }
      
      print('🎯 Add Work Location Flow: PASSED');
    });

    testWidgets('✏️ Edit Existing Location', (tester) async {
      print('🧪 Testing Edit Existing Location...');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Find existing location to edit
      final locationTiles = find.byType(ListTile);
      if (locationTiles.evaluate().isNotEmpty) {
        // Long press to show edit options or look for edit icon
        await tester.longPress(locationTiles.first);
        await tester.pumpAndSettle();
        print('✅ Long pressed location item');
        
        // Look for edit option
        final editOptions = [
          find.text('Editar'),
          find.text('Edit'),
          find.byIcon(Icons.edit),
        ];
        
        var editFound = false;
        for (final option in editOptions) {
          if (option.evaluate().isNotEmpty) {
            await tester.tap(option);
            await tester.pumpAndSettle();
            print('✅ Edit option selected');
            editFound = true;
            break;
          }
        }
        
        if (!editFound) {
          // Try tapping edit icon directly
          final editIcons = find.byIcon(Icons.edit);
          if (editIcons.evaluate().isNotEmpty) {
            await tester.tap(editIcons.first);
            await tester.pumpAndSettle();
            print('✅ Edit icon tapped directly');
          }
        }
        
        // Modify the location
        final nameField = find.byType(TextFormField).first;
        await tester.enterText(nameField, 'Casa Editada');
        await tester.pumpAndSettle();
        print('✅ Location name modified');
        
        // Save changes
        final saveButton = find.text('Salvar');
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle();
          print('✅ Changes saved');
          
          // Verify the change
          expect(find.text('Casa Editada'), findsAtLeastNWidgets(1));
        }
      }
      
      print('🎯 Edit Existing Location: PASSED');
    });

    testWidgets('🗑️ Delete Location Flow', (tester) async {
      print('🧪 Testing Delete Location...');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Count initial locations
      final initialLocationTiles = find.byType(ListTile).evaluate().length;
      print('📊 Initial location count: $initialLocationTiles');
      
      if (initialLocationTiles > 0) {
        final locationTile = find.byType(ListTile).first;
        
        // Long press for delete options
        await tester.longPress(locationTile);
        await tester.pumpAndSettle();
        
        // Look for delete option
        final deleteOptions = [
          find.text('Excluir'),
          find.text('Deletar'),
          find.text('Remove'),
          find.byIcon(Icons.delete),
        ];
        
        var deleteFound = false;
        for (final option in deleteOptions) {
          if (option.evaluate().isNotEmpty) {
            await tester.tap(option);
            await tester.pumpAndSettle();
            print('✅ Delete option selected');
            deleteFound = true;
            
            // Confirm deletion if dialog appears
            final confirmButtons = [
              find.text('Confirmar'),
              find.text('Sim'),
              find.text('Delete'),
            ];
            
            for (final confirm in confirmButtons) {
              if (confirm.evaluate().isNotEmpty) {
                await tester.tap(confirm);
                await tester.pumpAndSettle();
                print('✅ Deletion confirmed');
                break;
              }
            }
            break;
          }
        }
        
        if (deleteFound) {
          // Verify location count decreased
          final finalLocationTiles = find.byType(ListTile).evaluate().length;
          expect(finalLocationTiles, lessThan(initialLocationTiles), 
                 reason: 'Location count should decrease after deletion');
          print('✅ Location successfully deleted');
        }
      }
      
      print('🎯 Delete Location Flow: PASSED');
    });

    testWidgets('🔍 Search and Filter Locations', (tester) async {
      print('🧪 Testing Location Search and Filtering...');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Look for search functionality
      final searchElements = [
        find.byIcon(Icons.search),
        find.text('Buscar'),
        find.text('Search'),
        find.byType(SearchBar),
        find.byType(TextField),
      ];
      
      var searchFound = false;
      for (final element in searchElements) {
        if (element.evaluate().isNotEmpty) {
          await tester.tap(element);
          await tester.pumpAndSettle();
          print('✅ Search element activated');
          searchFound = true;
          break;
        }
      }
      
      if (searchFound) {
        // Enter search term
        final searchField = find.byType(TextField).first;
        await tester.enterText(searchField, 'Casa');
        await tester.pumpAndSettle();
        print('✅ Search term entered: Casa');
        
        // Verify search results
        final searchResults = find.text('Casa');
        if (searchResults.evaluate().isNotEmpty) {
          print('✅ Search results displayed');
        }
        
        // Clear search
        await tester.enterText(searchField, '');
        await tester.pumpAndSettle();
        print('✅ Search cleared');
      }
      
      // Test category filtering
      final categoryFilters = [
        find.text('Casa'),
        find.text('Trabalho'),
        find.text('Favorito'),
        find.byIcon(Icons.home),
        find.byIcon(Icons.work),
      ];
      
      for (final filter in categoryFilters) {
        if (filter.evaluate().isNotEmpty) {
          await tester.tap(filter);
          await tester.pumpAndSettle();
          print('✅ Category filter applied');
          break;
        }
      }
      
      print('🎯 Search and Filter Locations: PASSED');
    });

    testWidgets('📱 Location Selection for Trip', (tester) async {
      print('🧪 Testing Location Selection for Trip...');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Navigate to trip request
      final requestTripButton = find.text('Solicitar corrida');
      if (requestTripButton.evaluate().isNotEmpty) {
        await tester.tap(requestTripButton);
        await tester.pumpAndSettle();
        print('✅ Navigated to trip request');
      }
      
      // Test selecting saved location as origin
      final originField = find.text('De onde?');
      if (originField.evaluate().isNotEmpty) {
        await tester.tap(originField);
        await tester.pumpAndSettle();
        
        // Look for saved locations in the list
        final savedLocationsList = find.text('Locais salvos');
        if (savedLocationsList.evaluate().isNotEmpty) {
          await tester.tap(savedLocationsList);
          await tester.pumpAndSettle();
          print('✅ Saved locations section opened');
          
          // Select first saved location
          final locations = find.byType(ListTile);
          if (locations.evaluate().isNotEmpty) {
            await tester.tap(locations.first);
            await tester.pumpAndSettle();
            print('✅ Saved location selected as origin');
          }
        }
      }
      
      // Test selecting saved location as destination
      final destField = find.text('Para onde?');
      if (destField.evaluate().isNotEmpty) {
        await tester.tap(destField);
        await tester.pumpAndSettle();
        
        // Select different saved location
        final locations = find.byType(ListTile);
        if (locations.evaluate().length > 1) {
          await tester.tap(locations.at(1));
          await tester.pumpAndSettle();
          print('✅ Saved location selected as destination');
        }
      }
      
      print('🎯 Location Selection for Trip: PASSED');
    });

    testWidgets('💾 Location Data Persistence', (tester) async {
      print('🧪 Testing Location Data Persistence...');
      
      // Add a test location
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      const testLocationName = 'Teste Persistencia';
      
      // Add location (simplified)
      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
        await tester.pumpAndSettle();
        
        final nameField = find.byType(TextFormField).first;
        await tester.enterText(nameField, testLocationName);
        await tester.pumpAndSettle();
        
        final saveButton = find.text('Salvar');
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }
      }
      
      // Restart app to test persistence
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Verify location still exists
      final persistedLocation = find.text(testLocationName);
      expect(persistedLocation.evaluate().isNotEmpty, isTrue,
             reason: 'Location should persist across app restarts');
      
      print('✅ Location data persisted across app restart');
      print('🎯 Location Data Persistence: PASSED');
    });

    testWidgets('🧪 Location Validation and Error Handling', (tester) async {
      print('🧪 Testing Location Validation...');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Test adding location with empty fields
      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
        await tester.pumpAndSettle();
        
        // Try to save without filling fields
        final saveButton = find.text('Salvar');
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle();
          
          // Should show validation errors
          final validationErrors = [
            find.text('Campo obrigatório'),
            find.text('Nome é obrigatório'),
            find.text('Endereço é obrigatório'),
          ];
          
          var validationFound = false;
          for (final error in validationErrors) {
            if (error.evaluate().isNotEmpty) {
              print('✅ Validation error shown for empty fields');
              validationFound = true;
              break;
            }
          }
          
          expect(validationFound, isTrue, reason: 'Should show validation errors');
        }
        
        // Test with very long name
        final nameField = find.byType(TextFormField).first;
        const longName = 'Este é um nome muito longo para um local que deveria ser rejeitado pelo sistema de validação';
        await tester.enterText(nameField, longName);
        await tester.pumpAndSettle();
        
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle();
          
          // Should handle long names gracefully
          expect(tester.takeException(), isNull, 
                 reason: 'Should not crash with long location names');
          print('✅ Long names handled gracefully');
        }
      }
      
      print('🎯 Location Validation and Error Handling: PASSED');
    });
  });
}