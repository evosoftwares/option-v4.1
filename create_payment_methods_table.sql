-- Criação da tabela payment_methods no Supabase
-- Execute este script no SQL Editor do Supabase

CREATE TABLE IF NOT EXISTS public.payment_methods (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('wallet', 'pix')),
    is_default BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    pix_data JSONB NULL, -- Para armazenar dados do PIX (key_type, key_value, qr_code_data)
    asaas_customer_id TEXT NULL, -- Para integração com gateway de pagamento
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Índices para otimização
CREATE INDEX IF NOT EXISTS idx_payment_methods_user_id ON public.payment_methods(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_user_active ON public.payment_methods(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_payment_methods_user_default ON public.payment_methods(user_id, is_default);

-- Trigger para updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Remove trigger se já existir e cria novamente
DROP TRIGGER IF EXISTS update_payment_methods_updated_at ON public.payment_methods;
CREATE TRIGGER update_payment_methods_updated_at 
    BEFORE UPDATE ON public.payment_methods 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Políticas RLS (Row Level Security)
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;

-- Remove políticas existentes se houver conflito
DROP POLICY IF EXISTS "Users can view own payment methods" ON public.payment_methods;
DROP POLICY IF EXISTS "Users can insert own payment methods" ON public.payment_methods;
DROP POLICY IF EXISTS "Users can update own payment methods" ON public.payment_methods;
DROP POLICY IF EXISTS "Users can delete own payment methods" ON public.payment_methods;

-- Política: Usuários só podem ver/editar seus próprios métodos de pagamento
CREATE POLICY "Users can view own payment methods" ON public.payment_methods
    FOR SELECT USING (
        user_id IN (SELECT id FROM app_users WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can insert own payment methods" ON public.payment_methods
    FOR INSERT WITH CHECK (
        user_id IN (SELECT id FROM app_users WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can update own payment methods" ON public.payment_methods
    FOR UPDATE USING (
        user_id IN (SELECT id FROM app_users WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can delete own payment methods" ON public.payment_methods
    FOR DELETE USING (
        user_id IN (SELECT id FROM app_users WHERE user_id = auth.uid())
    );

-- Constraint para garantir apenas um método padrão por usuário
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_default_payment_method 
ON public.payment_methods(user_id) 
WHERE is_default = true AND is_active = true;

COMMENT ON TABLE public.payment_methods IS 'Métodos de pagamento dos usuários (PIX, Carteira Digital)';
COMMENT ON COLUMN public.payment_methods.pix_data IS 'JSON com dados do PIX: {"key_type": "cpf|email|phone|random_key", "key_value": "valor_da_chave", "qr_code_data": "dados_qr"}';