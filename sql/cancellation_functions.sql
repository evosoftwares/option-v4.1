-- Funções SQL para sistema de cancelamentos e strikes
-- Estas funções devem ser executadas no Supabase

-- 1. Função para incrementar cancelamentos consecutivos do passageiro
CREATE OR REPLACE FUNCTION increment_passenger_cancellations(passenger_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    current_count INTEGER := 0;
    new_count INTEGER := 0;
BEGIN
    -- Verificar se o passageiro existe
    IF NOT EXISTS (SELECT 1 FROM passengers WHERE user_id = passenger_user_id) THEN
        -- Criar registro do passageiro se não existir
        INSERT INTO passengers (user_id, consecutive_cancellations, total_trips, average_rating, created_at, updated_at)
        VALUES (passenger_user_id, 0, 0, 0.0, NOW(), NOW())
        ON CONFLICT (user_id) DO NOTHING;
    END IF;

    -- Incrementar contador de cancelamentos consecutivos
    UPDATE passengers 
    SET consecutive_cancellations = consecutive_cancellations + 1,
        updated_at = NOW()
    WHERE user_id = passenger_user_id
    RETURNING consecutive_cancellations INTO new_count;

    RETURN new_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Função para incrementar cancelamentos consecutivos do motorista
CREATE OR REPLACE FUNCTION increment_driver_cancellations(driver_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    current_count INTEGER := 0;
    new_count INTEGER := 0;
BEGIN
    -- Incrementar contador de cancelamentos consecutivos
    UPDATE drivers 
    SET consecutive_cancellations = consecutive_cancellations + 1,
        updated_at = NOW()
    WHERE user_id = driver_user_id
    RETURNING consecutive_cancellations INTO new_count;

    RETURN new_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Função para resetar cancelamentos consecutivos após viagem completada (passageiro)
CREATE OR REPLACE FUNCTION reset_passenger_cancellations(passenger_user_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE passengers 
    SET consecutive_cancellations = 0,
        updated_at = NOW()
    WHERE user_id = passenger_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Função para resetar cancelamentos consecutivos após viagem completada (motorista)
CREATE OR REPLACE FUNCTION reset_driver_cancellations(driver_user_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE drivers 
    SET consecutive_cancellations = 0,
        updated_at = NOW()
    WHERE user_id = driver_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Função para adicionar ganhos ao motorista (para taxa de cancelamento)
CREATE OR REPLACE FUNCTION add_driver_earnings(driver_user_id UUID, amount NUMERIC, description TEXT DEFAULT NULL)
RETURNS VOID AS $$
DECLARE
    wallet_id UUID;
    driver_id_val UUID;
BEGIN
    -- Buscar o driver_id
    SELECT id INTO driver_id_val FROM drivers WHERE user_id = driver_user_id;
    
    IF driver_id_val IS NULL THEN
        RAISE EXCEPTION 'Motorista não encontrado para o usuário %', driver_user_id;
    END IF;

    -- Criar ou atualizar carteira do motorista
    INSERT INTO driver_wallets (driver_id, available_balance, total_earned, created_at, updated_at)
    VALUES (driver_id_val, amount, amount, NOW(), NOW())
    ON CONFLICT (driver_id) 
    DO UPDATE SET 
        available_balance = driver_wallets.available_balance + amount,
        total_earned = driver_wallets.total_earned + amount,
        updated_at = NOW();

    -- Registrar transação
    INSERT INTO wallet_transactions (wallet_id, amount, type, description, status, created_at)
    VALUES (driver_id_val, amount, 'cancellation_compensation', 
            COALESCE(description, 'Compensação por cancelamento'), 'completed', NOW());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Função para verificar se usuário deve ser suspenso
CREATE OR REPLACE FUNCTION check_suspension_policy()
RETURNS TRIGGER AS $$
BEGIN
    -- Para passageiros
    IF TG_TABLE_NAME = 'passengers' AND NEW.consecutive_cancellations >= 3 THEN
        UPDATE app_users 
        SET status = 'suspended', 
            updated_at = NOW()
        WHERE id = NEW.user_id AND status != 'suspended';
        
        -- Inserir log de suspensão
        INSERT INTO activity_logs (user_id, action, entity_type, entity_id, metadata, created_at)
        VALUES (NEW.user_id, 'user_suspended', 'passenger', NEW.user_id, 
                jsonb_build_object('reason', 'consecutive_cancellations', 'count', NEW.consecutive_cancellations),
                NOW());
    END IF;

    -- Para motoristas
    IF TG_TABLE_NAME = 'drivers' AND NEW.consecutive_cancellations >= 3 THEN
        UPDATE app_users 
        SET status = 'suspended',
            updated_at = NOW()
        WHERE id = NEW.user_id AND status != 'suspended';
        
        -- Inserir log de suspensão
        INSERT INTO activity_logs (user_id, action, entity_type, entity_id, metadata, created_at)
        VALUES (NEW.user_id, 'user_suspended', 'driver', NEW.id,
                jsonb_build_object('reason', 'consecutive_cancellations', 'count', NEW.consecutive_cancellations),
                NOW());
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Criar triggers para suspensão automática
DROP TRIGGER IF EXISTS passenger_suspension_trigger ON passengers;
CREATE TRIGGER passenger_suspension_trigger
    AFTER UPDATE OF consecutive_cancellations ON passengers
    FOR EACH ROW
    WHEN (NEW.consecutive_cancellations >= 3)
    EXECUTE FUNCTION check_suspension_policy();

DROP TRIGGER IF EXISTS driver_suspension_trigger ON drivers;
CREATE TRIGGER driver_suspension_trigger
    AFTER UPDATE OF consecutive_cancellations ON drivers
    FOR EACH ROW
    WHEN (NEW.consecutive_cancellations >= 3)
    EXECUTE FUNCTION check_suspension_policy();

-- 8. Função para resetar cancelamentos após viagem completada (trigger)
CREATE OR REPLACE FUNCTION reset_cancellations_on_trip_completion()
RETURNS TRIGGER AS $$
BEGIN
    -- Se a viagem foi completada, resetar cancelamentos consecutivos
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        -- Resetar cancelamentos do passageiro
        PERFORM reset_passenger_cancellations(NEW.passenger_id);
        
        -- Resetar cancelamentos do motorista
        PERFORM reset_driver_cancellations(NEW.driver_id);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Criar trigger para resetar cancelamentos
DROP TRIGGER IF EXISTS trip_completion_reset_trigger ON trips;
CREATE TRIGGER trip_completion_reset_trigger
    AFTER UPDATE OF status ON trips
    FOR EACH ROW
    WHEN (NEW.status = 'completed')
    EXECUTE FUNCTION reset_cancellations_on_trip_completion();

-- 10. Função para reativar usuário (uso administrativo)
CREATE OR REPLACE FUNCTION reactivate_user(target_user_id UUID, admin_user_id UUID, reason TEXT DEFAULT NULL)
RETURNS BOOLEAN AS $$
BEGIN
    -- Verificar se o usuário admin tem permissão (apenas usuários com status 'admin')
    IF NOT EXISTS (SELECT 1 FROM app_users WHERE id = admin_user_id AND user_type = 'admin') THEN
        RAISE EXCEPTION 'Usuário não tem permissão para reativar contas';
    END IF;

    -- Reativar usuário
    UPDATE app_users 
    SET status = 'active',
        updated_at = NOW()
    WHERE id = target_user_id AND status = 'suspended';

    -- Resetar cancelamentos consecutivos
    UPDATE passengers 
    SET consecutive_cancellations = 0,
        updated_at = NOW()
    WHERE user_id = target_user_id;

    UPDATE drivers 
    SET consecutive_cancellations = 0,
        updated_at = NOW()
    WHERE user_id = target_user_id;

    -- Log da reativação
    INSERT INTO activity_logs (user_id, action, entity_type, entity_id, metadata, created_at)
    VALUES (admin_user_id, 'user_reactivated', 'user', target_user_id,
            jsonb_build_object('reason', COALESCE(reason, 'Reativação administrativa')),
            NOW());

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comentários sobre o uso:
-- Para usar estas funções no código Dart, chame:
-- await _supabase.rpc('increment_passenger_cancellations', params: {'passenger_user_id': userId});
-- await _supabase.rpc('increment_driver_cancellations', params: {'driver_user_id': userId});
-- await _supabase.rpc('add_driver_earnings', params: {'driver_user_id': userId, 'amount': valor, 'description': 'descrição'});
-- await _supabase.rpc('reactivate_user', params: {'target_user_id': userId, 'admin_user_id': adminId, 'reason': 'motivo'});