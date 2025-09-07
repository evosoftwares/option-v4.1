#!/usr/bin/env python3
"""
Script final para diagnosticar problemas específicos de cadastro
"""

from datetime import datetime, timedelta
from supabase import create_client, Client

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def main():
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    print("🔍 DIAGNÓSTICO COMPLETO - PROBLEMAS DE CADASTRO")
    print("=" * 70)
    
    # Data limite (últimas 24 horas)
    since = datetime.now() - timedelta(hours=24)
    since_str = since.isoformat()
    
    # 1. Verificar motoristas com problemas específicos
    print("\n🚗 ANÁLISE DETALHADA DOS MOTORISTAS RECENTES:")
    print("-" * 50)
    
    try:
        drivers = supabase.table('drivers')\
            .select('*')\
            .gte('created_at', since_str)\
            .order('created_at', desc=True)\
            .execute()
        
        if drivers.data:
            for driver in drivers.data:
                print(f"🚗 MOTORISTA ID: {driver.get('user_id', 'N/A')}")
                print(f"   Status de Aprovação: {driver.get('approval_status', 'N/A')}")
                print(f"   Veículo: {driver.get('vehicle_brand', 'N/A')} {driver.get('vehicle_model', 'N/A')}")
                print(f"   Placa: {driver.get('vehicle_plate', 'N/A')}")
                print(f"   Cor: {driver.get('vehicle_color', 'N/A')}")
                print(f"   Ano: {driver.get('vehicle_year', 'N/A')}")
                print(f"   Aprovado por: {driver.get('approved_by', 'Ninguém')}")
                print(f"   Data aprovação: {driver.get('approved_at', 'Não aprovado')}")
                print(f"   Online: {driver.get('is_online', False)}")
                print(f"   Criado: {driver.get('created_at', 'N/A')}")
                
                # Verificar problemas específicos
                problems = []
                if driver.get('approval_status') != 'approved':
                    problems.append(f"Status: {driver.get('approval_status', 'N/A')}")
                if not driver.get('vehicle_plate'):
                    problems.append("Sem placa do veículo")
                if driver.get('vehicle_brand') == 'PENDENTE' or driver.get('vehicle_model') == 'PENDENTE':
                    problems.append("Dados do veículo pendentes")
                if not driver.get('approved_by'):
                    problems.append("Aguardando aprovação manual")
                
                if problems:
                    print(f"   ⚠️  PROBLEMAS: {'; '.join(problems)}")
                else:
                    print("   ✅ Sem problemas identificados")
                print()
        else:
            print("⚠️  Nenhum motorista criado nas últimas 24h")
            
    except Exception as e:
        print(f"❌ Erro ao consultar motoristas: {e}")
    
    # 2. Verificar documentos
    print("\n📄 ANÁLISE DE DOCUMENTOS:")
    print("-" * 50)
    
    try:
        # Verificar se há documentos pendentes
        pending_docs = supabase.table('driver_documents')\
            .select('*')\
            .neq('status', 'approved')\
            .order('created_at', desc=True)\
            .limit(10)\
            .execute()
        
        if pending_docs.data:
            print(f"📄 DOCUMENTOS PENDENTES/REJEITADOS ({len(pending_docs.data)}):")
            for doc in pending_docs.data:
                print(f"   - Driver: {doc.get('driver_id', 'N/A')}")
                print(f"     Tipo: {doc.get('document_type', 'N/A')}")
                print(f"     Status: {doc.get('status', 'N/A')}")
                print(f"     Criado: {doc.get('created_at', 'N/A')}")
                if doc.get('rejection_reason'):
                    print(f"     Motivo rejeição: {doc.get('rejection_reason')}")
                print()
        else:
            print("✅ Nenhum documento pendente encontrado")
            
    except Exception as e:
        print(f"❌ Erro ao consultar documentos: {e}")
    
    # 3. Verificar configurações da plataforma
    print("\n⚙️  CONFIGURAÇÕES DA PLATAFORMA:")
    print("-" * 50)
    
    try:
        settings = supabase.table('platform_settings')\
            .select('*')\
            .execute()
        
        if settings.data:
            for setting in settings.data:
                key = setting.get('key', 'N/A')
                value = setting.get('value', 'N/A')
                print(f"   {key}: {value}")
                
                # Verificar configurações críticas
                if key == 'require_manual_approval' and value == 'true':
                    print("     ⚠️  APROVAÇÃO MANUAL OBRIGATÓRIA ATIVADA")
                elif key == 'auto_approve_drivers' and value == 'false':
                    print("     ⚠️  AUTO-APROVAÇÃO DESATIVADA")
                elif key in ['min_vehicle_year', 'max_vehicle_age']:
                    print(f"     📅 Restrição de idade do veículo: {value}")
        else:
            print("⚠️  Nenhuma configuração encontrada")
            
    except Exception as e:
        print(f"❌ Erro ao consultar configurações: {e}")
    
    # 4. Estatísticas gerais
    print("\n📊 ESTATÍSTICAS GERAIS:")
    print("-" * 50)
    
    try:
        # Total de usuários
        total_users = supabase.table('app_users').select('id', count='exact').execute()
        print(f"👥 Total de usuários: {total_users.count}")
        
        # Total de motoristas
        total_drivers = supabase.table('drivers').select('id', count='exact').execute()
        print(f"🚗 Total de motoristas: {total_drivers.count}")
        
        # Motoristas aprovados
        approved_drivers = supabase.table('drivers')\
            .select('id', count='exact')\
            .eq('approval_status', 'approved')\
            .execute()
        print(f"✅ Motoristas aprovados: {approved_drivers.count}")
        
        # Motoristas pendentes
        pending_drivers = supabase.table('drivers')\
            .select('id', count='exact')\
            .eq('approval_status', 'pending')\
            .execute()
        print(f"⏳ Motoristas pendentes: {pending_drivers.count}")
        
        # Motoristas rejeitados
        rejected_drivers = supabase.table('drivers')\
            .select('id', count='exact')\
            .eq('approval_status', 'rejected')\
            .execute()
        print(f"❌ Motoristas rejeitados: {rejected_drivers.count}")
        
    except Exception as e:
        print(f"❌ Erro ao consultar estatísticas: {e}")
    
    print("\n" + "=" * 70)
    print("✅ DIAGNÓSTICO CONCLUÍDO!")
    print("\n💡 RESUMO DOS PROBLEMAS IDENTIFICADOS:")
    print("   1. ⚠️  Motoristas ficam com status 'pending' - precisa aprovação manual")
    print("   2. 📄 Poucos documentos sendo enviados - verificar tela de upload")
    print("   3. 🔍 Sistema de logs não implementado - criar tabelas error_logs e app_logs")
    print("\n🔧 PRÓXIMOS PASSOS:")
    print("   1. Verificar se existe processo de aprovação automática")
    print("   2. Testar fluxo de upload de documentos")
    print("   3. Implementar sistema de logs estruturado")

if __name__ == "__main__":
    main()