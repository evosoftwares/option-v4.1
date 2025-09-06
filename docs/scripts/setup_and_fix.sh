#!/bin/bash
# Script para configurar ambiente e corrigir constraint driver_documents

echo "🚀 Setup e Correção - Driver Documents Constraint"
echo "================================================="

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir com cor
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Verificar se Python está instalado
if ! command -v python3 &> /dev/null; then
    print_error "Python3 não encontrado. Instale Python3 primeiro."
    exit 1
fi

# Verificar se pip está instalado
if ! command -v pip3 &> /dev/null; then
    print_error "pip3 não encontrado. Instale pip3 primeiro."
    exit 1
fi

# Instalar supabase se necessário
print_info "Verificando dependências..."
if ! python3 -c "import supabase" 2>/dev/null; then
    print_warning "Instalando supabase-py..."
    pip3 install supabase
    if [ $? -eq 0 ]; then
        print_status "supabase-py instalado com sucesso"
    else
        print_error "Falha ao instalar supabase-py"
        exit 1
    fi
else
    print_status "supabase-py já está instalado"
fi

# Solicitar configurações do Supabase
echo ""
print_info "Configuração do Supabase"
echo "========================"

# URL do Supabase
if [ -z "$SUPABASE_URL" ]; then
    echo -n "Digite a URL do seu projeto Supabase (ex: https://abc123.supabase.co): "
    read SUPABASE_URL
fi

# Service Role Key
if [ -z "$SUPABASE_SERVICE_ROLE_KEY" ]; then
    echo -n "Digite a Service Role Key (chave de admin): "
    read -s SUPABASE_SERVICE_ROLE_KEY
    echo ""
fi

# Validar se as variáveis foram definidas
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_SERVICE_ROLE_KEY" ]; then
    print_error "URL ou Service Role Key não fornecidos"
    exit 1
fi

# Exportar variáveis de ambiente
export SUPABASE_URL="$SUPABASE_URL"
export SUPABASE_SERVICE_ROLE_KEY="$SUPABASE_SERVICE_ROLE_KEY"

print_status "Variáveis de ambiente configuradas"

# Executar o script Python de correção
echo ""
print_info "Executando correção da constraint..."
echo "===================================="

python3 fix_constraint_with_admin.py

if [ $? -eq 0 ]; then
    echo ""
    print_status "Correção executada com sucesso!"
    echo ""
    print_info "Próximos passos:"
    echo "1. Teste o upload de documentos no seu app Flutter"
    echo "2. Verifique se não há mais erros de constraint"
    echo "3. Os tipos de documento permitidos são:"
    echo "   - CNH_FRONT, CNH_BACK, CRLV"
    echo "   - VEHICLE_FRONT, VEHICLE_BACK"
    echo "   - VEHICLE_LEFT, VEHICLE_RIGHT, VEHICLE_INTERIOR"
else
    echo ""
    print_error "Falha na execução da correção"
    echo ""
    print_info "Alternativas:"
    echo "1. Execute manualmente o arquivo fix_driver_documents_admin.sql no Supabase Dashboard"
    echo "2. Verifique se a Service Role Key tem privilégios de admin"
    echo "3. Consulte o arquivo GUIA_PERMISSOES_SUPABASE.md"
fi

echo ""
echo "================================================="
echo "✨ Script finalizado"