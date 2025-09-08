#!/bin/bash

# Script para iniciar AMBOS os emuladores simultaneamente - OPTION App
# Motorista (porta 5554) e Passageiro (porta 5556)

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🚗🧑‍🦱 Iniciando AMBOS Emuladores - OPTION App${NC}"
echo -e "${PURPLE}==============================================${NC}"

# Configurações
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/opt/homebrew/share/android-commandlinetools}"
EMULATOR_PATH="$ANDROID_SDK_ROOT/emulator/emulator"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# AVDs
DRIVER_AVD="OPTION_Driver_Pixel8"
PASSENGER_AVD="OPTION_Passenger_Pixel8"

# Verificar pré-requisitos
echo -e "${BLUE}🔍 Verificando pré-requisitos...${NC}"

if [ ! -d "$ANDROID_SDK_ROOT" ]; then
    echo -e "${RED}❌ Android SDK não encontrado em: $ANDROID_SDK_ROOT${NC}"
    echo -e "${YELLOW}💡 Configure ANDROID_SDK_ROOT ou instale Android SDK${NC}"
    exit 1
fi

if [ ! -f "$EMULATOR_PATH" ]; then
    echo -e "${RED}❌ Emulador não encontrado em: $EMULATOR_PATH${NC}"
    exit 1
fi

