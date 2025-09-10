#!/usr/bin/env python3
"""
Script para testar o sistema de localização em background dos motoristas.
Verifica se as localizações estão sendo atualizadas corretamente a cada 5 minutos.
"""

import os
import time
import asyncio
from datetime import datetime, timedelta
from supabase import create_client, Client

# Configurações do Supabase
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_ANON_KEY = os.getenv('SUPABASE_ANON_KEY')

if not SUPABASE_URL or not SUPABASE_ANON_KEY:
    print("❌ Erro: Variáveis SUPABASE_URL e SUPABASE_ANON_KEY não encontradas")
    print("Execute: export SUPABASE_URL=... && export SUPABASE_ANON_KEY=...")
    exit(1)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)

def print_header(title):
    """Imprime um cabeçalho formatado"""
    print(f"\n{'='*60}")
    print(f" {title}")
    print(f"{'='*60}")

def print_section(title):
    """Imprime uma seção formatada"""
    print(f"\n{'-'*40}")
    print(f" {title}")
    print(f"{'-'*40}")

def check_location_updates():
    """Verifica as atualizações de localização dos motoristas"""
    print_header("TESTE DO SISTEMA DE LOCALIZAÇÃO EM BACKGROUND")
    
    try:
        # Buscar motoristas com localização recente (últimos 10 minutos)
        recent_threshold = datetime.now() - timedelta(minutes=10)
        
        print_section("Motoristas com Localização Recente (últimos 10 min)")
        
        response = supabase.table('drivers').select(
            'id, name, email, is_online, is_approved, latitude, longitude, location_updated_at'
        ).gte('location_updated_at', recent_threshold.isoformat()).execute()
        
        recent_drivers = response.data
        print(f"📍 {len(recent_drivers)} motoristas com localização recente")
        
        for driver in recent_drivers:
            location_time = datetime.fromisoformat(driver['location_updated_at'].replace('Z', '+00:00'))
            minutes_ago = (datetime.now() - location_time.replace(tzinfo=None)).total_seconds() / 60
            
            status = "🟢 ONLINE" if driver['is_online'] else "🔴 OFFLINE"
            approved = "✅ APROVADO" if driver['is_approved'] else "❌ PENDENTE"
            
            print(f"  • {driver['name']} ({driver['email']})")
            print(f"    Status: {status} | {approved}")
            print(f"    Localização: {driver['latitude']:.6f}, {driver['longitude']:.6f}")
            print(f"    Atualizada há: {minutes_ago:.1f} minutos")
            print()
        
        # Buscar todos os motoristas online e aprovados
        print_section("Todos os Motoristas Online e Aprovados")
        
        response = supabase.table('drivers').select(
            'id, name, email, is_online, is_approved, latitude, longitude, location_updated_at'
        ).eq('is_online', True).eq('is_approved', True).execute()
        
        online_drivers = response.data
        print(f"👥 {len(online_drivers)} motoristas online e aprovados")
        
        outdated_count = 0
        for driver in online_drivers:
            if driver['location_updated_at']:
                location_time = datetime.fromisoformat(driver['location_updated_at'].replace('Z', '+00:00'))
                minutes_ago = (datetime.now() - location_time.replace(tzinfo=None)).total_seconds() / 60
                
                if minutes_ago > 10:  # Localização desatualizada
                    outdated_count += 1
                    print(f"  ⚠️  {driver['name']} - localização desatualizada há {minutes_ago:.1f} min")
                else:
                    print(f"  ✅ {driver['name']} - localização atualizada há {minutes_ago:.1f} min")
            else:
                outdated_count += 1
                print(f"  ❌ {driver['name']} - sem localização")
        
        # Testar a view available_drivers_view
        print_section("Teste da View available_drivers_view")
        
        try:
            response = supabase.table('available_drivers_view').select('*').execute()
            available_drivers = response.data
            print(f"🎯 {len(available_drivers)} motoristas disponíveis na view")
            
            for driver in available_drivers:
                print(f"  • {driver['name']} - {driver['latitude']:.6f}, {driver['longitude']:.6f}")
                
        except Exception as e:
            print(f"❌ Erro ao acessar available_drivers_view: {e}")
            print("💡 Execute o arquivo fix_view_permissions.sql no Supabase Dashboard")
        
        # Resumo
        print_section("RESUMO")
        print(f"📊 Motoristas com localização recente: {len(recent_drivers)}")
        print(f"📊 Motoristas online/aprovados: {len(online_drivers)}")
        print(f"📊 Motoristas com localização desatualizada: {outdated_count}")
        
        if outdated_count > 0:
            print(f"\n⚠️  ATENÇÃO: {outdated_count} motoristas precisam atualizar a localização")
            print("💡 Certifique-se de que o BackgroundLocationService está ativo no app")
        else:
            print("\n✅ Todos os motoristas online têm localização atualizada!")
            
    except Exception as e:
        print(f"❌ Erro ao verificar localizações: {e}")

def monitor_location_updates(duration_minutes=15):
    """Monitora atualizações de localização por um período"""
    print_header(f"MONITORAMENTO DE LOCALIZAÇÕES ({duration_minutes} minutos)")
    
    start_time = datetime.now()
    end_time = start_time + timedelta(minutes=duration_minutes)
    
    print(f"🕐 Iniciando monitoramento às {start_time.strftime('%H:%M:%S')}")
    print(f"🕐 Terminará às {end_time.strftime('%H:%M:%S')}")
    print("\n📡 Pressione Ctrl+C para parar o monitoramento\n")
    
    last_counts = {}
    
    try:
        while datetime.now() < end_time:
            # Verificar atualizações a cada 30 segundos
            current_time = datetime.now()
            
            # Contar motoristas com localização recente (últimos 5 minutos)
            recent_threshold = current_time - timedelta(minutes=5)
            
            response = supabase.table('drivers').select(
                'id, name, location_updated_at'
            ).gte('location_updated_at', recent_threshold.isoformat()).eq('is_online', True).execute()
            
            current_count = len(response.data)
            
            # Detectar mudanças
            if current_count != last_counts.get('recent', 0):
                print(f"🔄 {current_time.strftime('%H:%M:%S')} - {current_count} motoristas com localização recente")
                
                # Mostrar quais motoristas atualizaram
                for driver in response.data:
                    location_time = datetime.fromisoformat(driver['location_updated_at'].replace('Z', '+00:00'))
                    seconds_ago = (current_time - location_time.replace(tzinfo=None)).total_seconds()
                    
                    if seconds_ago < 60:  # Atualizado no último minuto
                        print(f"  📍 {driver['name']} atualizou localização há {seconds_ago:.0f}s")
            
            last_counts['recent'] = current_count
            time.sleep(30)  # Verificar a cada 30 segundos
            
    except KeyboardInterrupt:
        print("\n🛑 Monitoramento interrompido pelo usuário")
    
    print(f"\n✅ Monitoramento concluído às {datetime.now().strftime('%H:%M:%S')}")

def main():
    """Função principal"""
    print("🚀 Sistema de Teste de Localização em Background")
    print("\nOpções:")
    print("1. Verificar localizações atuais")
    print("2. Monitorar atualizações (15 min)")
    print("3. Ambos")
    
    choice = input("\nEscolha uma opção (1-3): ").strip()
    
    if choice == '1':
        check_location_updates()
    elif choice == '2':
        monitor_location_updates()
    elif choice == '3':
        check_location_updates()
        input("\nPressione Enter para iniciar o monitoramento...")
        monitor_location_updates()
    else:
        print("❌ Opção inválida")
        return
    
    print("\n🏁 Teste concluído!")

if __name__ == '__main__':
    main()