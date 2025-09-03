#!/usr/bin/env python3
"""
Script para corrigir políticas RLS do bucket user-photos
Resolve o erro: "new row violates row-level security policy"
"""

import os
import requests
import json

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk"

def execute_sql(sql_query):
    """Executa uma query SQL no Supabase"""
    url = f"{SUPABASE_URL}/rest/v1/rpc/exec_sql"
    
    headers = {
        "apikey": SUPABASE_SERVICE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "sql": sql_query
    }
    
    try:
        response = requests.post(url, headers=headers, json=payload)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"Erro ao executar SQL: {e}")
        return False

def fix_storage_rls():
    """Aplica as correções de RLS para o bucket user-photos"""
    print("🔧 Iniciando correção de RLS para bucket user-photos...")
    
    # SQL para corrigir as políticas RLS
    sql_commands = [
        # Remover políticas existentes
        "DROP POLICY IF EXISTS \"user_photos_insert\" ON storage.objects;",
        "DROP POLICY IF EXISTS \"user_photos_select\" ON storage.objects;",
        "DROP POLICY IF EXISTS \"user_photos_update\" ON storage.objects;",
        "DROP POLICY IF EXISTS \"user_photos_delete\" ON storage.objects;",
        "DROP POLICY IF EXISTS \"user_photos_public_select\" ON storage.objects;",
        
        # Habilitar RLS
        "ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;",
        
        # Criar política INSERT mais permissiva
        """
        CREATE POLICY "user_photos_insert" ON storage.objects
        FOR INSERT 
        TO authenticated
        WITH CHECK (
          bucket_id = 'user-photos'
        );
        """,
        
        # Criar política SELECT
        """
        CREATE POLICY "user_photos_select" ON storage.objects
        FOR SELECT 
        TO authenticated
        USING (
          bucket_id = 'user-photos'
        );
        """,
        
        # Criar política UPDATE
        """
        CREATE POLICY "user_photos_update" ON storage.objects
        FOR UPDATE 
        TO authenticated
        USING (
          bucket_id = 'user-photos'
        )
        WITH CHECK (
          bucket_id = 'user-photos'
        );
        """,
        
        # Criar política DELETE
        """
        CREATE POLICY "user_photos_delete" ON storage.objects
        FOR DELETE 
        TO authenticated
        USING (
          bucket_id = 'user-photos'
        );
        """,
        
        # Política SELECT pública
        """
        CREATE POLICY "user_photos_public_select" ON storage.objects
        FOR SELECT 
        TO public
        USING (
          bucket_id = 'user-photos'
        );
        """,
        
        # Conceder permissões
        "GRANT ALL ON storage.objects TO authenticated;",
        "GRANT SELECT ON storage.objects TO anon;",
        
        # Garantir que o bucket existe
        """
        INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
        VALUES (
          'user-photos',
          'user-photos', 
          true,
          52428800,
          ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
        )
        ON CONFLICT (id) 
        DO UPDATE SET
          public = EXCLUDED.public,
          file_size_limit = EXCLUDED.file_size_limit,
          allowed_mime_types = EXCLUDED.allowed_mime_types;
        """
    ]
    
    # Executar cada comando
    for i, sql in enumerate(sql_commands, 1):
        print(f"\n📝 Executando comando {i}/{len(sql_commands)}...")
        print(f"SQL: {sql[:100]}...")
        
        success = execute_sql(sql)
        if success:
            print("✅ Comando executado com sucesso")
        else:
            print("❌ Erro ao executar comando")
            return False
    
    print("\n🎉 Correção de RLS concluída com sucesso!")
    return True

def verify_policies():
    """Verifica se as políticas foram criadas corretamente"""
    print("\n🔍 Verificando políticas criadas...")
    
    verify_sql = """
    SELECT policyname, cmd, roles 
    FROM pg_policies 
    WHERE tablename = 'objects' 
    AND schemaname = 'storage' 
    AND policyname LIKE 'user_photos%';
    """
    
    return execute_sql(verify_sql)

if __name__ == "__main__":
    print("🚀 Iniciando correção de RLS para uploads...")
    
    if fix_storage_rls():
        verify_policies()
        print("\n✅ Correção aplicada! Teste agora o upload na aplicação.")
    else:
        print("\n❌ Falha na correção. Verifique os logs acima.")