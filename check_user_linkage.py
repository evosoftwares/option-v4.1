#!/usr/bin/env python3
"""
Script para verificar a linkagem entre auth.users, app_users e drivers
"""

from supabase import create_client, Client

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def main():
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    print("🔍 Verificando linkagem entre auth.users, app_users e drivers...")
    print("=" * 70)
    
    # Pegar o driver que encontramos
    driver_user_id = "b2a68a5a-7309-4d23-9ec5-01d1ac5a93b3"
    
    try:
        # 1. Verificar se existe app_user com esse ID
        print(f"\n1️⃣ Verificando app_user com ID: {driver_user_id}")
        app_user_result = supabase.table('app_users').select('*').eq('id', driver_user_id).execute()
        
        if app_user_result.data:
            app_user = app_user_result.data[0]
            print("✅ app_user encontrado:")
            print(f"   ID: {app_user['id']}")
            print(f"   Email: {app_user['email']}")
            print(f"   Nome: {app_user['full_name']}")
            print(f"   Tipo: {app_user['user_type']}")
            print(f"   Status: {app_user['status']}")
            
            # 2. Verificar se esse ID existe no auth.users
            print(f"\n2️⃣ Verificando se ID {driver_user_id} existe no auth.users...")
            # Nota: Não podemos acessar auth.users diretamente via API REST
            # Mas podemos verificar se o constraint está funcionando
            print("⚠️ Não é possível verificar auth.users diretamente via API REST")
            print("   Mas se app_user existe, significa que o constraint FK está OK")
            
        else:
            print("❌ app_user NÃO encontrado!")
            
        # 3. Verificar todos os drivers e seus app_users
        print(f"\n3️⃣ Verificando todos os drivers e suas linkagens...")
        drivers_result = supabase.table('drivers').select('id, user_id').execute()
        
        if drivers_result.data:
            print(f"📊 Total de drivers: {len(drivers_result.data)}")
            
            for driver in drivers_result.data:
                driver_id = driver['id']
                user_id = driver['user_id']
                
                # Verificar se existe app_user correspondente
                user_check = supabase.table('app_users').select('id, email, full_name, user_type').eq('id', user_id).execute()
                
                if user_check.data:
                    user_data = user_check.data[0]
                    status = "✅" if user_data['user_type'] == 'driver' else "⚠️"
                    print(f"   {status} Driver {driver_id[:8]}... -> User {user_id[:8]}... ({user_data['email']}) - Tipo: {user_data['user_type']}")
                else:
                    print(f"   ❌ Driver {driver_id[:8]}... -> User {user_id[:8]}... (NÃO ENCONTRADO)")
        
        # 4. Verificar app_users órfãos (sem driver correspondente)
        print(f"\n4️⃣ Verificando app_users do tipo 'driver' sem registro na tabela drivers...")
        driver_users = supabase.table('app_users').select('id, email, full_name').eq('user_type', 'driver').execute()
        
        if driver_users.data:
            print(f"📊 Total de app_users tipo 'driver': {len(driver_users.data)}")
            
            for user in driver_users.data:
                user_id = user['id']
                
                # Verificar se existe driver correspondente
                driver_check = supabase.table('drivers').select('id').eq('user_id', user_id).execute()
                
                if driver_check.data:
                    print(f"   ✅ User {user_id[:8]}... ({user['email']}) -> Driver existe")
                else:
                    print(f"   ❌ User {user_id[:8]}... ({user['email']}) -> SEM DRIVER")
                    
    except Exception as e:
        print(f"❌ Erro: {e}")
    
    print("\n" + "=" * 70)

if __name__ == "__main__":
    main()