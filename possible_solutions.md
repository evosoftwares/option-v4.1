# Possíveis Soluções para Erro 42P01

## 1. Schema Diferente
```sql
-- Se a tabela estiver em schema diferente
SELECT * FROM information_schema.tables WHERE table_name = 'app_users';

-- Pode ser que esteja em outro schema
SELECT schemaname, tablename FROM pg_tables WHERE tablename = 'app_users';
```

## 2. Nome da Tabela Diferente
```sql
-- Verificar se existe com nome similar
SELECT tablename FROM pg_tables WHERE tablename LIKE '%user%';
```

## 3. Problema de Conexão/Database
- Pode estar conectando em database diferente
- Verificar se o projeto Supabase é o correto

## 4. Solução Temporária - Criar Tabela
```sql
-- Se a tabela realmente não existir, criar:
CREATE TABLE IF NOT EXISTS public.app_users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email text NOT NULL UNIQUE,
    full_name text NOT NULL,
    phone text NOT NULL DEFAULT 'pending',
    photo_url text,
    user_type text NOT NULL,
    status text NOT NULL DEFAULT 'active',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    user_id uuid,
    fcm_token text,
    device_id text,
    device_platform text,
    last_active_at timestamptz DEFAULT now()
);
```

## 5. Para iOS
Verificar se há configurações específicas no iOS que podem estar causando o problema.