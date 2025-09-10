#!/usr/bin/env python3
"""
Script para configurar motoristas de teste com localizações atualizadas
"""

import os
from supabase import create_client, Client
from datetime import datetime, timezone
import random

# Configuração do Supabase
url = os.environ.get('SUPABASE_URL')
key = os.environ.get('SUPABASE_ANON_KEY')

if not url or not key:
    print("❌ Variáveis SUPABASE_URL e SUPABASE_ANON_KEY não encontradas")
    exit(1)

supabase: Client = create_client(url, key)

def setup_test_drivers():
    """Configura motoristas de teste com status online e localizações atualizadas"""
    try:
        # Buscar motoristas aprovados
        response = supabase.table('drivers').select('*').eq('approval_status', 'approved').execute()
        
        if not response.data:
            print("❌ Nenhum motorista aprovado encontrado")
            return
        
        print(f"📊 Encontrados {len(response.data)} motoristas aprovados")
        
        # Coordenadas de São Paulo (diferentes bairros)
        sp_locations = [
            (-23.5505, -46.6333, "Centro"),
            (-23.5475, -46.6361, "República"),
            (-23.5535, -46.6295, "Sé"),
            (-23.5489, -46.6388, "Vila Madalena"),
            (-23.5613, -46.6563, "Jardins"),
            (-23.5329, -46.6395, "Consolação"),
            (-23.5558, -46.6396, "Bela Vista"),
            (-23.5448, -46.6388, "Pinheiros"),
            (-23.5629, -46.6544, "Paulista"),
            (-23.5506, -46.6167, "Liberdade")
        ]
        
        updated_count = 0
        online_count = 0
        current_time = datetime.now(timezone.utc).isoformat()
        
        # Colocar os primeiros 5 motoristas online com localizações
        drivers_to_update = response.data[:5]
        
        for i, driver in enumerate(drivers_to_update):
            # Escolher localização
            lat, lng, neighborhood = sp_locations[i % len(sp_locations)]
            
            # Adicionar pequena variação para não ficarem no mesmo local
            lat += random.uniform(-0.005, 0.005)
            lng += random.uniform(-0.005, 0.005)
            
            # Atualizar motorista para online com localização
            update_data = {
                'is_online': True,
                'current_latitude': lat,
                'current_longitude': lng,
                'last_location_update': current_time,
                'consecutive_cancellations': 0  # Resetar cancelamentos
            }
            
            update_response = supabase.table('drivers').update(update_data).eq('id', driver['id']).execute()
            
            if update_response.data:
                print(f"✅ Motorista {driver['id'][:8]}... online em {neighborhood}: {lat:.6f}, {lng:.6f}")
                updated_count += 1
                online_count += 1
            else:
                print(f"❌ Erro ao atualizar motorista {driver['id'][:8]}...")
        
        # Colocar alguns motoristas offline para simular cenário real
        remaining_drivers = response.data[5:]
        for driver in remaining_drivers[:2]:
            update_response = supabase.table('drivers').update({
                'is_online': False
            }).eq('id', driver['id']).execute()
            
            if update_response.data:
                print(f"📴 Motorista {driver['id'][:8]}... colocado offline")
                updated_count += 1
        
        print(f"\n🎯 RESULTADO:")
        print(f"   📊 {updated_count} motoristas atualizados")
        print(f"   🟢 {online_count} motoristas online")
        print(f"   🔴 {len(remaining_drivers[:2])} motoristas offline")
        
    except Exception as e:
        print(f"❌ Erro ao configurar motoristas: {e}")

def test_driver_search():
    """Testa busca de motoristas próximos"""
    try:
        print("\n🔍 Testando busca de motoristas próximos...")
        
        # Coordenadas do centro de São Paulo
        center_lat = -23.5505
        center_lng = -46.6333
        
        # Buscar motoristas aprovados e online
        response = supabase.table('drivers').select('*').eq('approval_status', 'approved').eq('is_online', True).execute()
        
        if response.data:
            print(f"✅ Encontrados {len(response.data)} motoristas online")
            
            # Calcular distâncias
            nearby_drivers = []
            for driver in response.data:
                if driver['current_latitude'] and driver['current_longitude']:
                    # Cálculo simples de distância
                    lat_diff = abs(driver['current_latitude'] - center_lat)
                    lng_diff = abs(driver['current_longitude'] - center_lng)
                    distance = (lat_diff + lng_diff) * 111  # Aproximação em km
                    
                    if distance < 10:  # Dentro de 10km
                        nearby_drivers.append((driver, distance))
            
            nearby_drivers.sort(key=lambda x: x[1])  # Ordenar por distância
            
            print(f"📍 Motoristas próximos (< 10km): {len(nearby_drivers)}")
            for driver, distance in nearby_drivers[:3]:
                print(f"   🚗 {driver['id'][:8]}... - {distance:.2f}km - Lat: {driver['current_latitude']:.6f}, Lng: {driver['current_longitude']:.6f}")
        else:
            print("❌ Nenhum motorista online encontrado")
            
    except Exception as e:
        print(f"❌ Erro ao testar busca: {e}")

if __name__ == "__main__":
    print("🚀 CONFIGURANDO MOTORISTAS DE TESTE")
    print("=" * 50)
    
    setup_test_drivers()
    test_driver_search()
    
    print("\n✨ Configuração concluída!")
    print("\n📋 PRÓXIMOS PASSOS:")
    print("   1. Execute o SQL fix_view_permissions.sql no Supabase Dashboard")
    print("   2. Teste a busca de motoristas no app")
    print("   3. Verifique se os motoristas aparecem para os passageiros")