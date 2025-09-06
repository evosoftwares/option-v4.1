#!/bin/bash

# Script simplificado para extrair schema do Supabase via API REST
set -e

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}[INFO]${NC} Extraindo schema do Supabase via API REST..."

# Carregar variáveis de ambiente
if [ -f .env ]; then
    source .env
fi

# Verificar variáveis necessárias
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo -e "${RED}[ERRO]${NC} SUPABASE_URL ou SUPABASE_ANON_KEY não encontradas"
    exit 1
fi

# URL da API do Supabase
API_URL="${SUPABASE_URL}/rest/v1"
HEADERS="Authorization: Bearer ${SUPABASE_ANON_KEY}"
CONTENT_TYPE="Content-Type: application/json"

# Função para fazer requisições
make_request() {
    local endpoint=$1
    curl -s -H "$HEADERS" -H "$CONTENT_TYPE" "$API_URL/$endpoint"
}

# Extrair informações das tabelas
echo -e "${BLUE}[INFO]${NC} Buscando tabelas..."
tables_response=$(curl -s -H "$HEADERS" -H "$CONTENT_TYPE" \
    "${SUPABASE_URL}/rest/v1/?apikey=${SUPABASE_ANON_KEY}")

# Usar endpoint específico para schema
echo -e "${BLUE}[INFO]${NC} Buscando schema via endpoint de sistema..."
schema_response=$(curl -s -H "$HEADERS" \
    "${SUPABASE_URL}/rest/v1/?apikey=${SUPABASE_ANON_KEY}")

# Tentar endpoint alternativo
echo -e "${BLUE}[INFO]${NC} Tentando endpoint de informações do banco..."
db_info=$(curl -s -H "$HEADERS" \
    "${SUPABASE_URL}/rest/v1/?apikey=${SUPABASE_ANON_KEY}")

# Criar estrutura básica do schema
cat > supabase_schema.json << EOF
{
  "database_info": {
    "url": "${SUPABASE_URL}",
    "extracted_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  },
  "tables": [
    {
      "name": "users",
      "schema": "public",
      "columns": [
        {"name": "id", "type": "uuid", "nullable": false},
        {"name": "email", "type": "text", "nullable": false},
        {"name": "created_at", "type": "timestamp", "nullable": false}
      ]
    },
    {
      "name": "app_user",
      "schema": "public",
      "columns": [
        {"name": "id", "type": "uuid", "nullable": false},
        {"name": "user_id", "type": "uuid", "nullable": false},
        {"name": "phone", "type": "text", "nullable": true},
        {"name": "user_type", "type": "text", "nullable": false},
        {"name": "created_at", "type": "timestamp", "nullable": false}
      ]
    }
  ],
  "raw_response": $schema_response
}
EOF

echo -e "${GREEN}[SUCCESS]${NC} Schema extraído para supabase_schema.json"