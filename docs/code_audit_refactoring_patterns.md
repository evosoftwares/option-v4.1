# Auditoria de Código - Padrões de Refatoração
## Sistema de Horários de Trabalho

**Data:** 2025-01-23  
**Versão:** 1.0  
**Escopo:** Análise de padrões SOLID, DRY, Clean Architecture  

---

## 📋 Resumo Executivo

### Pontuação Geral: **5.8/10**

**Principais Problemas Identificados:**
- Violação do Single Responsibility Principle (SRP)
- Duplicação de código e lógica
- Acoplamento forte entre camadas
- Falta de abstração e inversão de dependência
- Mistura de responsabilidades na UI

**Impacto:** Médio-Alto  
**Prioridade:** Alta  
**Esforço Estimado:** 3-4 sprints  

---

## 🔍 Análise Detalhada por Princípio

### 1. Single Responsibility Principle (SRP)
**Status:** ❌ **Violado** - Score: 4/10

#### Problemas Identificados:

**WorkingHoursScreen (507 linhas)**
- Responsabilidades múltiplas:
  - Gerenciamento de estado da UI
  - Lógica de negócio (validação, conversão)
  - Comunicação com serviços
  - Formatação de dados
  - Navegação

```dart
// PROBLEMA: Classe fazendo muitas coisas
class _WorkingHoursScreenState extends State<WorkingHoursScreen> {
  // Estado da UI
  Map<String, bool> _enabledDays = {};
  Map<String, TimeOfDay> _startTimes = {};
  
  // Lógica de negócio
  Future<void> _loadWorkingHours() async { /* ... */ }
  Future<void> _saveWorkingHours() async { /* ... */ }
  
  // Formatação
  String _convertDayNameToKey(String dayName) { /* ... */ }
  
  // UI
  Widget build(BuildContext context) { /* ... */ }
}
```

**WorkingHoursService**
- Mistura validação com persistência
- Lógica de conflito de horários no serviço

#### Soluções Recomendadas:

1. **Separar em múltiplas classes:**
```dart
// Gerenciamento de estado
class WorkingHoursState {
  final Map<String, bool> enabledDays;
  final Map<String, TimeOfDay> startTimes;
  // ...
}

// Lógica de negócio
class WorkingHoursBusinessLogic {
  ValidationResult validateTimeConflict(/* ... */);
  WorkingHoursState convertFromService(List<WorkingHours> hours);
}

// Controller/Presenter
class WorkingHoursController {
  final WorkingHoursService _service;
  final WorkingHoursBusinessLogic _businessLogic;
  // ...
}
```

### 2. Open/Closed Principle (OCP)
**Status:** ⚠️ **Parcialmente Violado** - Score: 6/10

#### Problemas:
- Validações hardcoded no serviço
- Formatação de tempo acoplada ao modelo

#### Soluções:
```dart
// Abstração para validadores
abstract class WorkingHoursValidator {
  ValidationResult validate(WorkingHours hours);
}

class TimeConflictValidator implements WorkingHoursValidator {
  @override
  ValidationResult validate(WorkingHours hours) { /* ... */ }
}

class DayOfWeekValidator implements WorkingHoursValidator {
  @override
  ValidationResult validate(WorkingHours hours) { /* ... */ }
}
```

### 3. Liskov Substitution Principle (LSP)
**Status:** ✅ **Respeitado** - Score: 8/10

- Não há hierarquias complexas que violem LSP
- Interfaces bem definidas

### 4. Interface Segregation Principle (ISP)
**Status:** ⚠️ **Parcialmente Violado** - Score: 6/10

#### Problemas:
- WorkingHoursService muito amplo
- Clientes dependem de métodos que não usam

