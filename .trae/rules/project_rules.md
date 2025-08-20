# 🚀 Regras do Projeto - Uber Clone

## 📋 Diretrizes de Desenvolvimento

### 🧪 Testes e Mocking

#### ❌ O que NÃO fazer
- **Nunca usar mocks** (ex: `mockito`, `mocktail`) para simular comportamentos
- **Não criar classes fake** que imitem o comportamento do Supabase
- **Evitar stubs** que retornam dados hardcoded

#### ✅ O que FAZER
- **Sempre usar Supabase real** para testes de integração

### 🏗️ Arquitetura de Testes

#### 1. Configuração do Ambiente de Testes

```yaml
# supabase/config.toml
[env.testing]
project_id = "uber-clone-testing"
api_url = "http://localhost:54321"
anon_key = "your-testing-anon-key"
```

#### 2. Estrutura de Testes Recomendada

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

### 🔧 Implementação com Supabase

#### Exemplo de Teste de Integração

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
    // Limpar tabelas de teste
    await Supabase.instance.client
        .from('users')
        .delete()
        .neq('id', '00000000-0000-0000-0000-000000000000');
  }

  static Future<void> seedTestData() async {
    // Inserir dados de teste
    await Supabase.instance.client.from('users').insert([
      {
        'email': 'test@example.com',
        'name': 'Test User',
      }
    ]);
  }
}
```

#### Exemplo de Teste Real

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

### 🎯 Melhores Práticas

#### 1. Configuração de Ambiente
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

  // Métodos utilitários para tratamento de erros
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

### 🚨 Tratamento de Erros

#### 1. Exceções Customizadas
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

#### 2. Error Handling em Testes
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

### 🔍 Troubleshooting

#### Problemas Comuns

| Problema | Solução |
|----------|---------|
| **Supabase Local não inicia** | Verificar se Docker está rodando: `docker ps` |
| **Porta 54321 em uso** | Matar processo: `lsof -ti:54321 \| xargs kill -9` |
| **Erro de conexão** | Verificar `supabase/config.toml` e variáveis de ambiente |
| **Dados não persistem** | Usar `await` nas operações do Supabase |

#### Comandos Úteis
```bash
# Iniciar Supabase Local
supabase start

# Resetar banco de testes
supabase db reset

# Ver logs
supabase logs --follow

# Executar testes específicos
flutter test test/integration/auth/login_test.dart
```

### 📊 Performance

#### 1. Otimizações
- Usar `batched operations` para múltiplas inserções
- Implementar `pagination` para grandes conjuntos de dados
- Cachear queries frequentes com `Redis` (quando necessário)

#### 2. Monitoramento
```dart
// lib/services/monitoring_service.dart
class MonitoringService {
  static Future<void> logQueryPerformance(
    String queryName,
    Duration duration,
  ) async {
    // Log para análise de performance
    print('Query $queryName took ${duration.inMilliseconds}ms');
  }
}
```

### 🔄 CI/CD

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

### 📚 Recursos Adicionais

- [Supabase Testing Guide](https://supabase.com/docs/guides/testing)
- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Best Practices for Database Testing](https://supabase.com/blog/testing-on-supabase)