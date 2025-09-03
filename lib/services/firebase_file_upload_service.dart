import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'upload_analytics.dart';

class FirebaseFileUploadService {
  static FirebaseStorage get _storage => FirebaseStorage.instance;
  
  // Configurações de retry
  static const int maxRetryAttempts = 3;
  static const Duration initialRetryDelay = Duration(seconds: 1);
  
  // Configurações de upload
  static const int maxFileSizeBytes = 50 * 1024 * 1024; // 50MB
  static const int maxDocumentSizeBytes = 50 * 1024 * 1024; // 50MB para documentos
  static const List<String> allowedMimeTypes = [
    'image/jpeg',
    'image/jpg', 
    'image/png',
    'image/webp',
  ];
  static const List<String> allowedDocumentMimeTypes = [
    'image/jpeg',
    'image/jpg', 
    'image/png',
    'image/webp',
    'application/pdf',
  ];
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1920;
  static const int compressionQuality = 85;

  /// Wrapper para upload com retry logic
  static Future<T> _withRetry<T>(
    String operation, 
    Future<T> Function() uploadFunction,
    {bool Function(dynamic error)? shouldRetry}
  ) async {
    Exception? lastException;
    
    for (int attempt = 1; attempt <= maxRetryAttempts; attempt++) {
      try {
        print('🔄 [$operation] Tentativa $attempt de $maxRetryAttempts');
        return await uploadFunction();
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        final shouldRetryThis = shouldRetry?.call(e) ?? _defaultShouldRetry(e);
        
        if (attempt == maxRetryAttempts || !shouldRetryThis) {
          print('❌ [$operation] Falha definitiva na tentativa $attempt: $e');
          rethrow;
        }
        
        // Registrar tentativa de retry para analytics
        final uploadId = operation.contains('UPLOAD-') ? operation.split('-')[1] : operation;
        await UploadAnalytics.recordRetryAttempt(
          uploadId: uploadId,
          attemptNumber: attempt,
          errorMessage: e.toString(),
        );
        
        final delay = Duration(milliseconds: initialRetryDelay.inMilliseconds * (1 << (attempt - 1)));
        print('⏳ [$operation] Tentativa $attempt falhou: $e');
        print('   Tentando novamente em ${delay.inSeconds}s...');
        
        await Future.delayed(delay);
      }
    }
    
    throw lastException!;
  }
  
  /// Determina se um erro deve ser retried
  static bool _defaultShouldRetry(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Retry para erros de rede/conectividade
    if (errorString.contains('network') || 
        errorString.contains('connection') || 
        errorString.contains('timeout') ||
        errorString.contains('host lookup') ||
        errorString.contains('socket')) {
      return true;
    }
    
    // Retry para erros temporários do Firebase
    if (errorString.contains('internal-error') ||
        errorString.contains('unavailable') ||
        errorString.contains('deadline-exceeded')) {
      return true;
    }
    
    // NÃO retry para erros de autenticação, permissão ou dados inválidos
    if (errorString.contains('unauthenticated') ||
        errorString.contains('permission-denied') ||
        errorString.contains('invalid-argument') ||
        errorString.contains('not-found') ||
        errorString.contains('already-exists') ||
        errorString.contains('muito grande') ||
        errorString.contains('não permitido')) {
      return false;
    }
    
    return true; // Por padrão, tenta retry
  }

  /// Faz upload de documentos de motorista para o Firebase Storage
  /// 
  /// [file] - Arquivo de documento a ser enviado (imagem ou PDF)
  /// [folder] - Pasta onde o arquivo será salvo (ex: 'driver-documents')
  /// [path] - Caminho onde o arquivo será salvo
  /// [compress] - Se deve comprimir a imagem (padrão: true, não se aplica a PDFs)
  /// 
  /// Retorna a URL de download do arquivo enviado
  static Future<String> uploadDriverDocument({
    required File file,
    required String folder,
    required String path,
    bool compress = true,
  }) async {
    return _withRetry('UPLOAD-DOC', () => _uploadDriverDocumentInternal(
      file: file,
      folder: folder,
      path: path,
      compress: compress,
    ));
  }
  
