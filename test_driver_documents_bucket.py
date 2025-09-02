#!/usr/bin/env python3
"""
Script para testar a conectividade e funcionalidade do bucket 'driver-documents' no Supabase.
"""

import os
import sys
from supabase import create_client, Client
from dotenv import load_dotenv

# Carregar variáveis de ambiente
load_dotenv()

def test_driver_documents_bucket():
    """Testa a conectividade e funcionalidade do bucket driver-documents."""
    
    # Configuração do Supabase
    url = os.getenv('SUPABASE_URL')
    key = os.getenv('SUPABASE_ANON_KEY')
    
    if not url or not key:
        print("❌ ERRO: Variáveis SUPABASE_URL ou SUPABASE_ANON_KEY não encontradas")
        return False
    
    try:
        # Criar cliente Supabase
        supabase: Client = create_client(url, key)
        print("✅ Cliente Supabase criado com sucesso")
        
        # Testar listagem de buckets
        print("\n🔍 Testando listagem de buckets...")
        buckets = supabase.storage.list_buckets()
        print(f"📦 Buckets encontrados: {len(buckets)}")
        
        bucket_names = [bucket.name for bucket in buckets]
        print(f"📋 Nomes dos buckets: {bucket_names}")
        
        # Verificar se o bucket driver-documents existe
        if 'driver-documents' in bucket_names:
            print("✅ Bucket 'driver-documents' encontrado!")
            
            # Testar acesso ao bucket
            try:
                files = supabase.storage.from_('driver-documents').list()
                print(f"📁 Arquivos no bucket: {len(files)}")
                print("✅ Acesso ao bucket 'driver-documents' funcionando")
                return True
                
            except Exception as e:
                print(f"❌ Erro ao acessar bucket 'driver-documents': {e}")
                return False
        else:
            print("❌ Bucket 'driver-documents' NÃO encontrado!")
            print("💡 Execute o script create_driver_documents_bucket.sql no Supabase")
            return False
            
    except Exception as e:
        print(f"❌ Erro na conexão com Supabase: {e}")
        return False

if __name__ == "__main__":
    print("🧪 Testando bucket 'driver-documents'...\n")
    success = test_driver_documents_bucket()
    
    if success:
        print("\n🎉 Teste concluído com SUCESSO!")
        sys.exit(0)
    else:
        print("\n💥 Teste FALHOU!")
        sys.exit(1)