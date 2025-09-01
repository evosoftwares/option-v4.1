import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:option/screens/auth/register_screen.dart';

void main() {
  testWidgets('Debug validation test', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterScreen(),
      ),
    );

    // Verificar se os campos estão presentes
    expect(find.byType(TextFormField), findsNWidgets(4));
    
    // Tentar submeter formulário vazio
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();
    
    // Debug: imprimir todos os textos encontrados
    final textWidgets = find.byType(Text);
    for (int i = 0; i < textWidgets.evaluate().length; i++) {
      final widget = textWidgets.evaluate().elementAt(i).widget as Text;
      print('Text widget $i: "${widget.data}"');
    }
    
    // Verificar se alguma mensagem de erro aparece
    expect(find.textContaining('Informe'), findsAtLeastNWidgets(1));
  });
}