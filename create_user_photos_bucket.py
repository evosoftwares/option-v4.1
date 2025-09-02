#!/usr/bin/env python3
"""
Script para criar o bucket 'user-photos' via API do Supabase.
Este script cria o bucket necessário para os uploads de documentos.
"""

import requests
import json

# Configurações do Supabase (do app_config.dart)
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def create_user_photos_bucket():
    """Cria o bucket user-photos no Supabase."""
    
    print("🚀 Criando bucket 'user-photos'...")
    
    # Headers para autenticação
    headers = {
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "apikey": SUPABASE_ANON_KEY,
        "Content-Type": "application/json"
    }
    
    # Dados do bucket
    bucket_data = {
        "id": "user-photos",
        "name": "user-photos",
        "public": True,
        "file_size_limit": 5242880,  # 5MB
        "allowed_mime_types": ["image/jpeg", "image/png", "image/webp", "image/jpg"]
    }
    
    try:
        # Tentar criar o bucket
        response = requests.post(
            f"{SUPABASE_URL}/storage/v1/bucket",
            headers=headers,
            json=bucket_data
        )
        
        if response.status_code in [200, 201]:
            print("✅ Bucket 'user-photos' criado com sucesso!")
            return True
        elif response.status_code == 409:
            print("ℹ️ Bucket 'user-photos' já existe!")
            return True
        else:
            print(f"❌ Erro ao criar bucket: {response.status_code}")
            print(f"Resposta: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro durante criação: {e}")
        return False

def verify_bucket_creation():
    """Verifica se o bucket foi criado corretamente."""
    
    print("\n🔍 Verificando criação do bucket...")
    
    headers = {
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "apikey": SUPABASE_ANON_KEY,
        "Content-Type": "application/json"
    }
    
    try:
        response = requests.get(
            f"{SUPABASE_URL}/storage/v1/bucket",
            headers=headers
        )
        
        if response.status_code == 200:
            buckets = response.json()
            
            for bucket in buckets:
                if bucket['id'] == 'user-photos':
                    print("\n✅ Bucket 'user-photos' encontrado!")
                    print(f"   - Público: {bucket.get('public', 'N/A')}")
                    print(f"   - Limite: {bucket.get('file_size_limit', 'N/A')} bytes")
                    print(f"   - MIME types: {bucket.get('allowed_mime_types', 'N/A')}")
                    return True
            
            print("❌ Bucket 'user-photos' ainda não foi encontrado")
            return False
        else:
            print(f"❌ Erro ao verificar buckets: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Erro durante verificação: {e}")
        return False

def test_upload():
    """Testa um upload simples no bucket."""
    
    print("\n📤 Testando upload no bucket...")
    
    from io import BytesIO
    from PIL import Image
    
    # Criar uma imagem de teste
    test_image = Image.new('RGB', (100, 100), color='green')
    img_buffer = BytesIO()
    test_image.save(img_buffer, format='JPEG')
    img_data = img_buffer.getvalue()
    
    test_filename = "test_upload.jpg"
    test_path = f"test/{test_filename}"
    
    # Headers para upload
    upload_headers = {
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "apikey": SUPABASE_ANON_KEY,
    }
    
    try:
        # Fazer upload
        upload_response = requests.post(
            f"{SUPABASE_URL}/storage/v1/object/user-photos/{test_path}",
            headers=upload_headers,
            files={'file': (test_filename, img_data, 'image/jpeg')}
        )
        
        if upload_response.status_code in [200, 201]:
            print("   ✅ Upload de teste bem-sucedido!")
            
            # Verificar URL pública
            public_url = f"{SUPABASE_URL}/storage/v1/object/public/user-photos/{test_path}"
            print(f"   📎 URL: {public_url}")
            
            # Limpar arquivo de teste
            delete_response = requests.delete(
                f"{SUPABASE_URL}/storage/v1/object/user-photos/{test_path}",
                headers=upload_headers
            )
            
            if delete_response.status_code == 200:
                print("   🗑️ Arquivo de teste removido")
            
            return True
        else:
            print(f"   ❌ Erro no upload: {upload_response.status_code}")
            print(f"   Resposta: {upload_response.text}")
            return False
            
    except Exception as e:
        print(f"   ❌ Erro durante upload: {e}")
        return False

def main():
    print("🔧 Configurando bucket 'user-photos' para documentos\n")
    
    # Passo 1: Criar bucket
    if not create_user_photos_bucket():
        print("\n❌ FALHA: Não foi possível criar o bucket")
        print("💡 Tente executar o script SQL manualmente no Supabase Dashboard")
        return
    
    # Passo 2: Verificar criação
    if not verify_bucket_creation():
        print("\n❌ FALHA: Bucket não foi encontrado após criação")
        return
    
    # Passo 3: Testar upload
    if not test_upload():
        print("\n❌ FALHA: Upload de teste falhou")
        return
    
    print("\n🎉 SUCESSO! Bucket 'user-photos' configurado e funcionando!")
    print("💡 Agora você pode testar o upload de documentos na aplicação Flutter")
    print("💡 Os documentos de CNH serão salvos no bucket 'user-photos'")

if __name__ == "__main__":
    main()