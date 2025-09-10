#!/usr/bin/env python3
"""
Visualizador de tipos de colunas do Supabase
Mostra os tipos de dados de forma organizada e legível
"""

import json
from collections import defaultdict

def load_schema_with_types():
    """Carrega o schema com tipos de dados"""
    try:
        with open('supabase_schema_with_types.json', 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        print("❌ Arquivo supabase_schema_with_types.json não encontrado!")
        print("   Execute primeiro: python3 export_supabase_schema_with_types.py")
        return None

def show_table_types(schema_data, table_name):
    """Mostra os tipos de dados de uma tabela específica"""
    if table_name not in schema_data['tables']:
        print(f"❌ Tabela '{table_name}' não encontrada!")
        return
    
    table = schema_data['tables'][table_name]
    
    print(f"\n📋 TIPOS DE DADOS: {table_name.upper()}")
    print("=" * 70)
    
    if not table['accessible']:
        print(f"❌ Tabela inacessível: {table['error']}")
        return
    
    print(f"📊 Registros: {table['record_count']}")
    print(f"📝 Colunas: {table['column_count']}")
    
    if not table['column_types']:
        print("⚠️  Nenhum tipo de dado identificado (tabela vazia)")
        return
    
    # Agrupar por tipo
    types_groups = defaultdict(list)
    for column, col_type in table['column_types'].items():
        types_groups[col_type].append(column)
    
    print(f"\n🔧 TIPOS IDENTIFICADOS ({len(table['column_types'])} colunas):")
    print("-" * 70)
    
    # Ordenar tipos por frequência
    sorted_types = sorted(types_groups.items(), key=lambda x: len(x[1]), reverse=True)
    
    for col_type, columns in sorted_types:
        icon = get_type_icon(col_type)
        count = len(columns)
        
        print(f"\n{icon} {col_type.upper()} ({count} coluna{'s' if count > 1 else ''})")
        
        # Mostrar colunas em linhas de até 3
        for i in range(0, len(columns), 3):
            row_columns = columns[i:i+3]
            formatted_columns = [f"• {col}" for col in row_columns]
            print(f"   {' '.join(formatted_columns)}")
    
    # Mostrar exemplo de dados se disponível
    if table['example_data']:
        print(f"\n💡 EXEMPLO DE DADOS COM TIPOS:")
        print("-" * 70)
        example = table['example_data']
        
        for column in list(example.keys())[:8]:  # Mostrar apenas os primeiros 8
            value = example[column]
            col_type = table['column_types'].get(column, 'unknown')
            icon = get_type_icon(col_type)
            
            # Formatar valor para exibição
            if isinstance(value, str) and len(value) > 40:
                display_value = value[:40] + "..."
            else:
                display_value = value
            
            print(f"   {icon} {column:<20} ({col_type:<15}) = {display_value}")
        
        if len(example) > 8:
            print(f"   ... e mais {len(example) - 8} campos")

def get_type_icon(col_type):
    """Retorna um ícone apropriado para o tipo de dados"""
    type_icons = {
        'uuid': '🆔',
        'text': '📝',
        'integer': '🔢',
        'numeric': '💰',
        'boolean': '✅',
        'timestamp': '📅',
        'email (text)': '📧',
        'phone (text)': '📱',
        'url (text)': '🔗',
        'nullable': '❓',
    }
    
    return type_icons.get(col_type.lower(), '📄')

def show_types_summary(schema_data):
    """Mostra resumo geral dos tipos encontrados"""
    print("\n📊 RESUMO GERAL DOS TIPOS DE DADOS")
    print("=" * 70)
    
    all_types = defaultdict(int)
    tables_with_types = 0
    total_columns = 0
    
    for table_name, table_data in schema_data['tables'].items():
        if table_data['accessible'] and table_data['column_types']:
            tables_with_types += 1
            for col_type in table_data['column_types'].values():
                all_types[col_type] += 1
                total_columns += 1
    
    print(f"📋 Tabelas com tipos identificados: {tables_with_types}")
    print(f"📝 Total de colunas tipadas: {total_columns}")
    
    print(f"\n🔧 DISTRIBUIÇÃO DE TIPOS:")
    print("-" * 50)
    
    # Ordenar tipos por frequência
    sorted_types = sorted(all_types.items(), key=lambda x: x[1], reverse=True)
    
    for col_type, count in sorted_types:
        icon = get_type_icon(col_type)
        percentage = (count / total_columns) * 100
        print(f"   {icon} {col_type:<20} {count:>3} colunas ({percentage:>5.1f}%)")

def show_tables_by_complexity(schema_data):
    """Mostra tabelas ordenadas por complexidade (número de tipos diferentes)"""
    print("\n🏗️  COMPLEXIDADE DAS TABELAS (por variedade de tipos)")
    print("=" * 70)
    
    table_complexity = []
    
    for table_name, table_data in schema_data['tables'].items():
        if table_data['accessible'] and table_data['column_types']:
            unique_types = len(set(table_data['column_types'].values()))
            total_columns = len(table_data['column_types'])
            table_complexity.append((table_name, unique_types, total_columns, table_data['record_count']))
    
    # Ordenar por número de tipos únicos, depois por total de colunas
    table_complexity.sort(key=lambda x: (x[1], x[2]), reverse=True)
    
    for table_name, unique_types, total_columns, records in table_complexity:
        complexity_icon = "🔥" if unique_types >= 8 else "🔧" if unique_types >= 5 else "📝"
        print(f"   {complexity_icon} {table_name:<25} | {unique_types:>2} tipos únicos | {total_columns:>2} colunas | {records:>3} registros")

def main():
    print("🔍 CARREGANDO SCHEMA COM TIPOS DE DADOS...")
    
    schema_data = load_schema_with_types()
    if not schema_data:
        return
    
    print(f"✅ Schema carregado com sucesso!")
    print(f"📊 {len(schema_data['tables'])} tabelas encontradas")
    
    while True:
        print("\n" + "=" * 70)
        print("🔧 EXPLORADOR DE TIPOS DE DADOS - MENU PRINCIPAL")
        print("=" * 70)
        print("1. 📊 Resumo geral dos tipos")
        print("2. 🔍 Tipos de uma tabela específica")
        print("3. 🏗️  Tabelas por complexidade")
        print("4. 📋 Listar todas as tabelas com tipos")
        print("0. 🚪 Sair")
        print("=" * 70)
        
        choice = input("Escolha uma opção: ").strip()
        
        if choice == "0":
            print("👋 Até logo!")
            break
        elif choice == "1":
            show_types_summary(schema_data)
        elif choice == "2":
            show_table_selection_for_types(schema_data)
        elif choice == "3":
            show_tables_by_complexity(schema_data)
        elif choice == "4":
            list_tables_with_types(schema_data)
        else:
            print("❌ Opção inválida! Tente novamente.")

def show_table_selection_for_types(schema_data):
    """Permite selecionar uma tabela para ver tipos"""
    tables_with_types = [(name, data) for name, data in schema_data['tables'].items() 
                        if data['accessible'] and data['column_types']]
    
    print(f"\n📋 TABELAS COM TIPOS IDENTIFICADOS ({len(tables_with_types)}):")
    print("-" * 60)
    
    for i, (table_name, table_data) in enumerate(tables_with_types, 1):
        unique_types = len(set(table_data['column_types'].values()))
        total_columns = len(table_data['column_types'])
        print(f"   {i:2d}. {table_name:<25} | {unique_types} tipos únicos | {total_columns} colunas")
    
    try:
        choice = input(f"\nEscolha uma tabela (1-{len(tables_with_types)}) ou 0 para voltar: ").strip()
        if choice == "0":
            return
        
        index = int(choice) - 1
        if 0 <= index < len(tables_with_types):
            table_name = tables_with_types[index][0]
            show_table_types(schema_data, table_name)
        else:
            print("❌ Número inválido!")
    except ValueError:
        print("❌ Por favor, digite um número válido!")

def list_tables_with_types(schema_data):
    """Lista todas as tabelas que têm tipos identificados"""
    tables_with_types = [(name, data) for name, data in schema_data['tables'].items() 
                        if data['accessible'] and data['column_types']]
    
    print(f"\n🔧 TABELAS COM TIPOS IDENTIFICADOS ({len(tables_with_types)}):")
    print("=" * 80)
    
    for name, data in tables_with_types:
        unique_types = len(set(data['column_types'].values()))
        total_columns = len(data['column_types'])
        records = data['record_count']
        
        # Mostrar os 3 tipos mais comuns
        type_counts = defaultdict(int)
        for col_type in data['column_types'].values():
            type_counts[col_type] += 1
        
        top_types = sorted(type_counts.items(), key=lambda x: x[1], reverse=True)[:3]
        types_summary = ", ".join([f"{t}({c})" for t, c in top_types])
        
        print(f"   📊 {name:<25} | {unique_types:>2} tipos | {total_columns:>2} cols | {records:>3} regs | {types_summary}")

if __name__ == "__main__":
    main()