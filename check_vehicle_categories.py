#!/usr/bin/env python3
"""
Script para verificar categorias de veículo válidas no Supabase
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

def check_constraints():
    """Verifica constraints relacionadas a vehicle_category"""
    
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
    
    print("🔍 Verificando constraints de vehicle_category...")
    
    # Query SQL para verificar constraints da tabela drivers
    sql_query = """
    SELECT 
        tc.constraint_name,
        tc.constraint_type,
        kcu.column_name,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name,
        cc.check_clause
    FROM 
        information_schema.table_constraints AS tc 
        LEFT JOIN information_schema.key_column_usage AS kcu
          ON tc.constraint_name = kcu.constraint_name
        LEFT JOIN information_schema.constraint_column_usage AS ccu
          ON ccu.constraint_name = tc.constraint_name
        LEFT JOIN information_schema.check_constraints AS cc
          ON cc.constraint_name = tc.constraint_name
    WHERE 
        tc.table_name = 'drivers' 
        AND (kcu.column_name = 'vehicle_category' OR tc.constraint_name LIKE '%vehicle_category%')
    ORDER BY tc.constraint_name;
    """
    
    try:
        # Fazer query direta no banco
        response = requests.post(
            f"{url}/rest/v1/rpc/sql_query",
            headers=headers,
            json={"query": sql_query}
        )
        
        if response.status_code == 404:
            # Tentar método alternativo - verificar tabelas relacionadas
            print("🔄 Tentando verificar tabelas relacionadas a categorias...")
            
            # Verificar se existe tabela de categorias
            categories_response = requests.get(
                f"{url}/rest/v1/vehicle_categories",
                headers=headers
            )
            
            if categories_response.status_code == 200:
                categories = categories_response.json()
                print("✅ Tabela 'vehicle_categories' encontrada:")
                for cat in categories:
                    print(f"  - {cat}")
            else:
                print(f"❌ Tabela 'vehicle_categories' não encontrada (status: {categories_response.status_code})")
            
            # Verificar dados existentes na tabela drivers
            drivers_response = requests.get(
                f"{url}/rest/v1/drivers?select=vehicle_category&limit=20",
                headers=headers
            )
            
            if drivers_response.status_code == 200:
                drivers = drivers_response.json()
                categories_used = set()
                for driver in drivers:
                    if driver.get('vehicle_category'):
                        categories_used.add(driver['vehicle_category'])
                
                print("📋 Categorias atualmente em uso na tabela drivers:")
                for cat in sorted(categories_used):
                    print(f"  - '{cat}'")
                    
        else:
            print(f"Status da query: {response.status_code}")
            print(f"Resposta: {response.text}")
            
    except Exception as e:
        print(f"❌ Erro ao verificar constraints: {str(e)}")

    # Verificar platform_settings para categorias válidas
    print("\n🔍 Verificando platform_settings para categorias...")
    try:
        platform_response = requests.get(
            f"{url}/rest/v1/platform_settings",
            headers=headers
        )
        
        if platform_response.status_code == 200:
            settings = platform_response.json()
            print("✅ Dados de platform_settings:")
            for setting in settings:
                print(f"  - Categoria: {setting.get('category')}")
        else:
            print(f"❌ Erro ao acessar platform_settings (status: {platform_response.status_code})")
            
    except Exception as e:
        print(f"❌ Erro ao verificar platform_settings: {str(e)}")

if __name__ == "__main__":
    check_constraints()