# 🗺️ Mapeamento de Dependências e Relacionamentos Críticos

## 📊 **Estrutura Atual do Banco de Dados**

### **Tabela Central: `app_users`**
```sql
app_users (
  id UUID PRIMARY KEY,           -- Auth user ID
  user_id UUID,                  -- ⚠️ DUPLICADO - mesmo que id
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,       -- ⚠️ Dados corrompidos identificados
  phone TEXT NOT NULL,           -- ⚠️ Telefones temporários para teste
  photo_url TEXT,
  user_type TEXT NOT NULL,       -- 'passenger' | 'driver'
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
)
```

### **Relacionamentos Críticos Identificados**

#### **1. app_users → passengers (1:1)**
```sql
passengers (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES app_users(id),  -- FK crítica
  consecutive_cancellations INTEGER DEFAULT 0,
  total_trips INTEGER DEFAULT 0,
  average_rating NUMERIC,
  payment_method_id UUID REFERENCES payment_methods(id)
)
```
**Dependências:**
- `UserService._createPassengerRecord()` cria automaticamente
- `WalletService` depende da existência do registro de passenger
- `TripService` usa passenger_id para viagens

#### **2. app_users → drivers (1:1)**
```sql
drivers (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES app_users(id),  -- FK crítica
  cnh_number TEXT NOT NULL,
  vehicle_brand TEXT,
  vehicle_model TEXT,
  vehicle_plate TEXT,
  approval_status TEXT DEFAULT 'pending',
  is_online BOOLEAN DEFAULT FALSE,
  current_latitude NUMERIC,
  current_longitude NUMERIC,
  -- ... mais 20+ campos
)
```
**Dependências:**
- `UserService._createDriverRecord()` cria com dados placeholder
- `DriverService` para todas operações de motorista
- `LocationService` atualiza coordenadas
- `TripService` usa driver_id para viagens

#### **3. Relacionamentos com Sistema de Viagens**

```sql
trips (
  passenger_id UUID REFERENCES passengers(id),
  driver_id UUID REFERENCES drivers(id),
  -- Cascata crítica: app_users → passengers/drivers → trips
)

driver_offers (
  request_id UUID,
  driver_id UUID REFERENCES drivers(id)
)

trip_requests (
  passenger_id UUID REFERENCES passengers(id)
)
```

#### **4. Sistema de Pagamentos**
```sql
payment_methods (
  user_id UUID REFERENCES app_users(id),
  -- Usado por passengers.payment_method_id
)

passenger_wallet (
  passenger_id UUID REFERENCES passengers(id)
)

passenger_wallet_transactions (
  passenger_id UUID REFERENCES passengers(id)
)
```

#### **5. Sistema de Localização e Zonas**
```sql
driver_operation_zones (
  driver_id UUID REFERENCES drivers(id)
)

driver_excluded_zones (
  driver_id UUID REFERENCES drivers(id)
)
```

#### **6. Sistema de Documentos**
```sql
driver_documents (
  driver_id UUID REFERENCES drivers(id)
)
```

---

## ⚠️ **PONTOS CRÍTICOS IDENTIFICADOS**

### **1. Cascata de Dependências Frágil**
```
auth.users → app_users → passengers/drivers → trips/payments/zones
```
**Risco:** Qualquer problema em app_users quebra toda a cadeia

### **2. Campos Duplicados Problemáticos**
- `app_users.id` vs `app_users.user_id` (mesmo valor)
- Queries usam ambos inconsistentemente
- Migração pode quebrar FKs existentes

### **3. Dados Corrompidos Confirmados**
```sql
-- Encontrados no banco:
full_name LIKE '%missing_passenger_records%'
full_name LIKE '%{%}%'  -- JSON strings
phone LIKE '%-1640995%'  -- Telefones temporários com timestamp
```

### **4. Views e Dependências Indiretas**
```sql
available_drivers_view -- Depende de drivers + app_users
daily_statistics -- Agrega dados de trips
```

---

## 🔄 **Fluxos Críticos que NÃO Podem Quebrar**

### **1. Fluxo de Login**
```dart
LoginScreen → UserService.getCurrentUser() → app_users
         → verifica user_type → redireciona para home
```

### **2. Fluxo de Registro**
```dart
RegisterScreen → auth.signUp() → UserTypeScreen 
             → StepperController → (dados temporários)
             → UserService.createUser() → app_users + passengers/drivers
```

### **3. Fluxo de Viagem (Passageiro)**
```dart
PassengerHomeScreen → app_users → passengers → trip_requests
                  → driver_offers → trips → payments
```

### **4. Fluxo de Viagem (Motorista)**
```dart
DriverHomeScreen → app_users → drivers → driver_offers
               → location_updates → trips → earnings
```

### **5. Sistema de Pagamentos**
```dart
WalletService → passengers → payment_methods → transactions
```

---

## 🎯 **Estratégia de Migração Segura**

### **Fase 1: Proteção dos Fluxos Críticos**
1. **Manter compatibilidade** com queries existentes
2. **Backup de relacionamentos** antes de qualquer mudança
3. **Validação contínua** de integridade referencial

### **Fase 2: Migração Incremental**
1. **Adicionar novos campos** sem dropar existentes
2. **Migrar dados gradualmente** com validação
3. **Triggers bidirecionais** para sincronização

### **Fase 3: Cleanup Controlado**
1. **Remover campos duplicados** apenas após validação 100%
2. **Atualizar views** e dependências indiretas
3. **Cleanup de dados corrompidos** com whitelist

---

## 📋 **Checklist de Validação Antes de Mudanças**

- [ ] ✅ Backup completo de todas as tabelas relacionadas
- [ ] ✅ Mapeamento de todas as FKs e constraints
- [ ] ✅ Identificação de todas as views dependentes
- [ ] ✅ Lista de services que usam cada tabela
- [ ] ✅ Teste de rollback completo
- [ ] ✅ Validação de integridade referencial
- [ ] ✅ Monitoramento de queries em tempo real

---

## 🚨 **Sinais de Alerta Durante Migração**

### **Rollback Imediato Se:**
- Integridade referencial < 95%
- Queries críticas falhando > 1%
- Usuários não conseguem fazer login
- Sistema de pagamentos com erro
- Dados corrompidos aumentando

### **Monitoramento Contínuo:**
- Contagem de registros em cada tabela
- Logs de erro nos services críticos
- Tempo de resposta das queries principais
- Integridade dos relacionamentos FK

Este mapeamento garante que todas as dependências críticas sejam protegidas durante a migração.