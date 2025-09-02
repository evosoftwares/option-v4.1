# Documentação Avançada - Sistema de Horários de Trabalho

## Visão Geral

Este documento fornece uma documentação técnica abrangente do sistema de horários de trabalho, incluindo diagramas de arquitetura, fluxos de dados, guias de manutenção e troubleshooting.

## Arquitetura do Sistema

### Diagrama de Arquitetura (ASCII)

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                       │
├─────────────────────────────────────────────────────────────────┤
│  WorkingHoursScreen          │  WorkingHoursDialog              │
│  ├─ State Management         │  ├─ Modal Display                │
│  ├─ UI Components            │  ├─ Working Hours Info           │
│  ├─ User Interactions        │  └─ Navigation Actions           │
│  └─ Form Validation          │                                  │
├─────────────────────────────────────────────────────────────────┤
│                         SERVICE LAYER                          │
├─────────────────────────────────────────────────────────────────┤
│  WorkingHoursService                                            │
│  ├─ CRUD Operations          │  DriverStatusService             │
│  ├─ Business Logic           │  ├─ Status Validation            │
│  ├─ Data Validation          │  ├─ Working Hours Check          │
│  └─ Exception Handling       │  └─ Real-time Updates            │
├─────────────────────────────────────────────────────────────────┤
│                          DATA LAYER                            │
├─────────────────────────────────────────────────────────────────┤
│  WorkingHours Model          │  Supabase Client                 │
│  ├─ Data Structure           │  ├─ Database Connection          │
│  ├─ JSON Serialization       │  ├─ Query Execution              │
│  ├─ Time Parsing             │  ├─ Transaction Management       │
│  └─ Business Methods         │  └─ Error Handling               │
├─────────────────────────────────────────────────────────────────┤
│                        DATABASE LAYER                          │
├─────────────────────────────────────────────────────────────────┤
│  PostgreSQL Database                                            │
│  ├─ working_hours table      │  ├─ Indexes                      │
│  ├─ drivers table            │  ├─ Triggers                     │
│  ├─ driver_effective_status  │  ├─ Constraints                  │
│  └─ Views & Functions        │  └─ Audit Trail                  │
└─────────────────────────────────────────────────────────────────┘
```

### Componentes Principais

#### 1. Presentation Layer
- **WorkingHoursScreen**: Interface principal para configuração de horários
- **WorkingHoursDialog**: Modal de aviso quando motorista tenta trabalhar fora do horário

#### 2. Service Layer
- **WorkingHoursService**: Gerencia operações CRUD e lógica de negócio
- **DriverStatusService**: Controla status do motorista baseado nos horários

#### 3. Data Layer
- **WorkingHours Model**: Representa a estrutura de dados
- **Supabase Client**: Interface com o banco de dados

#### 4. Database Layer
- **PostgreSQL**: Armazenamento persistente com views e triggers

## Fluxos de Dados

### Fluxo 1: Configuração de Horários

```
[Motorista] → [WorkingHoursScreen] → [WorkingHoursService] → [Supabase] → [PostgreSQL]
     │                │                        │                │           │
     │                │                        │                │           │
     ▼                ▼                        ▼                ▼           ▼
1. Acessa tela   2. Carrega dados      3. Executa query   4. Conecta DB  5. Persiste
   de horários      existentes            getWorkingHours     com client     dados
     │                │                        │                │           │
     │                │                        │                │           │
     ▼                ▼                        ▼                ▼           ▼
6. Modifica      7. Valida dados       8. Executa batch   9. Transação   10. Confirma
   horários         no frontend           delete/insert      atômica        operação
```

### Fluxo 2: Verificação de Status

```
[Sistema] → [DriverStatusService] → [WorkingHoursService] → [Supabase] → [PostgreSQL]
     │              │                        │                  │           │
     │              │                        │                  │           │
     ▼              ▼                        ▼                  ▼           ▼
1. Timer      2. Verifica status      3. Busca horários   4. Query DB   5. Retorna
   periódico     de motoristas           do motorista        otimizada     resultados
     │              │                        │                  │           │
     │              │                        │                  │           │
     ▼              ▼                        ▼                  ▼           ▼
6. Atualiza   7. Calcula se está     8. Considera        9. Usa view    10. Atualiza
   cache local   dentro do horário      midnight crossing    eficiente      status
```

### Fluxo 3: Validação em Tempo Real

```
[Motorista] → [DriverBottomSheet] → [WorkingHoursDialog] → [WorkingHoursService]
     │               │                      │                      │
     │               │                      │                      │
     ▼               ▼                      ▼                      ▼
1. Tenta ir    2. Verifica horário    3. Mostra aviso       4. Busca horários
   online         atual vs config       se fora do horário     atualizados
     │               │                      │                      │
     │               │                      │                      │
     ▼               ▼                      ▼                      ▼
5. Decide      6. Permite/Bloqueia    7. Oferece opções     8. Navega para
   ação           ação baseado          (ficar offline/       configuração
                  no resultado          ajustar horário)
