#!/usr/bin/env python3
"""
Script para verificar as configurações de platform_settings
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

def check_platform_settings():
    """Verifica dados de platform_settings"""
    
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
    
    print("🔍 Verificando platform_settings...")
    
    try:
        # Verificar dados de platform_settings
        platform_response = requests.get(
            f"{url}/rest/v1/platform_settings",
            headers=headers
        )
        
        if platform_response.status_code == 200:
            settings = platform_response.json()
            print("✅ Dados de platform_settings:")
            for setting in settings:
                category = setting.get('category')
                if category:
                    print(f"  - Categoria: '{category}' (ID: {setting.get('id')})")
            print(f"\nTotal de categorias encontradas: {len(settings)}")
            
            # Comparar com categorias em uso
            print("\n🔄 Comparando com categorias em uso na tabela drivers...")
            drivers_response = requests.get(
                f"{url}/rest/v1/drivers?select=vehicle_category&limit=50",
                headers=headers
            )
            
            if drivers_response.status_code == 200:
                drivers = drivers_response.json()
                categories_used = set()
                for driver in drivers:
                    if driver.get('vehicle_category'):
                        categories_used.add(driver['vehicle_category'])
                
                print("📋 Categorias em uso na tabela drivers:")
                for cat in sorted(categories_used):
                    print(f"  - '{cat}'")
                
                # Encontrar inconsistências
                platform_categories = {s.get('category') for s in settings if s.get('category')}
                
                print(f"\n📊 ANÁLISE:")
                print(f"Platform Settings: {sorted(platform_categories)}")
                print(f"Drivers: {sorted(categories_used)}")
                
                missing_in_platform = categories_used - platform_categories
                missing_in_drivers = platform_categories - categories_used
                
                if missing_in_platform:
                    print(f"❌ Categorias em drivers mas não em platform_settings: {missing_in_platform}")
                if missing_in_drivers:
                    print(f"⚠️ Categorias em platform_settings mas não usadas: {missing_in_drivers}")
                
                if not missing_in_platform and not missing_in_drivers:
                    print("✅ Todas as categorias estão alinhadas")
                    
        else:
            print(f"❌ Erro ao acessar platform_settings (status: {platform_response.status_code})")
            print(f"Resposta: {platform_response.text}")
            
    except Exception as e:
        print(f"❌ Erro ao verificar platform_settings: {str(e)}")

if __name__ == "__main__":
    check_platform_settings()