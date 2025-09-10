#!/usr/bin/env python3
"""
Script para atualizar localizações dos motoristas para teste
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
    print("Configure as variáveis de ambiente primeiro")
    exit(1)

supabase: Client = create_client(url, key)

def update_driver_locations():
    """Atualiza localizações dos motoristas aprovados e online"""
    try:
        # Buscar motoristas aprovados e online
        response = supabase.table('drivers').select('*').eq('approval_status', 'approved').eq('is_online', True).execute()
        
        if not response.data:
            print("❌ Nenhum motorista aprovado e online encontrado")
            return
        
        print(f"📊 Encontrados {len(response.data)} motoristas aprovados e online")
        
        # Coordenadas de São Paulo (centro expandido)
        sp_coords = [
            (-23.5505, -46.6333),  # Centro
            (-23.5475, -46.6361),  # Próximo ao centro
            (-23.5535, -46.6295),  # Próximo ao centro
            (-23.5489, -46.6388),  # Vila Madalena
            (-23.5613, -46.6563),  # Jardins
            (-23.5329, -46.6395),  # Consolação
        ]
        
        updated_count = 0
        current_time = datetime.now(timezone.utc).isoformat()
        
        for driver in response.data:
            # Escolher coordenada aleatória
            lat, lng = random.choice(sp_coords)
            
            # Adicionar pequena variação
            lat += random.uniform(-0.01, 0.01)
            lng += random.uniform(-0.01, 0.01)
            
            # Atualizar localização
            update_response = supabase.table('drivers').update({
                'current_latitude': lat,
                'current_longitude': lng,
                'last_location_update': current_time
            }).eq('id', driver['id']).execute()
            
            if update_response.data:
                print(f"✅ Motorista {driver['id'][:8]}... atualizado: {lat:.6f}, {lng:.6f}")
                updated_count += 1
            else:
                print(f"❌ Erro ao atualizar motorista {driver['id'][:8]}...")
        
        print(f"\n🎯 RESULTADO: {updated_count} motoristas atualizados com sucesso")
        
    except Exception as e:
        print(f"❌ Erro ao atualizar localizações: {e}")

def test_available_drivers_view():
    """Testa a view available_drivers_view"""
    try:
        print("\n🔍 Testando view available_drivers_view...")
        response = supabase.table('available_drivers_view').select('*').limit(5).execute()
        
        if response.data:
            print(f"✅ View funcionando! Encontrados {len(response.data)} motoristas disponíveis")
            for driver in response.data:
                print(f"   🚗 ID: {driver['driver_id'][:8]}... - Lat: {driver['current_latitude']:.6f}, Lng: {driver['current_longitude']:.6f}")
        else:
            print("⚠️  View existe mas não retornou dados")
            
    except Exception as e:
        print(f"❌ Erro ao testar view: {e}")

if __name__ == "__main__":
    print("🚀 ATUALIZANDO LOCALIZAÇÕES DOS MOTORISTAS")
    print("=" * 50)
    
    update_driver_locations()
    test_available_drivers_view()
    
    print("\n✨ Processo concluído!")