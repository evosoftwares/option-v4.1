# SOLUÇÃO COMPLETA PARA PROBLEMAS COM WORKING HOURS

## Diagnóstico Final

Após análise completa do sistema, identificamos que os erros constantes relacionados aos `working_hours` têm duas causas principais:

1. **View `driver_effective_status` ausente ou com lógica incorreta**
2. **Permissões insuficientes para acessar tabelas do sistema**

## Solução Implementada

### 1. Correção da View `driver_effective_status`

A view `driver_effective_status` é responsável por calcular se um motorista está dentro dos horários de trabalho (`is_within_working_hours`). Criamos o SQL correto para esta view:

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
```

### 2. Melhorias no Código da Aplicação

Atualizamos o `WorkingHoursService` e `DriverStatusService` para melhor tratamento de erros:

- Validação do `driverId` antes de fazer chamadas
- Assumir que o motorista pode ficar online em caso de erros (não bloquear)
- Adicionar logs mais detalhados para diagnóstico

### 3. Arquivos Criados para Manutenção

1. `fix_driver_effective_status_view.sql` - Script SQL completo
2. `fix_driver_effective_status_view.py` - Script Python para aplicar a correção
3. `debug_working_hours.py` - Script de debug para diagnóstico
4. `verify_fix.py` - Script de verificação pós-correção
5. `SOLUTION.md` - Documentação completa da solução
6. `FIX_INSTRUCTIONS.md` - Instruções detalhadas para aplicação da correção

## Passos para Aplicar a Correção

### Passo 1: Acessar o Supabase Dashboard

1. Faça login no Supabase Dashboard
2. Selecione o projeto correto
3. Vá para a seção "SQL Editor"

### Passo 2: Executar o Script de Correção

1. Copie o conteúdo do arquivo `fix_driver_effective_status_view.sql`
2. Cole no editor SQL
3. Execute o script

### Passo 3: Verificar a Correção

1. Execute a seguinte query para verificar:
```sql
SELECT * FROM driver_effective_status LIMIT 5;
```

2. Verifique se a view retorna dados corretamente

## Resultados Esperados

Após aplicar a correção:

✅ **Motoristas sem horários definidos** poderão ficar online normalmente
✅ **Motoristas com horários definidos** só poderão ficar online dentro desses horários
✅ **Menos erros de "driver ID null"** nos logs
✅ **View `driver_effective_status`** calculará corretamente o `is_within_working_hours`
✅ **Melhor experiência para motoristas** com feedback claro sobre status

## Monitoramento Pós-Correção

1. Monitorar logs da aplicação por 24-48 horas
2. Verificar se os erros relacionados a working hours diminuíram
3. Confirmar com motoristas que o sistema está funcionando corretamente

## Prevenção de Problemas Futuros

1. **Validação de dados**: Sempre validar `driverId` antes de fazer chamadas
2. **Tratamento de erros**: Nunca bloquear funcionalidade em caso de erro
3. **Logs detalhados**: Manter logs para facilitar diagnósticos futuros
4. **Testes regulares**: Executar scripts de verificação periodicamente