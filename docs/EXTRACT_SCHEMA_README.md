# Extract Supabase Schema - README

## 📋 Descrição
Script shell para extrair todas as tabelas e campos do Supabase (schema público), gerando um arquivo estruturado com o schema completo.

## 🚀 Instalação e Configuração

### Pré-requisitos
- **curl**: Para requisições HTTP (geralmente já instalado)
- **jq**: Para processamento JSON
  - macOS: `brew install jq`
  - Ubuntu/Debian: `sudo apt-get install jq`
  - CentOS/RHEL: `sudo yum install jq`
- **Supabase CLI** (opcional): Para extração via CLI
  - Instalação: `npm install -g supabase`

### Configuração das Variáveis de Ambiente
Configure as seguintes variáveis no seu `.env` ou exporte diretamente:

```bash
# Método 1: Export direto
export SUPABASE_URL="https://seu-projeto.supabase.co"
export SUPABASE_KEY="sua-chave-de-api"

# Método 2: Usando arquivo .env
echo "SUPABASE_URL=https://seu-projeto.supabase.co" >> .env
echo "SUPABASE_KEY=sua-chave-de-api" >> .env
source .env
```

## 📖 Uso Básico

### Comando simples
```bash
./extract_supabase_schema.sh
```

### Com opções personalizadas
```bash
# Saída em formato texto
./extract_supabase_schema.sh -f text -o schema.txt

# Schema diferente
./extract_supabase_schema.sh -s auth -o auth_schema.json

# Arquivo customizado
./extract_supabase_schema.sh -o meu_schema.json
```

## 📊 Formatos de Saída

### JSON (padrão)
```json
[
  {
    "table_name": "users",
    "columns": [
      {
        "name": "id",
        "type": "uuid",
        "nullable": false,
        "default": "gen_random_uuid()"
      }
    ]
  }
]
```

### Texto estruturado
```
=== SCHEMA DO SUPABASE ===
Schema: public
Data/Hora: Wed Aug 20 08:48:21 -03 2025
==============================

TABELA: users
  - id: uuid (not null) [default: gen_random_uuid()]
  - email: text (not null)
  - created_at: timestamp with time zone (not null) [default: now()]
```

## 🔧 Opções de Linha de Comando

| Opção | Descrição | Exemplo |
|-------|-----------|---------|
| `-o, --output` | Nome do arquivo de saída | `-o meu_schema.json` |
| `-f, --format` | Formato: json ou text | `-f text` |
| `-s, --schema` | Schema a analisar | `-s auth` |
| `-h, --help` | Mostra ajuda | `-h` |

## 🛡️ Tratamento de Erros

O script inclui validação para:
- ✅ Variáveis de ambiente obrigatórias
- ✅ Disponibilidade de ferramentas (curl, jq)
- ✅ Conectividade com Supabase
- ✅ Permissões de API
- ✅ Formato de resposta válido

## 🔄 Fluxo de Execução

1. **Validação**: Verifica variáveis e ferramentas
2. **Detecção**: Identifica se usa CLI ou API REST
3. **Extração**: Busca tabelas e colunas
4. **Processamento**: Formata os dados
5. **Saída**: Salva no arquivo especificado

## 🐛 Solução de Problemas

### Erro: "curl não está instalado"
```bash
# macOS
brew install curl

# Ubuntu/Debian
sudo apt-get install curl
```

### Erro: "jq não está instalado"
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

### Erro: "SUPABASE_URL não está definida"
```bash
export SUPABASE_URL="https://seu-projeto.supabase.co"
```

### Erro de permissão
```bash
chmod +x extract_supabase_schema.sh
```

## 📈 Exemplos Avançados

### Script de backup diário
```bash
#!/bin/bash
# backup_schema.sh
DATE=$(date +%Y%m%d_%H%M%S)
./extract_supabase_schema.sh -o "backup_schema_${DATE}.json"
```

### Integração com CI/CD
```yaml
# .github/workflows/schema-check.yml
- name: Extract Schema
  run: |
    export SUPABASE_URL=${{ secrets.SUPABASE_URL }}
    export SUPABASE_KEY=${{ secrets.SUPABASE_KEY }}
    ./extract_supabase_schema.sh -o schema_snapshot.json
```

## 🔐 Segurança

- **Nunca** commite suas chaves de API
- Use secrets em ambientes de CI/CD
- Considere usar chaves com permissões limitadas
- Revogue chaves comprometidas imediatamente

## 📞 Suporte

Para problemas ou dúvidas:
1. Verifique os logs de erro
2. Confirme as variáveis de ambiente
3. Teste a conectividade manualmente
4. Consulte a documentação oficial do Supabase