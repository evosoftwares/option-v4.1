#!/usr/bin/env python3
"""
Script para adicionar colunas faltantes na tabela driver_excluded_zones
"""

import os
import requests
import json
from supabase import create_client, Client

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_KEY = os.getenv('SUPABASE_ANON_KEY') or "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def execute_sql_via_api(sql_command):
    """Executa comando SQL via API REST do Supabase"""
    url = f"{SUPABASE_URL}/rest/v1/rpc/execute_sql"
    
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
    }
    
    payload = {
        'sql': sql_command
    }
    
    try:
        response = requests.post(url, headers=headers, json=payload)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            print("✅ SQL executado com sucesso!")
            if response.text:
                print(f"Resposta: {response.text}")
            return True
        else:
            print(f"❌ Erro: {response.status_code}")
            print(f"Resposta: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro na requisição: {e}")
        return False

def check_table_structure():
    """Verifica a estrutura atual da tabela"""
    sql = """
    SELECT column_name, data_type, is_nullable, column_default
    FROM information_schema.columns 
    WHERE table_name = 'driver_excluded_zones' 
    AND table_schema = 'public'
    ORDER BY ordinal_position;
    """
    
    print("🔍 Verificando estrutura da tabela...")
    
    url = f"{SUPABASE_URL}/rest/v1/rpc/execute_sql"
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': 'application/json'
    }
    
    payload = {'sql': sql}
    
    try:
        response = requests.post(url, headers=headers, json=payload)
        if response.status_code == 200:
            result = response.json()
            print("📋 Colunas atuais:")
            for row in result:
                print(f"  - {row['column_name']}: {row['data_type']} (nullable: {row['is_nullable']})")
            return result
        else:
            print(f"❌ Erro ao verificar estrutura: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Erro: {e}")
        return None

def add_missing_columns():
    """Adiciona colunas que faltam na tabela"""
    
    # Adicionar coluna keyword
    add_keyword_sql = """
    DO $$
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'driver_excluded_zones' 
            AND column_name = 'keyword'
        ) THEN
            ALTER TABLE public.driver_excluded_zones ADD COLUMN keyword text;
        END IF;
    END $$;
    """
    
    print("➕ Adicionando coluna 'keyword'...")
    if not execute_sql_via_api(add_keyword_sql):
        return False
    
    # Adicionar coluna zone_type
    add_zone_type_sql = """
    DO $$
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'driver_excluded_zones' 
            AND column_name = 'zone_type'
        ) THEN
            ALTER TABLE public.driver_excluded_zones 
            ADD COLUMN zone_type text CHECK (zone_type IN ('rua', 'bairro', 'cidade', 'estado', 'regiao'));
        END IF;
    END $$;
    """
    
    print("➕ Adicionando coluna 'zone_type'...")
    if not execute_sql_via_api(add_zone_type_sql):
        return False
    
    # Adicionar coluna reason
    add_reason_sql = """
    DO $$
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'driver_excluded_zones' 
            AND column_name = 'reason'
        ) THEN
            ALTER TABLE public.driver_excluded_zones ADD COLUMN reason text;
        END IF;
    END $$;
    """
    
    print("➕ Adicionando coluna 'reason'...")
    if not execute_sql_via_api(add_reason_sql):
        return False
    
    # Migrar dados existentes
    migrate_data_sql = """
    UPDATE public.driver_excluded_zones 
    SET 
        keyword = neighborhood_name,
        zone_type = 'bairro'
    WHERE keyword IS NULL;
    """
    
    print("🔄 Migrando dados existentes...")
    if not execute_sql_via_api(migrate_data_sql):
        return False
    
    return True

def create_indexes():
    """Cria índices necessários"""
    indexes_sql = """
    CREATE INDEX IF NOT EXISTS idx_excluded_zones_keyword 
    ON public.driver_excluded_zones USING gin (to_tsvector('portuguese', keyword));
    
    CREATE INDEX IF NOT EXISTS idx_excluded_zones_type 
    ON public.driver_excluded_zones (zone_type);
    
    CREATE INDEX IF NOT EXISTS idx_driver_excluded_zones_driver_keyword
    ON public.driver_excluded_zones (driver_id, keyword);
    """
    
    print("📊 Criando índices adicionais...")
    return execute_sql_via_api(indexes_sql)

def test_insert():
    """Testa inserção na tabela com as novas colunas"""
    try:
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        
        # Busca um driver para teste
        drivers = supabase.table('drivers').select('id').limit(1).execute()
        
        if not drivers.data:
            print("❌ Nenhum driver encontrado para teste")
            return False
        
        driver_id = drivers.data[0]['id']
        
        # Tenta inserir uma exclusão de teste
        test_data = {
            'driver_id': driver_id,
            'neighborhood_name': 'Centro',
            'city': 'São Paulo',
            'state': 'SP',
            'keyword': 'Centro',
            'zone_type': 'bairro',
            'reason': 'Teste de funcionalidade após correção'
        }
        
        result = supabase.table('driver_excluded_zones').insert(test_data).execute()
        
        if result.data:
            print(f"✅ Inserção de teste bem-sucedida! ID: {result.data[0]['id']}")
            
            # Remove o registro de teste
            supabase.table('driver_excluded_zones').delete().eq('id', result.data[0]['id']).execute()
            print("🧹 Registro de teste removido")
            
            return True
        else:
            print("❌ Falha na inserção de teste")
            return False
            
    except Exception as e:
        print(f"❌ Erro no teste de inserção: {e}")
        return False

def main():
    print("🔧 Corrigindo estrutura da tabela driver_excluded_zones...")
    print(f"🔗 URL: {SUPABASE_URL}")
    
    # Verifica estrutura atual
    current_structure = check_table_structure()
    if not current_structure:
        print("❌ Não foi possível verificar a estrutura da tabela")
        return
    
    # Adiciona colunas faltantes
    print("\n🔧 Adicionando colunas faltantes...")
    if add_missing_columns():
        print("✅ Colunas adicionadas com sucesso!")
    else:
        print("❌ Falha ao adicionar colunas")
        return
    
    # Cria índices
    print("\n📊 Criando índices...")
    if create_indexes():
        print("✅ Índices criados com sucesso!")
    else:
        print("❌ Falha ao criar índices")
    
    # Verifica estrutura final
    print("\n🔍 Verificando estrutura final...")
    final_structure = check_table_structure()
    
    # Testa a funcionalidade
    print("\n🧪 Testando funcionalidade...")
    if test_insert():
        print("✅ Funcionalidade de adicionar exclusões está funcionando!")
        print("\n🎉 Correção concluída com sucesso!")
    else:
        print("❌ Ainda há problemas na funcionalidade")

if __name__ == "__main__":
    main()