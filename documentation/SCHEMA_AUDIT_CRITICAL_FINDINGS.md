# Auditoria Schema Database: Descobertas Críticas

## 🔍 **Análise Completa do Schema Atual**

### ✅ **DESCOBERTAS POSITIVAS:**

**1. Tabela `trip_requests` - Campos Existentes:**
```sql
-- ✅ JÁ EXISTEM (não precisam ser criados):
id                      UUID PRIMARY KEY
passenger_id            UUID NOT NULL
origin_address          TEXT NOT NULL
origin_latitude         NUMERIC NOT NULL
origin_longitude        NUMERIC NOT NULL
origin_neighborhood     TEXT
destination_address     TEXT NOT NULL
destination_latitude    NUMERIC NOT NULL
destination_longitude   NUMERIC NOT NULL
destination_neighborhood TEXT
vehicle_category        TEXT NOT NULL
needs_pet              BOOLEAN DEFAULT false
needs_grocery_space    BOOLEAN DEFAULT false
needs_ac               BOOLEAN DEFAULT false
is_condo_origin        BOOLEAN DEFAULT false
is_condo_destination   BOOLEAN DEFAULT false
number_of_stops        INTEGER DEFAULT 0
status                 TEXT DEFAULT 'searching'
selected_offer_id      UUID (referência a driver_offers)
created_at             TIMESTAMP WITH TIME ZONE DEFAULT now()
expires_at             TIMESTAMP WITH TIME ZONE DEFAULT (now() + '5 minutes')
```

**2. Tabela `drivers` - Campos Essenciais:**
```sql
-- ✅ CAMPOS DE PREÇOS INDIVIDUAIS JÁ EXISTEM:
custom_price_per_km      NUMERIC
custom_price_per_minute  NUMERIC

-- ✅ OUTROS CAMPOS IMPORTANTES:
accepts_pet             BOOLEAN DEFAULT false
accepts_grocery         BOOLEAN DEFAULT false  
accepts_condo           BOOLEAN DEFAULT false
current_latitude        NUMERIC
current_longitude       NUMERIC
is_online              BOOLEAN DEFAULT false
```

**3. Tabela `notifications` - Estrutura Completa:**
```sql
-- ✅ SISTEMA DE NOTIFICAÇÕES JÁ COMPLETO:
id          UUID PRIMARY KEY
user_id     UUID
title       TEXT NOT NULL
body        TEXT NOT NULL
type        TEXT NOT NULL
data        JSONB
priority    TEXT DEFAULT 'normal'
is_read     BOOLEAN DEFAULT false
sent_at     TIMESTAMP WITH TIME ZONE DEFAULT now()
read_at     TIMESTAMP WITH TIME ZONE
```

### ❌ **GAPS CRÍTICOS CONFIRMADOS:**

**1. Tabela `trip_requests` - Campos Faltantes:**
```sql
-- ❌ PRECISAM SER ADICIONADOS:
target_driver_id        UUID REFERENCES drivers(id)
fallback_drivers        UUID[]
accepted_by_driver_id   UUID REFERENCES drivers(id) 
accepted_at            TIMESTAMP WITH TIME ZONE
current_fallback_index INTEGER DEFAULT 0
timeout_count          INTEGER DEFAULT 0
estimated_distance_km  NUMERIC  -- ❌ NÃO ENCONTRADO no schema
estimated_duration_minutes INTEGER -- ❌ NÃO ENCONTRADO no schema
estimated_fare         NUMERIC  -- ❌ NÃO ENCONTRADO no schema
```

**2. Tabela `drivers` - Push Notifications:**
```sql
-- ❌ CAMPO FCM TOKEN NÃO EXISTE:
fcm_token              TEXT  -- Necessário para push notifications
device_platform        TEXT  -- iOS/Android para compatibilidade
```

**3. Tabela `app_users` - Token Management:**
```sql  
-- ❌ CAMPOS DE DEVICE TRACKING AUSENTES:
fcm_token              TEXT
device_id              TEXT
last_active_at         TIMESTAMP WITH TIME ZONE
```

---

## 🎯 **CORREÇÕES OBRIGATÓRIAS**