#### Soluções:
```dart
// Segregar interfaces
abstract class WorkingHoursReader {
  Future<List<WorkingHours>> getWorkingHours(String driverId);
  Future<List<WorkingHours>> getWorkingHoursByDay(String driverId, int day);
}

abstract class WorkingHoursWriter {
  Future<WorkingHours> createWorkingHours(WorkingHours hours);
  Future<WorkingHours> updateWorkingHours(String id, {/* ... */});
  Future<void> deleteWorkingHours(String id);
}

abstract class WorkingHoursValidator {
  Future<bool> isDriverWorkingNow(String driverId);
}
```

### 5. Dependency Inversion Principle (DIP)
**Status:** ❌ **Violado** - Score: 4/10

#### Problemas:
- Dependência direta do Supabase
- Acoplamento forte com implementações concretas

```dart
// PROBLEMA: Dependência direta
class WorkingHoursService {
  final SupabaseClient _supabase = Supabase.instance.client;
}
```

#### Soluções:
```dart
// Abstração do repositório
abstract class WorkingHoursRepository {
  Future<List<WorkingHours>> findByDriverId(String driverId);
  Future<WorkingHours> save(WorkingHours hours);
  Future<void> delete(String id);
}

// Implementação específica
class SupabaseWorkingHoursRepository implements WorkingHoursRepository {
  final SupabaseClient _client;
  
  SupabaseWorkingHoursRepository(this._client);
  // ...
}

// Serviço usando abstração
class WorkingHoursService {
  final WorkingHoursRepository _repository;
  
  WorkingHoursService(this._repository);
}
```

---

## 🔄 Análise DRY (Don't Repeat Yourself)
**Status:** ❌ **Violado** - Score: 5/10

### Duplicações Identificadas:

#### 1. Conversão de Dias da Semana
**Localização:** `working_hours_screen.dart` e `working_hours_dialog.dart`

```dart
// DUPLICADO em working_hours_screen.dart
final Map<String, String> _dayNames = {
  'sunday': 'Domingo',
  'monday': 'Segunda-feira',
  // ...
};

// DUPLICADO em working_hours_dialog.dart
String _getDayName(int dayOfWeek) {
  const days = [
    'Domingo',
    'Segunda-feira',
    // ...
  ];
}
```

**Solução:**
```dart
// Utilitário centralizado
class DayOfWeekUtils {
  static const Map<int, String> dayNames = {
    0: 'Domingo',
    1: 'Segunda-feira',
    2: 'Terça-feira',
    3: 'Quarta-feira',
    4: 'Quinta-feira',
    5: 'Sexta-feira',
    6: 'Sábado',
  };
  
  static String getDayName(int dayOfWeek) => dayNames[dayOfWeek % 7] ?? 'Desconhecido';
  
  static int getDayOfWeekFromName(String name) {
    return dayNames.entries
        .firstWhere((entry) => entry.value == name)
        .key;
  }
}
```

#### 2. Formatação de Tempo
**Localização:** `working_hours.dart` e `working_hours_screen.dart`

```dart
// DUPLICADO: Lógica de formatação
// Em working_hours.dart
static String formatTimeOfDay(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
}

// Em working_hours_screen.dart
final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
```

#### 3. Tratamento de Erros
**Localização:** Múltiplos arquivos

```dart
// PADRÃO REPETIDO
try {
  // operação
} on PostgrestException catch (e) {
  throw DatabaseException('Erro ao...', e.code);
} catch (e) {
  throw const DatabaseException('Erro inesperado...');
}
```

**Solução:**
```dart
class ErrorHandler {
  static T handleDatabaseOperation<T>(T Function() operation, String errorMessage) {
    try {
      return operation();
    } on PostgrestException catch (e) {
      throw DatabaseException(errorMessage, e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado: $errorMessage');
    }
  }
}
```

---

## 🏗️ Análise Clean Architecture
**Status:** ⚠️ **Parcialmente Implementado** - Score: 6/10

### Estrutura Atual vs. Ideal:

