#!/usr/bin/env python3
"""
Script de validação pós-execução do setup do bucket user-photos
Execute após rodar setup_user_photos_bucket_no_rls.sql
"""

import requests
import json
from typing import Dict, Any, List

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def validate_bucket_exists() -> bool:
    """Valida se o bucket user-photos foi criado"""
    print("🔍 Validando existência do bucket user-photos...")
    
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}"
    }
    
    try:
        response = requests.get(
            f"{SUPABASE_URL}/storage/v1/bucket",
            headers=headers,
            timeout=10
        )
        
        if response.status_code == 200:
            buckets = response.json()
            user_photos_bucket = None
            
            for bucket in buckets:
                if bucket.get('id') == 'user-photos':
                    user_photos_bucket = bucket
                    break
            
            if user_photos_bucket:
                print("✅ Bucket user-photos encontrado!")
                print(f"   📊 Público: {user_photos_bucket.get('public', False)}")
                print(f"   📏 Limite: {user_photos_bucket.get('file_size_limit', 'N/A')} bytes")
                print(f"   🎭 MIME types: {user_photos_bucket.get('allowed_mime_types', [])}")
                
                # Validar configurações específicas
                is_public = user_photos_bucket.get('public', False)
                file_limit = user_photos_bucket.get('file_size_limit', 0)
                mime_types = user_photos_bucket.get('allowed_mime_types', [])
                
                if not is_public:
                    print("⚠️  AVISO: Bucket não está público!")
                    return False
                
                if file_limit != 5242880:  # 5MB
                    print(f"⚠️  AVISO: Limite de arquivo incorreto: {file_limit} (esperado: 5242880)")
                    return False
                
                expected_mimes = ['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
                if not all(mime in mime_types for mime in expected_mimes):
                    print(f"⚠️  AVISO: MIME types incorretos: {mime_types}")
                    return False
                
                print("✅ Todas as configurações do bucket estão corretas!")
                return True
            else:
                print("❌ Bucket user-photos NÃO encontrado!")
                return False
        else:
            print(f"❌ Erro ao listar buckets: {response.status_code} - {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro de conectividade: {e}")
        return False

def validate_bucket_access() -> bool:
    """Valida se o bucket está acessível para operações"""
    print("\n🔍 Validando acesso ao bucket...")
    
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
            print(f"✅ Bucket acessível! Objetos encontrados: {len(objects)}")
            return True
        elif response.status_code == 400:
            error_data = response.json()
            error_msg = error_data.get('message', 'Erro desconhecido')
            print(f"❌ Erro de acesso: {error_msg}")
            return False
        else:
            print(f"❌ Erro inesperado: {response.status_code} - {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro de conectividade: {e}")
        return False

def validate_public_url_generation() -> bool:
    """Valida se URLs públicas podem ser geradas"""
    print("\n🔍 Validando geração de URLs públicas...")
    
    test_path = "test/validation_test.jpg"
    public_url = f"{SUPABASE_URL}/storage/v1/object/public/user-photos/{test_path}"
    
    try:
        # Tentar acessar URL pública (mesmo que arquivo não exista)
        response = requests.head(public_url, timeout=10)
        
        # Status 404 é esperado (arquivo não existe), mas indica que o bucket está público
        if response.status_code in [200, 404]:
            print("✅ URLs públicas podem ser geradas!")
            print(f"   🔗 Exemplo: {public_url}")
            return True
        else:
            print(f"❌ Erro ao gerar URL pública: {response.status_code}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro ao testar URL pública: {e}")
        return False

def simulate_upload_test() -> bool:
    """Simula um teste de upload (sem arquivo real)"""
    print("\n🔍 Simulando teste de upload...")
    
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "Content-Type": "image/jpeg"
    }
    
    # Dados de teste (1x1 pixel JPEG)
    test_jpeg_data = b'\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00H\x00H\x00\x00\xff\xdb\x00C\x00\x08\x06\x06\x07\x06\x05\x08\x07\x07\x07\t\t\x08\n\x0c\x14\r\x0c\x0b\x0b\x0c\x19\x12\x13\x0f\x14\x1d\x1a\x1f\x1e\x1d\x1a\x1c\x1c $.\'\" \x0c\x0c(7),01444\x1f\'9=82<.342\xff\xc0\x00\x11\x08\x00\x01\x00\x01\x01\x01\x11\x00\x02\x11\x01\x03\x11\x01\xff\xc4\x00\x14\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\xff\xc4\x00\x14\x10\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xda\x00\x0c\x03\x01\x00\x02\x11\x03\x11\x00\x3f\x00\xaa\xff\xd9'
    
    test_path = f"test/validation_{int(__import__('time').time())}.jpg"
    
    try:
        # Tentar fazer upload de teste
        response = requests.post(
            f"{SUPABASE_URL}/storage/v1/object/user-photos/{test_path}",
            headers=headers,
            data=test_jpeg_data,
            timeout=10
        )
        
        if response.status_code in [200, 201]:
            print("✅ Upload de teste bem-sucedido!")
            print(f"   📁 Arquivo: {test_path}")
            
            # Tentar remover o arquivo de teste
            delete_response = requests.delete(
                f"{SUPABASE_URL}/storage/v1/object/user-photos/{test_path}",
                headers=headers,
                timeout=10
            )
            
            if delete_response.status_code == 200:
                print("✅ Arquivo de teste removido com sucesso!")
            
            return True
        else:
            print(f"❌ Erro no upload de teste: {response.status_code} - {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro no teste de upload: {e}")
        return False

def main():
    """Executa todas as validações"""
    print("🧪 VALIDAÇÃO DO SETUP DO BUCKET USER-PHOTOS")
    print("=" * 55)
    
    validations = {
        "Bucket existe": validate_bucket_exists(),
        "Bucket acessível": False,
        "URLs públicas": False,
        "Upload funcional": False
    }
    
    if validations["Bucket existe"]:
        validations["Bucket acessível"] = validate_bucket_access()
        validations["URLs públicas"] = validate_public_url_generation()
        validations["Upload funcional"] = simulate_upload_test()
    
    # Resumo final
    print("\n📋 RESUMO DA VALIDAÇÃO:")
    print("=" * 55)
    
    all_passed = True
    for test_name, success in validations.items():
        status = "✅ PASSOU" if success else "❌ FALHOU"
        print(f"{test_name}: {status}")
        if not success:
            all_passed = False
    
    print("\n" + "=" * 55)
    
    if all_passed:
        print("🎉 SUCESSO! Bucket user-photos configurado corretamente!")
        print("\n✅ Próximos passos:")
        print("   1. Teste o upload na aplicação Flutter")
        print("   2. Monitore logs de erro")
        print("   3. Verifique se as fotos aparecem no Storage")
    else:
        print("⚠️  FALHA! Algumas validações falharam.")
        print("\n💡 Possíveis soluções:")
        
        if not validations["Bucket existe"]:
            print("   1. Execute setup_user_photos_bucket_no_rls.sql novamente")
            print("   2. Verifique permissões no Supabase Dashboard")
        
        if not validations["Bucket acessível"]:
            print("   1. Verifique se RLS está desabilitado")
            print("   2. Confirme que não há políticas conflitantes")
        
        if not validations["Upload funcional"]:
            print("   1. Verifique permissões de INSERT na tabela storage.objects")
            print("   2. Confirme configurações de MIME types")
    
    print("\n🏁 Validação concluída!")
    return all_passed

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)