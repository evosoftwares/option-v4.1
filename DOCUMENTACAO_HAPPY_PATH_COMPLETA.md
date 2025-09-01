# 📱 Documentação Completa do Happy Path - Aplicativo Option

## 🎯 Visão Geral

Este documento detalha o fluxo principal (Happy Path) do aplicativo Option, um sistema de transporte por aplicativo que conecta passageiros e motoristas. O Happy Path representa o caminho ideal que um usuário percorre desde o primeiro acesso até a conclusão bem-sucedida de uma viagem.

---

## 🔐 1. FLUXO DE AUTENTICAÇÃO E ONBOARDING

### 1.1 Primeiro Acesso - Registro

**Tela:** `LoginScreen` (`/login`)
- **Ação do Usuário:** Clica em "Criar conta"
- **Navegação:** → `RegisterScreen` (`/register`)

**Tela:** `RegisterScreen` (`/register`)
- **Campos:** Nome completo, email, senha, confirmação de senha
- **Validações:** Email único, senha forte, confirmação de senha
- **Ação do Sistema:** 
  - Cria conta no Supabase via `signUp()`
  - Envia email de confirmação
- **Navegação:** → `UserTypeScreen` (`/select_user_type`) com argumentos (nome, email)

### 1.2 Seleção de Tipo de Usuário

**Tela:** `UserTypeScreen` (`/select_user_type`)
- **Opções:** Passageiro ou Motorista
- **Ação do Sistema:** 
  - Armazena dados no `StepperController`
  - Define `userType` (passenger/driver)
- **Navegação:** → `UserRegistrationStepper` (`/registration_stepper`)

### 1.3 Processo de Registro Completo (Stepper)

**Tela:** `UserRegistrationStepper` (`/registration_stepper`)

#### Step 1: Telefone (`PhoneStep`)
- **Campo:** Número de telefone com validação
- **Validação:** Formato brasileiro, número único
- **Ação:** Armazena no `StepperController`

#### Step 2: Foto (`PhotoStep`)
- **Ação:** Upload de foto de perfil
- **Validação:** Formato de imagem válido
- **Armazenamento:** Supabase Storage

#### Step 3: Locais Favoritos (`PlacesStep`)
- **Ação:** Adicionar locais favoritos (casa, trabalho, outros)
- **Integração:** Google Places API
- **Armazenamento:** Tabela `saved_places`

#### Finalização do Registro
- **Ação do Sistema:**
  - Cria registro na tabela `app_users`
  - Cria registro específico (`passengers` ou `drivers`)
  - Salva locais favoritos
  - Configura perfil completo
- **Navegação:** → Tela principal baseada no tipo de usuário

### 1.4 Login de Usuário Existente

**Tela:** `LoginScreen` (`/login`)
- **Campos:** Email e senha
- **Ação do Sistema:**
  - Autentica via `Supabase.signInWithPassword()`
  - Verifica existência em `app_users` via `UserService.userExists()`
  - **Se usuário não existe:** → `/select_user_type`
  - **Se usuário existe:** → Tela principal baseada em `userType`

**Navegação Pós-Login:**
- **Motorista:** → `DriverHomeScreen` (`/driver_home`)
- **Passageiro:** → `PassengerHomeScreen` (`/home`)

---

## 🚗 2. FLUXO PRINCIPAL DO PASSAGEIRO

### 2.1 Tela Principal do Passageiro

**Tela:** `PassengerHomeScreen` (`/home`)
- **Componentes:**
  - Mapa do Google Maps em tela cheia
  - `DraggableScrollableSheet` na parte inferior
  - Botão de notificações
  - Botão de menu
- **Funcionalidades:**
  - Visualização da localização atual
  - Acesso rápido a locais favoritos
  - Botão "Para onde?" para iniciar viagem

### 2.2 Seleção de Destino e Opções

**Ação:** Usuário clica em "Para onde?"
**Navegação:** → `TripOptionsScreen` (`/trip_options`)

