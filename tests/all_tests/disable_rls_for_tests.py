#!/usr/bin/env python3
import os
import requests
import json
from dotenv import load_dotenv

# Carregar variáveis de ambiente
load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    print("❌ Erro: Variáveis de ambiente SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são necessárias")
    exit(1)

# Headers para autenticação
headers = {
    'apikey': SUPABASE_SERVICE_KEY,
    'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
    'Content-Type': 'application/json'
}

# Lista de tabelas para desabilitar RLS
tables = [
    'app_users', 'drivers', 'passengers', 'driver_documents',
    'trips', 'trip_requests', 'saved_places', 'payment_methods',
    'favorite_locations', 'emergency_contacts', 'driver_excluded_zones',
    'driver_operation_zones', 'passenger_wallets', 'passenger_wallet_transactions',
    'passenger_promo_codes', 'passenger_promo_code_usage', 'driver_offers'
]

print("🔧 Desabilitando RLS para testes...")

# SQL para desabilitar RLS
sql_commands = []
for table in tables:
    sql_commands.append(f"ALTER TABLE IF EXISTS {table} DISABLE ROW LEVEL SECURITY;")

# Adicionar comando para remover políticas
sql_commands.append("""
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT schemaname, tablename, policyname 
              FROM pg_policies 
              WHERE schemaname = 'public')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
                      r.policyname, r.schemaname, r.tablename);
    END LOOP;
END $$;
""")

# Executar comandos SQL
for i, sql in enumerate(sql_commands):
    try:
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/exec_sql",
            headers=headers,
            json={"sql": sql}
        )
        
        if response.status_code == 200:
            if i < len(tables):
                print(f"✅ RLS desabilitado para tabela: {tables[i]}")
            else:
                print("✅ Políticas RLS removidas")
        else:
            print(f"⚠️  Aviso ao processar comando {i+1}: {response.status_code} - {response.text}")
            
    except Exception as e:
        print(f"❌ Erro ao executar comando {i+1}: {str(e)}")

print("\n🎯 RLS desabilitado para testes. Execute os testes agora.")
print("⚠️  Lembre-se de reabilitar o RLS após os testes!")