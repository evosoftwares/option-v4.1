#!/usr/bin/env python3
"""
Script para corrigir a tabela driver_excluded_zones usando SQL direto
"""

import os
import requests
from supabase import create_client, Client

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_KEY = os.getenv('SUPABASE_ANON_KEY') or "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def check_table_structure():
    """Verifica a estrutura atual da tabela usando uma consulta simples"""
    try:
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        
        # Tenta fazer uma consulta para ver quais colunas existem
        result = supabase.table('driver_excluded_zones').select('*').limit(1).execute()
        
        print("📋 Tabela driver_excluded_zones encontrada")
        print(f"📊 Registros na tabela: {len(result.data)}")
        
        if result.data:
            print("🔍 Colunas disponíveis:")
            for col in result.data[0].keys():
                print(f"  - {col}")
        
        return True
        
    except Exception as e:
        print(f"❌ Erro ao verificar tabela: {e}")
        return False

def execute_sql_direct(sql_commands):
    """Executa comandos SQL usando requisições HTTP diretas"""
    
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': 'application/json'
    }
    
    success_count = 0
    
    for i, sql in enumerate(sql_commands, 1):
        print(f"\n🔧 Executando comando {i}/{len(sql_commands)}...")
        
        # Tenta diferentes endpoints para executar SQL
        endpoints = [
            f"{SUPABASE_URL}/rest/v1/rpc/execute_migration_rollback",
            f"{SUPABASE_URL}/rest/v1/rpc/exec_sql"
        ]
        
        executed = False
        
        for endpoint in endpoints:
            try:
                payload = {'sql': sql} if 'execute_migration' in endpoint else {'query': sql}
                
                response = requests.post(endpoint, headers=headers, json=payload)
                
                if response.status_code == 200:
                    print(f"✅ Comando executado com sucesso via {endpoint.split('/')[-1]}")
                    success_count += 1
                    executed = True
                    break
                else:
                    print(f"⚠️ Falha em {endpoint.split('/')[-1]}: {response.status_code}")
                    
            except Exception as e:
                print(f"⚠️ Erro em {endpoint.split('/')[-1]}: {e}")
        
        if not executed:
            print(f"❌ Não foi possível executar o comando {i}")
            print(f"SQL: {sql[:100]}...")
    
    return success_count

def add_columns_via_migration():
    """Adiciona colunas usando uma abordagem de migração"""
    
    sql_commands = [
        # Adicionar coluna keyword
        "ALTER TABLE public.driver_excluded_zones ADD COLUMN IF NOT EXISTS keyword text;",
        
        # Adicionar coluna zone_type
        "ALTER TABLE public.driver_excluded_zones ADD COLUMN IF NOT EXISTS zone_type text;",
        
        # Adicionar coluna reason
        "ALTER TABLE public.driver_excluded_zones ADD COLUMN IF NOT EXISTS reason text;",
        
        # Adicionar constraint para zone_type
        "ALTER TABLE public.driver_excluded_zones ADD CONSTRAINT IF NOT EXISTS check_zone_type CHECK (zone_type IN ('rua', 'bairro', 'cidade', 'estado', 'regiao'));",
        
        # Migrar dados existentes
        "UPDATE public.driver_excluded_zones SET keyword = neighborhood_name, zone_type = 'bairro' WHERE keyword IS NULL;"
    ]
    
    print("🔧 Tentando adicionar colunas via migração...")
    success_count = execute_sql_direct(sql_commands)
    
    print(f"\n📊 Resultado: {success_count}/{len(sql_commands)} comandos executados")
    
    return success_count > 0

def recreate_table_if_needed():
    """Recria a tabela com a estrutura correta se necessário"""
    
    print("🔄 Tentando recriar a tabela com estrutura completa...")
    
    # Primeiro, vamos tentar fazer backup dos dados existentes
    try:
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        
        # Busca dados existentes
        existing_data = supabase.table('driver_excluded_zones').select('*').execute()
        
        print(f"📦 Backup de {len(existing_data.data)} registros existentes")
        
        # Se há dados, vamos tentar uma abordagem mais cuidadosa
        if existing_data.data:
            print("⚠️ Existem dados na tabela. Tentando adicionar colunas sem recriar...")
            
            # Tenta inserir um registro de teste para ver quais colunas faltam
            drivers = supabase.table('drivers').select('id').limit(1).execute()
            
            if drivers.data:
                driver_id = drivers.data[0]['id']
                
                # Testa inserção com colunas básicas
                try:
                    test_basic = {
                        'driver_id': driver_id,
                        'neighborhood_name': 'Teste',
                        'city': 'São Paulo',
                        'state': 'SP'
                    }
                    
                    result = supabase.table('driver_excluded_zones').insert(test_basic).execute()
                    
                    if result.data:
                        print("✅ Inserção básica funciona")
                        
                        # Remove o teste
                        supabase.table('driver_excluded_zones').delete().eq('id', result.data[0]['id']).execute()
                        
                        # Agora testa com as novas colunas
                        test_full = {
                            'driver_id': driver_id,
                            'neighborhood_name': 'Teste Full',
                            'city': 'São Paulo',
                            'state': 'SP',
                            'keyword': 'Teste',
                            'zone_type': 'bairro',
                            'reason': 'Teste completo'
                        }
                        
                        try:
                            result_full = supabase.table('driver_excluded_zones').insert(test_full).execute()
                            
                            if result_full.data:
                                print("✅ Inserção completa funciona! Tabela já está correta.")
                                supabase.table('driver_excluded_zones').delete().eq('id', result_full.data[0]['id']).execute()
                                return True
                            
                        except Exception as e:
                            print(f"❌ Inserção completa falhou: {e}")
                            print("🔧 Colunas ainda precisam ser adicionadas")
                            
                            # Aqui podemos tentar uma abordagem alternativa
                            return try_alternative_approach()
                        
                except Exception as e:
                    print(f"❌ Inserção básica falhou: {e}")
                    return False
        
        return False
        
    except Exception as e:
        print(f"❌ Erro ao verificar dados existentes: {e}")
        return False

