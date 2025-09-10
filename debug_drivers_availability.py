#!/usr/bin/env python3
"""
Script para debugar o problema de motoristas não aparecendo para passageiros
"""

import os
from supabase import create_client, Client
from datetime import datetime, timedelta

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def main():
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    print("🔍 DIAGNÓSTICO: Motoristas não aparecendo para passageiros")
    print("=" * 70)
    
    # 1. Verificar total de motoristas cadastrados
    print("\n1️⃣ TOTAL DE MOTORISTAS CADASTRADOS:")
    print("-" * 40)
    try:
        total_drivers = supabase.table('drivers').select('id', count='exact').execute()
        print(f"   📊 Total: {total_drivers.count} motoristas")
    except Exception as e:
        print(f"   ❌ Erro: {e}")
    
    # 2. Verificar motoristas online
    print("\n2️⃣ MOTORISTAS ONLINE:")
    print("-" * 40)
    try:
        online_drivers = supabase.table('drivers').select('*').eq('is_online', True).execute()
        print(f"   📊 Online: {len(online_drivers.data)} motoristas")
        
        if online_drivers.data:
            print("   📋 Detalhes dos motoristas online:")
            for driver in online_drivers.data[:5]:  # Mostrar apenas os primeiros 5
                print(f"      🚗 ID: {driver['id'][:8]}...")
                print(f"         Status: {driver.get('approval_status', 'N/A')}")
                print(f"         Localização: {driver.get('current_latitude', 'N/A')}, {driver.get('current_longitude', 'N/A')}")
                print(f"         Última atualização: {driver.get('last_location_update', 'N/A')}")
                print(f"         Categoria: {driver.get('vehicle_category', 'N/A')}")
                print()
    except Exception as e:
        print(f"   ❌ Erro: {e}")
    
    # 3. Verificar motoristas aprovados
    print("\n3️⃣ MOTORISTAS APROVADOS:")
    print("-" * 40)
    try:
        approved_drivers = supabase.table('drivers').select('*').eq('approval_status', 'approved').execute()
        print(f"   📊 Aprovados: {len(approved_drivers.data)} motoristas")
        
        # Verificar quantos aprovados estão online
        approved_online = [d for d in approved_drivers.data if d.get('is_online', False)]
        print(f"   📊 Aprovados e Online: {len(approved_online)} motoristas")
        
    except Exception as e:
        print(f"   ❌ Erro: {e}")
    
    # 4. Verificar motoristas com localização atual
    print("\n4️⃣ MOTORISTAS COM LOCALIZAÇÃO ATUAL:")
    print("-" * 40)
    try:
        drivers_with_location = supabase.table('drivers').select('*').not_.is_('current_latitude', 'null').not_.is_('current_longitude', 'null').execute()
        print(f"   📊 Com localização: {len(drivers_with_location.data)} motoristas")
        
        # Verificar localização recente (últimas 2 horas)
        recent_cutoff = datetime.now() - timedelta(hours=2)
        recent_locations = []
        for driver in drivers_with_location.data:
            if driver.get('last_location_update'):
                try:
                    last_update = datetime.fromisoformat(driver['last_location_update'].replace('Z', '+00:00'))
                    if last_update > recent_cutoff:
                        recent_locations.append(driver)
                except:
                    pass
        
        print(f"   📊 Localização recente (2h): {len(recent_locations)} motoristas")
        
    except Exception as e:
        print(f"   ❌ Erro: {e}")
    
    # 5. Verificar se a view available_drivers_view existe
    print("\n5️⃣ VERIFICAR VIEW AVAILABLE_DRIVERS_VIEW:")
    print("-" * 40)
    try:
        view_result = supabase.table('available_drivers_view').select('*').limit(1).execute()
        print(f"   ✅ View existe e retornou {len(view_result.data)} registros")
        if view_result.data:
            print(f"   📋 Campos da view: {list(view_result.data[0].keys())}")
    except Exception as e:
        print(f"   ❌ View não existe ou erro: {e}")
        print("   ⚠️  Isso explica por que o código está falhando!")
    
    # 6. Testar busca de motoristas próximos (simulando São Paulo)
    print("\n6️⃣ TESTE DE BUSCA PRÓXIMA (São Paulo):")
    print("-" * 40)
    try:
        # Coordenadas aproximadas de São Paulo
        lat, lng = -23.5505, -46.6333
        radius_km = 10.0
        
        # Calcular bounding box
        lat_delta = radius_km / 111.0
        lng_delta = radius_km / (111.0 * abs(lat * 3.14159 / 180.0))
        
        nearby_drivers = supabase.table('drivers').select('*').eq('is_online', True).eq('approval_status', 'approved').gte('current_latitude', lat - lat_delta).lte('current_latitude', lat + lat_delta).gte('current_longitude', lng - lng_delta).lte('current_longitude', lng + lng_delta).execute()
        
        print(f"   📊 Motoristas próximos (SP): {len(nearby_drivers.data)} encontrados")
        
        if nearby_drivers.data:
            print("   📋 Primeiros resultados:")
            for driver in nearby_drivers.data[:3]:
                print(f"      🚗 ID: {driver['id'][:8]}...")
                print(f"         Localização: {driver.get('current_latitude', 'N/A')}, {driver.get('current_longitude', 'N/A')}")
                print(f"         Categoria: {driver.get('vehicle_category', 'N/A')}")
                print()
        
    except Exception as e:
        print(f"   ❌ Erro na busca: {e}")
    
    # 7. Verificar viagens ativas
    print("\n7️⃣ VERIFICAR VIAGENS ATIVAS:")
    print("-" * 40)
    try:
        active_trips = supabase.table('trips').select('driver_id').in_('status', ['ongoing', 'arrived', 'picked_up']).execute()
        active_driver_ids = [trip['driver_id'] for trip in active_trips.data if trip.get('driver_id')]
        print(f"   📊 Motoristas em viagem ativa: {len(set(active_driver_ids))}")
    except Exception as e:
        print(f"   ❌ Erro: {e}")
    
    print("\n" + "=" * 70)
    print("🎯 RESUMO DO DIAGNÓSTICO:")
    print("   1. Verifique se existem motoristas aprovados e online")
    print("   2. Verifique se a view 'available_drivers_view' existe")
    print("   3. Verifique se as localizações estão sendo atualizadas")
    print("   4. Verifique se não há filtros muito restritivos")
    print("=" * 70)

if __name__ == "__main__":
    main()