**Tela:** `TripOptionsScreen`
- **Seleção de Origem:** Localização atual ou endereço personalizado
- **Seleção de Destino:** 
  - Busca por endereço (Google Places API)
  - Seleção de locais favoritos
  - Histórico de destinos
- **Opções de Viagem:**
  - Categoria do veículo (econômico, conforto, premium)
  - Preferências especiais:
    - Viagem com pet
    - Ar-condicionado
    - Transporte de compras
  - Código promocional
- **Cálculo de Preço:** Estimativa automática baseada em distância e categoria
- **Ação:** Confirmar solicitação

### 2.3 Seleção e Confirmação do Motorista

**Navegação:** → `DriverSelectionScreen` (`/driver_selection`)

**Tela:** `DriverSelectionScreen`
- **Processo Automático:**
  - Sistema cria `TripRequest` no banco de dados
  - `TripRequestManager` inicia processo de matching
  - Busca motoristas disponíveis na região
  - Envia notificações para motoristas elegíveis
- **Interface do Usuário:**
  - Mapa mostrando motoristas próximos
  - Indicador de "Procurando motorista..."
  - Opção de cancelar solicitação
  - Timer de timeout (configurável)

### 2.4 Aguardando Motorista

**Navegação:** → `WaitingDriverScreen` (`/waiting_driver`)

**Tela:** `WaitingDriverScreen`
- **Informações Exibidas:**
  - Dados do motorista (nome, foto, avaliação)
  - Informações do veículo (modelo, placa, cor)
  - Tempo estimado de chegada
  - Localização do motorista em tempo real
- **Funcionalidades:**
  - Rastreamento GPS do motorista
  - Chat com o motorista
  - Opção de cancelar (com possível taxa)
  - Botão de emergência

### 2.5 Durante a Viagem

**Navegação:** → `PassengerTripScreen` (`/passenger_trip`)

**Tela:** `PassengerTripScreen`
- **Mapa em Tempo Real:**
  - Rota planejada
  - Localização atual do veículo
  - Progresso da viagem
- **Informações da Viagem:**
  - Tempo estimado de chegada
  - Distância restante
  - Valor atualizado da corrida
- **Funcionalidades:**
  - Chat com motorista
  - Compartilhamento de localização
  - Botão de emergência
  - Adicionar paradas extras

### 2.6 Finalização e Pagamento

**Processo Automático:**
- Motorista marca viagem como finalizada
- Sistema calcula valor final baseado em:
  - Distância percorrida
  - Tempo de viagem
  - Categoria do veículo
  - Taxas adicionais (pet, paradas, etc.)
  - Desconto de cupom promocional

**Pagamento Automático:**
- `PaymentProcessorService.processTripPayment()`
- Débito automático da carteira digital
- Cálculo de comissão da plataforma (10%)
- Crédito para o motorista

**Tela de Avaliação:**
- Avaliação do motorista (1-5 estrelas)
- Comentários opcionais
- Opção de gorjeta
- Recibo da viagem

---

## 🚙 3. FLUXO DO MOTORISTA

### 3.1 Tela Principal do Motorista

**Tela:** `DriverHomeScreen` (`/driver_home`)
- **Status de Disponibilidade:**
  - Toggle Online/Offline
  - Indicador visual de status
- **Mapa Interativo:**
  - Localização atual
  - Zonas de operação
  - Demanda em tempo real
- **Informações do Dia:**
  - Ganhos acumulados
  - Número de viagens
  - Tempo online
  - Avaliação média

### 3.2 Recebimento de Solicitações

**Processo Automático:**
- `TripRequestManager` identifica motoristas elegíveis
- Envia notificação via `NotificationService`
- Exibe solicitação na `DriverRequestsScreen`

**Tela:** `DriverRequestsScreen` (`/driver-requests`)
- **Informações da Solicitação:**
  - Dados do passageiro (nome, avaliação)
  - Origem e destino
  - Distância até o passageiro
  - Valor estimado da corrida
  - Preferências especiais
- **Timer de Resposta:** Countdown visual (30-60 segundos)
- **Ações Disponíveis:**
  - Aceitar solicitação
  - Recusar solicitação

