#!/usr/bin/env python3
"""
Script para verificar se o problema é o path vs bucket
"""

import requests
import json

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk"

def get_headers():
    return {
        "apikey": SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SERVICE_ROLE_KEY}",
        "Content-Type": "application/json"
    }

def list_buckets():
    """Lista todos os buckets existentes"""
    print("📋 Listando todos os buckets existentes...")
    
    try:
        response = requests.get(
            f"{SUPABASE_URL}/storage/v1/bucket",
            headers=get_headers()
        )
        
        if response.status_code == 200:
            buckets = response.json()
            print(f"✅ Encontrados {len(buckets)} buckets:")
            for bucket in buckets:
                print(f"   - ID: {bucket['id']}")
                print(f"     Nome: {bucket['name']}")
                print(f"     Público: {bucket['public']}")
                print(f"     Limite: {bucket.get('file_size_limit', 'Sem limite')} bytes")
                print(f"     Tipos: {bucket.get('allowed_mime_types', 'Todos')}")
                print()
            return buckets
        else:
            print(f"❌ Erro ao listar buckets: {response.status_code} - {response.text}")
            return []
            
    except Exception as e:
        print(f"❌ Erro: {str(e)}")
        return []

def check_policies():
    """Verifica se existem políticas RLS"""
    print("🔒 Verificando políticas RLS...")
    
    # Como não conseguimos executar SQL diretamente, vamos tentar via curl
    import subprocess
    
    curl_cmd = [
        'curl', '-s', '-X', 'POST',
        f'{SUPABASE_URL}/rest/v1/pg_policies',
        '-H', f'apikey: {SERVICE_ROLE_KEY}',
        '-H', f'Authorization: Bearer {SERVICE_ROLE_KEY}',
        '-H', 'Content-Type: application/json',
        '-d', '{"select": "policyname,tablename,schemaname"}'
    ]
    
    try:
        result = subprocess.run(curl_cmd, capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ Resposta: {result.stdout}")
        else:
            print(f"❌ Erro curl: {result.stderr}")
    except Exception as e:
        print(f"❌ Erro ao executar curl: {str(e)}")

def main():
    print("🔍 Investigando problema de bucket/policies...")
    print("=" * 60)
    
    # 1. Listar buckets
    buckets = list_buckets()
    
    # 2. Verificar se user-photos existe
    user_photos_exists = any(b['id'] == 'user-photos' for b in buckets)
    print(f"📋 Bucket 'user-photos' existe: {'✅ Sim' if user_photos_exists else '❌ Não'}")
    
    # 3. Verificar se driver-documents existe
    driver_docs_exists = any(b['id'] == 'driver-documents' for b in buckets)
    print(f"📋 Bucket 'driver-documents' existe: {'✅ Sim' if driver_docs_exists else '❌ Não'}")
    
    # 4. Problema identificado
    print("\n🎯 ANÁLISE DO PROBLEMA:")
    print("=" * 40)
    print("📋 Erro mostra:")
    print("   - bucket: user-photos")  
    print("   - path: driver_documents/ae47f8c3-d864-40d9-9ba9-7d6b6e469200/cnh_1756848762041.jpg")
    print()
    print("💡 POSSÍVEIS CAUSAS:")
    print("1. Políticas RLS não aplicadas no bucket 'user-photos'")
    print("2. Usuário não está autenticado corretamente")
    print("3. O path 'driver_documents/' pode causar confusão")
    print()
    print("🔧 PRÓXIMOS PASSOS:")
    print("1. Aplicar políticas RLS via Dashboard")
    print("2. Verificar autenticação do usuário")
    print("3. Testar upload com path simples")
    
    # 5. Tentar verificar políticas
    check_policies()

if __name__ == "__main__":
    main()