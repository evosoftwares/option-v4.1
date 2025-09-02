#!/usr/bin/env python3
"""
Script para criar o bucket 'driver-documents' via API do Supabase
"""

import requests
import json

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def create_driver_documents_bucket():
    """Cria o bucket driver-documents"""
    
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "Content-Type": "application/json"
    }
    
    print("🚀 Criando bucket 'driver-documents'...")
    
    # Dados do bucket
    bucket_data = {
        "id": "driver-documents",
        "name": "driver-documents",
        "public": False,  # Privado para documentos sensíveis
        "file_size_limit": 10485760,  # 10MB
        "allowed_mime_types": [
            "image/jpeg",
            "image/png", 
            "image/webp",
            "image/jpg",
            "application/pdf"
        ]
    }
    
    try:
        response = requests.post(
            f"{SUPABASE_URL}/storage/v1/bucket",
            headers=headers,
            json=bucket_data
        )
        
        if response.status_code in [200, 201]:
            print("✅ Bucket 'driver-documents' criado com sucesso!")
            print(f"   Resposta: {response.json()}")
            return True
        else:
            print(f"❌ Erro ao criar bucket: {response.status_code}")
            print(f"   Resposta: {response.text}")
            
            # Se o bucket já existe, isso é OK
            if "already exists" in response.text.lower():
                print("✅ Bucket já existe - isso é OK!")
                return True
                
            return False
            
    except Exception as e:
        print(f"❌ Erro na requisição: {e}")
        return False

def verify_bucket_creation():
    """Verifica se o bucket foi criado corretamente"""
    
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "Content-Type": "application/json"
    }
    
    print("\n🔍 Verificando se o bucket foi criado...")
    
    try:
        response = requests.get(
            f"{SUPABASE_URL}/storage/v1/bucket",
            headers=headers
        )
        
        if response.status_code == 200:
            buckets = response.json()
            driver_docs_bucket = None
            
            for bucket in buckets:
                if bucket['id'] == 'driver-documents':
                    driver_docs_bucket = bucket
                    break
            
            if driver_docs_bucket:
                print("✅ Bucket 'driver-documents' encontrado!")
                print(f"   - ID: {driver_docs_bucket['id']}")
                print(f"   - Nome: {driver_docs_bucket['name']}")
                print(f"   - Público: {driver_docs_bucket.get('public', 'N/A')}")
                print(f"   - Limite: {driver_docs_bucket.get('file_size_limit', 'N/A')} bytes")
                print(f"   - MIME types: {driver_docs_bucket.get('allowed_mime_types', 'N/A')}")
                return True
            else:
                print("❌ Bucket 'driver-documents' ainda não foi encontrado")
                return False
        else:
            print(f"❌ Erro ao verificar buckets: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Erro na verificação: {e}")
        return False

def test_upload():
    """Testa upload no bucket criado"""
    
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "Content-Type": "text/plain"
    }
    
    print("\n📤 Testando upload no bucket...")
    
    test_content = "Teste de upload após criação do bucket"
    test_filename = "test_upload.txt"
    
    try:
        response = requests.post(
            f"{SUPABASE_URL}/storage/v1/object/driver-documents/{test_filename}",
            headers=headers,
            data=test_content
        )
        
        if response.status_code in [200, 201]:
            print("✅ Upload de teste realizado com sucesso!")
            print(f"   Arquivo: {test_filename}")
            
            # Remover arquivo de teste
            delete_headers = {
                "apikey": SUPABASE_ANON_KEY,
                "Authorization": f"Bearer {SUPABASE_ANON_KEY}"
            }
            
            delete_response = requests.delete(
                f"{SUPABASE_URL}/storage/v1/object/driver-documents/{test_filename}",
                headers=delete_headers
            )
            
            if delete_response.status_code == 200:
                print("✅ Arquivo de teste removido")
            
            return True
        else:
            print(f"❌ Erro no upload: {response.status_code}")
            print(f"   Resposta: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro no teste de upload: {e}")
        return False

def main():
    """Função principal"""
    print("🚀 Criando bucket 'driver-documents' no Supabase Storage")
    print("=" * 60)
    
    # Passo 1: Criar o bucket
    if not create_driver_documents_bucket():
        print("❌ Falha ao criar bucket. Abortando.")
        return
    
    # Passo 2: Verificar se foi criado
    if not verify_bucket_creation():
        print("❌ Falha na verificação do bucket. Abortando.")
        return
    
    # Passo 3: Testar upload
    if not test_upload():
        print("❌ Falha no teste de upload.")
        return
    
    print("\n" + "=" * 60)
    print("✅ Bucket 'driver-documents' criado e testado com sucesso!")
    print("💡 Agora você pode testar o upload de CNH no aplicativo Flutter.")
    print("\n📋 Próximos passos:")
    print("   1. Teste o upload de CNH no aplicativo")
    print("   2. Verifique se o erro 'namespace CNH' foi resolvido")
    print("   3. Se ainda houver problemas, verifique as políticas RLS")

if __name__ == "__main__":
    main()