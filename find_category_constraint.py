#!/usr/bin/env python3
"""
Script para encontrar a constraint de foreign key de vehicle_category
"""

import os
import requests
import json
from pathlib import Path

def load_env():
    """Carrega variáveis de ambiente do arquivo .env.clean"""
    env_path = Path('.env.clean')
    if env_path.exists():
        with open(env_path) as f:
            for line in f:
                if line.strip() and not line.startswith('#'):
                    key, value = line.strip().split('=', 1)
                    os.environ[key] = value
    else:
        print("⚠️ Arquivo .env.clean não encontrado")

def find_category_constraint():
    """Tenta encontrar informações sobre a constraint de vehicle_category"""
    
    load_env()
    
    url = os.getenv('SUPABASE_URL')
    service_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
    
    if not url or not service_key:
        print("❌ Variáveis SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórias")
        return
    
    headers = {
        'apikey': service_key,
        'Authorization': f'Bearer {service_key}',
        'Content-Type': 'application/json'
    }
    
    print("🔍 Procurando por tabelas que podem conter categorias de veículos...")
    
    # Lista de possíveis nomes de tabelas que podem conter categorias
    possible_tables = [
        'vehicle_categories', 
        'categories', 
        'platform_settings',
        'pricing_categories',
        'service_categories'
    ]
    
    found_tables = []
    
    for table_name in possible_tables:
        try:
            response = requests.get(
                f"{url}/rest/v1/{table_name}?limit=1",
                headers=headers
            )
            
            if response.status_code == 200:
                found_tables.append(table_name)
                print(f"✅ Tabela encontrada: {table_name}")
                
                # Tentar ver dados da tabela
                data_response = requests.get(
                    f"{url}/rest/v1/{table_name}",
                    headers=headers
                )
                
                if data_response.status_code == 200:
                    data = data_response.json()
                    print(f"📊 Dados de {table_name}:")
                    for item in data:
                        print(f"  - {item}")
                        
            elif response.status_code == 403:
                print(f"⚠️ Tabela {table_name}: Acesso negado (403)")
            else:
                print(f"❌ Tabela {table_name}: Não encontrada (status: {response.status_code})")
                
        except Exception as e:
            print(f"❌ Erro ao verificar tabela {table_name}: {str(e)}")
    
    if not found_tables:
        print("❌ Nenhuma tabela de categorias encontrada diretamente acessível")
        
        # Tentar uma query SQL direta se possível
        print("\n🔍 Tentando query SQL para investigar constraints...")
        
        sql_query = """
        SELECT 
            tc.constraint_name,
            tc.table_name,
            kcu.column_name,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name
        FROM 
            information_schema.table_constraints AS tc 
            JOIN information_schema.key_column_usage AS kcu
              ON tc.constraint_name = kcu.constraint_name
            JOIN information_schema.constraint_column_usage AS ccu
              ON ccu.constraint_name = tc.constraint_name
        WHERE 
            tc.constraint_type = 'FOREIGN KEY' 
            AND tc.table_name = 'drivers'
            AND kcu.column_name = 'vehicle_category';
        """
        
        try:
            response = requests.post(
                f"{url}/rest/v1/rpc/sql_query",
                headers=headers,
                json={"query": sql_query}
            )
            
            if response.status_code == 200:
                result = response.json()
                print("✅ Query SQL executada com sucesso:")
                print(f"Resultado: {result}")
            else:
                print(f"❌ Query SQL falhou (status: {response.status_code})")
                print(f"Resposta: {response.text}")
                
        except Exception as e:
            print(f"❌ Erro ao executar query SQL: {str(e)}")

if __name__ == "__main__":
    find_category_constraint()