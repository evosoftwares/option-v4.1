# Investigação Detalhada: Fluxo de Salvamento de Locais Favoritos

## 📋 Resumo Executivo

Esta investigação analisou completamente o fluxo de salvamento de locais favoritos na aplicação Flutter, identificando componentes, interações, validações e problemas críticos no sistema.

## 🏗️ Arquitetura do Sistema

### Modelos de Dados

#### 1. `FavoriteLocation` (`lib/models/favorite_location.dart`)
```dart
class FavoriteLocation {
  String? id;
  String userId;
  String name;
  String address;
  LocationType type;
  double? latitude;
  double? longitude;
  String? placeId;
  DateTime? createdAt;
  DateTime? updatedAt;
}
```

#### 2. `SavedPlace` (`lib/services/favorite_locations_service.dart`)
```dart
class SavedPlace {
  String id;
  String userId;        // ✅ Corrigido: usa user_id
  String label;
  String address;
  double latitude;
  double longitude;
  LocationType category;
  DateTime? createdAt;
  DateTime? updatedAt;
}
```

#### 3. `LocationType` (Enum)
- **Tipos disponíveis**: `home`, `work`, `favorite`, `other`, `school`, `gym`, `hospital`, `shopping`, `restaurant`, `airport`, `hotel`, `park`
- **Funcionalidades**: Ícones, rótulos e descrições em português
- **Validação**: CHECK CONSTRAINT na tabela `saved_places`

## 🔄 Fluxos de Salvamento

### Fluxo 1: Através da Tela de Locais Favoritos

#### Componentes Envolvidos:
1. **`SavedPlacesScreen`** - Interface principal
2. **`SavedPlacesController`** - Gerenciamento de estado
3. **`FavoriteLocationsService`** - Serviço de persistência
4. **Tabela `saved_places`** - Armazenamento no Supabase

#### Etapas do Processo:

1. **Inicialização da Tela**
   ```dart
   // SavedPlacesScreen carrega locais existentes
   await _controller.loadSavedPlaces();
   ```

2. **Adição de Novo Local**
   - Usuário clica em "Adicionar local"
   - Abre diálogo modal com campos:
     - Nome do local (obrigatório)
     - Endereço (obrigatório)
     - Categoria (LocationType)
   - Coordenadas definidas como 0,0 (limitação atual)

3. **Validação e Salvamento**
   ```dart
   final success = await _controller.addSavedPlace(
     label: nameController.text,
     address: addressController.text,
     latitude: 0, // Coordenadas padrão
     longitude: 0,
     category: selectedCategory,
   );
   ```

4. **Persistência no Banco**
   ```dart
   // FavoriteLocationsService.addFavoriteLocation()
   await _supabase
     .from('saved_places')
     .insert({
       'user_id': userId,           // ✅ Corrigido: usa user_id
       'label': label,
       'address': address,
       'latitude': latitude,
       'longitude': longitude,
       'category': category.name,   // ✅ Funcional: coluna existe
     });
   ```

### Fluxo 2: Durante o Registro do Usuário (DESABILITADO)

#### Status Atual:
- **REMOVIDO** do fluxo de registro
- Código ainda presente mas não executado
- Comentário no código: "Locais favoritos foram removidos do fluxo de registro"

#### Componentes (Inativos):
1. **`PlacesStep`** - Coleta de locais durante registro
2. **`StepperController.saveFavoriteLocations()`** - Salvamento em lote
3. **`RealSavedPlacesService`** - Serviço alternativo

## 🗄️ Estrutura do Banco de Dados

### Tabela `saved_places` (Schema Real)
```sql
CREATE TABLE saved_places (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,                    -- ✅ Chave estrangeira correta
  label TEXT NOT NULL,
  address TEXT NOT NULL,
  latitude NUMERIC NOT NULL,
  longitude NUMERIC NOT NULL,
  category TEXT NOT NULL DEFAULT 'other',   -- ✅ Coluna existe
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

### ✅ ATUALIZAÇÃO: Estrutura da Tabela Verificada
- **Status**: Tabela `saved_places` está corretamente estruturada
- **Schema Real**: Alinhado com o código da aplicação
- **Funcionalidade**: Operacional

### Políticas de Segurança (RLS)
```sql
-- Usuários só podem ver seus próprios locais
CREATE POLICY "Users can view own saved places" ON saved_places
FOR SELECT USING (user_id = auth.uid());

-- Usuários só podem inserir para si mesmos
CREATE POLICY "Users can insert own saved places" ON saved_places
FOR INSERT WITH CHECK (user_id = auth.uid());

-- Usuários só podem atualizar seus próprios locais
CREATE POLICY "Users can update own saved places" ON saved_places
FOR UPDATE USING (user_id = auth.uid());

