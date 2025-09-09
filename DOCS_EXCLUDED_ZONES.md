# Locais Excluídos (Excluded Locations) - Documentação Técnica

## Visão Geral

O sistema de "Locais Excluídos" permite que motoristas definam áreas nas quais não desejam receber corridas. Esta funcionalidade é fundamental para permitir que motoristas tenham controle sobre onde trabalham, excluindo regiões perigosas, de baixa demanda ou onde não desejam atuar.

## Estrutura de Dados

### Modelo: DriverExcludedZone

```dart
class DriverExcludedZone {
  final String id;              // ID único da zona excluída
  final String driverId;        // ID do motorista
  final String neighborhoodName; // Nome do bairro (campo obrigatório)
  final String city;            // Cidade
  final String state;           // Estado
  final DateTime createdAt;     // Data de criação
  final String? keyword;        // Palavra-chave para exclusão flexível (opcional)
  final String? zoneType;       // Tipo da zona: rua, bairro, cidade, estado, regiao (opcional)
}
```

### Estrutura do Banco de Dados

Tabela: `driver_excluded_zones`

```sql
CREATE TABLE driver_excluded_zones (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id uuid NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    neighborhood_name text NOT NULL,  -- Campo obrigatório
    city text NOT NULL,
    state text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    keyword TEXT,  -- Palavra-chave para exclusão flexível
    zone_type TEXT CHECK (zone_type IN ('rua', 'bairro', 'cidade', 'estado', 'regiao'))
);
```

Índices:
- `idx_excluded_zones_driver` (driver_id)
- `idx_excluded_zones_location` (neighborhood_name, city)
- `idx_excluded_zones_keyword` (to_tsvector('portuguese', keyword))
- `idx_excluded_zones_type` (zone_type)

## Funcionamento do Sistema

### 1. Criação de Zonas Excluídas

O processo de criação de zonas excluídas é realizado através da tela `DriverExcludedZonesScreen` e utiliza o serviço `SecureDriverExcludedZonesService`.

#### Processo de Criação:

1. **Seleção do Tipo de Zona**:
   - O motorista escolhe entre: Rua/Avenida, Bairro, Cidade
   - Cada tipo tem uma interface apropriada para entrada de dados

2. **Entrada da Palavra-Chave**:
   - O motorista digita a palavra-chave que representa a zona a ser excluída
   - Exemplos: "Av. Paulista", "Centro", "São Paulo"

3. **Validação e Normalização**:
   - Os dados são validados e normalizados pelo `ZoneValidationService`
   - Verifica-se se o motorista existe
   - Verifica-se o limite de zonas (máximo configurável)

4. **Inserção no Banco de Dados**:
   - A zona é inserida na tabela `driver_excluded_zones`
   - O campo `neighborhood_name` é preenchido com a palavra-chave
   - O campo `keyword` também recebe a palavra-chave
   - O campo `zone_type` recebe o tipo selecionado

5. **Auditoria**:
   - A ação é registrada nos logs através do `ZoneExclusionLogger`
   - Uma entrada é adicionada na tabela `activity_logs`

### 2. Edição de Zonas Excluídas

A edição de zonas excluídas é limitada à remoção, pois o sistema foi projetado para que os motoristas adicionem e removam zonas conforme necessário.

### 3. Exclusão de Zonas Excluídas

A exclusão de zonas excluídas é feita através da interface de usuário ou programaticamente:

1. **Interface de Usuário**:
   - O motorista seleciona uma zona excluída na lista
   - Confirma a remoção através de um diálogo de confirmação
   - A zona é removida do banco de dados

2. **Programaticamente**:
   - `removeExcludedZone(String excludedZoneId)` - Remove uma zona específica
   - `removeMultipleExcludedZones(List<String> excludedZoneIds)` - Remove múltiplas zonas
   - `removeAllExcludedZones(String driverId)` - Remove todas as zonas de um motorista

### 4. Visualização das Zonas Excluídas

A tela `DriverExcludedZonesScreen` exibe todas as zonas excluídas do motorista:

1. **Lista de Zonas**:
   - Mostra todas as zonas excluídas ordenadas por data de criação
   - Utiliza a propriedade `displayName` para exibição adequada
   - Para zonas com `keyword`: "Palavra-chave (Tipo)"
   - Para zonas legadas: "Bairro, Cidade - Estado"

2. **Atualização em Tempo Real**:
   - Utiliza streams para atualização automática quando zonas são adicionadas/removidas

## Sistema de Matchmaking

O sistema de matchmaking utiliza as zonas excluídas para filtrar motoristas que não estão disponíveis para corridas em determinadas áreas.

### Processo de Filtragem:

1. **Identificação de Áreas**:
   - Extrai bairro, cidade e estado da origem e destino da corrida
   - Constrói endereços completos para verificação

