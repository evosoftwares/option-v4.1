import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:option/screens/auth/register_screen.dart';

void main() {
  testWidgets('Debug email validation message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterScreen(),
      ),
    );

    print('=== STEP 1: Enter invalid email ===');
    await tester.enterText(find.byType(TextFormField).at(1), 'invalid-email');
    
    print('=== STEP 2: Submit form ===');
    await tester.ensureVisible(find.text('Cadastrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cadastrar'), warnIfMissed: false);
    await tester.pumpAndSettle();
    
    print('=== STEP 3: Check all text widgets ===');
    final allTexts = find.byType(Text);
    final textWidgets = tester.widgetList<Text>(allTexts);
    
    print('All texts found:');
    for (int i = 0; i < textWidgets.length; i++) {
      final text = textWidgets.elementAt(i).data ?? '';
      print('  [$i]: "$text"');
    }
    
    print('=== STEP 4: Look for email error messages ===');
    final emailErrorMessages = [
      'E-mail inválido. Use o formato: exemplo@email.com',
      'Digite um e-mail válido',
      'Email inválido',
      'Informe um e-mail válido',
    ];
    
    for (final message in emailErrorMessages) {
      final found = find.text(message);
      print('Looking for: "$message" - Found: ${found.evaluate().length}');
    }
  });
}