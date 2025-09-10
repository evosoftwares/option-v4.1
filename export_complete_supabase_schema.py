#!/usr/bin/env python3
"""
Script completo para exportar schema do Supabase com tipos de dados
Combina todas as funcionalidades em um único arquivo
"""

import os
import json
import requests
from datetime import datetime
from collections import defaultdict
from typing import Dict, List, Any, Optional

# Tentar carregar python-dotenv se disponível
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    # Se não tiver python-dotenv, tentar carregar manualmente do .env.example
    def load_env_file(filename):
        if os.path.exists(filename):
            with open(filename, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        os.environ[key] = value
    
    # Tentar carregar do .env primeiro, depois .env.example
    load_env_file('.env')
    if not os.getenv('SUPABASE_URL'):
        load_env_file('.env.example')

class SupabaseSchemaExporter:
    def __init__(self):
        self.supabase_url = os.getenv('SUPABASE_URL')
        self.supabase_anon_key = os.getenv('SUPABASE_ANON_KEY')
        
        if not self.supabase_url or not self.supabase_anon_key:
            print("⚠️  Tentando carregar configurações do .env.example...")
            # Tentar carregar novamente
            self.supabase_url = os.getenv('SUPABASE_URL')
            self.supabase_anon_key = os.getenv('SUPABASE_ANON_KEY')
            
            if not self.supabase_url or not self.supabase_anon_key:
                raise ValueError("❌ Variáveis SUPABASE_URL e SUPABASE_ANON_KEY são obrigatórias!")
        
        self.headers = {
            'apikey': self.supabase_anon_key,
            'Authorization': f'Bearer {self.supabase_anon_key}',
            'Content-Type': 'application/json'
        }
        
        self.base_url = f"{self.supabase_url}/rest/v1"
        self.schema_data = {
            'export_date': datetime.now().isoformat(),
            'supabase_url': self.supabase_url,
            'total_tables': 0,
            'accessible_tables': 0,
            'type_inference_method': 'api_introspection_with_data_sampling',
            'tables': {}
        }
    
    def get_all_tables(self) -> List[str]:
        """Obtém lista de todas as tabelas disponíveis"""
        print("🔍 Descobrindo tabelas disponíveis...")
        
        # Lista de tabelas conhecidas do projeto
        known_tables = [
            'app_users', 'drivers', 'passengers', 'trips', 'trip_requests',
            'notifications', 'activity_logs', 'platform_settings', 
            'operational_cities', 'driver_offers', 'driver_schedules',
            'driver_status', 'available_drivers_view', 'driver_schedule_overrides',
            'withdrawal_requests', 'driver_earnings_view', 'trip_summary_view',
            'user_activity_view', 'payments', 'wallet_transactions',
            'promo_codes', 'user_promos', 'ratings', 'emergency_contacts',
            'support_tickets', 'app_versions'
        ]
        
        # Tentar descobrir tabelas automaticamente
        discovered_tables = set()
        
        for table in known_tables:
            try:
                response = requests.get(
                    f"{self.base_url}/{table}?limit=1",
                    headers=self.headers,
                    timeout=10
                )
                if response.status_code in [200, 206]:  # 206 = Partial Content
                    discovered_tables.add(table)
                    print(f"   ✅ {table}")
                else:
                    print(f"   ❌ {table} (HTTP {response.status_code})")
            except Exception as e:
                print(f"   ❌ {table} (Erro: {str(e)[:50]}...)")
        
        print(f"\n📊 Total de tabelas descobertas: {len(discovered_tables)}")
        return list(discovered_tables)
    
    def infer_column_type(self, value: Any) -> str:
        """Infere o tipo de dados baseado no valor"""
        if value is None:
            return 'nullable'
        
        if isinstance(value, bool):
            return 'boolean'
        
        if isinstance(value, int):
            return 'integer'
        
        if isinstance(value, float):
            return 'numeric'
        
        if isinstance(value, str):
            # Detectar tipos especiais de string
            if '@' in value and '.' in value:
                return 'email (text)'
            elif value.startswith('http://') or value.startswith('https://'):
                return 'url (text)'
            elif value.replace('+', '').replace('-', '').replace('(', '').replace(')', '').replace(' ', '').isdigit():
                return 'phone (text)'
            elif len(value) == 36 and value.count('-') == 4:  # UUID format
                return 'uuid'
            elif 'T' in value and ('Z' in value or '+' in value[-6:]):  # ISO timestamp
                return 'timestamp'
            else:
                return 'text'
        
        return 'unknown'
    
    def get_table_schema_and_data(self, table_name: str) -> Dict[str, Any]:
        """Obtém schema e dados de uma tabela específica"""
        print(f"📋 Analisando tabela: {table_name}")
        
        table_info = {
            'accessible': False,
            'columns': [],
            'column_count': 0,
            'record_count': 0,
            'column_types': {},
            'example_data': None,
            'error': None
        }
        
        try:
            # Primeiro, tentar obter contagem de registros
            count_response = requests.get(
                f"{self.base_url}/{table_name}?select=*&limit=0",
                headers={**self.headers, 'Prefer': 'count=exact'},
                timeout=15
            )
            
            if count_response.status_code == 200:
                content_range = count_response.headers.get('Content-Range', '')
                if content_range and '/' in content_range:
                    total_count = content_range.split('/')[-1]
                    table_info['record_count'] = int(total_count) if total_count.isdigit() else 0
            
            # Obter dados de exemplo para inferir tipos
            data_response = requests.get(
                f"{self.base_url}/{table_name}?limit=1",
                headers=self.headers,
                timeout=15
            )
            
            if data_response.status_code in [200, 206]:
                data = data_response.json()
                
                if data and len(data) > 0:
                    first_record = data[0]
                    table_info['columns'] = list(first_record.keys())
                    table_info['column_count'] = len(first_record.keys())
                    table_info['example_data'] = first_record
                    table_info['accessible'] = True
                    
                    # Inferir tipos de dados
                    for column, value in first_record.items():
                        table_info['column_types'][column] = self.infer_column_type(value)
                    
                    print(f"   ✅ {table_info['column_count']} colunas, {table_info['record_count']} registros")
                    
                    # Mostrar tipos identificados
                    type_counts = defaultdict(int)
                    for col_type in table_info['column_types'].values():
                        type_counts[col_type] += 1
                    
                    types_summary = ", ".join([f"{t}({c})" for t, c in sorted(type_counts.items())])
                    print(f"   🔧 Tipos: {types_summary}")
                    
                else:
                    table_info['accessible'] = True
                    table_info['columns'] = []
                    table_info['column_count'] = 0
                    print(f"   ⚠️  Tabela vazia")
            
            else:
                error_detail = "Acesso negado"
                try:
                    error_data = data_response.json()
                    if 'message' in error_data:
                        error_detail = error_data['message']
                    table_info['error'] = error_data
                except:
                    table_info['error'] = f"HTTP {data_response.status_code}"
                
                print(f"   ❌ Inacessível: {error_detail}")
        
        except Exception as e:
            error_msg = str(e)
            table_info['error'] = error_msg
            print(f"   ❌ Erro: {error_msg}")
        
        return table_info
    
    def export_schema(self, output_file: str = 'supabase_complete_schema.json'):
        """Exporta o schema completo com tipos para JSON"""
        print("🚀 INICIANDO EXPORTAÇÃO COMPLETA DO SCHEMA SUPABASE")
        print("=" * 70)
        
        # Descobrir tabelas
        tables = self.get_all_tables()
        self.schema_data['total_tables'] = len(tables)
        
        print(f"\n📊 Processando {len(tables)} tabelas...")
        print("-" * 50)
        
        accessible_count = 0
        
        # Processar cada tabela
        for table_name in sorted(tables):
            table_info = self.get_table_schema_and_data(table_name)
            self.schema_data['tables'][table_name] = table_info
            
            if table_info['accessible']:
                accessible_count += 1
        
        self.schema_data['accessible_tables'] = accessible_count
        
        # Salvar arquivo JSON
        print(f"\n💾 Salvando schema em: {output_file}")
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(self.schema_data, f, indent=2, ensure_ascii=False, default=str)
        
        # Mostrar resumo final
        print("\n" + "=" * 70)
        print("📊 RESUMO DA EXPORTAÇÃO")
        print("=" * 70)
        print(f"📋 Total de tabelas: {self.schema_data['total_tables']}")
        print(f"✅ Tabelas acessíveis: {self.schema_data['accessible_tables']}")
        print(f"❌ Tabelas inacessíveis: {self.schema_data['total_tables'] - self.schema_data['accessible_tables']}")
        
        # Estatísticas de tipos
        all_types = defaultdict(int)
        total_columns = 0
        
        for table_data in self.schema_data['tables'].values():
            if table_data['accessible'] and table_data['column_types']:
                for col_type in table_data['column_types'].values():
                    all_types[col_type] += 1
                    total_columns += 1
        
        if total_columns > 0:
            print(f"\n🔧 TIPOS DE DADOS IDENTIFICADOS:")
            print("-" * 40)
            print(f"📝 Total de colunas tipadas: {total_columns}")
            
            sorted_types = sorted(all_types.items(), key=lambda x: x[1], reverse=True)
            for col_type, count in sorted_types[:10]:  # Top 10 tipos
                percentage = (count / total_columns) * 100
                print(f"   • {col_type:<20} {count:>3} ({percentage:>5.1f}%)")
        
        print(f"\n💾 Arquivo salvo: {output_file}")
        
        # Mostrar principais tabelas
        accessible_tables = [(name, data) for name, data in self.schema_data['tables'].items() 
                           if data['accessible'] and data['column_types']]
        
        if accessible_tables:
            print(f"\n📋 PRINCIPAIS TABELAS:")
            print("-" * 60)
            
            # Ordenar por complexidade (número de colunas)
            accessible_tables.sort(key=lambda x: x[1]['column_count'], reverse=True)
            
            for name, data in accessible_tables[:10]:  # Top 10 tabelas
                unique_types = len(set(data['column_types'].values()))
                print(f"   📊 {name:<25} | {data['column_count']:>2} colunas | {unique_types} tipos | {data['record_count']:>3} registros")
        
        print(f"\n✅ Exportação completa finalizada!")
        return output_file
    
    def show_summary(self, schema_file: str = 'supabase_complete_schema.json'):
        """Mostra resumo do schema exportado"""
        try:
            with open(schema_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            print("\n" + "=" * 70)
            print("📊 RESUMO DO SCHEMA EXPORTADO")
            print("=" * 70)
            
            print(f"📅 Data da exportação: {data['export_date']}")
            print(f"🌐 URL do Supabase: {data['supabase_url']}")
            print(f"📋 Total de tabelas: {data['total_tables']}")
            print(f"✅ Tabelas acessíveis: {data['accessible_tables']}")
            
            # Listar tabelas acessíveis
            accessible = [(name, info) for name, info in data['tables'].items() if info['accessible']]
            if accessible:
                print(f"\n📋 TABELAS ACESSÍVEIS ({len(accessible)}):")
                print("-" * 60)
                
                for name, info in sorted(accessible, key=lambda x: x[1]['column_count'], reverse=True):
                    types_count = len(set(info['column_types'].values())) if info['column_types'] else 0
                    print(f"   📊 {name:<25} | {info['column_count']:>2} cols | {types_count} tipos | {info['record_count']:>3} regs")
            
            # Listar tabelas inacessíveis
            inaccessible = [(name, info) for name, info in data['tables'].items() if not info['accessible']]
            if inaccessible:
                print(f"\n❌ TABELAS INACESSÍVEIS ({len(inaccessible)}):")
                print("-" * 60)
                
                for name, info in inaccessible:
                    error = info.get('error', 'Erro desconhecido')
                    if isinstance(error, dict) and 'message' in error:
                        error = error['message']
                    print(f"   • {name}: {str(error)[:80]}")
            
        except FileNotFoundError:
            print(f"❌ Arquivo {schema_file} não encontrado!")
        except Exception as e:
            print(f"❌ Erro ao ler arquivo: {e}")

def main():
    """Função principal"""
    try:
        # Verificar variáveis de ambiente
        if not os.getenv('SUPABASE_URL') or not os.getenv('SUPABASE_ANON_KEY'):
            print("❌ ERRO: Variáveis de ambiente não configuradas!")
            print("")
            print("Configure as seguintes variáveis:")
            print("export SUPABASE_URL='sua_url_aqui'")
            print("export SUPABASE_ANON_KEY='sua_chave_aqui'")
            print("")
            print("Ou crie um arquivo .env com:")
            print("SUPABASE_URL=sua_url_aqui")
            print("SUPABASE_ANON_KEY=sua_chave_aqui")
            return
        
        # Criar exportador
        exporter = SupabaseSchemaExporter()
        
        # Exportar schema completo
        output_file = exporter.export_schema()
        
        # Mostrar resumo
        exporter.show_summary(output_file)
        
    except Exception as e:
        print(f"❌ Erro durante a exportação: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()