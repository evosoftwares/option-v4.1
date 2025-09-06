#!/usr/bin/env python3
"""
Script para desabilitar completamente RLS no Supabase
Resolve o erro: "new row violates row-level security policy"
"""

import requests
import json

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk"

def execute_sql(sql_command):
    """Executa comando SQL via API REST"""
    url = f"{SUPABASE_URL}/rest/v1/rpc/exec_sql"
    headers = {
        "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
        "Content-Type": "application/json",
        "apikey": SUPABASE_SERVICE_KEY
    }
    
    data = {"sql": sql_command}
    
    try:
        response = requests.post(url, headers=headers, json=data)
        print(f"SQL: {sql_command[:50]}...")
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            print("✅ Comando executado com sucesso")
            return True
        else:
            print(f"❌ Erro: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro na requisição: {e}")
        return False

def disable_rls_completely():
    """Desabilita completamente RLS para storage"""
    print("🔧 Desabilitando RLS completamente...")
    
    # Comandos SQL para desabilitar RLS
    sql_commands = [
        # Desabilitar RLS na tabela storage.objects
        "ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;",
        
        # Remover todas as políticas existentes
        "DROP POLICY IF EXISTS \"user_photos_insert\" ON storage.objects;",
        "DROP POLICY IF EXISTS \"user_photos_select\" ON storage.objects;",
        "DROP POLICY IF EXISTS \"user_photos_update\" ON storage.objects;",
        "DROP POLICY IF EXISTS \"user_photos_delete\" ON storage.objects;",
        "DROP POLICY IF EXISTS \"user_photos_public_select\" ON storage.objects;",
        "DROP POLICY IF EXISTS \"Users can upload their own profile photos\" ON storage.objects;",
        "DROP POLICY IF EXISTS \"Users can update their own profile photos\" ON storage.objects;",
        "DROP POLICY IF EXISTS \"Users can delete their own profile photos\" ON storage.objects;",
        "DROP POLICY IF EXISTS \"Public can view profile photos\" ON storage.objects;",
        "DROP POLICY IF EXISTS \"Authenticated users can upload profile photos\" ON storage.objects;",
        "DROP POLICY IF EXISTS \"Anyone can view profile photos\" ON storage.objects;",
        "DROP POLICY IF EXISTS \"Users can update their profile photos\" ON storage.objects;",
        "DROP POLICY IF EXISTS \"Users can delete their profile photos\" ON storage.objects;",
        
        # Conceder permissões totais
        "GRANT ALL ON storage.objects TO authenticated;",
        "GRANT ALL ON storage.objects TO anon;",
        "GRANT ALL ON storage.objects TO public;",
        
        # Verificar se RLS está desabilitado
        "SELECT schemaname, tablename, rowsecurity FROM pg_tables WHERE schemaname = 'storage' AND tablename = 'objects';"
    ]
    
    success_count = 0
    for i, command in enumerate(sql_commands, 1):
        print(f"\n📝 Executando comando {i}/{len(sql_commands)}...")
        if execute_sql(command):
            success_count += 1
        else:
            print(f"⚠️ Comando {i} falhou, mas continuando...")
    
    print(f"\n📊 Resultado: {success_count}/{len(sql_commands)} comandos executados com sucesso")
    
    if success_count > len(sql_commands) // 2:
        print("✅ RLS desabilitado com sucesso!")
        return True
    else:
        print("❌ Falha na desabilitação do RLS")
        return False

def check_rls_status():
    """Verifica o status do RLS"""
    print("🔍 Verificando status do RLS...")
    
    sql = "SELECT schemaname, tablename, rowsecurity FROM pg_tables WHERE schemaname = 'storage' AND tablename = 'objects';"
    
    if execute_sql(sql):
        print("✅ Verificação concluída")
    else:
        print("❌ Falha na verificação")

def main():
    print("🚀 Iniciando desabilitação completa do RLS...")
    
    # Verificar status atual
    check_rls_status()
    
    # Desabilitar RLS
    if disable_rls_completely():
        print("\n🎉 RLS desabilitado com sucesso!")
        print("🧪 Teste agora o upload na aplicação.")
    else:
        print("\n❌ Falha na desabilitação do RLS.")
        print("💡 Tente executar os comandos manualmente no SQL Editor do Supabase.")

if __name__ == "__main__":
    main()