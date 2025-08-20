#!/usr/bin/env bash

# =============================================================================
# Script: extract_supabase_schema.sh
# Descrição: Extrai todas as tabelas e campos do Supabase (schema público)
# Autor: Sistema automatizado
# Data: 2025-08-20
# =============================================================================
#
# USO:
#   ./extract_supabase_schema.sh [OPÇÕES]
#
# OPÇÕES:
#   -o, --output FILE    Nome do arquivo de saída (padrão: supabase_schema.json)
#   -f, --format FORMAT  Formato de saída: json ou text (padrão: json)
#   -s, --schema SCHEMA  Schema a ser analisado (padrão: public)
#   --env-file FILE      Arquivo .env customizado (padrão: .env na raiz)
#   -q, --quiet          Modo silencioso - reduz mensagens de log
#   -h, --help          Mostra esta ajuda
#
# VARIÁVEIS DE AMBIENTE NECESSÁRIAS:
#   SUPABASE_URL        URL do projeto Supabase (ex: https://xyz.supabase.co)
#   SUPABASE_KEY        Chave de API (service_role ou anon)
#   SUPABASE_CLI_PATH   (opcional) Caminho para o CLI do Supabase
#
# DETECÇÃO AUTOMÁTICA DE CREDENCIAIS:
#   O script buscará automaticamente as credenciais nas seguintes fontes:
#   1. Variáveis de ambiente do sistema (prioritárias)
#   2. Arquivo .env na raiz do projeto (busca flexível por nomes de variáveis)
#
# PADRÕES DE VARIÁVEIS SUPORTADOS:
#   - URL: SUPABASE_URL, SUPABASE_PROJECT_URL, NEXT_PUBLIC_SUPABASE_URL
#   - KEY: SUPABASE_KEY, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, NEXT_PUBLIC_SUPABASE_ANON_KEY
#
# EXEMPLOS:
#   ./extract_supabase_schema.sh
#   ./extract_supabase_schema.sh -o minhas_tabelas.json
#   ./extract_supabase_schema.sh -f text -o schema.txt
#   ./extract_supabase_schema.sh --env-file .env.local
#   ./extract_supabase_schema.sh --quiet
#
# =============================================================================

# Configurações de shell para melhor compatibilidade
set -euo pipefail

