#!/usr/bin/env python3
"""
Script para corrigir o problema de URLs de documentos vazias
Investigar se é problema de consulta ou problema real de dados
"""

from supabase import create_client, Client

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def main():
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    print("🔍 INVESTIGANDO PROBLEMA DAS URLs DE DOCUMENTOS")
    print("=" * 70)
    
    # 1. Verificar todos os campos da tabela driver_documents
    print("\n📄 CONSULTA DETALHADA DOS DOCUMENTOS:")
    print("-" * 50)
    
    try:
        all_docs = supabase.table('driver_documents')\
            .select('id, driver_id, document_type, file_url, status, created_at')\
            .order('created_at', desc=True)\
            .execute()
        
        if all_docs.data:
            print(f"📊 TOTAL DE DOCUMENTOS: {len(all_docs.data)}")
            print()
            
            # Verificar cada documento individualmente
            for i, doc in enumerate(all_docs.data):
                print(f"📄 DOCUMENTO #{i+1}:")
                print(f"   ID: {doc.get('id', 'N/A')}")
                print(f"   Driver ID: {doc.get('driver_id', 'N/A')}")
                print(f"   Tipo: {doc.get('document_type', 'N/A')}")
                print(f"   Status: {doc.get('status', 'N/A')}")
                print(f"   Criado: {doc.get('created_at', 'N/A')}")
                
                # Verificar field específico da URL
                file_url = doc.get('file_url', '')
                print(f"   file_url length: {len(file_url) if file_url else 0}")
                print(f"   file_url is None: {file_url is None}")
                print(f"   file_url is empty string: {file_url == ''}")
                
                if file_url:
                    print(f"   ✅ URL VÁLIDA: {file_url}")
                else:
                    print(f"   ❌ URL VAZIA/NULA")
                    
                print()
        else:
            print("❌ Nenhum documento encontrado")
            
    except Exception as e:
        print(f"❌ Erro: {e}")
    
    # 2. Verificar se o problema está no campo correto
    print("\n🔍 VERIFICAÇÃO COMPLETA DA ESTRUTURA:")
    print("-" * 50)
    
    try:
        # Buscar um documento para ver todos os campos
        sample_doc = supabase.table('driver_documents')\
            .select('*')\
            .limit(1)\
            .execute()
        
        if sample_doc.data:
            doc = sample_doc.data[0]
            print("📋 TODOS OS CAMPOS DISPONÍVEIS:")
            for key, value in doc.items():
                print(f"   {key}: {value}")
        else:
            print("❌ Nenhum documento para análise")
            
    except Exception as e:
        print(f"❌ Erro na verificação da estrutura: {e}")
    
    # 3. Verificar se existe inconsistência entre driver_id e user_id
    print("\n🔗 VERIFICAÇÃO DE CONSISTÊNCIA DRIVER_ID <-> USER_ID:")
    print("-" * 50)
    
    try:
        # Buscar todos os drivers recentes
        recent_drivers = supabase.table('drivers')\
            .select('id, user_id')\
            .order('created_at', desc=True)\
            .limit(10)\
            .execute()
        
        if recent_drivers.data:
            print("📊 MAPEAMENTO DRIVER_ID <-> USER_ID:")
            driver_mapping = {}
            for driver in recent_drivers.data:
                driver_id = driver.get('id')
                user_id = driver.get('user_id')
                driver_mapping[user_id] = driver_id
                print(f"   User ID: {user_id} -> Driver ID: {driver_id}")
            
            print("\n🔍 VERIFICANDO SE DOCUMENTOS USAM OS IDs CORRETOS:")
            
            # Verificar documentos
            docs_check = supabase.table('driver_documents')\
                .select('driver_id, document_type')\
                .execute()
            
            if docs_check.data:
                for doc in docs_check.data:
                    driver_id_in_doc = doc.get('driver_id')
                    doc_type = doc.get('document_type')
                    
                    # Verificar se este driver_id existe na tabela drivers
                    is_valid = any(driver_id_in_doc == d['id'] for d in recent_drivers.data)
                    
                    if is_valid:
                        print(f"   ✅ {doc_type}: Driver ID {driver_id_in_doc} é válido")
                    else:
                        print(f"   ❌ {doc_type}: Driver ID {driver_id_in_doc} NÃO EXISTE na tabela drivers!")
                        
                        # Tentar encontrar o user_id correspondente
                        for user_id, correct_driver_id in driver_mapping.items():
                            if user_id == driver_id_in_doc:
                                print(f"      💡 PROBLEMA: Documento usa USER_ID em vez de DRIVER_ID!")
                                print(f"      💡 USER_ID: {user_id} deveria ser DRIVER_ID: {correct_driver_id}")
            
        else:
            print("❌ Nenhum driver encontrado")
            
    except Exception as e:
        print(f"❌ Erro na verificação de consistência: {e}")
        
    print("\n" + "=" * 70)
    print("✅ INVESTIGAÇÃO CONCLUÍDA!")
    print("\n💡 POSSÍVEIS CAUSAS IDENTIFICADAS:")
    print("   1. URLs de documentos estão realmente vazias no banco")
    print("   2. Problema na consulta (campo errado sendo retornado)")
    print("   3. Inconsistência entre user_id e driver_id nas consultas")
    print("   4. Problema no upload/salvamento das URLs")

if __name__ == "__main__":
    main()