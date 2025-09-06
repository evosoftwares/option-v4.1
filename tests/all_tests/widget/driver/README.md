# Driver Excluded Zones Tests

This directory contains tests for the driver excluded zones functionality.

## Test Structure

- `driver_excluded_zones_screen_test.dart` - Widget tests for the UI
- `driver_excluded_zones_screen_test.mocks.dart` - Generated mocks (created by build_runner)

## Running Tests

### Unit Tests

```bash
flutter test tests/all_tests/widget/driver/driver_excluded_zones_screen_test.dart
flutter test tests/all_tests/unit/services/secure_driver_excluded_zones_service_test.dart
flutter test tests/all_tests/unit/services/driver_excluded_zones_service_test.dart
```

### Integration Tests

```bash
flutter test tests/all_tests/integration/services/driver_excluded_zones_integration_test.dart
```

## Generating Mocks

The tests use Mockito for mocking dependencies. To generate mock files:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Or use the provided script:

```bash
./generate_mocks.sh
```

## Test Coverage

The tests cover:

1. **UI Display**
   - Loading indicators
   - Empty state display
   - Zone list display
   - Error message display

2. **Functionality**
   - Adding excluded zones
   - Removing excluded zones
   - Zone validation
   - Address parsing

3. **Error Handling**
   - Network errors
   - Validation errors
   - Database constraint violations
   - Missing driver scenarios

4. **Service Layer**
   - Driver existence validation
   - Zone duplicate prevention
   - Foreign key constraint handling
   - Multiple zone operations