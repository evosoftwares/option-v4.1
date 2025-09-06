// =============================================
// IMPLEMENTAÇÃO COMPLETA: UPLOAD DE FOTO DE PERFIL
// =============================================
// Usando Firebase Storage para armazenamento de imagens
// Usando bucket 'user-photos' e UserService existente
// =============================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../lib/exceptions/app_exceptions.dart';
import '../../lib/services/user_service.dart';
import '../../lib/services/firebase_file_upload_service.dart';

class ProfilePhotoUploadService {
  static const String _bucketName = 'user-photos'; // Bucket Firebase Storage
  
  /// Upload completo: selecionar imagem + upload + atualizar banco
  static Future<String?> uploadProfilePhoto(String userId) async {
    try {
      // 1. Selecionar imagem
      final imageFile = await _selectImage();
      if (imageFile == null) {
        print('📸 Upload cancelado pelo usuário');
        return null;
      }
      
      // 2. Upload para Firebase Storage
      final photoUrl = await _uploadToStorage(userId, imageFile);
      if (photoUrl == null) {
        throw Exception('Falha no upload da imagem');
      }
      
      // 3. Atualizar photo_url no banco
      final success = await _updatePhotoUrlInDatabase(userId, photoUrl);
      if (!success) {
        // Se falhou ao atualizar banco, remover arquivo do storage
        await _removeFromStorage(userId, photoUrl);
        throw Exception('Falha ao atualizar photo_url no banco');
      }
      
      print('✅ Upload completo! URL: $photoUrl');
      return photoUrl;
      
    } catch (e) {
      print('❌ Erro no upload: $e');
      rethrow;
    }
  }
  
  /// Seleciona imagem da galeria ou câmera
  static Future<File?> _selectImage() async {
    try {
      final picker = ImagePicker();
      
      // Mostrar opções: Galeria ou Câmera
      final source = await _showImageSourceDialog();
      if (source == null) return null;
      
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
      
    } catch (e) {
      print('❌ Erro ao selecionar imagem: $e');
      return null;
    }
  }
  
  /// Upload da imagem para o Firebase Storage
  static Future<String?> _uploadToStorage(String userId, File imageFile) async {
    try {
      // Gerar nome único para o arquivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_${userId}_$timestamp.jpg';
      final uploadPath = 'profiles/$fileName';
      
      print('📤 Fazendo upload: $uploadPath');
      
      // Upload usando FirebaseFileUploadService
      final publicUrl = await FirebaseFileUploadService.uploadImage(
        file: imageFile,
        folder: _bucketName,
        path: uploadPath,
      );
      
      print('✅ Upload realizado: $publicUrl');
      return publicUrl;
      
    } on FirebaseFileUploadException catch (e) {
      print('❌ Erro de Firebase Storage: ${e.message}');
      return null;
    } catch (e) {
      print('❌ Erro no upload: $e');
      return null;
    }
  }
  
  /// Atualiza photo_url no banco usando UserService (sem RLS)
  static Future<bool> _updatePhotoUrlInDatabase(String userId, String photoUrl) async {
    try {
      // Usar UserService existente que já funciona sem RLS
      await UserService.updateUser(
        userId: userId,
        photoUrl: photoUrl,
      );
      
      print('✅ photo_url atualizado no banco');
      return true;
      
    } on UserNotFoundException catch (e) {
      print('❌ Usuário não encontrado: $e');
      return false;
      
    } on DatabaseException catch (e) {
      print('❌ Erro de banco: ${e.message}');
      return false;
      
    } catch (e) {
      print('❌ Erro inesperado: $e');
      return false;
    }
  }
  
  /// Remove arquivo do storage em caso de erro
  static Future<void> _removeFromStorage(String userId, String photoUrl) async {
    try {
      // Extrair path do URL do Firebase Storage
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      
      // Para URLs do Firebase Storage, o path está após '/o/'
      final oIndex = pathSegments.indexOf('o');
      if (oIndex != -1 && oIndex < pathSegments.length - 1) {
        final encodedPath = pathSegments[oIndex + 1];
        final decodedPath = Uri.decodeComponent(encodedPath);
        
        // Extrair folder e path
        final pathParts = decodedPath.split('/');
        if (pathParts.length >= 2) {
          final folder = pathParts[0];
          final filePath = pathParts.sublist(1).join('/');
          
          await FirebaseFileUploadService.deleteFile(
            folder: folder,
            path: filePath,
          );
          
          print('🗑️ Arquivo removido do Firebase Storage: $filePath');
        }
      }
    } catch (e) {
      print('⚠️ Erro ao remover arquivo: $e');
    }
  }
  
  /// Mostra dialog para escolher fonte da imagem
  static Future<ImageSource?> _showImageSourceDialog() async {
    // Esta função deve ser chamada em um contexto com BuildContext
    // Por simplicidade, retornando galeria por padrão
    return ImageSource.gallery;
  }
}

