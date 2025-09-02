import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_helper.dart';

class FileUploadService {
  static SupabaseClient get _supabase {
    final c = SupabaseHelper.client;
    if (c == null) {
      throw FileUploadException('Supabase não inicializado');
    }
    return c;
  }
  
  // Configurações de upload
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxDocumentSizeBytes = 10 * 1024 * 1024; // 10MB para documentos
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

  /// Faz upload de documentos de motorista para o Supabase Storage
  /// 
  /// [file] - Arquivo de documento a ser enviado (imagem ou PDF)
  /// [bucket] - Nome do bucket no Supabase Storage
  /// [path] - Caminho onde o arquivo será salvo
  /// [compress] - Se deve comprimir a imagem (padrão: true, não se aplica a PDFs)
  /// 
  /// Retorna a URL pública do arquivo enviado
  static Future<String> uploadDriverDocument({
    required File file,
    required String bucket,
    required String path,
    bool compress = true,
  }) async {
    try {
      print('🔄 FileUploadService.uploadDriverDocument iniciado');
      print('  - file: ${file.path}');
      print('  - bucket: $bucket');
      print('  - path: $path');
      print('  - compress: $compress');

      // Validar se o arquivo existe
      if (!await file.exists()) {
        throw FileUploadException('Arquivo não encontrado: ${file.path}');
      }

      // Validar tamanho do arquivo (10MB para documentos)
      final fileSize = await file.length();
      if (fileSize > maxDocumentSizeBytes) {
        throw FileUploadException(
          'Arquivo muito grande: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB. Máximo permitido: ${(maxDocumentSizeBytes / 1024 / 1024).toStringAsFixed(2)}MB',
        );
      }

      // Validar tipo MIME para documentos
      final mimeType = _getMimeType(file.path);
      if (!allowedDocumentMimeTypes.contains(mimeType)) {
        throw FileUploadException(
          'Tipo de arquivo não permitido: $mimeType. Tipos permitidos: ${allowedDocumentMimeTypes.join(', ')}',
        );
      }

      Uint8List fileBytes;
      
      if (compress && mimeType != 'application/pdf') {
        // Comprimir apenas imagens, não PDFs
        print('🔄 Comprimindo imagem...');
        fileBytes = await _compressImage(file);
        print('✅ Imagem comprimida: ${fileBytes.length} bytes');
      } else {
        // Usar arquivo original para PDFs ou quando compressão está desabilitada
        fileBytes = await file.readAsBytes();
        print('📄 Usando arquivo original: ${fileBytes.length} bytes');
      }
      
      print('🔄 Fazendo upload para Supabase...');
      await _supabase.storage.from(bucket).uploadBinary(
        path,
        fileBytes,
        fileOptions: FileOptions(
          contentType: mimeType,
          upsert: true,
        ),
      );
      
      final url = _supabase.storage.from(bucket).getPublicUrl(path);
      print('✅ Upload concluído: $url');
      
      return url;
    } catch (e) {
      print('❌ Erro no upload: $e');
      if (e is StorageException) {
        throw FileUploadException('Erro no storage: ${e.message}');
      }
      rethrow;
    }
  }

