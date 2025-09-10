#!/usr/bin/env python3
"""
Script avançado para explorar e exportar o schema do Supabase
Conecta ao banco, lista todas as tabelas e suas colunas, e salva em JSON
"""

from supabase import create_client, Client
import requests
import json
from datetime import datetime

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def get_table_info(supabase, table_name):
    """Obtém informações detalhadas de uma tabela"""
    try:
        # Obter schema via API
        url = f"{SUPABASE_URL}/rest/v1/{table_name}?limit=1"
        headers = {
            'apikey': SUPABASE_KEY,
            'Authorization': f'Bearer {SUPABASE_KEY}',
            'Content-Type': 'application/json'
        }
        
        response = requests.get(url, headers=headers)
        
        if response.status_code == 200:
            data = response.json()
            columns = list(data[0].keys()) if data else []
            
            # Contar registros
            try:
                count_result = supabase.table(table_name).select('*', count='exact').limit(0).execute()
                record_count = count_result.count if hasattr(count_result, 'count') else 0
            except:
                record_count = "Erro ao contar"
            
            # Obter exemplo de dados
            example_data = data[0] if data else None
            
            return {
                'accessible': True,
                'columns': columns,
                'column_count': len(columns),
                'record_count': record_count,
                'example_data': example_data,
                'error': None
            }
        else:
            return {
                'accessible': False,
                'columns': [],
                'column_count': 0,
                'record_count': 0,
                'example_data': None,
                'error': f"HTTP {response.status_code}: {response.text[:100]}"
            }
            
    except Exception as e:
        return {
            'accessible': False,
            'columns': [],
            'column_count': 0,
            'record_count': 0,
            'example_data': None,
            'error': str(e)
        }

def get_all_tables():
    """Lista todas as tabelas conhecidas do projeto"""
    return [
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

def main():
    print("🔍 EXPLORADOR AVANÇADO DE SCHEMA DO SUPABASE")
    print("=" * 70)
    print(f"📡 Conectando a: {SUPABASE_URL}")
    print("=" * 70)
    
    # Inicializar cliente Supabase
    try:
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        print("✅ Conexão com Supabase estabelecida!\n")
    except Exception as e:
        print(f"❌ Erro ao conectar: {e}")
        return
    
    # Obter lista de tabelas
    tables = get_all_tables()
    schema_data = {
        'metadata': {
            'export_date': datetime.now().isoformat(),
            'supabase_url': SUPABASE_URL,
            'total_tables': len(tables)
        },
        'tables': {}
    }
    
    print(f"📊 EXPLORANDO {len(tables)} TABELAS")
    print("=" * 70)
    
    accessible_count = 0
    inaccessible_count = 0
    
    # Explorar cada tabela
    for i, table_name in enumerate(tables, 1):
        print(f"\n{i:2d}. 📋 {table_name.upper()}")
        print("-" * 50)
        
        table_info = get_table_info(supabase, table_name)
        schema_data['tables'][table_name] = table_info
        
        if table_info['accessible']:
            accessible_count += 1
            print(f"    ✅ Acessível")
            print(f"    📝 Colunas: {table_info['column_count']}")
            print(f"    📊 Registros: {table_info['record_count']}")
            
            # Mostrar algumas colunas principais
            if table_info['columns']:
                main_columns = table_info['columns'][:5]
                print(f"    🔑 Principais: {', '.join(main_columns)}")
                if len(table_info['columns']) > 5:
                    print(f"    ➕ E mais {len(table_info['columns']) - 5} colunas...")
        else:
            inaccessible_count += 1
            print(f"    ❌ Inacessível: {table_info['error'][:50]}...")
    
    # Salvar schema em arquivo JSON
    output_file = 'supabase_schema_export.json'
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(schema_data, f, indent=2, ensure_ascii=False, default=str)
        print(f"\n💾 Schema exportado para: {output_file}")
    except Exception as e:
        print(f"\n❌ Erro ao salvar arquivo: {e}")
    
    # Resumo final
    print("\n" + "=" * 70)
    print("📈 RESUMO DA EXPLORAÇÃO")
    print("=" * 70)
    print(f"✅ Tabelas acessíveis: {accessible_count}")
    print(f"❌ Tabelas inacessíveis: {inaccessible_count}")
    print(f"🎯 Total explorado: {len(tables)}")
    
    # Mostrar tabelas principais acessíveis
    main_tables = ['app_users', 'drivers', 'passengers', 'trips', 'trip_requests']
    print(f"\n🔥 TABELAS PRINCIPAIS:")
    for table in main_tables:
        if table in schema_data['tables'] and schema_data['tables'][table]['accessible']:
            info = schema_data['tables'][table]
            print(f"   ✅ {table}: {info['column_count']} colunas, {info['record_count']} registros")
        else:
            print(f"   ❌ {table}: Inacessível")
    
    print(f"\n🚀 Exploração concluída! Dados salvos em {output_file}")
    print("=" * 70)

if __name__ == "__main__":
    main()