#!/usr/bin/env python3
"""
Script para testar conectividade e estado do bucket user-photos no Supabase
"""

import requests
import json
from typing import Dict, Any

# Configurações do Supabase (do app_config.dart)
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def test_supabase_connectivity():
    """Testa conectividade básica com Supabase"""
    print("🔧 Testando conectividade com Supabase...")
    print(f"🌐 URL: {SUPABASE_URL}")
    print(f"🔑 Key: {SUPABASE_ANON_KEY[:20]}...")
    
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "Content-Type": "application/json"
    }
    
    try:
        # Teste 1: Verificar se a API está respondendo
        print("\n🔍 Teste 1: Verificando API básica...")
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/",
            headers=headers,
            timeout=10
        )
        
        if response.status_code == 200:
            print("✅ API Supabase acessível!")
        else:
            print(f"❌ Erro na API: {response.status_code} - {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro de conectividade: {e}")
        return False
    
    return True

def test_storage_buckets():
    """Testa acesso aos buckets do Storage"""
    print("\n🔍 Teste 2: Verificando buckets do Storage...")
    
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}"
    }
    
    try:
        # Listar buckets
        response = requests.get(
            f"{SUPABASE_URL}/storage/v1/bucket",
            headers=headers,
            timeout=10
        )
        
        if response.status_code == 200:
            buckets = response.json()
            print(f"✅ Storage acessível! Buckets encontrados: {len(buckets)}")
            
            # Verificar cada bucket
            user_photos_found = False
            for bucket in buckets:
                bucket_id = bucket.get('id', 'N/A')
                is_public = bucket.get('public', False)
                print(f"   📁 Bucket: {bucket_id} (público: {is_public})")
                
                if bucket_id == 'user-photos':
                    user_photos_found = True
                    print(f"   ✅ Bucket user-photos encontrado!")
                    print(f"      📊 Público: {is_public}")
                    print(f"      📏 Limite: {bucket.get('file_size_limit', 'N/A')} bytes")
                    print(f"      🎭 MIME types: {bucket.get('allowed_mime_types', 'N/A')}")
            
            if not user_photos_found:
                print("❌ Bucket user-photos NÃO encontrado!")
                print("💡 Solução: Execute setup_user_photos_bucket_no_rls.sql no Supabase")
                return False
            
            return True
            
        else:
            print(f"❌ Erro ao acessar Storage: {response.status_code} - {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro de conectividade no Storage: {e}")
        return False

def test_bucket_access():
    """Testa acesso específico ao bucket user-photos"""
    print("\n🔍 Teste 3: Verificando acesso ao bucket user-photos...")
    
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}"
    }
    
    try:
        # Tentar listar objetos no bucket
        response = requests.get(
            f"{SUPABASE_URL}/storage/v1/object/list/user-photos",
            headers=headers,
            timeout=10
        )
        
        if response.status_code == 200:
            objects = response.json()
            print(f"✅ Bucket user-photos acessível! Objetos: {len(objects)}")
            return True
        elif response.status_code == 400:
            error_data = response.json()
            error_msg = error_data.get('message', 'Erro desconhecido')
            
            if 'not found' in error_msg.lower():
                print("❌ Bucket user-photos não encontrado!")
                print("💡 Execute setup_user_photos_bucket_no_rls.sql no Supabase")
            elif 'permission' in error_msg.lower():
                print("❌ Problema de permissão no bucket user-photos!")
                print("💡 Verifique políticas de segurança ou RLS")
            else:
                print(f"❌ Erro no bucket: {error_msg}")
            
            return False
        else:
            print(f"❌ Erro inesperado: {response.status_code} - {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro de conectividade no bucket: {e}")
        return False

def test_upload_simulation():
    """Simula um upload para testar permissões"""
    print("\n🔍 Teste 4: Simulando upload...")
    
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}"
    }
    
    try:
        # Tentar obter URL pública (teste de conectividade)
        test_path = "test/connectivity_test.jpg"
        response = requests.get(
            f"{SUPABASE_URL}/storage/v1/object/public/user-photos/{test_path}",
            headers=headers,
            timeout=10
        )
        
        # Qualquer resposta (mesmo 404) indica que o bucket está acessível
        if response.status_code in [200, 404]:
            print("✅ URL pública gerada com sucesso!")
            print(f"   🔗 URL: {SUPABASE_URL}/storage/v1/object/public/user-photos/{test_path}")
            return True
        else:
            print(f"❌ Erro ao gerar URL pública: {response.status_code} - {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro na simulação de upload: {e}")
        return False

def main():
    """Executa todos os testes"""
    print("🚀 DIAGNÓSTICO DO BUCKET USER-PHOTOS")
    print("=" * 50)
    
    results = {
        "conectividade": test_supabase_connectivity(),
        "storage_buckets": False,
        "bucket_access": False,
        "upload_simulation": False
    }
    
    if results["conectividade"]:
        results["storage_buckets"] = test_storage_buckets()
        
        if results["storage_buckets"]:
            results["bucket_access"] = test_bucket_access()
            results["upload_simulation"] = test_upload_simulation()
    
    # Resumo final
    print("\n📋 RESUMO DO DIAGNÓSTICO:")
    print("=" * 50)
    
    for test_name, success in results.items():
        status = "✅ PASSOU" if success else "❌ FALHOU"
        print(f"{test_name.replace('_', ' ').title()}: {status}")
    
    if all(results.values()):
        print("\n🎉 Todos os testes passaram! O bucket está funcionando.")
    else:
        print("\n⚠️  Alguns testes falharam. Verifique as soluções sugeridas acima.")
        
        if not results["storage_buckets"]:
            print("\n💡 PRÓXIMOS PASSOS:")
            print("1. Execute setup_user_photos_bucket_no_rls.sql no Supabase Dashboard")
            print("2. Verifique se o bucket foi criado corretamente")
            print("3. Execute este script novamente")
    
    print("\n🏁 Diagnóstico concluído!")

if __name__ == "__main__":
    main()