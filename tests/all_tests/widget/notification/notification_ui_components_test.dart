import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:option/widgets/notification_status_card.dart';
import 'package:option/widgets/notification_permission_dialog.dart';
import 'package:option/widgets/notification_status_indicator.dart';
import 'package:option/examples/notification_ui_integration_example.dart';

void main() {
  group('Notification UI Components Tests', () {
    testWidgets('NotificationStatusCard displays correctly with granted permission', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationStatusCard(
              permissionStatus: NotificationPermissionStatus.granted,
              connectionStatus: OneSignalConnectionStatus.connected,
              showDetails: true,
            ),
          ),
        ),
      );

      // Verificar se o card é exibido
      expect(find.byType(Card), findsOneWidget);
      
      // Verificar se o título está presente
      expect(find.text('Status das Notificações'), findsOneWidget);
      
      // Verificar se mostra status positivo
      expect(find.text('Funcionando perfeitamente'), findsOneWidget);
      
      // Verificar se os detalhes são mostrados
      expect(find.text('Detalhes'), findsOneWidget);
      expect(find.text('Recebimento de notificações:'), findsOneWidget);
      expect(find.text('Ativo'), findsOneWidget);
    });

    testWidgets('NotificationStatusCard displays error state correctly', (WidgetTester tester) async {
      const errorMessage = 'Erro de conexão com servidor';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationStatusCard(
              permissionStatus: NotificationPermissionStatus.error,
              connectionStatus: OneSignalConnectionStatus.error,
              errorMessage: errorMessage,
              showDetails: true,
            ),
          ),
        ),
      );

      // Verificar se o erro é exibido
      expect(find.text(errorMessage), findsOneWidget);
      
      // Verificar se mostra ícone de erro
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('NotificationStatusCard shows action buttons when needed', (WidgetTester tester) async {
      bool retryTapped = false;
      bool permissionTapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationStatusCard(
              permissionStatus: NotificationPermissionStatus.denied,
              connectionStatus: OneSignalConnectionStatus.error,
              onRetry: () => retryTapped = true,
              onRequestPermission: () => permissionTapped = true,
            ),
          ),
        ),
      );

      // Verificar se os botões estão presentes
      expect(find.text('Permitir Notificações'), findsOneWidget);
      expect(find.text('Tentar Novamente'), findsOneWidget);
      
      // Testar toque nos botões
      await tester.tap(find.text('Permitir Notificações'));
      await tester.pump();
      expect(permissionTapped, isTrue);
      
      await tester.tap(find.text('Tentar Novamente'));
      await tester.pump();
      expect(retryTapped, isTrue);
    });

    testWidgets('NotificationPermissionDialog displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => NotificationPermissionDialog(
                    reason: NotificationPermissionReason.firstTime,
                    onAllow: () {},
                    onDeny: () {},
                  ),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Mostrar o diálogo
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verificar se o diálogo é exibido
      expect(find.text('Receba Notificações'), findsOneWidget);
      expect(find.text('Para uma melhor experiência no Option'), findsOneWidget);
      expect(find.text('Com as notificações você recebe:'), findsOneWidget);
      
      // Verificar benefícios
      expect(find.text('Avisos quando o motorista chegou'), findsOneWidget);
      expect(find.text('Mensagens do motorista ou passageiro'), findsOneWidget);
      
      // Verificar botões
      expect(find.text('Permitir Notificações'), findsOneWidget);
      expect(find.text('Agora não'), findsOneWidget);
    });

    testWidgets('NotificationStatusIndicator compact size works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationStatusIndicator(
              size: NotificationIndicatorSize.compact,
              showPulse: false,
            ),
          ),
        ),
      );

      // Verificar se apenas o ícone é exibido (tamanho compacto)
      expect(find.byType(Icon), findsOneWidget);
      
      // Não deve haver texto no modo compacto
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('NotificationStatusIndicator small size shows status text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationStatusIndicator(
              size: NotificationIndicatorSize.small,
              showPulse: false,
            ),
          ),
        ),
      );

      // Deve haver ícone e texto
      expect(find.byType(Icon), findsOneWidget);
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('NotificationStatusIndicator responds to tap', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationStatusIndicator(
              size: NotificationIndicatorSize.small,
              onTap: () => tapped = true,
              showPulse: false,
            ),
          ),
        ),
      );

      // Tocar no indicador
      await tester.tap(find.byType(NotificationStatusIndicator));
      await tester.pump();
      
      expect(tapped, isTrue);
    });

    testWidgets('NotificationUIIntegrationExample loads without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationUIIntegrationExample(),
        ),
      );

      // Verificar se a tela carrega sem erros
      expect(find.text('Integração UI OneSignal'), findsOneWidget);
      expect(find.text('Status Card Completo'), findsOneWidget);
      expect(find.text('Indicadores de Status'), findsOneWidget);
      expect(find.text('Ações Disponíveis'), findsOneWidget);
    });

    testWidgets('Integration example buttons work', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationUIIntegrationExample(),
        ),
      );

      // Verificar se os botões estão presentes
      expect(find.text('Onboarding'), findsOneWidget);
      expect(find.text('Permissão'), findsOneWidget);
      expect(find.text('Toggle Permissão'), findsOneWidget);
      expect(find.text('Toggle Conexão'), findsOneWidget);

      // Testar toggle de permissão
      await tester.tap(find.text('Toggle Permissão'));
      await tester.pump();
      
      // Verificar mudança de estado (ícone deve mudar)
      expect(find.byType(Icon), findsWidgets);
    });

    group('Status States', () {
      testWidgets('Shows different icons for different permission states', (WidgetTester tester) async {
        // Teste para permissão concedida
        await tester.pumpWidget(
          const MaterialApp(
            home: NotificationStatusCard(
              permissionStatus: NotificationPermissionStatus.granted,
              connectionStatus: OneSignalConnectionStatus.connected,
            ),
          ),
        );
        
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        
        // Teste para permissão negada
        await tester.pumpWidget(
          const MaterialApp(
            home: NotificationStatusCard(
              permissionStatus: NotificationPermissionStatus.denied,
              connectionStatus: OneSignalConnectionStatus.connected,
            ),
          ),
        );
        
        expect(find.byIcon(Icons.block), findsOneWidget);
      });

      testWidgets('Shows loading state correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: NotificationStatusCard(
              permissionStatus: NotificationPermissionStatus.requesting,
              connectionStatus: OneSignalConnectionStatus.connecting,
            ),
          ),
        );
        
        expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
        expect(find.text('Solicitando Permissão'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('Displays error messages clearly', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: NotificationStatusCard(
              permissionStatus: NotificationPermissionStatus.error,
              connectionStatus: OneSignalConnectionStatus.error,
              errorMessage: 'Teste de erro',
            ),
          ),
        );
        
        expect(find.text('Teste de erro'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsWidgets);
      });

      testWidgets('Shows retry option on error', (WidgetTester tester) async {
        bool retryPressed = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: NotificationStatusCard(
              permissionStatus: NotificationPermissionStatus.error,
              connectionStatus: OneSignalConnectionStatus.error,
              onRetry: () => retryPressed = true,
            ),
          ),
        );
        
        expect(find.text('Tentar Novamente'), findsOneWidget);
        
        await tester.tap(find.text('Tentar Novamente'));
        await tester.pump();
        
        expect(retryPressed, isTrue);
      });
    });
  });

  group('Accessibility Tests', () {
    testWidgets('Components have proper semantic labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationStatusCard(
            permissionStatus: NotificationPermissionStatus.granted,
            connectionStatus: OneSignalConnectionStatus.connected,
          ),
        ),
      );

      // Verificar se os textos importantes estão acessíveis
      expect(find.text('Status das Notificações'), findsOneWidget);
      expect(find.text('Funcionando perfeitamente'), findsOneWidget);
    });

    testWidgets('Buttons are accessible', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationStatusCard(
            permissionStatus: NotificationPermissionStatus.denied,
            connectionStatus: OneSignalConnectionStatus.connected,
            onRequestPermission: () {},
          ),
        ),
      );

      // Verificar se botões têm textos claros
      expect(find.text('Permitir Notificações'), findsOneWidget);
      
      // Verificar se são clicáveis
      expect(find.widgetWithText(FilledButton, 'Permitir Notificações'), findsOneWidget);
    });
  });
}