2. **Verificação de Exclusões**:
   - Utiliza a função SQL `check_address_exclusion(driver_id, full_address)` para verificar se um motorista excluiu uma área
   - Verifica tanto origem quanto destino da corrida

3. **Filtragem de Motoristas**:
   - Remove da lista de motoristas disponíveis aqueles que excluíram a origem OU o destino da corrida
   - Se a verificação falhar, o sistema usa um fallback com busca por palavras-chave

### Funções SQL:

```sql
-- Verifica se um endereço está na lista de exclusões do motorista
CREATE OR REPLACE FUNCTION check_address_exclusion(
  driver_id_param UUID,
  full_address TEXT
) 
RETURNS BOOLEAN 
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check if any keywords from driver exclusions match the address
  RETURN EXISTS (
    SELECT 1 
    FROM public.driver_excluded_zones dez
    WHERE dez.driver_id = driver_id_param
    AND (
      -- Keyword-based matching (new system)
      (dez.keyword IS NOT NULL AND lower(full_address) LIKE '%' || lower(dez.keyword) || '%')
      OR
      -- Legacy neighborhood matching (backward compatibility)
      (dez.keyword IS NULL AND lower(full_address) LIKE '%' || lower(dez.neighborhood_name) || '%')
    )
  );
END;
$$;

-- Retorna motoristas que excluíram um endereço específico
CREATE OR REPLACE FUNCTION get_excluded_drivers_for_address(
  full_address TEXT
) 
RETURNS TABLE(driver_id UUID, exclusion_reason TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    dez.driver_id,
    CASE 
      WHEN dez.keyword IS NOT NULL 
      THEN 'Palavra-chave: ' || dez.keyword || ' (' || COALESCE(dez.zone_type, 'não especificado') || ')'
      ELSE 'Bairro: ' || dez.neighborhood_name || ' (sistema legado)'
    END as exclusion_reason
  FROM public.driver_excluded_zones dez
  WHERE 
    (dez.keyword IS NOT NULL AND lower(full_address) LIKE '%' || lower(dez.keyword) || '%')
    OR 
    (dez.keyword IS NULL AND lower(full_address) LIKE '%' || lower(dez.neighborhood_name) || '%');
END;
$$;
```

## Segurança e Validações

### Validações Implementadas:

1. **Validação de Dados**:
   - Todos os dados são normalizados e validados antes da inserção
   - Verificação de existência do motorista
   - Limites de caracteres e formato

2. **Prevenção de Concorrência**:
   - Uso de verificações antes da inserção para evitar duplicatas
   - Tratamento adequado de erros de chave única

3. **Limites**:
   - Limite máximo configurável de zonas excluídas por motorista
   - Verificação antes da adição de novas zonas

4. **Auditoria**:
   - Todos os eventos são registrados com logs detalhados
   - Registros em `activity_logs` para auditoria

## Compatibilidade Reversa

O sistema mantém compatibilidade total com versões anteriores:

- Zonas legadas sem `keyword`/`zone_type` continuam funcionando
- Zonas legadas são exibidas como "Bairro, Cidade - Estado"
- Novas zonas são exibidas como "Palavra-chave (Tipo)"
- A migração de banco de dados é automática

## Testes

O sistema inclui testes abrangentes:

1. **Testes de Modelo**:
   - Conversão de JSON para objeto e vice-versa
   - Validação de propriedades e métodos
   - Testes de igualdade e cópia

2. **Testes de Serviço**:
   - Validação de entrada de dados
   - Testes de limite de zonas
   - Testes de manipulação de banco de dados
   - Testes de tratamento de erros

3. **Testes de Integração**:
   - Fluxo completo de adição/remoção de zonas
   - Testes de filtragem no sistema de matchmaking
   - Testes de compatibilidade reversa

## Performance

1. **Indexação**:
   - Índices otimizados para consultas frequentes
   - Indexação full-text para busca por palavras-chave

2. **Caching**:
   - O serviço de matching utiliza cache para consultas repetidas
   - Cache com duração configurável (padrão: 2 minutos)

3. **Streaming**:
   - Atualização em tempo real da interface
   - Redução de chamadas desnecessárias ao servidor

## Considerações Finais

O sistema de "Locais Excluídos" é uma funcionalidade crítica para a experiência do motorista, permitindo controle total sobre onde atuar. A implementação atual oferece:

1. **Flexibilidade**: Sistema de palavras-chave permite exclusões granulares
2. **Segurança**: Validações rigorosas e auditoria completa
3. **Performance**: Indexação otimizada e caching
4. **Compatibilidade**: Manutenção de funcionalidade com versões anteriores
5. **Usabilidade**: Interface intuitiva e feedback claro ao usuário

A integração com o sistema de matchmaking garante que passageiros recebam motoristas disponíveis para suas áreas, respeitando as preferências dos motoristas.