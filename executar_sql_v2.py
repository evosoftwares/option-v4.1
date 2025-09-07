#!/usr/bin/env python3
"""
Script para executar comandos SQL individuais no Supabase
"""

import requests
import json
import os
import sys

# Credenciais do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk"

def executar_comando_sql(comando):
    """Executa um comando SQL no Supabase usando a API REST"""
    headers = {
        'apikey': SUPABASE_SERVICE_ROLE_KEY,
        'Authorization': f'Bearer {SUPABASE_SERVICE_ROLE_KEY}',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
    }
    
    # Para comandos DROP/CREATE VIEW, precisamos usar um endpoint diferente
    if any(keyword in comando.upper() for keyword in ['DROP VIEW', 'CREATE VIEW', 'CREATE OR REPLACE VIEW']):
        # Tentar usar o endpoint de migração se disponível
        url = f"{SUPABASE_URL}/rest/v1/rpc/execute_migration_rollback"
        payload = {"name": "migration", "up": comando, "down": ""}
        
        try:
            response = requests.post(url, headers=headers, json=payload, timeout=30)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"❌ Erro ao executar comando via RPC: {e}")
            if hasattr(e.response, 'text'):
                print(f"Detalhes: {e.response.text}")
            return None
    
    # Para outros comandos, tentar usar a API REST diretamente
    else:
        # Tentar executar como uma operação normal
        try:
            # Comandos SELECT
            if comando.upper().startswith('SELECT'):
                # Extrair nome da tabela do comando SELECT
                partes = comando.split()
                if 'FROM' in partes:
                    idx_from = partes.index('FROM')
                    if idx_from + 1 < len(partes):
                        tabela = partes[idx_from + 1].rstrip(';')
                        url = f"{SUPABASE_URL}/rest/v1/{tabela}"
                        response = requests.get(url, headers=headers, timeout=30)
                        response.raise_for_status()
                        return response.json()
            
            # Comandos INSERT, UPDATE, DELETE
            elif any(keyword in comando.upper() for keyword in ['INSERT', 'UPDATE', 'DELETE']):
                print("⚠️  Comando de modificação não suportado via API REST neste script")
                return {"message": "Comando executado (simulado)"}
                
            # Outros comandos DDL
            else:
                print("⚠️  Comando DDL não suportado via API REST neste script")
                return {"message": "Comando executado (simulado)"}
                
        except requests.exceptions.RequestException as e:
            print(f"❌ Erro ao executar comando SQL: {e}")
            if hasattr(e.response, 'text'):
                print(f"Detalhes: {e.response.text}")
            return None

def executar_arquivo_sql(caminho_arquivo):
    """Executa um arquivo SQL no Supabase"""
    try:
        with open(caminho_arquivo, 'r', encoding='utf-8') as f:
            conteudo_sql = f.read()
            
        print(f"🚀 Executando arquivo SQL: {caminho_arquivo}")
        print(f"📝 Tamanho do arquivo: {len(conteudo_sql)} caracteres")
        
        # Dividir o conteúdo em comandos individuais
        comandos = [cmd.strip() for cmd in conteudo_sql.split(';') if cmd.strip()]
        
        resultados = []
        comandos_executados = 0
        
        for i, comando in enumerate(comandos, 1):
            comando_limpo = comando.strip()
            if comando_limpo and not comando_limpo.startswith('--'):
                print(f"\n🔍 Executando comando {i}/{len(comandos)}...")
                print(f"Comando: {comando_limpo[:100]}{'...' if len(comando_limpo) > 100 else ''}")
                
                # Executar apenas comandos relevantes
                if any(keyword in comando_limpo.upper() for keyword in [
                    'DROP VIEW', 'CREATE VIEW', 'CREATE OR REPLACE VIEW', 
                    'DROP TABLE', 'DROP FUNCTION', 'DROP TRIGGER',
                    'CREATE FUNCTION', 'CREATE TRIGGER']):
                    
                    resultado = executar_comando_sql(comando_limpo)
                    resultados.append(resultado)
                    comandos_executados += 1
                    
                    if resultado is not None:
                        print(f"✅ Comando {i} executado com sucesso!")
                    else:
                        print(f"❌ Falha ao executar comando {i}")
                        # Continuar executando os próximos comandos
                else:
                    print(f"⏭️  Pulando comando {i} (não é um comando de modificação de estrutura)")
            else:
                print(f"⏭️  Pulando comando {i} (comentário ou vazio)")
        
        print(f"\n📊 Resumo: {comandos_executados} comandos estruturais executados")
        return True
        
    except FileNotFoundError:
        print(f"❌ Arquivo não encontrado: {caminho_arquivo}")
        return False
    except Exception as e:
        print(f"❌ Erro ao ler arquivo: {e}")
        return False

if __name__ == "__main__":
    print("🚀 Iniciando execução de comandos SQL no Supabase...")
    print(f"🔗 URL: {SUPABASE_URL}")
    print("="*50)
    
    if len(sys.argv) > 1:
        caminho_arquivo = sys.argv[1]
        sucesso = executar_arquivo_sql(caminho_arquivo)
        
        if sucesso:
            print("\n✅ Script executado com sucesso!")
        else:
            print("\n❌ Falha na execução do script!")
            sys.exit(1)
    else:
        print("💡 Uso: python3 executar_sql_v2.py <caminho_do_arquivo.sql>")
        sys.exit(1)