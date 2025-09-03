#!/usr/bin/env python3
"""
Script simples para desabilitar RLS via API REST
"""

import requests
import json

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk"

def test_upload():
    """Testa upload direto via API"""
    print("🧪 Testando upload direto...")
    
    # Criar um arquivo de teste pequeno
    test_data = b"test image data"
    
    url = f"{SUPABASE_URL}/storage/v1/object/user-photos/test/test_upload.jpg"
    headers = {
        "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
        "Content-Type": "image/jpeg",
        "apikey": SUPABASE_SERVICE_KEY
    }
    
    try:
        response = requests.post(url, headers=headers, data=test_data)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code in [200, 201]:
            print("✅ Upload funcionou!")
            return True
        else:
            print(f"❌ Upload falhou: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro no teste: {e}")
        return False

def check_bucket_policies():
    """Verifica políticas do bucket"""
    print("🔍 Verificando políticas do bucket...")
    
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
            print(f"Bucket info: {json.dumps(bucket_info, indent=2)}")
            
            # Verificar se é público
            if bucket_info.get('public', False):
                print("✅ Bucket é público")
            else:
                print("⚠️ Bucket não é público")
                
            return True
        else:
            print(f"❌ Erro ao verificar bucket: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro na verificação: {e}")
        return False

def update_bucket_to_public():
    """Atualiza bucket para público"""
    print("🔧 Atualizando bucket para público...")
    
    url = f"{SUPABASE_URL}/storage/v1/bucket/user-photos"
    headers = {
        "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
        "Content-Type": "application/json",
        "apikey": SUPABASE_SERVICE_KEY
    }
    
    data = {
        "public": True,
        "file_size_limit": 52428800,  # 50MB
        "allowed_mime_types": ["image/jpeg", "image/jpg", "image/png", "image/webp"]
    }
    
    try:
        response = requests.put(url, headers=headers, json=data)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            print("✅ Bucket atualizado para público!")
            return True
        else:
            print(f"❌ Erro ao atualizar bucket: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro na atualização: {e}")
        return False

def main():
    print("🚀 Diagnosticando problema de upload...")
    
    # Verificar bucket
    print("\n1. Verificando configuração do bucket...")
    check_bucket_policies()
    
    # Atualizar para público se necessário
    print("\n2. Garantindo que bucket é público...")
    update_bucket_to_public()
    
    # Testar upload
    print("\n3. Testando upload direto...")
    if test_upload():
        print("\n🎉 Upload funcionou! O problema foi resolvido.")
    else:
        print("\n❌ Upload ainda falha. Pode ser problema de RLS.")
        print("💡 Tente executar no SQL Editor do Supabase:")
        print("   ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;")
    
    print("\n🧪 Teste agora o upload na aplicação.")

if __name__ == "__main__":
    main()