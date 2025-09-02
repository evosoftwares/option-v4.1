#!/usr/bin/env python3
"""
Script para criar o bucket 'driver-documents' no Supabase via Python.
"""

import os
import sys
from supabase import create_client, Client
from dotenv import load_dotenv

# Carregar variáveis de ambiente
load_dotenv()

def create_driver_documents_bucket():
    """Cria o bucket driver-documents no Supabase."""
    
    # Configuração do Supabase
    url = os.getenv('SUPABASE_URL')
    key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')  # Usar service role para criar buckets
    
    if not url or not key:
        print("❌ ERRO: Variáveis SUPABASE_URL ou SUPABASE_SERVICE_ROLE_KEY não encontradas")
        return False
    
    try:
        # Criar cliente Supabase
        supabase: Client = create_client(url, key)
        print("✅ Cliente Supabase criado com sucesso")
        
        # Verificar se o bucket já existe
        print("\n🔍 Verificando buckets existentes...")
        buckets = supabase.storage.list_buckets()
        bucket_names = [bucket.name for bucket in buckets]
        print(f"📋 Buckets existentes: {bucket_names}")
        
        if 'driver-documents' in bucket_names:
            print("✅ Bucket 'driver-documents' já existe!")
            return True
        
        # Criar o bucket driver-documents
        print("\n🔨 Criando bucket 'driver-documents'...")
        
        try:
            # Criar bucket privado
            result = supabase.storage.create_bucket('driver-documents')
            
            print(f"✅ Bucket 'driver-documents' criado com sucesso!")
            print(f"📋 Resultado: {result}")
            
            # Verificar se foi criado
            buckets = supabase.storage.list_buckets()
            bucket_names = [bucket.name for bucket in buckets]
            
            if 'driver-documents' in bucket_names:
                print("✅ Verificação: Bucket 'driver-documents' confirmado!")
                return True
            else:
                print("❌ Erro: Bucket não foi criado corretamente")
                return False
                
        except Exception as e:
            print(f"❌ Erro ao criar bucket: {e}")
            return False
            
    except Exception as e:
        print(f"❌ Erro na conexão com Supabase: {e}")
        return False

if __name__ == "__main__":
    print("🔨 Criando bucket 'driver-documents'...\n")
    success = create_driver_documents_bucket()
    
    if success:
        print("\n🎉 Bucket criado com SUCESSO!")
        sys.exit(0)
    else:
        print("\n💥 Falha ao criar bucket!")
        sys.exit(1)