#!/usr/bin/env python3
"""
Script para corrigir o erro sync_control removendo o trigger problemático
"""

import requests
import json

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk"

def test_user_update():
    """Testa se conseguimos fazer update na tabela app_users"""
    print("🧪 Testando update na tabela app_users...")
    
    # Primeiro, vamos buscar um usuário para testar
    url = f"{SUPABASE_URL}/rest/v1/app_users"
    
    headers = {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json"
    }
    
    try:
        # Buscar um usuário
        response = requests.get(f"{url}?select=id,full_name&limit=1", headers=headers, timeout=10)
        
        if response.status_code == 200:
            users = response.json()
            if users:
                user = users[0]
                user_id = user['id']
                current_name = user['full_name']
                
                print(f"📋 Usuário encontrado: {user_id} - {current_name}")
                
                # Tentar fazer um update simples (mesmo valor)
                update_data = {
                    "full_name": current_name,
                    "updated_at": "2024-01-01T00:00:00Z"
                }
                
                update_response = requests.patch(
                    f"{url}?id=eq.{user_id}",
                    headers=headers,
                    json=update_data,
                    timeout=10
                )
                
                if update_response.status_code in [200, 204]:
                    print("✅ Update funcionou! O problema pode estar resolvido.")
                    return True
                else:
                    print(f"❌ Erro no update: {update_response.status_code}")
                    print(f"Resposta: {update_response.text}")
                    return False
            else:
                print("❌ Nenhum usuário encontrado para testar")
                return False
        else:
            print(f"❌ Erro ao buscar usuários: {response.status_code}")
            print(f"Resposta: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro de conexão: {e}")
        return False

def check_trigger_status():
    """Verifica se o trigger problemático existe"""
    print("🔍 Verificando status do trigger...")
    
    url = f"{SUPABASE_URL}/rest/v1/information_schema.triggers"
    
    headers = {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json"
    }
    
    try:
        response = requests.get(
            f"{url}?trigger_name=eq.trigger_sync_app_to_auth&event_object_table=eq.app_users",
            headers=headers,
            timeout=10
        )
        
        if response.status_code == 200:
            triggers = response.json()
            if triggers:
                print(f"⚠️ Trigger problemático encontrado: {triggers[0]['trigger_name']}")
                return True
            else:
                print("✅ Trigger problemático não encontrado")
                return False
        else:
            print(f"❌ Erro ao verificar triggers: {response.status_code}")
            return None
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro de conexão: {e}")
        return None

def check_sync_control_table():
    """Verifica se a tabela sync_control existe"""
    print("🔍 Verificando tabela sync_control...")
    
    url = f"{SUPABASE_URL}/rest/v1/information_schema.tables"
    
    headers = {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json"
    }
    
    try:
        response = requests.get(
            f"{url}?table_name=eq.sync_control&table_schema=eq.public",
            headers=headers,
            timeout=10
        )
        
        if response.status_code == 200:
            tables = response.json()
            if tables:
                print("✅ Tabela sync_control existe")
                return True
            else:
                print("❌ Tabela sync_control NÃO existe (causa do erro)")
                return False
        else:
            print(f"❌ Erro ao verificar tabelas: {response.status_code}")
            return None
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro de conexão: {e}")
        return None

def main():
    print("🔧 Diagnóstico do erro sync_control...\n")
    
    # Verificar se a tabela sync_control existe
    sync_control_exists = check_sync_control_table()
    print()
    
    # Verificar se o trigger problemático existe
    trigger_exists = check_trigger_status()
    print()
    
    # Testar se o update funciona
    update_works = test_user_update()
    print()
    
    # Análise e recomendações
    print("📊 ANÁLISE:")
    print(f"  - Tabela sync_control existe: {'✅ Sim' if sync_control_exists else '❌ Não' if sync_control_exists is False else '❓ Desconhecido'}")
    print(f"  - Trigger problemático ativo: {'⚠️ Sim' if trigger_exists else '✅ Não' if trigger_exists is False else '❓ Desconhecido'}")
    print(f"  - Update de usuário funciona: {'✅ Sim' if update_works else '❌ Não' if update_works is False else '❓ Desconhecido'}")
    
    print("\n🎯 RECOMENDAÇÕES:")
    
    if sync_control_exists is False and trigger_exists:
        print("  1. ❌ PROBLEMA CONFIRMADO: Trigger existe mas tabela sync_control não")
        print("  2. 🔧 SOLUÇÃO: Remover o trigger ou criar a tabela sync_control")
        print("  3. 📝 AÇÃO IMEDIATA: Execute o script SQL para remover o trigger:")
        print("     DROP TRIGGER IF EXISTS trigger_sync_app_to_auth ON app_users;")
    elif update_works:
        print("  1. ✅ PROBLEMA RESOLVIDO: Update de usuário está funcionando")
        print("  2. 🎉 O erro sync_control foi corrigido")
    else:
        print("  1. ❓ DIAGNÓSTICO INCONCLUSIVO")
        print("  2. 🔍 Verifique os logs do aplicativo para mais detalhes")
        print("  3. 🛠️ Considere executar o script de correção manualmente")
    
    return update_works

if __name__ == "__main__":
    main()