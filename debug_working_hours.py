#!/usr/bin/env python3
"""
Script de debug para verificar funcionamento dos horários de trabalho
"""

import requests
import json
from datetime import datetime

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk"

headers = {
    "apikey": SUPABASE_SERVICE_ROLE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
    "Content-Type": "application/json"
}

def test_driver_working_hours(driver_id):
    """Testa os horários de trabalho de um motorista específico"""
    print(f"🔍 Testando horários de trabalho para driver_id: {driver_id}")
    
    try:
        # 1. Verificar dados do motorista
        print("\n1. Verificando dados do motorista...")
        driver_url = f"{SUPABASE_URL}/rest/v1/drivers?id=eq.{driver_id}"
        driver_response = requests.get(driver_url, headers=headers)
        
        if driver_response.status_code == 200 and driver_response.json():
            driver_data = driver_response.json()[0]
            print(f"✅ Motorista encontrado: {driver_data.get('id')}")
        else:
            print("❌ Motorista não encontrado")
            return
        
        # 2. Verificar status do motorista
        print("\n2. Verificando status do motorista...")
        status_url = f"{SUPABASE_URL}/rest/v1/driver_status?driver_id=eq.{driver_id}"
        status_response = requests.get(status_url, headers=headers)
        
        if status_response.status_code == 200:
            status_data = status_response.json()
            if status_data:
                print(f"✅ Status encontrado: online_intent = {status_data[0].get('online_intent')}")
            else:
                print("⚠️ Nenhum status encontrado para este motorista")
        
        # 3. Verificar horários de trabalho
        print("\n3. Verificando horários de trabalho...")
        hours_url = f"{SUPABASE_URL}/rest/v1/working_hours?driver_id=eq.{driver_id}&is_active=eq.true"
        hours_response = requests.get(hours_url, headers=headers)
        
        if hours_response.status_code == 200:
            hours_data = hours_response.json()
            if hours_data:
                print(f"✅ {len(hours_data)} horário(s) de trabalho encontrado(s):")
                for hour in hours_data:
                    print(f"   📅 Dia {hour['day_of_week']}: {hour['start_time']} - {hour['end_time']}")
            else:
                print("ℹ️ Nenhum horário de trabalho ativo encontrado")
        
        # 4. Verificar view driver_effective_status
        print("\n4. Verificando view driver_effective_status...")
        effective_url = f"{SUPABASE_URL}/rest/v1/driver_effective_status?driver_id=eq.{driver_id}"
        effective_response = requests.get(effective_url, headers=headers)
        
        if effective_response.status_code == 200:
            effective_data = effective_response.json()
            if effective_data:
                status = effective_data[0]
                print(f"✅ Status efetivo encontrado:")
                print(f"   🔹 online_intent: {status.get('online_intent')}")
                print(f"   🔹 is_within_working_hours: {status.get('is_within_working_hours')}")
                print(f"   🔹 effective_online: {status.get('effective_online')}")
            else:
                print("❌ Nenhum status efetivo encontrado")
        else:
            print(f"❌ Erro ao buscar status efetivo: {effective_response.status_code}")
        
        # 5. Verificar horário atual
        print("\n5. Informações de horário atual...")
        now = datetime.now()
        day_of_week = now.weekday()  # 0=Segunda, 6=Domingo (ajustar para 0=Domingo)
        day_of_week = (day_of_week + 1) % 7  # Converter para 0=Domingo
        current_time = now.strftime("%H:%M:%S")
        
        print(f"   📅 Dia da semana atual: {day_of_week} ({now.strftime('%A')})")
        print(f"   🕐 Hora atual: {current_time}")
        
    except Exception as e:
        print(f"❌ Erro durante o teste: {e}")

def list_all_drivers_with_working_hours():
    """Lista todos os motoristas com seus horários de trabalho"""
    print("📋 Listando todos os motoristas com horários de trabalho...")
    
    try:
        # Buscar motoristas
        drivers_url = f"{SUPABASE_URL}/rest/v1/drivers?select=id,user_id&limit=10"
        drivers_response = requests.get(drivers_url, headers=headers)
        
        if drivers_response.status_code == 200:
            drivers = drivers_response.json()
            print(f"📊 Encontrados {len(drivers)} motoristas")
            
            for driver in drivers:
                driver_id = driver['id']
                user_id = driver['user_id']
                print(f"\n🚗 Motorista ID: {driver_id} (User: {user_id})")
                
                # Verificar horários
                hours_url = f"{SUPABASE_URL}/rest/v1/working_hours?driver_id=eq.{driver_id}&is_active=eq.true"
                hours_response = requests.get(hours_url, headers=headers)
                
                if hours_response.status_code == 200:
                    hours = hours_response.json()
                    if hours:
                        print(f"   📅 {len(hours)} horário(s) ativo(s):")
                        for hour in hours:
                            print(f"      Dia {hour['day_of_week']}: {hour['start_time']} - {hour['end_time']}")
                    else:
                        print("   ℹ️ Nenhum horário ativo")
                else:
                    print(f"   ❌ Erro ao buscar horários: {hours_response.status_code}")
        else:
            print(f"❌ Erro ao buscar motoristas: {drivers_response.status_code}")
            
    except Exception as e:
        print(f"❌ Erro ao listar motoristas: {e}")

def create_sample_working_hours(driver_id):
    """Cria horários de trabalho de exemplo para testes"""
    print(f"🆕 Criando horários de trabalho de exemplo para driver_id: {driver_id}")
    
    sample_hours = [
        {
            "driver_id": driver_id,
            "day_of_week": 1,  # Segunda
            "start_time": "08:00:00",
            "end_time": "18:00:00",
            "is_active": True
        },
        {
            "driver_id": driver_id,
            "day_of_week": 2,  # Terça
            "start_time": "08:00:00",
            "end_time": "18:00:00",
            "is_active": True
        }
    ]
    
    try:
        for hour_data in sample_hours:
            # Inserir horário
            insert_url = f"{SUPABASE_URL}/rest/v1/working_hours"
            response = requests.post(insert_url, headers=headers, json=hour_data)
            
            if response.status_code in [200, 201]:
                print(f"✅ Horário criado para dia {hour_data['day_of_week']}")
            else:
                print(f"❌ Erro ao criar horário: {response.status_code} - {response.text}")
                
    except Exception as e:
        print(f"❌ Erro ao criar horários de exemplo: {e}")

if __name__ == "__main__":
    print("🔧 Script de debug dos horários de trabalho")
    print("=" * 40)
    
    # Menu de opções
    print("\nEscolha uma opção:")
    print("1. Testar horários de um motorista específico")
    print("2. Listar todos os motoristas com horários")
    print("3. Criar horários de exemplo")
    
    choice = input("\nOpção: ").strip()
    
    if choice == "1":
        driver_id = input("Informe o ID do motorista: ").strip()
        if driver_id:
            test_driver_working_hours(driver_id)
        else:
            print("❌ ID do motorista não informado")
    elif choice == "2":
        list_all_drivers_with_working_hours()
    elif choice == "3":
        driver_id = input("Informe o ID do motorista: ").strip()
        if driver_id:
            create_sample_working_hours(driver_id)
        else:
            print("❌ ID do motorista não informado")
    else:
        print("❌ Opção inválida")