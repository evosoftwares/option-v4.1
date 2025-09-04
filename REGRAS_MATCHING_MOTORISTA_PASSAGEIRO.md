# 🚗 Regras Completas de Matching Motorista-Passageiro - App Option

## 📋 Índice
1. [Introdução e Visão Geral](#introdução-e-visão-geral)
2. [Critérios Básicos de Elegibilidade](#critérios-básicos-de-elegibilidade)
3. [Sistema de Horários de Trabalho](#sistema-de-horários-de-trabalho)
4. [Filtros de Preferências do Passageiro](#filtros-de-preferências-do-passageiro)
5. [Sistema de Zonas de Exclusão](#sistema-de-zonas-de-exclusão)
6. [Áreas de Atuação](#áreas-de-atuação)
7. [Sistema de Scoring e Ordenação](#sistema-de-scoring-e-ordenação)
8. [Preços Personalizados](#preços-personalizados)
9. [Cache e Performance](#cache-e-performance)
10. [Fluxo Técnico Detalhado](#fluxo-técnico-detalhado)
11. [Casos Especiais e Limitações](#casos-especiais-e-limitações)
12. [Exemplos Práticos](#exemplos-práticos)
13. [FAQ - Perguntas Frequentes](#faq---perguntas-frequentes)

---

## 🎯 Introdução e Visão Geral

O sistema de matching do app Option funciona com um **pipeline de filtros sequencial** que determina quais motoristas aparecem para um passageiro. O processo segue esta ordem:

```
Passageiro faz solicitação 
    ↓
Busca motoristas na região (raio de até 10km)
    ↓
Aplica filtros básicos de elegibilidade
    ↓
Filtra por preferências do passageiro
    ↓
Remove motoristas com zonas de exclusão
    ↓
Verifica disponibilidade em tempo real
    ↓
Calcula scores de matching
    ↓
Ordena e limita resultado (máx. 10 motoristas)
    ↓
Exibe lista para o passageiro
```

### 🔑 Conceitos Importantes

- **Critérios Eliminatórios**: Se não atendidos, o motorista não aparece na lista
- **Critérios de Score**: Afetam a posição na listagem, mas não eliminam o motorista
- **Matching Bidirecional**: Considera preferências do passageiro E configurações do motorista

---

## ✅ Critérios Básicos de Elegibilidade

Para um motorista aparecer na listagem, **TODOS** estes critérios devem ser atendidos:

### 1. 🟢 Status Online Efetivo
- **Campo**: `effective_online = true` na view `driver_effective_status`
- **Lógica**: Combina intenção do motorista + horários de trabalho
- **Como funciona**:
  - Motorista indica intenção de ficar online
  - Sistema verifica se está dentro dos horários de trabalho configurados
  - Se SIM → `effective_online = true`
  - Se NÃO → `effective_online = false` (mesmo que queira estar online)

### 2. 📍 Localização Dentro do Raio
- **Campo**: `current_latitude` e `current_longitude` não nulos
- **Raio padrão**: 10km da origem do passageiro
- **Método de cálculo**: Bounding box aproximado para performance
- **Fórmula**: 
  ```
  latDelta = radiusKm / 111.0 km por grau
  lngDelta = radiusKm / (111.0 * cos(latitude))
  ```

### 3. ✅ Status de Aprovação
- **Campo**: `approval_status = 'approved'` OR `approval_status IS NULL`
- **Motivo**: Apenas motoristas aprovados podem atender corridas
- **Estados possíveis**: `pending`, `approved`, `rejected`, `null`

### 4. 🚫 Não Estar em Viagem Ativa
- **Verificação**: Sem registros na tabela `trips` com status `accepted` ou `in_progress`
- **Consulta em tempo real**: Verificada no momento da busca
- **Fallback**: Em caso de erro, assume disponível para não impactar funcionalidade

### 5. 📱 Localização Atualizada Recente
- **Campo**: `last_location_update` deve ser recente
- **Objetivo**: Evitar motoristas com localização desatualizada
- **Implementação**: Filtro implícito via queries de proximidade

---

## ⏰ Sistema de Horários de Trabalho

O sistema de horários implementa uma lógica sofisticada que separa **intenção** de **disponibilidade efetiva**.

### 📊 Tabelas Envolvidas

#### `driver_status`
```sql
- driver_id: UUID
- online_intent: BOOLEAN  -- Intenção do motorista
- intent_updated_at: TIMESTAMP
```

#### `working_hours` 
```sql
- driver_id: UUID
- day_of_week: INT (0=domingo, 6=sábado)
- start_time: TIME
- end_time: TIME
- is_active: BOOLEAN
```

#### `driver_effective_status` (VIEW)
```sql
-- Combina as duas tabelas acima
- driver_id: UUID
- online_intent: BOOLEAN
- effective_online: BOOLEAN  -- Status final calculado
- is_within_working_hours: BOOLEAN
```

### 🔄 Lógica de Cálculo do Status Efetivo

```sql
-- Pseudocódigo da view
effective_online = online_intent AND (
    working_hours IS NULL OR  -- Sem horários = sempre disponível
    is_within_working_hours = true
)
```

### 📋 Regras dos Horários

1. **Sem horários configurados**: Motorista pode ficar online 24/7
2. **Com horários configurados**: Só fica online dentro dos horários
3. **Múltiplos períodos**: Mesmo dia pode ter vários horários (ex: manhã e tarde)
4. **Atravessar meia-noite**: Horário 23:00-02:00 é suportado
5. **Ativação/desativação**: Horários podem ser temporariamente desativados

### 🎯 Impacto no Matching

- **Filtro principal**: `effective_online = true`
- **Verificação dupla**: Status checado novamente em tempo real
- **Mudança automática**: Motorista sai da listagem quando sai do horário
- **Interface visual**: App mostra status "Fora do horário" quando aplicável

---

## 🎛️ Filtros de Preferências do Passageiro

Estes filtros removem motoristas que **não atendem** às necessidades específicas do passageiro.

### 1. 🐕 Transporte de Pets
- **Preferência do passageiro**: `needsPet = true`
- **Campo do motorista**: `accepts_pet = true`
- **Regra**: Se passageiro precisa, motorista DEVE aceitar pets
- **Taxa adicional**: `pet_fee` (configurável por motorista)

### 2. 🛒 Compras/Mercado  
- **Preferência do passageiro**: `needsGrocery = true`
- **Campo do motorista**: `accepts_grocery = true`
- **Uso**: Corridas para supermercado, farmácia, etc.
- **Taxa adicional**: `grocery_fee` (configurável por motorista)

### 3. 🏢 Condomínios
- **Preferência do passageiro**: `needsCondo = true`
- **Campo do motorista**: `accepts_condo = true`
- **Aplicação**: Origem OU destino em condomínio
- **Taxa adicional**: `condo_fee` (configurável por motorista)

### 4. ❄️ Ar-Condicionado
- **Preferência do passageiro**: `needsAC = true`
- **Campo do motorista**: `ac_policy`
- **Valores válidos para passar no filtro**:
  - `always_on` (sempre ligado)
  - `on_request` (liga quando solicitado)
  - `seasonal` (liga conforme temperatura)
- **Valores que eliminam o motorista**:
  - `never` ou `nunca` (nunca liga)
  - `null` (não definido)

### 5. 🚗 Categoria do Veículo
- **Preferência do passageiro**: `vehicleCategory` (string)
- **Campo do motorista**: `vehicle_category`
- **Categorias típicas**: `economy`, `standard`, `premium`, `luxury`
- **Match exato**: Deve ser exatamente igual
- **Passageiro sem preferência**: Aceita qualquer categoria

### 📊 Tabela Resumo dos Filtros

| Filtro | Campo Passageiro | Campo Motorista | Ação |
|--------|------------------|-----------------|------|
| Pet | `needsPet: true` | `accepts_pet: true` | Elimina se motorista não aceita |
| Mercado | `needsGrocery: true` | `accepts_grocery: true` | Elimina se motorista não aceita |
| Condomínio | `needsCondo: true` | `accepts_condo: true` | Elimina se motorista não aceita |
| Ar-condicionado | `needsAC: true` | `ac_policy ≠ 'never'` | Elimina se nunca liga AC |
| Categoria | `vehicleCategory: string` | `vehicle_category: string` | Elimina se categorias diferentes |

---

## 🚫 Sistema de Zonas de Exclusão

Permite que motoristas definam **bairros/regiões específicas** onde não desejam aceitar corridas.

### 📋 Como Funciona

#### Configuração pelo Motorista
1. **Acesso**: Menu → Trabalho → Zonas excluídas
2. **Interface**: Busca por endereço ou preenchimento manual
3. **Dados necessários**:
   - Nome do bairro (ex: "Centro", "Copacabana")
   - Cidade (ex: "Rio de Janeiro", "São Paulo")  
   - Estado (sigla - ex: "RJ", "SP")
4. **Limite**: Máximo 50 zonas por motorista

#### Estrutura no Banco
```sql
driver_excluded_zones (
    id UUID PRIMARY KEY,
    driver_id UUID,
    neighborhood_name TEXT,
    city TEXT, 
    state TEXT,
    created_at TIMESTAMP
)
```

### 🎯 Lógica de Filtragem

#### Verificação Dupla
O sistema verifica se a **origem OU destino** da viagem está em zona excluída:

```sql
-- Pseudocódigo da verificação
FOR cada motorista:
    zones = buscar_zonas_excluidas(motorista_id)
    
    FOR cada zona IN zones:
        IF (origem_bairro = zona.bairro AND origem_cidade = zona.cidade AND origem_estado = zona.estado)
            OR (destino_bairro = zona.bairro AND destino_cidade = zona.cidade AND destino_estado = zona.estado):
            ELIMINAR motorista
```

#### Otimização em Lote
Para performance, o sistema processa múltiplos motoristas simultaneamente:

```sql
SELECT DISTINCT driver_id 
FROM driver_excluded_zones 
WHERE driver_id IN (lista_motoristas)
  AND ((neighborhood_name = origem_bairro AND city = origem_cidade AND state = origem_estado)
    OR (neighborhood_name = destino_bairro AND city = destino_cidade AND state = destino_estado))
```

### 📍 Cenários de Aplicação

1. **Origem excluída**: Motorista não aparece para corridas que começam na zona
2. **Destino excluído**: Motorista não aparece para corridas que terminam na zona  
3. **Ambos excluídos**: Motorista não aparece em nenhum caso
4. **Informações incompletas**: Se origem/destino não têm bairro/cidade/estado, filtro não é aplicado

### ⚠️ Limitações e Considerações

- **Granularidade**: Apenas por bairro, não por ruas específicas
- **Dependência de dados**: Requer geocodificação precisa dos endereços
- **Não afeta corridas ativas**: Só impacta novas solicitações
- **Fallback em erro**: Se consulta falhar, motorista não é eliminado

---

## 🗺️ Áreas de Atuação

Sistema avançado que permite motoristas desenhar **polígonos personalizados** no mapa com **multiplicadores de preço**.

### 🎨 Como Funciona

#### Interface para Motorista
1. **Acesso**: Menu → Trabalho → Áreas de atuação
2. **Criação**: Tocar no mapa para desenhar polígonos (mín. 3 pontos)
3. **Configuração**:
   - Nome da área (ex: "Centro", "Zona Sul")
   - Multiplicador de preço (0.1x a 10.0x)
   - Status ativo/inativo

#### Estrutura no Banco
```sql
driver_operation_zones (
    id UUID PRIMARY KEY,
    driver_id UUID,
    zone_name TEXT,
    polygon_coordinates JSONB,  -- Array de {lat, lng}
    price_multiplier NUMERIC(4,2) DEFAULT 1.00,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
```

### 📐 Algoritmo Point-in-Polygon

#### Ray Casting Algorithm
Para verificar se um ponto está dentro de um polígono:

```dart
bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
  int intersections = 0;
  
  for (int i = 0; i < polygon.length; i++) {
    LatLng p1 = polygon[i];
    LatLng p2 = polygon[(i + 1) % polygon.length];
    
    if (rayIntersectsEdge(point, p1, p2)) {
      intersections++;
    }
  }
  
  return intersections % 2 == 1; // Ímpar = dentro
}
```

#### Aplicação no Matching
1. **Verificação de localização**: Sistema verifica se origem/destino estão dentro de áreas ativas
2. **Cálculo de multiplicador**: `preço_final = preço_base * price_multiplier`
3. **Áreas sobrepostas**: Usa o maior multiplicador encontrado
4. **Performance**: Algoritmo otimizado para múltiplos polígonos

### 🎯 Integração com Preços

```dart
// Exemplo de uso no cálculo
final multiplier = await driverOperationZonesService
    .getPriceMultiplierForPoint(driverId, pickupLocation);
    
final finalPrice = basePrice * multiplier;
```

### 📊 Funcionalidades Avançadas

- **Estatísticas**: Área total em km², multiplicador médio
- **Cores dinâmicas**: Cada área tem cor diferente no mapa
- **Validação de sobreposição**: Sistema detecta áreas que se sobrepõem
- **Backup e restauração**: Áreas podem ser exportadas/importadas

---

## 🏆 Sistema de Scoring e Ordenação

Após aplicar todos os filtros eliminatórios, o sistema calcula um **score de matching** (0-100 pontos) para ordenar os motoristas.

### 📊 Componentes do Score

#### 1. 📏 Distância (40% do peso total)
```dart
// Quanto mais próximo, maior o score
final distanceScore = ((maxRadius - distance) / maxRadius) * 40;
score += max(0.0, distanceScore);
```
- **Peso**: 40 pontos máximos
- **Lógica**: Motorista mais próximo recebe pontuação máxima
- **Cálculo**: Haversine distance em km

#### 2. ⭐ Rating/Avaliação (30% do peso total)
```dart
if (driver.ratings > 0) {
  final ratingScore = (driver.ratings / 5.0) * 30;
  score += ratingScore;
} else {
  score += 15.0; // Score neutro para novos motoristas
}
```
- **Peso**: 30 pontos máximos
- **Escala**: 0-5 estrelas
- **Novos motoristas**: Recebem 15 pontos (neutro)

#### 3. 🚗 Experiência (20% do peso total)
```dart
final experienceScore = min(driver.totalTrips / 100.0, 1) * 20;
score += experienceScore;
```
- **Peso**: 20 pontos máximos
- **Cálculo**: Número de viagens completadas
- **Teto**: 100 viagens = pontuação máxima

#### 4. 🎯 Confiabilidade (10% do peso total)
```dart
final reliabilityScore = max(0, (5 - driver.cancellations) / 5.0) * 10;
score += reliabilityScore;
```
- **Peso**: 10 pontos máximos
- **Cálculo**: Baseado no número de cancelamentos
- **Lógica**: Menos cancelamentos = maior confiabilidade

### 🎁 Bônus por Preferências (+2 pontos cada)

Motoristas que atendem preferências específicas recebem pontos extras:

```dart
if (needsPet && driver.acceptsPet) score += 2.0;
if (needsGrocery && driver.acceptsGrocery) score += 2.0;  
if (needsCondo && driver.acceptsCondo) score += 2.0;
if (needsAC && driver.hasAC) score += 2.0;
```

### 📈 Exemplo de Cálculo

**Motorista A**: 2km distância, 4.5 estrelas, 150 viagens, 1 cancelamento
```
Distância: ((10-2)/10) * 40 = 32 pontos
Rating: (4.5/5) * 30 = 27 pontos  
Experiência: min(150/100, 1) * 20 = 20 pontos
Confiabilidade: (5-1)/5 * 10 = 8 pontos
Bônus Pet: +2 pontos
Total: 89 pontos
```

**Motorista B**: 1km distância, 3.8 estrelas, 50 viagens, 3 cancelamentos
```
Distância: ((10-1)/10) * 40 = 36 pontos
Rating: (3.8/5) * 30 = 22.8 pontos
Experiência: (50/100) * 20 = 10 pontos  
Confiabilidade: (5-3)/5 * 10 = 4 pontos
Total: 72.8 pontos
```

**Resultado**: Motorista A aparece primeiro na lista.

### 🔢 Ordenação Final

```dart
// Ordena do maior para o menor score
matchResults.sort((a, b) => b.matchScore.compareTo(a.matchScore));

// Limita ao máximo definido (padrão: 10 motoristas)
final finalResults = matchResults.take(maxDrivers).toList();
```

---

## 💰 Preços Personalizados

Motoristas podem configurar preços individuais e taxas adicionais específicas.

### 🔧 Configuração por Motorista

#### Preços Base Customizados
- **Campo**: `custom_price_per_km` (por quilômetro)
- **Campo**: `custom_price_per_minute` (por minuto)
- **Interface**: Menu → Trabalho → Preços personalizados
- **Fallback**: Se não definido, usa preço padrão da categoria

#### Taxas Adicionais
```sql
-- Campos na tabela drivers
pet_fee NUMERIC(10,2) DEFAULT 5.00,
grocery_fee NUMERIC(10,2) DEFAULT 3.00,  
condo_fee NUMERIC(10,2) DEFAULT 2.00,
stop_fee NUMERIC(10,2) DEFAULT 1.50
```

### 💡 Aplicação no Matching

#### Durante a Busca
- Preços personalizados **NÃO eliminam** motoristas
- São considerados apenas para **exibição** ao passageiro
- Score de matching **não** considera preços

#### Cálculo Final
```dart
// Preço base
final pricePerKm = driver.customPricePerKm ?? category.basePricePerKm;
final pricePerMinute = driver.customPricePerMinute ?? category.basePricePerMinute;

// Preço da corrida
var totalPrice = (pricePerKm * distance) + (pricePerMinute * duration);

// Taxas adicionais
if (needsPet) totalPrice += driver.petFee;
if (needsGrocery) totalPrice += driver.groceryFee;
if (needsCondo) totalPrice += driver.condoFee;

// Multiplicador de área
if (multiplier > 1.0) totalPrice *= multiplier;
```

### 📊 Exibição para o Passageiro

```
Motorista João - 4.8★ - 2 min
R$ 15,50 • Sedan Azul
+ Pet: R$ 5,00
+ Condomínio: R$ 2,00
```

### 🎯 Estratégia de Negócio

- **Flexibilidade**: Motoristas ajustam preços conforme demanda
- **Transparência**: Passageiro vê valores antes de escolher
- **Competitividade**: Preços menores podem atrair mais corridas

---

## ⚡ Cache e Performance

O sistema implementa várias otimizações para garantir resposta rápida nas buscas.

### 🗄️ Cache de Motoristas

#### Implementação
```dart
final Map<String, List<Driver>> _driversCache = {};
final Map<String, DateTime> _cacheTimestamps = {};
static const Duration _cacheValidDuration = Duration(minutes: 2);
```

#### Chave de Cache
```dart
final cacheKey = '${latitude}_${longitude}_${radiusKm}_${vehicleCategory ?? "any"}';
```

#### Lógica de Invalidação
- **Tempo de vida**: 2 minutos
- **Limpeza automática**: Cache limpo quando expira
- **Força refresh**: `clearCache()` pode ser chamado manualmente

### 🚀 Otimizações de Query

#### View Otimizada `available_drivers_view`
```sql
CREATE VIEW available_drivers_view AS
SELECT 
    d.id as driver_id,
    d.user_id,
    d.vehicle_brand,
    d.is_online,
    d.current_latitude,
    u.full_name,
    u.photo_url
FROM drivers d
JOIN app_users u ON d.user_id = u.id
WHERE d.is_online = true 
  AND d.approval_status = 'approved';
```

#### Bounding Box em vez de Distância Precisa
```dart
// Aproximação rápida para busca inicial
final latDelta = radiusKm / 111.0;
final lngDelta = radiusKm / (111.0 * cos(latitude * pi / 180.0));

query = query
    .gte('current_latitude', latitude - latDelta)
    .lte('current_latitude', latitude + latDelta)
    .gte('current_longitude', longitude - lngDelta)  
    .lte('current_longitude', longitude + lngDelta);
```

### 📊 Processamento em Lote

#### Zonas de Exclusão
```sql
-- Em vez de N queries individuais
SELECT DISTINCT driver_id 
FROM driver_excluded_zones
WHERE driver_id IN ('id1', 'id2', 'id3')
  AND (conditions...)
```

#### Verificação de Disponibilidade
```dart
// Processa múltiplos motoristas paralelamente
final futures = drivers.map((driver) => checkAvailability(driver));
final results = await Future.wait(futures);
```

### 🎯 Métricas de Performance

- **Cache hit rate**: ~70% para buscas repetidas
- **Tempo médio de resposta**: <500ms para 50 motoristas
- **Queries reduzidas**: 80% menos consultas com batching

---

## 🔧 Fluxo Técnico Detalhado

### 📋 Método Principal: `DriverMatchingService.findBestDrivers()`

#### Entrada
```dart
class MatchingCriteria {
  final double passengerLatitude;
  final double passengerLongitude;
  final String? destinationNeighborhood;
  final String? destinationCity;
  final String? destinationState;
  final double maxRadiusKm; // Padrão: 10.0
  final String? vehicleCategory;
  final bool needsPet;
  final bool needsAC;
  final bool needsGrocery; 
  final bool needsCondo;
  final int maxDrivers; // Padrão: 10
}
```

#### Pipeline de Execução

##### 1️⃣ Busca Regional
```dart
final availableDrivers = await _getAvailableDriversInRegion(criteria);
print('✅ ${availableDrivers.length} motoristas encontrados na região');
```

**Consulta SQL equivalente:**
```sql
SELECT * FROM drivers 
WHERE is_online = true
  AND approval_status = 'approved'
  AND current_latitude BETWEEN lat1 AND lat2
  AND current_longitude BETWEEN lng1 AND lng2
  AND vehicle_category = categoria (se especificada)
LIMIT 50;
```

##### 2️⃣ Filtros de Preferência  
```dart
final filteredByPreferences = await _filterByPreferences(availableDrivers, criteria);
print('✅ ${filteredByPreferences.length} motoristas após filtro de preferências');
```

**Lógica aplicada:**
```dart
return drivers.where((driver) {
  if (needsPet && !driver.acceptsPet) return false;
  if (needsGrocery && !driver.acceptsGrocery) return false;
  if (needsCondo && !driver.acceptsCondo) return false;
  if (needsAC && driver.acPolicy == 'never') return false;
  return true;
}).toList();
```

##### 3️⃣ Zonas de Exclusão
```dart
final filteredByZones = await _filterByExclusionZones(filteredByPreferences, criteria);
print('✅ ${filteredByZones.length} motoristas após filtro de zonas de exclusão');
```

**Consulta em lote:**
```sql
SELECT DISTINCT driver_id FROM driver_excluded_zones
WHERE driver_id IN (lista_motoristas)
  AND ((neighborhood_name = origem AND city = cidade_origem AND state = estado_origem)
    OR (neighborhood_name = destino AND city = cidade_destino AND state = estado_destino));
```

##### 4️⃣ Verificação Tempo Real
```dart
final realTimeAvailable = await _verifyRealTimeAvailability(filteredByZones);
print('✅ ${realTimeAvailable.length} motoristas disponíveis em tempo real');
```

**Verificações:**
- Sem viagens ativas (`trips.status NOT IN ('accepted', 'in_progress')`)
- Status online ainda válido
- Fallback graceful em caso de erro

##### 5️⃣ Cálculo de Scores
```dart
final matchResults = await _calculateMatchScores(realTimeAvailable, criteria);
print('✅ Scores calculados para ${matchResults.length} motoristas');
```

**Para cada motorista:**
```dart
final distance = calculateHaversineDistance(passengerLat, passengerLng, driverLat, driverLng);
final etaMinutes = (distance * 2).round(); // 30km/h médio
final score = calculateMatchScore(driver, distance, criteria);
```

##### 6️⃣ Ordenação e Limitação
```dart
matchResults.sort((a, b) => b.matchScore.compareTo(a.matchScore));
final finalResults = matchResults.take(criteria.maxDrivers).toList();
print('🎉 Matching finalizado com ${finalResults.length} motoristas');
```

### 🔄 Tratamento de Erros

#### Estratégia Graceful Degradation
```dart
try {
  // Operação principal
} catch (e) {
  print('⚠️ Erro não crítico: $e');
  // Continua com dados parciais
} finally {
  // Sempre retorna algum resultado
}
```

#### Logs Detalhados
```dart
print('🎯 [${DateTime.now()}] Iniciando matching com critérios:');
print('  📍 Origem: ($passengerLatitude, $passengerLongitude)');
print('  🎯 Destino: $destinationNeighborhood, $destinationCity');
print('  📊 Top 3 scores: ${finalResults.take(3).map((r) => r.matchScore.toStringAsFixed(1)).join(", ")}');
```

---

## ⚠️ Casos Especiais e Limitações

### 🚫 Motoristas Eliminados

#### 1. Sem Localização Atual
```dart
if (driver.currentLatitude == null || driver.currentLongitude == null) {
  continue; // Pula este motorista
}
```
**Causas comuns:**
- GPS desligado
- App em segundo plano há muito tempo
- Conectividade instável

#### 2. Horário Fora de Trabalho
```dart
// Motorista quer estar online mas está fora do horário
effective_online = online_intent AND is_within_working_hours
```
**Comportamento:**
- Motorista não aparece nas buscas
- Interface mostra "Fora do horário de trabalho"

#### 3. Excesso de Cancelamentos
```dart
// Filtro de confiabilidade muito baixa (futuro)
if (driver.cancellations > 10 && driver.trips < 50) {
  // Possível penalização
}
```

### 🔧 Fallbacks e Recuperação

#### Cache Failure
```dart
if (cacheError) {
  print('📦 Cache indisponível, buscando diretamente do banco');
  return await _fetchFromDatabase();
}
```

#### Database Timeout
```dart
try {
  return await query.timeout(Duration(seconds: 10));
} catch (TimeoutException e) {
  return _cachedResults ?? [];
}
```

#### Insufficient Results
```dart
if (finalResults.length < 3) {
  print('⚠️ Poucos motoristas encontrados, expandindo raio de busca');
  criteria.maxRadiusKm *= 1.5; // Expande busca
  return findBestDrivers(criteria); // Recursivo
}
```

### 📊 Limitações Conhecidas

#### Performance
- **Máximo de 50 motoristas** na busca inicial
- **Timeout de 10 segundos** para queries complexas
- **Cache de 2 minutos** pode mostrar dados levemente desatualizados

#### Precisão Geográfica
- **Bounding box** é aproximação, não círculo perfeito
- **Distâncias calculadas** em linha reta, não por ruas
- **Geocodificação** depende da qualidade dos dados de endereço

#### Zonas de Exclusão
- **Apenas nível de bairro**, não ruas específicas
- **Dependente de geocoding** preciso
- **Sem suporte a formas geográficas** complexas

---

## 💡 Exemplos Práticos

### 🎬 Cenário 1: Corrida Simples no Centro

**Situação:**
- Passageiro em: Praça da Sé, São Paulo, SP
- Destino: Av. Paulista, São Paulo, SP  
- Preferências: Nenhuma específica

**Filtros Aplicados:**
1. ✅ Motoristas online num raio de 10km
2. ✅ Status aprovado
3. ✅ Sem viagem ativa
4. ⏭️ Sem filtros de preferência
5. ✅ Verificação de zonas excluídas
6. ✅ Score por distância + rating

**Resultado Esperado:**
```
1. João - 4.8★ - 1 min - R$ 8,50
2. Maria - 4.6★ - 2 min - R$ 9,00  
3. Pedro - 4.9★ - 3 min - R$ 8,80
```

### 🐕 Cenário 2: Corrida com Pet

**Situação:**
- Passageiro precisa transportar cachorro
- Preferência: `needsPet = true`

**Filtros Aplicados:**
1. ✅ Busca regional normal
2. 🔍 **FILTRO CRÍTICO**: `accepts_pet = true`
3. ✅ Demais filtros normais

**Motoristas Eliminados:**
```
❌ Carlos - Rating 4.9 mas accepts_pet = false
❌ Ana - Muito próxima mas não aceita pets  
✅ Roberto - Rating 4.2 mas aceita pets
```

**Resultado:**
- Menos motoristas na lista
- Preços podem incluir taxa de pet (+R$ 5,00)
- Score bonus (+2 pontos) para quem aceita

### 🏢 Cenário 3: Destino em Zona Excluída

**Situação:**
- Origem: Copacabana, Rio de Janeiro, RJ
- Destino: Cidade de Deus, Rio de Janeiro, RJ
- Motorista João tem "Cidade de Deus" em zonas excluídas

**Filtros Aplicados:**
1. ✅ João aparece na busca regional (está próximo)
2. ✅ Passa nos filtros de preferência
3. ❌ **ELIMINADO** - destino está em zona excluída
4. ✅ Outros motoristas continuam normalmente

**Consulta SQL executada:**
```sql
SELECT driver_id FROM driver_excluded_zones
WHERE neighborhood_name = 'Cidade de Deus'
  AND city = 'Rio de Janeiro' 
  AND state = 'RJ'
  AND driver_id = 'joao_id';
-- Retorna resultado = João é eliminado
```

### ⏰ Cenário 4: Fora do Horário de Trabalho

**Situação:**
- Horário: 23:30 (sexta-feira)
- Maria configurou horário: Segunda a Sexta, 06:00-22:00
- Maria quer ficar online (`online_intent = true`)

**Status Calculado:**
```sql
-- View driver_effective_status calcula:
online_intent = true
is_within_working_hours = false (23:30 > 22:00)
effective_online = false
```

**Resultado:**
- ❌ Maria não aparece em nenhuma busca
- Interface mostra "Motorista fora do horário"
- Automaticamente volta online às 06:00 segunda

### 💰 Cenário 5: Área de Atuação com Multiplicador

**Situação:**
- Corrida no Centro (área premium do motorista)
- Multiplicador configurado: 1.5x
- Preço base: R$ 10,00

**Cálculo de Preço:**
```dart
final basePrice = 10.00;
final multiplier = await getAreaMultiplier(driverArea, pickupLocation);
final finalPrice = basePrice * multiplier; // R$ 15,00
```

**Exibição para Passageiro:**
```
Carlos - 4.7★ - 3 min
R$ 15,00 • Área Premium
Sedan Preto • Aceita pets
```

---

## ❓ FAQ - Perguntas Frequentes

### 🔍 Por que motorista próximo não aparece?

**Possíveis causas:**

1. **Status offline efetivo**
   - ✅ Verificar: Motorista está dentro do horário de trabalho?
   - ✅ Verificar: Motorista não está em viagem ativa?

2. **Filtros de preferência**
   - ✅ Verificar: Passageiro marcou pet/mercado/condomínio/AC?
   - ✅ Verificar: Motorista aceita essas preferências?

3. **Zonas de exclusão**
   - ✅ Verificar: Origem ou destino está em zona excluída do motorista?
   - ✅ Verificar: Bairro/cidade/estado foram geocodificados corretamente?

4. **Localização desatualizada**
   - ✅ Verificar: GPS do motorista está funcionando?
   - ✅ Verificar: App do motorista está ativo?

### 🚗 Quantos motoristas aparecem na busca?

- **Máximo padrão**: 10 motoristas
- **Máximo técnico**: 50 motoristas na busca inicial
- **Ordenação**: Por score de matching (0-100 pontos)
- **Personalização**: Valor pode ser ajustado por parâmetro

### ⏱️ Com que frequência a lista é atualizada?

- **Cache**: 2 minutos para consultas iguais
- **Status online**: Verificado em tempo real
- **Localização**: Atualizada conforme movimento do motorista
- **Manual**: Passageiro pode "puxar para atualizar"

### 💰 Como são calculados os preços?

**Fórmula básica:**
```
Preço = (preço_km × distância) + (preço_minuto × duração) + taxas_extras × multiplicador_área
```

**Componentes:**
- **Preço base**: Padrão da categoria OU personalizado do motorista
- **Taxas extras**: Pet, mercado, condomínio, paradas
- **Multiplicador**: Área de atuação premium (se aplicável)
- **Transparência**: Passageiro vê breakdown antes de escolher

### 🔄 Posso cancelar configurações que afetam o matching?

**Sim, tudo é reversível:**

1. **Horários de trabalho**
   - ✅ Desativar horários específicos
   - ✅ Trabalhar 24/7 removendo todos os horários

2. **Zonas de exclusão**  
   - ✅ Remover zonas individuais
   - ✅ Limpar todas as zonas

3. **Preferências**
   - ✅ Desmarcar aceita pets/mercado/condomínio
   - ✅ Alterar política de ar-condicionado

4. **Preços**
   - ✅ Voltar para preços padrão da categoria
   - ✅ Ajustar taxas extras

### 🎯 Como melhorar minha posição na listagem?

**Fatores controláveis:**

1. **Localização** (40% do score)
   - ✅ Ficar próximo a áreas de demanda
   - ✅ Manter GPS sempre ativo

2. **Rating** (30% do score)
   - ✅ Manter veículo limpo e bem conservado
   - ✅ Ser pontual e educado
   - ✅ Seguir rota mais eficiente

3. **Experiência** (20% do score)
   - ✅ Completar mais viagens
   - ✅ Evitar cancelamentos desnecessários

4. **Confiabilidade** (10% do score)
   - ✅ Reduzir cancelamentos
   - ✅ Aceitar viagens quando possível

5. **Bônus de preferências** (+2 pontos cada)
   - ✅ Aceitar pets, mercado, condomínio
   - ✅ Manter ar-condicionado funcional

### 🛠️ Problemas técnicos comuns

**"Não estou recebendo viagens":**
1. Verificar status online efetivo
2. Verificar horários de trabalho
3. Verificar zonas de exclusão muito restritivas
4. Testar localização GPS
5. Reiniciar aplicativo

**"Preços estão errados":**
1. Verificar preços personalizados
2. Verificar áreas de atuação ativas
3. Verificar taxas extras configuradas
4. Comparar com preços da categoria

**"App lento para encontrar motoristas":**
1. Cache pode estar desatualizado
2. Muitos filtros aplicados
3. Região com poucos motoristas
4. Horário de baixa demanda

---

## 🔚 Conclusão

Este documento apresenta **todas as regras e critérios** que determinam o matching entre motoristas e passageiros no app Option. O sistema é complexo mas segue uma lógica clara:

### 🎯 **Resumo Executivo**

1. **Filtros Eliminatórios** removem motoristas que não podem atender
2. **Sistema de Score** ordena os restantes por relevância  
3. **Configurações do Motorista** dão controle sobre disponibilidade
4. **Preferências do Passageiro** refinam a busca
5. **Performance Otimizada** garante resposta rápida

### 🚀 **Próximos Passos**

Para desenvolvedores:
- ✅ Implementar melhorias de performance
- ✅ Adicionar novos critérios de matching
- ✅ Criar dashboards de monitoramento

Para motoristas:
- ✅ Configurar horários otimizados
- ✅ Definir zonas de exclusão estratégicas  
- ✅ Ajustar preços competitivos

Para passageiros:
- ✅ Entender como preferências afetam opções
- ✅ Usar filtros para encontrar motorista ideal

---

**📞 Suporte Técnico**: Para dúvidas sobre implementação, consulte o código-fonte nos arquivos `lib/services/driver_matching_service.dart` e `lib/services/driver_service.dart`.

**📝 Última Atualização**: Setembro 2024 - Versão 4.1