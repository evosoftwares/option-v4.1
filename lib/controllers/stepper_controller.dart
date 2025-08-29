import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../exceptions/user_registration_exception.dart';
import '../models/favorite_location.dart';
import '../services/app_logger.dart';
import '../services/file_upload_service.dart';
import '../services/real_saved_places_service.dart' as places_service show ValidationException;
import '../services/real_saved_places_service.dart';
import '../services/stepper_persistence_service.dart';
import '../services/user_service.dart';
import '../utils/supabase_helper.dart';

export '../services/real_saved_places_service.dart' show DatabaseException, NetworkException;

class StepperController extends ChangeNotifier {

  StepperController();
  int _currentStep = 0;

  String? _userType;
  String? _phone;
  String? _fullName;
  String? _email;
  File? _profilePhoto;
  String? _uploadedPhotoUrl;
  bool _isUploadingPhoto = false;
  String? _uploadedPhotoPath;
  List<FavoriteLocation> _favoriteLocations = [];
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final RealSavedPlacesService _savedPlacesService = RealSavedPlacesService();
  int get currentStep => _currentStep;
  String? get userType => _userType;
  String? get phone => _phone;
  String? get fullName => _fullName;
  String? get email => _email;
  File? get profilePhoto => _profilePhoto;
  String? get uploadedPhotoUrl => _uploadedPhotoUrl;
  bool get isUploadingPhoto => _isUploadingPhoto;
  List<FavoriteLocation> get favoriteLocations => _favoriteLocations;

  void setUserType(String type) {
    _userType = type;
    notifyListeners();
    // Auto-save do estado crítico
    _saveState();
  }

  void setPhone(String phone) {
    _phone = phone;
    notifyListeners();
    // Auto-save do estado crítico
    _saveState();
  }

  void setFullName(String name) {
    _fullName = name;
    notifyListeners();
    // Auto-save do estado crítico
    _saveState();
  }

  void setEmail(String email) {
    _email = email;
    notifyListeners();
    // Auto-save do estado crítico
    _saveState();
  }

  void setProfilePhoto(File? photo) {
    _profilePhoto = photo;
    notifyListeners();
  }

  void removeProfilePhoto() {
    _profilePhoto = null;

    // If a file was already uploaded, attempt to delete it from Storage
    if (_uploadedPhotoPath != null) {
      FileUploadService.deleteFile(
        bucket: 'user-photos',
        path: _uploadedPhotoPath!,
      ).then((ok) {
        if (ok) {
          AppLogger.upload('Foto de perfil removida do Storage', filename: _uploadedPhotoPath);
        } else {
          AppLogger.warning('Não foi possível remover a foto do Storage');
        }
      }).catchError((e) {
        AppLogger.error('Erro ao remover foto do Storage', error: e);
      });
    }

    _uploadedPhotoUrl = null;
    _uploadedPhotoPath = null;
    notifyListeners();
  }

  bool hasProfilePhoto() => _profilePhoto != null;

  /// Upload profile photo to Supabase Storage
  Future<String?> uploadProfilePhoto() async {
    if (_profilePhoto == null) return null;
    
    try {
      _isUploadingPhoto = true;
      notifyListeners();
      
      final authUser = SupabaseHelper.client?.auth.currentUser;
      if (authUser == null) {
        throw Exception('Usuário não autenticado');
      }
      
      AppLogger.upload('Fazendo upload da foto de perfil');

      // Delete previously uploaded file if exists (cleanup on re-upload)
      if (_uploadedPhotoPath != null) {
        try {
          AppLogger.upload('Removendo foto anterior do Storage', filename: _uploadedPhotoPath);
          await FileUploadService.deleteFile(
            bucket: 'user-photos',
            path: _uploadedPhotoPath!,
          );
        } catch (e) {
          AppLogger.warning('Falha ao remover foto anterior', tag: 'UPLOAD');
        }
      }
      
      // Generate storage path
      final fileName = _profilePhoto!.path.split('/').last;
      final storagePath = FileUploadService.generateUserPhotoPath(
        userId: authUser.id,
        fileName: fileName,
      );
      
      // Upload to user-photos bucket
      final photoUrl = await FileUploadService.uploadImage(
        file: _profilePhoto!,
        bucket: 'user-photos',
        path: storagePath,
      );
      
      _uploadedPhotoUrl = photoUrl;
      _uploadedPhotoPath = storagePath;
      AppLogger.success('Foto de perfil enviada com sucesso');
      
      return photoUrl;
    } on SocketException catch (e) {
      AppLogger.error('Erro de conexão ao fazer upload da foto: ${e.message}', error: e);
      throw Exception('Erro de conexão. Verifique sua internet e tente novamente.');
    } on TimeoutException catch (e) {
      AppLogger.error('Timeout ao fazer upload da foto: ${e.message}', error: e);
      throw Exception('Upload demorou muito. Verifique sua conexão e tente novamente.');
    } catch (e) {
      AppLogger.error('Erro ao fazer upload da foto', error: e);
      if (e.toString().contains('Failed host lookup')) {
        throw Exception('Erro de conexão com o servidor. Verifique sua internet.');
      }
      rethrow;
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
  }

  void nextStep() {
    if (_currentStep < 2) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 2) {
      _currentStep = step;
      notifyListeners();
    }
  }