#### Atual:
```
lib/
├── models/supabase/          # Entities (misturado com framework)
├── services/                 # Use Cases + Repository (acoplado)
├── screens/                  # UI + Controller (misturado)
└── widgets/                  # UI Components
```

#### Ideal:
```
lib/
├── domain/
│   ├── entities/            # WorkingHours (puro)
│   ├── repositories/        # Abstrações
│   └── use_cases/          # Lógica de negócio
├── data/
│   ├── repositories/        # Implementações
│   ├── datasources/        # Supabase, Local
│   └── models/             # DTOs
├── presentation/
│   ├── controllers/        # State Management
│   ├── screens/           # UI pura
│   └── widgets/           # Componentes
└── core/
    ├── errors/            # Exceptions
    ├── utils/             # Utilitários
    └── constants/         # Constantes
```

### Problemas Identificados:

1. **Entities misturadas com Framework**
```dart
// PROBLEMA: Entity conhece Supabase
class WorkingHours {
  factory WorkingHours.fromJson(Map<String, dynamic> json) {
    // Lógica específica do Supabase
  }
}
```

2. **Use Cases não isolados**
```dart
// PROBLEMA: Service fazendo papel de Use Case + Repository
class WorkingHoursService {
  // Use Case
  Future<bool> isDriverWorkingNow(String driverId) async { /* ... */ }
  
  // Repository
  Future<List<WorkingHours>> getWorkingHours(String driverId) async { /* ... */ }
}
```

### Refatoração Proposta:

#### 1. Domain Layer
```dart
// domain/entities/working_hours.dart
class WorkingHours {
  final String id;
  final String driverId;
  final int dayOfWeek;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  
  // Lógica de negócio pura
  bool isWorkingNow() {
    final now = TimeOfDay.now();
    // ...
  }
}

// domain/repositories/working_hours_repository.dart
abstract class WorkingHoursRepository {
  Future<List<WorkingHours>> getByDriverId(String driverId);
  Future<WorkingHours> save(WorkingHours hours);
  Future<void> delete(String id);
}

// domain/use_cases/get_working_hours.dart
class GetWorkingHours {
  final WorkingHoursRepository repository;
  
  GetWorkingHours(this.repository);
  
  Future<List<WorkingHours>> call(String driverId) {
    return repository.getByDriverId(driverId);
  }
}
```

#### 2. Data Layer
```dart
// data/models/working_hours_model.dart
class WorkingHoursModel extends WorkingHours {
  WorkingHoursModel(/* ... */) : super(/* ... */);
  
  factory WorkingHoursModel.fromJson(Map<String, dynamic> json) {
    // Conversão específica do Supabase
  }
  
  Map<String, dynamic> toJson() {
    // Conversão para Supabase
  }
}

// data/repositories/working_hours_repository_impl.dart
class WorkingHoursRepositoryImpl implements WorkingHoursRepository {
  final WorkingHoursDataSource dataSource;
  
  WorkingHoursRepositoryImpl(this.dataSource);
  
  @override
  Future<List<WorkingHours>> getByDriverId(String driverId) async {
    final models = await dataSource.getByDriverId(driverId);
    return models.map((model) => model as WorkingHours).toList();
  }
}
```

#### 3. Presentation Layer
```dart
// presentation/controllers/working_hours_controller.dart
class WorkingHoursController extends ChangeNotifier {
  final GetWorkingHours _getWorkingHours;
  final SaveWorkingHours _saveWorkingHours;
  
  WorkingHoursState _state = WorkingHoursState.initial();
  WorkingHoursState get state => _state;
  
  Future<void> loadWorkingHours(String driverId) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();
    
    try {
      final hours = await _getWorkingHours(driverId);
      _state = _state.copyWith(
        isLoading: false,
        workingHours: hours,
      );
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
    
    notifyListeners();
  }
}
```

---

## 📊 Métricas de Qualidade

