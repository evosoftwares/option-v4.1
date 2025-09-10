#!/usr/bin/env python3
"""
Script para consultar documentos pendentes de um motorista
Usando apenas o ID do usuário autenticado
"""

import os
from supabase import create_client, Client

# Configurações do Supabase (credenciais reais)
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

supabase: Client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)

try:
    print("🔍 CONSULTANDO DOCUMENTOS PENDENTES")
    print("=" * 40)
    
    # ID do usuário autenticado (deve existir na tabela auth.users)
    auth_user_id = '00c53da5-b700-4f48-b4bb-e4e74e57356c'
    
    print(f"👤 Consultando documentos para usuário: {auth_user_id}")
    
    # 1. Buscar o driver_id baseado no auth user_id
    print("🔍 Buscando motorista...")
    driver_result = supabase.table('drivers').select('id').eq('user_id', auth_user_id).execute()
    
    if not driver_result.data:
        print("⚠️ Motorista não encontrado para este usuário")
        print("Criando entrada de motorista...")
        
        # Criar entrada básica de motorista
        new_driver = {
            'user_id': auth_user_id,
            'vehicle_brand': 'Toyota',
            'vehicle_model': 'Corolla',
            'vehicle_year': 2020,
            'vehicle_color': 'Branco',
            'vehicle_plate': 'TEST123',
            'vehicle_category': 'comum',
            'approval_status': 'pending'
        }
        
        driver_create_result = supabase.table('drivers').insert(new_driver).execute()
        driver_id = driver_create_result.data[0]['id']
        print(f"✅ Motorista criado com ID: {driver_id}")
    else:
        driver_id = driver_result.data[0]['id']
        print(f"✅ Motorista encontrado com ID: {driver_id}")
    
    # 2. Consultar documentos pendentes
    print("📄 Consultando documentos...")
    docs_result = supabase.table('driver_documents').select('*').eq('driver_id', driver_id).execute()
    
    if docs_result.data:
        print(f"📋 Encontrados {len(docs_result.data)} documentos:")
        for doc in docs_result.data:
            status = doc.get('status', 'unknown')
            doc_type = doc.get('document_type', 'unknown')
            print(f"   - {doc_type}: {status}")
            if status == 'rejected':
                reason = doc.get('rejection_reason', 'Sem motivo especificado')
                print(f"     Motivo: {reason}")
    else:
        print("📄 Criando documentos de teste...")
        # Criar documentos pendentes para teste
        test_documents = [
            {
                'driver_id': driver_id,
                'document_type': 'cnh',
                'file_url': 'https://example.com/cnh_test.jpg',
                'status': 'pending',
                'mime_type': 'image/jpeg',
                'file_size': 1024000
            },
            {
                'driver_id': driver_id,
                'document_type': 'foto_perfil',
                'file_url': 'https://example.com/foto_test.jpg',
                'status': 'rejected',
                'rejection_reason': 'Foto não está clara',
                'mime_type': 'image/jpeg',
                'file_size': 512000
            }
        ]
        
        for doc in test_documents:
            supabase.table('driver_documents').insert(doc).execute()
            print(f"✅ Documento {doc['document_type']} criado com status {doc['status']}")
    
    # 3. Verificar status de documentos pendentes
    pending_docs = supabase.table('driver_documents').select('*').eq('driver_id', driver_id).in_('status', ['pending', 'rejected']).execute()
    
    if pending_docs.data:
        print(f"\n⚠️ DOCUMENTOS PENDENTES ENCONTRADOS: {len(pending_docs.data)}")
        print("\n🎯 RESULTADO DO TESTE:")
        print(f"   📱 Auth User ID: {auth_user_id}")
        print(f"   🚗 Driver ID: {driver_id}")
        print(f"   📄 Documentos pendentes: {len(pending_docs.data)}")
        print("\n✅ O app deve mostrar a mensagem de documentos pendentes!")
    else:
        print("\n✅ Todos os documentos estão aprovados")
        print("\n⚠️ O app NÃO deve mostrar mensagem de documentos pendentes")
    
except Exception as e:
    print(f"❌ Erro: {e}")
    print("💥 Falha na consulta!")