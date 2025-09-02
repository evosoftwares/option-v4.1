#!/usr/bin/env python3
"""
Script para diagnosticar o erro "Operação não suportada no namespace CNH"
no Supabase Storage
"""

import requests
import json
from datetime import datetime

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def test_supabase_storage():
    """Testa o Supabase Storage para identificar problemas"""
    
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "Content-Type": "application/json"
    }
    
    print("🔍 Testando Supabase Storage...")
    print(f"📍 URL: {SUPABASE_URL}")
    print(f"🔑 Key: {SUPABASE_ANON_KEY[:20]}...")
    print()
    
    # Teste 1: Listar buckets
    print("📋 Teste 1: Listando buckets...")
    try:
        response = requests.get(
            f"{SUPABASE_URL}/storage/v1/bucket",
            headers=headers
        )
        
        if response.status_code == 200:
            buckets = response.json()
            print(f"✅ {len(buckets)} buckets encontrados:")
            
            driver_docs_found = False
            for bucket in buckets:
                print(f"   - {bucket['id']} (público: {bucket.get('public', 'N/A')})")
                if bucket['id'] == 'driver-documents':
                    driver_docs_found = True
                    print(f"     ✅ Bucket driver-documents encontrado!")
                    print(f"     - Limite: {bucket.get('file_size_limit', 'N/A')} bytes")
                    print(f"     - MIME types: {bucket.get('allowed_mime_types', 'N/A')}")
            
            if not driver_docs_found:
                print("❌ Bucket 'driver-documents' NÃO encontrado!")
                return False
                
        else:
            print(f"❌ Erro ao listar buckets: {response.status_code}")
            print(f"   Resposta: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro na requisição: {e}")
        return False
    
    print()
    
    # Teste 2: Testar upload no bucket driver-documents
    print("📤 Teste 2: Testando upload no bucket driver-documents...")
    try:
        test_content = f"Teste CNH - {datetime.now().isoformat()}"
        test_filename = f"test_cnh_{int(datetime.now().timestamp())}.txt"
        
        upload_headers = {
            "apikey": SUPABASE_ANON_KEY,
            "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
            "Content-Type": "text/plain"
        }
        
        response = requests.post(
            f"{SUPABASE_URL}/storage/v1/object/driver-documents/{test_filename}",
            headers=upload_headers,
            data=test_content
        )
        
        if response.status_code in [200, 201]:
            print("✅ Upload de teste realizado com sucesso!")
            print(f"   Arquivo: {test_filename}")
            print(f"   Resposta: {response.json()}")
            
            # Tentar remover o arquivo de teste
            delete_response = requests.delete(
                f"{SUPABASE_URL}/storage/v1/object/driver-documents/{test_filename}",
                headers=headers
            )
            
            if delete_response.status_code == 200:
                print("✅ Arquivo de teste removido com sucesso")
            else:
                print(f"⚠️ Não foi possível remover arquivo de teste: {delete_response.status_code}")
                
        else:
            print(f"❌ Erro no upload: {response.status_code}")
            print(f"   Resposta: {response.text}")
            
            # Verificar se é o erro específico do namespace
            if "namespace" in response.text.lower() and "cnh" in response.text.lower():
                print("🎯 ERRO ENCONTRADO: Este é o erro do namespace CNH!")
                print(f"   Mensagem completa: {response.text}")
                return False
                
    except Exception as e:
        print(f"❌ Erro na requisição de upload: {e}")
        return False
    
    print()
    
    # Teste 3: Verificar políticas RLS
    print("🔒 Teste 3: Verificando políticas RLS...")
    try:
        rls_query = """
        SELECT 
            schemaname, 
            tablename, 
            policyname, 
            cmd, 
            qual, 
            with_check
        FROM pg_policies 
        WHERE schemaname = 'storage' AND tablename = 'objects'
        """
        
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/exec_sql",
            headers=headers,
            json={"sql": rls_query}
        )
        
        if response.status_code == 200:
            policies = response.json()
            if policies:
                print(f"📋 {len(policies)} políticas RLS encontradas:")
                for policy in policies:
                    print(f"   - {policy['policyname']}: {policy['cmd']}")
            else:
                print("✅ Nenhuma política RLS ativa para storage.objects")
        else:
            print(f"⚠️ Não foi possível verificar políticas RLS: {response.status_code}")
            
    except Exception as e:
        print(f"⚠️ Erro ao verificar RLS: {e}")
    
    print()
    print("✅ Diagnóstico concluído!")
    return True

def main():
    """Função principal"""
    print("🚀 Iniciando diagnóstico do erro 'Operação não suportada no namespace CNH'")
    print("=" * 70)
    
    success = test_supabase_storage()
    
    print("=" * 70)
    if success:
        print("✅ Testes concluídos - Supabase Storage parece estar funcionando")
        print("💡 O erro pode estar relacionado a:")
        print("   1. Configuração específica do Flutter")
        print("   2. Versão do supabase_flutter")
        print("   3. Implementação específica no código")
    else:
        print("❌ Problemas encontrados no Supabase Storage")
        print("💡 Verifique:")
        print("   1. Se o bucket 'driver-documents' existe")
        print("   2. Se as permissões estão corretas")
        print("   3. Se o RLS está configurado adequadamente")

if __name__ == "__main__":
    main()