### **SCRIPT 1: Campos de Trip Requests (CRÍTICO)**
```sql
BEGIN;

-- Adicionar campos para sistema de matching direcionado
ALTER TABLE trip_requests 
ADD COLUMN IF NOT EXISTS target_driver_id UUID REFERENCES drivers(id),
ADD COLUMN IF NOT EXISTS fallback_drivers UUID[],
ADD COLUMN IF NOT EXISTS accepted_by_driver_id UUID REFERENCES drivers(id),
ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS current_fallback_index INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS timeout_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS estimated_distance_km NUMERIC,
ADD COLUMN IF NOT EXISTS estimated_duration_minutes INTEGER,
ADD COLUMN IF NOT EXISTS estimated_fare NUMERIC;

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_trip_requests_target_driver 
    ON trip_requests(target_driver_id);
CREATE INDEX IF NOT EXISTS idx_trip_requests_status_expires 
    ON trip_requests(status, expires_at);
CREATE INDEX IF NOT EXISTS idx_trip_requests_accepted_by 
    ON trip_requests(accepted_by_driver_id);

-- Ajustar default do expires_at para 10 segundos (matching system)
ALTER TABLE trip_requests 
    ALTER COLUMN expires_at SET DEFAULT (now() + '00:00:10'::interval);

COMMIT;
```

### **SCRIPT 2: Push Notifications Infrastructure (CRÍTICO)**
```sql
BEGIN;

-- Adicionar FCM tokens para drivers
ALTER TABLE drivers
ADD COLUMN IF NOT EXISTS fcm_token TEXT,
ADD COLUMN IF NOT EXISTS device_platform TEXT CHECK (device_platform IN ('ios', 'android', 'web')),
ADD COLUMN IF NOT EXISTS last_notification_at TIMESTAMP WITH TIME ZONE;

-- Adicionar FCM tokens para app_users (passageiros)
ALTER TABLE app_users
ADD COLUMN IF NOT EXISTS fcm_token TEXT,
ADD COLUMN IF NOT EXISTS device_id TEXT,
ADD COLUMN IF NOT EXISTS device_platform TEXT CHECK (device_platform IN ('ios', 'android', 'web')),
ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- Índices para otimizar queries de notificação
CREATE INDEX IF NOT EXISTS idx_drivers_fcm_token ON drivers(fcm_token);
CREATE INDEX IF NOT EXISTS idx_app_users_fcm_token ON app_users(fcm_token);

COMMIT;
```

### **SCRIPT 3: Status Enum e Validações (IMPORTANTE)**
```sql
BEGIN;

-- Criar enum para status de trip_requests mais específicos
CREATE TYPE trip_request_status AS ENUM (
    'pending',
    'searching', 
    'accepted',
    'driver_arriving',
    'driver_arrived', 
    'in_progress',
    'completed',
    'cancelled_by_passenger',
    'cancelled_by_driver',
    'expired',
    'no_show'
);

-- Alterar coluna status para usar enum (CUIDADO: pode quebrar dados existentes)
-- ALTER TABLE trip_requests 
--     ALTER COLUMN status TYPE trip_request_status USING status::trip_request_status;

COMMIT;
```

---

## ⚠️ **RECOMENDAÇÕES DE IMPLEMENTAÇÃO**

### **PRIORIDADE 1 - EXECUTAR IMEDIATAMENTE:**
1. **Script 1** (Campos trip_requests) - Sem isso o sistema não funciona
2. **Script 2** (FCM tokens) - Push notifications são essenciais

### **PRIORIDADE 2 - ESTA SEMANA:**
3. **Script 3** (Status enum) - Melhora consistência mas não quebra sistema atual

### **VALIDAÇÃO PÓS-EXECUÇÃO:**
```sql
-- Verificar se campos foram criados corretamente
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'trip_requests' 
AND column_name IN ('target_driver_id', 'fallback_drivers', 'accepted_by_driver_id')
ORDER BY ordinal_position;

-- Verificar FCM tokens
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name IN ('drivers', 'app_users') 
AND column_name = 'fcm_token';
```

---

## 📊 **IMPACTO DAS DESCOBERTAS**

### **Timeline Revisada:**
- **Semana 1**: ✅ Schema modifications (Scripts 1-2) - PRONTO PARA EXECUTAR
- **Semana 2**: 🔧 TripRequestManager implementation  
- **Semana 3**: 🎨 UI Components
- **Semana 4**: 🧪 Testing e Deploy

### **Redução de Riscos:**
- ✅ Campos `expires_at` e `selected_offer_id` já existem
- ✅ Sistema de `driver_offers` já implementado  
- ✅ Preços individuais (`custom_price_per_*`) disponíveis
- ❌ Apenas 9 campos precisam ser adicionados vs 15+ estimados anteriormente

**O sistema está 80% pronto no schema - apenas ajustes pontuais são necessários!**