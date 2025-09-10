import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/exceptions/user_registration_exception.dart';
import '../../data/models/user.dart';
import '../services/app_logger.dart';
import '../services/firebase_file_upload_service.dart';
import '../services/stepper_persistence_service.dart';
import '../services/user_service.dart';
import '../../core/utils/supabase_helper.dart';


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
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  int get currentStep => _currentStep;
  String? get userType => _userType;
  String? get phone => _phone;
  String? get fullName => _fullName;
  String? get email => _email;
  File? get profilePhoto => _profilePhoto;
  String? get uploadedPhotoUrl => _uploadedPhotoUrl;
  bool get isUploadingPhoto => _isUploadingPhoto;
  

  // Alias para compatibilidade com add_location_modal

  void setUserType(String type) {
    final previousType = _userType;
    _userType = type;
    
    AppLogger.stepper('Tipo de usuário definido', step: _currentStep);
    AppLogger.update('StepperState', 'user_type', tag: 'STEPPER', changes: {
      'previous_type': previousType,
      'new_type': type,
      'current_step': _currentStep
    });
    
    notifyListeners();
    // Auto-save do estado crítico
    _saveState();
  }

  void setPhone(String phone) {
    final sanitizedPhone = _sanitizeStringValue(phone);
    final previousPhone = _phone;
    _phone = sanitizedPhone;
    
    AppLogger.stepper('Telefone definido', step: _currentStep);
    AppLogger.validation('phone_format', sanitizedPhone?.isNotEmpty == true, entity: 'StepperController');
    AppLogger.update('StepperState', 'phone', tag: 'STEPPER', changes: {
      'has_previous': previousPhone != null,
      'new_length': sanitizedPhone?.length ?? 0,
      'current_step': _currentStep
    });
    
    notifyListeners();
    // Auto-save do estado crítico
    _saveState();
  }

  void setFullName(String name) {
    _fullName = _sanitizeStringValue(name);
    notifyListeners();
    // Auto-save do estado crítico
    _saveState();
  }

  void setEmail(String email) {
    _email = _sanitizeStringValue(email);
    notifyListeners();
    // Auto-save do estado crítico
    _saveState();
  }

  /// Limpa dados persistidos corrompidos (strings "null")
  Future<void> clearCorruptedPersistedData() async {
    try {
      await StepperPersistenceService.clearStepperState();
      AppLogger.persistence('Dados persistidos corrompidos limpos');
    } catch (e) {
      AppLogger.error('Erro ao limpar dados persistidos corrompidos', error: e);
    }
  }

  void setProfilePhoto(File? photo) {
    _profilePhoto = photo;
    notifyListeners();
  }

  void removeProfilePhoto() {
    _profilePhoto = null;

    // If a file was already uploaded, attempt to delete it from Storage
    if (_uploadedPhotoPath != null) {
      FirebaseFileUploadService.deleteFile(
        folder: 'user-photos',
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

  /// Upload profile photo to Firebase Storage
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
          await FirebaseFileUploadService.deleteFile(
            folder: 'user-photos',
            path: _uploadedPhotoPath!,
          );
        } catch (e) {
          AppLogger.warning('Falha ao remover foto anterior', tag: 'UPLOAD');
        }
      }
      
      // Generate storage path
      final fileName = _profilePhoto!.path.split('/').last;
      final storagePath = FirebaseFileUploadService.generateUserPhotoPath(
        userId: authUser.id,
        fileName: fileName,
      );
      
      // Upload to user-photos folder no Firebase Storage
      final photoUrl = await FirebaseFileUploadService.uploadImage(
        file: _profilePhoto!,
        folder: 'user-photos',
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

      // Upload da foto de perfil se selecionada
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
          // Continue registration without photo instead of throwing exception
          photoUrl = null;
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
        
        // Criar perfil de motorista automaticamente se o tipo for 'driver'
        if (_userType == 'driver') {
          print('🚗 Criando perfil de motorista automaticamente...');
          try {
            // Criar objeto User do modelo local
            final user = User(
              id: authUser.id,
              email: email,
              fullName: _fullName!.trim(),
              phone: _phone!.trim(),
              photoUrl: photoUrl,
              userType: _userType!,
              status: 'active',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await UserService.createDriverRecord(user);
            print('✅ Perfil de motorista criado com sucesso!');
          } catch (e) {
            print('⚠️ Erro ao criar perfil de motorista: $e');
            AppLogger.error('Erro ao criar perfil de motorista', error: e);
            // Não falha o registro se a criação do perfil de motorista falhar
            // O usuário pode completar o perfil posteriormente
          }
        }
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

      // Locais favoritos foram removidos do fluxo de registro obrigatório
      print('ℹ️ Registro concluído - locais favoritos não são obrigatórios para motoristas');

      // Limpar dados persistidos após sucesso
      await StepperPersistenceService.clearStepperState();

      return true;
    } on SocketException catch (e) {
      print('❌ Erro de conexão ao completar registro: ${e.message}');
      AppLogger.error('Erro de conexão ao completar registro', error: e);
      throw Exception('Erro de conexão. Verifique sua internet e tente novamente.');
    } on TimeoutException catch (e) {
      print('❌ Timeout ao completar registro: ${e.message}');
      AppLogger.error('Timeout ao completar registro', error: e);
      throw Exception('Operação demorou muito. Verifique sua conexão e tente novamente.');
    } catch (e) {
      print('❌ Erro ao completar registro: $e');
      
      if (e.toString().contains('Failed host lookup')) {
        AppLogger.error('Erro de DNS ao completar registro', error: e);
        throw Exception('Erro de conexão com o servidor. Verifique sua internet.');
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
    notifyListeners();
  }

  Future<void> loadUserData() async {
    try {
      final hasState = await StepperPersistenceService.hasPersistedState();
      if (hasState) {
        final state = await StepperPersistenceService.loadStepperState();
        
        // Só carrega dados persistidos se os valores atuais estão vazios
        // Isso evita sobrescrever dados corretos vindos do user_type_screen
        _userType ??= _sanitizeStringValue(state['userType']);
        _phone ??= _sanitizeStringValue(state['phone']);
        _fullName ??= _sanitizeStringValue(state['fullName']);
        _email ??= _sanitizeStringValue(state['email']);
        
        _currentStep = state['currentStep'] ?? 0;
        // Favorite locations are no longer part of mandatory registration flow
        _uploadedPhotoUrl ??= _sanitizeStringValue(state['uploadedPhotoUrl']);
        
        AppLogger.persistence('Estado do stepper recuperado da persistência (apenas campos vazios)');
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

  /// Sanitiza valores string, convertendo "null" para null
  String? _sanitizeStringValue(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
        return null;
      }
      return trimmed;
    }
    return value?.toString();
  }
}