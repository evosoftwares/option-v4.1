# OPTION - Urban Mobility App

Uma aplicação Flutter de mobilidade urbana similar ao Uber/99, conectando passageiros e motoristas através de serviços de ride-hailing.

## 🚗 Sobre o Projeto

OPTION é uma plataforma dual que oferece:
- **Para Passageiros**: Solicitação de viagens, rastreamento em tempo real, pagamentos integrados
- **Para Motoristas**: Recebimento de corridas, gerenciamento de documentos, controle de ganhos

## 🛠️ Tecnologias Principais

- **Flutter 3.0+** (Dart 3.0+)
- **Supabase** (Database, Auth, Storage)
- **Firebase** (File Storage, Core services)
- **Google Maps API** para serviços de localização
- **OneSignal** para notificações push
- **Asaas** para integração de pagamentos

## 🚀 Começando

### Pré-requisitos

```bash
# Flutter SDK 3.0+
flutter --version

# Android SDK configurado
echo $ANDROID_SDK_ROOT

# Dependências
flutter pub get
```

### Executando o App

```bash
# Modo debug
flutter run

# Modo release
flutter run --release

# Web (com renderer HTML)
flutter run -d chrome --web-renderer html

# Com variáveis de ambiente
SUPABASE_URL=https://qlbwacmavngtonauxnte.supabase.co \
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... \
flutter run
```

## 🧪 Testes com Emuladores Android

### Scripts de Emuladores Automatizados

Para facilitar os testes, criamos scripts que configuram automaticamente dois emuladores Android - um para motorista e outro para passageiro:

#### ⚡ Teste Rápido (Recomendado)
```bash
cd scripts/emulators
./quick_test.sh
```

**Opções disponíveis:**
1. **Teste completo** - Inicia ambos emuladores + apps automaticamente
2. **Só emuladores** - Apenas inicia os emuladores
3. **Só apps** - Executa apps em emuladores já rodando
4. **Parar tudo** - Limpa e encerra todos os processos

#### 🚗 Emulador Individual - Motorista
```bash
cd scripts/emulators
./start_driver_emulator.sh
```

**Configurações:**
- AVD: `OPTION_Driver_Pixel8`
- Porta: `5554`
- GPS: Centro SP (-23.5505, -46.6333)
- Device ID: `emulator-5554`

#### 🧑‍🦱 Emulador Individual - Passageiro
```bash
cd scripts/emulators
./start_passenger_emulator.sh
```

**Configurações:**
- AVD: `OPTION_Passenger_Pixel8`
- Porta: `5556`
- GPS: Vila Madalena SP (-23.5489, -46.6388)
- Device ID: `emulator-5556`

#### 🚀 Ambos Simultaneamente
```bash
cd scripts/emulators
./start_both_emulators.sh
```

**Recursos:**
- Cria AVDs automaticamente se necessário
- Configura localizações diferentes para teste
- Otimiza configurações para desenvolvimento
- Monitora status dos emuladores

#### 🛑 Parar Todos os Emuladores
```bash
cd scripts/emulators
./stop_all_emulators.sh
```

### Executando Apps nos Emuladores

```bash
# Motorista
flutter run -d emulator-5554

# Passageiro
flutter run -d emulator-5556

# Ambos simultaneamente (terminais separados)
flutter run -d emulator-5554 &
flutter run -d emulator-5556 &
```

### Cenários de Teste

1. **Fluxo Completo de Viagem:**
   - Motorista: Registro → Documentos → Ficar online → Aceitar corrida
   - Passageiro: Registro → Solicitar viagem → Acompanhar → Avaliar

2. **Teste de GPS:**
   ```bash
   # Mover motorista
   adb -s emulator-5554 emu geo fix -46.6350 -23.5520
   
   # Mover passageiro
   adb -s emulator-5556 emu geo fix -46.6400 -23.5500
   ```

