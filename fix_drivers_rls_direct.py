#!/usr/bin/env python3
import requests
import json

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk"

headers = {
    "apikey": SUPABASE_SERVICE_ROLE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
    "Content-Type": /var/folders/4l/zpzt8gfx5d53lk9_09kgzpmm0000gn/T/TemporaryItems/NSIRD_screencaptureui_Ygs1td/Captura de Tela 2025-09-05 às 11.23.45.png"application/json"
}

def test_direct_access():
    """Testa acesso direto à tabela drivers usando service_role"""
    print("🧪 Testando acesso direto à tabela drivers...")
    
    try:
        # Tentar acessar diretamente com service_role
        url = f"{SUPABASE_URL}/rest/v1/drivers?select=id,is_online&limit=1"
        response = requests.get(url, headers=headers)
        
        print(f"📊 Status da resposta: {response.status_code}")
        
        if response.status_code == 200:
            print("✅ Acesso direto funcionou!")
            data = response.json()
            if data:
                print(f"📋 Dados obtidos: {len(data)} registros")
                return data[0]  # Retorna o primeiro driver para teste
        else:
            print(f"❌ Falha no acesso: {response.text}")
            
    except Exception as e:
        print(f"❌ Erro: {e}")
    
    return None

def test_patch_with_service_role(driver_data):
    """Testa operação PATCH usando service_role diretamente"""
    print("\n🔧 Testando PATCH com service_role...")
    
    if not driver_data:
        print("❌ Sem dados de driver para teste")
        return
    
    driver_id = driver_data['id']
    current_status = driver_data.get('is_online', False)
    
    try:
        # Fazer PATCH diretamente
        patch_url = f"{SUPABASE_URL}/rest/v1/drivers?id=eq.{driver_id}"
        patch_data = {"is_online": not current_status}
        
        print(f"📋 Driver ID: {driver_id}")
        print(f"📋 Status atual: {current_status}")
        print(f"📋 Novo status: {not current_status}")
        
        response = requests.patch(patch_url, headers=headers, json=patch_data)
        
        print(f"📊 Status da resposta PATCH: {response.status_code}")
        
        if response.status_code == 200:
            print("✅ PATCH funcionou!")
            print(f"📋 Resposta: {response.json()}")
            
            # Reverter mudança
            revert_data = {"is_online": current_status}
            revert_response = requests.patch(patch_url, headers=headers, json=revert_data)
            
            if revert_response.status_code == 200:
                print("✅ Status revertido com sucesso")
            else:
                print(f"⚠️ Falha ao reverter: {revert_response.status_code}")
                
        elif response.status_code == 406:
            print("❌ ERRO 406 - Not Acceptable confirmado!")
            print(f"📋 Detalhes: {response.text}")
        else:
            print(f"❌ PATCH falhou: {response.status_code}")
            print(f"📋 Resposta: {response.text}")
            
    except Exception as e:
        print(f"❌ Erro no PATCH: {e}")

def check_table_permissions():
    """Verifica permissões da tabela drivers"""
    print("\n🔍 Verificando permissões da tabela...")
    
    # Tentar diferentes operações para identificar o problema
    operations = [
        ("SELECT", "GET", f"{SUPABASE_URL}/rest/v1/drivers?select=id&limit=1"),
        ("INSERT", "POST", f"{SUPABASE_URL}/rest/v1/drivers"),
        ("UPDATE", "PATCH", f"{SUPABASE_URL}/rest/v1/drivers?id=eq.test"),
        ("DELETE", "DELETE", f"{SUPABASE_URL}/rest/v1/drivers?id=eq.test")
    ]
    
    for op_name, method, url in operations:
        try:
            if method == "GET":
                response = requests.get(url, headers=headers)
            elif method == "POST":
                response = requests.post(url, headers=headers, json={})
            elif method == "PATCH":
                response = requests.patch(url, headers=headers, json={})
            elif method == "DELETE":
                response = requests.delete(url, headers=headers)
            
            print(f"📋 {op_name}: {response.status_code}")
            
            if response.status_code not in [200, 201, 204, 404, 409]:
                print(f"   ❌ Erro: {response.text}")
                
        except Exception as e:
            print(f"📋 {op_name}: Erro - {e}")

if __name__ == "__main__":
    print("🚀 Diagnóstico avançado da tabela drivers")
    print(f"🔗 URL: {SUPABASE_URL}")
    print(f"🔑 Service Key: {SUPABASE_SERVICE_ROLE_KEY[:20]}...")
    
    # Verificar permissões gerais
    check_table_permissions()
    
    # Testar acesso direto
    driver_data = test_direct_access()
    
    # Testar PATCH se conseguimos dados
    if driver_data:
        test_patch_with_service_role(driver_data)
    
    print("\n✨ Diagnóstico concluído")
    print("\n💡 Se o problema persistir:")
    print("   1. Acesse o Supabase Dashboard")
    print("   2. Vá para SQL Editor")
    print("   3. Execute: ALTER TABLE drivers DISABLE ROW LEVEL SECURITY;")
    print("   4. Execute: DROP POLICY IF EXISTS \"Allow driver operations\" ON drivers;")