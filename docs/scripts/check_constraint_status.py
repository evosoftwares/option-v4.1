#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para verificar o status atual da constraint driver_documents
Diagnostica por que o erro persiste após a correção
"""

import os
from supabase import create_client, Client
from dotenv import load_dotenv

# Carrega variáveis do arquivo .env
load_dotenv('.claude/.env')

# Configurações do Supabase
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
    print("❌ Erro: Variáveis de ambiente SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY não encontradas no arquivo .claude/.env")
    print("Verifique se o arquivo .claude/.env contém as credenciais corretas")
    exit(1)

print(f"✅ Conectando ao Supabase: {SUPABASE_URL}")
print(f"✅ Usando Service Role Key: {SUPABASE_SERVICE_ROLE_KEY[:20]}...")

def check_constraint_status():
    """
    Verifica o status atual das constraints na tabela driver_documents
    """
    
    print("🔍 Verificando status das constraints...")
    
    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        print("❌ Erro: Configure SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY")
        return False
    
    try:
        # Conectar com privilégios de service_role
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
        print("✅ Conectado ao Supabase")
        
        # 1. Verificar dados atuais na tabela
        print("\n📊 1. Análise dos dados atuais:")
        try:
            result = supabase.table('driver_documents').select('document_type').execute()
            if result.data:
                # Contar tipos de documento
                type_counts = {}
                for row in result.data:
                    doc_type = row.get('document_type')
                    type_counts[doc_type] = type_counts.get(doc_type, 0) + 1
                
                print("   Tipos de documento encontrados:")
                for doc_type, count in type_counts.items():
                    print(f"   - {doc_type}: {count} registros")
                    
                # Verificar dados inválidos
                valid_types = {
                    'CNH_FRONT', 'CNH_BACK', 'CRLV', 
                    'VEHICLE_FRONT', 'VEHICLE_BACK', 
                    'VEHICLE_LEFT', 'VEHICLE_RIGHT', 'VEHICLE_INTERIOR'
                }
                
                invalid_types = set(type_counts.keys()) - valid_types
                if invalid_types:
                    print(f"\n⚠️  Tipos inválidos encontrados: {invalid_types}")
                else:
                    print("\n✅ Todos os tipos são válidos")
            else:
                print("   Nenhum dado encontrado na tabela")
        except Exception as e:
            print(f"   ❌ Erro ao consultar dados: {e}")
        
        # 2. Testar inserção válida
        print("\n🧪 2. Teste de inserção válida:")
        try:
            test_data = {
                'driver_id': 'test-driver-verification',
                'document_type': 'CNH_FRONT',
                'file_url': 'https://test-url.com/test.jpg',
                'status': 'PENDING'
            }
            
            result = supabase.table('driver_documents').insert(test_data).execute()
            print("   ✅ Inserção válida: SUCESSO")
            
            # Limpar teste
            supabase.table('driver_documents').delete().eq('driver_id', 'test-driver-verification').execute()
            
        except Exception as e:
            print(f"   ❌ Inserção válida FALHOU: {e}")
        
        # 3. Testar inserção inválida
        print("\n🧪 3. Teste de inserção inválida:")
        try:
            test_data = {
                'driver_id': 'test-driver-invalid',
                'document_type': 'INVALID_TYPE',
                'file_url': 'https://test-url.com/test.jpg',
                'status': 'PENDING'
            }
            
            result = supabase.table('driver_documents').insert(test_data).execute()
            print("   ⚠️  Inserção inválida: PERMITIDA (constraint não está funcionando!)")
            
            # Limpar teste
            supabase.table('driver_documents').delete().eq('driver_id', 'test-driver-invalid').execute()
            
        except Exception as e:
            print(f"   ✅ Inserção inválida BLOQUEADA: {e}")
            if "check constraint" in str(e).lower():
                print("   🎉 Constraint está funcionando corretamente!")
        
        # 4. Verificar se há dados problemáticos específicos
        print("\n🔍 4. Verificando registros recentes:")
        try:
            result = supabase.table('driver_documents').select('*').order('created_at', desc=True).limit(5).execute()
            if result.data:
                print("   Últimos 5 registros:")
                for row in result.data:
                    print(f"   - ID: {row.get('id')}, Tipo: {row.get('document_type')}, Driver: {row.get('driver_id')}")
            else:
                print("   Nenhum registro encontrado")
        except Exception as e:
            print(f"   ❌ Erro ao consultar registros recentes: {e}")
        
        return True
        
    except Exception as e:
        print(f"❌ Erro ao verificar constraints: {e}")
        return False

def fix_constraint_direct():
    """
    Tenta corrigir a constraint diretamente usando SQL simples
    """
    print("\n🔧 Tentando correção direta da constraint...")
    
    try:
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
        
        # Primeiro, tentar remover constraint antiga
        print("   1. Removendo constraint antiga...")
        try:
            # Usar SQL direto via REST API
            response = supabase.postgrest.rpc('exec_sql', {
                'sql': 'ALTER TABLE public.driver_documents DROP CONSTRAINT IF EXISTS driver_documents_document_type_check;'
            }).execute()
            print("   ✅ Constraint antiga removida")
        except Exception as e:
            print(f"   ⚠️  Aviso ao remover constraint: {e}")
        
        # Corrigir dados inválidos
        print("   2. Corrigindo dados inválidos...")
        try:
            # Buscar registros com tipos inválidos
            result = supabase.table('driver_documents').select('id, document_type').execute()
            
            valid_types = {
                'CNH_FRONT', 'CNH_BACK', 'CRLV', 
                'VEHICLE_FRONT', 'VEHICLE_BACK', 
                'VEHICLE_LEFT', 'VEHICLE_RIGHT', 'VEHICLE_INTERIOR'
            }
            
            fixed_count = 0
            for row in result.data:
                if row['document_type'] not in valid_types:
                    # Corrigir para CNH_FRONT
                    supabase.table('driver_documents').update({
                        'document_type': 'CNH_FRONT'
                    }).eq('id', row['id']).execute()
                    fixed_count += 1
            
            print(f"   ✅ {fixed_count} registros corrigidos")
            
        except Exception as e:
            print(f"   ❌ Erro ao corrigir dados: {e}")
        
        # Criar nova constraint
        print("   3. Criando nova constraint...")
        try:
            response = supabase.postgrest.rpc('exec_sql', {
                'sql': '''ALTER TABLE public.driver_documents 
                         ADD CONSTRAINT driver_documents_document_type_simple 
                         CHECK (document_type IN (
                             'CNH_FRONT', 'CNH_BACK', 'CRLV', 
                             'VEHICLE_FRONT', 'VEHICLE_BACK', 
                             'VEHICLE_LEFT', 'VEHICLE_RIGHT', 'VEHICLE_INTERIOR'
                         ));'''
            }).execute()
            print("   ✅ Nova constraint criada")
        except Exception as e:
            print(f"   ❌ Erro ao criar constraint: {e}")
        
        return True
        
    except Exception as e:
        print(f"❌ Erro na correção direta: {e}")
        return False

if __name__ == "__main__":
    print("🔍 Diagnóstico - Status da Constraint Driver Documents")
    print("=" * 60)
    
    if check_constraint_status():
        print("\n🔧 Tentando correção automática...")
        fix_constraint_direct()
        
        print("\n🔍 Verificação pós-correção:")
        check_constraint_status()
    
    print("\n" + "=" * 60)
    print("✨ Diagnóstico finalizado")
    print("\n💡 Se o problema persistir:")
    print("   1. Execute o script fix_driver_documents_admin.sql no Supabase Dashboard")
    print("   2. Verifique se há triggers ou policies interferindo")
    print("   3. Confirme se você está usando a service_role_key correta")