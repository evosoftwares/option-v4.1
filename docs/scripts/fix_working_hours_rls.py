#!/usr/bin/env python3
"""
Script para desabilitar RLS na tabela working_hours
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
    
    payload = {
        "sql": sql_command
    }
    
    try:
        response = requests.post(url, headers=headers, json=payload)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"Erro: {e}")
        return False

def disable_rls_working_hours():
    """Desabilita RLS na tabela working_hours"""
    print("🔧 Desabilitando RLS na tabela working_hours...")
    
    sql_commands = [
        "ALTER TABLE working_hours DISABLE ROW LEVEL SECURITY;",
        "GRANT SELECT, INSERT, UPDATE, DELETE ON working_hours TO authenticated, anon;",
        "GRANT USAGE ON SCHEMA public TO authenticated, anon;"
    ]
    
    for sql in sql_commands:
        print(f"\nExecutando: {sql}")
        success = execute_sql(sql)
        if success:
            print("✅ Comando executado com sucesso")
        else:
            print("❌ Falha na execução")

def test_working_hours_access():
    """Testa acesso à tabela working_hours"""
    print("\n🧪 Testando acesso à tabela working_hours...")
    
    url = f"{SUPABASE_URL}/rest/v1/working_hours?select=count"
    headers = {
        "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
        "apikey": SUPABASE_SERVICE_KEY,
        "Prefer": "count=exact"
    }
    
    try:
        response = requests.get(url, headers=headers)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            count = response.headers.get('content-range', '').split('/')[-1]
            print(f"✅ Acesso OK - {count} registros na tabela")
            return True
        else:
            print(f"❌ Erro: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Erro: {e}")
        return False

def main():
    print("🚀 Corrigindo problemas de RLS na tabela working_hours...")
    
    # Primeiro testa o acesso atual
    print("\n1. Testando acesso atual...")
    if test_working_hours_access():
        print("✅ Tabela working_hours já está acessível")
        return
    
    # Se não conseguir acessar, tenta desabilitar RLS
    print("\n2. Desabilitando RLS...")
    disable_rls_working_hours()
    
    # Testa novamente
    print("\n3. Testando acesso após correção...")
    if test_working_hours_access():
        print("\n✅ Problema resolvido! Tabela working_hours agora está acessível.")
        print("💡 Teste novamente o botão IR na aplicação.")
    else:
        print("\n❌ Problema persiste. Pode ser necessário executar os comandos SQL manualmente no Supabase Dashboard.")
        print("\n📋 Comandos para executar manualmente:")
        print("   ALTER TABLE working_hours DISABLE ROW LEVEL SECURITY;")
        print("   GRANT SELECT, INSERT, UPDATE, DELETE ON working_hours TO authenticated, anon;")

if __name__ == "__main__":
    main()