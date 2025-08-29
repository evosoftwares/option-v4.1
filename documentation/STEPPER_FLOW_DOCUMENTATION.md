# 📋 Documentação Completa do Fluxo Stepper - Sistema de Cadastro OPTION

## 🎯 Visão Geral

O sistema stepper é o núcleo do processo de cadastro/registro do aplicativo OPTION, responsável por coletar dados do usuário de forma progressiva e intuitiva. O fluxo é diferenciado entre motoristas e passageiros, com persistência automática para garantir que interrupções não resultem em perda de dados.

## 🏗️ Arquitetura do Sistema

### Componentes Principais

1. **StepperController** - Controlador de estado global
2. **UserRegistrationStepper** - Interface principal do fluxo
3. **StepperPersistenceService** - Serviço de persistência local
4. **Steps individuais** - PhoneStep, PhotoStep, PlacesStep
5. **Integração Supabase** - Auth + Database + Storage

### Diagrama de Fluxo

```
Register Screen → UserType Screen → Stepper Flow → Home Screen
     ↓               ↓                    ↓            ↓
[auth.signUp]  [select type]     [collect data]  [app ready]
     ↓               ↓                    ↓            ↓
auth.users     [store in state]    [create user]  [navigate]
                     ↓                    ↓
                [persist data]      [save locations]
```

## 🔄 Fluxo Detalhado de Navegação

### 1. Início do Processo
```
/register → /select_user_type → /registration_stepper
```

**Dados transferidos entre telas:**
- `fullName` (do registro)
- `email` (do registro) 
- `userType` (seleção do usuário)

### 2. Estados do StepperController

```dart
class StepperController extends ChangeNotifier {
  // Estados principais
  int _currentStep = 0;           // 0, 1, 2
  String? _userType;              // 'passenger' | 'driver'  
  String? _phone;                 // telefone com máscara
  String? _fullName;              // nome completo
  String? _email;                 // email do usuário
  File? _profilePhoto;            // foto selecionada
  String? _uploadedPhotoUrl;      // URL após upload
  List<FavoriteLocation> _favoriteLocations = [];
  
  // Estados auxiliares
  bool _isUploadingPhoto = false;
  String? _uploadedPhotoPath;
}
```

## 📱 Detalhamento dos Steps

### Step 0: Telefone (PhoneStep)
**Localização:** `lib/screens/stepper/phone_step.dart`

**Funcionalidades:**
- Coleta número de telefone brasileiro
- Validação com regex específica
- Formatação automática com máscara `(00) 00000-0000`
- Prefixo fixo `+55`

**Fluxo técnico:**
```dart
// Validação
String? _validatePhone(String? value) => PhoneValidator.validate(value);

// Salvamento no controller
controller.setPhone(phone);

// Auto-persistência
StepperPersistenceService.saveStepperState(phone: phone);
```

**Dados salvos:**
- `phone`: String formatada

### Step 1: Foto (PhotoStep)
**Localização:** `lib/screens/stepper/photo_step.dart`

**Funcionalidades:**
- Seleção via câmera ou galeria
- Redimensionamento automático (800x800px, 85% qualidade)
- Upload para Supabase Storage bucket `user-photos`
- Cleanup automático de fotos anteriores

**Fluxo técnico:**
```dart
// Upload com cleanup
final photoUrl = await FileUploadService.uploadImage(
  file: _profilePhoto!,
  bucket: 'user-photos',
  path: storagePath,
);

// Path gerado automaticamente
String storagePath = "users/{userId}/profile/{timestamp}_{filename}"
```

**Dados salvos:**
- `profilePhoto`: File local
- `uploadedPhotoUrl`: String (URL do Storage)
- `uploadedPhotoPath`: String (path interno)

### Step 2: Locais Favoritos (PlacesStep)
**Localização:** `lib/screens/stepper/places_step.dart`

**Comportamento diferenciado:**
- **Passageiros**: Coletam locais favoritos
- **Motoristas**: Pulam automaticamente este step

**Funcionalidades (apenas passageiros):**
- Integração com PlacePickerScreen
- Geocodificação automática de endereços
- Suporte a múltiplos locais
- Categorização por tipo (casa, trabalho, etc.)

**Fluxo técnico:**
```dart
// Adicionar local com geocodificação
final geocodeResult = await _locationService.geocodeAddress(address);
final location = FavoriteLocation(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  name: name,
  address: finalAddress,
  type: type,
  latitude: latitude,
  longitude: longitude,
);
```

**Dados coletados (❌ NÃO SALVOS NO BANCO):**
- `favoriteLocations`: List<FavoriteLocation> - apenas em memória local

## 💾 Sistema de Persistência

### StepperPersistenceService
**Localização:** `lib/services/stepper_persistence_service.dart`

**Estratégia:**
- Usar SharedPreferences para persistência local
- Auto-save em mudanças críticas (userType, phone)
- Serialização JSON para objetos complexos
- Cleanup automático após sucesso

