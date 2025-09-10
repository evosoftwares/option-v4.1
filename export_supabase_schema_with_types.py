#!/usr/bin/env python3
"""
Exportador completo do schema Supabase com tipos de dados
Captura tabelas, colunas e seus tipos de dados específicos
"""

import json
import requests
from datetime import datetime
from supabase import create_client, Client

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def get_table_schema_with_types(table_name):
    """
    Obtém o schema de uma tabela específica com tipos de dados
    usando a API REST do PostgREST
    """
    try:
        # URL para obter informações do schema via PostgREST
        url = f"{SUPABASE_URL}/rest/v1/"
        headers = {
            "apikey": SUPABASE_KEY,
            "Authorization": f"Bearer {SUPABASE_KEY}",
            "Content-Type": "application/json"
        }
        
        # Fazer uma requisição OPTIONS para obter metadados da tabela
        response = requests.options(f"{url}{table_name}", headers=headers)
        
        if response.status_code == 200:
            # Tentar extrair informações do cabeçalho Accept-Post
            accept_post = response.headers.get('Accept-Post', '')
            if accept_post:
                # Parse do JSON schema se disponível
                try:
                    schema_info = json.loads(accept_post)
                    return schema_info
                except:
                    pass
        
        # Método alternativo: fazer uma query vazia para obter estrutura
        response = requests.get(
            f"{url}{table_name}?limit=0", 
            headers=headers
        )
        
        if response.status_code == 200:
            return {"accessible": True, "method": "empty_query"}
        else:
            return {"accessible": False, "error": f"HTTP {response.status_code}: {response.text[:100]}"}
            
    except Exception as e:
        return {"accessible": False, "error": str(e)}

def get_postgresql_schema_info():
    """
    Tenta obter informações de schema diretamente do PostgreSQL
    usando queries na information_schema
    """
    try:
        # Query para obter informações de colunas com tipos
        query = """
        SELECT 
            table_name,
            column_name,
            data_type,
            is_nullable,
            column_default,
            character_maximum_length,
            numeric_precision,
            numeric_scale
        FROM information_schema.columns 
        WHERE table_schema = 'public'
        ORDER BY table_name, ordinal_position
        """
        
        url = f"{SUPABASE_URL}/rest/v1/rpc/get_schema_info"
        headers = {
            "apikey": SUPABASE_KEY,
            "Authorization": f"Bearer {SUPABASE_KEY}",
            "Content-Type": "application/json"
        }
        
        # Tentar executar a query (pode não funcionar devido a permissões)
        response = requests.post(url, headers=headers, json={"query": query})
        
        if response.status_code == 200:
            return response.json()
        else:
            return None
            
    except Exception as e:
        print(f"⚠️  Não foi possível acessar information_schema: {e}")
        return None

def analyze_column_types_from_data(table_name, sample_data):
    """
    Analisa os tipos de dados baseado em dados de exemplo
    """
    if not sample_data:
        return {}
    
    column_types = {}
    
    for column, value in sample_data.items():
        if value is None:
            column_types[column] = "nullable"
        elif isinstance(value, bool):
            column_types[column] = "boolean"
        elif isinstance(value, int):
            column_types[column] = "integer"
        elif isinstance(value, float):
            column_types[column] = "numeric"
        elif isinstance(value, str):
            # Tentar identificar tipos específicos baseado no conteúdo
            if value.count('-') == 4 and len(value) == 36:  # UUID format
                column_types[column] = "uuid"
            elif '@' in value and '.' in value:  # Email format
                column_types[column] = "email (text)"
            elif value.endswith('+00:00') or 'T' in value:  # Timestamp format
                column_types[column] = "timestamp"
            elif value.startswith('http'):  # URL format
                column_types[column] = "url (text)"
            elif value.startswith('(') and ')' in value:  # Phone format
                column_types[column] = "phone (text)"
            else:
                column_types[column] = "text"
        else:
            column_types[column] = f"unknown ({type(value).__name__})"
    
    return column_types

