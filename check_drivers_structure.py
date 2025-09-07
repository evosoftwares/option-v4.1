#!/usr/bin/env python3
"""
Script para verificar a estrutura real da tabela drivers
"""

from supabase import create_client, Client

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def main():
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    print("🔍 Verificando estrutura da tabela drivers...")
    print("=" * 60)
    
    # Pegar um registro para ver todos os campos disponíveis
    try:
        result = supabase.table('drivers').select('*').limit(1).execute()
        
        if result.data:
            driver = result.data[0]
            print("📋 CAMPOS DISPONÍVEIS NA TABELA DRIVERS:")
            print("-" * 40)
            for key, value in driver.items():
                print(f"   {key}: {value}")
        else:
            print("⚠️ Nenhum motorista encontrado")
            
    except Exception as e:
        print(f"❌ Erro: {e}")
    
    print("\n" + "=" * 60)

if __name__ == "__main__":
    main()