#!/usr/bin/env python3
"""
Script para executar comandos SQL no Supabase
"""

import requests
import json
import os
import sys

# Credenciais do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk"

def executar_sql(query):
    """Executa um comando SQL no Supabase"""
    headers = {
        'apikey': SUPABASE_SERVICE_ROLE_KEY,
        'Authorization': f'Bearer {SUPABASE_SERVICE_ROLE_KEY}',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
    }
    
    url = f"{SUPABASE_URL}/rest/v1/rpc/execute_sql"
    
    # Payload para a requisição
    payload = {
        "query": query
    }
    
    try:
        response = requests.post(url, headers=headers, json=payload, timeout=30)
        response.raise_for_status()
        
        resultado = response.json()
        print(f"✅ Comando executado com sucesso!")
        return resultado
        
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
        for i, comando in enumerate(comandos, 1):
            if comando.upper().startswith(('SELECT', 'INSERT', 'UPDATE', 'DELETE', 'CREATE', 'DROP', 'ALTER', 'BEGIN', 'COMMIT', 'DO')):
                print(f"🔍 Executando comando {i}/{len(comandos)}...")
                print(f"Comando: {comando[:100]}{'...' if len(comando) > 100 else ''}")
                
                resultado = executar_sql(comando)
                resultados.append(resultado)
                
                if resultado is not None:
                    print(f"✅ Comando {i} executado com sucesso!")
                else:
                    print(f"❌ Falha ao executar comando {i}")
                    return False
            else:
                print(f"⏭️  Pulando comando {i} (comentário ou vazio)")
        
        print("✅ Todos os comandos foram executados com sucesso!")
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
        print("💡 Uso: python3 executar_sql.py <caminho_do_arquivo.sql>")
        sys.exit(1)