# Função para verificar se realpath está disponível, senão usar alternativa
get_real_path() {
    local file_path="$1"
    if command -v realpath &> /dev/null; then
        realpath "$file_path" 2>/dev/null || echo "$file_path"
    else
        # Alternativa para sistemas sem realpath
        if [[ "$file_path" == /* ]]; then
            echo "$file_path"
        else
            echo "$(pwd)/$file_path"
        fi
    fi
}

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações padrão
OUTPUT_FILE="supabase_schema.json"
FORMAT="json"
SCHEMA="public"
USE_CLI=false
SUPABASE_CLI_CMD="supabase"
ENV_FILE=".env"
QUIET=false

# Arrays para armazenar padrões de variáveis
SUPABASE_URL_PATTERNS=("SUPABASE_URL" "SUPABASE_PROJECT_URL" "NEXT_PUBLIC_SUPABASE_URL")
SUPABASE_KEY_PATTERNS=("SUPABASE_KEY" "SUPABASE_ANON_KEY" "SUPABASE_SERVICE_ROLE_KEY" "NEXT_PUBLIC_SUPABASE_ANON_KEY")

# Funções auxiliares
log() {
    if [[ "$QUIET" != true ]]; then
        printf '%b\n' "${BLUE}[INFO]${NC} $1"
    fi
}

error() {
    printf '%b\n' "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    if [[ "$QUIET" != true ]]; then
        printf '%b\n' "${YELLOW}[WARNING]${NC} $1"
    fi
}

success() {
    if [[ "$QUIET" != true ]]; then
        printf '%b\n' "${GREEN}[SUCCESS]${NC} $1"
    fi
}

# Função de ajuda
show_help() {
    grep '^#' "$0" | grep -v '#!/usr/bin/env bash' | sed 's/^# //g'
}

# Função para carregar arquivo .env com melhor parsing
load_env_file() {
    local env_file_path="$1"
    
    if [[ ! -f "$env_file_path" ]]; then
        warning "Arquivo .env não encontrado: $env_file_path"
        return 1
    fi
    
    log "Carregando variáveis do arquivo: $env_file_path"
    
    # Lê o arquivo .env linha por linha com tratamento melhorado
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Ignora linhas vazias ou comentários
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Extrai chave e valor com melhor tratamento
        if [[ "$line" == *"="* ]]; then
            local key="${line%%=*}"
            local value="${line#*=}"
            
            # Remove espaços em branco no início e fim
            key=$(printf '%s\n' "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            value=$(printf '%s\n' "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            # Remove aspas simples e duplas do valor se presentes
            value="${value%\"}"
            value="${value#\"}"
            value="${value%\'}"
            value="${value#\'}"

            # Remove espaços extras após remover aspas
            value=$(printf '%s\n' "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            # Exporta a variável apenas se não estiver já definida no ambiente
            if [[ -z "${!key:-}" ]]; then
                export "$key"="$value"
            fi
        fi
    done < "$env_file_path"
    
    return 0
}

# Função para validar URL do Supabase
validate_supabase_url() {
    local url="$1"
    
    # Remove aspas e espaços extras da URL
    url=$(printf '%s\n' "$url" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    url="${url%\"}"
    url="${url#\"}"
    url="${url%\'}"
    url="${url#\'}"

    # Remove espaços extras novamente após remover aspas
    url=$(printf '%s\n' "$url" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Valida formato da URL
    if [[ ! "$url" =~ ^https?:// ]]; then
        error "URL inválida: '$url' - deve começar com http:// ou https://"
        return 1
    fi
    
    # Valida se é uma URL do Supabase
    if [[ ! "$url" =~ \.supabase\.(co|red|in) ]]; then
        warning "A URL não parece ser de um projeto Supabase: $url"
    fi
    
    printf '%s\n' "$url"
    return 0
}

# Função para buscar variável usando padrões flexíveis
find_variable() {
    local patterns=("$@")
    local value=""
    
    # Busca a primeira variável não-vazia dentre os padrões fornecidos
    for pattern in "${patterns[@]}"; do
        if [[ -n "${!pattern:-}" ]]; then
            value="${!pattern}"
            break
        fi
    done
    
    if [[ -n "$value" ]]; then
        printf '%s\n' "$value"
        return 0
    else
        return 1
    fi
}

# Função para detectar credenciais do Supabase
detect_supabase_credentials() {
    log "Detectando credenciais do Supabase..."
    
    local supabase_url=""
    local supabase_key=""
    
    # Busca URL do Supabase
    supabase_url=$(find_variable "${SUPABASE_URL_PATTERNS[@]}")
    if [[ -z "$supabase_url" ]]; then
        error "Nenhuma URL do Supabase encontrada. Verifique as variáveis: ${SUPABASE_URL_PATTERNS[*]}"
        return 1
    fi
    
    # Valida e limpa a URL
    supabase_url=$(validate_supabase_url "$supabase_url")
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    # Busca chave do Supabase
    supabase_key=$(find_variable "${SUPABASE_KEY_PATTERNS[@]}")
    if [[ -z "$supabase_key" ]]; then
        error "Nenhuma chave do Supabase encontrada. Verifique as variáveis: ${SUPABASE_KEY_PATTERNS[*]}"
        return 1
    fi
    
    # Limpa a chave de aspas e espaços
    supabase_key=$(printf '%s\n' "$supabase_key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    supabase_key="${supabase_key%\"}"
    supabase_key="${supabase_key#\"}"
    supabase_key="${supabase_key%\'}"
    supabase_key="${supabase_key#\'}"

    # Exporta as variáveis encontradas
    export SUPABASE_URL="$supabase_url"
    export SUPABASE_KEY="$supabase_key"
    
    # Log informativo sobre qual variável foi usada
    for pattern in "${SUPABASE_URL_PATTERNS[@]}"; do
        if [[ -n "${!pattern:-}" ]]; then
            log "URL encontrada via variável: $pattern"
            break
        fi
    done
    
    for pattern in "${SUPABASE_KEY_PATTERNS[@]}"; do
        if [[ -n "${!pattern:-}" ]]; then
            log "Chave encontrada via variável: $pattern"
            break
        fi
    done
    
    return 0
}

# Função para testar conectividade com a API do Supabase
test_connectivity() {
    local url="$1"
    local key="$2"
    
    log "Testando conectividade com o Supabase..."
    
    if ! command -v curl &> /dev/null; then
        error "curl não está instalado. Instale-o para continuar."
        return 1
    fi
    
    local test_response
    test_response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "apikey: $key" \
        -H "Authorization: Bearer $key" \
        "${url}/rest/v1/" 2>/dev/null || echo "000")
    
    if [[ "$test_response" == "200" ]] || [[ "$test_response" == "404" ]]; then
        log "Conectividade OK (status: $test_response)"
        return 0
    else
        error "Falha na conectividade com o Supabase (status: $test_response). Verifique suas credenciais e conexão com a internet."
        return 1
    fi
}

# Parse de argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -f|--format)
            FORMAT="$2"
            if [[ "$FORMAT" != "json" && "$FORMAT" != "text" ]]; then
                error "Formato inválido. Use 'json' ou 'text'."
                exit 1
            fi
            shift 2
            ;;
        -s|--schema)
            SCHEMA="$2"
            shift 2
            ;;
        --env-file)
            ENV_FILE="$2"
            shift 2
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            error "Opção desconhecida: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validação de variáveis de ambiente
validate_env() {
    log "Validando variáveis de ambiente..."
    
    if [[ -z "${SUPABASE_URL:-}" ]]; then
        error "SUPABASE_URL não está definida. Configure-a nas variáveis de ambiente ou no arquivo .env"
        return 1
    fi
    
    if [[ -z "${SUPABASE_KEY:-}" ]]; then
        error "SUPABASE_KEY não está definida. Configure-a nas variáveis de ambiente ou no arquivo .env"
        return 1
    fi
    
    success "Variáveis de ambiente validadas"
    log "URL do Supabase: $SUPABASE_URL"
}

# Verifica se o Supabase CLI está disponível e autenticada
check_supabase_cli() {
    local cli_status=0
    
    if command -v "$SUPABASE_CLI_CMD" &> /dev/null; then
        log "Supabase CLI encontrado: $(which "$SUPABASE_CLI_CMD")"
        
        # Testa se a CLI está autenticada
        if "$SUPABASE_CLI_CMD" status &> /dev/null; then
            log "Supabase CLI está autenticada"
            USE_CLI=true
            return 0
        else
            warning "Supabase CLI encontrada mas não está autenticada. Usando API REST como fallback."
            USE_CLI=false
            return 1
        fi
    elif [[ -n "${SUPABASE_CLI_PATH:-}" ]] && [[ -x "$SUPABASE_CLI_PATH" ]]; then
        SUPABASE_CLI_CMD="$SUPABASE_CLI_PATH"
        log "Supabase CLI encontrado em: $SUPABASE_CLI_PATH"
        
        # Testa autenticação
        if "$SUPABASE_CLI_CMD" status &> /dev/null; then
            log "Supabase CLI está autenticada"
            USE_CLI=true
            return 0
        else
            warning "Supabase CLI encontrada mas não está autenticada. Usando API REST como fallback."
            USE_CLI=false
            return 1
        fi
    else
        warning "Supabase CLI não encontrada, usando API REST"
        USE_CLI=false
        return 1
    fi
}

# Extrai schema usando Supabase CLI com tratamento de erros melhorado
extract_with_cli() {
    log "Extraindo schema usando Supabase CLI..."
    
    # Verifica se está logado novamente (já verificado em check_supabase_cli)
    if ! "$SUPABASE_CLI_CMD" status &> /dev/null; then
        error "Supabase CLI não está autenticada. Execute: supabase login"
        return 1
    fi
    
    # Verifica se jq está disponível
    if ! command -v jq &> /dev/null; then
        error "jq não está instalado. Instale com: brew install jq (macOS) ou apt-get install jq (Linux)"
        return 1
    fi
    
    # Extrai tabelas com tratamento de erro
    local tables_json
    tables_json=$("$SUPABASE_CLI_CMD" db dump --schema-only --schema "$SCHEMA" 2>&1)
    local cli_exit_code=$?
    
    if [[ $cli_exit_code -ne 0 ]]; then
        error "Erro ao executar comando Supabase CLI: $tables_json"
        return 1
    fi
    
    if [[ -z "$tables_json" ]] || [[ "$tables_json" == "[]" ]]; then
        error "Nenhum dado retornado pela Supabase CLI"
        return 1
    fi
    
    # Processa e formata os dados
    echo "$tables_json" | jq -r '
        .[]
        | select(.type == "table")
        | {
            table_name: .name,
            columns: [
                .columns[] | {
                    name: .name,
                    type: .type,
                    nullable: .nullable,
                    default: .default
                }
            ]
        }' 2>&1 || {
        local jq_error="$?"
        error "Erro ao processar dados do CLI com jq. Código: $jq_error"
        return 1
    }
}

# Extrai schema usando API REST
extract_with_api() {
    log "Extraindo schema usando API REST..."
    
    local api_url="${SUPABASE_URL}/rest/v1"
    local headers=(
        -H "apikey: $SUPABASE_KEY"
        -H "Authorization: Bearer $SUPABASE_KEY"
    )
    
    # Verifica se curl está disponível
    if ! command -v curl &> /dev/null; then
        error "curl não está instalado. Instale-o para continuar."
        return 1
    fi
    
    # Verifica se jq está disponível
    if ! command -v jq &> /dev/null; then
        error "jq não está instalado. Instale com: brew install jq (macOS) ou apt-get install jq (Linux)"
        return 1
    fi
    
    # Busca todas as tabelas do schema
    local tables_query="SELECT table_name FROM information_schema.tables WHERE table_schema = '$SCHEMA'"
    local tables_response
    
    tables_response=$(curl -s -X POST \
        "${api_url}/rpc/sql" \
        "${headers[@]}" \
        -H "Content-Type: application/json" \
        -d "{\"query\": \"$tables_query\"}" 2>&1)
    
    local curl_exit_code=$?
    if [[ $curl_exit_code -ne 0 ]]; then
        error "Erro ao buscar tabelas com curl: $tables_response"
        return 1
    fi
    
    # Verifica se houve erro na resposta
    if echo "$tables_response" | jq -e '.error' &> /dev/null; then
        local error_msg
        error_msg=$(echo "$tables_response" | jq -r '.error')
        error "Erro ao buscar tabelas: $error_msg"
        return 1
    fi
    
    # Array para armazenar todas as tabelas
    local all_tables="[]"
    
    # Para cada tabela, busca os campos
    local table_names
    table_names=$(echo "$tables_response" | jq -r '.[].table_name' 2>/dev/null)
    
    if [[ -z "$table_names" ]]; then
        warning "Nenhuma tabela encontrada no schema '$SCHEMA'"
        echo "[]"
        return 0
    fi
    
    while IFS= read -r table_name; do
        [[ -z "$table_name" ]] && continue
        
        log "Processando tabela: $table_name"
        
        local columns_query="SELECT
            column_name as name,
            data_type as type,
            is_nullable as nullable,
            column_default as default_value
        FROM information_schema.columns
        WHERE table_schema = '$SCHEMA'
        AND table_name = '$table_name'
        ORDER BY ordinal_position"
        
        local columns_response
        columns_response=$(curl -s -X POST \
            "${api_url}/rpc/sql" \
            "${headers[@]}" \
            -H "Content-Type: application/json" \
            -d "{\"query\": \"$columns_query\"}" 2>&1)
        
        local curl_exit_code=$?
        if [[ $curl_exit_code -ne 0 ]]; then
            warning "Erro ao buscar colunas da tabela '$table_name': $columns_response"
            continue
        fi
        
        # Verifica se houve erro na resposta
        if echo "$columns_response" | jq -e '.error' &> /dev/null; then
            local error_msg
            error_msg=$(echo "$columns_response" | jq -r '.error')
            warning "Erro ao buscar colunas da tabela '$table_name': $error_msg"
            continue
        fi
        
        local table_data
        table_data=$(jq -n \
            --arg table "$table_name" \
            --argjson columns "$columns_response" \
            '{table_name: $table, columns: $columns}')
        
        all_tables=$(echo "$all_tables" | jq ". += [$table_data]" 2>/dev/null)
    done <<< "$table_names"
    
    echo "$all_tables"
}

# Formata saída em texto estruturado
format_text_output() {
    local json_data="$1"
    
    echo "=== SCHEMA DO SUPABASE ==="
    echo "Schema: $SCHEMA"
    echo "Data/Hora: $(date)"
    echo "=============================="
    echo ""
    
    echo "$json_data" | jq -r '
        .[] |
        "TABELA: \(.table_name)" +
        "\n" +
        (.columns | map(
            "  - \(.name): \(.type)" +
            (if .nullable == "YES" then " (nullable)" else " (not null)" end) +
            (if .default then " [default: \(.default)]" else "" end)
        ) | join("\n")) +
        "\n"'
}

# Função principal
main() {
    log "Iniciando extração do schema do Supabase..."
    log "Schema alvo: $SCHEMA"
    log "Formato de saída: $FORMAT"
    log "Arquivo de saída: $OUTPUT_FILE"
    
    # Carrega arquivo .env se especificado ou se existir o padrão
    if [[ "$ENV_FILE" != ".env" ]] || [[ -f "$ENV_FILE" ]]; then
        load_env_file "$ENV_FILE"
    fi
    
    # Detecta credenciais do Supabase
    detect_supabase_credentials
    
    # Validação inicial
    validate_env
    
    # Testa conectividade antes de prosseguir
    test_connectivity "$SUPABASE_URL" "$SUPABASE_KEY"
    
    # Verifica CLI (mas não falha se não estiver autenticada)
    check_supabase_cli
    
    # Extração dos dados
    local schema_data=""
    local extraction_success=false
    
    if [[ "$USE_CLI" == true ]]; then
        if schema_data=$(extract_with_cli 2>/dev/null); then
            extraction_success=true
        else
            warning "Falha ao extrair com CLI, tentando API REST..."
            USE_CLI=false
        fi
    fi
    
    if [[ "$extraction_success" != true ]]; then
        if schema_data=$(extract_with_api 2>/dev/null); then
            extraction_success=true
        else
            error "Falha ao extrair dados tanto pela CLI quanto pela API REST"
            exit 1
        fi
    fi
    
    # Valida se temos dados
    if [[ -z "$schema_data" ]] || [[ "$schema_data" == "[]" ]]; then
        error "Nenhuma tabela encontrada no schema '$SCHEMA'"
        exit 1
    fi
    
    # Formata e salva a saída
    log "Processando dados e salvando..."
    
    if [[ "$FORMAT" == "text" ]]; then
        format_text_output "$schema_data" > "$OUTPUT_FILE"
    else
        printf '%s\n' "$schema_data" | jq '.' > "$OUTPUT_FILE"
    fi
    
    success "Schema extraído com sucesso!"
    log "Arquivo salvo: $(get_real_path "$OUTPUT_FILE")"
    
    # Estatísticas
    local table_count
    table_count=$(printf '%s\n' "$schema_data" | jq 'length')
    log "Total de tabelas: $table_count"
}

# Executa o script
main "$@"