// =============================================
// WIDGET PARA EXIBIR FOTO DE PERFIL
// =============================================

class ProfilePhotoWidget extends StatelessWidget {
  
  const ProfilePhotoWidget({
    super.key,
    this.photoUrl,
    this.size = 80,
    this.onTap,
  });
  final String? photoUrl;
  final double size;
  final VoidCallback? onTap;
  
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: ClipOval(
          child: _buildImage(),
        ),
      ),
    );
  
  Widget _buildImage() {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return Image.network(
        photoUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ Erro ao carregar imagem: $error');
          return _buildPlaceholder();
        },
      );
    }
    return _buildPlaceholder();
  }
  
  Widget _buildPlaceholder() => ColoredBox(
      color: Colors.grey.shade200,
      child: Icon(
        Icons.account_circle,
        size: size * 0.6,
        color: Colors.grey.shade400,
      ),
    );
}

// =============================================
// EXEMPLO DE USO COMPLETO
// =============================================

class ProfilePhotoExample extends StatefulWidget {
  const ProfilePhotoExample({super.key});

  @override
  _ProfilePhotoExampleState createState() => _ProfilePhotoExampleState();
}

class _ProfilePhotoExampleState extends State<ProfilePhotoExample> {
  String? _currentPhotoUrl;
  bool _isUploading = false;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentPhoto();
  }
  
  /// Carrega foto atual do usuário
  Future<void> _loadCurrentPhoto() async {
    try {
      // TODO: Implementar carregamento da foto usando UserService
      // final user = await UserService.getCurrentUser();
      // if (user != null) {
      //   setState(() {
      //     _currentPhotoUrl = user.photoUrl;
      //   });
      // }
    } catch (e) {
      print('❌ Erro ao carregar foto atual: $e');
    }
  }
  
  /// Inicia processo de upload
  Future<void> _uploadPhoto() async {
    try {
      setState(() {
        _isUploading = true;
      });
      
      // TODO: Obter usuário atual usando UserService
      // final currentUser = await UserService.getCurrentUser();
      // if (currentUser == null) {
      //   throw Exception('Usuário não autenticado');
      // }
      // final userId = currentUser.id;
      
      // Simulação para exemplo - substitua pela implementação real
      const userId = 'user_id_example';
      
      // Upload da foto
      final newPhotoUrl = await ProfilePhotoUploadService.uploadProfilePhoto(userId);
      
      if (newPhotoUrl != null) {
        setState(() {
          _currentPhotoUrl = newPhotoUrl;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Foto de Perfil'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Widget da foto
            ProfilePhotoWidget(
              photoUrl: _currentPhotoUrl,
              size: 120,
              onTap: _isUploading ? null : _uploadPhoto,
            ),
            
            const SizedBox(height: 20),
            
            // Botão de upload
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadPhoto,
              icon: _isUploading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(
                _isUploading ? 'Enviando...' : 'Alterar Foto',
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Info da URL atual
            if (_currentPhotoUrl != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'URL: $_currentPhotoUrl',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
}

// =============================================
// CHECKLIST DE VERIFICAÇÃO
// =============================================

/*
✅ CHECKLIST PARA IMPLEMENTAÇÃO:

1. [ ] Bucket 'user-photos' criado e configurado (público)
2. [ ] RLS desabilitado na tabela app_users
3. [ ] Permissões UPDATE concedidas para anon/authenticated
4. [ ] Coluna photo_url existe na tabela app_users
5. [ ] UserService.updateUser() funcionando
6. [ ] Dependências adicionadas no pubspec.yaml:
   - image_picker: ^1.0.4
   - supabase_flutter: (já existe)
7. [ ] Permissões de câmera/galeria no Android/iOS
8. [ ] Teste de upload realizado com sucesso

COMANDOS SQL PARA VERIFICAÇÃO:

-- Verificar bucket
SELECT name, public FROM storage.buckets WHERE name = 'user-photos';

-- Verificar RLS
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'app_users';

-- Verificar coluna
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'app_users' AND column_name = 'photo_url';

-- Verificar permissões
SELECT grantee, privilege_type FROM information_schema.role_table_grants 
WHERE table_name = 'app_users' AND privilege_type = 'UPDATE';

DEPENDÊNCIAS PUBSPEC.YAML:

dependencies:
  image_picker: ^1.0.4
  supabase_flutter: ^2.0.0

PERMISSÕES ANDROID (android/app/src/main/AndroidManifest.xml):

<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

PERMISSÕES iOS (ios/Runner/Info.plist):

<key>NSCameraUsageDescription</key>
<string>Este app precisa acessar a câmera para tirar fotos de perfil</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Este app precisa acessar a galeria para selecionar fotos de perfil</string>

*/