# Verificar se já existem emuladores rodando
RUNNING_EMULATORS=$(adb devices | grep "emulator" | wc -l)
if [ $RUNNING_EMULATORS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Emuladores já rodando detectados:${NC}"
    adb devices | grep "emulator"
    echo -e "${YELLOW}❓ Deseja parar todos os emuladores existentes? [y/N]:${NC}"
    read -r STOP_EXISTING
    if [[ $STOP_EXISTING =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🛑 Parando emuladores existentes...${NC}"
        adb devices | grep "emulator" | cut -f1 | while read -r device; do
            adb -s "$device" emu kill
        done
        sleep 3
    fi
fi

# Criar AVDs se não existirem
echo -e "${BLUE}📱 Verificando/Criando AVDs...${NC}"

create_avd_if_needed() {
    local avd_name=$1
    local avd_type=$2

    if ! "$EMULATOR_PATH" -list-avds | grep -q "$avd_name"; then
        echo -e "${YELLOW}💡 Criando AVD para $avd_type: $avd_name${NC}"
        echo "no" | "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/avdmanager" create avd \
            -n "$avd_name" \
            -k "system-images;android-34;google_apis;arm64-v8a" \
            -d "pixel_8" \
            --force

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ AVD '$avd_name' criado!${NC}"
        else
            echo -e "${RED}❌ Erro ao criar AVD $avd_name${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✅ AVD '$avd_name' já existe${NC}"
    fi
}

create_avd_if_needed "$DRIVER_AVD" "MOTORISTA"
create_avd_if_needed "$PASSENGER_AVD" "PASSAGEIRO"

# Função para iniciar emulador em background
start_emulator() {
    local avd_name=$1
    local port=$2
    local type=$3
    local lat=$4
    local lon=$5

    echo -e "${BLUE}🚀 Iniciando emulador $type (porta $port)...${NC}"

    "$EMULATOR_PATH" \
        -avd "$avd_name" \
        -dns-server 8.8.8.8,8.8.4.4 \
        -no-snapshot-load \
        -no-snapshot-save \
        -gpu auto \
        -memory 4096 \
        -partition-size 8192 \
        -port "$port" \
        -netdelay none \
        -netspeed full \
        -wipe-data \
        -no-window \
        > /dev/null 2>&1 &

    local emulator_pid=$!
    echo "$emulator_pid" > "/tmp/option_emulator_$(echo $type | tr '[:upper:]' '[:lower:]')_${port}.pid"

    echo -e "${YELLOW}⏳ Aguardando $type iniciar na porta $port...${NC}"

    # Aguardar até 3 minutos para o emulador iniciar
    local timeout=180
    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        if adb -s "emulator-$port" shell echo "test" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Emulador $type iniciado! (emulator-$port)${NC}"

            # Configurações de desenvolvimento
            adb -s "emulator-$port" shell settings put global window_animation_scale 0
            adb -s "emulator-$port" shell settings put global transition_animation_scale 0
            adb -s "emulator-$port" shell settings put global animator_duration_scale 0

            # Configurar GPS
            adb -s "emulator-$port" emu geo fix "$lon" "$lat"

            return 0
        fi
        sleep 5
        elapsed=$((elapsed + 5))
        echo -e "${YELLOW}⏳ $type: ${elapsed}s/${timeout}s${NC}"
    done

    echo -e "${RED}❌ Timeout: $type não iniciou em ${timeout}s${NC}"
    return 1
}

# Iniciar emuladores simultaneamente
echo -e "${PURPLE}🚀 Iniciando emuladores simultaneamente...${NC}"

# Motorista - Porto 5554 - Localização: Centro SP
start_emulator "$DRIVER_AVD" "5554" "MOTORISTA" "-23.5505" "-46.6333" &
DRIVER_PID=$!

# Passageiro - Porto 5556 - Localização: Vila Madalena SP
start_emulator "$PASSENGER_AVD" "5556" "PASSAGEIRO" "-23.5489" "-46.6388" &
PASSENGER_PID=$!

# Aguardar ambos terminarem
wait $DRIVER_PID
DRIVER_SUCCESS=$?

wait $PASSENGER_PID
PASSENGER_SUCCESS=$?

# Verificar resultados
echo -e "${PURPLE}📊 Resultado da inicialização:${NC}"

if [ $DRIVER_SUCCESS -eq 0 ]; then
    echo -e "${GREEN}✅ MOTORISTA: emulator-5554 - PRONTO${NC}"
else
    echo -e "${RED}❌ MOTORISTA: Falha na inicialização${NC}"
fi

if [ $PASSENGER_SUCCESS -eq 0 ]; then
    echo -e "${GREEN}✅ PASSAGEIRO: emulator-5556 - PRONTO${NC}"
else
    echo -e "${RED}❌ PASSAGEIRO: Falha na inicialização${NC}"
fi

# Status final
echo -e "${PURPLE}================================================${NC}"
echo -e "${BLUE}📱 Emuladores ativos:${NC}"
adb devices | grep "emulator"

if [ $DRIVER_SUCCESS -eq 0 ] && [ $PASSENGER_SUCCESS -eq 0 ]; then
    echo -e "${GREEN}🎉 AMBOS emuladores iniciados com sucesso!${NC}"
    echo ""
    echo -e "${BLUE}🎯 Para executar o app:${NC}"
    echo -e "${YELLOW}   MOTORISTA:  flutter run -d emulator-5554${NC}"
    echo -e "${YELLOW}   PASSAGEIRO: flutter run -d emulator-5556${NC}"
    echo ""
    echo -e "${BLUE}🔧 Para depuração:${NC}"
    echo -e "${YELLOW}   adb -s emulator-5554 logcat | grep flutter  # Logs motorista${NC}"
    echo -e "${YELLOW}   adb -s emulator-5556 logcat | grep flutter  # Logs passageiro${NC}"
    echo ""
    echo -e "${BLUE}📍 Localizações configuradas:${NC}"
    echo -e "${YELLOW}   MOTORISTA:  Centro SP (-23.5505, -46.6333)${NC}"
    echo -e "${YELLOW}   PASSAGEIRO: Vila Madalena SP (-23.5489, -46.6388)${NC}"

    # Criar script de parada
    cat > "$SCRIPT_DIR/stop_all_emulators.sh" << 'EOF'
#!/bin/bash
echo "🛑 Parando todos os emuladores OPTION..."
adb devices | grep "emulator" | cut -f1 | while read -r device; do
    echo "Parando $device..."
    adb -s "$device" emu kill
done
rm -f /tmp/option_emulator_*.pid
echo "✅ Todos os emuladores parados!"
EOF
    chmod +x "$SCRIPT_DIR/stop_all_emulators.sh"

    echo -e "${GREEN}💡 Para parar todos: ./stop_all_emulators.sh${NC}"

else
    echo -e "${RED}❌ Alguns emuladores falharam ao iniciar${NC}"
    exit 1
fi

# Monitoramento contínuo
echo -e "${PURPLE}💡 Pressione Ctrl+C para parar todos os emuladores${NC}"

# Função cleanup para parar emuladores ao sair
cleanup() {
    echo -e "\n${YELLOW}🛑 Parando emuladores...${NC}"
    adb devices | grep "emulator" | cut -f1 | while read -r device; do
        adb -s "$device" emu kill
    done
    rm -f /tmp/option_emulator_*.pid
    echo -e "${GREEN}✅ Emuladores parados!${NC}"
    exit 0
}

trap cleanup INT

# Aguardar indefinidamente
while true; do
    sleep 10
    # Verificar se emuladores ainda estão rodando
    RUNNING_COUNT=$(adb devices | grep "emulator" | wc -l)
    if [ $RUNNING_COUNT -eq 0 ]; then
        echo -e "${RED}❌ Todos os emuladores foram fechados${NC}"
        break
    fi
done