3. **Debug e Logs:**
   ```bash
   # Logs do motorista
   adb -s emulator-5554 logcat | grep flutter
   
   # Logs do passageiro
   adb -s emulator-5556 logcat | grep flutter
   ```

## 🏗️ Build

```bash
# APK Android
flutter build apk --release

# iOS (sem codesigning)
flutter build ios --no-codesign

# Web
flutter build web
```

## 🧪 Testes

```bash
# Executar todos os testes
flutter test

# Testes específicos
flutter test test/user_registration_test.dart
flutter test test_platform_settings_direct.dart

# Testes de integração
flutter test integration_test/

# Gerar mocks
./generate_mocks.sh
flutter pub run build_runner build --delete-conflicting-outputs
```

## 📁 Estrutura do Projeto

```
lib/
├── config/           # Configurações (Supabase, API keys, feature flags)
├── controllers/      # Controladores de state management
├── core/            # Utilitários core, error handling, performance
├── debug/           # Utilitários e telas de debug
├── exceptions/      # Classes de exceções customizadas
├── models/          # Modelos de dados (principalmente Supabase)
├── screens/         # Telas da UI organizadas por feature
│   ├── auth/        # Telas de autenticação
│   ├── driver/      # Telas específicas do motorista
│   ├── passenger/   # Telas específicas do passageiro
│   ├── payments/    # Telas de pagamento
│   ├── stepper/     # Fluxos de onboarding
│   ├── trip/        # Telas relacionadas à viagem
│   └── wallet/      # Gerenciamento de carteira
├── services/        # Lógica de negócio e serviços de API
├── theme/           # Temas Material Design 3
├── utils/           # Funções utilitárias e helpers
├── validators/      # Lógica de validação de entrada
├── widgets/         # Componentes UI reutilizáveis
└── main.dart        # Ponto de entrada da aplicação
```

## 🔧 Serviços Principais

- **UserService**: Gerenciamento de usuários com integração auth
- **AuthService**: Autenticação e autorização (incluindo bypass para testes)
- **TripService**: Gerenciamento do ciclo de vida da viagem
- **DriverService**: Operações e status do motorista
- **LocationService**: Manipulação de GPS e localização
- **PaymentService**: Integração de pagamentos Asaas
- **NotificationService**: Notificações push OneSignal

## ⚙️ Configuração

### Variáveis de Ambiente

```bash
export SUPABASE_URL=https://qlbwacmavngtonauxnte.supabase.co
export SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
export ASAAS_API_KEY=seu_api_key
export GOOGLE_MAPS_API_KEY=seu_maps_key
```

A configuração é tratada em `lib/config/app_config.dart` com padrões de produção.

## 🐛 Troubleshooting

### Problemas com Emuladores
- Execute `flutter doctor -v` para diagnosticar
- Verifique se `ANDROID_SDK_ROOT` está configurado
- Use `./stop_all_emulators.sh` para limpar emuladores travados

### Problemas de Autenticação
- Emuladores usam automaticamente bypass auth (mais confiável)
- Dispositivos físicos usam auth normal do Supabase
- Verifique logs com `flutter logs`

### Conectividade
```bash
# Testar conexão
adb shell ping google.com

# Reiniciar ADB
adb kill-server && adb start-server
```

## 📚 Documentação Adicional

- [CLAUDE.md](CLAUDE.md) - Guia para desenvolvimento com Claude
- [EMULATOR_AUTH_GUIDE.md](EMULATOR_AUTH_GUIDE.md) - Solução de problemas de auth
- [scripts/emulators/TESTING_GUIDE.md](scripts/emulators/TESTING_GUIDE.md) - Guia completo de testes

## 🤝 Contribuição

1. Clone o repositório
2. Configure o ambiente de desenvolvimento
3. Use os scripts de emuladores para teste
4. Execute os testes antes de fazer commit
5. Siga os padrões existentes de código

## 📄 Licença

Este projeto está licenciado sob a licença MIT.

---

**🚗 OPTION - Conectando pessoas através da mobilidade urbana**