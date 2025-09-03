#!/usr/bin/env python3
"""
Script para aplicar políticas RLS via API do Supabase
Alternativa para quando não é possível executar SQL diretamente no Dashboard
"""

import os
import requests
import json
from dotenv import load_dotenv

# Carregar variáveis de ambiente
load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

if not all([SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY]):
    print("❌ Erro: Variáveis SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórias")
    print("💡 Adicione SUPABASE_SERVICE_ROLE_KEY no arquivo .env")
    exit(1)

def execute_sql(query, description):
    """Executa uma query SQL via API do Supabase"""
    print(f"🔧 {description}...")
    
    headers = {
        'Authorization': f'Bearer {SUPABASE_SERVICE_ROLE_KEY}',
        'apikey': SUPABASE_SERVICE_ROLE_KEY,
        'Content-Type': 'application/json'
    }
    
    try:
        response = requests.post(
            f'{SUPABASE_URL}/rest/v1/rpc/exec_sql',
            headers=headers,
            json={'query': query}
        )
        
        if response.status_code in [200, 201, 204]:
            print(f"✅ {description} - Sucesso")
            return True
        else:
            print(f"❌ {description} - Erro: {response.status_code}")
            print(f"   Resposta: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ {description} - Erro: {str(e)}")
        return False

def apply_rls_policies():
    """Aplica todas as políticas RLS necessárias"""
    print("🚀 Aplicando políticas RLS via API...")
    print("="*50)
    
    # 1. Habilitar RLS
    success = execute_sql(
        "ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;",
        "Habilitando RLS na tabela storage.objects"
    )
    
    if not success:
        print("❌ Falha ao habilitar RLS. Abortando...")
        return False
    
    # 2. Remover políticas existentes
    policies_to_drop = [
        "Allow authenticated users to select files",
        "Allow authenticated users to insert files", 
        "Allow authenticated users to update files",
        "Allow authenticated users to delete files"
    ]
    
    for policy in policies_to_drop:
        execute_sql(
            f'DROP POLICY IF EXISTS "{policy}" ON storage.objects;',
            f"Removendo política: {policy}"
        )
    
    # 3. Criar política SELECT
    success = execute_sql(
        '''
        CREATE POLICY "Allow authenticated users to select files"
        ON storage.objects
        FOR SELECT
        TO authenticated
        USING (bucket_id = 'user-photos');
        ''',
        "Criando política SELECT"
    )
    
    if not success:
        return False
    
    # 4. Criar política INSERT
    success = execute_sql(
        '''
        CREATE POLICY "Allow authenticated users to insert files"
        ON storage.objects
        FOR INSERT
        TO authenticated
        WITH CHECK (bucket_id = 'user-photos');
        ''',
        "Criando política INSERT"
    )
    
    if not success:
        return False
    
    # 5. Criar política UPDATE (ESSENCIAL para upsert)
    success = execute_sql(
        '''
        CREATE POLICY "Allow authenticated users to update files"
        ON storage.objects
        FOR UPDATE
        TO authenticated
        USING (bucket_id = 'user-photos')
        WITH CHECK (bucket_id = 'user-photos');
        ''',
        "Criando política UPDATE (essencial para upsert)"
    )
    
    if not success:
        return False
    
    # 6. Criar política DELETE
    success = execute_sql(
        '''
        CREATE POLICY "Allow authenticated users to delete files"
        ON storage.objects
        FOR DELETE
        TO authenticated
        USING (bucket_id = 'user-photos');
        ''',
        "Criando política DELETE"
    )
    
    if not success:
        return False
    
    return True

def verify_policies():
    """Verifica se as políticas foram criadas corretamente"""
    print("\n🔍 Verificando políticas criadas...")
    
    headers = {
        'Authorization': f'Bearer {SUPABASE_SERVICE_ROLE_KEY}',
        'apikey': SUPABASE_SERVICE_ROLE_KEY,
        'Content-Type': 'application/json'
    }
    
    query = """
    SELECT policyname, cmd 
    FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects'
    ORDER BY policyname;
    """
    
    try:
        response = requests.post(
            f'{SUPABASE_URL}/rest/v1/rpc/exec_sql',
            headers=headers,
            json={'query': query}
        )
        
        if response.status_code == 200:
            policies = response.json()
            if policies:
                print(f"✅ Políticas encontradas: {len(policies)}")
                for policy in policies:
                    print(f"  - {policy.get('policyname', 'N/A')} ({policy.get('cmd', 'N/A')})")
                return len(policies) >= 4
            else:
                print("❌ Nenhuma política encontrada")
                return False
        else:
            print(f"❌ Erro ao verificar políticas: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Erro ao verificar políticas: {str(e)}")
        return False

def main():
    print("🔐 Aplicando Políticas RLS via API do Supabase")
    print(f"📍 URL: {SUPABASE_URL}")
    print("="*50)
    
    # Aplicar políticas RLS
    if apply_rls_policies():
        print("\n✅ Todas as políticas RLS foram aplicadas com sucesso!")
        
        # Verificar políticas
        if verify_policies():
            print("\n🎉 Configuração RLS completa!")
            print("📝 Próximo passo: Testar upload de documentos no app Flutter")
        else:
            print("\n⚠️  Políticas aplicadas, mas verificação falhou")
    else:
        print("\n❌ Falha ao aplicar políticas RLS")
        print("💡 Verifique se SUPABASE_SERVICE_ROLE_KEY está correto")

if __name__ == '__main__':
    main()