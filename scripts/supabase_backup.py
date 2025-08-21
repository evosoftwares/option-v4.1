#!/usr/bin/env python3
"""
Script para backup completo do banco de dados Supabase
"""
import os
import subprocess
import datetime
import sys
from pathlib import Path

# Configurações do Supabase (extraídas do .env)
SUPABASE_URL = "https://qlbwacmavngtonauxnte.supabase.co"
SUPABASE_SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk"

# Extrair host e database da URL
def extract_connection_params(url):
    """Extrai host, port e database name da URL do Supabase"""
    # URL format: postgresql://postgres:[PASSWORD]@aws-0-us-east-1.pooler.supabase.com:5432/postgres
    # Para Supabase, usamos a conexão direta do PostgreSQL
    host = "aws-0-us-east-1.pooler.supabase.com"
    port = 5432
    database = "postgres"
    user = "postgres"
    
    # Senha precisa ser obtida das variáveis de ambiente ou configurada manualmente
    password = os.getenv('SUPABASE_DB_PASSWORD')
    if not password:
        # Se não estiver nas variáveis, tentar extrair do service role key ou pedir
        print("⚠️  A senha do banco de dados PostgreSQL não foi encontrada.")
        print("   Por favor, configure a variável SUPABASE_DB_PASSWORD")
        print("   ou use a senha fornecida no painel do Supabase.")
    
    return host, port, database, user, password

def create_backup():
    """Cria backup completo do banco de dados"""
    
    # Criar diretório de backups se não existir
    backup_dir = Path("backups")
    backup_dir.mkdir(exist_ok=True)
    
    # Gerar nome do arquivo com timestamp
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    backup_file = backup_dir / f"supabase_backup_{timestamp}.sql"
    
    print(f"🔄 Iniciando backup do Supabase...")
    print(f"📁 Arquivo de saída: {backup_file}")
    
    # Extrair parâmetros de conexão
    host, port, database, user, password = extract_connection_params(SUPABASE_URL)
    
    if not password:
        # Tentar obter senha interativamente
        import getpass
        password = getpass.getpass("Digite a senha do banco de dados PostgreSQL: ")
    
    # Comando pg_dump para backup completo
    pg_dump_cmd = [
        "pg_dump",
        f"--host={host}",
        f"--port={port}",
        f"--username={user}",
        f"--dbname={database}",
        "--no-password",
        "--verbose",
        "--clean",  # Adiciona DROP TABLE antes de CREATE TABLE
        "--if-exists",
        "--create",  # Inclui CREATE DATABASE
        "--no-owner",  # Remove comandos de ALTER OWNER
        "--no-privileges",  # Remove comandos de GRANT/REVOKE
        "--data-only",  # Apenas dados (para teste, depois removeremos)
    ]
    
    # Para backup completo (estrutura + dados), remover --data-only
    full_backup_cmd = [
        "pg_dump",
        f"--host={host}",
        f"--port={port}",
        f"--username={user}",
        f"--dbname={database}",
        "--no-password",
        "--verbose",
        "--clean",
        "--if-exists",
        "--create",
        "--no-owner",
        "--no-privileges",
    ]
    
    # Configurar variável de ambiente para senha
    env = os.environ.copy()
    env['PGPASSWORD'] = password
    
    try:
        print("🔄 Executando pg_dump...")
        
        # Executar comando de backup
        with open(backup_file, 'w') as f:
            result = subprocess.run(
                full_backup_cmd,
                env=env,
                stdout=f,
                stderr=subprocess.PIPE,
                text=True
            )
        
        if result.returncode == 0:
            print(f"✅ Backup criado com sucesso: {backup_file}")
            
            # Verificar tamanho do arquivo
            file_size = backup_file.stat().st_size
            print(f"📊 Tamanho do arquivo: {file_size / 1024 / 1024:.2f} MB")
            
            # Listar tabelas no backup (verificação básica)
            with open(backup_file, 'r') as f:
                content = f.read()
                if "CREATE TABLE" in content or "INSERT INTO" in content:
                    print("✅ Arquivo contém estrutura e/ou dados válidos")
                else:
                    print("⚠️  Arquivo parece estar vazio ou não contém dados esperados")
            
            return str(backup_file)
        else:
            print(f"❌ Erro ao criar backup: {result.stderr}")
            return None
            
    except FileNotFoundError:
        print("❌ pg_dump não encontrado. Instale o PostgreSQL client tools:")
        print("   macOS: brew install postgresql")
        print("   Ubuntu/Debian: sudo apt-get install postgresql-client")
        print("   Windows: Baixe do site oficial do PostgreSQL")
        return None
    except Exception as e:
        print(f"❌ Erro inesperado: {str(e)}")
        return None

def main():
    """Função principal"""
    print("🚀 Script de Backup do Supabase")
    print("=" * 40)
    
    # Verificar se pg_dump está disponível
    try:
        subprocess.run(["pg_dump", "--version"], 
                      stdout=subprocess.PIPE, 
                      stderr=subprocess.PIPE, 
                      check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ pg_dump não está disponível no sistema")
        return
    
    # Criar backup
    backup_file = create_backup()
    
    if backup_file:
        print("\n🎉 Backup concluído com sucesso!")
        print(f"📁 Arquivo salvo em: {backup_file}")
    else:
        print("\n❌ Falha ao criar backup")
        sys.exit(1)

if __name__ == "__main__":
    main()