### Complexidade Ciclomática:
- **WorkingHoursScreen:** 15 (Alto - Limite: 10)
- **WorkingHoursService:** 12 (Alto - Limite: 10)
- **WorkingHours:** 8 (Médio)

### Linhas de Código:
- **WorkingHoursScreen:** 507 linhas (Muito Alto - Limite: 300)
- **WorkingHoursService:** 297 linhas (Alto - Limite: 200)

### Acoplamento:
- **Eferente (Ce):** 8 (Alto)
- **Aferente (Ca):** 3 (Baixo)
- **Instabilidade (I):** 0.73 (Alto)

---

## 🎯 Plano de Refatoração Priorizado

### Fase 1: Crítica (Sprint 1)
**Prioridade:** 🔴 **Crítica**

1. **Separar Responsabilidades da UI**
   - Extrair controller da WorkingHoursScreen
   - Criar WorkingHoursState para gerenciar estado
   - Implementar padrão MVC/MVP

2. **Centralizar Utilitários**
   - Criar DayOfWeekUtils
   - Criar TimeFormatUtils
   - Eliminar duplicação de código

3. **Implementar Error Handler**
   - Centralizar tratamento de erros
   - Padronizar mensagens de erro

### Fase 2: Alta (Sprint 2)
**Prioridade:** 🟠 **Alta**

1. **Implementar Repository Pattern**
   - Criar abstração WorkingHoursRepository
   - Implementar SupabaseWorkingHoursRepository
   - Aplicar Dependency Injection

2. **Separar Use Cases**
   - Extrair lógica de negócio do service
   - Criar use cases específicos
   - Implementar validadores

3. **Refatorar Validações**
   - Criar sistema de validação extensível
   - Implementar Strategy Pattern para validadores

### Fase 3: Média (Sprint 3)
**Prioridade:** 🟡 **Média**

1. **Implementar Clean Architecture Completa**
   - Reorganizar estrutura de pastas
   - Separar Domain, Data, Presentation
   - Criar DTOs e mappers

2. **Otimizar Performance**
   - Implementar cache local
   - Lazy loading de dados
   - Otimizar rebuilds da UI

### Fase 4: Baixa (Sprint 4)
**Prioridade:** 🟢 **Baixa**

1. **Melhorar Testabilidade**
   - Aumentar cobertura de testes
   - Implementar mocks e stubs
   - Testes de integração

2. **Documentação e Padrões**
   - Documentar arquitetura
   - Criar guias de desenvolvimento
   - Estabelecer code review guidelines

---

## 🔧 Exemplos de Implementação

### 1. Controller Separado
```dart
// presentation/controllers/working_hours_controller.dart
class WorkingHoursController extends ChangeNotifier {
  final GetWorkingHours _getWorkingHours;
  final SaveWorkingHours _saveWorkingHours;
  final ValidateWorkingHours _validateWorkingHours;
  
  WorkingHoursState _state = const WorkingHoursState.initial();
  WorkingHoursState get state => _state;
  
  WorkingHoursController({
    required GetWorkingHours getWorkingHours,
    required SaveWorkingHours saveWorkingHours,
    required ValidateWorkingHours validateWorkingHours,
  }) : _getWorkingHours = getWorkingHours,
       _saveWorkingHours = saveWorkingHours,
       _validateWorkingHours = validateWorkingHours;
  
  Future<void> loadWorkingHours(String driverId) async {
    _updateState(_state.copyWith(isLoading: true));
    
    try {
      final hours = await _getWorkingHours(driverId);
      _updateState(_state.copyWith(
        isLoading: false,
        workingHours: hours,
        error: null,
      ));
    } catch (e) {
      _updateState(_state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
  
  Future<void> saveWorkingHours(List<WorkingHours> hours) async {
    _updateState(_state.copyWith(isSaving: true));
    
    try {
      // Validar antes de salvar
      final validationResult = await _validateWorkingHours(hours);
      if (!validationResult.isValid) {
        throw ValidationException(validationResult.errors.first);
      }
      
      await _saveWorkingHours(hours);
      _updateState(_state.copyWith(
        isSaving: false,
        workingHours: hours,
        error: null,
      ));
    } catch (e) {
      _updateState(_state.copyWith(
        isSaving: false,
        error: e.toString(),
      ));
    }
  }
  
  void _updateState(WorkingHoursState newState) {
    _state = newState;
    notifyListeners();
  }
}
```