```

## Estrutura de Dados

### Modelo WorkingHours

```dart
class WorkingHours {
  final String id;              // UUID único
  final String driverId;        // Referência ao motorista
  final int dayOfWeek;          // 0=Domingo, 1=Segunda, ..., 6=Sábado
  final String startTime;       // Formato HH:mm:ss
  final String endTime;         // Formato HH:mm:ss
  final DateTime createdAt;     // Timestamp de criação
  final DateTime updatedAt;     // Timestamp de atualização
}
```

### Schema do Banco de Dados

```sql
-- Tabela principal
CREATE TABLE working_hours (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_working_hours_driver_day ON working_hours(driver_id, day_of_week);
CREATE INDEX idx_working_hours_driver_time ON working_hours(driver_id, start_time, end_time);

-- View para status efetivo
CREATE VIEW driver_effective_status AS
SELECT 
    d.id as driver_id,
    d.user_id,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM working_hours wh 
            WHERE wh.driver_id = d.id 
            AND wh.day_of_week = EXTRACT(DOW FROM NOW())
            AND (
                (wh.start_time <= wh.end_time AND NOW()::TIME BETWEEN wh.start_time AND wh.end_time)
                OR 
                (wh.start_time > wh.end_time AND (NOW()::TIME >= wh.start_time OR NOW()::TIME <= wh.end_time))
            )
        ) THEN true
        ELSE false
    END as is_within_working_hours
FROM drivers d;
```

## Guia de Manutenção

### Tarefas Regulares

#### Diárias
1. **Monitorar logs de erro**
   ```bash
   # Verificar logs do Supabase
   grep "working_hours" /var/log/supabase/postgres.log
   ```

2. **Verificar performance de queries**
   ```sql
   -- Queries mais lentas relacionadas a working_hours
   SELECT query, mean_time, calls 
   FROM pg_stat_statements 
   WHERE query LIKE '%working_hours%' 
   ORDER BY mean_time DESC;
   ```

#### Semanais
1. **Analisar padrões de uso**
   ```sql
   -- Estatísticas de uso por dia da semana
   SELECT 
       day_of_week,
       COUNT(*) as total_configs,
       AVG(EXTRACT(EPOCH FROM (end_time - start_time))/3600) as avg_hours
   FROM working_hours 
   WHERE created_at >= NOW() - INTERVAL '7 days'
   GROUP BY day_of_week
   ORDER BY day_of_week;
   ```

2. **Verificar integridade dos dados**
   ```sql
   -- Verificar horários inválidos
   SELECT * FROM working_hours 
   WHERE start_time = end_time 
   OR start_time IS NULL 
   OR end_time IS NULL;
   ```

#### Mensais
1. **Otimizar índices**
   ```sql
   -- Analisar uso dos índices
   SELECT schemaname, tablename, indexname, idx_tup_read, idx_tup_fetch
   FROM pg_stat_user_indexes 
   WHERE tablename = 'working_hours';
   ```

2. **Limpar dados antigos** (se aplicável)
   ```sql
   -- Arquivar registros muito antigos
   DELETE FROM working_hours 
   WHERE updated_at < NOW() - INTERVAL '2 years'
   AND driver_id NOT IN (SELECT id FROM drivers WHERE is_active = true);
   ```

### Backup e Recuperação

#### Backup dos Dados
```bash
# Backup específico da tabela working_hours
pg_dump -h localhost -U postgres -t working_hours app_db > working_hours_backup.sql

# Backup com dados relacionados
pg_dump -h localhost -U postgres -t working_hours -t drivers app_db > full_backup.sql
```

#### Recuperação
```bash
# Restaurar tabela específica
psql -h localhost -U postgres app_db < working_hours_backup.sql

# Verificar integridade após restauração
psql -h localhost -U postgres app_db -c "SELECT COUNT(*) FROM working_hours;"
```

## Troubleshooting

### Problemas Comuns

#### 1. Motorista não consegue ir online

**Sintomas:**
- Botão "IR" não funciona
- Aparece dialog de horário de trabalho
- Logs mostram "fora do horário"

**Diagnóstico:**
```sql
-- Verificar horários configurados
SELECT * FROM working_hours 
WHERE driver_id = 'DRIVER_ID' 
ORDER BY day_of_week, start_time;

-- Verificar status atual
SELECT * FROM driver_effective_status 
WHERE driver_id = 'DRIVER_ID';

-- Verificar horário atual vs configurado
SELECT 
    NOW()::TIME as current_time,
    EXTRACT(DOW FROM NOW()) as current_day,
    wh.day_of_week,
    wh.start_time,
    wh.end_time
