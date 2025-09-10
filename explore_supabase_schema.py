#!/usr/bin/env python3
"""
Script para explorar o schema do Supabase
Conecta ao banco e lista todas as tabelas e suas colunas
"""

from supabase import create_client, Client
import requests
import json

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def get_table_schema_via_api(table_name):
    """Obtém o schema de uma tabela específica via API REST"""
    try:
        url = f"{SUPABASE_URL}/rest/v1/{table_name}?limit=1"
        headers = {
            'apikey': SUPABASE_KEY,
            'Authorization': f'Bearer {SUPABASE_KEY}',
            'Content-Type': 'application/json'
        }
        
        response = requests.get(url, headers=headers)
        
        if response.status_code == 200:
            data = response.json()
            if data:
                return list(data[0].keys())
            else:
                return ["Tabela vazia"]
        else:
            return [f"Erro {response.status_code}: {response.text[:100]}"]
            
    except Exception as e:
        return [f"Erro: {str(e)}"]

def get_all_tables():
    """Lista todas as tabelas disponíveis"""
    # Lista de tabelas conhecidas do projeto
    known_tables = [
        'app_users',
        'drivers', 
        'passengers',
        'trips',
        'trip_requests',
        'driver_wallets',
        'wallet_transactions',
        'payment_methods',
        'notifications',
        'activity_logs',
        'platform_settings',
        'operational_cities',
        'driver_offers',
        'driver_schedules',
        'driver_status',
        'asaas_webhook_events',
        'location_sharing',
        'location_updates',
        'driver_operational_cities',
        'driver_operation_zones',
        'driver_schedule_overrides',
        'withdrawal_requests',
        'available_drivers_view',
        'driver_earnings_view',
        'trip_summary_view',
        'user_activity_view'
    ]
    
    return known_tables

def main():
    print("🔍 EXPLORADOR DE SCHEMA DO SUPABASE")
    print("=" * 60)
    print(f"📡 Conectando a: {SUPABASE_URL}")
    print("=" * 60)
    
    # Inicializar cliente Supabase
    try:
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        print("✅ Conexão com Supabase estabelecida!\n")
    except Exception as e:
        print(f"❌ Erro ao conectar: {e}")
        return
    
    # Obter lista de tabelas
    tables = get_all_tables()
    
    print(f"📊 TABELAS ENCONTRADAS: {len(tables)}")
    print("=" * 60)
    
    # Explorar cada tabela
    for i, table_name in enumerate(tables, 1):
        print(f"\n{i:2d}. 📋 TABELA: {table_name.upper()}")
        print("-" * 50)
        
        # Obter colunas da tabela
        columns = get_table_schema_via_api(table_name)
        
        if columns and not any("Erro" in str(col) for col in columns):
            print(f"    📝 Colunas ({len(columns)}):")
            for j, column in enumerate(columns, 1):
                print(f"       {j:2d}. {column}")
                
            # Tentar obter um registro de exemplo
            try:
                result = supabase.table(table_name).select('*').limit(1).execute()
                if result.data:
                    print(f"    📊 Registros: {len(result.data)} (exemplo disponível)")
                else:
                    print("    📊 Registros: 0 (tabela vazia)")
            except Exception as e:
                print(f"    ⚠️  Erro ao contar registros: {str(e)[:50]}...")
        else:
            print(f"    ❌ Não foi possível acessar: {columns[0] if columns else 'Erro desconhecido'}")
    
    # Resumo final
    print("\n" + "=" * 60)
    print("📈 RESUMO DA EXPLORAÇÃO")
    print("=" * 60)
    
    accessible_tables = []
    inaccessible_tables = []
    
    for table_name in tables:
        columns = get_table_schema_via_api(table_name)
        if columns and not any("Erro" in str(col) for col in columns):
            accessible_tables.append(table_name)
        else:
            inaccessible_tables.append(table_name)
    
    print(f"✅ Tabelas acessíveis: {len(accessible_tables)}")
    for table in accessible_tables:
        print(f"   - {table}")
    
    if inaccessible_tables:
        print(f"\n❌ Tabelas inacessíveis: {len(inaccessible_tables)}")
        for table in inaccessible_tables:
            print(f"   - {table}")
    
    print(f"\n🎯 Total de tabelas exploradas: {len(tables)}")
    print("\n" + "=" * 60)
    print("🚀 Exploração concluída!")

if __name__ == "__main__":
    main()