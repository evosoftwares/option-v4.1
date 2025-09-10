#!/usr/bin/env python3
"""
Script para conectar ao Supabase e extrair informações do schema do banco de dados.
"""

import os
import requests
import json
from supabase import create_client, Client

# Credenciais do Supabase encontradas nos arquivos de backup
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def connect_to_supabase():
    """Conecta ao Supabase usando as credenciais"""
    try:
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)
        print("✅ Conexão com Supabase estabelecida com sucesso!")
        return supabase
    except Exception as e:
        print(f"❌ Erro ao conectar ao Supabase: {e}")
        return None

def get_table_schema(supabase):
    """Obtém informações do schema das tabelas"""
    try:
        # Consulta para obter informações das tabelas
        response = supabase.table('pg_tables').select('*').execute()
        
        if response.data:
            print("✅ Informações das tabelas obtidas com sucesso!")
            return response.data
        else:
            print("❌ Nenhuma tabela encontrada ou erro na consulta")
            return None
            
    except Exception as e:
        print(f"❌ Erro ao obter schema das tabelas: {e}")
        return None

def get_columns_info(supabase):
    """Obtém informações detalhadas das colunas"""
    try:
        # Consulta para obter informações das colunas
        response = supabase.rpc('get_columns_info').execute()
        
        if response.data:
            print("✅ Informações das colunas obtidas com sucesso!")
            return response.data
        else:
            # Tentativa alternativa usando query SQL direta
            return get_columns_info_alternative(supabase)
            
    except Exception as e:
        print(f"❌ Erro ao obter informações das colunas: {e}")
        return get_columns_info_alternative(supabase)

def get_columns_info_alternative(supabase):
    """Método alternativo para obter informações das colunas"""
    try:
        # Query SQL para obter informações das colunas
        query = """
        SELECT 
            table_name,
            column_name,
            data_type,
            is_nullable,
            column_default,
            character_maximum_length,
            numeric_precision,
            numeric_scale
        FROM information_schema.columns
        WHERE table_schema = 'public'
        ORDER BY table_name, ordinal_position;
        """
        
        response = supabase.rpc('query', {'sql': query}).execute()
        
        if response.data:
            return response.data
        else:
            print("❌ Não foi possível obter informações das colunas")
            return None
            
    except Exception as e:
        print(f"❌ Erro no método alternativo: {e}")
        return None

def get_constraints_info(supabase):
    """Obtém informações sobre constraints"""
    try:
        # Query para obter constraints
        query = """
        SELECT 
            tc.table_name,
            tc.constraint_name,
            tc.constraint_type,
            kcu.column_name,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name
        FROM information_schema.table_constraints tc
        LEFT JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name
        LEFT JOIN information_schema.constraint_column_usage ccu
            ON tc.constraint_name = ccu.constraint_name
        WHERE tc.table_schema = 'public'
        ORDER BY tc.table_name, tc.constraint_type;
        """
        
        response = supabase.rpc('query', {'sql': query}).execute()
        
        if response.data:
            print("✅ Informações de constraints obtidas com sucesso!")
            return response.data
        else:
            print("❌ Não foi possível obter informações de constraints")
            return None
            
    except Exception as e:
        print(f"❌ Erro ao obter constraints: {e}")
        return None

def get_indexes_info(supabase):
    """Obtém informações sobre índices"""
    try:
        # Query para obter índices
        query = """
        SELECT 
            tablename AS table_name,
            indexname AS index_name,
            indexdef AS index_definition
        FROM pg_indexes
        WHERE schemaname = 'public'
        ORDER BY tablename, indexname;
        """
        
        response = supabase.rpc('query', {'sql': query}).execute()
        
        if response.data:
            print("✅ Informações de índices obtidas com sucesso!")
            return response.data
        else:
            print("❌ Não foi possível obter informações de índices")
            return None
            
    except Exception as e:
        print(f"❌ Erro ao obter índices: {e}")
        return None

def main():
    """Função principal"""
    print("🔍 Iniciando extração do schema do Supabase...")
    
    # Conectar ao Supabase
    supabase = connect_to_supabase()
    if not supabase:
        return
    
    # Obter informações do schema
    schema_data = {
        'tables': get_table_schema(supabase),
        'columns': get_columns_info(supabase),
        'constraints': get_constraints_info(supabase),
        'indexes': get_indexes_info(supabase)
    }
    
    # Salvar dados em arquivo JSON para análise
    with open('supabase_schema_output.json', 'w') as f:
        json.dump(schema_data, f, indent=2, ensure_ascii=False)
    
    print("✅ Dados do schema salvos em 'supabase_schema_output.json'")
    print("📊 Resumo dos dados obtidos:")
    
    for key, value in schema_data.items():
        if value:
            print(f"   {key}: {len(value)} registros")
        else:
            print(f"   {key}: Nenhum dado obtido")

if __name__ == "__main__":
    main()