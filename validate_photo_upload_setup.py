#!/usr/bin/env python3
# =============================================
# VALIDAÇÃO: CONFIGURAÇÃO UPLOAD DE FOTO
# =============================================
# Script para validar se a configuração está correta
# para upload de fotos de perfil no Supabase
# =============================================

import os
import sys
from supabase import create_client, Client
from datetime import datetime

# Configurações do Supabase (ajuste conforme necessário)
SUPABASE_URL = "https://your-project.supabase.co"  # Substitua pela sua URL
SUPABASE_ANON_KEY = "your-anon-key"  # Substitua pela sua chave

def create_supabase_client() -> Client:
    """Cria cliente Supabase"""
    try:
        return create_client(SUPABASE_URL, SUPABASE_ANON_KEY)
    except Exception as e:
        print(f"❌ Erro ao conectar com Supabase: {e}")
        sys.exit(1)

def check_bucket_exists(supabase: Client, bucket_name: str) -> bool:
    """Verifica se o bucket existe"""
    try:
        buckets = supabase.storage.list_buckets()
        bucket_names = [bucket.name for bucket in buckets]
        
        if bucket_name in bucket_names:
            print(f"✅ Bucket '{bucket_name}' encontrado")
            return True
        else:
            print(f"❌ Bucket '{bucket_name}' NÃO encontrado")
            print(f"   Buckets disponíveis: {bucket_names}")
            return False
            
    except Exception as e:
        print(f"❌ Erro ao verificar buckets: {e}")
        return False

def check_bucket_public(supabase: Client, bucket_name: str) -> bool:
    """Verifica se o bucket é público"""
    try:
        bucket = supabase.storage.get_bucket(bucket_name)
        if bucket.public:
            print(f"✅ Bucket '{bucket_name}' é público")
            return True
        else:
            print(f"❌ Bucket '{bucket_name}' NÃO é público")
            return False
            
    except Exception as e:
        print(f"❌ Erro ao verificar se bucket é público: {e}")
        return False

def check_table_structure(supabase: Client) -> bool:
    """Verifica estrutura da tabela app_users"""
    try:
        # Verificar se a coluna photo_url existe
        result = supabase.rpc('check_column_exists', {
            'table_name': 'app_users',
            'column_name': 'photo_url'
        }).execute()
        
        if result.data:
            print("✅ Coluna 'photo_url' existe na tabela 'app_users'")
            return True
        else:
            print("❌ Coluna 'photo_url' NÃO existe na tabela 'app_users'")
            return False
            
    except Exception as e:
        # Fallback: tentar fazer uma query simples
        try:
            result = supabase.table('app_users').select('photo_url').limit(1).execute()
            print("✅ Coluna 'photo_url' existe na tabela 'app_users'")
            return True
        except Exception as e2:
            print(f"❌ Erro ao verificar coluna photo_url: {e2}")
            return False

def check_rls_status(supabase: Client) -> bool:
    """Verifica status do RLS na tabela app_users"""
    try:
        # Tentar fazer um SELECT simples
        result = supabase.table('app_users').select('id').limit(1).execute()
        print("✅ Acesso à tabela 'app_users' permitido (RLS desabilitado ou permissões corretas)")
        return True
        
    except Exception as e:
        print(f"❌ Erro ao acessar tabela 'app_users': {e}")
        print("   Possível problema: RLS habilitado sem permissões adequadas")
        return False

def test_upload_simulation(supabase: Client, bucket_name: str) -> bool:
    """Simula um upload de arquivo"""
    try:
        # Criar um arquivo de teste temporário
        test_content = f"Test upload at {datetime.now()}"
        test_filename = f"test_upload_{int(datetime.now().timestamp())}.txt"
        
        # Tentar fazer upload
        result = supabase.storage.from_(bucket_name).upload(
            test_filename,
            test_content.encode('utf-8'),
            file_options={"content-type": "text/plain"}
        )
        
        if result:
            print(f"✅ Upload de teste realizado com sucesso: {test_filename}")
            
            # Tentar obter URL pública
            public_url = supabase.storage.from_(bucket_name).get_public_url(test_filename)
            print(f"✅ URL pública gerada: {public_url}")
            
            # Limpar arquivo de teste
            try:
                supabase.storage.from_(bucket_name).remove([test_filename])
                print(f"✅ Arquivo de teste removido")
            except:
                print(f"⚠️ Não foi possível remover arquivo de teste: {test_filename}")
            
            return True
        else:
            print("❌ Falha no upload de teste")
            return False
            
    except Exception as e:
        print(f"❌ Erro no teste de upload: {e}")
        return False

