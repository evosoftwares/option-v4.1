#!/usr/bin/env python3

import requests
import json

# Configurações diretas do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk"

print("🔧 Iniciando correção da constraint driver_documents_document_type_check")
print(f"🔗 Conectando ao Supabase: {SUPABASE_URL}")

# Headers para as requisições
headers = {
    "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
    "apikey": SUPABASE_SERVICE_ROLE_KEY,
    "Content-Type": "application/json",
    "Prefer": "return=minimal"
}

def execute_sql_via_rpc(sql_command, description):
    """Executa comando SQL via RPC do Supabase"""
    print(f"\n📝 {description}")
    
    try:
        # Usando a função rpc para executar SQL
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/exec_sql",
            headers=headers,
            json={"sql": sql_command},
            timeout=30
        )
        
        if response.status_code in [200, 201, 204]:
            print(f"   ✅ Sucesso: {description}")
            return True
        else:
            print(f"   ❌ Erro {response.status_code}: {response.text}")
            return False
            
    except Exception as e:
        print(f"   ❌ Erro de execução: {e}")
        return False

def execute_sql_direct(sql_command, description):
    """Executa comando SQL diretamente via PostgREST"""
    print(f"\n📝 {description}")
    
    try:
        # Tentativa de executar via endpoint direto
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/query",
            headers=headers,
            json={"query": sql_command},
            timeout=30
        )
        
        if response.status_code in [200, 201, 204]:
            print(f"   ✅ Sucesso: {description}")
            return True
        else:
            print(f"   ❌ Erro {response.status_code}: {response.text}")
            return False
            
    except Exception as e:
        print(f"   ❌ Erro de execução: {e}")
        return False

# Comandos SQL para correção
sql_commands = [
    {
        "sql": "ALTER TABLE driver_documents DROP CONSTRAINT IF EXISTS driver_documents_document_type_check;",
        "description": "Removendo constraint problemática"
    },
    {
        "sql": "UPDATE driver_documents SET document_type = 'CNH_FRONT' WHERE document_type IS NULL OR document_type NOT IN ('CNH_FRONT', 'CNH_BACK', 'CRLV', 'VEHICLE_FRONT', 'VEHICLE_BACK', 'VEHICLE_LEFT', 'VEHICLE_RIGHT', 'VEHICLE_INTERIOR');",
        "description": "Corrigindo dados inválidos"
    },
    {
        "sql": "ALTER TABLE driver_documents ADD CONSTRAINT driver_documents_document_type_simple CHECK (document_type IN ('CNH_FRONT', 'CNH_BACK', 'CRLV', 'VEHICLE_FRONT', 'VEHICLE_BACK', 'VEHICLE_LEFT', 'VEHICLE_RIGHT', 'VEHICLE_INTERIOR'));",
        "description": "Criando nova constraint simplificada"
    }
]

print("\n🚀 Executando comandos de correção...")

success_count = 0
for i, cmd in enumerate(sql_commands, 1):
    print(f"\n--- Comando {i}/{len(sql_commands)} ---")
    
    # Tenta primeiro via RPC
    if execute_sql_via_rpc(cmd["sql"], cmd["description"]):
        success_count += 1
    # Se falhar, tenta via método direto
    elif execute_sql_direct(cmd["sql"], cmd["description"]):
        success_count += 1
    else:
        print(f"   ⚠️  Falha em ambos os métodos para: {cmd['description']}")

print(f"\n\n📊 Resultado final:")
print(f"   ✅ Comandos executados com sucesso: {success_count}/{len(sql_commands)}")

if success_count == len(sql_commands):
    print("\n🎉 Correção concluída com sucesso!")
    print("\n📋 Próximos passos:")
    print("   1. Teste o upload de documentos no aplicativo")
    print("   2. Verifique se não há mais erros de constraint")
    print("   3. Os tipos de documento permitidos são:")
    print("      - CNH_FRONT, CNH_BACK, CRLV")
    print("      - VEHICLE_FRONT, VEHICLE_BACK, VEHICLE_LEFT, VEHICLE_RIGHT, VEHICLE_INTERIOR")
else:
    print("\n⚠️  Correção parcial ou com falhas")
    print("\n💡 Soluções alternativas:")
    print("   1. Execute o script fix_constraint_dashboard.sql no Supabase Dashboard")
    print("   2. Verifique se há policies RLS interferindo")
    print("   3. Confirme as permissões da service_role_key")

print("\n" + "="*60)