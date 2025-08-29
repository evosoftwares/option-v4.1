# Sistema de Matching de Motoristas

## Visão Geral

O Sistema de Matching de Motoristas é responsável por encontrar e selecionar os melhores motoristas disponíveis para atender às solicitações de corrida dos passageiros. O sistema utiliza algoritmos avançados de filtragem, pontuação e ordenação para garantir a melhor experiência tanto para passageiros quanto para motoristas.

## Arquitetura

### Componentes Principais

1. **DriverMatchingService** - Serviço principal que coordena todo o processo de matching
2. **MatchingCriteria** - Classe que define os critérios de busca do passageiro
3. **DriverMatchResult** - Classe que representa o resultado do matching para cada motorista
4. **DriverService** - Serviço para operações com dados dos motoristas
5. **DriverExcludedZonesService** - Serviço para verificação de zonas de exclusão

### Fluxo de Funcionamento

```
Passageiro solicita corrida
        ↓
Criação do MatchingCriteria
        ↓
Busca motoristas no raio especificado
        ↓
Filtragem por zona de exclusão
        ↓
Filtragem por preferências
        ↓
Verificação de disponibilidade em tempo real
        ↓
Cálculo de pontuação de matching
        ↓
Ordenação por pontuação
        ↓
Retorno dos melhores motoristas
```

## Classes e Modelos

### MatchingCriteria

Define os critérios para busca de motoristas.

```dart
class MatchingCriteria {
  final double passengerLatitude;
  final double passengerLongitude;
  final double maxRadiusKm;
  final String? vehicleCategory;
  final bool needsPet;
  final bool needsGrocery;
  final bool needsCondo;
  final bool needsAC;
  final int maxDrivers;
}
```

**Parâmetros:**
- `passengerLatitude/passengerLongitude`: Localização do passageiro
- `maxRadiusKm`: Raio máximo de busca (padrão: 10km)
- `vehicleCategory`: Categoria do veículo (standard, premium, etc.)
- `needsPet`: Requer transporte de animais
- `needsGrocery`: Requer transporte de compras
- `needsCondo`: Requer acesso a condomínios
- `needsAC`: Requer ar condicionado
- `maxDrivers`: Número máximo de motoristas retornados (padrão: 10)

### DriverMatchResult

Representa o resultado do matching para um motorista específico.

```dart
class DriverMatchResult {
  final Driver driver;
  final double distanceKm;
  final int estimatedArrivalMinutes;
  final double matchScore;
  final bool isAvailable;
  final String? unavailabilityReason;
}
```

**Propriedades:**
- `driver`: Dados completos do motorista
- `distanceKm`: Distância até o passageiro
- `estimatedArrivalMinutes`: Tempo estimado de chegada
- `matchScore`: Pontuação de compatibilidade (0.0 a 1.0)
- `isAvailable`: Disponibilidade em tempo real
- `unavailabilityReason`: Motivo da indisponibilidade (se aplicável)

## Algoritmos

### 1. Filtragem por Distância

Utiliza a fórmula de Haversine para calcular distâncias geográficas:

```dart
double calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371; // km
  
  double dLat = _toRadians(lat2 - lat1);
  double dLon = _toRadians(lon2 - lon1);
  
  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
      sin(dLon / 2) * sin(dLon / 2);
  
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}
```

### 2. Sistema de Pontuação

A pontuação de matching considera múltiplos fatores:

```dart
double calculateMatchScore(Driver driver, double passengerLat, double passengerLon) {
  double score = 1.0;
  
  // Fator distância (peso: 40%)
  double distance = calculateHaversineDistance(...);
  double distanceScore = max(0.0, 1.0 - (distance / 20.0));
  score *= (0.4 * distanceScore + 0.6);
  
  // Fator avaliação (peso: 30%)
  double ratingScore = (driver.ratings ?? 3.0) / 5.0;
  score *= (0.3 * ratingScore + 0.7);
  
  // Fator experiência (peso: 20%)
  double experienceScore = min(1.0, driver.trips / 100.0);
  score *= (0.2 * experienceScore + 0.8);
  
  // Penalização por cancelamentos (peso: 10%)
  double cancellationRate = driver.trips > 0 ? driver.cancellations / driver.trips : 0.0;
  double cancellationPenalty = max(0.0, 1.0 - (cancellationRate * 10));
  score *= (0.1 * cancellationPenalty + 0.9);
  
  return min(1.0, max(0.0, score));
}
```

### 3. Filtragem por Preferências

Verifica se o motorista atende às preferências específicas:

- **Pet**: `driver.acceptsPet == true`
- **Grocery**: `driver.acceptsGrocery == true`
- **Condo**: `driver.acceptsCondo == true`
- **AC**: `driver.acPolicy == 'always_on'`

### 4. Verificação de Disponibilidade

Verifica em tempo real se o motorista está disponível:

- Status online: `driver.isOnline == true`
- Sem viagem ativa: Consulta tabela `trips` para viagens em andamento
- Aprovação: `driver.approvalStatus == 'approved'`

## Cache e Performance

### Sistema de Cache

O sistema implementa cache para otimizar performance:

```dart
class DriverMatchingService {
  final Map<String, List<DriverMatchResult>> _cache = {};
  static const Duration _cacheExpiry = Duration(minutes: 2);
  
  String _generateCacheKey(MatchingCriteria criteria) {
    return '${criteria.passengerLatitude}_${criteria.passengerLongitude}_'
           '${criteria.maxRadiusKm}_${criteria.vehicleCategory}_'
           '${criteria.needsPet}_${criteria.needsGrocery}_'
           '${criteria.needsCondo}_${criteria.needsAC}';
  }
}
```