### 3.3 Aceitação e Navegação até o Passageiro

**Ação:** Motorista aceita a solicitação
**Processo do Sistema:**
- Atualiza status da `TripRequest` para "accepted"
- Cria registro na tabela `trips`
- Notifica o passageiro
- Inicia navegação GPS

**Navegação:** → `DriverTripScreen` (`/driver_trip`)

**Fase: "A caminho do passageiro"**
- **Mapa com Rota:** Navegação GPS até a origem
- **Informações do Passageiro:** Nome, foto, telefone
- **Funcionalidades:**
  - Chat com passageiro
  - Ligação direta
  - Botão "Cheguei" ao alcançar origem

### 3.4 Durante a Viagem

**Fase: "Em viagem"**
- **Ação:** Motorista clica "Iniciar viagem" ao embarcar passageiro
- **Navegação GPS:** Rota otimizada até o destino
- **Rastreamento:**
  - Localização em tempo real
  - Cálculo automático de distância/tempo
  - Atualização de preço dinâmica
- **Funcionalidades:**
  - Chat com passageiro
  - Paradas adicionais
  - Botão de emergência

### 3.5 Finalização da Viagem

**Ação:** Motorista clica "Finalizar viagem" ao chegar ao destino
**Processo do Sistema:**
- Calcula valores finais
- Processa pagamento automático
- Atualiza estatísticas do motorista
- Libera motorista para novas solicitações

**Tela de Avaliação:**
- Avaliação do passageiro
- Comentários sobre a viagem
- Resumo de ganhos

---

## 💰 4. SISTEMA DE PAGAMENTOS

### 4.1 Métodos de Pagamento Disponíveis

**Implementados:**
- **Carteira Digital:** Sistema principal com saldo e transações
- **PIX:** Integração com Asaas para pagamentos instantâneos
- **Cupons Promocionais:** Códigos de desconto

**Em Desenvolvimento:**
- **Cartão de Crédito/Débito:** Estrutura criada

### 4.2 Fluxo de Pagamento da Viagem

**Processo Automático (`PaymentProcessorService`):**

1. **Cálculo do Valor Final:**
   - Valor base da corrida
   - Aplicação de desconto promocional
   - Taxas adicionais (pet, paradas, etc.)

2. **Verificação de Saldo:**
   - Confirma saldo suficiente na carteira
   - Falha se saldo insuficiente

3. **Processamento:**
   - Débito da carteira do passageiro
   - Cálculo da comissão da plataforma (10%)
   - Crédito para carteira do motorista

4. **Registro de Transações:**
   - `PassengerWalletTransaction` (débito)
   - `DriverWalletTransaction` (crédito)
   - Atualização de status da viagem

### 4.3 Recarga de Carteira (PIX)

**Fluxo PIX (`AsaasService`):**
1. Usuário solicita recarga
2. Sistema gera QR Code PIX
3. Usuário paga via app bancário
4. Webhook confirma pagamento
5. Saldo é creditado automaticamente

---

## 🔔 5. FUNCIONALIDADES AUXILIARES

### 5.1 Sistema de Notificações

**Tipos de Notificação:**
- **trip_request:** Solicitações para motoristas
- **trip_update:** Atualizações de status da viagem
- **chat_message:** Mensagens do chat
- **emergency:** Alertas de emergência
- **general:** Notificações administrativas

**Canais de Entrega:**
- Push notifications (OneSignal)
- Notificações locais
- In-app notifications

### 5.2 Navegação e Menus

**Menu do Passageiro (`UserMenuScreen`):**
- Perfil e configurações
- Carteira digital
- Histórico de viagens
- Locais salvos
- Notificações
- Ajuda e suporte

**Menu do Motorista (`DriverMenuScreen`):**
- Perfil e documentos
- Carteira e ganhos
- Estatísticas
- Configurações do veículo
- Zonas de operação
- Horários de trabalho
- Preços personalizados

### 5.3 Histórico de Viagens

