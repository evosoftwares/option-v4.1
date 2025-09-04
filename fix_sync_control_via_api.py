#!/usr/bin/env python3
"""
Script para corrigir o erro sync_control via API REST do Supabase
"""

import requests
import json

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk"

def execute_sql(sql_query):
    """Executa uma query SQL via API REST do Supabase"""
    url = f"{SUPABASE_URL}/rest/v1/rpc/exec_sql"
    
    headers = {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=minimal"
    }
    
    payload = {
        "sql": sql_query
    }
    
    try:
        response = requests.post(url, headers=headers, json=payload, timeout=30)
        
        if response.status_code == 200:
            print(f"✅ SQL executado com sucesso")
            if response.text:
                try:
                    result = response.json()
                    return result
                except:
                    return response.text
            return True
        else:
            print(f"❌ Erro na execução: {response.status_code}")
            print(f"Resposta: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro de conexão: {e}")
        return False

def main():
    print("🔧 Iniciando correção do erro sync_control...")
    
    # SQL para corrigir o problema
    fix_sql = """
    -- Desabilitar o trigger problemático temporariamente
    DROP TRIGGER IF EXISTS trigger_sync_app_to_auth ON app_users;
    
    -- Criar versão segura da função is_sync_enabled
    CREATE OR REPLACE FUNCTION is_sync_enabled(feature_name TEXT)
    RETURNS BOOLEAN AS $$
    BEGIN
        -- Verificar se a tabela sync_control existe
        IF EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'sync_control' 
            AND table_schema = 'public'
        ) THEN
            -- Se existe, usar a lógica original
            DECLARE
                enabled_status BOOLEAN;
            BEGIN
                SELECT enabled INTO enabled_status 
                FROM sync_control 
                WHERE sync_control.feature_name = is_sync_enabled.feature_name;
                
                RETURN COALESCE(enabled_status, FALSE);
            END;
        ELSE
            -- Se não existe, retornar FALSE (sincronização desabilitada)
            RETURN FALSE;
        END IF;
    END;
    $$ LANGUAGE plpgsql;
    
    -- Criar versão segura da função controlled_sync_app_to_auth
    CREATE OR REPLACE FUNCTION controlled_sync_app_to_auth()
    RETURNS TRIGGER AS $$
    BEGIN
        -- Sincronização desabilitada por padrão até configuração adequada
        -- Log de sincronização desabilitada (apenas se tabela auth_sync_logs existir)
        BEGIN
            INSERT INTO auth_sync_logs (
                event_type,
                user_id,
                operation,
                source_table,
                target_table,
                error_message,
                sync_status
            ) VALUES (
                TG_OP || '_app_user',
                COALESCE(NEW.id, OLD.id),
                'sync_disabled',
                'app_users',
                'auth.users',
                'Sincronização desabilitada - sync_control não configurado',
                'skipped'
            );
        EXCEPTION WHEN OTHERS THEN
            -- Se auth_sync_logs também não existir, apenas ignora
            NULL;
        END;
        
        RETURN COALESCE(NEW, OLD);
    END;
    $$ LANGUAGE plpgsql;
    """
    
    # Executar a correção
    result = execute_sql(fix_sql)
    
    if result:
        print("✅ Correção aplicada com sucesso!")
        
        # Verificar o status após a correção
        check_sql = """
        SELECT 
            'Trigger Status' as check_type,
            CASE 
                WHEN EXISTS (
                    SELECT 1 FROM information_schema.triggers 
                    WHERE trigger_name = 'trigger_sync_app_to_auth'
                    AND event_object_table = 'app_users'
                ) THEN 'ATIVO'
                ELSE 'INATIVO'
            END as status
        UNION ALL
        SELECT 
            'Sync Control Table' as check_type,
            CASE 
                WHEN EXISTS (
                    SELECT 1 FROM information_schema.tables 
                    WHERE table_name = 'sync_control'
                    AND table_schema = 'public'
                ) THEN 'EXISTE'
                ELSE 'NÃO EXISTE'
            END as status;
        """
        
        print("\n📊 Verificando status após correção...")
        check_result = execute_sql(check_sql)
        
        if check_result:
            print("\n📋 Status atual:")
            if isinstance(check_result, list):
                for item in check_result:
                    print(f"  - {item.get('check_type', 'N/A')}: {item.get('status', 'N/A')}")
        
        print("\n🎯 Agora você pode tentar atualizar o perfil do usuário novamente.")
        print("   O erro 'relation sync_control does not exist' deve estar resolvido.")
        
    else:
        print("❌ Falha na aplicação da correção")
        return False
    
    return True

if __name__ == "__main__":
    main()