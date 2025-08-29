# Plano de Correção: Sistema de Matching e Fluxo de Viagens

## 📋 Análise da Situação Atual

### ✅ O que já funciona bem:
- **Tela de seleção de motoristas** (`driver_selection_screen.dart`) - UI completa
- **Serviço de busca de motoristas** (`driver_service.dart`) - Funcional com filtros básicos
- **Cálculo de preços individuais** (`IndividualPricingService`) - Já implementado
- **Estruturas de dados** - Tabelas e modelos existem
- **Sistema de Trip Service** - Base sólida implementada

### ❌ Gaps Críticos Identificados:

1. **Sistema de Matching Direcionado**: Atual é "primeiro que aceita" vs esperado "seleção direcionada"
2. **Interface de Solicitações para Motoristas**: Não existe
3. **Sistema de Timeout/Fallback**: Ausente
4. **Fluxo de Estados de Viagem**: Incompleto
5. **Notificações Push**: Não integradas ao matching

---

## 🎯 Plano de Implementação

### **FASE 1: Correção do Sistema de Matching (2-3 semanas)**

#### 1.1 Modificar Estrutura de TripRequest
```sql
-- Adicionar campos na tabela trip_requests
ALTER TABLE trip_requests ADD COLUMN target_driver_id UUID REFERENCES drivers(id);
ALTER TABLE trip_requests ADD COLUMN expires_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE trip_requests ADD COLUMN fallback_drivers UUID[];
ALTER TABLE trip_requests ADD COLUMN accepted_by_driver_id UUID REFERENCES drivers(id);
ALTER TABLE trip_requests ADD COLUMN accepted_at TIMESTAMP WITH TIME ZONE;
```

#### 1.2 Criar TripRequestManager Service
**Arquivo:** `lib/services/trip_request_manager.dart`

**Funcionalidades:**
- Enviar solicitação direcionada a motorista específico
- Gerenciar timeout de 10 segundos
- Fallback automático para próximo motorista
- Notificações push integradas

#### 1.3 Atualizar Driver Selection Screen
**Modificações em** `lib/screens/trip/driver_selection_screen.dart`:
- Implementar seleção direcionada (já está funcionando visualmente)
- Integrar com novo TripRequestManager
- Gerar lista de fallback drivers ordenada por proximidade

#### 1.4 Criar Interface de Solicitações para Motoristas
**Novos arquivos:**
- `lib/screens/driver/driver_requests_screen.dart`
- `lib/widgets/trip_request_card.dart`
- `lib/services/driver_request_notification_service.dart`

**Funcionalidades:**
- Lista de solicitações direcionadas ao motorista
- Timer visual de 10 segundos
- Botões aceitar/recusar com UX intuitiva
- Sons e vibrações para alertas

### **FASE 2: Fluxo Completo de Estados de Viagem (1-2 semanas)**

#### 2.1 Implementar Estados de Transição
**Estados necessários:**
1. `pending` → Aguardando aceitação do motorista
2. `accepted` → Motorista aceitou, indo buscar passageiro
3. `driver_arriving` → Motorista a caminho do ponto de embarque
4. `driver_arrived` → Motorista chegou no local de embarque
5. `in_progress` → Viagem em andamento
6. `completed` → Viagem finalizada
7. `cancelled_by_driver` → Cancelada pelo motorista
8. `cancelled_by_passenger` → Cancelada pelo passageiro

#### 2.2 Atualizar Trip Service
**Modificações em** `lib/services/trip_service.dart`:
- Métodos de transição de estados
- Validações de transição (não pode pular estados)
- Timestamps de cada transição
- Notificações automáticas para cada mudança

#### 2.3 Real-time Updates
**Implementar:**
- Stream subscriptions para mudanças de estado
- Sincronização automática entre apps do motorista e passageiro
- Atualização de localização em tempo real durante viagem

### **FASE 3: Sistema de Cancelamento e Taxas (1 semana)**

#### 3.1 Implementar Política de Cancelamento
**Regras baseadas no fluxo de negócio:**
```dart
// Cálculo de taxa de cancelamento
MultaBase = min((PreçoTotalEstimado * 0.20), 10.00)
FatorDeslocamento = DistânciaPercorrida / DistânciaTotalAtéPassageiro
TaxaFinal = MultaBase * FatorDeslocamento
```

#### 3.2 Sistema de No-Show
- Timer de 3 minutos após motorista chegar
- Direito do motorista a TaxaFinal completa
- Interface para reportar no-show

#### 3.3 Sistema de Strikes
- Contador de cancelamentos consecutivos
- Suspensão automática após 3 strikes
- Reset de strikes após viagem completada

---

## 🔧 Implementação Detalhada

### **1. TripRequestManager Service**

```dart
class TripRequestManager {
  static const int ACCEPTANCE_TIMEOUT_SECONDS = 10;
  
  Future<String> sendDirectedRequest({
    required String passengerId,
    required String targetDriverId,
    required List<String> fallbackDrivers,
    required TripRequestData tripData,
  }) async {
    // 1. Criar trip_request com target_driver_id
    // 2. Definir expires_at para 10 segundos
    // 3. Enviar push notification ao motorista
    // 4. Iniciar timeout timer
    // 5. Retornar request_id
  }
  
  Future<void> handleDriverResponse({
    required String requestId,
    required String driverId,
    required bool accepted,
  }) async {
    if (accepted) {
      await _acceptRequest(requestId, driverId);
    } else {
      await _processRejectionOrTimeout(requestId);
    }
  }
  
  Future<void> _processRejectionOrTimeout(String requestId) async {
    // 1. Buscar próximo motorista da lista fallback
    // 2. Se existe próximo: enviar nova solicitação
    // 3. Se não existe: marcar request como expired
    // 4. Notificar passageiro do resultado
  }
}
```