  /// Implementação interna do upload (sem retry)
  static Future<String> _uploadDriverDocumentInternal({
    required File file,
    required String folder,
    required String path,
    bool compress = true,
  }) async {
    final startTime = DateTime.now();
    final uploadId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Registrar início do upload para analytics
    final fileSize = await file.length();
    await UploadAnalytics.recordUploadStart(
      uploadId: uploadId,
      type: 'driver-document',
      fileSizeBytes: fileSize,
      fileName: file.path.split('/').last,
    );
    
    try {
      print('🚀 [UPLOAD-$uploadId] FirebaseFileUploadService.uploadDriverDocument iniciado');
      print('📍 [UPLOAD-$uploadId] Parâmetros:');
      print('   - file: ${file.path}');
      print('   - folder: $folder');
      print('   - path: $path');
      print('   - compress: $compress');
      print('   - timestamp: ${startTime.toIso8601String()}');
      
      // Verificar estado do Firebase
      print('🔍 [UPLOAD-$uploadId] Verificando Firebase...');
      print('   - Firebase apps: ${Firebase.apps.length}');
      print('   - Storage bucket: ${_storage.bucket}');
      
      // Validar se o arquivo existe
      if (!await file.exists()) {
        throw FirebaseFileUploadException('Arquivo não encontrado: ${file.path}');
      }

      // Validar tamanho do arquivo
      final fileSize = await file.length();
      print('📏 [UPLOAD-$uploadId] Tamanho do arquivo: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
      
      if (fileSize > maxDocumentSizeBytes) {
        final errorMsg = 'Arquivo muito grande: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB. Máximo permitido: ${(maxDocumentSizeBytes / 1024 / 1024).toStringAsFixed(2)}MB';
        print('❌ [UPLOAD-$uploadId] $errorMsg');
        throw FirebaseFileUploadException(errorMsg);
      }

      // Validar tipo MIME para documentos
      final mimeType = _getMimeType(file.path);
      print('🏷️ [UPLOAD-$uploadId] Tipo MIME detectado: $mimeType');
      
      if (!allowedDocumentMimeTypes.contains(mimeType)) {
        final errorMsg = 'Tipo de arquivo não permitido: $mimeType. Tipos permitidos: ${allowedDocumentMimeTypes.join(', ')}';
        print('❌ [UPLOAD-$uploadId] $errorMsg');
        throw FirebaseFileUploadException(errorMsg);
      }

      Uint8List fileBytes;
      
      if (compress && mimeType != 'application/pdf') {
        // Comprimir apenas imagens, não PDFs
        print('🗜️ [UPLOAD-$uploadId] Comprimindo imagem...');
        final compressStart = DateTime.now();
        fileBytes = await _compressImage(file);
        final compressDuration = DateTime.now().difference(compressStart);
        print('✅ [UPLOAD-$uploadId] Imagem comprimida: ${fileBytes.length} bytes (${compressDuration.inMilliseconds}ms)');
        print('📊 [UPLOAD-$uploadId] Redução: ${((fileSize - fileBytes.length) / fileSize * 100).toStringAsFixed(1)}%');
      } else {
        // Usar arquivo original para PDFs ou quando compressão está desabilitada
        fileBytes = await file.readAsBytes();
        print('📄 [UPLOAD-$uploadId] Usando arquivo original: ${fileBytes.length} bytes');
      }
      
      // Criar referência no Firebase Storage
      final storageRef = _storage.ref().child('$folder/$path');
      print('🎯 [UPLOAD-$uploadId] Referência criada: ${storageRef.fullPath}');
      
      print('⬆️ [UPLOAD-$uploadId] Iniciando upload para Firebase Storage...');
      
      // Fazer upload
      final uploadTask = storageRef.putData(
        fileBytes,
        SettableMetadata(
          contentType: mimeType,
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'uploadId': uploadId,
            'originalSize': fileSize.toString(),
            'compressedSize': fileBytes.length.toString(),
          },
        ),
      );
      
      // Aguardar conclusão do upload
      final uploadStart = DateTime.now();
      final snapshot = await uploadTask;
      final uploadDuration = DateTime.now().difference(uploadStart);
      
      print('📤 [UPLOAD-$uploadId] Upload concluído em ${uploadDuration.inMilliseconds}ms');
      print('⚡ [UPLOAD-$uploadId] Velocidade: ${(fileBytes.length / 1024 / (uploadDuration.inMilliseconds / 1000)).toStringAsFixed(1)} KB/s');
      
      // Obter URL de download
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      final totalDuration = DateTime.now().difference(startTime);
      print('✅ [UPLOAD-$uploadId] Upload completo: $downloadUrl');
      print('⏱️ [UPLOAD-$uploadId] Tempo total: ${totalDuration.inMilliseconds}ms');
      
      // Registrar sucesso para analytics
      await UploadAnalytics.recordUploadSuccess(
        uploadId: uploadId,
        downloadUrl: downloadUrl,
        totalDuration: totalDuration,
        finalSizeBytes: fileBytes.length,
      );
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('❌ [UPLOAD-$uploadId] Erro do Firebase Storage: ${e.message}');
      print('🔍 [UPLOAD-$uploadId] Código do erro: ${e.code}');
      throw FirebaseFileUploadException('Erro no Firebase Storage: ${e.message}');
    } catch (e) {
      final totalDuration = DateTime.now().difference(startTime);
      print('❌ [UPLOAD-$uploadId] Erro inesperado no upload: $e');
      print('⏱️ [UPLOAD-$uploadId] Tempo até erro: ${totalDuration.inMilliseconds}ms');
      
      // Registrar falha para analytics
      await UploadAnalytics.recordUploadFailure(
        uploadId: uploadId,
        errorMessage: e.toString(),
        totalDuration: totalDuration,
      );
      
      if (e is FirebaseFileUploadException) rethrow;
      throw FirebaseFileUploadException('Erro inesperado no upload: $e');
    }
  }