-- Usuários só podem deletar seus próprios locais
CREATE POLICY "Users can delete own saved places" ON saved_places
FOR DELETE USING (user_id = auth.uid());
```

## 🔧 Serviços de Persistência

### 1. `SavedPlacesService` (Abordagem JSON)
- **Localização**: `lib/services/saved_places_service.dart`
- **Estratégia**: Salva como JSON na coluna `saved_places` da tabela `app_users`
- **Uso**: Não utilizado atualmente

### 2. `RealSavedPlacesService` (Abordagem Relacional)
- **Localização**: `lib/services/real_saved_places_service.dart`
- **Estratégia**: Usa tabela dedicada `saved_places`
- **Exceções Customizadas**:
  - `ValidationException`
  - `DatabaseException`
  - `NetworkException`

### 3. `FavoriteLocationsService` (Atual)
- **Localização**: `lib/services/favorite_locations_service.dart`
- **Estratégia**: Usa tabela `saved_places`
- **Status**: Serviço principal em uso

## ✅ Validações Implementadas

### Validações de Frontend
1. **Campos obrigatórios**:
   - Nome do local não vazio
   - Endereço não vazio
   - Categoria selecionada

2. **Autenticação**:
   - Usuário deve estar logado
   - Verificação de `auth.currentUser`

### Validações de Backend
1. **RealSavedPlacesService**:
   ```dart
   if (location.userId.isEmpty) {
     throw ValidationException('ID do usuário é obrigatório');
   }
   if (location.name.isEmpty) {
     throw ValidationException('Nome do local é obrigatório');
   }
   if (location.address.isEmpty) {
     throw ValidationException('Endereço do local é obrigatório');
   }
   ```

2. **Constraints de Banco**:
   - `UNIQUE(user_id, label)` - Evita duplicatas
   - `CHECK CONSTRAINT` para categoria (já implementado)

## 🚨 Tratamento de Erros

### Hierarquia de Exceções
```dart
SavedPlacesException (base)
├── ValidationException
├── DatabaseException
└── NetworkException
```

### Tratamento por Camada

#### 1. Controller Layer
```dart
try {
  await FavoriteLocationsService.addFavoriteLocation(...);
  return true;
} catch (e) {
  _setError('Erro ao adicionar local: ${e.toString()}');
  return false;
}
```

#### 2. Service Layer
```dart
try {
  final response = await _supabase.from('saved_places').insert(...);
  return FavoriteLocation.fromJson(response);
} on PostgrestException catch (e) {
  throw DatabaseException('Erro ao salvar: ${e.message}');
} catch (e) {
  throw NetworkException('Erro de conexão');
}
```

#### 3. UI Layer
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(success 
      ? 'Local adicionado com sucesso!' 
      : 'Erro ao adicionar local'),
    backgroundColor: success 
      ? colorScheme.primary
      : colorScheme.error,
  ),
);
```

## 🔍 Problemas Identificados

### 1. **RESOLVIDO: Estrutura do Banco Correta**
- **Status**: Coluna `category` existe e está funcional
- **Impacto**: Sistema operacional
- **Observação**: Schema alinhado com código da aplicação

### 2. **Coordenadas Padrão Inválidas**
- **Problema**: Latitude/longitude definidas como 0,0
- **Impacto**: Locais sem coordenadas reais
- **Solução**: Integrar com serviço de geocodificação

### 3. **Múltiplas Implementações**
- **Problema**: 3 serviços diferentes para mesma funcionalidade
- **Impacto**: Confusão e inconsistência
- **Solução**: Padronizar em uma implementação

### 4. **Fluxo de Registro Incompleto**
- **Problema**: Código para coleta durante registro desabilitado
- **Impacto**: Funcionalidade não disponível
- **Solução**: Reativar ou remover código obsoleto

## 🛠️ Soluções Recomendadas

### 1. ✅ Schema do Banco Verificado
```sql
-- ✅ Coluna category já existe com estrutura correta:
-- - Tipo: TEXT
-- - NOT NULL
-- - Default: 'other'
-- - Constraint: Validação de categorias válidas

-- Constraint existente:
ALTER TABLE saved_places 
ADD CONSTRAINT saved_places_category_check 
CHECK (category IN (
  'home', 'work', 'favorite', 'other', 'school', 
  'gym', 'hospital', 'shopping', 'restaurant', 
  'airport', 'hotel', 'park'
));
```

### 2. Implementar Geocodificação
```dart
// Obter coordenadas reais do endereço
final coordinates = await _locationService.geocodeAddress(address);
final latitude = coordinates['latitude'] ?? 0.0;
final longitude = coordinates['longitude'] ?? 0.0;
```

### 3. Consolidar Serviços
- Manter apenas `FavoriteLocationsService`
- Remover `SavedPlacesService` e `RealSavedPlacesService`
- Migrar funcionalidades necessárias

### 4. Melhorar UX
- Adicionar loading states
- Implementar retry automático
- Melhorar mensagens de erro
- Adicionar validação em tempo real

## 📊 Métricas e Monitoramento

### Logs Implementados
```dart
AppLogger.info('Salvando local favorito para usuário $userId');
AppLogger.error('Erro ao salvar local favorito', error: e);
AppLogger.success('Local favorito salvo com sucesso');
```

### Pontos de Monitoramento
1. Taxa de sucesso no salvamento
2. Tempo de resposta das operações
3. Tipos de erro mais frequentes
4. Uso por tipo de categoria

## 🔮 Próximos Passos

1. **Imediato**: ✅ Schema do banco verificado e correto
2. **Curto prazo**: Implementar geocodificação real
3. **Médio prazo**: Consolidar serviços e melhorar UX
4. **Longo prazo**: Adicionar funcionalidades avançadas (sincronização, backup)

---

**Investigação realizada em**: " + DateTime.now().toString() + "
**Status**: Completa
**Próxima revisão**: Após implementação das correções críticas