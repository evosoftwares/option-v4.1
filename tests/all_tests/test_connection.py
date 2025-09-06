#!/usr/bin/env python3

import os
import requests
from dotenv import load_dotenv

# Carrega variáveis do arquivo .env
load_dotenv('.env.clean')

# Configurações do Supabase
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

print(f"🔗 Testando conectividade com: {SUPABASE_URL}")
print(f"🔑 Service Role Key: {SUPABASE_SERVICE_ROLE_KEY[:20]}...")

try:
    # Teste básico de conectividade HTTP
    response = requests.get(f"{SUPABASE_URL}/rest/v1/", 
                          headers={
                              "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
                              "apikey": SUPABASE_SERVICE_ROLE_KEY
                          },
                          timeout=10)
    
    print(f"✅ Status HTTP: {response.status_code}")
    print(f"✅ Conectividade OK")
    
    # Teste específico da tabela driver_documents
    response = requests.get(f"{SUPABASE_URL}/rest/v1/driver_documents?limit=1", 
                          headers={
                              "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
                              "apikey": SUPABASE_SERVICE_ROLE_KEY
                          },
                          timeout=10)
    
    print(f"✅ Acesso à tabela driver_documents: {response.status_code}")
    if response.status_code == 200:
        print(f"✅ Dados retornados: {len(response.json())} registros")
    else:
        print(f"❌ Erro: {response.text}")
        
except requests.exceptions.RequestException as e:
    print(f"❌ Erro de conectividade: {e}")
except Exception as e:
    print(f"❌ Erro geral: {e}")