  /// Faz upload de uma imagem para o Firebase Storage
  /// 
  /// [file] - Arquivo de imagem a ser enviado
  /// [folder] - Pasta onde o arquivo será salvo (ex: 'user-photos')
  /// [path] - Caminho onde o arquivo será salvo
  /// [compress] - Se deve comprimir a imagem (padrão: true)
  /// 
  /// Retorna a URL de download do arquivo enviado
  static Future<String> uploadImage({
    required File file,
    required String folder,
    required String path,
    bool compress = true,
  }) async {
    return _withRetry('UPLOAD-IMG', () => _uploadImageInternal(
      file: file,
      folder: folder,
      path: path,
      compress: compress,
    ));
  }
  
  /// Implementação interna do upload de imagem (sem retry)
  static Future<String> _uploadImageInternal({
    required File file,
    required String folder,
    required String path,
    bool compress = true,
  }) async {
    try {
      print('🔄 FirebaseFileUploadService.uploadImage iniciado');
      print('  - file: ${file.path}');
      print('  - folder: $folder');
      print('  - path: $path');
      print('  - compress: $compress');
      
      // Validar se o arquivo existe
      if (!await file.exists()) {
        throw FirebaseFileUploadException('Arquivo não encontrado: ${file.path}');
      }

      // Validar tamanho do arquivo
      final fileSize = await file.length();
      if (fileSize > maxFileSizeBytes) {
        throw FirebaseFileUploadException(
          'Arquivo muito grande: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB. Máximo permitido: ${(maxFileSizeBytes / 1024 / 1024).toStringAsFixed(2)}MB',
        );
      }

      // Validar tipo MIME
      final mimeType = _getMimeType(file.path);
      if (!allowedMimeTypes.contains(mimeType)) {
        throw FirebaseFileUploadException(
          'Tipo de arquivo não permitido: $mimeType. Tipos permitidos: ${allowedMimeTypes.join(', ')}',
        );
      }

      Uint8List fileBytes;
      
      if (compress) {
        // Comprimir imagem
        print('🔄 Comprimindo imagem...');
        fileBytes = await _compressImage(file);
        print('✅ Imagem comprimida: ${fileBytes.length} bytes');
      } else {
        // Usar arquivo original
        fileBytes = await file.readAsBytes();
      }

      // Criar referência no Firebase Storage
      final storageRef = _storage.ref().child('$folder/$path');
      
      print('🔄 Fazendo upload para Firebase Storage...');
      
      // Fazer upload
      final uploadTask = storageRef.putData(
        fileBytes,
        SettableMetadata(
          contentType: mimeType,
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      // Aguardar conclusão do upload
      final snapshot = await uploadTask;
      
      // Obter URL de download
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Upload concluído: $downloadUrl');
      
      return downloadUrl;

    } on FirebaseException catch (e) {
      print('❌ Erro do Firebase Storage: ${e.message}');
      throw FirebaseFileUploadException('Erro no Firebase Storage: ${e.message}');
    } catch (e) {
      print('❌ Erro inesperado no upload: $e');
      if (e is FirebaseFileUploadException) rethrow;
      throw FirebaseFileUploadException('Erro inesperado no upload: $e');
    }
  }

  /// Remove um arquivo do Firebase Storage
  static Future<bool> deleteFile({
    required String folder,
    required String path,
  }) async {
    try {
      print('🔄 FirebaseFileUploadService.deleteFile iniciado');
      print('  - folder: $folder');
      print('  - path: $path');

      final storageRef = _storage.ref().child('$folder/$path');
      await storageRef.delete();

      print('✅ Arquivo removido com sucesso');
      return true;

    } on FirebaseException catch (e) {
      print('❌ Erro ao remover arquivo: ${e.message}');
      return false;
    } catch (e) {
      print('❌ Erro inesperado ao remover arquivo: $e');
      return false;
    }
  }

  /// Comprime uma imagem mantendo a qualidade
  static Future<Uint8List> _compressImage(File file) async {
    try {
      // Ler a imagem
      final imageBytes = await file.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw const FirebaseFileUploadException('Não foi possível decodificar a imagem');
      }

      // Redimensionar se necessário
      var resizedImage = image;
      if (image.width > maxImageWidth || image.height > maxImageHeight) {
        resizedImage = img.copyResize(
          image,
          width: image.width > maxImageWidth ? maxImageWidth : null,
          height: image.height > maxImageHeight ? maxImageHeight : null,
          maintainAspect: true,
        );
      }

      // Comprimir como JPEG
      final compressedBytes = img.encodeJpg(resizedImage, quality: compressionQuality);
      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      throw FirebaseFileUploadException('Erro ao comprimir imagem: $e');
    }
  }

  /// Determina o tipo MIME baseado na extensão do arquivo
  static String _getMimeType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  /// Lista arquivos em uma pasta específica
  static Future<List<String>> listFiles(String folder) async {
    try {
      final storageRef = _storage.ref().child(folder);
      final result = await storageRef.listAll();
      
      final urls = <String>[];
      for (final item in result.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }
      
      return urls;
    } on FirebaseException catch (e) {
      print('❌ Erro ao listar arquivos: ${e.message}');
      return [];
    }
  }

  /// Obtém metadados de um arquivo
  static Future<Map<String, dynamic>?> getFileMetadata({
    required String folder,
    required String path,
  }) async {
    try {
      final storageRef = _storage.ref().child('$folder/$path');
      final metadata = await storageRef.getMetadata();
      
      return {
        'name': metadata.name,
        'bucket': metadata.bucket,
        'fullPath': metadata.fullPath,
        'size': metadata.size,
        'timeCreated': metadata.timeCreated?.toIso8601String(),
        'updated': metadata.updated?.toIso8601String(),
        'contentType': metadata.contentType,
        'customMetadata': metadata.customMetadata,
      };
    } on FirebaseException catch (e) {
      print('❌ Erro ao obter metadados: ${e.message}');
      return null;
    }
  }

  /// Gera o caminho para foto de perfil do usuário
  static String generateUserPhotoPath({
    required String userId,
    required String fileName,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = fileName.split('.').last;
    return '$userId/profile_$timestamp.$extension';
  }

  /// Gera o caminho para documento do motorista
  static String generateDriverDocumentPath({
    required String userId,
    required String documentType,
    required String fileName,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = fileName.split('.').last;
    return '$userId/documents/${documentType}_$timestamp.$extension';
   }

   /// Valida se o arquivo é uma imagem válida
   static Future<bool> isValidImage(File file) async {
     try {
       final bytes = await file.readAsBytes();
       final image = img.decodeImage(bytes);
       return image != null;
     } catch (e) {
       return false;
     }
   }

   /// Obtém informações da imagem
   static Future<Map<String, dynamic>?> getImageInfo(File file) async {
     try {
       final bytes = await file.readAsBytes();
       final image = img.decodeImage(bytes);
       
       if (image == null) return null;
       
       return {
         'width': image.width,
         'height': image.height,
         'size': bytes.length,
       };
     } catch (e) {
       return null;
     }
   }
 }

/// Exceção personalizada para erros de upload do Firebase
class FirebaseFileUploadException implements Exception {
  
  const FirebaseFileUploadException(this.message);
  final String message;
  
  @override
  String toString() => 'FirebaseFileUploadException: $message';
}