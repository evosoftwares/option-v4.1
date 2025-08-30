import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/favorite_location.dart';
import 'app_logger.dart';

/// Serviço responsável por persistir e recuperar dados do stepper
/// para melhorar a UX em caso de interrupção do processo de registro
class StepperPersistenceService {
  static const String _prefix = 'stepper_';
  static const String _keyUserType = '${_prefix}user_type';
  static const String _keyPhone = '${_prefix}phone';
  static const String _keyFullName = '${_prefix}full_name';
  static const String _keyEmail = '${_prefix}email';
  static const String _keyCurrentStep = '${_prefix}current_step';
  static const String _keyFavoriteLocations = '${_prefix}favorite_locations';
  static const String _keyUploadedPhotoUrl = '${_prefix}uploaded_photo_url';

  /// Salva o estado atual do stepper para persistência
  static Future<void> saveStepperState({
    String? userType,
    String? phone,
    String? fullName,
    String? email,
    int? currentStep,
    List<FavoriteLocation>? favoriteLocations,
    String? uploadedPhotoUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (userType != null) {
        await prefs.setString(_keyUserType, userType);
      }
      
      if (phone != null) {
        await prefs.setString(_keyPhone, phone);
      }
      
      if (fullName != null && fullName.isNotEmpty && fullName.toLowerCase() != 'null') {
        await prefs.setString(_keyFullName, fullName);
      }
      
      if (email != null && email.isNotEmpty && email.toLowerCase() != 'null') {
        await prefs.setString(_keyEmail, email);
      }
      
      if (currentStep != null) {
        await prefs.setInt(_keyCurrentStep, currentStep);
      }
      
      if (favoriteLocations != null) {
        final locationsJson = favoriteLocations
            .map((location) => location.toJson())
            .toList();
        await prefs.setString(_keyFavoriteLocations, jsonEncode(locationsJson));
      }
      
      if (uploadedPhotoUrl != null && uploadedPhotoUrl.isNotEmpty) {
        await prefs.setString(_keyUploadedPhotoUrl, uploadedPhotoUrl);
      }
      
    } catch (e) {
      AppLogger.error('Erro ao salvar estado do stepper', error: e);
    }
  }

  /// Recupera os dados persistidos do stepper
  static Future<Map<String, dynamic>> loadStepperState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final userType = prefs.getString(_keyUserType);
      final phone = prefs.getString(_keyPhone);
      final fullName = prefs.getString(_keyFullName);
      final email = prefs.getString(_keyEmail);
      final currentStep = prefs.getInt(_keyCurrentStep) ?? 0;
      final uploadedPhotoUrl = prefs.getString(_keyUploadedPhotoUrl);
      
      var favoriteLocations = <FavoriteLocation>[];
      final locationsJson = prefs.getString(_keyFavoriteLocations);
      if (locationsJson != null && locationsJson.isNotEmpty) {
        try {
          final locationsData = jsonDecode(locationsJson) as List;
          favoriteLocations = locationsData
              .map((locationData) => FavoriteLocation.fromJson(locationData))
              .toList();
        } catch (e) {
          AppLogger.warning('Erro ao deserializar locais favoritos');
        }
      }
      
      return {
        'userType': userType,
        'phone': phone,
        'fullName': fullName,
        'email': email,
        'currentStep': currentStep,
        'favoriteLocations': favoriteLocations,
        'uploadedPhotoUrl': uploadedPhotoUrl,
      };
    } catch (e) {
      AppLogger.error('Erro ao carregar estado do stepper', error: e);
      return {};
    }
  }

  /// Verifica se existe um estado salvo do stepper
  static Future<bool> hasPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_keyUserType);
    } catch (e) {
      return false;
    }
  }

  /// Limpa todos os dados persistidos do stepper
  static Future<void> clearStepperState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_keyUserType);
      await prefs.remove(_keyPhone);
      await prefs.remove(_keyFullName);
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyCurrentStep);
      await prefs.remove(_keyFavoriteLocations);
      await prefs.remove(_keyUploadedPhotoUrl);
      
      AppLogger.persistence('Estado do stepper limpo com sucesso');
    } catch (e) {
      AppLogger.error('Erro ao limpar estado do stepper', error: e);
    }
  }

  /// Salva apenas dados críticos (performance otimizada)
  static Future<void> saveMinimalState({
    String? userType,
    String? phone,
    int? currentStep,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (userType != null) {
        await prefs.setString(_keyUserType, userType);
      }
      
      if (phone != null) {
        await prefs.setString(_keyPhone, phone);
      }
      
      if (currentStep != null) {
        await prefs.setInt(_keyCurrentStep, currentStep);
      }
      
    } catch (e) {
      AppLogger.error('Erro ao salvar estado mínimo', error: e);
    }
  }
}