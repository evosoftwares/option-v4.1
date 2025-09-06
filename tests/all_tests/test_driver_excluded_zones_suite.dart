import 'package:flutter_test/flutter_test.dart';

// Import all driver excluded zones tests
import 'widget/driver/driver_excluded_zones_screen_test.dart' as screen_test;
import 'unit/services/secure_driver_excluded_zones_service_test.dart' as secure_service_test;
import 'unit/services/driver_excluded_zones_service_test.dart' as service_test;
import 'unit/models/driver_excluded_zone_test.dart' as model_test;
import 'unit/services/zone_validation_service_test.dart' as validation_test;

void main() {
  group('Driver Excluded Zones Test Suite', () {
    // Run all tests in sequence
    screen_test.main();
    secure_service_test.main();
    service_test.main();
    model_test.main();
    validation_test.main();
  });
}