**Tela:** `TripHistoryScreen` (`/trip_history`)
- **Funcionalidades:**
  - Lista de viagens passadas
  - Filtros por data e status
  - Detalhes de cada viagem
  - Recibos e comprovantes
  - Re-avaliação de viagens

### 5.4 Carteira Digital

**Tela:** `WalletScreen` (`/wallet`)
- **Passageiro:**
  - Saldo atual
  - Histórico de transações
  - Recarga via PIX
  - Métodos de pagamento
- **Motorista:**
  - Saldo disponível
  - Ganhos do dia/semana/mês
  - Histórico de recebimentos
  - Solicitação de saque

### 5.5 Locais Salvos

**Tela:** `SavedPlacesScreen` (`/saved_places`)
- **Funcionalidades:**
  - Adicionar/editar/remover locais
  - Categorização (casa, trabalho, outros)
  - Integração com Google Places
  - Acesso rápido durante solicitação

### 5.6 Sistema de Emergência

**Tela:** `EmergencyScreen` (`/emergency`)
- **Funcionalidades:**
  - Botão de pânico
  - Contatos de emergência
  - Compartilhamento de localização
  - Histórico de emergências
  - Ligação automática para autoridades

---

## 🔄 6. FLUXOS DE TRANSIÇÃO E ESTADOS

### 6.1 Estados da Viagem

```
TripRequest: pending → accepted → expired/cancelled
Trip: ongoing → completed → cancelled
```

### 6.2 Estados do Motorista

```
Driver: offline → online → busy → offline
```

### 6.3 Transições Críticas

**Matching de Viagem:**
```
Passageiro solicita → Sistema busca motoristas → Notifica motoristas → Motorista aceita → Viagem criada
```

**Execução da Viagem:**
```
Motorista aceita → A caminho → Chegou → Em viagem → Finalizada → Pagamento → Avaliação
```

---

## ⚡ 7. PONTOS CRÍTICOS DO HAPPY PATH

### 7.1 Dependências Externas

- **Google Maps API:** Mapas, geocoding, rotas
- **Supabase:** Autenticação, banco de dados, storage
- **OneSignal:** Push notifications
- **Asaas:** Processamento de pagamentos PIX

### 7.2 Validações Essenciais

- **Saldo suficiente** antes de aceitar viagem
- **Motorista disponível** na região
- **Conectividade GPS** durante a viagem
- **Status de pagamento** antes de finalizar

### 7.3 Tratamento de Erros

- **Timeout de matching:** Notificar "nenhum motorista encontrado"
- **Falha de pagamento:** Bloquear finalização até resolução
- **Perda de GPS:** Manter último estado conhecido
- **Desconexão:** Sincronizar ao reconectar

---

## 📊 8. MÉTRICAS E MONITORAMENTO

### 8.1 KPIs do Happy Path

- **Taxa de conversão:** Registro → Primeira viagem
- **Tempo de matching:** Solicitação → Motorista aceita
- **Taxa de conclusão:** Viagens iniciadas → Finalizadas
- **Satisfação:** Avaliações médias

### 8.2 Pontos de Monitoramento

- Tempo de resposta do matching
- Taxa de cancelamento por etapa
- Falhas de pagamento
- Erros de GPS/navegação

---

## 🎯 CONCLUSÃO

O Happy Path do aplicativo Option representa um fluxo completo e otimizado que vai desde o primeiro acesso do usuário até a conclusão bem-sucedida de viagens. O sistema foi projetado para minimizar atritos e maximizar a experiência do usuário, com automação inteligente em pontos críticos como matching de motoristas e processamento de pagamentos.

**Principais Forças:**
- Onboarding simplificado e guiado
- Matching automático e eficiente
- Pagamentos totalmente automatizados
- Interface intuitiva e responsiva
- Sistema robusto de notificações

**Áreas de Atenção:**
- Dependência de conectividade estável
- Necessidade de motoristas ativos na região
- Manutenção de saldo na carteira
- Precisão do GPS em áreas urbanas densas

Este documento serve como referência para desenvolvimento, testes e otimização contínua do aplicativo, garantindo que o Happy Path permaneça fluido e eficiente para todos os usuários.