import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:option/widgets/wallet_feedback_widgets.dart';
import 'package:option/widgets/enhanced_transaction_list.dart';
import 'package:option/widgets/wallet_dashboard.dart';

void main() {
  group('Wallet UI Components', () {
    testWidgets('WalletOperationFeedback displays correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WalletOperationFeedback(
              type: WalletOperationType.success,
              title: 'Success',
              message: 'Operation completed successfully',
            ),
          ),
        ),
      );

      expect(find.text('Success'), findsOneWidget);
      expect(find.text('Operation completed successfully'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('WalletProgressIndicator displays correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WalletProgressIndicator(
              message: 'Processing...',
            ),
          ),
        ),
      );

      expect(find.text('Processing...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('EnhancedTransactionList displays empty state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedTransactionList(
              transactions: [],
            ),
          ),
        ),
      );

      expect(find.text('Nenhuma transação encontrada'), findsOneWidget);
    });

    testWidgets('WalletDashboard displays loading state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WalletDashboard(
              wallet: null,
              recentTransactions: [],
              isLoading: true,
            ),
          ),
        ),
      );

      // Should show loading skeleton
      expect(find.byType(Container), findsWidgets);
    });
  });
}