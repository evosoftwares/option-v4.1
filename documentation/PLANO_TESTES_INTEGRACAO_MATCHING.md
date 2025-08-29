# Plano de Testes de Integração - Sistema de Matching Direcionado

## Objetivo
Validar o funcionamento completo do sistema de matching direcionado, desde a seleção do motorista até a resposta da solicitação.

## Pré-requisitos

### Ambiente de Teste
- Aplicativo compilado com sucesso (✓ Verificado)
- Conexão com Supabase configurada
- Dados de teste preparados no banco
- Pelo menos 2 dispositivos ou emuladores (passageiro e motorista)

### Dados de Teste Necessários

#### Usuários de Teste
```sql
-- Passageiro de teste
INSERT INTO users (id, email, phone, user_type, name) VALUES 
('test-passenger-001', 'passenger@test.com', '+5511999999001', 'passenger', 'Passageiro Teste');

-- Motoristas de teste
INSERT INTO users (id, email, phone, user_type, name) VALUES 
('test-driver-001', 'driver1@test.com', '+5511999999002', 'driver', 'Motorista Teste 1'),
('test-driver-002', 'driver2@test.com', '+5511999999003', 'driver', 'Motorista Teste 2'),
('test-driver-003', 'driver3@test.com', '+5511999999004', 'driver', 'Motorista Teste 3');
```

#### Motoristas Disponíveis
```sql
-- Configurar motoristas como disponíveis
INSERT INTO drivers (user_id, status, latitude, longitude, category_id, is_available) VALUES 
('test-driver-001', 'available', -23.5505, -46.6333, 1, true),
('test-driver-002', 'available', -23.5515, -46.6343, 1, true),
('test-driver-003', 'available', -23.5525, -46.6353, 2, true);
```

## Cenários de Teste

### Cenário 1: Fluxo Completo de Matching Direcionado

#### Objetivo
Validar o fluxo completo desde a seleção do motorista até a aceitação da viagem.

#### Passos
1. **Login como Passageiro**
   - Fazer login com `passenger@test.com`
   - Verificar se a tela inicial carrega corretamente

2. **Solicitar Viagem**
   - Definir origem: "Av. Paulista, 1000"
   - Definir destino: "Shopping Ibirapuera"
   - Selecionar categoria de veículo
   - Confirmar solicitação

3. **Tela de Seleção de Motoristas**
   - Verificar se a lista de motoristas é exibida
   - Verificar se as informações estão corretas (nome, distância, ETA, preço)
   - Selecionar um motorista específico

4. **Criação da Solicitação Direcionada**
   - Verificar se `TripRequestManager.createDirectedTripRequest` é chamado
   - Verificar se a navegação para `WaitingDriverScreen` ocorre
   - Verificar se o `tripRequestId` é passado corretamente

5. **Tela de Espera**
   - Verificar se o status inicial é "searching"
   - Verificar se as informações da viagem são exibidas
   - Verificar se o monitoramento de status é iniciado

6. **Resposta do Motorista (Simulada)**
   - Simular aceitação via banco de dados:
   ```sql
   UPDATE trip_requests 
   SET status = 'accepted', accepted_by_driver_id = 'test-driver-001'
   WHERE id = '[trip_request_id]';
   ```

7. **Navegação para Tela da Viagem**
   - Verificar se a navegação para `PassengerTripScreen` ocorre
   - Verificar se os dados da viagem são passados corretamente

#### Critérios de Sucesso
- ✅ Todos os passos executam sem erros
- ✅ Dados são persistidos corretamente no banco
- ✅ Navegação entre telas funciona
- ✅ Status da solicitação é atualizado em tempo real

### Cenário 2: Fallback para Matching Geral

#### Objetivo
Validar o comportamento quando o motorista selecionado não aceita a viagem.

#### Passos
1. Repetir passos 1-5 do Cenário 1
2. **Simular Rejeição do Motorista**
   ```sql
   UPDATE trip_requests 
   SET status = 'fallback'
   WHERE id = '[trip_request_id]';
   ```
3. **Verificar Fallback**
   - Status deve mudar para "expanding_search"
   - Sistema deve iniciar matching geral

