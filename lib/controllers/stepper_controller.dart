import 'package:flutter/material.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/favorite_location.dart';
import '../services/user_service.dart';

class StepperController extends ChangeNotifier {
  int _currentStep = 0;
  final List<FavoriteLocation> _favoriteLocations = [];
  String? _userType;
  String? _phone;
  String? _fullName;
  String? _email;
  File? _profilePhoto;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  int get currentStep => _currentStep;
  List<FavoriteLocation> get favoriteLocations => _favoriteLocations;
  List<FavoriteLocation> get locations => _favoriteLocations;
  String? get userType => _userType;
  String? get phone => _phone;
  String? get fullName => _fullName;
  String? get email => _email;
  File? get profilePhoto => _profilePhoto;

  void setUserType(String type) {
    _userType = type;
    notifyListeners();
  }

  void setPhone(String phone) {
    _phone = phone;
    notifyListeners();
  }

  void setFullName(String name) {
    _fullName = name;
    notifyListeners();
  }

  void setEmail(String email) {
    _email = email;
    notifyListeners();
  }

  void setProfilePhoto(File? photo) {
    _profilePhoto = photo;
    notifyListeners();
  }

  void removeProfilePhoto() {
    _profilePhoto = null;
    notifyListeners();
  }

  bool hasProfilePhoto() => _profilePhoto != null;

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

  void addLocationWithDetails(String name, String address, LocationType type) {
    final location = FavoriteLocation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      address: address,
      type: type,
    );
    addLocation(location);
  }

  void updateLocation(int index, FavoriteLocation location) {
    if (index >= 0 && index < _favoriteLocations.length) {
      _favoriteLocations[index] = location;
      notifyListeners();
    }
  }

  void updateLocationById(String id, String name, String address, LocationType type) {
    final index = _favoriteLocations.indexWhere((loc) => loc.id == id);
    if (index != -1) {
      final updatedLocation = FavoriteLocation(
        id: id,
        name: name,
        address: address,
        type: type,
      );
      _favoriteLocations[index] = updatedLocation;
      notifyListeners();
    }
  }

  void updateLocations(List<FavoriteLocation> locations) {
    _favoriteLocations.clear();
    _favoriteLocations.addAll(locations);
    notifyListeners();
  }

  void removeLocation(int index) {
    if (index >= 0 && index < _favoriteLocations.length) {
      _favoriteLocations.removeAt(index);
      notifyListeners();
    }
  }

  void removeLocationById(String id) {
    _favoriteLocations.removeWhere((location) => location.id == id);
    notifyListeners();
  }

  Future<bool> completeRegistration() async {
    // Cria o app_user vinculado ao auth somente ao final do stepper 3
    try {
      print('🔄 Iniciando completeRegistration...');
      
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) {
        print('❌ Erro: Usuário não autenticado');
        throw Exception('Usuário não autenticado');
      }
      
      print('✅ Usuário autenticado: ${authUser.id}');
      print('📧 Email: ${authUser.email}');

      // Validar dados obrigatórios
      final email = authUser.email ?? _email;
      if (email == null || email.isEmpty) {
        print('❌ Erro: Email não encontrado');
        throw Exception('Email é obrigatório para completar o cadastro');
      }

      if (_fullName == null || _fullName!.trim().isEmpty) {
        print('❌ Erro: Nome completo não encontrado');
        throw Exception('Nome completo é obrigatório para completar o cadastro');
      }

      if (_userType == null || _userType!.isEmpty) {
        print('❌ Erro: Tipo de usuário não selecionado');
        throw Exception('Tipo de usuário é obrigatório para completar o cadastro');
      }

      print('📋 Dados validados:');
      print('  - Email: $email');
      print('  - Nome: $_fullName');
      print('  - Telefone: $_phone');
      print('  - Tipo: $_userType');

      final exists = await UserService.userExists(authUser.id);
      print('🔍 Usuário já existe: $exists');
      
      if (!exists) {
        print('🆕 Criando novo usuário...');
        // Criar app_user com dados coletados no stepper
        await UserService.createUser(
          authUserId: authUser.id,
          email: email,
          fullName: _fullName!.trim(),
          phone: _phone?.trim(),
          userType: _userType!,
        );
        print('✅ Usuário criado com sucesso!');
      } else {
        print('ℹ️ Usuário já existe, pulando criação');
      }

      return true;
    } catch (e) {
      print('❌ Erro ao completar registro: $e');
      rethrow;
    }
  }

  void reset() {
    _currentStep = 0;
    _favoriteLocations.clear();
    _userType = null;
    _phone = null;
    _fullName = null;
    _email = null;
    _profilePhoto = null;
    notifyListeners();
  }

  void loadUserData() {
    // Carregar dados do usuário se necessário
    notifyListeners();
  }

  void updatePhotoUrl(String? photoUrl) {
    // Não podemos criar um File a partir de uma URL
    // Este método deve ser usado apenas para notificar que a URL da foto foi atualizada
    // O File da foto deve ser definido através do setProfilePhoto()
    print('📸 Photo URL atualizada: $photoUrl');
    notifyListeners();
  }
}