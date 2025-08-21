import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class PhotoService {
  final ImagePicker _picker = ImagePicker();

  /// Solicita permissões necessárias para câmera e galeria
  Future<bool> requestPermissions() async {
    try {
      var permissions = await [
        Permission.camera,
        Permission.photos,
        Permission.storage,
      ].request();

      // Verifica se pelo menos uma das permissões foi concedida
      var hasCameraPermission = permissions[Permission.camera]?.isGranted ?? false;
      var hasPhotosPermission = permissions[Permission.photos]?.isGranted ?? false;
      var hasStoragePermission = permissions[Permission.storage]?.isGranted ?? false;

      return hasCameraPermission || hasPhotosPermission || hasStoragePermission;
    } catch (e) {
      print('Erro ao solicitar permissões: $e');
      return false;
    }
  }

  /// Tira uma foto com a câmera
  Future<File?> takePhoto() async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        print('Permissões não concedidas');
        return null;
      }

      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      return photo != null ? File(photo.path) : null;
    } catch (e) {
      print('Erro ao tirar foto: $e');
      return null;
    }
  }

  /// Seleciona uma foto da galeria
  Future<File?> pickFromGallery() async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        print('Permissões não concedidas');
        return null;
      }

      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      return photo != null ? File(photo.path) : null;
    } catch (e) {
      print('Erro ao selecionar foto: $e');
      return null;
    }
  }

  /// Remove uma foto do sistema de arquivos
  Future<bool> deletePhoto(File photo) async {
    try {
      if (await photo.exists()) {
        await photo.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Erro ao deletar foto: $e');
      return false;
    }
  }
}