**Chaves de persistência:**
```dart
static const String _keyUserType = 'stepper_user_type';
static const String _keyPhone = 'stepper_phone';  
static const String _keyFullName = 'stepper_full_name';
static const String _keyEmail = 'stepper_email';
static const String _keyCurrentStep = 'stepper_current_step';
static const String _keyFavoriteLocations = 'stepper_favorite_locations';
static const String _keyUploadedPhotoUrl = 'stepper_uploaded_photo_url';
```

**Métodos principais:**
```dart
// Salvar estado
static Future<void> saveStepperState({...});

// Carregar estado  
static Future<Map<String, dynamic>> loadStepperState();

// Verificar se existe estado
static Future<bool> hasPersistedState();

// Limpar após sucesso
static Future<void> clearStepperState();
```

## 🏁 Finalização do Cadastro

### Processo completeRegistration()

**Localização:** `StepperController.completeRegistration()`

**Fluxo completo:**
1. **Validação de dados obrigatórios**
2. **Upload de foto** (se necessário)  
3. **Verificação de usuário existente**
4. **Criação do app_user**
5. **❌ Salvamento de locais favoritos** - FUNCIONALIDADE QUEBRADA
6. **Limpeza de dados persistidos**
7. **Navegação final**

**Código técnico:**
```dart
Future<bool> completeRegistration() async {
  // 1. Validações
  if (email == null || _fullName == null || _userType == null) {
    throw Exception('Dados obrigatórios ausentes');
  }
  
  // 2. Upload foto
  if (hasProfilePhoto() && _uploadedPhotoUrl == null) {
    photoUrl = await uploadProfilePhoto();
  }
  
  // 3. Verificar existência
  final exists = await UserService.userExists(authUser.id);
  
  // 4. Criar usuário se não existe
  if (!exists) {
    await UserService.createUser(
      authUserId: authUser.id,
      email: email,
      fullName: _fullName!,
      phone: _phone,
      photoUrl: photoUrl,
      userType: _userType!,
    );
  }
  
  // 5. ❌ PROBLEMA: Salvar locais (passageiros) - FUNCIONALIDADE QUEBRADA
  if (_favoriteLocations.isNotEmpty && _userType == 'passenger') {
    // ❌ ATENÇÃO: _saveFavoriteLocations() falhará pois tabela saved_places não existe
    try {
      await _saveFavoriteLocations(authUser.id);
    } catch (e) {
      // ⚠️ Erro esperado: tabela não existe no banco
      print('❌ Erro ao salvar locais (funcionalidade não implementada): $e');
    }
  }
  
  // 6. Cleanup
  await StepperPersistenceService.clearStepperState();
  
  return true;
}
```

## 📊 Fluxo de Dados

### Mapeamento Completo dos Dados

| Campo | Origem | Validação | Destino Final |
|-------|--------|-----------|---------------|
| `email` | Register Screen | Email regex | `app_users.email` |
| `fullName` | Register Screen | Nome válido | `app_users.full_name` |  
| `userType` | UserType Screen | 'passenger'/'driver' | `app_users.user_type` |
| `phone` | PhoneStep | Phone regex BR | `app_users.phone` (OBRIGATÓRIO) |
| `photoUrl` | PhotoStep | Upload Storage | `app_users.photo_url` (opcional) |
| `favoriteLocations` | PlacesStep | Geocoding | ❌ **NÃO PERSISTIDO** ❌ |

### Relacionamentos de Banco

```sql
-- Fluxo REAL de criação
auth.users (Supabase Auth)
    ↓ [id referenciado]
app_users.user_id (referência opcional ao auth.users.id)
    ↓ 
❌ LOCAIS FAVORITOS: Não são persistidos no banco ❌
```

### ⚠️ **LIMITAÇÃO CRÍTICA IDENTIFICADA:**
A funcionalidade de locais favoritos **coleta dados mas NÃO os persiste** no banco de dados. A tabela `saved_places` mencionada no código não existe no schema atual do Supabase.

## 🚨 Tratamento de Casos Extremos

### 1. Interrupção Durante Upload de Foto
**Problema:** App fechado durante upload  
**Solução:** 
- File local mantido no controller
- Retry automático no próximo acesso
- Cleanup de uploads parciais

### 2. Falha na Geocodificação
**Problema:** Endereço não encontrado  
**Solução:**
- Salvar local sem coordenadas
- Retry durante salvamento final
- Ignorar locais sem coordenadas válidas

### 3. Dados Persistidos Corrompidos
**Problema:** JSON inválido em SharedPreferences  
**Solução:**
```dart
try {
  final locationsData = jsonDecode(locationsJson) as List;
  favoriteLocations = locationsData
      .map((data) => FavoriteLocation.fromJson(data))
      .toList();
} catch (e) {
  AppLogger.warning('Erro ao deserializar locais favoritos');
  // Continuar com lista vazia
}
```

### 4. Usuário Já Existe no Banco
**Problema:** Processo executado múltiplas vezes  
**Solução:**
- Verificação `UserService.userExists()`
- Update apenas de campos necessários (ex: photo_url)
- Skip da criação se já existe

