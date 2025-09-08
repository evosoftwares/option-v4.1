#!/bin/bash

# Script para iniciar emulador Android para PASSAGEIRO - OPTION App
# Configuração otimizada para desenvolvimento e teste

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧑‍🦱 Iniciando Emulador PASSAGEIRO - OPTION App${NC}"
echo -e "${BLUE}===================================================${NC}"

# Configurações do emulador
AVD_NAME="OPTION_Passenger_Pixel8"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/opt/homebrew/share/android-commandlinetools}"
EMULATOR_PATH="$ANDROID_SDK_ROOT/emulator/emulator"

# Verificar se o SDK existe
if [ ! -d "$ANDROID_SDK_ROOT" ]; then
    echo -e "${RED}❌ Android SDK não encontrado em: $ANDROID_SDK_ROOT${NC}"
    echo -e "${YELLOW}💡 Configure ANDROID_SDK_ROOT ou instale Android SDK${NC}"
    exit 1
fi

# Verificar se o emulador existe
if [ ! -f "$EMULATOR_PATH" ]; then
    echo -e "${RED}❌ Emulador não encontrado em: $EMULATOR_PATH${NC}"
    exit 1
fi

# Listar AVDs disponíveis
echo -e "${YELLOW}📱 AVDs disponíveis:${NC}"
"$EMULATOR_PATH" -list-avds

# Verificar se o AVD específico existe
if ! "$EMULATOR_PATH" -list-avds | grep -q "$AVD_NAME"; then
    echo -e "${YELLOW}⚠️  AVD '$AVD_NAME' não encontrado${NC}"
    echo -e "${YELLOW}💡 Criando AVD para passageiro...${NC}"

    # Criar AVD se não existir
    echo "no" | "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/avdmanager" create avd \
        -n "$AVD_NAME" \
        -k "system-images;android-34;google_apis;arm64-v8a" \
        -d "pixel_8" \
        --force

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ AVD '$AVD_NAME' criado com sucesso!${NC}"
    else
        echo -e "${RED}❌ Erro ao criar AVD${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}🚀 Iniciando emulador para PASSAGEIRO...${NC}"
echo -e "${BLUE}Configurações:${NC}"
echo -e "  • AVD: $AVD_NAME"
echo -e "  • DNS: 8.8.8.8, 8.8.4.4"
echo -e "  • Porta: 5556 (diferente do motorista)"
echo -e "  • Snapshot: desabilitado para teste limpo"
echo -e "  • GPU: auto"
echo -e "  • RAM: 4GB"

# Iniciar emulador com configurações específicas para passageiro
"$EMULATOR_PATH" \
    -avd "$AVD_NAME" \
    -dns-server 8.8.8.8,8.8.4.4 \
    -no-snapshot-load \
    -no-snapshot-save \
    -gpu auto \
    -memory 4096 \
    -partition-size 8192 \
    -port 5556 \
    -netdelay none \
    -netspeed full \
    -wipe-data \
    -show-kernel \
    -verbose &

# Aguardar o emulador iniciar
echo -e "${YELLOW}⏳ Aguardando emulador iniciar...${NC}"
adb wait-for-device

# Verificar se o emulador está funcionando
sleep 10
if adb -s emulator-5556 shell echo "test" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Emulador PASSAGEIRO iniciado com sucesso!${NC}"
    echo -e "${GREEN}📱 Device ID: emulator-5556${NC}"

    # Configurações específicas para desenvolvimento
    echo -e "${BLUE}🔧 Aplicando configurações de desenvolvimento...${NC}"

    # Desabilitar animações para testes mais rápidos
    adb -s emulator-5556 shell settings put global window_animation_scale 0
    adb -s emulator-5556 shell settings put global transition_animation_scale 0
    adb -s emulator-5556 shell settings put global animator_duration_scale 0

    # Configurar localização para São Paulo - diferente do motorista (para simular passageiro em outro local)
    adb -s emulator-5556 emu geo fix -46.6388 -23.5489

    # Mostrar informações do dispositivo
    echo -e "${BLUE}📊 Informações do emulador:${NC}"
    adb -s emulator-5556 shell getprop ro.product.model
    adb -s emulator-5556 shell getprop ro.build.version.release

    echo -e "${GREEN}🎯 Para executar o app PASSAGEIRO:${NC}"
    echo -e "${YELLOW}flutter run -d emulator-5556${NC}"
    echo -e "${GREEN}🔗 Para conectar especificamente:${NC}"
    echo -e "${YELLOW}adb connect emulator-5556${NC}"

else
    echo -e "${RED}❌ Erro ao iniciar emulador${NC}"
    exit 1
fi

# Aguardar comando para não fechar o terminal
echo -e "${BLUE}💡 Pressione Ctrl+C para parar o emulador${NC}"
wait
