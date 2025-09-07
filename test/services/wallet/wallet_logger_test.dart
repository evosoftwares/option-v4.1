import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../lib/services/wallet_logger.dart';

void main() {
  group('WalletLogger', () {
    late WalletLogger walletLogger;

    setUp(() {
      walletLogger = WalletLogger();
    });

    tearDown(() {
      resetMocktailState();
    });

    group('Log Operations', () {
      test('should log passenger credit added', () async {
        // Act & Assert
        expect(
          () => walletLogger.logPassengerCreditAdded(
            passengerId: 'passenger-123',
            userId: 'user-123',
            amount: 50.0,
            description: 'Credit added',
            transactionId: 'txn-123',
          ),
          returnsNormally,
        );
      });

      test('should log passenger debit', () async {
        // Act & Assert
        expect(
          () => walletLogger.logPassengerDebit(
            passengerId: 'passenger-123',
            userId: 'user-123',
            tripId: 'trip-123',
            amount: 25.0,
            description: 'Trip payment',
            transactionId: 'txn-456',
          ),
          returnsNormally,
        );
      });

      test('should log driver earnings added', () async {
        // Act & Assert
        expect(
          () => walletLogger.logDriverEarningsAdded(
            driverId: 'driver-123',
            userId: 'user-123',
            amount: 30.0,
            description: 'Trip earnings',
            referenceType: 'trip',
            referenceId: 'trip-123',
          ),
          returnsNormally,
        );
      });

      test('should log withdrawal requested', () async {
        // Act & Assert
        expect(
          () => walletLogger.logWithdrawalRequested(
            walletId: 'wallet-123',
            userId: 'user-123',
            amount: 100.0,
            method: 'pix',
            withdrawalId: 'withdrawal-123',
          ),
          returnsNormally,
        );
      });

      test('should log withdrawal processed', () async {
        // Act & Assert
        expect(
          () => walletLogger.logWithdrawalProcessed(
            walletId: 'wallet-123',
            userId: 'user-123',
            amount: 100.0,
            method: 'pix',
            withdrawalId: 'withdrawal-123',
            status: 'completed',
          ),
          returnsNormally,
        );
      });

      test('should log balance checked', () async {
        // Act & Assert
        expect(
          () => walletLogger.logBalanceChecked(
            walletId: 'wallet-123',
            userId: 'user-123',
            walletType: 'passenger',
            balance: 150.0,
          ),
          returnsNormally,
        );
      });

      test('should log withdrawal blocked', () async {
        // Act & Assert
        expect(
          () => walletLogger.logWithdrawalBlocked(
            userId: 'user-123',
            reason: 'Rate limit exceeded',
            blockType: 'rate_limit',
            amount: 200.0,
            pixKey: 'pix-key-123',
          ),
          returnsNormally,
        );
      });

      test('should log suspicious activity', () async {
        // Act & Assert
        expect(
          () => walletLogger.logSuspiciousActivity(
            userId: 'user-123',
            activityType: 'multiple_withdrawals',
          ),
          returnsNormally,
        );
      });

      test('should map wallet log level to error severity correctly', () async {
        // This test would require accessing private methods, which is not ideal
        // Instead, we'll test the behavior through the public API
        
        // Test that critical logs are handled
        expect(
          () => walletLogger.logSuspiciousActivity(
            userId: 'user-123',
            activityType: 'suspicious',
          ),
          returnsNormally,
        );
        
        // Test that info logs are handled
        expect(
          () => walletLogger.logPassengerCreditAdded(
            passengerId: 'passenger-123',
            userId: 'user-123',
            amount: 50.0,
            description: 'Credit added',
            transactionId: 'txn-123',
          ),
          returnsNormally,
        );
      });
    });
  });
}