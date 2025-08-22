-- Passenger Wallet System Migration (Corrected and Ready)
-- Safe to run multiple times (IF NOT EXISTS and IF NOT EXISTS indexes); policies/triggers are dropped before creation
-- Apply this in Supabase SQL editor or via CLI migrations

-- Ensure UUID generator function is available
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================================
-- 1) Core Tables (order matters for FKs)
-- ==========================================

-- 1.1) Passenger Wallets
CREATE TABLE IF NOT EXISTS passenger_wallets (
    id UUID PRIMARY KEY, -- will be set to passenger_id by trigger
    passenger_id UUID NOT NULL REFERENCES passengers(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    available_balance NUMERIC(10,2) NOT NULL DEFAULT 0.00 CHECK (available_balance >= 0),
    pending_balance NUMERIC(10,2) NOT NULL DEFAULT 0.00 CHECK (pending_balance >= 0),
    total_spent NUMERIC(10,2) NOT NULL DEFAULT 0.00 CHECK (total_spent >= 0),
    total_cashback NUMERIC(10,2) NOT NULL DEFAULT 0.00 CHECK (total_cashback >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_passenger_wallet UNIQUE (passenger_id),
    CONSTRAINT unique_user_wallet UNIQUE (user_id),
    CONSTRAINT wallet_id_equals_passenger_id CHECK (id = passenger_id)
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_passenger_wallets_passenger_id ON passenger_wallets(passenger_id);
CREATE INDEX IF NOT EXISTS idx_passenger_wallets_user_id ON passenger_wallets(user_id);

-- 1.2) Payment Methods (referenced by wallet transactions)
CREATE TABLE IF NOT EXISTS payment_methods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('wallet', 'credit_card', 'debit_card', 'pix')),
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    card_data JSONB,
    pix_data JSONB,
    asaas_customer_id VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payment_methods_user_id ON payment_methods(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_type ON payment_methods(type);
CREATE INDEX IF NOT EXISTS idx_payment_methods_is_default ON payment_methods(is_default);
CREATE INDEX IF NOT EXISTS idx_payment_methods_is_active ON payment_methods(is_active);

-- 1.3) Passenger Promo Codes
CREATE TABLE IF NOT EXISTS passenger_promo_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('percentage', 'fixed', 'free_ride')),
    value NUMERIC(10,2) NOT NULL CHECK (value > 0),
    min_amount NUMERIC(10,2) NOT NULL DEFAULT 0.00 CHECK (min_amount >= 0),
    max_discount NUMERIC(10,2) CHECK (max_discount IS NULL OR max_discount > 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_first_ride_only BOOLEAN NOT NULL DEFAULT FALSE,
    usage_limit INTEGER CHECK (usage_limit IS NULL OR usage_limit > 0),
    usage_count INTEGER NOT NULL DEFAULT 0 CHECK (usage_count >= 0),
    valid_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_until TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_dates_check CHECK (valid_from < valid_until)
);

CREATE INDEX IF NOT EXISTS idx_passenger_promo_codes_code ON passenger_promo_codes(code);
CREATE INDEX IF NOT EXISTS idx_passenger_promo_codes_is_active ON passenger_promo_codes(is_active);
CREATE INDEX IF NOT EXISTS idx_passenger_promo_codes_valid_dates ON passenger_promo_codes(valid_from, valid_until);

-- 1.4) Passenger Wallet Transactions (after payment_methods exists)
CREATE TABLE IF NOT EXISTS passenger_wallet_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL REFERENCES passenger_wallets(id) ON DELETE CASCADE,
    passenger_id UUID NOT NULL REFERENCES passengers(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('credit', 'trip_payment', 'cashback', 'refund', 'cancellation_fee')),
    amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    description TEXT NOT NULL,
    trip_id UUID REFERENCES trips(id) ON DELETE SET NULL,
    payment_method_id UUID REFERENCES payment_methods(id) ON DELETE SET NULL,
    asaas_payment_id VARCHAR(255),
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_pwt_passenger_id ON passenger_wallet_transactions(passenger_id);
CREATE INDEX IF NOT EXISTS idx_pwt_wallet_id ON passenger_wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_pwt_type ON passenger_wallet_transactions(type);
CREATE INDEX IF NOT EXISTS idx_pwt_status ON passenger_wallet_transactions(status);
CREATE INDEX IF NOT EXISTS idx_pwt_created_at ON passenger_wallet_transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_pwt_asaas_payment_id ON passenger_wallet_transactions(asaas_payment_id);

-- 1.5) Passenger Promo Code Usage
CREATE TABLE IF NOT EXISTS passenger_promo_code_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    promo_code_id UUID NOT NULL REFERENCES passenger_promo_codes(id) ON DELETE CASCADE,
    trip_id UUID REFERENCES trips(id) ON DELETE SET NULL,
    original_amount NUMERIC(10,2) NOT NULL CHECK (original_amount > 0),
    discount_amount NUMERIC(10,2) NOT NULL CHECK (discount_amount >= 0),
    final_amount NUMERIC(10,2) NOT NULL CHECK (final_amount >= 0),
    used_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_amounts_check CHECK (original_amount = discount_amount + final_amount)
);

CREATE INDEX IF NOT EXISTS idx_ppcu_user_id ON passenger_promo_code_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_ppcu_promo_code_id ON passenger_promo_code_usage(promo_code_id);
CREATE INDEX IF NOT EXISTS idx_ppcu_trip_id ON passenger_promo_code_usage(trip_id);
CREATE INDEX IF NOT EXISTS idx_ppcu_used_at ON passenger_promo_code_usage(used_at);


