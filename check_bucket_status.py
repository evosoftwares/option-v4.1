#!/usr/bin/env python3
"""
Script para verificar o status do bucket 'user-photos' no Supabase Storage
Verifica se o bucket existe, suas configurações e políticas RLS atuais
"""

import os
import requests
import json
from dotenv import load_dotenv

# Carregar variáveis de ambiente
load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_ANON_KEY = os.getenv('SUPABASE_ANON_KEY')
SUPABASE_SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

if not all([SUPABASE_URL, SUPABASE_ANON_KEY]):
    print("❌ Erro: Variáveis de ambiente SUPABASE_URL e SUPABASE_ANON_KEY são obrigatórias")
    exit(1)

def check_bucket_exists():
    """Verifica se o bucket 'user-photos' existe"""
    print("🔍 Verificando se o bucket 'user-photos' existe...")
    
    headers = {
        'Authorization': f'Bearer {SUPABASE_SERVICE_ROLE_KEY or SUPABASE_ANON_KEY}',
        'apikey': SUPABASE_ANON_KEY,
        'Content-Type': 'application/json'
    }
    
    try:
        response = requests.get(
            f'{SUPABASE_URL}/storage/v1/bucket',
            headers=headers
        )
        
        if response.status_code == 200:
            buckets = response.json()
            user_photos_bucket = None
            
            print(f"📦 Buckets encontrados: {len(buckets)}")
            for bucket in buckets:
                print(f"  - {bucket.get('name', 'N/A')} (público: {bucket.get('public', False)})")
                if bucket.get('name') == 'user-photos':
                    user_photos_bucket = bucket
            
            if user_photos_bucket:
                print("✅ Bucket 'user-photos' encontrado!")
                print(f"   Público: {user_photos_bucket.get('public', False)}")
                print(f"   ID: {user_photos_bucket.get('id', 'N/A')}")
                print(f"   Criado em: {user_photos_bucket.get('created_at', 'N/A')}")
                return True
            else:
                print("❌ Bucket 'user-photos' NÃO encontrado!")
                return False
        else:
            print(f"❌ Erro ao listar buckets: {response.status_code}")
            print(f"   Resposta: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro na requisição: {str(e)}")
        return False

def check_rls_policies():
    """Verifica as políticas RLS atuais na tabela storage.objects"""
    print("\n🔒 Verificando políticas RLS na tabela storage.objects...")
    
    headers = {
        'Authorization': f'Bearer {SUPABASE_SERVICE_ROLE_KEY or SUPABASE_ANON_KEY}',
        'apikey': SUPABASE_ANON_KEY,
        'Content-Type': 'application/json'
    }
    
    query = """
    SELECT 
        policyname, 
        cmd,
        roles,
        qual,
        with_check
    FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects'
    ORDER BY policyname;
    """
    
    try:
        response = requests.post(
            f'{SUPABASE_URL}/rest/v1/rpc/exec_sql',
            headers=headers,
            json={'query': query}
        )
        
        if response.status_code == 200:
            policies = response.json()
            if policies:
                print(f"📋 Políticas RLS encontradas: {len(policies)}")
                for policy in policies:
                    print(f"  - {policy.get('policyname', 'N/A')} ({policy.get('cmd', 'N/A')})")
            else:
                print("⚠️  Nenhuma política RLS encontrada na tabela storage.objects")
        else:
            print(f"❌ Erro ao verificar políticas RLS: {response.status_code}")
            print(f"   Resposta: {response.text}")
            
    except Exception as e:
        print(f"❌ Erro ao verificar políticas RLS: {str(e)}")

def main():
    print("🚀 Verificando status do Supabase Storage...")
    print(f"📍 URL: {SUPABASE_URL}")
    print("="*50)
    
    # Verificar se bucket existe
    bucket_exists = check_bucket_exists()
    
    # Verificar políticas RLS
    check_rls_policies()
    
    print("\n" + "="*50)
    if bucket_exists:
        print("✅ Bucket 'user-photos' está configurado")
        print("📝 Próximo passo: Executar script fix_storage_rls.sql no Supabase Dashboard")
    else:
        print("❌ Bucket 'user-photos' precisa ser criado primeiro")
        print("📝 Próximo passo: Criar bucket 'user-photos' no Supabase Dashboard")

if __name__ == '__main__':
    main()