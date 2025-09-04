-- =============================================================================
-- FIX: Adicionar coluna updated_at à tabela driver_documents
-- =============================================================================
-- 
-- PROBLEMA: A tabela driver_documents não possui a coluna updated_at,
-- mas o modelo Dart DriverDocument e o serviço estão tentando usar essa coluna,
-- causando erro: "Could not find the 'updated_at' column of 'driver_documents' in the schema cache"
--
-- SOLUÇÃO: Adicionar a coluna updated_at e configurar trigger para atualizá-la automaticamente
--
-- =============================================================================

BEGIN;

-- Verificar estrutura atual da tabela
SELECT 'ANTES DA CORREÇÃO - Colunas da tabela driver_documents:' as info;
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'driver_documents' 
ORDER BY ordinal_position;

-- Adicionar coluna updated_at se não existir
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'driver_documents' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE driver_documents 
        ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();
        
        -- Atualizar registros existentes com o valor de created_at
        UPDATE driver_documents 
        SET updated_at = created_at 
        WHERE updated_at IS NULL;
        
        RAISE NOTICE 'Coluna updated_at adicionada à tabela driver_documents';
    ELSE
        RAISE NOTICE 'Coluna updated_at já existe na tabela driver_documents';
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
DROP TRIGGER IF EXISTS update_driver_documents_updated_at ON driver_documents;
CREATE TRIGGER update_driver_documents_updated_at
    BEFORE UPDATE ON driver_documents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Verificar estrutura após a correção
SELECT 'APÓS A CORREÇÃO - Colunas da tabela driver_documents:' as info;
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'driver_documents' 
ORDER BY ordinal_position;

-- Verificar se o trigger foi criado
SELECT 'TRIGGERS na tabela driver_documents:' as info;
SELECT trigger_name, event_manipulation, action_timing
FROM information_schema.triggers
WHERE event_object_table = 'driver_documents';

SELECT '✅ SUCESSO: Coluna updated_at adicionada e trigger configurado para driver_documents' as resultado;

COMMIT;

-- =============================================================================
-- INSTRUÇÕES DE USO:
-- =============================================================================
-- 
-- 1. Execute este script no Supabase SQL Editor
-- 2. Verifique se não há erros na execução
-- 3. Teste a funcionalidade de salvar/editar documentos no app
-- 4. A coluna updated_at será automaticamente atualizada em cada UPDATE
--
-- =============================================================================