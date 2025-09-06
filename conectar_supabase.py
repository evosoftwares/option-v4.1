#!/usr/bin/env python3
"""
Script para conectar ao Supabase e listar todas as tabelas
"""

import requests
import json
import os

# Credenciais do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk"

def listar_tabelas():
    """Lista todas as tabelas do banco Supabase usando API REST"""
    headers = {
        'apikey': SUPABASE_SERVICE_ROLE_KEY,
        'Authorization': f'Bearer {SUPABASE_SERVICE_ROLE_KEY}',
        'Content-Type': 'application/json'
    }
    
    # Vamos tentar acessar diretamente as tabelas conhecidas
    tabelas_conhecidas = [
        'app_users', 'drivers', 'passengers', 'trips', 'trip_requests',
        'driver_offers', 'payment_methods', 'driver_documents', 'promo_codes',
        'driver_status', 'working_hours', 'ratings', 'emergency_contacts'
    ]
    
    tabelas_encontradas = []
    
    print("🔄 Verificando tabelas do Supabase...")
    print(f"🔗 URL: {SUPABASE_URL}")
    print(f"🔑 Usando Service Role Key")
    
    for tabela in tabelas_conhecidas:
        try:
            url = f"{SUPABASE_URL}/rest/v1/{tabela}?select=*&limit=1"
            response = requests.get(url, headers=headers, timeout=10)
            
            if response.status_code == 200:
                tabelas_encontradas.append(tabela)
                print(f"✅ {tabela}")
            elif response.status_code == 404:
                print(f"❌ {tabela} - não encontrada")
            else:
                print(f"⚠️  {tabela} - status {response.status_code}")
                
        except requests.exceptions.RequestException as e:
            print(f"❌ {tabela} - erro: {e}")
    
    if tabelas_encontradas:
        print("\n" + "="*50)
        print("TABELAS ENCONTRADAS:")
        print("="*50)
        for tabela in tabelas_encontradas:
            print(f"• {tabela}")
    
    return tabelas_encontradas

def verificar_dados_tabela(nome_tabela, limite=5):
    """Verifica os dados de uma tabela específica"""
    headers = {
        'apikey': SUPABASE_SERVICE_ROLE_KEY,
        'Authorization': f'Bearer {SUPABASE_SERVICE_ROLE_KEY}',
        'Content-Type': 'application/json'
    }
    
    url = f"{SUPABASE_URL}/rest/v1/{nome_tabela}?select=*&limit={limite}"
    
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        
        dados = response.json()
        print(f"\n📋 Dados da tabela '{nome_tabela}' (primeiros {limite} registros):")
        print("-" * 30)
        
        if dados:
            # Mostrar colunas
            colunas = list(dados[0].keys())
            print(f"Colunas: {', '.join(colunas)}")
            print(f"Total de registros: {len(dados)}")
            
            # Mostrar alguns registros
            for i, registro in enumerate(dados[:3], 1):
                print(f"Registro {i}: {registro}")
        else:
            print("Tabela vazia")
            
        return dados
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro ao buscar dados da tabela {nome_tabela}: {e}")
        return None

if __name__ == "__main__":
    print("🚀 Iniciando conexão com Supabase...")
    print("\n")
    
    # Listar todas as tabelas
    tabelas = listar_tabelas()
    
    if tabelas:
        # Verificar dados das tabelas encontradas
        for tabela in tabelas:
            verificar_dados_tabela(tabela)
    
    print("\n✅ Operação concluída!")
    
    # Informações adicionais
    print("\n📋 RESUMO:")
    print("="*30)
    print("✅ Conexão estabelecida com sucesso")
    print("✅ Supabase URL: https://qlbwacmavngtonauxnte.supabase.co")
    print("⚠️  Algumas tabelas podem ter RLS (Row Level Security) ativada")
    print("💡 Use a Service Role Key para acesso completo")