#!/usr/bin/env python3
import requests
import json

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk"

headers = {
    "apikey": SUPABASE_SERVICE_ROLE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
    "Content-Type": "application/json"
}

def check_drivers_table():
    print("🔍 Verificando tabela drivers...")
    
    # 1. Verificar se a tabela existe e suas colunas
    try:
        url = f"{SUPABASE_URL}/rest/v1/drivers?limit=1"
        response = requests.get(url, headers=headers)
        
        if response.status_code == 200:
            print("✅ Tabela drivers acessível")
            data = response.json()
            if data:
                print(f"📊 Exemplo de registro: {list(data[0].keys())}")
        else:
            print(f"❌ Erro ao acessar tabela drivers: {response.status_code}")
            print(f"   Resposta: {response.text}")
            
    except Exception as e:
        print(f"❌ Erro na verificação: {e}")

def check_rls_status():
    print("\n🔒 Verificando status do RLS...")
    
    # Verificar RLS usando uma query direta
    try:
        # Tentar uma operação simples de leitura
        url = f"{SUPABASE_URL}/rest/v1/drivers?select=id&limit=1"
        response = requests.get(url, headers=headers)
        
        if response.status_code == 200:
            print("✅ RLS permite leitura com service_role")
        elif response.status_code == 401:
            print("❌ RLS bloqueando acesso - precisa ser desabilitado")
        else:
            print(f"⚠️  Status inesperado: {response.status_code}")
            print(f"   Resposta: {response.text}")
            
    except Exception as e:
        print(f"❌ Erro na verificação RLS: {e}")

def test_patch_operation():
    print("\n🧪 Testando operação PATCH...")
    
    try:
        # Primeiro, pegar um driver existente
        url = f"{SUPABASE_URL}/rest/v1/drivers?select=id,is_online&limit=1"
        response = requests.get(url, headers=headers)
        
        if response.status_code != 200:
            print(f"❌ Não foi possível obter drivers: {response.status_code}")
            return
            
        drivers = response.json()
        if not drivers:
            print("❌ Nenhum driver encontrado para teste")
            return
            
        driver = drivers[0]
        driver_id = driver['id']
        current_status = driver.get('is_online', False)
        
        print(f"📋 Testando com driver ID: {driver_id}")
        print(f"📋 Status atual: {current_status}")
        
        # Tentar fazer um PATCH simples
        patch_url = f"{SUPABASE_URL}/rest/v1/drivers?id=eq.{driver_id}"
        patch_data = {"is_online": not current_status}  # Inverter o status
        
        response = requests.patch(patch_url, headers=headers, json=patch_data)
        
        if response.status_code == 200:
            print("✅ PATCH funcionou corretamente")
            # Reverter a mudança
            revert_data = {"is_online": current_status}
            requests.patch(patch_url, headers=headers, json=revert_data)
            print("✅ Status revertido")
        elif response.status_code == 406:
            print("❌ ERRO 406 - Not Acceptable detectado!")
            print(f"   Resposta: {response.text}")
        else:
            print(f"❌ PATCH falhou com status: {response.status_code}")
            print(f"   Resposta: {response.text}")
            
    except Exception as e:
        print(f"❌ Erro no teste PATCH: {e}")

if __name__ == "__main__":
    print("🚀 Iniciando diagnóstico da tabela drivers...")
    print(f"🔗 URL: {SUPABASE_URL}")
    print(f"🔑 Service Key: {SUPABASE_SERVICE_ROLE_KEY[:20]}...")
    
    check_drivers_table()
    check_rls_status()
    test_patch_operation()
    
    print("\n✨ Diagnóstico concluído")