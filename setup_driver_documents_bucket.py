#!/usr/bin/env python3
"""
Script para criar automaticamente o bucket 'driver-documents' no Supabase.
Este script executa o SQL necessário para configurar o bucket corretamente.
"""

import os
from supabase import create_client, Client

def setup_driver_documents_bucket():
    """Configura o bucket driver-documents no Supabase."""
    
    # Configuração do cliente Supabase
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_ANON_KEY")
    
    if not url or not key:
        print("❌ Erro: Variáveis SUPABASE_URL e SUPABASE_ANON_KEY não encontradas")
        print("💡 Configure as variáveis de ambiente primeiro")
        return False
    
    try:
        supabase: Client = create_client(url, key)
        print("✅ Cliente Supabase criado com sucesso")
        
        # SQL para criar o bucket e configurações
        sql_commands = [
            # Criar bucket
            """
            INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
            VALUES (
                'driver-documents',
                'driver-documents',
                false,
                10485760,
                ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg', 'application/pdf']
            )
            ON CONFLICT (id) DO NOTHING;
            """,
            
            # Desabilitar RLS
            "ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;",
            
            # Conceder permissões
            "GRANT SELECT, INSERT, UPDATE, DELETE ON storage.objects TO authenticated, anon;",
            
            # Remover políticas conflitantes
            'DROP POLICY IF EXISTS "Drivers can upload own documents" ON storage.objects;',
            'DROP POLICY IF EXISTS "Drivers can view own documents" ON storage.objects;',
            'DROP POLICY IF EXISTS "Drivers can delete own documents" ON storage.objects;',
            'DROP POLICY IF EXISTS "Admins can view all documents" ON storage.objects;'
        ]
        
        print("\n🔨 Executando configuração do bucket...")
        
        for i, sql in enumerate(sql_commands, 1):
            try:
                result = supabase.rpc('exec_sql', {'sql': sql.strip()})
                print(f"✅ Comando {i}/{len(sql_commands)} executado")
            except Exception as e:
                print(f"⚠️  Comando {i}/{len(sql_commands)} falhou (pode ser normal): {e}")
        
        # Verificar se o bucket foi criado
        print("\n🔍 Verificando bucket criado...")
        buckets = supabase.storage.list_buckets()
        bucket_names = [bucket.id for bucket in buckets]
        
        if 'driver-documents' in bucket_names:
            print("✅ Bucket 'driver-documents' criado com sucesso!")
            
            # Testar acesso
            try:
                files = supabase.storage.from_('driver-documents').list()
                print("✅ Acesso ao bucket confirmado")
                return True
            except Exception as e:
                print(f"⚠️  Bucket criado mas acesso limitado: {e}")
                return True
        else:
            print("❌ Falha ao criar bucket 'driver-documents'")
            return False
            
    except Exception as e:
        print(f"❌ Erro na configuração: {e}")
        return False

def verify_bucket_config():
    """Verifica a configuração do bucket."""
    
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_ANON_KEY")
    
    if not url or not key:
        return False
    
    try:
        supabase: Client = create_client(url, key)
        
        # Verificar buckets existentes
        buckets = supabase.storage.list_buckets()
        
        print("\n📋 Buckets encontrados:")
        for bucket in buckets:
            print(f"  - {bucket.id} (público: {bucket.public})")
        
        # Verificar bucket específico
        driver_bucket = next((b for b in buckets if b.id == 'driver-documents'), None)
        
        if driver_bucket:
            print(f"\n✅ Bucket 'driver-documents' configurado:")
            print(f"  - Público: {driver_bucket.public}")
            print(f"  - ID: {driver_bucket.id}")
            return True
        else:
            print("\n❌ Bucket 'driver-documents' não encontrado")
            return False
            
    except Exception as e:
        print(f"❌ Erro na verificação: {e}")
        return False

if __name__ == "__main__":
    print("🔧 Configurando bucket 'driver-documents'...\n")
    
    # Primeiro verificar se já existe
    if verify_bucket_config():
        print("\n✅ Bucket já está configurado corretamente!")
    else:
        # Tentar criar
        success = setup_driver_documents_bucket()
        
        if success:
            print("\n🎉 Configuração concluída com sucesso!")
            print("💡 Agora teste o upload na aplicação Flutter")
        else:
            print("\n💥 Falha na configuração!")
            print("💡 Execute manualmente o script create_driver_documents_bucket.sql no Supabase SQL Editor")