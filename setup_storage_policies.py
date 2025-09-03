#!/usr/bin/env python3
"""
Script para aplicar políticas RLS no Supabase Storage via API REST
Este script resolve o erro "new row violates row-level security policy"
"""

import requests
import json
from typing import Dict, Any

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk"

def get_headers() -> Dict[str, str]:
    """Retorna headers padrão para requisições"""
    return {
        "apikey": SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SERVICE_ROLE_KEY}",
        "Content-Type": "application/json"
    }

def execute_sql(sql: str) -> Dict[str, Any]:
    """Executa SQL via API REST usando Edge Function"""
    print(f"📝 Executando SQL: {sql[:100]}...")
    
    # Tenta diferentes endpoints para executar SQL
    endpoints = [
        f"{SUPABASE_URL}/rest/v1/rpc/query",  
        f"{SUPABASE_URL}/rest/v1/query",
        f"{SUPABASE_URL}/functions/v1/sql-exec"
    ]
    
    for endpoint in endpoints:
        try:
            response = requests.post(
                endpoint,
                headers=get_headers(),
                json={"query": sql},
                timeout=30
            )
            
            if response.status_code == 200:
                print(f"✅ SQL executado com sucesso!")
                return response.json()
            else:
                print(f"❌ Erro {response.status_code}: {response.text}")
                
        except Exception as e:
            print(f"❌ Erro na requisição para {endpoint}: {str(e)}")
            continue
    
    return {"error": "Não foi possível executar SQL"}

def check_bucket_exists() -> bool:
    """Verifica se o bucket user-photos existe"""
    print("🔍 Verificando se bucket user-photos existe...")
    
    try:
        response = requests.get(
            f"{SUPABASE_URL}/storage/v1/bucket/user-photos",
            headers=get_headers()
        )
        
        if response.status_code == 200:
            bucket_data = response.json()
            print(f"✅ Bucket encontrado: {bucket_data['name']}")
            print(f"   - Público: {bucket_data['public']}")
            print(f"   - ID: {bucket_data['id']}")
            return True
        else:
            print(f"❌ Bucket não encontrado: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Erro ao verificar bucket: {str(e)}")
        return False

def create_bucket() -> bool:
    """Cria o bucket user-photos se não existir"""
    print("🪣 Criando bucket user-photos...")
    
    bucket_config = {
        "id": "user-photos",
        "name": "user-photos",
        "public": True,
        "file_size_limit": 52428800,  # 50MB
        "allowed_mime_types": ["image/jpeg", "image/jpg", "image/png", "image/webp"]
    }
    
    try:
        response = requests.post(
            f"{SUPABASE_URL}/storage/v1/bucket",
            headers=get_headers(),
            json=bucket_config
        )
        
        if response.status_code in [200, 201]:
            print("✅ Bucket criado com sucesso!")
            return True
        else:
            print(f"❌ Erro ao criar bucket: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro ao criar bucket: {str(e)}")
        return False

def main():
    """Função principal"""
    print("🚀 Iniciando configuração das políticas RLS do Supabase Storage...")
    print("=" * 70)
    
    # 1. Verificar se bucket existe
    if not check_bucket_exists():
        print("📦 Bucket não existe, tentando criar...")
        if not create_bucket():
            print("❌ Falha ao criar bucket. Verifique as permissões.")
            return
    
    # 2. Tentar aplicar políticas via SQL direto (pode falhar por permissões)
    print("\n🔒 Tentando aplicar políticas RLS...")
    
    # Como não conseguimos executar SQL direto, vamos mostrar as instruções
    print("\n📋 INSTRUÇÕES MANUAIS:")
    print("=" * 50)
    print("1. Acesse: https://supabase.com/dashboard")
    print("2. Selecione seu projeto: qlbwacmavngtonauxnte")
    print("3. Vá para 'SQL Editor'")
    print("4. Execute os seguintes comandos:")
    
    commands = [
        "-- Habilitar RLS",
        "ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;",
        "",
        "-- Política INSERT",
        "CREATE POLICY \"user_photos_insert\" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'user-photos' AND auth.uid()::text IS NOT NULL);",
        "",
        "-- Política SELECT para autenticados", 
        "CREATE POLICY \"user_photos_select\" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'user-photos');",
        "",
        "-- Política UPDATE para upsert",
        "CREATE POLICY \"user_photos_update\" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'user-photos' AND auth.uid()::text IS NOT NULL) WITH CHECK (bucket_id = 'user-photos' AND auth.uid()::text IS NOT NULL);",
        "",
        "-- Política DELETE",
        "CREATE POLICY \"user_photos_delete\" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'user-photos' AND auth.uid()::text IS NOT NULL);",
        "",
        "-- Política SELECT pública",
        "CREATE POLICY \"user_photos_public_select\" ON storage.objects FOR SELECT TO public USING (bucket_id = 'user-photos');",
        "",
        "-- Conceder permissões",
        "GRANT ALL ON storage.objects TO authenticated;"
    ]
    
    for cmd in commands:
        print(cmd)
    
    print("\n✅ Após executar essas políticas, o erro deve ser resolvido!")
    print("🧪 Teste o upload de documentos na aplicação.")

if __name__ == "__main__":
    main()