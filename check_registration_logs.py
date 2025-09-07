#!/usr/bin/env python3
"""
Script para verificar logs de erro de cadastro no Supabase
Analisa tanto os error_logs quanto app_logs para identificar problemas de registro
"""

import os
import sys
from datetime import datetime, timedelta
from supabase import create_client, Client

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def main():
    try:
        # Conectar ao Supabase
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        print("🔍 Conectado ao Supabase - Verificando logs de cadastro...")
        print("=" * 60)
        
        # Data limite (últimas 24 horas)
        since = datetime.now() - timedelta(hours=24)
        since_str = since.isoformat()
        
        # 1. Verificar logs de erro
        print("\n📋 LOGS DE ERRO (error_logs):")
        print("-" * 40)
        
        try:
            error_response = supabase.table('error_logs')\
                .select('*')\
                .gte('timestamp', since_str)\
                .order('timestamp', desc=True)\
                .limit(50)\
                .execute()
            
            if error_response.data:
                for error in error_response.data:
                    print(f"⚠️  {error.get('timestamp', 'N/A')}")
                    print(f"   Tipo: {error.get('error_type', 'N/A')}")
                    print(f"   Severidade: {error.get('severity', 'N/A')}")
                    print(f"   Mensagem: {error.get('message', 'N/A')}")
                    if error.get('user_message'):
                        print(f"   Msg Usuario: {error.get('user_message')}")
                    if error.get('technical_details'):
                        print(f"   Detalhes: {error.get('technical_details')}")
                    if error.get('context'):
                        print(f"   Contexto: {error.get('context')}")
                    print()
            else:
                print("✅ Nenhum erro encontrado na tabela error_logs")
                
        except Exception as e:
            print(f"❌ Erro ao consultar error_logs: {e}")
        
        # 2. Verificar logs de aplicação
        print("\n📋 LOGS DE APLICAÇÃO (app_logs):")
        print("-" * 40)
        
        try:
            app_response = supabase.table('app_logs')\
                .select('*')\
                .gte('timestamp', since_str)\
                .order('timestamp', desc=True)\
                .limit(50)\
                .execute()
            
            if app_response.data:
                for log in app_response.data:
                    level = log.get('level', 'info').upper()
                    icon = "🔴" if level == "ERROR" else "🟡" if level == "WARNING" else "🔵"
                    print(f"{icon} {log.get('timestamp', 'N/A')}")
                    print(f"   Level: {level}")
                    print(f"   Mensagem: {log.get('message', 'N/A')}")
                    if log.get('context'):
                        print(f"   Contexto: {log.get('context')}")
                    print()
            else:
                print("✅ Nenhum log encontrado na tabela app_logs")
                
        except Exception as e:
            print(f"❌ Erro ao consultar app_logs: {e}")
        
        # 3. Verificar logs de autenticação do Supabase (se disponível)
        print("\n📋 TENTATIVAS DE CADASTRO RECENTES:")
        print("-" * 40)
        
        try:
            # Verificar usuários criados recentemente
            users_response = supabase.table('app_users')\
                .select('id, phone, user_type, created_at, updated_at')\
                .gte('created_at', since_str)\
                .order('created_at', desc=True)\
                .limit(20)\
                .execute()
            
            if users_response.data:
                print("👥 Usuários criados recentemente:")
                for user in users_response.data:
                    print(f"   📱 {user.get('phone', 'N/A')} - Tipo: {user.get('user_type', 'N/A')}")
                    print(f"      Criado: {user.get('created_at', 'N/A')}")
                    print(f"      ID: {user.get('id', 'N/A')}")
                    print()
            else:
                print("⚠️  Nenhum usuário criado nas últimas 24h")
                
        except Exception as e:
            print(f"❌ Erro ao consultar app_users: {e}")
        
        # 4. Buscar erros relacionados a cadastro/registro
        print("\n📋 ERROS ESPECÍFICOS DE CADASTRO:")
        print("-" * 40)
        
        try:
            # Buscar todos os erros recentes e filtrar localmente
            all_errors = supabase.table('error_logs')\
                .select('*')\
                .gte('timestamp', since_str)\
                .order('timestamp', desc=True)\
                .execute()
            
            cadastro_keywords = ['cadastro', 'registro', 'registration', 'signup', 'auth', 'user']
            cadastro_errors = []
            
            if all_errors.data:
                for error in all_errors.data:
                    message = error.get('message', '').lower()
                    details = error.get('technical_details', '').lower()
                    if any(keyword in message or keyword in details for keyword in cadastro_keywords):
                        cadastro_errors.append(error)
            
            if cadastro_errors:
                for error in cadastro_errors:
                    print(f"🚨 {error.get('timestamp', 'N/A')}")
                    print(f"   Mensagem: {error.get('message', 'N/A')}")
                    print(f"   Detalhes: {error.get('technical_details', 'N/A')}")
                    print(f"   Contexto: {error.get('context', 'N/A')}")
                    print()
            else:
                print("✅ Nenhum erro específico de cadastro encontrado")
                
        except Exception as e:
            print(f"❌ Erro ao buscar erros de cadastro: {e}")
            
        print("\n" + "=" * 60)
        print("✅ Análise de logs concluída!")
        
    except Exception as e:
        print(f"❌ Erro geral: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()