#### Critérios de Sucesso
- ✅ Status é atualizado para fallback
- ✅ Matching geral é iniciado automaticamente
- ✅ Passageiro é notificado da mudança

### Cenário 3: Cancelamento da Solicitação

#### Objetivo
Validar o cancelamento da solicitação direcionada.

#### Passos
1. Repetir passos 1-5 do Cenário 1
2. **Cancelar Viagem**
   - Tocar no botão "Cancelar viagem"
   - Confirmar cancelamento

3. **Verificar Cancelamento**
   - Status deve ser atualizado para "cancelled"
   - Navegação deve retornar à tela inicial
   - Monitoramento deve ser interrompido

#### Critérios de Sucesso
- ✅ Status é atualizado para cancelled
- ✅ Navegação retorna à tela inicial
- ✅ Recursos são liberados corretamente

### Cenário 4: Teste de Performance

#### Objetivo
Validar a performance do sistema com múltiplas solicitações.

#### Passos
1. Criar 10 solicitações direcionadas simultaneamente
2. Monitorar tempo de resposta
3. Verificar uso de memória
4. Verificar se há vazamentos de recursos

#### Critérios de Sucesso
- ✅ Tempo de resposta < 3 segundos
- ✅ Uso de memória estável
- ✅ Sem vazamentos de recursos

## Validação de Dados

### Verificações no Banco de Dados

#### Estrutura da Tabela trip_requests
```sql
-- Verificar se os novos campos existem
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'trip_requests' 
AND column_name IN ('target_driver_id', 'fallback_drivers', 'accepted_by_driver_id');
```

#### Dados da Solicitação
```sql
-- Verificar dados da solicitação criada
SELECT 
  id,
  passenger_id,
  target_driver_id,
  status,
  created_at,
  pickup_latitude,
  pickup_longitude,
  destination_latitude,
  destination_longitude,
  estimated_price
FROM trip_requests 
WHERE id = '[trip_request_id]';
```

### Logs de Debug

#### TripRequestManager
- Verificar logs de criação da solicitação
- Verificar logs de monitoramento de status
- Verificar logs de notificações

#### Telas
- Verificar logs de navegação
- Verificar logs de atualização de estado
- Verificar logs de dispose de recursos

## Ferramentas de Teste

### Flutter Inspector
- Monitorar árvore de widgets
- Verificar vazamentos de memória
- Analisar performance de renderização

### Supabase Dashboard
- Monitorar queries em tempo real
- Verificar logs de autenticação
- Analisar performance do banco

### Logs do Aplicativo
- Configurar logging detalhado
- Capturar erros e exceções
- Monitorar fluxo de dados

## Checklist de Execução

### Preparação
- [ ] Ambiente de teste configurado
- [ ] Dados de teste inseridos
- [ ] Aplicativo compilado e instalado
- [ ] Dispositivos/emuladores preparados

### Execução dos Cenários
- [ ] Cenário 1: Fluxo Completo
- [ ] Cenário 2: Fallback
- [ ] Cenário 3: Cancelamento
- [ ] Cenário 4: Performance

### Validação
- [ ] Dados no banco verificados
- [ ] Logs analisados
- [ ] Performance medida
- [ ] Recursos liberados corretamente

### Documentação
- [ ] Resultados documentados
- [ ] Bugs identificados e reportados
- [ ] Melhorias sugeridas
- [ ] Próximos passos definidos

## Critérios de Aceitação

O sistema será considerado aprovado se:

1. **Funcionalidade**: Todos os cenários principais executam com sucesso
2. **Performance**: Tempo de resposta dentro dos limites aceitáveis
3. **Estabilidade**: Sem crashes ou vazamentos de memória
4. **Dados**: Persistência e sincronização corretas
5. **UX**: Navegação fluida e feedback adequado ao usuário

## Próximos Passos

Após a conclusão dos testes:

1. **Correção de Bugs**: Resolver problemas identificados
2. **Otimizações**: Implementar melhorias de performance
3. **Testes Automatizados**: Criar testes automatizados para CI/CD
4. **Deploy**: Preparar para deploy em produção
5. **Monitoramento**: Configurar monitoramento em produção

---

**Data de Criação**: $(date)
**Versão**: 1.0
**Responsável**: Equipe de Desenvolvimento