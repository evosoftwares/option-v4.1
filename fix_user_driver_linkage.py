#!/usr/bin/env python3
"""
Script para corrigir inconsistências na linkagem entre app_users e drivers
"""

from supabase import create_client, Client

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def main():
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    print("🔧 Corrigindo inconsistências na linkagem entre app_users e drivers...")
    print("=" * 80)
    
    try:
        # 1. Corrigir usuário 'passenger' que tem registro de driver
        print("\n1️⃣ Corrigindo usuário 'passageiro@gmail.com' com tipo incorreto...")
        
        # Buscar o usuário problemático
        passenger_user = supabase.table('app_users').select('*').eq('email', 'passageiro@gmail.com').execute()
        
        if passenger_user.data:
            user_data = passenger_user.data[0]
            user_id = user_data['id']
            
            print(f"   Usuário encontrado: {user_data['email']} (ID: {user_id[:8]}...)")
            print(f"   Tipo atual: {user_data['user_type']}")
            
            # Verificar se tem registro de driver
            driver_check = supabase.table('drivers').select('*').eq('user_id', user_id).execute()
            
            if driver_check.data:
                print("   ✅ Tem registro de driver - corrigindo tipo para 'driver'")
                
                # Atualizar o tipo do usuário para 'driver'
                update_result = supabase.table('app_users').update({
                    'user_type': 'driver',
                    'updated_at': 'now()'
                }).eq('id', user_id).execute()
                
                if update_result.data:
                    print("   ✅ Tipo de usuário corrigido com sucesso!")
                else:
                    print("   ❌ Erro ao atualizar tipo de usuário")
            else:
                print("   ⚠️ Não tem registro de driver")
        else:
            print("   ⚠️ Usuário 'passageiro@gmail.com' não encontrado")
        
        # 2. Listar app_users órfãos do tipo 'driver' sem registro na tabela drivers
        print("\n2️⃣ Identificando app_users órfãos do tipo 'driver'...")
        
        driver_users = supabase.table('app_users').select('id, email, full_name, user_type').eq('user_type', 'driver').execute()
        
        orphan_users = []
        
        if driver_users.data:
            for user in driver_users.data:
                user_id = user['id']
                
                # Verificar se existe driver correspondente
                driver_check = supabase.table('drivers').select('id').eq('user_id', user_id).execute()
                
                if not driver_check.data:
                    orphan_users.append(user)
            
            if orphan_users:
                print(f"   📊 Encontrados {len(orphan_users)} usuários órfãos:")
                for user in orphan_users:
                    print(f"      - {user['email']} (ID: {user['id'][:8]}...)")
                
                # Opção: Corrigir tipo para 'passenger' ou criar registro de driver
                print("\n   🔧 Corrigindo tipos para 'passenger' (usuários sem registro de driver)...")
                
                for user in orphan_users:
                    try:
                        update_result = supabase.table('app_users').update({
                            'user_type': 'passenger',
                            'updated_at': 'now()'
                        }).eq('id', user['id']).execute()
                        
                        if update_result.data:
                            print(f"      ✅ {user['email']} -> tipo alterado para 'passenger'")
                        else:
                            print(f"      ❌ Erro ao alterar {user['email']}")
                    except Exception as e:
                        print(f"      ❌ Erro ao alterar {user['email']}: {e}")
            else:
                print("   ✅ Nenhum usuário órfão encontrado")
        
        # 3. Verificar se ainda há inconsistências
        print("\n3️⃣ Verificação final das linkagens...")
        
        # Verificar drivers sem app_user correspondente
        drivers_result = supabase.table('drivers').select('id, user_id').execute()
        
        if drivers_result.data:
            inconsistent_drivers = []
            
            for driver in drivers_result.data:
                user_check = supabase.table('app_users').select('id, user_type').eq('id', driver['user_id']).execute()
                
                if not user_check.data:
                    inconsistent_drivers.append(driver)
                elif user_check.data[0]['user_type'] != 'driver':
                    inconsistent_drivers.append({
                        **driver,
                        'user_type': user_check.data[0]['user_type']
                    })
            
            if inconsistent_drivers:
                print(f"   ⚠️ Ainda há {len(inconsistent_drivers)} inconsistências:")
                for driver in inconsistent_drivers:
                    if 'user_type' in driver:
                        print(f"      - Driver {driver['id'][:8]}... -> User tipo '{driver['user_type']}'")
                    else:
                        print(f"      - Driver {driver['id'][:8]}... -> User não encontrado")
            else:
                print("   ✅ Todas as linkagens estão consistentes!")
        
        print("\n" + "=" * 80)
        print("🎉 Correção de linkagens concluída!")
        
    except Exception as e:
        print(f"❌ Erro durante a correção: {e}")

if __name__ == "__main__":
    main()