  void addLocation(FavoriteLocation location) {
    _favoriteLocations.add(location);
    notifyListeners();
  }

  void removeLocation(int index) {
    if (index >= 0 && index < _favoriteLocations.length) {
      _favoriteLocations.removeAt(index);
      notifyListeners();
    }
  }

  Future<void> saveFavoriteLocations(List<FavoriteLocation> locations) async {
    try {
      final authUser = SupabaseHelper.client?.auth.currentUser;
      if (authUser == null) {
        throw Exception('Usuário não autenticado');
      }

      if (locations.isEmpty) {
        AppLogger.info('Nenhum local favorito para salvar');
        return;
      }

      AppLogger.info('Salvando ${locations.length} locais favoritos...');
      
      // Salvar cada local no banco usando RealSavedPlacesService
      final savedLocations = <FavoriteLocation>[];
      
      for (final location in locations) {
        try {
          final locationWithUserId = location.copyWith(userId: authUser.id);
          final savedLocation = await _savedPlacesService.addPlace(locationWithUserId);
          savedLocations.add(savedLocation);
          AppLogger.info('Local "${location.name}" salvo com sucesso');
        } on places_service.ValidationException catch (e) {
          AppLogger.error('Erro de validação ao salvar local "${location.name}": ${e.message}');
          throw Exception('Dados inválidos para o local "${location.name}": ${e.message}');
        } on DatabaseException catch (e) {
          AppLogger.error('Erro de banco ao salvar local "${location.name}": ${e.message}');
          throw Exception('Erro no banco de dados ao salvar local "${location.name}": ${e.message}');
        } on NetworkException catch (e) {
          AppLogger.error('Erro de rede ao salvar local "${location.name}": ${e.message}');
          throw Exception('Erro de conexão ao salvar local "${location.name}": ${e.message}');
        }
      }
      
      _favoriteLocations = savedLocations;
      notifyListeners();
      
      AppLogger.success('${savedLocations.length} locais favoritos salvos no banco');
    } catch (e) {
      AppLogger.error('Erro ao salvar locais favoritos no banco', error: e);
      rethrow;
    }
  }



