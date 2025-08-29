# Correção do Mapeamento saved_places

## Problema Identificado
A tabela `saved_places` já existe no Supabase, mas o código Flutter estava usando nomes de campos diferentes:

**Estrutura real da tabela no banco:**
- `label` (text) - para o nome do local
- `category` (varchar) - para o tipo do local
- `user_id`, `address`, `latitude`, `longitude`, `created_at`, `updated_at`

**O que o código estava tentando usar:**
- `name` (esperava este campo, mas o banco tem `label`)
- `type` (esperava este campo, mas o banco tem `category`)

## Correção Aplicada
Foram atualizados os seguintes arquivos para fazer o mapeamento correto:

### 1. lib/models/favorite_location.dart
- `fromJson()`: mapeia `json['label']` → `name` e `json['category']` → `type`
- `toJson()`: mapeia `name` → `'label'` e `type.name` → `'category'`
- `toInsertJson()`: mapeia `name` → `'label'` e `type.name` → `'category'`

### 2. lib/services/real_saved_places_service.dart
- `updatePlace()`: corrigido para usar `'label'` e `'category'` no updateData

## Resultado
Agora o código deve funcionar corretamente com a estrutura existente da tabela `saved_places`, fazendo o mapeamento automático entre:
- Modelo Flutter: `name` ↔ Banco: `label`
- Modelo Flutter: `type` ↔ Banco: `category`

## Teste
Após essas correções, teste novamente o salvamento de locais favoritos. O erro "Could not find the 'name' column" deve ser resolvido.

## Arquivos Desnecessários
- `create_saved_places_table_fixed.sql` - não é mais necessário executar, pois a tabela já existe
- Use apenas o mapeamento de campos corrigido no código