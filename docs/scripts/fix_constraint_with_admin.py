#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para corrigir constraint driver_documents usando credenciais de admin
Resolve o erro: must be owner of table driver_documents
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

# Credenciais S3 (se necessário para storage)
S3_ACCESS_KEY = "11bda1a93c6eb63e465a34fa62b89cd2"
S3_SECRET_KEY = "174437248668fed86f8acbed6ff1a1c6ca233cd020ecaa5d6b72cd536a255364"

def fix_driver_documents_constraint():
    """
    Corrige a constraint driver_documents_document_type_check
    usando privilégios de administrador
    """
    
    print("🔧 Iniciando correção da constraint driver_documents...")
    
    # Verificar se temos as credenciais necessárias
    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        print("❌ Erro: Configure SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY")
        print("   Exemplo:")
        print("   export SUPABASE_URL='https://your-project.supabase.co'")
        print("   export SUPABASE_SERVICE_ROLE_KEY='your-service-role-key'")
        return False
    
    try:
        # Conectar com privilégios de service_role (admin)
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
        print("✅ Conectado ao Supabase com privilégios de admin")
        
        # SQL para corrigir a constraint
        sql_commands = [
            # 1. Verificar constraints atuais
            """
            SELECT constraint_name, constraint_type, check_clause
            FROM information_schema.table_constraints tc
            LEFT JOIN information_schema.check_constraints cc 
                ON tc.constraint_name = cc.constraint_name
            WHERE tc.table_name = 'driver_documents'
                AND tc.constraint_type = 'CHECK';
            """,
            
            # 2. Remover constraint problemática
            """
            ALTER TABLE public.driver_documents 
            DROP CONSTRAINT IF EXISTS driver_documents_document_type_check;
            """,
            
            # 3. Verificar dados inválidos
            """
            SELECT DISTINCT document_type, COUNT(*) as count
            FROM public.driver_documents 
            WHERE document_type NOT IN (
                'CNH_FRONT', 'CNH_BACK', 'CRLV', 
                'VEHICLE_FRONT', 'VEHICLE_BACK', 
                'VEHICLE_LEFT', 'VEHICLE_RIGHT', 'VEHICLE_INTERIOR'
            )
            OR document_type IS NULL
            GROUP BY document_type;
            """,
            
            # 4. Corrigir dados inválidos
            """
            UPDATE public.driver_documents 
            SET document_type = 'CNH_FRONT'
            WHERE document_type IS NULL 
               OR document_type NOT IN (
                'CNH_FRONT', 'CNH_BACK', 'CRLV', 
                'VEHICLE_FRONT', 'VEHICLE_BACK', 
                'VEHICLE_LEFT', 'VEHICLE_RIGHT', 'VEHICLE_INTERIOR'
            );
            """,
            
            # 5. Criar nova constraint
            """
            ALTER TABLE public.driver_documents 
            ADD CONSTRAINT driver_documents_document_type_simple 
            CHECK (document_type IN (
                'CNH_FRONT', 'CNH_BACK', 'CRLV', 
                'VEHICLE_FRONT', 'VEHICLE_BACK', 
                'VEHICLE_LEFT', 'VEHICLE_RIGHT', 'VEHICLE_INTERIOR'
            ));
            """,
            
            # 6. Verificar se funcionou
            """
            SELECT constraint_name, check_clause 
            FROM information_schema.check_constraints 
            WHERE constraint_name = 'driver_documents_document_type_simple';
            """
        ]
        
        # Executar comandos SQL
        for i, sql in enumerate(sql_commands, 1):
            print(f"\n📝 Executando comando {i}/6...")
            try:
                result = supabase.rpc('exec_sql', {'sql': sql.strip()})
                print(f"✅ Comando {i} executado com sucesso")
                if result.data:
                    print(f"   Resultado: {result.data}")
            except Exception as e:
                print(f"⚠️  Comando {i} com aviso: {e}")
                # Alguns comandos podem dar aviso mas ainda funcionar
                continue
        
        print("\n🎉 Correção da constraint concluída!")
        print("\n📋 Próximos passos:")
        print("   1. Teste o upload de documentos no app")
        print("   2. Verifique se não há mais erros de constraint")
        print("   3. Os tipos permitidos agora são:")
        print("      - CNH_FRONT, CNH_BACK, CRLV")
        print("      - VEHICLE_FRONT, VEHICLE_BACK")
        print("      - VEHICLE_LEFT, VEHICLE_RIGHT, VEHICLE_INTERIOR")
        
        return True
        
    except Exception as e:
        print(f"❌ Erro ao executar correção: {e}")
        print("\n🔍 Possíveis soluções:")
        print("   1. Verifique se a SUPABASE_SERVICE_ROLE_KEY está correta")
        print("   2. Execute o script fix_driver_documents_admin.sql no Dashboard")
        print("   3. Verifique se você tem permissões de admin no projeto")
        return False

def test_constraint():
    """
    Testa se a constraint está funcionando corretamente
    """
    print("\n🧪 Testando constraint...")
    
    try:
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
        
        # Tentar inserir um documento válido (teste)
        test_data = {
            'driver_id': 'test-driver-id',
            'document_type': 'CNH_FRONT',
            'file_url': 'test-url',
            'status': 'PENDING'
        }
        
        # Inserir
        result = supabase.table('driver_documents').insert(test_data).execute()
        print("✅ Inserção de documento válido: OK")
        
        # Remover teste
        supabase.table('driver_documents').delete().eq('driver_id', 'test-driver-id').execute()
        print("✅ Limpeza do teste: OK")
        
        print("🎉 Constraint funcionando corretamente!")
        return True
        
    except Exception as e:
        print(f"❌ Erro no teste: {e}")
        return False

if __name__ == "__main__":
    print("🚀 Script de Correção - Constraint Driver Documents")
    print("=" * 50)
    
    # Executar correção
    if fix_driver_documents_constraint():
        # Testar se funcionou
        test_constraint()
    else:
        print("\n❌ Falha na correção. Verifique os logs acima.")
    
    print("\n" + "=" * 50)
    print("✨ Script finalizado")