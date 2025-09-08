# 🚗🧑‍🦱 Guia de Testes com Emuladores - OPTION App

Este guia mostra como usar os scripts de emuladores para testar o app OPTION com dois dispositivos simultâneos (motorista e passageiro).

## 📋 Pré-requisitos

### 1. Android SDK Configurado
```bash
# Verificar se Android SDK está instalado
echo $ANDROID_SDK_ROOT
# Deve mostrar: /Users/seu-usuario/Library/Android/sdk

# Se não estiver configurado:
export ANDROID_SDK_ROOT=~/Library/Android/sdk
```

### 2. AVD Manager e Emulador
```bash
# Verificar se emulador existe
ls $ANDROID_SDK_ROOT/emulator/emulator

# Verificar AVDs existentes
$ANDROID_SDK_ROOT/emulator/emulator -list-avds
```

### 3. Sistema Images (API 34)
```bash
# Instalar system image se necessário
$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager \
  "system-images;android-34;google_apis;x86_64"
```

## 🚀 Scripts Disponíveis

### 1. Emulador Individual - Motorista
```bash
cd option-v4.1/scripts/emulators
chmod +x start_driver_emulator.sh
./start_driver_emulator.sh
```

**Configurações:**
- AVD: `OPTION_Driver_Pixel8`
- Porta: `5554`
- GPS: Centro de São Paulo (-23.5505, -46.6333)
- Device ID: `emulator-5554`

### 2. Emulador Individual - Passageiro
```bash
cd option-v4.1/scripts/emulators
chmod +x start_passenger_emulator.sh
./start_passenger_emulator.sh
```

**Configurações:**
- AVD: `OPTION_Passenger_Pixel8`
- Porta: `5556`
- GPS: Vila Madalena SP (-23.5489, -46.6388)
- Device ID: `emulator-5556`

### 3. Ambos Simultaneamente (Recomendado)
```bash
cd option-v4.1/scripts/emulators
chmod +x start_both_emulators.sh
./start_both_emulators.sh
```

**Recursos:**
- Cria AVDs automaticamente se não existirem
- Configura localizações diferentes
- Otimiza para desenvolvimento
- Monitora status dos emuladores

### 4. Parar Todos os Emuladores
```bash
cd option-v4.1/scripts/emulators
chmod +x stop_all_emulators.sh
./stop_all_emulators.sh
```

## 📱 Testando o App

### Executar App no Motorista
```bash
cd option-v4.1
flutter run -d emulator-5554
```

### Executar App no Passageiro
```bash
cd option-v4.1
flutter run -d emulator-5556
```

### Executar Simultaneamente (Duas Instâncias)
```bash
# Terminal 1 - Motorista
cd option-v4.1
flutter run -d emulator-5554

# Terminal 2 - Passageiro (em paralelo)
cd option-v4.1
flutter run -d emulator-5556
```

## 🧪 Cenários de Teste

### 1. Fluxo Completo de Viagem

#### No Emulador do Motorista:
1. Registrar como motorista
2. Fazer upload dos documentos
3. Ficar online/disponível
4. Receber solicitação de viagem
5. Aceitar viagem
6. Navegar até passageiro
7. Iniciar viagem
8. Finalizar viagem

#### No Emulador do Passageiro:
1. Registrar como passageiro
2. Definir localização de origem
3. Definir destino
4. Solicitar viagem
5. Aguardar motorista
6. Acompanhar viagem
7. Avaliar motorista

### 2. Teste de Localização
```bash
# Alterar GPS do motorista
adb -s emulator-5554 emu geo fix -46.6333 -23.5505

# Alterar GPS do passageiro
adb -s emulator-5556 emu geo fix -46.6388 -23.5489

# Simular movimento do motorista
adb -s emulator-5554 emu geo fix -46.6350 -23.5520
adb -s emulator-5554 emu geo fix -46.6360 -23.5530
```

### 3. Teste de Notificações
```bash
# Verificar logs de notificação
adb -s emulator-5554 logcat | grep -i "onesignal\|notification"
adb -s emulator-5556 logcat | grep -i "onesignal\|notification"
```

## 🐛 Debug e Logs

### Logs em Tempo Real
```bash
# Logs do motorista
adb -s emulator-5554 logcat | grep flutter

# Logs do passageiro
adb -s emulator-5556 logcat | grep flutter

# Logs específicos do app
adb -s emulator-5554 logcat | grep "OPTION\|Supabase\|Trip"
adb -s emulator-5556 logcat | grep "OPTION\|Supabase\|Trip"
```

### Conectividade
```bash
# Testar internet nos emuladores
adb -s emulator-5554 shell ping google.com
adb -s emulator-5556 shell ping google.com

# Verificar DNS
adb -s emulator-5554 shell nslookup supabase.co
adb -s emulator-5556 shell nslookup supabase.co
```

### Informações dos Dispositivos
```bash
# Info do emulador motorista
adb -s emulator-5554 shell getprop ro.product.model
adb -s emulator-5554 shell getprop ro.build.version.release

# Info do emulador passageiro
adb -s emulator-5556 shell getprop ro.product.model
adb -s emulator-5556 shell getprop ro.build.version.release
```

