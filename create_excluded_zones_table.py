#!/usr/bin/env python3
"""
Script para criar a tabela driver_excluded_zones no Supabase
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

def create_excluded_zones_table():
    """Cria a tabela driver_excluded_zones"""
    
    # SQL para criar a tabela
    create_table_sql = """
    CREATE TABLE IF NOT EXISTS public.driver_excluded_zones (
        id uuid DEFAULT gen_random_uuid() NOT NULL,
        driver_id uuid NOT NULL,
        neighborhood_name text NOT NULL,
        city text NOT NULL,
        state text NOT NULL,
        created_at timestamp with time zone DEFAULT now(),
        keyword text,
        zone_type text CHECK (zone_type IN ('rua', 'bairro', 'cidade', 'estado', 'regiao')),
        reason text
    );
    """
    
    print("🔧 Criando tabela driver_excluded_zones...")
    if not execute_sql_via_api(create_table_sql):
        return False
    
    # Adicionar chave primária
    pk_sql = """
    DO $$
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'driver_excluded_zones_pkey' 
            AND table_name = 'driver_excluded_zones'
        ) THEN
            ALTER TABLE public.driver_excluded_zones ADD CONSTRAINT driver_excluded_zones_pkey PRIMARY KEY (id);
        END IF;
    END $$;
    """
    
    print("🔑 Adicionando chave primária...")
    if not execute_sql_via_api(pk_sql):
        return False
    
    # Adicionar chave estrangeira
    fk_sql = """
    DO $$
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'driver_excluded_zones_driver_id_fkey' 
            AND table_name = 'driver_excluded_zones'
        ) THEN
            ALTER TABLE public.driver_excluded_zones 
            ADD CONSTRAINT driver_excluded_zones_driver_id_fkey 
            FOREIGN KEY (driver_id) REFERENCES public.drivers(id) ON DELETE CASCADE;
        END IF;
    END $$;
    """
    
    print("🔗 Adicionando chave estrangeira...")
    if not execute_sql_via_api(fk_sql):
        return False
    
    # Criar índices
    indexes_sql = """
    CREATE INDEX IF NOT EXISTS idx_excluded_zones_driver 
    ON public.driver_excluded_zones (driver_id);
    
    CREATE INDEX IF NOT EXISTS idx_excluded_zones_location 
    ON public.driver_excluded_zones (neighborhood_name, city);
    
    CREATE INDEX IF NOT EXISTS idx_excluded_zones_keyword 
    ON public.driver_excluded_zones USING gin (to_tsvector('portuguese', keyword));
    """
    
    print("📊 Criando índices...")
    if not execute_sql_via_api(indexes_sql):
        return False
    
    return True

def check_table_exists():
    """Verifica se a tabela existe"""
    try:
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        
        # Tenta fazer uma consulta simples na tabela
        result = supabase.table('driver_excluded_zones').select('count', count='exact').limit(1).execute()
        
        print(f"✅ Tabela driver_excluded_zones existe! Registros: {result.count}")
        return True
        
    except Exception as e:
        print(f"❌ Tabela driver_excluded_zones não existe: {e}")
        return False

def test_insert():
    """Testa inserção na tabela"""
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
            'reason': 'Teste de funcionalidade'
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
    print("🚀 Iniciando criação da tabela driver_excluded_zones...")
    print(f"🔗 URL: {SUPABASE_URL}")
    
    # Verifica se a tabela já existe
    if check_table_exists():
        print("✅ Tabela já existe!")
    else:
        print("📋 Tabela não existe, criando...")
        
        if create_excluded_zones_table():
            print("✅ Tabela criada com sucesso!")
            
            # Verifica novamente
            if check_table_exists():
                print("✅ Verificação final: Tabela existe!")
            else:
                print("❌ Erro: Tabela não foi criada corretamente")
                return
        else:
            print("❌ Falha na criação da tabela")
            return
    
    # Testa a funcionalidade
    print("\n🧪 Testando funcionalidade...")
    if test_insert():
        print("✅ Funcionalidade de adicionar exclusões está funcionando!")
    else:
        print("❌ Problema na funcionalidade de adicionar exclusões")

if __name__ == "__main__":
    main()