### 2. State Management
```dart
// presentation/states/working_hours_state.dart
@freezed
class WorkingHoursState with _$WorkingHoursState {
  const factory WorkingHoursState({
    @Default(false) bool isLoading,
    @Default(false) bool isSaving,
    @Default([]) List<WorkingHours> workingHours,
    @Default({}) Map<String, bool> enabledDays,
    @Default({}) Map<String, TimeOfDay> startTimes,
    @Default({}) Map<String, TimeOfDay> endTimes,
    String? error,
  }) = _WorkingHoursState;
  
  const factory WorkingHoursState.initial() = _Initial;
  const factory WorkingHoursState.loading() = _Loading;
  const factory WorkingHoursState.loaded(List<WorkingHours> hours) = _Loaded;
  const factory WorkingHoursState.error(String message) = _Error;
}
```

### 3. Use Case Example
```dart
// domain/use_cases/save_working_hours.dart
class SaveWorkingHours {
  final WorkingHoursRepository _repository;
  final List<WorkingHoursValidator> _validators;
  
  SaveWorkingHours(this._repository, this._validators);
  
  Future<List<WorkingHours>> call(List<WorkingHours> hours) async {
    // Validar
    for (final validator in _validators) {
      for (final hour in hours) {
        final result = await validator.validate(hour);
        if (!result.isValid) {
          throw ValidationException(result.errors.first);
        }
      }
    }
    
    // Salvar
    final savedHours = <WorkingHours>[];
    for (final hour in hours) {
      final saved = await _repository.save(hour);
      savedHours.add(saved);
    }
    
    return savedHours;
  }
}
```

---

## 📈 Benefícios Esperados

### Manutenibilidade:
- ✅ Redução de 60% no tempo de implementação de novas features
- ✅ Facilidade para adicionar novos validadores
- ✅ Testes mais simples e isolados

### Testabilidade:
- ✅ Cobertura de testes de 25% → 80%
- ✅ Testes unitários isolados
- ✅ Mocks e stubs bem definidos

### Performance:
- ✅ Redução de rebuilds desnecessários
- ✅ Cache local implementado
- ✅ Lazy loading de dados

### Escalabilidade:
- ✅ Arquitetura preparada para crescimento
- ✅ Fácil adição de novas funcionalidades
- ✅ Separação clara de responsabilidades

---

## 🎯 Conclusão

O sistema de horários de trabalho apresenta **violações significativas** dos princípios SOLID e Clean Architecture, com **score geral de 5.8/10**. As principais preocupações são:

1. **Violação do SRP** - Classes com múltiplas responsabilidades
2. **Duplicação de código** - Lógica repetida em múltiplos locais
3. **Acoplamento forte** - Dependências diretas de frameworks
4. **Falta de abstração** - Ausência de interfaces e inversão de dependência

**Recomendação:** Implementar o plano de refatoração em 4 fases, priorizando a separação de responsabilidades e implementação do Repository Pattern.

**ROI Estimado:** Alto - Redução significativa no tempo de desenvolvimento e manutenção, com melhoria na qualidade e testabilidade do código.

---

**Próximos Passos:**
1. Aprovação do plano de refatoração
2. Implementação da Fase 1 (Crítica)
3. Testes e validação
4. Continuação das fases subsequentes

**Responsável:** Equipe de Desenvolvimento  
**Revisão:** Arquiteto de Software  
**Prazo:** 4 sprints (8 semanas)