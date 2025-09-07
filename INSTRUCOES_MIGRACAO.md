# Instruções para Aplicar a Migração de Working Hours no Supabase

## ⚠️ IMPORTANTE: Faça backup do banco de dados antes de prosseguir!

## Passo 1: Acessar o Supabase Dashboard

1. Acesse https://app.supabase.com
2. Faça login com suas credenciais
3. Selecione o projeto correto

## Passo 2: Criar um Backup (Opcional mas Recomendado)

1. Vá para "Database" → "Backups"
2. Clique em "Create backup"
3. Aguarde a conclusão do backup

## Passo 3: Executar o Script de Migração

1. No menu lateral, clique em "SQL Editor"
2. Clique em "New query"
3. Copie e cole o conteúdo do arquivo `script_supabase_dashboard.sql`
4. Clique em "Run" para executar o script

## Passo 4: Verificar a Execução

Após executar o script, verifique se:

1. A view `driver_effective_status` foi criada corretamente:
   ```sql
   SELECT * FROM driver_effective_status LIMIT 5;
   ```

2. A função `check_driver_documents_approved` existe:
   ```sql
   SELECT routine_name 
   FROM information_schema.routines 
   WHERE routine_name = 'check_driver_documents_approved';
   ```

3. As tabelas relacionadas a working_hours foram removidas:
   ```sql
   SELECT table_name 
   FROM information_schema.tables 
   WHERE table_name IN ('working_hours', 'driver_schedules', 'driver_schedule_overrides');
   ```

## Passo 5: Testar a Nova Funcionalidade

1. Verifique um motorista com documentos aprovados:
   ```sql
   -- Substitua 'ID_DO_MOTORISTA' pelo ID real de um motorista
   SELECT check_driver_documents_approved('ID_DO_MOTORISTA');
   ```

2. Verifique o status efetivo de alguns motoristas:
   ```sql
   SELECT 
       driver_id,
       online_intent,
       documents_validated,
       effective_online
   FROM driver_effective_status 
   LIMIT 10;
   ```

## Passo 6: Monitorar os Resultados

Nos próximos dias, monitore:

1. Logs da aplicação para verificar se os erros relacionados a working hours foram resolvidos
2. Feedback dos motoristas sobre a nova funcionalidade
3. Verifique se motoristas com documentos aprovados conseguem ficar online normalmente

## ⚠️ Em Caso de Problemas

Se encontrar problemas após a migração:

1. Reverta as mudanças executando o script de rollback (se disponível)
2. Restaure o backup do banco de dados
3. Entre em contato com a equipe de desenvolvimento

## 📝 Notas Finais

- Esta migração é irreversível: os dados de working_hours serão perdidos permanentemente
- A nova lógica é mais simples e confiável
- Todos os motoristas agora ficam online apenas quando todos os documentos obrigatórios estão aprovados