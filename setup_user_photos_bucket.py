#!/usr/bin/env python3
"""
Script para configurar o bucket user-photos no Supabase via API
"""

import requests
import json

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def create_user_photos_bucket():
    """
    Cria o bucket user-photos com configurações específicas
    """
    print("🔧 Configurando bucket user-photos no Supabase")
    print()
    
    # Headers para autenticação
    headers = {
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "apikey": SUPABASE_ANON_KEY,
        "Content-Type": "application/json"
    }
    
    # Configuração do bucket
    bucket_config = {
        "id": "user-photos",
        "name": "user-photos",
        "public": True,
        "file_size_limit": 5242880,  # 5MB
        "allowed_mime_types": [
            "image/jpeg",
            "image/png", 
            "image/webp",
            "image/jpg"
        ]
    }
    
    try:
        # Primeiro, verificar se o bucket já existe
        print("📋 Verificando buckets existentes...")
        list_url = f"{SUPABASE_URL}/storage/v1/bucket"
        response = requests.get(list_url, headers=headers)
        
        if response.status_code == 200:
            buckets = response.json()
            bucket_names = [bucket.get('id', bucket.get('name', '')) for bucket in buckets]
            print(f"   Buckets encontrados: {bucket_names}")
            
            if "user-photos" in bucket_names:
                print("   ✅ Bucket 'user-photos' já existe!")
                return True
        else:
            print(f"   ⚠️  Erro ao listar buckets: {response.status_code}")
            print(f"   Resposta: {response.text}")
        
        # Criar o bucket
        print("\n🚀 Criando bucket 'user-photos'...")
        create_url = f"{SUPABASE_URL}/storage/v1/bucket"
        
        response = requests.post(
            create_url,
            headers=headers,
            json=bucket_config
        )
        
        if response.status_code in [200, 201]:
            print("   ✅ Bucket 'user-photos' criado com sucesso!")
            print(f"   Configurações: {json.dumps(bucket_config, indent=2)}")
            return True
        else:
            print(f"   ❌ Erro ao criar bucket: {response.status_code}")
            print(f"   Resposta: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro inesperado: {str(e)}")
        return False

def test_bucket_access():
    """
    Testa se o bucket está acessível
    """
    print("\n🧪 Testando acesso ao bucket...")
    
    headers = {
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "apikey": SUPABASE_ANON_KEY
    }
    
    try:
        # Listar objetos no bucket (deve retornar lista vazia se bucket existe)
        list_url = f"{SUPABASE_URL}/storage/v1/object/list/user-photos"
        response = requests.post(
            list_url,
            headers=headers,
            json={"limit": 1}
        )
        
        if response.status_code == 200:
            print("   ✅ Bucket acessível via API!")
            return True
        else:
            print(f"   ❌ Erro ao acessar bucket: {response.status_code}")
            print(f"   Resposta: {response.text}")
            return False
            
    except Exception as e:
        print(f"   ❌ Erro no teste: {str(e)}")
        return False

def main():
    print("=" * 60)
    print("CONFIGURAÇÃO DO BUCKET USER-PHOTOS")
    print("=" * 60)
    print()
    
    # Criar bucket
    bucket_created = create_user_photos_bucket()
    
    if bucket_created:
        # Testar acesso
        access_ok = test_bucket_access()
        
        if access_ok:
            print("\n🎉 SUCESSO: Bucket user-photos configurado e funcionando!")
            print("\n📝 Próximos passos:")
            print("   1. Teste o upload na aplicação Flutter")
            print("   2. Verifique se os documentos são salvos corretamente")
            print("   3. Confirme que as URLs públicas funcionam")
        else:
            print("\n⚠️  ATENÇÃO: Bucket criado mas com problemas de acesso")
            print("   Execute o script SQL setup_user_photos_bucket_no_rls.sql")
    else:
        print("\n❌ FALHA: Não foi possível configurar o bucket")
        print("\n💡 Soluções:")
        print("   1. Verifique as credenciais do Supabase")
        print("   2. Execute o script SQL manualmente no Supabase Dashboard")
        print("   3. Verifique as permissões do projeto")

if __name__ == "__main__":
    main()