import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../lib/models/passenger_wallet.dart';
import '../../../lib/models/driver_wallet.dart';
import '../../../lib/models/wallet_transaction.dart';
import '../../../lib/services/wallet_logger.dart';

void main() {
  group('Wallet Extensions', () {
    group('PassengerWallet', () {
      test('should log wallet info', () async {
        // Arrange
        final wallet = PassengerWallet(
          id: 'wallet-123',
          passengerId: 'passenger-123',
          userId: 'user-123',
          availableBalance: 100.0,
          pendingBalance: 0.0,
          totalSpent: 50.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act & Assert
        expect(() => wallet.logWalletInfo(), returnsNormally);
      });
    });

    group('DriverWallet', () {
      test('should log wallet info', () async {
        // Arrange
        final wallet = DriverWallet(
          id: 'wallet-123',
          driverId: 'driver-123',
          availableBalance: 200.0,
          pendingBalance: 50.0,
          totalEarned: 500.0,
          totalWithdrawn: 100.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act & Assert
        expect(() => wallet.logWalletInfo(), returnsNormally);
      });
    });

    group('WalletTransaction', () {
      test('should log transaction info', () async {
        // Arrange
        final transaction = WalletTransaction(
          id: 'txn-123',
          walletId: 'wallet-123',
          type: WalletTransactionType.credit,
          amount: 50.0,
          description: 'Credit added',
          status: WalletTransactionStatus.completed,
          createdAt: DateTime.now(),
        );

        // Act & Assert
        expect(() => transaction.logTransaction(), returnsNormally);
      });
    });
  });
}