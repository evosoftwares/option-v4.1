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

  bool hasProfilePhoto() {
    return _profilePhoto != null;
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
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) {
        throw Exception('Usuário não autenticado');
      }

      final exists = await UserService.userExists(authUser.id);
      if (!exists) {
        // Criar app_user com dados coletados no stepper
        await UserService.createUser(
          authUserId: authUser.id,
          email: authUser.email ?? (_email ?? ''),
          fullName: _fullName ?? '',
          phone: _phone,
          photoUrl: null, // Upload da foto será implementado depois
          userType: _userType ?? 'passenger',
        );
      }

      return true;
    } catch (e) {
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
    if (photoUrl != null) {
      _profilePhoto = File(photoUrl);
      notifyListeners();
    }
  }
}