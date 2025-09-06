import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/screens/notifications/notifications_screen.dart';

void main() {
  group('Teste da Tela de Notificações', () {
    test('Deve instanciar NotificationsScreen sem erros', () {
      // Arrange & Act
      NotificationsScreen? screen;
      
      expect(() {
        screen = const NotificationsScreen();
      }, returnsNormally);
      
      // Assert
      expect(screen, isNotNull);
      expect(screen, isA<NotificationsScreen>());
      print('✅ NotificationsScreen instanciada sem erros');
    });

    test('Deve verificar tipo da tela', () {
      // Arrange & Act
      const screen = NotificationsScreen();
      
      // Assert
      expect(screen, isA<StatefulWidget>());
      expect(screen.runtimeType.toString(), equals('NotificationsScreen'));
      print('✅ Tipo da tela verificado corretamente');
    });

    test('Deve ter key opcional', () {
      // Arrange & Act
      const screenWithoutKey = NotificationsScreen();
      const screenWithKey = NotificationsScreen(key: ValueKey('test'));
      
      // Assert
      expect(screenWithoutKey.key, isNull);
      expect(screenWithKey.key, isNotNull);
      expect(screenWithKey.key, isA<ValueKey<String>>());
      print('✅ Key opcional funciona corretamente');
    });
  });

  // Teste adicional para verificar propriedades da tela
  group('Propriedades da Tela de Notificações', () {
    test('Deve ter método createState disponível', () {
      // Arrange
      const screen = NotificationsScreen();
      
      // Act & Assert
      expect(screen.createState, isA<Function>());
      print('✅ Método createState está disponível');
    });

    test('Deve ser uma tela válida do Flutter', () {
      // Arrange
      const screen = NotificationsScreen();
      
      // Act & Assert
      expect(screen, isA<Widget>());
      expect(screen, isA<StatefulWidget>());
      expect(screen.toString(), contains('NotificationsScreen'));
      print('✅ Tela é um widget válido do Flutter');
    });
  });
}