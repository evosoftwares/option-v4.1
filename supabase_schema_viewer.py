#!/usr/bin/env python3
"""
Visualizador interativo do schema do Supabase
Apresenta as tabelas de forma organizada e mostra relações
"""

import json
from supabase import create_client, Client

# Configurações do Supabase
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E"

def load_schema():
    """Carrega o schema exportado"""
    try:
        with open('supabase_schema_export.json', 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        print("❌ Arquivo supabase_schema_export.json não encontrado!")
        print("   Execute primeiro: python3 export_supabase_schema.py")
        return None

def show_table_details(schema_data, table_name):
    """Mostra detalhes de uma tabela específica"""
    if table_name not in schema_data['tables']:
        print(f"❌ Tabela '{table_name}' não encontrada!")
        return
    
    table = schema_data['tables'][table_name]
    
    print(f"\n📋 DETALHES DA TABELA: {table_name.upper()}")
    print("=" * 60)
    
    if not table['accessible']:
        print(f"❌ Tabela inacessível: {table['error']}")
        return
    
    print(f"📊 Registros: {table['record_count']}")
    print(f"📝 Colunas: {table['column_count']}")
    
    if table['columns']:
        print(f"\n🔑 ESTRUTURA DAS COLUNAS:")
        for i, column in enumerate(table['columns'], 1):
            # Identificar colunas especiais
            icon = "🆔" if column == 'id' else \
                   "🔗" if column.endswith('_id') else \
                   "📧" if 'email' in column else \
                   "📱" if 'phone' in column else \
                   "📅" if 'created_at' in column or 'updated_at' in column else \
                   "💰" if 'price' in column or 'fee' in column or 'balance' in column else \
                   "📍" if 'latitude' in column or 'longitude' in column else \
                   "✅" if column.startswith('is_') or column.startswith('accepts_') else \
                   "📄"
            
            print(f"   {i:2d}. {icon} {column}")
    
    # Mostrar exemplo de dados se disponível
    if table['example_data']:
        print(f"\n💡 EXEMPLO DE DADOS:")
        example = table['example_data']
        for key, value in list(example.items())[:5]:  # Mostrar apenas os primeiros 5
            if isinstance(value, str) and len(value) > 50:
                value = value[:50] + "..."
            print(f"   {key}: {value}")
        if len(example) > 5:
            print(f"   ... e mais {len(example) - 5} campos")

def show_relationships():
    """Mostra as principais relações entre tabelas"""
    print("\n🔗 PRINCIPAIS RELAÇÕES ENTRE TABELAS")
    print("=" * 60)
    
    relationships = [
        ("app_users", "drivers", "id → user_id", "Um usuário pode ser um motorista"),
        ("app_users", "passengers", "id → user_id", "Um usuário pode ser um passageiro"),
        ("drivers", "driver_wallets", "id → driver_id", "Cada motorista tem uma carteira"),
        ("drivers", "driver_offers", "id → driver_id", "Motorista pode fazer ofertas"),
        ("drivers", "driver_schedules", "id → driver_id", "Motorista tem horários"),
        ("trip_requests", "trips", "id → request_id", "Solicitação vira viagem"),
        ("drivers", "trips", "id → driver_id", "Motorista realiza viagens"),
        ("passengers", "trips", "id → passenger_id", "Passageiro faz viagens"),
    ]
    
    for parent, child, relation, description in relationships:
        print(f"   📊 {parent} ──({relation})──> {child}")
        print(f"      💭 {description}")
        print()

def show_main_menu(schema_data):
    """Mostra o menu principal interativo"""
    while True:
        print("\n" + "=" * 70)
        print("🔍 EXPLORADOR DE SCHEMA DO SUPABASE - MENU PRINCIPAL")
        print("=" * 70)
        print("1. 📊 Resumo geral das tabelas")
        print("2. 🔍 Detalhes de uma tabela específica")
        print("3. 🔗 Ver relações entre tabelas")
        print("4. 📋 Listar todas as tabelas acessíveis")
        print("5. ❌ Listar tabelas inacessíveis")
        print("0. 🚪 Sair")
        print("=" * 70)
        
        choice = input("Escolha uma opção: ").strip()
        
        if choice == "0":
            print("👋 Até logo!")
            break
        elif choice == "1":
            show_summary(schema_data)
        elif choice == "2":
            show_table_selection(schema_data)
        elif choice == "3":
            show_relationships()
        elif choice == "4":
            list_accessible_tables(schema_data)
        elif choice == "5":
            list_inaccessible_tables(schema_data)
        else:
            print("❌ Opção inválida! Tente novamente.")

def show_summary(schema_data):
    """Mostra resumo geral"""
    print("\n📊 RESUMO GERAL DO SCHEMA")
    print("=" * 50)
    
    accessible = sum(1 for t in schema_data['tables'].values() if t['accessible'])
    inaccessible = len(schema_data['tables']) - accessible
    
    print(f"📅 Data da exportação: {schema_data['metadata']['export_date'][:19]}")
    print(f"🎯 Total de tabelas: {schema_data['metadata']['total_tables']}")
    print(f"✅ Tabelas acessíveis: {accessible}")
    print(f"❌ Tabelas inacessíveis: {inaccessible}")
    
    # Tabelas com mais registros
    print(f"\n🔥 TABELAS COM MAIS DADOS:")
    accessible_tables = [(name, data) for name, data in schema_data['tables'].items() 
                        if data['accessible'] and isinstance(data['record_count'], int)]
    accessible_tables.sort(key=lambda x: x[1]['record_count'], reverse=True)
    
    for name, data in accessible_tables[:5]:
        print(f"   📊 {name}: {data['record_count']} registros, {data['column_count']} colunas")

def show_table_selection(schema_data):
    """Permite selecionar uma tabela para ver detalhes"""
    accessible_tables = [name for name, data in schema_data['tables'].items() if data['accessible']]
    
    print(f"\n📋 TABELAS DISPONÍVEIS ({len(accessible_tables)}):")
    print("-" * 50)
    
    for i, table_name in enumerate(accessible_tables, 1):
        record_count = schema_data['tables'][table_name]['record_count']
        print(f"   {i:2d}. {table_name} ({record_count} registros)")
    
    try:
        choice = input(f"\nEscolha uma tabela (1-{len(accessible_tables)}) ou 0 para voltar: ").strip()
        if choice == "0":
            return
        
        index = int(choice) - 1
        if 0 <= index < len(accessible_tables):
            show_table_details(schema_data, accessible_tables[index])
        else:
            print("❌ Número inválido!")
    except ValueError:
        print("❌ Por favor, digite um número válido!")

def list_accessible_tables(schema_data):
    """Lista todas as tabelas acessíveis"""
    accessible = [(name, data) for name, data in schema_data['tables'].items() if data['accessible']]
    
    print(f"\n✅ TABELAS ACESSÍVEIS ({len(accessible)}):")
    print("=" * 60)
    
    for name, data in accessible:
        print(f"   📊 {name:<25} | {data['record_count']:>6} registros | {data['column_count']:>2} colunas")

def list_inaccessible_tables(schema_data):
    """Lista todas as tabelas inacessíveis"""
    inaccessible = [(name, data) for name, data in schema_data['tables'].items() if not data['accessible']]
    
    print(f"\n❌ TABELAS INACESSÍVEIS ({len(inaccessible)}):")
    print("=" * 60)
    
    for name, data in inaccessible:
        error = data['error'][:50] + "..." if len(data['error']) > 50 else data['error']
        print(f"   ❌ {name:<25} | {error}")

def main():
    print("🚀 CARREGANDO SCHEMA DO SUPABASE...")
    
    schema_data = load_schema()
    if not schema_data:
        return
    
    print(f"✅ Schema carregado com sucesso!")
    print(f"📊 {len(schema_data['tables'])} tabelas encontradas")
    
    show_main_menu(schema_data)

if __name__ == "__main__":
    main()