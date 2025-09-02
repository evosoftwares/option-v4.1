# Decisões Técnicas - Sistema de Horários de Trabalho

## Visão Geral

Este documento registra as principais decisões técnicas tomadas durante o desenvolvimento do sistema de horários de trabalho para motoristas.

## Decisões de Arquitetura

### 1. Sem Fuso Horário (Timezone)

**Decisão**: Utilizar `now()` do servidor sem consideração de fuso horário.

**Justificativa**:
- Simplificação da implementação
- Evita complexidade de conversões de timezone
- Assume que todos os motoristas operam no mesmo fuso horário do servidor
- Reduz possibilidade de bugs relacionados a conversões de tempo

**Implementação**:
- Uso de `now()` nas views SQL
- Horários armazenados como strings no formato `HH:mm:ss`
- Comparações de tempo baseadas em minutos desde meia-noite

### 2. Sem Controle de Concorrência

**Decisão**: Atualização simples sem controle de versão ou locks.

**Justificativa**:
- Cenário de uso não requer alta concorrência
- Motoristas geralmente atualizam seus próprios horários
- Simplifica a implementação e reduz complexidade
- Conflitos são raros no contexto de uso

**Implementação**:
- Atualizações diretas na tabela `driver_status`
- Sem campos de versão ou timestamp de controle
- Trigger automático para `updated_at`

### 3. Limites de Horário

**Decisão**: Início inclusivo, fim exclusivo.

**Justificativa**:
- Padrão comum em sistemas de tempo
- Evita sobreposição entre intervalos consecutivos
- Facilita cálculos de duração
- Comportamento intuitivo para usuários

**Implementação**:
```sql
-- Exemplo: horário 09:00 às 17:00
-- Inclui 09:00:00, exclui 17:00:00
CURRENT_TIME >= start_time AND CURRENT_TIME < end_time
```

### 4. Casos que Cruzam Meia-Noite

**Decisão**: Suporte nativo para horários que cruzam meia-noite.

**Justificativa**:
- Necessário para turnos noturnos
- Implementação através de lógica OR na view
- Mantém simplicidade do modelo de dados

**Implementação**:
```sql
-- Para horários como 22:00 às 06:00
(start_time <= end_time AND CURRENT_TIME >= start_time AND CURRENT_TIME < end_time)
OR
(start_time > end_time AND (CURRENT_TIME >= start_time OR CURRENT_TIME < end_time))
```

### 5. Múltiplos Intervalos por Dia

**Decisão**: Permitir múltiplos registros por motorista/dia.

**Justificativa**:
- Flexibilidade para horários fragmentados
- Suporte a pausas longas (ex: almoço)
- Modelo simples sem complicações de arrays

**Implementação**:
- Tabela `working_hours` permite múltiplos registros
- View agrega com `EXISTS` para verificar se está em qualquer intervalo
- Interface permite adicionar/remover intervalos independentemente

### 6. Comportamento na Ausência de Horários

**Decisão**: Motorista sem horários cadastrados = sempre offline.

**Justificativa**:
- Comportamento seguro (opt-in)
- Força configuração explícita de horários
- Evita motoristas "sempre online" por engano
- Facilita debugging e suporte

**Implementação**:
```sql
-- Se não existir horário para hoje, effective_online = false
effective_online = online_intent AND EXISTS (
  SELECT 1 FROM working_hours 
  WHERE driver_id = ds.driver_id 
  AND day_of_week = EXTRACT(DOW FROM NOW())
  AND dentro_do_horario_logic
)
```

## Estrutura de Dados

### Tabela `working_hours`
```sql
CREATE TABLE working_hours (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID NOT NULL REFERENCES drivers(id),
  day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Tabela `driver_status`
```sql
CREATE TABLE driver_status (
  driver_id UUID PRIMARY KEY REFERENCES drivers(id),
  online_intent BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### View `driver_effective_status`
```sql
CREATE VIEW driver_effective_status AS
SELECT 
  ds.driver_id,
  ds.online_intent,
  ds.updated_at,
  (
    ds.online_intent AND EXISTS (
      SELECT 1 FROM working_hours wh
      WHERE wh.driver_id = ds.driver_id
      AND wh.day_of_week = EXTRACT(DOW FROM NOW())
      AND (
        (wh.start_time <= wh.end_time AND CURRENT_TIME >= wh.start_time AND CURRENT_TIME < wh.end_time)
        OR
        (wh.start_time > wh.end_time AND (CURRENT_TIME >= wh.start_time OR CURRENT_TIME < wh.end_time))
      )
    )
  ) AS effective_online
FROM driver_status ds;
```

## Validações

### No Aplicativo
- Horário de início deve ser diferente do horário de fim
- Não permitir sobreposição de intervalos no mesmo dia
- Validação de formato de tempo (HH:mm)
- Verificação antes de ativar status online

### No Banco de Dados
- Constraints de integridade referencial
- Check constraints para day_of_week (0-6)
- Trigger para updated_at automático

## Considerações de Performance

### Índices Recomendados
```sql
-- Para consultas frequentes na view
CREATE INDEX idx_working_hours_driver_day ON working_hours(driver_id, day_of_week);
CREATE INDEX idx_driver_status_online ON driver_status(online_intent) WHERE online_intent = true;
```

### Otimizações
- View materializada pode ser considerada para alta carga
- Cache de horários no aplicativo para reduzir consultas
- Batch updates para múltiplos motoristas

## Limitações Conhecidas

1. **Fuso Horário**: Sistema não suporta motoristas em fusos diferentes
2. **Concorrência**: Atualizações simultâneas podem se sobrescrever
3. **Histórico**: Não mantém histórico de mudanças de horários
4. **Exceções**: Não suporta feriados ou dias especiais
5. **Granularidade**: Limitado a minutos (não suporta segundos)

## Melhorias Futuras

1. Suporte a fuso horário por motorista
2. Histórico de alterações de horários
3. Suporte a exceções (feriados, folgas)
4. Interface para administradores gerenciarem horários
5. Relatórios de disponibilidade
6. Notificações automáticas de mudanças de status

## Testes Implementados

### Testes Unitários (`working_hours_service_test.dart`)
- Parsing de horários
- Formatação de tempo
- Lógica de horários normais e que cruzam meia-noite
- Casos extremos (00:00, 23:59)
- Nomes de dias da semana

### Testes de Widget (`working_hours_screen_test.dart`)
- Exibição de horários
- Indicadores de status
- Conversão de TimeOfDay
- Casos extremos de interface

### Casos de Teste Cobertos
- Horários normais (08:00-17:00)
- Horários noturnos (22:00-06:00)
- Múltiplos intervalos por dia
- Ausência de horários
- Bordas de meia-noite (23:59, 00:00)
- Validações de entrada

---

**Data**: Janeiro 2025  
**Versão**: 1.0  
**Autor**: Sistema de Desenvolvimento Option v4.1