#!/usr/bin/env python3
"""
Script simples para configurar bucket user-photos sem RLS
"""

import requests
import json

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk"

def create_bucket():
    """Cria o bucket user-photos"""
    print("🪣 Criando bucket user-photos...")
    
    url = f"{SUPABASE_URL}/storage/v1/bucket"
    headers = {
        "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
        "Content-Type": "application/json",
        "apikey": SUPABASE_SERVICE_KEY
    }
    
    data = {
        "id": "user-photos",
        "name": "user-photos",
        "public": True,
        "file_size_limit": 5242880,  # 5MB
        "allowed_mime_types": ["image/jpeg", "image/jpg", "image/png", "image/webp"]
    }
    
    try:
        response = requests.post(url, headers=headers, json=data)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code in [200, 201]:
            print("✅ Bucket criado com sucesso!")
            return True
        elif response.status_code == 409:
            print("ℹ️ Bucket já existe")
            return True
        else:
            print(f"❌ Erro ao criar bucket: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro na requisição: {e}")
        return False

def check_bucket():
    """Verifica se o bucket existe"""
    print("🔍 Verificando bucket user-photos...")
    
    url = f"{SUPABASE_URL}/storage/v1/bucket/user-photos"
    headers = {
        "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
        "apikey": SUPABASE_SERVICE_KEY
    }
    
    try:
        response = requests.get(url, headers=headers)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            bucket_info = response.json()
            print(f"✅ Bucket encontrado: {json.dumps(bucket_info, indent=2)}")
            return True
        else:
            print(f"❌ Bucket não encontrado: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro na verificação: {e}")
        return False

def main():
    print("🚀 Configurando bucket user-photos...")
    
    # Verificar se bucket existe
    if not check_bucket():
        # Criar bucket se não existir
        if create_bucket():
            # Verificar novamente
            check_bucket()
    
    print("\n✅ Configuração concluída!")
    print("🧪 Teste agora o upload na aplicação.")

if __name__ == "__main__":
    main()