-- OneSignal Push & Notificações: Script de alinhamento de esquema (executar no Editor SQL do Supabase)
-- Observações importantes:
-- - Não utiliza RLS nem Functions (conforme política do projeto)
-- - Cria/ajusta tabelas e colunas utilizadas pelo app para OneSignal e histórico de notificações
-- - Idempotente: usa IF NOT EXISTS quando possível

BEGIN;

-- Extensões necessárias para UUID
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Tabela de histórico de notificações (envios)
CREATE TABLE IF NOT EXISTS public.notification_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB,
  sent_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  sender_id UUID,
  platform TEXT NOT NULL DEFAULT 'onesignal',
  status TEXT NOT NULL DEFAULT 'queued', -- queued | sent | failed | partial
  error TEXT
);

-- Índices para consultas operacionais
CREATE INDEX IF NOT EXISTS idx_notification_history_sent_at ON public.notification_history (sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_notification_history_status ON public.notification_history (status);
CREATE INDEX IF NOT EXISTS idx_notification_history_platform ON public.notification_history (platform);

-- Tabela de destinatários por notificação
CREATE TABLE IF NOT EXISTS public.notification_recipients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id UUID NOT NULL REFERENCES public.notification_history(id) ON DELETE CASCADE,
  user_id UUID,
  player_id TEXT NOT NULL,
  delivered_at TIMESTAMPTZ,
  opened_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'pending', -- pending | delivered | opened | failed
  error TEXT
);

CREATE INDEX IF NOT EXISTS idx_notification_recipients_notification_id ON public.notification_recipients(notification_id);
CREATE INDEX IF NOT EXISTS idx_notification_recipients_user_id ON public.notification_recipients(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_recipients_player_id ON public.notification_recipients(player_id);

-- Histórico de tokens OneSignal por usuário/dispositivo
CREATE TABLE IF NOT EXISTS public.onesignal_token_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID,
  role TEXT, -- 'driver' | 'passenger' | outros
  player_id TEXT,
  push_token TEXT,
  device_id TEXT,
  device_platform TEXT, -- 'android' | 'ios' | 'web'
  event TEXT, -- 'created' | 'updated' | 'revoked'
  changed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_onesignal_token_hist_user ON public.onesignal_token_history(user_id, changed_at DESC);
CREATE INDEX IF NOT EXISTS idx_onesignal_token_hist_player ON public.onesignal_token_history(player_id);

-- Alinhar schema de app_users com OneSignal
ALTER TABLE IF EXISTS public.app_users
  ADD COLUMN IF NOT EXISTS onesignal_player_id TEXT,
  ADD COLUMN IF NOT EXISTS push_token TEXT,
  ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMPTZ DEFAULT now(),
  ADD COLUMN IF NOT EXISTS token_active BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS token_updated_at TIMESTAMPTZ DEFAULT now();

CREATE INDEX IF NOT EXISTS idx_app_users_onesignal_player_id ON public.app_users(onesignal_player_id);

-- Alinhar schema de drivers com OneSignal
ALTER TABLE IF EXISTS public.drivers
  ADD COLUMN IF NOT EXISTS onesignal_player_id TEXT,
  ADD COLUMN IF NOT EXISTS push_token TEXT,
  ADD COLUMN IF NOT EXISTS device_id TEXT,
  ADD COLUMN IF NOT EXISTS device_platform TEXT,
  ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMPTZ DEFAULT now(),
  ADD COLUMN IF NOT EXISTS token_active BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS token_updated_at TIMESTAMPTZ DEFAULT now();

CREATE INDEX IF NOT EXISTS idx_drivers_onesignal_player_id ON public.drivers(onesignal_player_id);

-- Observação: Não adicionamos UNIQUE a player_id para evitar conflitos de múltiplos dispositivos por usuário.
-- Caso precise, um índice parcial/composto pode ser criado posteriormente conforme regras de negócio.

COMMIT;