# Supabase Backup

Este diretório contém scripts e configurações para backup automático do projeto Supabase.

## Estrutura

- `scripts/supabase_backup.sh` - Script principal de backup
- `scripts/supabase_backup_cron.txt` - Configuração do cron para backups locais
- `.github/workflows/supabase_backup.yml` - Workflow do GitHub Actions para backups na nuvem

## Configuração dos Backups Locais

1. Dê permissão de execução ao script:
   ```bash
   chmod +x scripts/supabase_backup.sh
   ```

2. Edite o arquivo `scripts/supabase_backup_cron.txt` com os caminhos corretos

3. Adicione ao crontab:
   ```bash
   crontab scripts/supabase_backup_cron.txt
   ```

4. Verifique se o cron foi adicionado:
   ```bash
   crontab -l
   ```

## Configuração do GitHub Actions

1. Adicione as seguintes secrets no repositório:
   - `SUPABASE_PROJECT_ID` - ID do projeto Supabase

2. O workflow será executado automaticamente conforme agendado

## Estrutura dos Backups

Os backups são salvos em:
- `$HOME/supabase_backups/database/` - Backups do banco de dados (.sql.gz)
- `$HOME/supabase_backups/storage/` - Backups do storage
- `$HOME/supabase_backups/logs/` - Logs dos backups

## Retenção

Backups são mantidos por 7 dias. Após esse período, são automaticamente excluídos.