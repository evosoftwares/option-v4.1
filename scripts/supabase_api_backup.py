#!/usr/bin/env python3
"""
Script de backup usando a API REST do Supabase
Alternativa quando pg_dump não está disponível
"""
import os
import json
import requests
import datetime
from pathlib import Path

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk"

# Headers para autenticação
HEADERS = {
    'apikey': SUPABASE_SERVICE_ROLE_KEY,
    'Authorization': f'Bearer {SUPABASE_SERVICE_ROLE_KEY}',
    'Content-Type': 'application/json'
}

# Tabelas para backup (baseado na estrutura do projeto)
TABLES = [
    'users',
    'drivers',
    'passengers',
    'trips',
    'driver_offers',
    'trip_requests',
    'locations',
    'payments',
    'reviews',
    'notifications',
    'wallet_transactions',
    'driver_documents',
    'vehicle_documents'
]

def create_backup_dir():
    """Cria diretório de backups se não existir"""
    backup_dir = Path("backups")
    backup_dir.mkdir(exist_ok=True)
    return backup_dir

def backup_table(table_name):
    """Faz backup de uma tabela específica"""
    url = f"{SUPABASE_URL}/rest/v1/{table_name}"
    
    # Obter todos os registros (sem limite)
    params = {
        'select': '*',
        'limit': 10000  # Limite alto para evitar timeout
    }
    
    try:
        response = requests.get(url, headers=HEADERS, params=params)
        response.raise_for_status()
        
        data = response.json()
        print(f"✅ {table_name}: {len(data)} registros")
        
        return {
            'table_name': table_name,
            'count': len(data),
            'data': data,
            'backup_date': datetime.datetime.now().isoformat()
        }
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro ao fazer backup de {table_name}: {str(e)}")
        return {
            'table_name': table_name,
            'count': 0,
            'data': [],
            'error': str(e),
            'backup_date': datetime.datetime.now().isoformat()
        }

def backup_database_schema():
    """Faz backup do schema usando a API de informações do banco"""
    url = f"{SUPABASE_URL}/rest/v1/"
    
    # Para cada tabela, obter informações de schema
    schema_info = {}
    
    for table in TABLES:
        try:
            # Obter informações da tabela
            url_info = f"{SUPABASE_URL}/rest/v1/{table}"
            response = requests.options(url_info, headers=HEADERS)
            
            if response.status_code == 200:
                schema_info[table] = response.json()
            else:
                schema_info[table] = {'error': 'Não foi possível obter schema'}
                
        except Exception as e:
            schema_info[table] = {'error': str(e)}
    
    return schema_info

def main():
    """Função principal"""
    print("🚀 Backup via API REST do Supabase")
    print("=" * 40)
    
    # Criar diretório de backups
    backup_dir = create_backup_dir()
    
    # Gerar nome do arquivo
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    backup_file = backup_dir / f"supabase_api_backup_{timestamp}.json"
    
    print(f"📁 Arquivo de saída: {backup_file}")
    
    # Backup do schema
    print("\n📋 Fazendo backup do schema...")
    schema = backup_database_schema()
    
    # Backup dos dados
    print("\n💾 Fazendo backup dos dados...")
    all_data = {
        'backup_type': 'supabase_api_backup',
        'backup_date': datetime.datetime.now().isoformat(),
        'supabase_url': SUPABASE_URL,
        'schema': schema,
        'tables': {}
    }
    
    total_records = 0
    
    for table in TABLES:
        table_data = backup_table(table)
        all_data['tables'][table] = table_data
        total_records += table_data['count']
    
    # Salvar arquivo JSON
    try:
        with open(backup_file, 'w', encoding='utf-8') as f:
            json.dump(all_data, f, indent=2, ensure_ascii=False)
        
        print(f"\n✅ Backup concluído!")
        print(f"📊 Total de registros: {total_records}")
        
        # Verificar tamanho do arquivo
        file_size = backup_file.stat().st_size
        print(f"📁 Tamanho do arquivo: {file_size / 1024:.2f} KB")
        
        # Criar também um arquivo CSV para cada tabela
        print("\n📊 Criando arquivos CSV...")
        create_csv_backups(all_data, backup_dir, timestamp)
        
    except Exception as e:
        print(f"❌ Erro ao salvar arquivo: {str(e)}")
        return False
    
    return True

def create_csv_backups(data, backup_dir, timestamp):
    """Cria arquivos CSV para cada tabela"""
    import csv
    
    csv_dir = backup_dir / f"csv_backup_{timestamp}"
    csv_dir.mkdir(exist_ok=True)
    
    for table_name, table_info in data['tables'].items():
        if table_info['data']:
            csv_file = csv_dir / f"{table_name}.csv"
            
            try:
                with open(csv_file, 'w', newline='', encoding='utf-8') as f:
                    if table_info['data']:
                        writer = csv.DictWriter(f, fieldnames=table_info['data'][0].keys())
                        writer.writeheader()
                        writer.writerows(table_info['data'])
                
                print(f"   ✅ {table_name}.csv: {len(table_info['data'])} registros")
                
            except Exception as e:
                print(f"   ❌ Erro ao criar {table_name}.csv: {str(e)}")

if __name__ == "__main__":
    success = main()
    if not success:
        exit(1)