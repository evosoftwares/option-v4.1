import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:option/screens/auth/register_screen.dart';

void main() {
  testWidgets('Debug form validation step by step', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterScreen(),
      ),
    );

    print('=== STEP 1: Initial state ===');
    // Verificar se os campos estão presentes
    final nameField = find.byType(TextFormField).at(0);
    final emailField = find.byType(TextFormField).at(1);
    final passwordField = find.byType(TextFormField).at(2);
    final confirmPasswordField = find.byType(TextFormField).at(3);
    final submitButton = find.text('Cadastrar');
    
    expect(nameField, findsOneWidget);
    expect(emailField, findsOneWidget);
    expect(passwordField, findsOneWidget);
    expect(confirmPasswordField, findsOneWidget);
    expect(submitButton, findsOneWidget);
    print('✓ All form fields found');

    print('=== STEP 2: Before submission ===');
    // Verificar se não há mensagens de erro antes da submissão
    expect(find.text('Informe seu nome'), findsNothing);
    expect(find.text('Informe seu e-mail'), findsNothing);
    expect(find.text('Informe sua senha'), findsNothing);
    expect(find.text('Confirme sua senha'), findsNothing);
    print('✓ No error messages before submission');

    print('=== STEP 3: Submit empty form ===');
    // Fazer scroll para garantir que o botão esteja visível
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    
    // Tentar submeter o formulário vazio
    await tester.tap(submitButton, warnIfMissed: false);
    print('✓ Tapped submit button');
    
    // Aguardar todas as animações e rebuilds
    await tester.pumpAndSettle();
    print('✓ Pumped and settled');

    print('=== STEP 4: Check for error messages ===');
    // Verificar se as mensagens de erro aparecem
    final nameError = find.text('Informe seu nome');
    final emailError = find.text('Informe seu e-mail');
    final passwordError = find.text('Informe sua senha');
    final confirmPasswordError = find.text('Confirme sua senha');
    
    print('Name error found: ${nameError.evaluate().isNotEmpty}');
    print('Email error found: ${emailError.evaluate().isNotEmpty}');
    print('Password error found: ${passwordError.evaluate().isNotEmpty}');
    print('Confirm password error found: ${confirmPasswordError.evaluate().isNotEmpty}');

    print('=== STEP 5: Debug all text widgets ===');
    // Listar todos os textos na tela para debug
    final allTexts = find.byType(Text);
    final textWidgets = allTexts.evaluate().map((element) {
      final widget = element.widget as Text;
      return widget.data ?? widget.textSpan?.toPlainText() ?? 'null';
    }).toList();
    
    print('All texts found:');
    for (int i = 0; i < textWidgets.length; i++) {
      print('  [$i]: "${textWidgets[i]}"');
    }

    print('=== STEP 6: Check Form validation state ===');
    // Verificar se o Form está sendo validado
    final formFinder = find.byType(Form);
    expect(formFinder, findsOneWidget);
    
    final formWidget = tester.widget<Form>(formFinder);
    final formKey = formWidget.key as GlobalKey<FormState>?;
    
    if (formKey != null) {
      final formState = formKey.currentState;
      if (formState != null) {
        final isValid = formState.validate();
        print('Form validation result: $isValid');
      } else {
        print('FormState is null');
      }
    } else {
      print('FormKey is null');
    }

    print('=== STEP 7: Final assertions ===');
    // Verificar se pelo menos uma mensagem de erro aparece
    final hasAnyError = nameError.evaluate().isNotEmpty ||
                       emailError.evaluate().isNotEmpty ||
                       passwordError.evaluate().isNotEmpty ||
                       confirmPasswordError.evaluate().isNotEmpty;
    
    print('Has any error message: $hasAnyError');
    
    // O teste deve falhar se não houver mensagens de erro
    expect(hasAnyError, isTrue, reason: 'Expected at least one validation error message to appear');
  });
}