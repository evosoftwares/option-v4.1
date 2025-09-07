#!/usr/bin/env python3
"""
Script para verificar o fluxo completo de cadastro incluindo documentos
"""

from datetime import datetime, timedelta
from supabase import create_client, Client

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def main():
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    print("🔍 ANÁLISE DO FLUXO DE CADASTRO + DOCUMENTOS")
    print("=" * 70)
    
    # 1. Verificar estrutura da tabela driver_documents
    print("\n📄 ESTRUTURA DA TABELA DRIVER_DOCUMENTS:")
    print("-" * 50)
    
    try:
        docs_sample = supabase.table('driver_documents')\
            .select('*')\
            .limit(1)\
            .execute()
        
        if docs_sample.data:
            doc = docs_sample.data[0]
            print("📋 CAMPOS DISPONÍVEIS:")
            for key, value in doc.items():
                print(f"   {key}: {value}")
        else:
            # Tentar criar estrutura esperada
            print("⚠️  Nenhum documento encontrado. Verificando estrutura...")
            
    except Exception as e:
        print(f"❌ Erro ao consultar driver_documents: {e}")
    
    # 2. Verificar todos os documentos existentes
    print("\n📄 TODOS OS DOCUMENTOS NO SISTEMA:")
    print("-" * 50)
    
    try:
        all_docs = supabase.table('driver_documents')\
            .select('*')\
            .order('created_at', desc=True)\
            .execute()
        
        if all_docs.data:
            print(f"📊 TOTAL DE DOCUMENTOS: {len(all_docs.data)}")
            
            # Agrupar por driver
            drivers_docs = {}
            for doc in all_docs.data:
                driver_id = doc.get('driver_id')
                if driver_id not in drivers_docs:
                    drivers_docs[driver_id] = []
                drivers_docs[driver_id].append(doc)
            
            print(f"👥 MOTORISTAS COM DOCUMENTOS: {len(drivers_docs)}")
            print()
            
            for driver_id, docs in drivers_docs.items():
                print(f"🚗 MOTORISTA: {driver_id}")
                for doc in docs:
                    doc_type = doc.get('document_type', 'N/A')
                    status = doc.get('status', 'N/A')
                    created = doc.get('created_at', 'N/A')
                    url = doc.get('document_url', 'N/A')
                    print(f"   📄 {doc_type}: {status} (criado: {created})")
                    if url and url != 'N/A':
                        print(f"      URL: {url[:50]}..." if len(url) > 50 else f"      URL: {url}")
                print()
        else:
            print("❌ NENHUM DOCUMENTO ENCONTRADO NO SISTEMA!")
            print("   Isso indica que o upload de documentos não está funcionando.")
            
    except Exception as e:
        print(f"❌ Erro ao consultar todos os documentos: {e}")
    
    # 3. Verificar motoristas SEM documentos
    print("\n🚫 MOTORISTAS SEM DOCUMENTOS:")
    print("-" * 50)
    
    try:
        # Buscar todos os motoristas
        all_drivers = supabase.table('drivers')\
            .select('user_id, vehicle_brand, vehicle_model, created_at')\
            .execute()
        
        # Buscar todos os IDs de motoristas que têm documentos
        drivers_with_docs = supabase.table('driver_documents')\
            .select('driver_id')\
            .execute()
        
        docs_driver_ids = set()
        if drivers_with_docs.data:
            docs_driver_ids = {doc['driver_id'] for doc in drivers_with_docs.data}
        
        drivers_without_docs = []
        if all_drivers.data:
            for driver in all_drivers.data:
                if driver['user_id'] not in docs_driver_ids:
                    drivers_without_docs.append(driver)
        
        print(f"🚫 MOTORISTAS SEM DOCUMENTOS: {len(drivers_without_docs)}")
        
        if drivers_without_docs:
            for driver in drivers_without_docs:
                print(f"   🚗 {driver.get('user_id', 'N/A')}")
                print(f"      Veículo: {driver.get('vehicle_brand', 'N/A')} {driver.get('vehicle_model', 'N/A')}")
                print(f"      Cadastrado: {driver.get('created_at', 'N/A')}")
                print()
        else:
            print("✅ Todos os motoristas têm documentos!")
            
    except Exception as e:
        print(f"❌ Erro ao verificar motoristas sem documentos: {e}")
    
    # 4. Verificar tipos de documento esperados
    print("\n📋 TIPOS DE DOCUMENTO ESPERADOS:")
    print("-" * 50)
    
    expected_doc_types = ['CNH', 'CRLV', 'FOTO_PERFIL', 'FOTO_VEICULO']
    
    try:
        if all_docs.data:
            actual_doc_types = set()
            for doc in all_docs.data:
                actual_doc_types.add(doc.get('document_type'))
            
            print("📄 TIPOS ENCONTRADOS:")
            for doc_type in actual_doc_types:
                count = sum(1 for doc in all_docs.data if doc.get('document_type') == doc_type)
                print(f"   {doc_type}: {count} documentos")
            
            print("\n📄 TIPOS ESPERADOS MAS NÃO ENCONTRADOS:")
            for expected in expected_doc_types:
                if expected not in actual_doc_types:
                    print(f"   ❌ {expected}")
        else:
            print("❌ Nenhum documento para analisar tipos")
            
    except Exception as e:
        print(f"❌ Erro ao analisar tipos de documento: {e}")
    
    # 5. Verificar URLs de documentos (se estão válidas)
    print("\n🔗 VERIFICAÇÃO DE URLs DE DOCUMENTOS:")
    print("-" * 50)
    
    try:
        if all_docs.data:
            valid_urls = 0
            invalid_urls = 0
            
            for doc in all_docs.data:
                url = doc.get('document_url', '')
                if url and url.startswith('http'):
                    valid_urls += 1
                else:
                    invalid_urls += 1
                    print(f"   ❌ URL inválida: {url} (doc: {doc.get('document_type', 'N/A')})")
            
            print(f"✅ URLs válidas: {valid_urls}")
            print(f"❌ URLs inválidas: {invalid_urls}")
        else:
            print("❌ Nenhuma URL para verificar")
            
    except Exception as e:
        print(f"❌ Erro ao verificar URLs: {e}")
    
    print("\n" + "=" * 70)
    print("✅ ANÁLISE DO FLUXO DE DOCUMENTOS CONCLUÍDA!")
    print("\n💡 CONCLUSÕES:")
    print("   1. Se há 0 documentos = problema no upload/salvamento")
    print("   2. Se motoristas sem docs = fluxo de upload não obrigatório")
    print("   3. URLs inválidas = problema no storage/geração de URLs")
    print("\n🔧 PRÓXIMO PASSO:")
    print("   → Verificar código do upload de documentos no app Flutter")

if __name__ == "__main__":
    main()