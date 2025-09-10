#!/usr/bin/env python3
"""
Teste básico da funcionalidade de exclusões usando apenas colunas existentes
"""

import os
from supabase import create_client, Client

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_KEY = os.getenv('SUPABASE_ANON_KEY') or "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def test_basic_exclusion_functionality():
    """Testa a funcionalidade básica de exclusões"""
    try:
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        
        print("🔍 Verificando se existem drivers...")
        
        # Busca um driver para teste
        drivers = supabase.table('drivers').select('id').limit(1).execute()
        
        if not drivers.data:
            print("❌ Nenhum driver encontrado para teste")
            return False
        
        driver_id = drivers.data[0]['id']
        print(f"✅ Driver encontrado: {driver_id}")
        
        print("\n🧪 Testando inserção com colunas básicas...")
        
        # Tenta inserir uma exclusão usando apenas colunas básicas
        test_data = {
            'driver_id': driver_id,
            'neighborhood_name': 'Centro Teste',
            'city': 'São Paulo',
            'state': 'SP'
        }
        
        result = supabase.table('driver_excluded_zones').insert(test_data).execute()
        
        if result.data:
            exclusion_id = result.data[0]['id']
            print(f"✅ Inserção bem-sucedida! ID: {exclusion_id}")
            
            print("\n🔍 Verificando se a exclusão foi salva...")
            
            # Verifica se a exclusão foi salva
            saved_exclusion = supabase.table('driver_excluded_zones').select('*').eq('id', exclusion_id).execute()
            
            if saved_exclusion.data:
                exclusion = saved_exclusion.data[0]
                print(f"✅ Exclusão encontrada:")
                print(f"   - ID: {exclusion['id']}")
                print(f"   - Driver ID: {exclusion['driver_id']}")
                print(f"   - Bairro: {exclusion['neighborhood_name']}")
                print(f"   - Cidade: {exclusion['city']}")
                print(f"   - Estado: {exclusion['state']}")
                print(f"   - Criado em: {exclusion['created_at']}")
                
                print("\n🔍 Testando busca por driver...")
                
                # Testa busca por driver
                driver_exclusions = supabase.table('driver_excluded_zones').select('*').eq('driver_id', driver_id).execute()
                
                print(f"✅ Encontradas {len(driver_exclusions.data)} exclusões para o driver")
                
                print("\n🧹 Removendo exclusão de teste...")
                
                # Remove o registro de teste
                supabase.table('driver_excluded_zones').delete().eq('id', exclusion_id).execute()
                print("✅ Exclusão de teste removida")
                
                return True
            else:
                print("❌ Exclusão não foi encontrada após inserção")
                return False
        else:
            print("❌ Falha na inserção")
            return False
            
    except Exception as e:
        print(f"❌ Erro no teste: {e}")
        return False

def check_table_structure():
    """Verifica a estrutura da tabela"""
    try:
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        
        print("🔍 Verificando estrutura da tabela...")
        
        # Faz uma consulta simples para ver a estrutura
        result = supabase.table('driver_excluded_zones').select('*').limit(1).execute()
        
        print(f"✅ Tabela acessível. Registros: {len(result.data)}")
        
        if result.data:
            print("📋 Colunas disponíveis:")
            for col in result.data[0].keys():
                print(f"   - {col}")
        else:
            print("📋 Tabela vazia, mas estrutura acessível")
        
        return True
        
    except Exception as e:
        print(f"❌ Erro ao verificar estrutura: {e}")
        return False

def main():
    print("🚀 Testando funcionalidade básica de exclusões...")
    print(f"🔗 URL: {SUPABASE_URL}")
    
    # Verifica estrutura
    if not check_table_structure():
        print("❌ Não foi possível verificar a estrutura da tabela")
        return
    
    print("\n" + "="*50)
    
    # Testa funcionalidade
    if test_basic_exclusion_functionality():
        print("\n🎉 Funcionalidade de adicionar exclusões está funcionando!")
        print("\n✅ RESUMO:")
        print("   - Tabela driver_excluded_zones existe")
        print("   - Inserção de exclusões funciona")
        print("   - Busca por driver funciona")
        print("   - Remoção de exclusões funciona")
        print("\n💡 A funcionalidade básica está operacional.")
        print("   O app pode adicionar exclusões usando as colunas básicas:")
        print("   - driver_id, neighborhood_name, city, state")
    else:
        print("\n❌ Ainda há problemas na funcionalidade")
        print("\n🔧 Possíveis soluções:")
        print("   1. Verificar permissões RLS no Supabase")
        print("   2. Verificar se a tabela drivers existe")
        print("   3. Verificar conectividade com o banco")

if __name__ == "__main__":
    main()