  Future<bool> completeRegistration() async {
    // Cria o app_user vinculado ao auth somente ao final do stepper 3
    try {
      AppLogger.stepper('Iniciando completeRegistration');
      
      final authUser = SupabaseHelper.client?.auth.currentUser;
      if (authUser == null) {
        AppLogger.error('Usuário não autenticado', tag: 'AUTH');
        throw RequiredFieldsException('autenticação');
      }
      
      AppLogger.auth('Usuário autenticado', userId: authUser.id);
      print('📧 Email: ${authUser.email}');

      // DEBUGGING - Verificar o estado atual do controller
      print('🔍 [DEBUG] Estado completo do StepperController:');
      print('  - _fullName: "$_fullName"');
      print('  - _email: "$_email"');
      print('  - _phone: "$_phone"');
      print('  - _userType: "$_userType"');
      print('  - hasProfilePhoto: ${hasProfilePhoto()}');
      print('  - _uploadedPhotoUrl: $_uploadedPhotoUrl');

      // Validar dados obrigatórios
      final email = authUser.email ?? _email;
      if (email == null || email.isEmpty) {
        AppLogger.error('Email não encontrado para completar cadastro');
        throw RequiredFieldsException('email');
      }

      if (_fullName == null || _fullName!.trim().isEmpty) {
        AppLogger.error('Nome completo não encontrado para completar cadastro');
        throw RequiredFieldsException('nome completo');
      }

      if (_userType == null || _userType!.isEmpty) {
        AppLogger.error('Tipo de usuário não selecionado para completar cadastro');
        throw RequiredFieldsException('tipo de usuário');
      }

      if (_phone == null || _phone!.trim().isEmpty) {
        AppLogger.error('Telefone não encontrado para completar cadastro');
        throw RequiredFieldsException('telefone');
      }

      // Upload photo if one is selected
      var photoUrl = _uploadedPhotoUrl;
      if (hasProfilePhoto() && photoUrl == null) {
        print('📸 Fazendo upload da foto de perfil...');
        try {
          photoUrl = await uploadProfilePhoto();
          print('✅ Foto de perfil salva: $photoUrl');
        } catch (e) {
          print('❌ Erro ao fazer upload da foto (continuando sem foto): $e');
          // Log the error but continue without photo
          AppLogger.error('Erro no upload da foto de perfil', error: e);
          throw PhotoUploadException(e.toString());
        }
      }

      print('📋 Dados validados:');
      print('  - Email: $email');
      print('  - Nome: $_fullName');
      print('  - Telefone: $_phone');
      print('  - Tipo: $_userType');
      print('  - Photo URL: $photoUrl');

      final exists = await UserService.userExists(authUser.id);
      print('🔍 Usuário já existe: $exists');
      
      if (!exists) {
        print('🆕 Criando novo usuário...');
        // Criar app_user com dados coletados no stepper
        await UserService.createUser(
          authUserId: authUser.id,
          email: email,
          fullName: _fullName!.trim(),
          phone: _phone!.trim(),
          photoUrl: photoUrl,
          userType: _userType!,
        );
        print('✅ Usuário criado com sucesso!');
      } else {
        print('ℹ️ Usuário já existe, pulando criação');
        // Se já existe e temos uma foto nova, atualiza o usuário com a nova URL
        if (photoUrl != null && photoUrl.isNotEmpty) {
          try {
            print('🔄 Atualizando photo_url do usuário existente...');
            await UserService.updateUser(
              userId: authUser.id,
              photoUrl: photoUrl,
            );
            print('✅ photo_url atualizado com sucesso para usuário existente');
          } catch (e) {
            print('⚠️ Falha ao atualizar photo_url do usuário existente: $e');
          }
        }
      }

      // Locais favoritos foram removidos do fluxo de registro
      print('ℹ️ Registro concluído sem coleta de locais favoritos');

      // Limpar dados persistidos após sucesso
      await StepperPersistenceService.clearStepperState();

      return true;
    } on SocketException catch (e) {
      print('❌ Erro de conexão ao completar registro: ${e.message}');
      AppLogger.error('Erro de conexão ao completar registro', error: e);
      throw NetworkException('Erro de conexão. Verifique sua internet e tente novamente.');
    } on TimeoutException catch (e) {
      print('❌ Timeout ao completar registro: ${e.message}');
      AppLogger.error('Timeout ao completar registro', error: e);
      throw NetworkException('Operação demorou muito. Verifique sua conexão e tente novamente.');
    } catch (e) {
      print('❌ Erro ao completar registro: $e');
      
      if (e.toString().contains('Failed host lookup')) {
        AppLogger.error('Erro de DNS ao completar registro', error: e);
        throw NetworkException('Erro de conexão com o servidor. Verifique sua internet.');
      }
      
      // Mapear exceção para tipo específico de registro
      final mappedException = UserRegistrationExceptionMapper.mapException(e.toString());
      throw mappedException;
    }
  }



  void reset() {
    _currentStep = 0;
    _userType = null;
    _phone = null;
    _fullName = null;
    _email = null;
    _profilePhoto = null;
    _uploadedPhotoUrl = null;
    _uploadedPhotoPath = null;
    _isUploadingPhoto = false;
    _favoriteLocations = [];
    notifyListeners();
  }

  Future<void> loadUserData() async {
    try {
      final hasState = await StepperPersistenceService.hasPersistedState();
      if (hasState) {
        final state = await StepperPersistenceService.loadStepperState();
        
        _userType = state['userType'];
        _phone = state['phone'];
        _fullName = state['fullName'];
        _email = state['email'];
        _currentStep = state['currentStep'] ?? 0;
        // Favorite locations removed from registration flow
        _uploadedPhotoUrl = state['uploadedPhotoUrl'];
        
        AppLogger.persistence('Estado do stepper recuperado da persistência');
      }
    } catch (e) {
      AppLogger.error('Erro ao carregar dados persistidos', error: e);
    }
    notifyListeners();
  }

  /// Salva o estado atual do stepper
  void _saveState() {
    StepperPersistenceService.saveStepperState(
      userType: _userType,
      phone: _phone,
      fullName: _fullName,
      email: _email,
      currentStep: _currentStep,
      favoriteLocations: const [],
      uploadedPhotoUrl: _uploadedPhotoUrl,
    );
  }

  void updatePhotoUrl(String? photoUrl) {
    // Não podemos criar um File a partir de uma URL
    // Este método deve ser usado apenas para notificar que a URL da foto foi atualizada
    // O File da foto deve ser definido através do setProfilePhoto()
    print('📸 Photo URL atualizada: $photoUrl');
    _uploadedPhotoUrl = photoUrl;
    notifyListeners();
  }
}