def try_alternative_approach():
    """Tenta uma abordagem alternativa usando o endpoint de backup"""
    
    print("🔄 Tentando abordagem alternativa...")
    
    # Vamos tentar usar o endpoint que sabemos que existe
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': 'application/json'
    }
    
    # Comando para adicionar as colunas uma por vez
    alter_commands = [
        "ALTER TABLE driver_excluded_zones ADD COLUMN keyword text",
        "ALTER TABLE driver_excluded_zones ADD COLUMN zone_type text", 
        "ALTER TABLE driver_excluded_zones ADD COLUMN reason text"
    ]
    
    for cmd in alter_commands:
        try:
            # Tenta via execute_migration_rollback (que sabemos que existe)
            payload = {'sql': cmd}
            response = requests.post(
                f"{SUPABASE_URL}/rest/v1/rpc/execute_migration_rollback",
                headers=headers,
                json=payload
            )
            
            if response.status_code == 200:
                print(f"✅ Executado: {cmd}")
            else:
                print(f"⚠️ Falha em: {cmd} - {response.status_code}: {response.text}")
                
        except Exception as e:
            print(f"❌ Erro ao executar {cmd}: {e}")
    
    # Testa se funcionou
    return test_final_functionality()

def test_final_functionality():
    """Testa se a funcionalidade final está funcionando"""
    try:
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        
        # Busca um driver para teste
        drivers = supabase.table('drivers').select('id').limit(1).execute()
        
        if not drivers.data:
            print("❌ Nenhum driver encontrado para teste")
            return False
        
        driver_id = drivers.data[0]['id']
        
        # Tenta inserir uma exclusão de teste completa
        test_data = {
            'driver_id': driver_id,
            'neighborhood_name': 'Centro Teste',
            'city': 'São Paulo',
            'state': 'SP',
            'keyword': 'Centro',
            'zone_type': 'bairro',
            'reason': 'Teste final de funcionalidade'
        }
        
        result = supabase.table('driver_excluded_zones').insert(test_data).execute()
        
        if result.data:
            print(f"✅ Teste final bem-sucedido! ID: {result.data[0]['id']}")
            
            # Remove o registro de teste
            supabase.table('driver_excluded_zones').delete().eq('id', result.data[0]['id']).execute()
            print("🧹 Registro de teste removido")
            
            return True
        else:
            print("❌ Falha no teste final")
            return False
            
    except Exception as e:
        print(f"❌ Erro no teste final: {e}")
        return False

def main():
    print("🚀 Corrigindo funcionalidade de adicionar exclusões...")
    print(f"🔗 URL: {SUPABASE_URL}")
    
    # Verifica estrutura atual
    if not check_table_structure():
        print("❌ Não foi possível verificar a tabela")
        return
    
    # Tenta recriar/corrigir a tabela
    if recreate_table_if_needed():
        print("\n🎉 Funcionalidade de adicionar exclusões corrigida com sucesso!")
    else:
        print("\n⚠️ Tentando abordagem de migração...")
        
        if add_columns_via_migration():
            print("✅ Migração executada")
            
            if test_final_functionality():
                print("\n🎉 Funcionalidade corrigida via migração!")
            else:
                print("\n❌ Ainda há problemas após migração")
        else:
            print("\n❌ Não foi possível corrigir a funcionalidade")
            print("\n💡 Sugestões:")
            print("1. Verifique as permissões do usuário no Supabase")
            print("2. Execute as migrações SQL manualmente no painel do Supabase")
            print("3. Verifique se a tabela drivers existe e tem dados")

if __name__ == "__main__":
    main()