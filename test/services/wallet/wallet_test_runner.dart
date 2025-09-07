import 'package:flutter_test/flutter_test.dart';
import 'wallet_logger_test.dart' as wallet_logger_test;
import 'passenger_wallet_service_test.dart' as passenger_wallet_service_test;
import 'driver_wallet_service_test.dart' as driver_wallet_service_test;

void main() {
  group('Wallet Tests', () {
    group('Wallet Logger Tests', wallet_logger_test.main);
    group('Passenger Wallet Service Tests', passenger_wallet_service_test.main);
    group('Driver Wallet Service Tests', driver_wallet_service_test.main);
  });
}