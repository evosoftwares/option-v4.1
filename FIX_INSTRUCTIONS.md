# Correção da View driver_effective_status

## Problema
A view `driver_effective_status` está causando erros nos horários de trabalho dos motoristas, impedindo que entrem online fora dos horários definidos ou mesmo quando não há horários definidos.

## Solução
Vamos corrigir a view diretamente no Supabase Dashboard:

1. Acesse o Supabase Dashboard
2. Vá para a seção SQL Editor
3. Execute o seguinte SQL:

```sql
-- Remover view existente se houver
DROP VIEW IF EXISTS driver_effective_status;

-- Criar a view corrigida
CREATE OR REPLACE VIEW driver_effective_status AS
SELECT 
    ds.driver_id,
    ds.online_intent,
    ds.updated_at as intent_updated_at,
    -- Verificar se o motorista está nos horários de trabalho
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM working_hours wh 
            WHERE wh.driver_id = ds.driver_id 
            AND wh.is_active = true
            AND wh.day_of_week = EXTRACT(DOW FROM NOW())  -- 0 = Domingo, 6 = Sábado
            AND (
                -- Caso normal: mesmo dia (ex: 08:00 às 18:00)
                (wh.start_time <= wh.end_time AND 
                 CURRENT_TIME >= wh.start_time AND 
                 CURRENT_TIME < wh.end_time)
                OR
                -- Caso que cruza meia-noite (ex: 22:00 às 06:00)
                (wh.start_time > wh.end_time AND 
                 (CURRENT_TIME >= wh.start_time OR 
                  CURRENT_TIME < wh.end_time))
            )
        ) THEN true
        -- Se não há horários definidos, assume que está disponível
        WHEN NOT EXISTS (
            SELECT 1 
            FROM working_hours wh 
            WHERE wh.driver_id = ds.driver_id 
            AND wh.is_active = true
        ) THEN true
        ELSE false
    END as is_within_working_hours,
    -- Status efetivo: intenção online E dentro dos horários
    (ds.online_intent AND (
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM working_hours wh 
                WHERE wh.driver_id = ds.driver_id 
                AND wh.is_active = true
                AND wh.day_of_week = EXTRACT(DOW FROM NOW())
                AND (
                    (wh.start_time <= wh.end_time AND 
                     CURRENT_TIME >= wh.start_time AND 
                     CURRENT_TIME < wh.end_time)
                    OR
                    (wh.start_time > wh.end_time AND 
                     (CURRENT_TIME >= wh.start_time OR 
                      CURRENT_TIME < wh.end_time))
                )
            ) THEN true
            WHEN NOT EXISTS (
                SELECT 1 
                FROM working_hours wh 
                WHERE wh.driver_id = ds.driver_id 
                AND wh.is_active = true
            ) THEN true
            ELSE false
        END
    )) as effective_online
FROM driver_status ds;

-- Verificar se a view foi criada corretamente
SELECT * FROM driver_effective_status LIMIT 5;
```

## Verificação Pós-Correção

Após aplicar a correção, execute os seguintes comandos para verificar:

```sql
-- Verificar se a view existe
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_name = 'driver_effective_status';

-- Verificar alguns registros
SELECT 
    driver_id,
    online_intent,
    is_within_working_hours,
    effective_online
FROM driver_effective_status 
LIMIT 10;
```

## Teste de Funcionalidade

Para testar se a correção funcionou:

1. Verifique um motorista sem horários definidos:
```sql
-- Primeiro, verifique se há horários para um motorista específico
SELECT * FROM working_hours WHERE driver_id = 'ID_DO_MOTORISTA';

-- Depois, verifique o status efetivo
SELECT 
    driver_id,
    online_intent,
    is_within_working_hours,
    effective_online
FROM driver_effective_status 
WHERE driver_id = 'ID_DO_MOTORISTA';
```

2. Verifique um motorista com horários definidos:
```sql
-- Verifique os horários
SELECT * FROM working_hours WHERE driver_id = 'ID_DO_MOTORISTA';

-- Verifique o status efetivo
SELECT 
    driver_id,
    online_intent,
    is_within_working_hours,
    effective_online
FROM driver_effective_status 
WHERE driver_id = 'ID_DO_MOTORISTA';
```

## Logs de Monitoramento

Após a correção, monitore os logs da aplicação para verificar se os erros relacionados a "driver ID null" e problemas com working hours foram resolvidos.