**Estratégias de Cache:**
- Cache por localização e critérios
- Expiração automática em 2 minutos
- Invalidação em mudanças de status dos motoristas

### Otimizações

1. **Consultas Eficientes**: Uso de índices geográficos no banco
2. **Filtragem Progressiva**: Aplicação de filtros em ordem de eficiência
3. **Limite de Resultados**: Processamento apenas dos motoristas necessários
4. **Cache Inteligente**: Reutilização de resultados para critérios similares

## Configurações

### Parâmetros Configuráveis

```dart
class MatchingConfig {
  static const double DEFAULT_MAX_RADIUS_KM = 10.0;
  static const int DEFAULT_MAX_DRIVERS = 10;
  static const Duration CACHE_EXPIRY = Duration(minutes: 2);
  static const double MIN_RATING_THRESHOLD = 3.0;
  static const double MAX_CANCELLATION_RATE = 0.2; // 20%
  static const int MIN_EXPERIENCE_TRIPS = 5;
}
```

### Zonas de Exclusão

O sistema suporta zonas geográficas onde motoristas específicos não podem operar:

- Definidas por polígonos geográficos
- Verificação automática durante o matching
- Configuráveis por motorista ou região

## Integração

### Uso Básico

```dart
// Criar critérios de busca
final criteria = MatchingCriteria(
  passengerLatitude: -23.5505,
  passengerLongitude: -46.6333,
  maxRadiusKm: 15.0,
  vehicleCategory: 'standard',
  needsPet: true,
  maxDrivers: 5,
);

// Buscar motoristas
final service = DriverMatchingService(supabaseClient);
final results = await service.findBestDrivers(criteria);

// Processar resultados
for (final result in results) {
  print('Motorista: ${result.driver.id}');
  print('Distância: ${result.distanceKm}km');
  print('ETA: ${result.estimatedArrivalMinutes}min');
  print('Score: ${result.matchScore}');
}
```

### Integração com DriverSelectionScreen

```dart
class DriverSelectionScreen extends StatefulWidget {
  Future<void> _loadDriversWithRetry() async {
    final criteria = MatchingCriteria(
      passengerLatitude: widget.pickupLocation.latitude,
      passengerLongitude: widget.pickupLocation.longitude,
      maxRadiusKm: 15.0,
      vehicleCategory: widget.selectedCategory,
      needsPet: widget.needsPet,
      needsGrocery: widget.needsGrocery,
      needsCondo: widget.needsCondo,
      needsAC: widget.needsAC,
      maxDrivers: 10,
    );
    
    final matchResults = await _driverMatchingService.findBestDrivers(criteria);
    // Processar resultados...
  }
}
```

## Testes

### Testes Unitários

Localizados em `test/unit/driver_matching_service_test.dart`:

- Validação de `MatchingCriteria`
- Validação de `DriverMatchResult`
- Testes de consistência de dados
- Validação de modelos `Driver`

### Testes de Integração

Localizados em `test/integration/driver_matching_integration_test.dart`:

- Testes de criação de objetos
- Validação de serialização JSON
- Testes de integração entre componentes

### Executar Testes

```bash
# Todos os testes do sistema de matching
flutter test test/unit/driver_matching_service_test.dart test/integration/driver_matching_integration_test.dart

# Apenas testes unitários
flutter test test/unit/driver_matching_service_test.dart

# Apenas testes de integração
flutter test test/integration/driver_matching_integration_test.dart
```

## Monitoramento e Métricas

### Métricas Importantes

1. **Tempo de Resposta**: Tempo para encontrar motoristas
2. **Taxa de Cache Hit**: Eficiência do sistema de cache
3. **Precisão do Matching**: Qualidade dos motoristas selecionados
4. **Taxa de Aceitação**: Porcentagem de corridas aceitas pelos motoristas

### Logs e Debugging

```dart
// Habilitar logs detalhados
DriverMatchingService.enableDebugLogs = true;

// Logs automáticos incluem:
// - Critérios de busca
// - Número de motoristas encontrados
// - Tempo de processamento
// - Cache hits/misses
// - Filtros aplicados
```

## Troubleshooting

### Problemas Comuns

1. **Nenhum motorista encontrado**
   - Verificar raio de busca
   - Verificar critérios muito restritivos
   - Verificar disponibilidade de motoristas na região

2. **Performance lenta**
   - Verificar índices do banco de dados
   - Ajustar configurações de cache
   - Reduzir raio de busca

3. **Resultados inconsistentes**
   - Verificar sincronização de dados
   - Verificar configurações de cache
   - Verificar logs de erro

### Configurações de Debug

```dart
// Desabilitar cache para debugging
DriverMatchingService.disableCache = true;

// Aumentar logs
DriverMatchingService.logLevel = LogLevel.verbose;

// Forçar recálculo de scores
DriverMatchingService.forceScoreRecalculation = true;
```

## Roadmap

### Melhorias Futuras

1. **Machine Learning**: Implementar algoritmos de ML para melhorar a precisão do matching
2. **Previsão de Demanda**: Antecipar necessidades de motoristas por região
3. **Otimização Dinâmica**: Ajustar algoritmos baseado em métricas em tempo real
4. **Matching Bidirecional**: Considerar preferências dos motoristas também
5. **Integração com Trânsito**: Considerar condições de trânsito em tempo real

### Versioning

- **v1.0**: Implementação básica com filtragem e pontuação
- **v1.1**: Sistema de cache e otimizações de performance
- **v1.2**: Integração com zonas de exclusão
- **v1.3**: Melhorias no algoritmo de pontuação
- **v2.0**: (Planejado) Integração com Machine Learning

---

**Última atualização**: Janeiro 2025  
**Versão do sistema**: 1.3  
**Autor**: Equipe de Desenvolvimento Option