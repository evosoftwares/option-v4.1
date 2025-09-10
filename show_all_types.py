#!/usr/bin/env python3
"""
Mostra todos os tipos de dados das colunas do Supabase
Exibe um resumo completo sem interação
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
        return None

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

def main():
    print("🔍 TIPOS DE DADOS DAS COLUNAS DO SUPABASE")
    print("=" * 80)
    
    schema_data = load_schema_with_types()
    if not schema_data:
        return
    
    # Coletar estatísticas gerais
    all_types = defaultdict(int)
    tables_with_types = 0
    total_columns = 0
    
    print(f"\n📊 RESUMO GERAL:")
    print("-" * 50)
    
    for table_name, table_data in schema_data['tables'].items():
        if table_data['accessible'] and table_data['column_types']:
            tables_with_types += 1
            for col_type in table_data['column_types'].values():
                all_types[col_type] += 1
                total_columns += 1
    
    print(f"📋 Tabelas com tipos identificados: {tables_with_types}")
    print(f"📝 Total de colunas tipadas: {total_columns}")
    
    # Mostrar distribuição de tipos
    print(f"\n🔧 DISTRIBUIÇÃO DE TIPOS:")
    print("-" * 60)
    
    sorted_types = sorted(all_types.items(), key=lambda x: x[1], reverse=True)
    
    for col_type, count in sorted_types:
        icon = get_type_icon(col_type)
        percentage = (count / total_columns) * 100
        print(f"   {icon} {col_type:<20} {count:>3} colunas ({percentage:>5.1f}%)")
    
    # Mostrar detalhes por tabela
    print(f"\n📋 DETALHES POR TABELA:")
    print("=" * 80)
    
    tables_with_types_list = [(name, data) for name, data in schema_data['tables'].items() 
                             if data['accessible'] and data['column_types']]
    
    # Ordenar por complexidade (número de tipos únicos)
    tables_with_types_list.sort(key=lambda x: len(set(x[1]['column_types'].values())), reverse=True)
    
    for table_name, table_data in tables_with_types_list:
        unique_types = len(set(table_data['column_types'].values()))
        total_cols = len(table_data['column_types'])
        records = table_data['record_count']
        
        complexity_icon = "🔥" if unique_types >= 8 else "🔧" if unique_types >= 5 else "📝"
        
        print(f"\n{complexity_icon} {table_name.upper()}")
        print(f"   📊 {records} registros | {total_cols} colunas | {unique_types} tipos únicos")
        
        # Agrupar colunas por tipo
        types_groups = defaultdict(list)
        for column, col_type in table_data['column_types'].items():
            types_groups[col_type].append(column)
        
        # Mostrar tipos ordenados por frequência
        sorted_table_types = sorted(types_groups.items(), key=lambda x: len(x[1]), reverse=True)
        
        for col_type, columns in sorted_table_types:
            icon = get_type_icon(col_type)
            count = len(columns)
            
            print(f"   {icon} {col_type} ({count}): ", end="")
            
            # Mostrar até 5 colunas por linha
            if count <= 5:
                print(", ".join(columns))
            else:
                print(", ".join(columns[:5]) + f" ... (+{count-5} mais)")
    
    # Mostrar tabelas inacessíveis
    inaccessible_tables = [(name, data) for name, data in schema_data['tables'].items() 
                          if not data['accessible']]
    
    if inaccessible_tables:
        print(f"\n❌ TABELAS INACESSÍVEIS ({len(inaccessible_tables)}):")
        print("-" * 60)
        for table_name, table_data in inaccessible_tables:
            print(f"   • {table_name}: {table_data['error']}")
    
    print(f"\n✅ Análise completa! Total: {len(schema_data['tables'])} tabelas ({tables_with_types} acessíveis)")

if __name__ == "__main__":
    main()