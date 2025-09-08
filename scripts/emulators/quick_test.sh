#!/bin/bash

# Script de conveniência para teste rápido - OPTION App
# Inicia ambos emuladores e executa o app automaticamente

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}⚡ OPTION - Teste Rápido${NC}"
echo -e "${PURPLE}========================${NC}"

# Diretório do script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Verificar se estamos no diretório correto
if [ ! -f "$PROJECT_DIR/pubspec.yaml" ]; then
    echo -e "${RED}❌ Erro: pubspec.yaml não encontrado em $PROJECT_DIR${NC}"
    echo -e "${YELLOW}💡 Execute este script do diretório correto do projeto${NC}"
    exit 1
fi

# Função de limpeza
cleanup() {
    echo -e "\n${YELLOW}🧹 Limpando recursos...${NC}"

    # Parar todos os processos flutter
    pkill -f "flutter.*run" 2>/dev/null || true

    # Parar emuladores
    "$SCRIPT_DIR/stop_all_emulators.sh"

    echo -e "${GREEN}✅ Limpeza concluída!${NC}"
    exit 0
}

# Interceptar Ctrl+C
trap cleanup INT

echo -e "${BLUE}🔍 Verificando ambiente...${NC}"

# Verificar Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter não encontrado no PATH${NC}"
    exit 1
fi

# Verificar Android SDK
if [ -z "$ANDROID_SDK_ROOT" ]; then
    echo -e "${YELLOW}⚠️  ANDROID_SDK_ROOT não definido, usando padrão${NC}"
    export ANDROID_SDK_ROOT="/opt/homebrew/share/android-commandlinetools"
fi

if [ ! -d "$ANDROID_SDK_ROOT" ]; then
    echo -e "${RED}❌ Android SDK não encontrado em: $ANDROID_SDK_ROOT${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Ambiente verificado${NC}"

# Opções de execução
echo -e "${BLUE}🚀 Opções disponíveis:${NC}"
echo -e "  ${YELLOW}1${NC} - Teste completo (ambos emuladores + apps)"
echo -e "  ${YELLOW}2${NC} - Só iniciar emuladores"
echo -e "  ${YELLOW}3${NC} - Executar apps (emuladores já rodando)"
echo -e "  ${YELLOW}4${NC} - Parar tudo e sair"
echo ""
echo -e "${YELLOW}Escolha uma opção [1-4]:${NC} "
read -r OPTION

case $OPTION in
    1)
        echo -e "${GREEN}🎯 Executando teste completo...${NC}"

        # Parar emuladores existentes
        echo -e "${BLUE}🧹 Limpando emuladores existentes...${NC}"
        "$SCRIPT_DIR/stop_all_emulators.sh" 2>/dev/null || true
        sleep 2

        # Iniciar ambos emuladores
        echo -e "${BLUE}🚀 Iniciando emuladores...${NC}"
        "$SCRIPT_DIR/start_both_emulators.sh" &
        EMULATOR_PID=$!

        # Aguardar emuladores ficarem prontos (timeout 3 minutos)
        echo -e "${YELLOW}⏳ Aguardando emuladores ficarem prontos...${NC}"
        timeout=180
        elapsed=0

        while [ $elapsed -lt $timeout ]; do
            driver_ready=false
            passenger_ready=false

            if adb -s emulator-5554 shell echo "test" >/dev/null 2>&1; then
                driver_ready=true
            fi

            if adb -s emulator-5556 shell echo "test" >/dev/null 2>&1; then
                passenger_ready=true
            fi

            if [ "$driver_ready" = true ] && [ "$passenger_ready" = true ]; then
                echo -e "${GREEN}✅ Ambos emuladores prontos!${NC}"
                break
            fi

            sleep 5
            elapsed=$((elapsed + 5))
            echo -e "${YELLOW}⏳ Aguardando... ${elapsed}s/${timeout}s${NC}"
        done

        if [ $elapsed -ge $timeout ]; then
            echo -e "${RED}❌ Timeout: emuladores não ficaram prontos${NC}"
            cleanup
            exit 1
        fi

        # Aguardar mais um pouco para estabilizar
        sleep 10

        # Executar apps
        echo -e "${BLUE}📱 Executando apps...${NC}"

        cd "$PROJECT_DIR"

        # App do motorista em background
        echo -e "${YELLOW}🚗 Iniciando app do motorista (emulator-5554)...${NC}"
        flutter run -d emulator-5554 > /tmp/option_driver.log 2>&1 &
        DRIVER_APP_PID=$!

        sleep 5

        # App do passageiro em background
        echo -e "${YELLOW}🧑‍🦱 Iniciando app do passageiro (emulator-5556)...${NC}"
        flutter run -d emulator-5556 > /tmp/option_passenger.log 2>&1 &
        PASSENGER_APP_PID=$!

        echo -e "${GREEN}🎉 Apps iniciados!${NC}"
        echo -e "${BLUE}📊 Status:${NC}"
        echo -e "  • Motorista: emulator-5554 (PID: $DRIVER_APP_PID)"
        echo -e "  • Passageiro: emulator-5556 (PID: $PASSENGER_APP_PID)"
        echo ""
        echo -e "${BLUE}📜 Para ver logs:${NC}"
        echo -e "${YELLOW}  tail -f /tmp/option_driver.log    # Logs motorista${NC}"
        echo -e "${YELLOW}  tail -f /tmp/option_passenger.log # Logs passageiro${NC}"

        ;;

    2)
        echo -e "${GREEN}🚀 Iniciando só os emuladores...${NC}"
        "$SCRIPT_DIR/start_both_emulators.sh"
        exit 0
        ;;

    3)
        echo -e "${GREEN}📱 Executando apps em emuladores existentes...${NC}"

        # Verificar se emuladores estão rodando
        if ! adb devices | grep -q "emulator-5554"; then
            echo -e "${RED}❌ Emulador do motorista (5554) não encontrado${NC}"
            exit 1
        fi

        if ! adb devices | grep -q "emulator-5556"; then
            echo -e "${RED}❌ Emulador do passageiro (5556) não encontrado${NC}"
            exit 1
        fi

        cd "$PROJECT_DIR"

        # Executar apps
        echo -e "${YELLOW}🚗 Executando app do motorista...${NC}"
        flutter run -d emulator-5554 &
        DRIVER_APP_PID=$!

        sleep 5

        echo -e "${YELLOW}🧑‍🦱 Executando app do passageiro...${NC}"
        flutter run -d emulator-5556 &
        PASSENGER_APP_PID=$!

        ;;

    4)
        echo -e "${RED}🛑 Parando tudo...${NC}"
        cleanup
        exit 0
        ;;

    *)
        echo -e "${RED}❌ Opção inválida${NC}"
        exit 1
        ;;
esac

# Monitoramento
echo -e "${PURPLE}💡 Pressione Ctrl+C para parar tudo e sair${NC}"
echo -e "${BLUE}🔄 Monitorando execução...${NC}"

# Aguardar indefinidamente
while true; do
    sleep 10

    # Verificar se emuladores ainda estão rodando
    driver_running=$(adb devices | grep "emulator-5554" | wc -l)
    passenger_running=$(adb devices | grep "emulator-5556" | wc -l)

    if [ $driver_running -eq 0 ] && [ $passenger_running -eq 0 ]; then
        echo -e "${RED}❌ Todos os emuladores foram fechados${NC}"
        break
    fi

    # Status a cada minuto
    current_time=$(date +%H:%M:%S)
    echo -e "${BLUE}[$current_time] ✅ Sistemas rodando...${NC}"
done

cleanup
