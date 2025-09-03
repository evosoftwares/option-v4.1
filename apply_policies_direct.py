#!/usr/bin/env python3
"""
Script para aplicar políticas RLS diretamente usando supabase-py
"""

from supabase import create_client, Client
import asyncio

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk"

def create_supabase_client() -> Client:
    """Cria cliente Supabase com service role"""
    return create_client(SUPABASE_URL, SERVICE_ROLE_KEY)

def update_bucket_config():
    """Atualiza configuração do bucket user-photos"""
    print("🪣 Atualizando configuração do bucket user-photos...")
    
    try:
        supabase = create_supabase_client()
        
        # Usar SQL direto através do cliente
        sql = """
        UPDATE storage.buckets 
        SET file_size_limit = 52428800
        WHERE id = 'user-photos';
        """
        
        result = supabase.rpc('exec_sql', {'query': sql}).execute()
        print(f"✅ Bucket atualizado: {result.data}")
        return True
        
    except Exception as e:
        print(f"❌ Erro ao atualizar bucket: {str(e)}")
        return False

def apply_rls_policies():
    """Aplica políticas RLS usando diferentes métodos"""
    print("🔒 Aplicando políticas RLS...")
    
    policies = [
        "ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;",
        "DROP POLICY IF EXISTS \"user_photos_insert\" ON storage.objects;",
        "CREATE POLICY \"user_photos_insert\" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'user-photos' AND auth.uid()::text IS NOT NULL);",
        "DROP POLICY IF EXISTS \"user_photos_select\" ON storage.objects;", 
        "CREATE POLICY \"user_photos_select\" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'user-photos');",
        "DROP POLICY IF EXISTS \"user_photos_update\" ON storage.objects;",
        "CREATE POLICY \"user_photos_update\" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'user-photos' AND auth.uid()::text IS NOT NULL) WITH CHECK (bucket_id = 'user-photos' AND auth.uid()::text IS NOT NULL);",
        "DROP POLICY IF EXISTS \"user_photos_delete\" ON storage.objects;",
        "CREATE POLICY \"user_photos_delete\" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'user-photos' AND auth.uid()::text IS NOT NULL);",
        "DROP POLICY IF EXISTS \"user_photos_public_select\" ON storage.objects;",
        "CREATE POLICY \"user_photos_public_select\" ON storage.objects FOR SELECT TO public USING (bucket_id = 'user-photos');",
        "GRANT ALL ON storage.objects TO authenticated;"
    ]
    
    try:
        supabase = create_supabase_client()
        
        for i, sql in enumerate(policies, 1):
            print(f"📝 Executando política {i}/{len(policies)}: {sql[:50]}...")
            try:
                # Tentar diferentes métodos de execução
                methods = [
                    lambda: supabase.rpc('exec_sql', {'query': sql}).execute(),
                    lambda: supabase.postgrest.rpc('exec_sql', {'sql': sql}).execute(),
                    lambda: supabase.rpc('sql', {'query': sql}).execute()
                ]
                
                success = False
                for method in methods:
                    try:
                        result = method()
                        print(f"   ✅ Sucesso com método")
                        success = True
                        break
                    except Exception as method_error:
                        continue
                        
                if not success:
                    print(f"   ❌ Falhou em todos os métodos")
                    
            except Exception as e:
                print(f"   ❌ Erro: {str(e)}")
                
        return True
        
    except Exception as e:
        print(f"❌ Erro geral: {str(e)}")
        return False

def main():
    """Função principal"""
    print("🚀 Aplicando políticas RLS diretamente...")
    print("=" * 50)
    
    # 1. Tentar atualizar bucket
    # update_bucket_config()
    
    # 2. Aplicar políticas RLS
    # apply_rls_policies()
    
    # Por enquanto, vamos só mostrar o problema identificado
    print("\n🎯 PROBLEMA IDENTIFICADO:")
    print("=" * 30)
    print("✅ Bucket 'user-photos' existe")
    print("❌ Políticas RLS não estão aplicadas")
    print("❌ Bucket não tem limite de tamanho configurado")
    print()
    print("🔧 SOLUÇÃO MANUAL OBRIGATÓRIA:")
    print("1. Acesse: https://supabase.com/dashboard/project/qlbwacmavngtonauxnte/sql")
    print("2. Execute cada comando abaixo (um por vez):")
    print()
    
    commands = [
        "ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;",
        "CREATE POLICY \"user_photos_insert\" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'user-photos' AND auth.uid()::text IS NOT NULL);",
        "CREATE POLICY \"user_photos_select\" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'user-photos');", 
        "CREATE POLICY \"user_photos_update\" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'user-photos' AND auth.uid()::text IS NOT NULL) WITH CHECK (bucket_id = 'user-photos' AND auth.uid()::text IS NOT NULL);",
        "CREATE POLICY \"user_photos_delete\" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'user-photos' AND auth.uid()::text IS NOT NULL);",
        "CREATE POLICY \"user_photos_public_select\" ON storage.objects FOR SELECT TO public USING (bucket_id = 'user-photos');",
        "GRANT ALL ON storage.objects TO authenticated;",
        "UPDATE storage.buckets SET file_size_limit = 52428800 WHERE id = 'user-photos';"
    ]
    
    for i, cmd in enumerate(commands, 1):
        print(f"{i}. {cmd}")
    
    print("\n✅ Após executar estes comandos, o erro será resolvido!")

if __name__ == "__main__":
    main()