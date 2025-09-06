import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:option/screens/profile/profile_edit_screen.dart';

void main() {
  testWidgets('Debug Profile Edit Screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const ProfileEditScreen(),
        routes: {
          '/login': (context) => const Scaffold(body: Text('Login')),
        },
      ),
    );

    // Let's see what's actually rendered
    await tester.pumpAndSettle();
    
    // Print all text widgets found
    final allTexts = find.byType(Text);
    print('=== All Text Widgets Found (${allTexts.evaluate().length}) ===');
    for (var i = 0; i < allTexts.evaluate().length; i++) {
      final textWidget = tester.widget<Text>(allTexts.at(i));
      print('Text $i: "${textWidget.data}"');
    }
    
    // Check for specific widgets
    print('\n=== Specific Widgets Search ===');
    print('ChoiceChip count: ${find.byType(ChoiceChip).evaluate().length}');
    print('FilledButton count: ${find.byType(FilledButton).evaluate().length}');
    print('ListView count: ${find.byType(ListView).evaluate().length}');
    print('Wrap count: ${find.byType(Wrap).evaluate().length}');
    
    // Try to find text in choice chips
    final passageiroText = find.text('Passageiro');
    final motoristaText = find.text('Motorista');
    final salvarText = find.text('Salvar alterações');
    
    print('Passageiro found: ${passageiroText.evaluate().length}');
    print('Motorista found: ${motoristaText.evaluate().length}'); 
    print('Salvar alterações found: ${salvarText.evaluate().length}');
    
    // Try scrolling to see if there are more elements
    final listView = find.byType(ListView);
    if (listView.evaluate().isNotEmpty) {
      print('Trying to scroll down to reveal more content...');
      await tester.drag(listView, const Offset(0, -300));
      await tester.pumpAndSettle();
      
      // Check again after scrolling
      print('\nAfter scrolling:');
      print('ChoiceChip count: ${find.byType(ChoiceChip).evaluate().length}');
      print('FilledButton count: ${find.byType(FilledButton).evaluate().length}');
      print('Wrap count: ${find.byType(Wrap).evaluate().length}');
      print('Passageiro found: ${find.text('Passageiro').evaluate().length}');
      print('Salvar alterações found: ${find.text('Salvar alterações').evaluate().length}');
      
      // Print new texts found after scrolling
      final allTextsAfter = find.byType(Text);
      print('\n=== All Text Widgets After Scrolling (${allTextsAfter.evaluate().length}) ===');
      for (var i = 0; i < allTextsAfter.evaluate().length; i++) {
        final textWidget = tester.widget<Text>(allTextsAfter.at(i));
        print('Text $i: "${textWidget.data}"');
      }
    }
    
    // Print all widgets in the tree
    print('\n=== Widget Tree ===');
    debugDumpApp();
    
    expect(find.text('Editar perfil'), findsOneWidget);
  });
}