### 5. 🚨 **PROBLEMA CRÍTICO: Locais Favoritos Não Persistem**
**Problema:** Funcionalidade coleta dados mas não salva no banco
**Causa raiz:** Tabela `saved_places` não existe no schema Supabase
**Impacto:** 
- Passageiros perdem tempo coletando dados inúteis
- Erro de runtime ao tentar salvar
- Experiência de usuário quebrada

**Soluções possíveis:**
1. **Criar tabela missing:**
```sql
CREATE TABLE saved_places (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES app_users(user_id),
  label TEXT NOT NULL,
  address TEXT NOT NULL,
  latitude NUMERIC NOT NULL,
  longitude NUMERIC NOT NULL,
  category TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

2. **Desabilitar funcionalidade:** Pular step de locais para todos os usuários
3. **Implementar alternativa:** Usar JSON field em `app_users` para locais

## 🔍 Debugging e Logs

### Sistema de Logging Integrado
- **AppLogger.stepper()** - Eventos específicos do stepper
- **AppLogger.upload()** - Upload de arquivos  
- **AppLogger.persistence()** - Operações de persistência
- **AppLogger.auth()** - Eventos de autenticação

### Pontos Críticos de Debug
```dart
// Estado do controller
print('🔍 [DEBUG] Estado completo do StepperController:');
print('  - _fullName: "$_fullName"');
print('  - _email: "$_email"');  
print('  - _phone: "$_phone"');
print('  - _userType: "$_userType"');

// Processo de salvamento
print('📍 Salvando local ${i + 1}/${_favoriteLocations.length}: ${location.name}');
print('✅ Local "${location.name}" salvo com sucesso! ID: ${savedPlace.id}');
```

## ⚡ Performance e Otimizações

### Estratégias Implementadas

1. **Auto-save Inteligente:**
   - Apenas dados críticos (userType, phone) 
   - Save sob demanda para dados pesados

2. **Upload Otimizado:**
   - Redimensionamento automático de imagens
   - Cleanup de arquivos anteriores
   - Upload assíncrono com loading states

3. **Navegação Fluida:**
   - PageController com animações suaves
   - Estados de loading adequados
   - Validações não-bloqueantes

## 🧪 Casos de Teste Recomendados

### Cenários de Teste

1. **Fluxo Completo Passageiro:**
   - Telefone → Foto → 3 locais → Finalização
   
2. **Fluxo Completo Motorista:**
   - Telefone → Foto → Auto-finalização

3. **Interrupção e Recuperação:**
   - Fechar app no step 1, reabrir, verificar dados
   
4. **Falhas de Rede:**
   - Upload com conexão instável
   - Geocoding offline
   
5. **Dados Inválidos:**
   - Telefones malformados
   - Locais com endereços inexistentes

## 📚 Referências Técnicas

### Arquivos Principais
- `lib/controllers/stepper_controller.dart` - Controller principal
- `lib/screens/stepper/user_registration_stepper.dart` - Interface 
- `lib/services/stepper_persistence_service.dart` - Persistência
- `lib/screens/stepper/phone_step.dart` - Step telefone
- `lib/screens/stepper/photo_step.dart` - Step foto  
- `lib/screens/stepper/places_step.dart` - Step locais

### Dependências Externas
- `shared_preferences: ^2.2.2` - Persistência local
- `image_picker: ^1.0.5` - Seleção de fotos
- `supabase_flutter: ^2.5.6` - Backend e storage
- `provider: ^6.1.1` - Gerenciamento de estado

### Configurações Requeridas
- Permissões de câmera e galeria
- Configuração Supabase (URL, anon key)
- Bucket `user-photos` no Supabase Storage
- Google Maps API key para geocoding

### ⚠️ **Configurações Missing (CRÍTICAS):**
- **Tabela `saved_places`** - necessária para persistir locais favoritos
- **Relacionamento correto** entre `auth.users.id` e `app_users.user_id`

---

## 🏆 Conclusão

O sistema stepper do OPTION representa uma implementação **parcialmente funcional** de coleta progressiva de dados. Embora a arquitetura seja sólida, há uma **inconsistência crítica** entre o código e o schema do banco de dados:

### ✅ **Funcional:**
- Coleta de dados básicos (nome, email, telefone, foto)
- Persistência local durante o processo
- Upload seguro de fotos
- Fluxo diferenciado motorista/passageiro

### ❌ **Problema Crítico:**
- **Locais favoritos não são persistidos** devido à ausência da tabela `saved_places`
- Funcionalidade coleta dados mas falha silenciosamente no salvamento
- Experiência de usuário incompleta para passageiros

### 🔧 **Ação Requerida:**
1. **Implementar tabela `saved_places`** no Supabase
2. **Ou desabilitar** coleta de locais favoritos  
3. **Ou usar alternativa** (JSON field em `app_users`)

**Última atualização:** 26/08/2025  
**Versão da documentação:** 1.1 (Corrigida)  
**Status do sistema:** ⚠️ **Parcialmente funcional** - requer correção do banco