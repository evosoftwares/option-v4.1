# Wallet Tests

This directory contains unit tests for the wallet functionality of the OPTION application.

## Structure

- `wallet_logger_test.dart` - Tests for wallet logging functionality
- `wallet_extensions_test.dart` - Tests for wallet model extensions
- `passenger_wallet_service_test.dart` - Tests for passenger wallet operations (simplified)
- `driver_wallet_service_test.dart` - Tests for driver wallet operations (simplified)

## Running Tests

To run all wallet tests:

```bash
flutter test test/services/wallet/
```

To run individual test files:

```bash
flutter test test/services/wallet/wallet_logger_test.dart
flutter test test/services/wallet/wallet_extensions_test.dart
flutter test test/services/wallet/passenger_wallet_service_test.dart
flutter test test/services/wallet/driver_wallet_service_test.dart
```

## Test Coverage

The tests cover the following functionality:

### Wallet Logger
- Logging passenger credit additions
- Logging passenger debits
- Logging driver earnings
- Logging withdrawal requests
- Logging processed withdrawals
- Logging balance checks
- Logging blocked withdrawals
- Logging suspicious activity

### Wallet Extensions
- Logging passenger wallet information
- Logging driver wallet information
- Logging wallet transaction information

### Wallet Services
- Error handling for database operations

## Implementation Notes

Due to complexity with mocking the Supabase client and PostgREST types, the wallet service tests are simplified to focus on error handling rather than full functionality testing. The main focus of this implementation is on the logging functionality, which is fully tested.

## Mocking

The tests use `mocktail` to mock dependencies where possible. Each test file includes the necessary mock classes.