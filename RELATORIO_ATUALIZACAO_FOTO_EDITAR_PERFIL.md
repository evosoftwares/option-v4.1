# Relatório: Atualização da Foto de Perfil na Tela Editar Perfil

## 📋 Visão Geral

Este relatório analisa a implementação da funcionalidade de atualização de foto de perfil na tela de edição de perfil (`ProfileEditScreen`), identificando o fluxo atual, problemas encontrados e soluções recomendadas.

## 🔍 Análise da Implementação Atual

### Arquivo: `lib/screens/profile/profile_edit_screen.dart`

#### 1. Seleção de Imagem

**Método:** `_selectImage()`
- **Funcionalidade:** Modal bottom sheet com opções de câmera e galeria
- **Configurações:**
  - Resolução máxima: 1024x1024
  - Qualidade: 85%
  - Armazenamento temporário em `File? _selectedImage`

```dart
final XFile? image = await _picker.pickImage(
  source: source,
  maxWidth: 1024,
  maxHeight: 1024,
  imageQuality: 85,
);
```

#### 2. Upload da Foto

**Método:** `_uploadPhoto()`
- **Problema Identificado:** ❌ Usa bucket `'avatars'` em vez de `'user-photos'`
- **Caminho gerado:** `FileUploadService.generateUserPhotoPath()`
- **Compressão:** Habilitada (`compress: true`)

```dart
final photoUrl = await FileUploadService.uploadImage(
  file: _selectedImage!,
  bucket: 'avatars', // ❌ PROBLEMA: Deveria ser 'user-photos'
  path: photoPath,
  compress: true,
);
```

#### 3. Salvamento no Banco

**Método:** `_onSave()`
- **Fluxo:**
  1. Valida formulário
  2. Faz upload da nova foto (se selecionada)
  3. Chama `UserService.updateUser()` com nova `photoUrl`
  4. Atualiza estado local e exibe feedback

```dart
// Upload da foto se foi selecionada uma nova
String? newPhotoUrl;
if (_selectedImage != null) {
  newPhotoUrl = await _uploadPhoto();
}

final updated = await UserService.updateUser(
  userId: _currentUser!.id,
  fullName: _nameController.text.trim(),
  phone: unformattedPhone,
  userType: _selectedType,
  photoUrl: newPhotoUrl ?? _currentUser!.photoUrl, // Mantém URL atual se não houver nova foto
);
```

## 🚨 Problemas Identificados

### 1. Bucket Incorreto

**Problema:** A tela de editar perfil usa o bucket `'avatars'` em vez de `'user-photos'`

**Impacto:**
- ❌ Inconsistência com o stepper (que usa `'user-photos'`)
- ❌ Possível falha no upload se bucket `'avatars'` não existir
- ❌ Fotos ficam em buckets diferentes dependendo da origem

**Localização:** Linha 148 em `profile_edit_screen.dart`

### 2. Falta de Tratamento de Rollback

**Problema:** Se o upload da foto funcionar mas a atualização no banco falhar, a foto fica "órfã" no storage

**Impacto:**
- ❌ Desperdício de espaço no storage
- ❌ Inconsistência entre storage e banco de dados

### 3. Ausência de Validação de Arquivo

**Problema:** Não há validação específica de tipo de arquivo ou tamanho antes do upload

**Impacto:**
- ❌ Possível upload de arquivos inválidos
- ❌ Experiência do usuário prejudicada

## ✅ Soluções Recomendadas

### 1. Correção do Bucket

**Alteração necessária:**
```dart
// ANTES (❌ Incorreto)
final photoUrl = await FileUploadService.uploadImage(
  file: _selectedImage!,
  bucket: 'avatars',
  path: photoPath,
  compress: true,
);

// DEPOIS (✅ Correto)
final photoUrl = await FileUploadService.uploadImage(
  file: _selectedImage!,
  bucket: 'user-photos', // Usar o mesmo bucket do stepper
  path: photoPath,
  compress: true,
);
```

### 2. Implementação de Rollback