def get_enhanced_table_info(supabase: Client, table_name):
    """
    Obtém informações completas de uma tabela incluindo tipos inferidos
    """
    try:
        print(f"🔍 Analisando tabela: {table_name}")
        
        # Tentar obter dados da tabela
        response = supabase.table(table_name).select("*").limit(1).execute()
        
        if response.data:
            sample_data = response.data[0] if response.data else None
            
            # Contar registros
            count_response = supabase.table(table_name).select("*", count="exact").limit(1).execute()
            record_count = count_response.count if hasattr(count_response, 'count') else len(response.data)
            
            # Obter todas as colunas fazendo uma query vazia
            empty_response = supabase.table(table_name).select("*").limit(0).execute()
            
            # Inferir tipos baseado nos dados de exemplo
            column_types = analyze_column_types_from_data(table_name, sample_data) if sample_data else {}
            
            # Obter lista de colunas
            columns = list(sample_data.keys()) if sample_data else []
            
            return {
                "accessible": True,
                "columns": columns,
                "column_count": len(columns),
                "record_count": record_count,
                "column_types": column_types,
                "example_data": sample_data,
                "error": None
            }
        else:
            # Tabela vazia - tentar obter estrutura de outra forma
            try:
                empty_response = supabase.table(table_name).select("*").limit(0).execute()
                return {
                    "accessible": True,
                    "columns": [],
                    "column_count": 0,
                    "record_count": 0,
                    "column_types": {},
                    "example_data": None,
                    "error": None
                }
            except Exception as e:
                return {
                    "accessible": False,
                    "columns": [],
                    "column_count": 0,
                    "record_count": 0,
                    "column_types": {},
                    "example_data": None,
                    "error": str(e)
                }
                
    except Exception as e:
        error_msg = str(e)
        return {
            "accessible": False,
            "columns": [],
            "column_count": 0,
            "record_count": 0,
            "column_types": {},
            "example_data": None,
            "error": error_msg
        }

def main():
    print("🚀 INICIANDO EXPORTAÇÃO COMPLETA DO SCHEMA SUPABASE")
    print("=" * 70)
    
    # Conectar ao Supabase
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    # Lista de tabelas conhecidas (expandida)
    known_tables = [
        "app_users", "drivers", "passengers", "trips", "trip_requests",
        "driver_wallets", "wallet_transactions", "payment_methods",
        "notifications", "activity_logs", "platform_settings",
        "operational_cities", "driver_offers", "driver_schedules",
        "driver_status", "driver_operational_cities", "driver_operation_zones",
        "driver_schedule_overrides", "withdrawal_requests",
        "available_drivers_view", "driver_earnings_view", "trip_summary_view",
        "user_activity_view"
    ]
    
    # Tentar obter informações do PostgreSQL schema
    print("🔍 Tentando acessar information_schema do PostgreSQL...")
    pg_schema_info = get_postgresql_schema_info()
    
    if pg_schema_info:
        print("✅ Informações de schema PostgreSQL obtidas!")
    else:
        print("⚠️  Usando método de inferência baseado em dados")
    
    # Estrutura para armazenar os dados
    schema_data = {
        "metadata": {
            "export_date": datetime.now().isoformat(),
            "supabase_url": SUPABASE_URL,
            "total_tables": len(known_tables),
            "includes_column_types": True,
            "type_inference_method": "data_analysis"
        },
        "tables": {}
    }
    
    accessible_count = 0
    inaccessible_count = 0
    
    # Processar cada tabela
    for i, table_name in enumerate(known_tables, 1):
        print(f"\n{i:2d}. 📋 {table_name.upper()}")
        print("-" * 50)
        
        table_info = get_enhanced_table_info(supabase, table_name)
        schema_data["tables"][table_name] = table_info
        
        if table_info["accessible"]:
            accessible_count += 1
            print(f"    ✅ Acessível")
            print(f"    📝 Colunas: {table_info['column_count']}")
            print(f"    📊 Registros: {table_info['record_count']}")
            
            if table_info["column_types"]:
                print(f"    🔧 Tipos identificados: {len(table_info['column_types'])}")
                # Mostrar alguns tipos como exemplo
                for col, col_type in list(table_info["column_types"].items())[:3]:
                    print(f"       • {col}: {col_type}")
                if len(table_info["column_types"]) > 3:
                    print(f"       ... e mais {len(table_info['column_types']) - 3} colunas")
        else:
            inaccessible_count += 1
            error = table_info["error"][:60] + "..." if len(table_info["error"]) > 60 else table_info["error"]
            print(f"    ❌ Inacessível: {error}")
    
    # Salvar arquivo JSON
    output_file = "supabase_schema_with_types.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(schema_data, f, indent=2, ensure_ascii=False)
    
    print(f"\n💾 Schema com tipos exportado para: {output_file}")
    
    # Resumo final
    print("\n" + "=" * 70)
    print("📈 RESUMO DA EXPORTAÇÃO COM TIPOS")
    print("=" * 70)
    print(f"✅ Tabelas acessíveis: {accessible_count}")
    print(f"❌ Tabelas inacessíveis: {inaccessible_count}")
    print(f"🎯 Total explorado: {len(known_tables)}")
    
    # Mostrar tabelas com mais tipos identificados
    tables_with_types = [(name, data) for name, data in schema_data["tables"].items() 
                        if data["accessible"] and data["column_types"]]
    tables_with_types.sort(key=lambda x: len(x[1]["column_types"]), reverse=True)
    
    print(f"\n🔧 TABELAS COM TIPOS IDENTIFICADOS:")
    for name, data in tables_with_types[:5]:
        print(f"   ✅ {name}: {len(data['column_types'])} tipos, {data['record_count']} registros")
    
    print(f"\n🚀 Exportação completa! Tipos de dados salvos em {output_file}")
    print("=" * 70)

if __name__ == "__main__":
    main()