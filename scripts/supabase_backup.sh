#!/bin/bash

# Script de backup do banco de dados Supabase
# Autor: Sistema de Backup
# Data: $(date +%Y-%m-%d)

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configurações do Supabase
SUPABASE_URL="https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_HOST="aws-0-us-east-1.pooler.supabase.com"
SUPABASE_PORT="5432"
SUPABASE_DATABASE="postgres"
SUPABASE_USER="postgres"

# Diretório de backups
BACKUP_DIR="backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="${BACKUP_DIR}/supabase_backup_${TIMESTAMP}.sql"

# Função para exibir mensagens
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se pg_dump está instalado
check_dependencies() {
    if ! command -v pg_dump &> /dev/null; then
        print_error "pg_dump não está instalado!"
        echo "Instale com:"
        echo "  macOS: brew install postgresql"
        echo "  Ubuntu: sudo apt-get install postgresql-client"
        echo "  Windows: Baixe do site oficial do PostgreSQL"
        exit 1
    fi
    
    print_message "pg_dump encontrado: $(pg_dump --version)"
}

# Obter senha do usuário
get_password() {
    if [ -z "$SUPABASE_DB_PASSWORD" ]; then
        print_warning "Variável SUPABASE_DB_PASSWORD não encontrada"
        read -s -p "Digite a senha do banco de dados PostgreSQL: " password
        echo
        export PGPASSWORD="$password"
    else
        export PGPASSWORD="$SUPABASE_DB_PASSWORD"
        print_message "Usando senha da variável de ambiente"
    fi
}

# Criar diretório de backups
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        print_message "Diretório de backups criado: $BACKUP_DIR"
    fi
}

# Executar backup
perform_backup() {
    print_message "Iniciando backup do Supabase..."
    print_message "Arquivo de saída: $BACKUP_FILE"
    
    # Comando pg_dump com opções completas
    pg_dump \
        --host="$SUPABASE_HOST" \
        --port="$SUPABASE_PORT" \
        --username="$SUPABASE_USER" \
        --dbname="$SUPABASE_DATABASE" \
        --no-password \
        --verbose \
        --clean \
        --if-exists \
        --create \
        --no-owner \
        --no-privileges \
        --format=plain \
        --file="$BACKUP_FILE"
    
    if [ $? -eq 0 ]; then
        print_message "✅ Backup criado com sucesso!"
        
        # Verificar tamanho do arquivo
        file_size=$(du -h "$BACKUP_FILE" | cut -f1)
        print_message "📊 Tamanho do arquivo: $file_size"
        
        # Contar linhas (aproximadamente)
        line_count=$(wc -l < "$BACKUP_FILE")
        print_message "📄 Número de linhas: $line_count"
        
        # Verificar se o arquivo contém dados válidos
        if grep -q "CREATE TABLE\|INSERT INTO" "$BACKUP_FILE"; then
            print_message "✅ Arquivo contém estrutura e/ou dados válidos"
        else
            print_warning "⚠️  Arquivo pode estar vazio ou não conter dados esperados"
        fi
        
    else
        print_error "❌ Falha ao criar backup"
        exit 1
    fi
}

# Função principal
main() {
    echo "🚀 Script de Backup do Supabase"
    echo "=============================="
    
    check_dependencies
    create_backup_dir
    get_password
    perform_backup
    
    echo
    print_message "🎉 Backup concluído com sucesso!"
    print_message "📁 Arquivo salvo em: $(pwd)/$BACKUP_FILE"
}

# Executar se for o script principal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi