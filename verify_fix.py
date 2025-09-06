#!/usr/bin/env python3
"""
Script de verificação pós-correção dos horários de trabalho
"""

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

def verify_driver_effective_status_view():
    """Verifica se a view driver_effective_status está funcionando"""
    print("🔍 Verificando view driver_effective_status...")
    
    try:
        # Verificar se a view existe e tem dados
        url = f"{SUPABASE_URL}/rest/v1/driver_effective_status?select=*&limit=5"
        response = requests.get(url, headers=headers)
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ View driver_effective_status acessível")
            print(f"📊 Registros encontrados: {len(data)}")
            
            if data:
                print("📋 Amostra de dados:")
                for i, record in enumerate(data):
                    print(f"   [{i+1}] Driver: {record.get('driver_id', 'N/A')[:8]}...")
                    print(f"       Intent: {record.get('online_intent', 'N/A')}")
                    print(f"       Within Hours: {record.get('is_within_working_hours', 'N/A')}")
                    print(f"       Effective Online: {record.get('effective_online', 'N/A')}")
            else:
                print("⚠️ View está vazia")
                
            return True
        else:
            print(f"❌ Erro ao acessar view: {response.status_code}")
            print(f"📋 Detalhes: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro na verificação: {e}")
        return False

def check_working_hours_structure():
    """Verifica a estrutura da tabela working_hours"""
    print("\n🔍 Verificando estrutura da tabela working_hours...")
    
    try:
        # Verificar alguns registros
        url = f"{SUPABASE_URL}/rest/v1/working_hours?select=driver_id,day_of_week,start_time,end_time,is_active&limit=3"
        response = requests.get(url, headers=headers)
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Tabela working_hours acessível")
            print(f"📊 Registros encontrados: {len(data)}")
            
            if data:
                print("📋 Amostra de dados:")
                for i, record in enumerate(data):
                    print(f"   [{i+1}] Driver: {record.get('driver_id', 'N/A')[:8]}...")
                    print(f"       Dia: {record.get('day_of_week', 'N/A')}")
                    print(f"       Horário: {record.get('start_time', 'N/A')} - {record.get('end_time', 'N/A')}")
                    print(f"       Ativo: {record.get('is_active', 'N/A')}")
            else:
                print("ℹ️ Tabela working_hours está vazia")
                
            return True
        else:
            print(f"❌ Erro ao acessar tabela: {response.status_code}")
            print(f"📋 Detalhes: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro na verificação: {e}")
        return False

def check_driver_status_structure():
    """Verifica a estrutura da tabela driver_status"""
    print("\n🔍 Verificando estrutura da tabela driver_status...")
    
    try:
        # Verificar alguns registros
        url = f"{SUPABASE_URL}/rest/v1/driver_status?select=driver_id,online_intent,updated_at&limit=3"
        response = requests.get(url, headers=headers)
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Tabela driver_status acessível")
            print(f"📊 Registros encontrados: {len(data)}")
            
            if data:
                print("📋 Amostra de dados:")
                for i, record in enumerate(data):
                    print(f"   [{i+1}] Driver: {record.get('driver_id', 'N/A')[:8]}...")
                    print(f"       Intent: {record.get('online_intent', 'N/A')}")
                    print(f"       Updated: {record.get('updated_at', 'N/A')}")
            else:
                print("ℹ️ Tabela driver_status está vazia")
                
            return True
        else:
            print(f"❌ Erro ao acessar tabela: {response.status_code}")
            print(f"📋 Detalhes: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro na verificação: {e}")
        return False

def main():
    print("✅ Script de verificação pós-correção")
    print("=" * 40)
    
    # Executar verificações
    view_ok = verify_driver_effective_status_view()
    table_ok = check_working_hours_structure()
    status_ok = check_driver_status_structure()
    
    print("\n" + "=" * 40)
    print("📋 RESUMO DA VERIFICAÇÃO:")
    print(f"   View driver_effective_status: {'✅ OK' if view_ok else '❌ ERRO'}")
    print(f"   Tabela working_hours: {'✅ OK' if table_ok else '❌ ERRO'}")
    print(f"   Tabela driver_status: {'✅ OK' if status_ok else '❌ ERRO'}")
    
    if view_ok and table_ok and status_ok:
        print("\n🎉 Todas as verificações passaram!")
        print("💡 A correção foi aplicada com sucesso.")
    else:
        print("\n⚠️ Algumas verificações falharam.")
        print("💡 Verifique os erros acima e tente novamente.")

if __name__ == "__main__":
    main()