## 📊 Monitoramento

### Status dos Emuladores
```bash
# Ver dispositivos conectados
adb devices

# Ver emuladores rodando
adb devices | grep emulator

# Matar servidor ADB se necessário
adb kill-server && adb start-server
```

### Performance
```bash
# Verificar uso de CPU/RAM
top | grep emulator

# Limpar cache do Flutter
flutter clean && flutter pub get
```

## ❌ Solução de Problemas

### Problema: "AVD não encontrado"
```bash
# Listar AVDs disponíveis
$ANDROID_SDK_ROOT/emulator/emulator -list-avds

# Criar AVD manualmente
$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/avdmanager create avd \
  -n OPTION_Driver_Pixel8 \
  -k "system-images;android-34;google_apis;x86_64" \
  -d "pixel_8"
```

### Problema: "Emulador não inicia"
```bash
# Verificar se ANDROID_SDK_ROOT está correto
echo $ANDROID_SDK_ROOT

# Verificar permissões
chmod +x $ANDROID_SDK_ROOT/emulator/emulator

# Tentar iniciar manualmente
$ANDROID_SDK_ROOT/emulator/emulator -avd OPTION_Driver_Pixel8 -verbose
```

### Problema: "Erro de DNS/Conectividade"
```bash
# Reiniciar emulador com DNS específico
$ANDROID_SDK_ROOT/emulator/emulator \
  -avd OPTION_Driver_Pixel8 \
  -dns-server 8.8.8.8,8.8.4.4
```

### Problema: "Flutter não encontra dispositivo"
```bash
# Verificar dispositivos Flutter
flutter devices

# Reconectar ADB
adb kill-server
adb start-server

# Aguardar dispositivo
adb wait-for-device
```

### Problema: "Emulador muito lento"
```bash
# Usar aceleração de hardware
$ANDROID_SDK_ROOT/emulator/emulator \
  -avd OPTION_Driver_Pixel8 \
  -gpu host \
  -memory 4096
```

## 💡 Dicas de Desenvolvimento

### 1. Hot Reload
- Use `flutter run` para desenvolvimento com hot reload
- Mantenha ambos os terminais abertos
- Salve arquivos para aplicar mudanças instantaneamente

### 2. Build Otimizado
```bash
# Build debug para testes rápidos
flutter build apk --debug

# Install em dispositivo específico
flutter install -d emulator-5554
```

### 3. Variáveis de Ambiente
```bash
# Para usar ambiente de desenvolvimento
SUPABASE_URL=https://qlbwacmavngtonauxnte.supabase.co \
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... \
flutter run -d emulator-5554
```

### 4. Bypass Auth para Emuladores
Os scripts já configuram o `EmulatorAuthHelper` que:
- Detecta automaticamente emuladores
- Usa bypass auth (mais estável)
- Fallback para auth normal se necessário

## 📈 Métricas e Análise

### Tempo de Inicialização
```bash
# Medir tempo de startup do app
time flutter run -d emulator-5554
```

### Uso de Memória
```bash
# Monitorar memória do app
adb -s emulator-5554 shell dumpsys meminfo com.option.app
```

### Performance de Rede
```bash
# Simular conexão lenta
adb -s emulator-5554 shell cmd connectivity airplane-mode enable
adb -s emulator-5554 shell cmd connectivity airplane-mode disable
```

## 🔄 Workflow Recomendado

1. **Iniciar Emuladores:**
   ```bash
   ./start_both_emulators.sh
   ```

2. **Aguardar Inicialização (2-3 minutos)**

3. **Executar App em Ambos:**
   ```bash
   # Terminal 1
   flutter run -d emulator-5554
   
   # Terminal 2  
   flutter run -d emulator-5556
   ```

4. **Testar Fluxos:**
   - Registro de usuários
   - Solicitação de viagem
   - Matching motorista-passageiro
   - Viagem completa

5. **Debug Conforme Necessário:**
   - Logs em tempo real
   - Alteração de GPS
   - Teste de conectividade

6. **Finalizar:**
   ```bash
   ./stop_all_emulators.sh
   ```

## 📝 Checklist de Teste

### ✅ Antes de Começar
- [ ] Android SDK configurado
- [ ] Scripts com permissão de execução
- [ ] Flutter funcionando (`flutter doctor`)
- [ ] Supabase acessível

### ✅ Durante o Teste
- [ ] Ambos emuladores iniciaram
- [ ] Apps rodando nos dois dispositivos
- [ ] GPS configurado corretamente
- [ ] Conectividade funcionando
- [ ] Logs sendo capturados

### ✅ Cenários Testados
- [ ] Registro motorista e passageiro
- [ ] Solicitação de viagem
- [ ] Matching de viagem
- [ ] Navegação e GPS
- [ ] Finalização e avaliação
- [ ] Pagamentos (se aplicável)

---

**🎯 Com estes scripts e este guia, você terá um ambiente de teste robusto e confiável para desenvolvimento do OPTION!**