### **2. Driver Requests Screen**

```dart
class DriverRequestsScreen extends StatefulWidget {
  // Tela principal que substitui ou complementa driver_home_screen
  // - Lista de solicitações direcionadas
  // - Timer countdown para cada solicitação
  // - Botões de aceitar/recusar bem visíveis
  // - Sons de alerta para novas solicitações
}

class TripRequestCard extends StatelessWidget {
  // Widget para cada solicitação individual
  // - Informações do passageiro (nome, foto, rating)
  // - Origem e destino
  // - Distância até o passageiro
  // - Valor estimado da corrida
  // - Timer visual contando regressivamente
  // - Botões de ação
}
```

### **3. Modificações no Driver Selection**

```dart
class _DriverSelectionScreenState extends State<DriverSelectionScreen> {
  
  Future<void> _selectDriver(Driver selectedDriver, List<Driver> allDrivers) async {
    // 1. Gerar lista de fallback (outros drivers próximos, ordenados por distância)
    final fallbackDrivers = _generateFallbackList(selectedDriver, allDrivers);
    
    // 2. Usar TripRequestManager em vez de TripService direto
    final requestId = await TripRequestManager().sendDirectedRequest(
      targetDriverId: selectedDriver.id,
      fallbackDrivers: fallbackDrivers.map((d) => d.id).toList(),
      tripData: _buildTripData(),
    );
    
    // 3. Navegar para WaitingDriverScreen com requestId
    Navigator.pushNamed(context, '/waiting_driver', arguments: requestId);
  }
  
  List<Driver> _generateFallbackList(Driver selected, List<Driver> all) {
    return all
        .where((d) => d.id != selected.id)
        .take(5) // Máximo 5 fallback drivers
        .toList();
  }
}
```

### **4. Atualização do Waiting Driver Screen**

```dart
class WaitingDriverScreen extends StatefulWidget {
  // Modificações necessárias:
  // - Mostrar qual motorista está sendo contatado
  // - Progresso visual do fallback (motorista 1 de 3, por exemplo)
  // - Timeout visual para cada tentativa
  // - Feedback quando mudando para próximo motorista
}
```

---

## 📊 Cronograma de Implementação

### **Semana 1-2: Base do Sistema de Matching**
- [ ] Modificar tabela `trip_requests` (campos adicionais)
- [ ] Criar `TripRequestManager` service
- [ ] Implementar sistema de timeout básico
- [ ] Testes unitários do matching

### **Semana 3: Interface do Motorista**
- [ ] Criar `DriverRequestsScreen`
- [ ] Implementar `TripRequestCard` widget
- [ ] Integrar notificações push
- [ ] Adicionar navegação ao `driver_home_screen`

### **Semana 4: Integração e Estados**
- [ ] Modificar `DriverSelectionScreen` para usar novo sistema
- [ ] Implementar transições de estado completas
- [ ] Atualizar `WaitingDriverScreen` com feedback de fallback
- [ ] Testes de integração

### **Semana 5: Sistema de Cancelamento**
- [ ] Implementar cálculo de taxas de cancelamento
- [ ] Sistema de no-show com timer de 3 minutos
- [ ] Sistema de strikes automático
- [ ] Testes de políticas de negócio

### **Semana 6: Polimento e Testes**
- [ ] Testes end-to-end completos
- [ ] Melhorias de UX baseadas em testes
- [ ] Documentação técnica
- [ ] Deploy para ambiente de testes

---

## ⚠️ Considerações Técnicas

### **1. Performance**
- Usar índices apropriados em `target_driver_id` e `expires_at`
- Cache de motoristas próximos para reduzir queries
- Debounce em mudanças de localização

### **2. Reliability**
- Jobs background para limpar requests expirados
- Retry logic para notificações push falhadas
- Fallback para sistema antigo se novo falhar

### **3. Monitoramento**
- Métricas de tempo de resposta dos motoristas
- Taxa de sucesso do matching direcionado vs genérico
- Logs detalhados para debug do fluxo

### **4. Rollback Strategy**
- Feature flags para habilitar/desabilitar novo sistema
- Manter sistema antigo funcionando em paralelo
- Migração gradual por cidade/região

---

## 🎯 Resultados Esperados

### **Melhorias na UX:**
- **Passageiros**: Feedback claro sobre qual motorista está sendo contatado
- **Motoristas**: Interface dedicada para solicitações com timeout claro
- **Ambos**: Menos tempo de espera e maior taxa de sucesso

### **Alinhamento com Regras de Negócio:**
- ✅ Seleção direcionada a motorista específico
- ✅ Sistema de fallback automático
- ✅ Timeout de 10 segundos por motorista
- ✅ Preços individuais por motorista
- ✅ Lista de 10 motoristas mais próximos

### **Métricas de Sucesso:**
- Redução de 50%+ no tempo médio de matching
- Aumento de 30%+ na taxa de aceitação de viagens
- Redução de 40%+ em cancelamentos por timeout
- 95%+ de disponibilidade do sistema de matching

---

## 📝 Próximos Passos

1. **Aprovação do Plano**: Review técnico e de negócio
2. **Setup do Ambiente**: Branches, feature flags, ambiente de testes
3. **Kick-off da Implementação**: Começar pela Fase 1
4. **Testes Paralelos**: Implementar junto com desenvolvimento
5. **Deploy Gradual**: Rollout por região/cidade

---

**Estimativa Total**: 5-6 semanas para implementação completa  
**Criticidade**: Alta - Funcionalidade core do negócio  
**Risco**: Médio - Mudanças significativas, mas com rollback strategy  

Este plano transforma o sistema atual de "primeiro que aceita" para "seleção direcionada com fallback", alinhando completamente com o fluxo de negócio documentado.