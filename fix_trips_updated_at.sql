-- =============================================================================
-- CORREÇÃO: Adicionar coluna updated_at à tabela trips
-- =============================================================================
-- 
-- PROBLEMA IDENTIFICADO:
-- A tabela 'trips' não possui a coluna 'updated_at' no banco de dados,
-- mas o modelo Trip.dart espera essa coluna e tenta usá-la em operações
-- de inserção e atualização.
--
-- SOLUÇÃO:
-- 1. Adicionar a coluna updated_at à tabela trips
-- 2. Definir valor padrão como now()
-- 3. Atualizar registros existentes
-- 4. Criar trigger para atualização automática
--
-- =============================================================================

BEGIN;

-- Verificar estrutura antes da correção
SELECT 'ANTES DA CORREÇÃO - Colunas da tabela trips:' as info;
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'trips' 
ORDER BY ordinal_position;

-- Adicionar coluna updated_at se não existir
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'trips' 
        AND column_name = 'updated_at'
    ) THEN
        -- Adicionar a coluna updated_at
        ALTER TABLE trips 
        ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();
        
        -- Atualizar registros existentes com o valor de created_at
        UPDATE trips 
        SET updated_at = created_at 
        WHERE updated_at IS NULL;
        
        RAISE NOTICE 'Coluna updated_at adicionada à tabela trips';
    ELSE
        RAISE NOTICE 'Coluna updated_at já existe na tabela trips';
    END IF;
END $$;

-- Criar ou recriar a função de trigger para updated_at (se não existir)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Criar trigger para atualizar updated_at automaticamente
DROP TRIGGER IF EXISTS update_trips_updated_at ON trips;
CREATE TRIGGER update_trips_updated_at
    BEFORE UPDATE ON trips
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Verificar estrutura após a correção
SELECT 'APÓS A CORREÇÃO - Colunas da tabela trips:' as info;
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'trips' 
ORDER BY ordinal_position;

-- Verificar se o trigger foi criado
SELECT 'TRIGGERS na tabela trips:' as info;
SELECT trigger_name, event_manipulation, action_timing
FROM information_schema.triggers
WHERE event_object_table = 'trips';

SELECT '✅ SUCESSO: Coluna updated_at adicionada e trigger configurado para trips' as resultado;

COMMIT;

-- =============================================================================
-- INSTRUÇÕES DE USO:
-- =============================================================================
-- 
-- 1. Execute este script no Supabase SQL Editor
-- 2. Verifique se não há erros na execução
-- 3. Teste a funcionalidade de criar/atualizar viagens no app
-- 4. A coluna updated_at será automaticamente atualizada em cada UPDATE
--