-- ==========================================
-- 2) RLS and Policies (drop-then-create for idempotency)
-- ==========================================
ALTER TABLE passenger_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE passenger_wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE passenger_promo_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE passenger_promo_code_usage ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid duplicates on re-run
DROP POLICY IF EXISTS "Users can view their own wallet" ON passenger_wallets;
DROP POLICY IF EXISTS "Users can update their own wallet" ON passenger_wallets;
DROP POLICY IF EXISTS "System can insert passenger wallets" ON passenger_wallets;

DROP POLICY IF EXISTS "Users can view their own wallet transactions" ON passenger_wallet_transactions;
DROP POLICY IF EXISTS "Users can update their own wallet transactions" ON passenger_wallet_transactions;
DROP POLICY IF EXISTS "System can insert wallet transactions" ON passenger_wallet_transactions;

DROP POLICY IF EXISTS "Users can view their own payment methods" ON payment_methods;
DROP POLICY IF EXISTS "Users can insert their own payment methods" ON payment_methods;
DROP POLICY IF EXISTS "Users can update their own payment methods" ON payment_methods;
DROP POLICY IF EXISTS "Users can delete their own payment methods" ON payment_methods;

DROP POLICY IF EXISTS "Users can view active promo codes" ON passenger_promo_codes;

DROP POLICY IF EXISTS "Users can view their own promo code usage" ON passenger_promo_code_usage;
DROP POLICY IF EXISTS "System can insert promo code usage" ON passenger_promo_code_usage;

-- passenger_wallets policies
CREATE POLICY "Users can view their own wallet" ON passenger_wallets
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update their own wallet" ON passenger_wallets
    FOR UPDATE USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "System can insert passenger wallets" ON passenger_wallets
    FOR INSERT WITH CHECK (true);

-- passenger_wallet_transactions policies
CREATE POLICY "Users can view their own wallet transactions" ON passenger_wallet_transactions
    FOR SELECT USING (
        passenger_id IN (
            SELECT id FROM passengers WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own wallet transactions" ON passenger_wallet_transactions
    FOR UPDATE USING (
        passenger_id IN (
            SELECT id FROM passengers WHERE user_id = auth.uid()
        )
    )
    WITH CHECK (
        passenger_id IN (
            SELECT id FROM passengers WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "System can insert wallet transactions" ON passenger_wallet_transactions
    FOR INSERT WITH CHECK (true);

-- payment_methods policies
CREATE POLICY "Users can view their own payment methods" ON payment_methods
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own payment methods" ON payment_methods
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own payment methods" ON payment_methods
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own payment methods" ON payment_methods
    FOR DELETE USING (user_id = auth.uid());

-- passenger_promo_codes (read-only for users)
CREATE POLICY "Users can view active promo codes" ON passenger_promo_codes
    FOR SELECT USING (is_active = TRUE);

-- passenger_promo_code_usage policies
CREATE POLICY "Users can view their own promo code usage" ON passenger_promo_code_usage
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "System can insert promo code usage" ON passenger_promo_code_usage
    FOR INSERT WITH CHECK (true);


-- ==========================================
-- 3) Triggers and Utility Functions
-- ==========================================
-- Standard updated_at trigger function (idempotent)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Auto-maintain updated_at
DROP TRIGGER IF EXISTS update_passenger_wallets_updated_at ON passenger_wallets;
CREATE TRIGGER update_passenger_wallets_updated_at
    BEFORE UPDATE ON passenger_wallets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_payment_methods_updated_at ON payment_methods;
CREATE TRIGGER update_payment_methods_updated_at
    BEFORE UPDATE ON payment_methods
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Ensure wallet.id == passenger_id on insert
CREATE OR REPLACE FUNCTION set_passenger_wallet_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.id IS NULL THEN
        NEW.id := NEW.passenger_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS bi_set_passenger_wallet_id ON passenger_wallets;
CREATE TRIGGER bi_set_passenger_wallet_id
    BEFORE INSERT ON passenger_wallets
    FOR EACH ROW EXECUTE FUNCTION set_passenger_wallet_id();

-- Auto-create wallet when a passenger is created
CREATE OR REPLACE FUNCTION create_passenger_wallet_on_passenger_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO passenger_wallets (passenger_id, user_id, available_balance, pending_balance, total_spent, total_cashback)
    VALUES (NEW.id, NEW.user_id, 0.00, 0.00, 0.00, 0.00)
    ON CONFLICT (passenger_id) DO NOTHING; -- idempotent safeguard
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_create_passenger_wallet ON passengers;
CREATE TRIGGER trigger_create_passenger_wallet
    AFTER INSERT ON passengers
    FOR EACH ROW
    EXECUTE FUNCTION create_passenger_wallet_on_passenger_insert();


-- ==========================================
-- 4) Seed Data and Grants
-- ==========================================
-- Sample promo codes (idempotent)
INSERT INTO passenger_promo_codes (code, type, value, min_amount, max_discount, is_first_ride_only, valid_until)
VALUES
  ('PRIMEIRAVIAGEM', 'percentage', 50.00, 10.00, 25.00, TRUE, NOW() + INTERVAL '1 year'),
  ('CASHBACK10', 'percentage', 10.00, 20.00, 15.00, FALSE, NOW() + INTERVAL '3 months'),
  ('VIAGRAGRATIS', 'free_ride', 35.00, 0.00, 35.00, TRUE, NOW() + INTERVAL '6 months')
ON CONFLICT (code) DO NOTHING;

-- Minimal grants (RLS still applies)
GRANT SELECT, INSERT, UPDATE, DELETE ON passenger_wallets TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON passenger_wallet_transactions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON payment_methods TO authenticated;
GRANT SELECT ON passenger_promo_codes TO authenticated;
GRANT SELECT, INSERT ON passenger_promo_code_usage TO authenticated;

-- Note: Sequences grants removed because all PKs are UUID (no sequences used)