def test_update_simulation(supabase: Client) -> bool:
    """Simula uma atualização na tabela app_users"""
    try:
        # Tentar fazer um UPDATE simples (sem WHERE para não afetar dados reais)
        # Apenas testamos se a operação é permitida
        test_url = f"https://example.com/test_{int(datetime.now().timestamp())}.jpg"
        
        # Fazer um SELECT primeiro para ver se há dados
        result = supabase.table('app_users').select('id').limit(1).execute()
        
        if result.data and len(result.data) > 0:
            user_id = result.data[0]['id']
            
            # Tentar atualizar (mas reverter imediatamente)
            original = supabase.table('app_users').select('photo_url').eq('id', user_id).single().execute()
            original_url = original.data.get('photo_url') if original.data else None
            
            # Fazer update de teste
            update_result = supabase.table('app_users').update({
                'photo_url': test_url
            }).eq('id', user_id).execute()
            
            if update_result:
                print("✅ UPDATE na tabela 'app_users' permitido")
                
                # Reverter para valor original
                supabase.table('app_users').update({
                    'photo_url': original_url
                }).eq('id', user_id).execute()
                
                return True
            else:
                print("❌ UPDATE na tabela 'app_users' falhou")
                return False
        else:
            print("⚠️ Nenhum usuário encontrado para testar UPDATE")
            return True  # Não é um erro crítico
            
    except Exception as e:
        print(f"❌ Erro no teste de UPDATE: {e}")
        return False

def main():
    """Função principal de validação"""
    print("🔍 VALIDAÇÃO: CONFIGURAÇÃO UPLOAD DE FOTO")
    print("=" * 50)
    
    # Verificar variáveis de ambiente
    if SUPABASE_URL == "https://your-project.supabase.co":
        print("⚠️ ATENÇÃO: Configure SUPABASE_URL no script")
        print("   Você pode encontrar a URL no Dashboard do Supabase > Settings > API")
    
    if SUPABASE_ANON_KEY == "your-anon-key":
        print("⚠️ ATENÇÃO: Configure SUPABASE_ANON_KEY no script")
        print("   Você pode encontrar a chave no Dashboard do Supabase > Settings > API")
        return
    
    # Criar cliente
    supabase = create_supabase_client()
    
    bucket_name = 'user-photos'
    all_checks_passed = True
    
    print(f"\n📋 Verificando configuração para bucket: {bucket_name}")
    print("-" * 50)
    
    # 1. Verificar se bucket existe
    if not check_bucket_exists(supabase, bucket_name):
        all_checks_passed = False
    
    # 2. Verificar se bucket é público
    if not check_bucket_public(supabase, bucket_name):
        all_checks_passed = False
    
    # 3. Verificar estrutura da tabela
    if not check_table_structure(supabase):
        all_checks_passed = False
    
    # 4. Verificar status do RLS
    if not check_rls_status(supabase):
        all_checks_passed = False
    
    # 5. Testar upload
    if not test_upload_simulation(supabase, bucket_name):
        all_checks_passed = False
    
    # 6. Testar update
    if not test_update_simulation(supabase):
        all_checks_passed = False
    
    print("\n" + "=" * 50)
    if all_checks_passed:
        print("🎉 TODAS AS VERIFICAÇÕES PASSARAM!")
        print("✅ Configuração está correta para upload de fotos")
        print("\n📱 Próximos passos:")
        print("   1. Adicionar dependências no pubspec.yaml:")
        print("      - image_picker: ^1.0.4")
        print("   2. Configurar permissões de câmera/galeria")
        print("   3. Testar na aplicação Flutter")
    else:
        print("❌ ALGUMAS VERIFICAÇÕES FALHARAM")
        print("\n🔧 Ações necessárias:")
        print("   1. Execute o script SQL: setup_user_photos_bucket_no_rls.sql")
        print("   2. Execute o script SQL: setup_app_users_no_rls.sql")
        print("   3. Verifique as configurações no Supabase Dashboard")
        print("   4. Execute este script novamente")

if __name__ == "__main__":
    main()

# =============================================
# INSTRUÇÕES DE USO
# =============================================
"""
📋 COMO USAR ESTE SCRIPT:

1. Instalar dependências:
   pip install supabase

2. Configurar variáveis:
   - Edite SUPABASE_URL com sua URL do projeto
   - Edite SUPABASE_ANON_KEY com sua chave anônima

3. Executar:
   python validate_photo_upload_setup.py

4. Analisar resultados:
   - ✅ = Configuração correta
   - ❌ = Problema encontrado
   - ⚠️ = Atenção necessária

5. Corrigir problemas:
   - Execute os scripts SQL mencionados
   - Verifique configurações no Supabase Dashboard
   - Execute novamente até todas as verificações passarem
"""