  /// Faz upload de uma imagem para o Supabase Storage
  /// 
  /// [file] - Arquivo de imagem a ser enviado
  /// [bucket] - Nome do bucket no Supabase Storage
  /// [path] - Caminho onde o arquivo será salvo
  /// [compress] - Se deve comprimir a imagem (padrão: true)
  /// 
  /// Retorna a URL pública do arquivo enviado
  static Future<String> uploadImage({
    required File file,
    required String bucket,
    required String path,
    bool compress = true,
  }) async {
    try {
      print('🔄 FileUploadService.uploadImage iniciado');
      print('  - file: ${file.path}');
      print('  - bucket: $bucket');
      print('  - path: $path');
      print('  - compress: $compress');

      // Validar se o arquivo existe
      if (!await file.exists()) {
        throw FileUploadException('Arquivo não encontrado: ${file.path}');
      }

      // Validar tamanho do arquivo
      final fileSize = await file.length();
      if (fileSize > maxFileSizeBytes) {
        throw FileUploadException(
          'Arquivo muito grande: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB. Máximo permitido: ${(maxFileSizeBytes / 1024 / 1024).toStringAsFixed(2)}MB',
        );
      }

      // Validar tipo MIME
      final mimeType = _getMimeType(file.path);
      if (!allowedMimeTypes.contains(mimeType)) {
        throw FileUploadException(
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

      // Fazer upload para o Supabase Storage
      print('🔄 Fazendo upload para Supabase Storage...');
      final response = await _supabase.storage
          .from(bucket)
          .uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true, // Substitui se já existir
            ),
          );

      print('✅ Upload concluído: $response');

      // Obter URL pública
      final publicUrl = _supabase.storage
          .from(bucket)
          .getPublicUrl(path);

      print('✅ URL pública gerada: $publicUrl');
      return publicUrl;

    } on StorageException catch (e) {
      print('❌ Erro do Supabase Storage: ${e.message}');
      throw FileUploadException('Erro no upload: ${e.message}');
    } catch (e) {
      print('❌ Erro inesperado no upload: $e');
      if (e is FileUploadException) rethrow;
      throw FileUploadException('Erro inesperado no upload: $e');
    }
  }

  /// Remove um arquivo do Supabase Storage
  static Future<bool> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      print('🔄 FileUploadService.deleteFile iniciado');
      print('  - bucket: $bucket');
      print('  - path: $path');

      final response = await _supabase.storage
          .from(bucket)
          .remove([path]);

      print('✅ Arquivo removido: $response');
      return true;

    } on StorageException catch (e) {
      print('❌ Erro ao remover arquivo: ${e.message}');
      return false;
    } catch (e) {
      print('❌ Erro inesperado ao remover arquivo: $e');
      return false;
    }
  }

  /// Comprime uma imagem mantendo qualidade aceitável
  static Future<Uint8List> _compressImage(File file) async {
    try {
      // Ler bytes da imagem
      final originalBytes = await file.readAsBytes();
      
      // Decodificar imagem
      final image = img.decodeImage(originalBytes);
      if (image == null) {
        throw FileUploadException('Não foi possível decodificar a imagem');
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
      final compressedBytes = img.encodeJpg(
        resizedImage,
        quality: compressionQuality,
      );

      return Uint8List.fromList(compressedBytes);

    } catch (e) {
      print('❌ Erro ao comprimir imagem: $e');
      // Se falhar na compressão, retorna o arquivo original
      return file.readAsBytes();
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
      default:
        return 'image/jpeg'; // Padrão
    }
  }

  /// Gera um nome único para o arquivo baseado no timestamp
  static String generateUniqueFileName(String originalFileName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = originalFileName.split('.').last;
    return '${timestamp}_${DateTime.now().microsecond}.$extension';
  }

  /// Gera um caminho para documentos do motorista
  static String generateDriverDocumentPath({
    required String driverId,
    required String documentType,
    required String fileName,
  }) {
    final uniqueFileName = generateUniqueFileName(fileName);
    return 'drivers/$driverId/documents/$documentType/$uniqueFileName';
  }

  /// Gera um caminho para fotos de perfil do usuário
  static String generateUserPhotoPath({
    required String userId,
    required String fileName,
  }) {
    final uniqueFileName = generateUniqueFileName(fileName);
    return 'users/$userId/profile/$uniqueFileName';
  }

  /// Valida se um arquivo é uma imagem válida
  static Future<bool> isValidImage(File file) async {
    try {
      if (!await file.exists()) return false;
      
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      return image != null;
    } catch (e) {
      return false;
    }
  }

  /// Obtém informações sobre uma imagem
  static Future<Map<String, dynamic>?> getImageInfo(File file) async {
    try {
      if (!await file.exists()) return null;
      
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return null;
      
      return {
        'width': image.width,
        'height': image.height,
        'size': bytes.length,
        'mimeType': _getMimeType(file.path),
      };
    } catch (e) {
      return null;
    }
  }
}

/// Exceção personalizada para erros de upload
class FileUploadException implements Exception {
  
  FileUploadException(this.message);
  final String message;
  
  @override
  String toString() => 'FileUploadException: $message';
}