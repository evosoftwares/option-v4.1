#!/usr/bin/env python3
"""
Script para testar se o bucket 'user-photos' está funcionando para uploads de documentos.
Verifica se o bucket existe e se é possível fazer upload de arquivos.
"""

import os
import requests
from io import BytesIO
from PIL import Image

# Configurações do Supabase (do app_config.dart)
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def test_user_photos_bucket():
    """Testa se o bucket user-photos está funcionando para documentos."""
    
    print("🧪 Testando bucket 'user-photos' para documentos...\n")
    
    # Headers para autenticação
    headers = {
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "apikey": SUPABASE_ANON_KEY,
        "Content-Type": "application/json"
    }
    
    try:
        # Teste 1: Listar buckets
        print("📋 Teste 1: Verificando buckets disponíveis...")
        response = requests.get(
            f"{SUPABASE_URL}/storage/v1/bucket",
            headers=headers
        )
        
        if response.status_code == 200:
            buckets = response.json()
            bucket_names = [bucket['id'] for bucket in buckets]
            print(f"   Buckets encontrados: {bucket_names}")
            
            if 'user-photos' in bucket_names:
                user_photos_bucket = next(b for b in buckets if b['id'] == 'user-photos')
                print(f"   ✅ Bucket user-photos encontrado!")
                print(f"      - Público: {user_photos_bucket.get('public', 'N/A')}")
                print(f"      - Limite: {user_photos_bucket.get('file_size_limit', 'N/A')} bytes")
                print(f"      - MIME types: {user_photos_bucket.get('allowed_mime_types', 'N/A')}")
            else:
                print("   ❌ Bucket 'user-photos' NÃO encontrado!")
                return False
        else:
            print(f"   ❌ Erro ao listar buckets: {response.status_code}")
            print(f"   Resposta: {response.text}")
            return False
            
        # Teste 2: Upload de teste para documentos
        print("\n📤 Teste 2: Testando upload de documento...")
        
        # Criar uma imagem de teste
        test_image = Image.new('RGB', (100, 100), color='red')
        img_buffer = BytesIO()
        test_image.save(img_buffer, format='JPEG')
        img_data = img_buffer.getvalue()
        
        test_filename = "test_document_upload.jpg"
        test_path = f"documents/{test_filename}"
        
        # Headers para upload
        upload_headers = {
            "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
            "apikey": SUPABASE_ANON_KEY,
        }
        
        # Fazer upload
        upload_response = requests.post(
            f"{SUPABASE_URL}/storage/v1/object/user-photos/{test_path}",
            headers=upload_headers,
            files={'file': (test_filename, img_data, 'image/jpeg')}
        )
        
        if upload_response.status_code in [200, 201]:
            print("   ✅ Upload de documento bem-sucedido!")
            
            # Teste 3: Verificar URL pública
            public_url = f"{SUPABASE_URL}/storage/v1/object/public/user-photos/{test_path}"
            print(f"   📎 URL pública: {public_url}")
            
            # Testar acesso à URL
            url_response = requests.get(public_url)
            if url_response.status_code == 200:
                print("   ✅ URL pública acessível!")
            else:
                print(f"   ⚠️ URL pública não acessível: {url_response.status_code}")
            
            # Limpar arquivo de teste
            delete_response = requests.delete(
                f"{SUPABASE_URL}/storage/v1/object/user-photos/{test_path}",
                headers=upload_headers
            )
            
            if delete_response.status_code == 200:
                print("   🗑️ Arquivo de teste removido")
            
        else:
            print(f"   ❌ Erro no upload: {upload_response.status_code}")
            print(f"   Resposta: {upload_response.text}")
            return False
            
        print("\n🎉 SUCESSO! Bucket 'user-photos' está funcionando para documentos!")
        return True
        
    except Exception as e:
        print(f"❌ Erro durante o teste: {e}")
        return False

def main():
    print("🔧 Testando configuração do bucket user-photos para documentos\n")
    
    success = test_user_photos_bucket()
    
    if success:
        print("\n✅ RESULTADO: Bucket user-photos está pronto para receber documentos!")
        print("💡 Agora você pode testar o upload de CNH na aplicação Flutter")
    else:
        print("\n❌ RESULTADO: Há problemas com o bucket user-photos")
        print("💡 Verifique se o bucket existe e está configurado corretamente")
        print("💡 Execute o script setup_user_photos_bucket_no_rls.sql se necessário")

if __name__ == "__main__":
    main()