FROM working_hours wh 
WHERE wh.driver_id = 'DRIVER_ID' 
AND wh.day_of_week = EXTRACT(DOW FROM NOW());
```

**Soluções:**
1. Verificar se há horários configurados para o dia atual
2. Verificar se o horário atual está dentro do range
3. Considerar midnight crossing (horários que passam da meia-noite)
4. Verificar timezone do servidor vs cliente

#### 2. Performance lenta na tela de horários

**Sintomas:**
- Tela demora para carregar
- Lag ao alterar horários
- Timeout ao salvar

**Diagnóstico:**
```sql
-- Verificar performance da query principal
EXPLAIN ANALYZE 
SELECT * FROM working_hours 
WHERE driver_id = 'DRIVER_ID' 
ORDER BY day_of_week, start_time;

-- Verificar estatísticas da tabela
SELECT 
    schemaname,
    tablename,
    n_tup_ins,
    n_tup_upd,
    n_tup_del,
    n_live_tup,
    n_dead_tup
FROM pg_stat_user_tables 
WHERE tablename = 'working_hours';
```

**Soluções:**
1. Verificar se os índices estão sendo usados
2. Executar VACUUM ANALYZE na tabela
3. Considerar implementar cache no frontend
4. Otimizar queries com LIMIT quando apropriado

#### 3. Dados inconsistentes

**Sintomas:**
- Horários salvos não aparecem
- Conflitos de horário não detectados
- Status incorreto do motorista

**Diagnóstico:**
```sql
-- Verificar conflitos de horário
SELECT 
    wh1.id as id1,
    wh2.id as id2,
    wh1.day_of_week,
    wh1.start_time,
    wh1.end_time,
    wh2.start_time,
    wh2.end_time
FROM working_hours wh1
JOIN working_hours wh2 ON (
    wh1.driver_id = wh2.driver_id 
    AND wh1.day_of_week = wh2.day_of_week 
    AND wh1.id != wh2.id
    AND (
        (wh1.start_time <= wh2.end_time AND wh1.end_time >= wh2.start_time)
    )
);

-- Verificar registros órfãos
SELECT wh.* 
FROM working_hours wh
LEFT JOIN drivers d ON wh.driver_id = d.id
WHERE d.id IS NULL;
```

**Soluções:**
1. Implementar constraints mais rigorosas
2. Adicionar validação de conflitos no backend
3. Executar scripts de limpeza de dados
4. Revisar lógica de validação no frontend

### Scripts de Diagnóstico

#### Script de Health Check
```sql
-- Health check completo do sistema de horários
WITH stats AS (
    SELECT 
        COUNT(*) as total_records,
        COUNT(DISTINCT driver_id) as unique_drivers,
        MIN(created_at) as oldest_record,
        MAX(updated_at) as newest_update
    FROM working_hours
),
conflicts AS (
    SELECT COUNT(*) as conflict_count
    FROM working_hours wh1
    JOIN working_hours wh2 ON (
        wh1.driver_id = wh2.driver_id 
        AND wh1.day_of_week = wh2.day_of_week 
        AND wh1.id != wh2.id
        AND wh1.start_time <= wh2.end_time 
        AND wh1.end_time >= wh2.start_time
    )
),
orphans AS (
    SELECT COUNT(*) as orphan_count
    FROM working_hours wh
    LEFT JOIN drivers d ON wh.driver_id = d.id
    WHERE d.id IS NULL
)
SELECT 
    s.total_records,
    s.unique_drivers,
    s.oldest_record,
    s.newest_update,
    c.conflict_count,
    o.orphan_count,
    CASE 
        WHEN c.conflict_count = 0 AND o.orphan_count = 0 THEN 'HEALTHY'
        WHEN c.conflict_count > 0 OR o.orphan_count > 0 THEN 'NEEDS_ATTENTION'
        ELSE 'UNKNOWN'
    END as health_status
FROM stats s, conflicts c, orphans o;
```

## Monitoramento e Alertas

### Métricas Importantes

1. **Performance**
   - Tempo médio de resposta das queries
   - Número de queries por minuto
   - Uso de CPU e memória

2. **Funcionalidade**
   - Taxa de sucesso ao salvar horários
   - Número de conflitos detectados
   - Tempo médio de carregamento da tela

3. **Dados**
   - Número total de configurações de horário
   - Motoristas ativos com horários configurados
   - Registros órfãos ou inconsistentes

### Alertas Recomendados

```yaml
# Exemplo de configuração de alertas (Prometheus/Grafana)
alerts:
  - name: working_hours_high_error_rate
    condition: error_rate > 5%
    duration: 5m
    action: notify_team
    
  - name: working_hours_slow_queries
    condition: avg_query_time > 1s
    duration: 2m
    action: investigate
    
  - name: working_hours_data_conflicts
    condition: conflict_count > 0
    duration: 1m
    action: immediate_fix
```

## Conclusão

Esta documentação fornece uma base sólida para manutenção e troubleshooting do sistema de horários de trabalho. Mantenha-a atualizada conforme o sistema evolui e adicione novos cenários de troubleshooting conforme eles surgem.

### Próximos Passos

1. Implementar monitoramento automatizado
2. Criar dashboards de métricas
3. Automatizar scripts de health check
4. Desenvolver testes de carga
5. Documentar novos casos de uso