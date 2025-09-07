#!/usr/bin/env python3
"""
Script para verificar as tabelas disponíveis no Supabase e analisar problemas de cadastro
"""

import os
import sys
from datetime import datetime, timedelta
from supabase import create_client, Client

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def main():
    try:
        # Conectar ao Supabase
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        print("🔍 Conectado ao Supabase - Analisando estrutura do banco...")
        print("=" * 70)
        
        # Data limite (últimas 24 horas)
        since = datetime.now() - timedelta(hours=24)
        since_str = since.isoformat()
        
        # 1. Verificar usuários recentes com mais detalhes
        print("\n👥 ANÁLISE DETALHADA DE CADASTROS RECENTES:")
        print("-" * 50)
        
        try:
            users_response = supabase.table('app_users')\
                .select('*')\
                .gte('created_at', since_str)\
                .order('created_at', desc=True)\
                .execute()
            
            if users_response.data:
                for user in users_response.data:
                    print(f"📱 USUÁRIO: {user.get('phone', 'N/A')}")
                    print(f"   ID: {user.get('id', 'N/A')}")
                    print(f"   Tipo: {user.get('user_type', 'N/A')}")
                    print(f"   Nome: {user.get('full_name', 'N/A')}")
                    print(f"   Email: {user.get('email', 'N/A')}")
                    print(f"   Status: {user.get('status', 'N/A')}")
                    print(f"   Criado: {user.get('created_at', 'N/A')}")
                    print(f"   Atualizado: {user.get('updated_at', 'N/A')}")
                    print()
            else:
                print("⚠️  Nenhum usuário criado nas últimas 24h")
                
        except Exception as e:
            print(f"❌ Erro ao consultar app_users: {e}")
        
        # 2. Verificar motoristas recentes
        print("\n🚗 MOTORISTAS CADASTRADOS RECENTEMENTE:")
        print("-" * 50)
        
        try:
            drivers_response = supabase.table('drivers')\
                .select('*')\
                .gte('created_at', since_str)\
                .order('created_at', desc=True)\
                .execute()
            
            if drivers_response.data:
                for driver in drivers_response.data:
                    print(f"🚗 MOTORISTA: {driver.get('user_id', 'N/A')}")
                    print(f"   Veículo: {driver.get('vehicle_brand', 'N/A')} {driver.get('vehicle_model', 'N/A')}")
                    print(f"   Placa: {driver.get('license_plate', 'N/A')}")
                    print(f"   Status: {driver.get('status', 'N/A')}")
                    print(f"   Aprovado: {driver.get('approved', 'N/A')}")
                    print(f"   Criado: {driver.get('created_at', 'N/A')}")
                    print()
            else:
                print("⚠️  Nenhum motorista criado nas últimas 24h")
                
        except Exception as e:
            print(f"❌ Erro ao consultar drivers: {e}")
        
        # 3. Verificar documentos de motorista
        print("\n📄 DOCUMENTOS DE MOTORISTAS RECENTES:")
        print("-" * 50)
        
        try:
            docs_response = supabase.table('driver_documents')\
                .select('*')\
                .gte('created_at', since_str)\
                .order('created_at', desc=True)\
                .execute()
            
            if docs_response.data:
                for doc in docs_response.data:
                    print(f"📄 DOCUMENTO: {doc.get('document_type', 'N/A')}")
                    print(f"   Driver ID: {doc.get('driver_id', 'N/A')}")
                    print(f"   Status: {doc.get('status', 'N/A')}")
                    print(f"   URL: {doc.get('document_url', 'N/A')}")
                    print(f"   Criado: {doc.get('created_at', 'N/A')}")
                    print()
            else:
                print("✅ Nenhum documento enviado nas últimas 24h")
                
        except Exception as e:
            print(f"❌ Erro ao consultar driver_documents: {e}")
        
        # 4. Verificar requests de viagens recentes (pode indicar problemas)
        print("\n🚕 REQUESTS DE VIAGEM RECENTES:")
        print("-" * 50)
        
        try:
            requests_response = supabase.table('trip_requests')\
                .select('*')\
                .gte('created_at', since_str)\
                .order('created_at', desc=True)\
                .limit(10)\
                .execute()
            
            if requests_response.data:
                for req in requests_response.data:
                    print(f"🚕 REQUEST: {req.get('id', 'N/A')}")
                    print(f"   Passageiro: {req.get('passenger_id', 'N/A')}")
                    print(f"   Status: {req.get('status', 'N/A')}")
                    print(f"   Origem: {req.get('pickup_location', 'N/A')}")
                    print(f"   Criado: {req.get('created_at', 'N/A')}")
                    print()
            else:
                print("✅ Nenhuma solicitação de viagem nas últimas 24h")
                
        except Exception as e:
            print(f"❌ Erro ao consultar trip_requests: {e}")
        
        # 5. Verificar se há problemas com autenticação
        print("\n🔐 ANÁLISE DE POSSÍVEIS PROBLEMAS:")
        print("-" * 50)
        
        # Verificar usuários sem dados completos
        try:
            incomplete_users = supabase.table('app_users')\
                .select('id, phone, full_name, email, user_type')\
                .is_('full_name', 'null')\
                .limit(10)\
                .execute()
            
            if incomplete_users.data:
                print("⚠️  USUÁRIOS COM DADOS INCOMPLETOS:")
                for user in incomplete_users.data:
                    print(f"   - {user.get('phone', 'N/A')} (ID: {user.get('id', 'N/A')})")
            else:
                print("✅ Todos os usuários têm dados completos")
                
        except Exception as e:
            print(f"❌ Erro ao verificar usuários incompletos: {e}")
        
        # Verificar motoristas não aprovados
        try:
            unapproved_drivers = supabase.table('drivers')\
                .select('user_id, status, approved, created_at')\
                .eq('approved', False)\
                .limit(10)\
                .execute()
            
            if unapproved_drivers.data:
                print(f"\n⚠️  MOTORISTAS NÃO APROVADOS ({len(unapproved_drivers.data)}):")
                for driver in unapproved_drivers.data:
                    print(f"   - ID: {driver.get('user_id', 'N/A')} | Status: {driver.get('status', 'N/A')}")
            else:
                print("\n✅ Todos os motoristas estão aprovados")
                
        except Exception as e:
            print(f"\n❌ Erro ao verificar motoristas não aprovados: {e}")
            
        print("\n" + "=" * 70)
        print("✅ Análise concluída!")
        print("\n💡 DICA: Para ver logs detalhados do Supabase:")
        print("   1. Acesse: https://supabase.com/dashboard/project/qlbwacmavngtonauxnte/logs/explorer")
        print("   2. Vá em 'Logs' > 'Explorer' no menu lateral")
        print("   3. Filtre por 'Auth' ou 'Database' para ver erros específicos")
        
    except Exception as e:
        print(f"❌ Erro geral: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()