**Melhoria sugerida:**
```dart
Future<void> _onSave() async {
  // ... validações ...
  
  String? newPhotoUrl;
  String? uploadedPhotoPath;
  
  try {
    // Upload da foto se foi selecionada uma nova
    if (_selectedImage != null) {
      newPhotoUrl = await _uploadPhoto();
      uploadedPhotoPath = photoPath; // Salvar caminho para possível rollback
    }

    // Atualizar no banco
    final updated = await UserService.updateUser(
      userId: _currentUser!.id,
      fullName: _nameController.text.trim(),
      phone: unformattedPhone,
      userType: _selectedType,
      photoUrl: newPhotoUrl ?? _currentUser!.photoUrl,
    );
    
    // Sucesso - atualizar estado
    setState(() => _currentUser = updated);
    
  } catch (e) {
    // Se falhou e havia upload, fazer rollback
    if (newPhotoUrl != null && uploadedPhotoPath != null) {
      try {
        await FileUploadService.deleteFile(
          bucket: 'user-photos',
          path: uploadedPhotoPath,
        );
      } catch (deleteError) {
        print('Erro ao fazer rollback da foto: $deleteError');
      }
    }
    
    // Exibir erro
    ScaffoldMessenger.of(context).showSnackBar(/* erro */);
  }
}
```

### 3. Validação de Arquivo

**Adição sugerida:**
```dart
Future<void> _selectImage() async {
  // ... seleção da imagem ...
  
  if (image != null) {
    final file = File(image.path);
    
    // Validar tamanho (ex: máximo 5MB)
    final fileSize = await file.length();
    if (fileSize > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arquivo muito grande. Máximo 5MB.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Validar tipo
    final extension = image.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tipo de arquivo não suportado.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _selectedImage = file);
  }
}
```

## 🔄 Comparação com o Stepper

### Semelhanças
- ✅ Ambos usam `FileUploadService.uploadImage()`
- ✅ Ambos usam `UserService.updateUser()` para salvar no banco
- ✅ Ambos têm tratamento de erros básico

### Diferenças
| Aspecto | Stepper | Editar Perfil |
|---------|---------|---------------|
| **Bucket** | `'user-photos'` ✅ | `'avatars'` ❌ |
| **Momento do Upload** | No `completeRegistration()` | No `_onSave()` |
| **Rollback** | ✅ Implementado | ❌ Ausente |
| **Validação** | ✅ Via `FileUploadService` | ❌ Mínima |
| **Cleanup** | ✅ Remove foto anterior | ❌ Não implementado |

## 📝 Recomendações de Implementação

### Prioridade Alta
1. **Corrigir bucket** de `'avatars'` para `'user-photos'`
2. **Implementar rollback** em caso de falha na atualização do banco
3. **Adicionar validação** de arquivo antes do upload

### Prioridade Média
4. **Implementar cleanup** da foto anterior ao fazer upload de nova
5. **Melhorar feedback** visual durante o upload
6. **Adicionar logs** para debugging

### Prioridade Baixa
7. **Unificar lógica** de upload entre stepper e editar perfil
8. **Criar serviço** dedicado para upload de foto de perfil
9. **Implementar cache** local da imagem

## ✅ Checklist de Correções

- [ ] Alterar bucket de `'avatars'` para `'user-photos'`
- [ ] Implementar rollback em caso de falha
- [ ] Adicionar validação de arquivo
- [ ] Implementar cleanup da foto anterior
- [ ] Melhorar tratamento de erros
- [ ] Adicionar logs de debug
- [ ] Testar fluxo completo
- [ ] Validar consistência com stepper

## 🎯 Conclusão

A implementação atual da atualização de foto de perfil na tela de editar perfil está **funcionalmente correta** mas apresenta **inconsistências importantes** com o sistema do stepper, principalmente o uso do bucket incorreto. As correções sugeridas garantirão:

- ✅ **Consistência** entre diferentes partes do sistema
- ✅ **Robustez** com rollback e validações
- ✅ **Melhor experiência** do usuário
- ✅ **Manutenibilidade** do código

A correção mais crítica é a mudança do bucket para `'user-photos'`, que deve ser implementada imediatamente para evitar inconsistências no armazenamento de fotos.