#!/bin/bash

# Script aprimorado para backup automático do Supabase
# Salva dumps do banco de dados e uploads em intervalos regulares

set -euo pipefail

# Configurações
SUPABASE_PROJECT_ID="qlbwacmavngtonauxnte"
BACKUP_DIR="$HOME/supabase_backups"
LOG_DIR="$HOME/supabase_backups/logs"
DATE=$(date +"%Y%m%d_%H%M%S")
RETENTION_DAYS=7
FULL_BACKUP=false

# Criar diretórios se não existirem
mkdir -p "$BACKUP_DIR/database"
mkdir -p "$BACKUP_DIR/storage"
mkdir -p "$LOG_DIR"

# Arquivo de log
LOG_FILE="$LOG_DIR/backup_$DATE.log"

# Funções auxiliares
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Processar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --full)
            FULL_BACKUP=true
            shift
            ;;
        *)
            log "Opção desconhecida: $1"
            exit 1
            ;;
    esac
done

log "Iniciando backup do Supabase - $DATE"
log "Modo full: $FULL_BACKUP"

# Verificar se o CLI do Supabase está instalado
if ! command -v supabase &> /dev/null; then
    log "ERRO: CLI do Supabase não encontrado. Instale com: npm install -g supabase"
    exit 1
fi

# Backup do banco de dados
log "Fazendo backup do banco de dados..."
if supabase db dump --project-ref "$SUPABASE_PROJECT_ID" --file "$BACKUP_DIR/database/backup_$DATE.sql" 2>>"$LOG_FILE"; then
    log "Backup do banco de dados concluído com sucesso"
    
    # Compactar o backup do banco de dados
    log "Compactando backup do banco de dados..."
    if gzip "$BACKUP_DIR/database/backup_$DATE.sql" 2>>"$LOG_FILE"; then
        log "Backup do banco de dados compactado: $BACKUP_DIR/database/backup_$DATE.sql.gz"
    else
        log "ERRO: Falha ao compactar backup do banco de dados"
        exit 1
    fi
else
    log "ERRO: Falha no backup do banco de dados"
    exit 1
fi

# Backup dos buckets de storage (somente em modo full)
if [ "$FULL_BACKUP" = true ]; then
    log "Fazendo backup do storage (modo full)..."
    # Listar buckets
    if supabase storage ls --project-ref "$SUPABASE_PROJECT_ID" > "$BACKUP_DIR/storage/buckets_$DATE.txt" 2>>"$LOG_FILE"; then
        log "Lista de buckets salva"
        # Aqui você pode adicionar comandos para copiar os buckets individualmente
        # Exemplo: supabase storage cp -r supabase://bucket_name "$BACKUP_DIR/storage/bucket_name_$DATE/" --project-ref "$SUPABASE_PROJECT_ID"
    else
        log "Aviso: Não foi possível listar os buckets de storage"
    fi
fi

# Limpar backups antigos
log "Limpando backups antigos (+$RETENTION_DAYS dias)..."
find "$BACKUP_DIR/database" -name "backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete 2>>"$LOG_FILE"
find "$BACKUP_DIR/storage" -name "backup_*" -mtime +$RETENTION_DAYS -delete 2>>"$LOG_FILE"
find "$LOG_DIR" -name "backup_*.log" -mtime +$RETENTION_DAYS -delete 2>>"$LOG_FILE"

log "Backup concluído com sucesso!"
log "Local: $BACKUP_DIR"
log "Database: $BACKUP_DIR/database/backup_$DATE.sql.gz"
log "Logs: $LOG_FILE"