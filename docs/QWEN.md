# Qwen Code Customization

This file contains custom instructions for Qwen Code to tailor its interactions for this specific project.

## Project Overview

This is a Flutter project named 'option-v4.1'. It appears to be an application related to options trading, possibly with some Uber-like features based on the presence of 'uber_clone.iml'.

## Key Files and Directories

- `pubspec.yaml`: Defines project dependencies and metadata.
- `lib/`: Main source code directory (likely contains Dart files, though not listed in the current view).
- `assets/`: Likely contains images, fonts, and other static resources.
- `analysis_options.yaml`: Configures Dart analyzer settings.
- `README.md`: Main project documentation.
- `.gitignore`: Specifies files and directories to be ignored by Git.

## Preferred Tools and Commands

- **Flutter CLI**: Use `flutter` commands for building, testing, and managing the project.
- **Dart Analyzer**: Use `dart analyze` for static analysis.
- **Testing**: Refer to `TEST_INSTRUCTIONS.md` for project-specific testing guidelines.
- **Schema Extraction**: The script `extract_supabase_schema.sh` might be relevant for database schema management.

## Coding Style and Conventions

- Follow the style and conventions defined in `analysis_options.yaml`.
- Adhere to Flutter and Dart best practices.
- Ensure code is well-documented, especially public APIs.
- Maintain consistency with existing code in the project.

## Interaction Preferences

- Be concise and direct in responses.
- Prioritize safety and correctness in code modifications.
- Use absolute paths for file operations.
- Always verify changes with project-specific tools (e.g., `flutter analyze`, `flutter test`) before considering a task complete.
- When refactoring or modifying code, prefer making small, focused changes and verifying each step.
- If unsure about a request, ask clarifying questions before proceeding.

## Project Rules (Uber Clone)

### Development Guidelines

#### Testing and Mocking

##### ❌ What NOT to do
- **Never use mocks** (e.g., `mockito`, `mocktail`) to simulate behaviors
- **Do not create fake classes** that mimic Supabase behavior
- **Avoid stubs** that return hardcoded data

##### ✅ What TO do
- **Always use real Supabase** for integration tests

### Test Architecture

#### 1. Test Environment Setup

```yaml
# supabase/config.toml
[env.testing]
project_id = "uber-clone-testing"
api_url = "http://localhost:54321"
anon_key = "your-testing-anon-key"
```

#### 2. Recommended Test Structure

```
test/
├── integration/
│   ├── auth/
│   │   ├── login_test.dart
│   │   └── register_test.dart
│   └── services/
│       └── supabase_service_test.dart
├── fixtures/
│   └── test_data.dart
└── helpers/
    ├── supabase_test_helper.dart
    └── test_constants.dart
```

### Implementation with Supabase

#### Integration Test Example

```dart
// test/helpers/supabase_test_helper.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseTestHelper {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey: 'your-testing-anon-key',
    );
  }

  static Future<void> cleanDatabase() async {
    // Clean test tables
    await Supabase.instance.client
        .from('users')
        .delete()
        .neq('id', '00000000-0000-0000-0000-000000000000');
  }

  static Future<void> seedTestData() async {
    // Insert test data
    await Supabase.instance.client.from('users').insert([
      {
        'email': 'test@example.com',
        'name': 'Test User',
      }
    ]);
  }
}
```

#### Real Test Example

```dart
// test/integration/auth/login_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:uber_clone/services/auth_service.dart';
import '../helpers/supabase_test_helper.dart';

void main() {
  group('AuthService Integration Tests', () {
    late AuthService authService;

    setUpAll(() async {
      await SupabaseTestHelper.initialize();
    });

    setUp(() async {
      await SupabaseTestHelper.cleanDatabase();
      await SupabaseTestHelper.seedTestData();
      authService = AuthService();
    });

    test('should login with valid credentials', () async {
      // Act
      final result = await authService.login(
        email: 'test@example.com',
        password: 'password123',
      );

      // Assert
      expect(result, isNotNull);
      expect(result.user, isNotNull);
      expect(result.user!.email, equals('test@example.com'));
    });

    test('should throw exception with invalid credentials', () async {
      // Act & Assert
      expect(
        () => authService.login(
          email: 'wrong@example.com',
          password: 'wrongpassword',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
```

### Best Practices

#### 1. Environment Configuration
```dart
// lib/config/app_config.dart
class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://localhost:54321',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-local-anon-key',
  );
}
```

#### 2. Service Pattern
```dart
// lib/services/base_service.dart
abstract class BaseService {
  final SupabaseClient client;

  BaseService() : client = Supabase.instance.client;

  // Utility methods for error handling
  Future<T> handleError<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e.code);
    } on AuthException catch (e) {
      throw AuthException(e.message, e.statusCode);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
```

### Error Handling

#### 1. Custom Exceptions
```dart
// lib/exceptions/app_exceptions.dart
class DatabaseException implements Exception {
  final String message;
  final String? code;
  
  DatabaseException(this.message, [this.code]);
  
  @override
  String toString() => 'DatabaseException: $message${code != null ? ' (Code: $code)' : ''}';
}

class NetworkException implements Exception {
  final String message;
  
  NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}
```

#### 2. Error Handling in Tests
```dart
// test/integration/helpers/error_handler.dart
class TestErrorHandler {
  static Future<T> expectDatabaseError<T>(
    Future<T> Function() operation,
    String expectedMessage,
  ) async {
    try {
      await operation();
      fail('Expected DatabaseException but none was thrown');
    } on DatabaseException catch (e) {
      expect(e.message, contains(expectedMessage));
    }
  }
}
```

### Troubleshooting

#### Common Issues

| Issue | Solution |
|-------|----------|
| **Supabase Local won't start** | Check if Docker is running: `docker ps` |
| **Port 54321 in use** | Kill process: `lsof -ti:54321 | xargs kill -9` |
| **Connection error** | Check `supabase/config.toml` and environment variables |
| **Data doesn't persist** | Use `await` in Supabase operations |

#### Useful Commands
```bash
# Start Supabase Local
supabase start

# Reset test database
supabase db reset

# View logs
supabase logs --follow

# Run specific tests
flutter test test/integration/auth/login_test.dart
```

### Performance

#### 1. Optimizations
- Use `batched operations` for multiple insertions
- Implement `pagination` for large datasets
- Cache frequent queries with `Redis` (when needed)

#### 2. Monitoring
```dart
// lib/services/monitoring_service.dart
class MonitoringService {
  static Future<void> logQueryPerformance(
    String queryName,
    Duration duration,
  ) async {
    // Log for performance analysis
    print('Query $queryName took ${duration.inMilliseconds}ms');
  }
}
```

### CI/CD

#### GitHub Actions
```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Supabase
        uses: supabase/setup-cli@v1
        with:
          version: latest
          
      - name: Start Supabase
        run: supabase start
        
      - name: Run tests
        run: flutter test integration/
        
      - name: Stop Supabase
        run: supabase stop
```

### Additional Resources

- [Supabase Testing Guide](https://supabase.com/docs/guides/testing)
- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Best Practices for Database Testing](https://supabase.com/blog/testing-on-supabase)