import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/favorite_location.dart';
import 'app_logger.dart';

/// Serviço de persistência SELETIVO - apenas para dados de cadastro
/// Status de aprovação e dados críticos sempre buscados frescos do banco
class StepperPersistenceService {
  static const String _prefix = 'stepper_';
  static const String _keyUserType = '${_prefix}user_type';
  static const String _keyPhone = '${_prefix}phone';
  static const String _keyFullName = '${_prefix}full_name';
  static const String _keyEmail = '${_prefix}email';
  static const String _keyCurrentStep = '${_prefix}current_step';
  static const String _keyUploadedPhotoUrl = '${_prefix}uploaded_photo_url';
  
  // NOTA: Locais favoritos e dados de aprovação NÃO são mais persistidos

  /// Salva APENAS dados básicos de cadastro (não salva dados de aprovação)
  static Future<void> saveStepperState({
    String? userType,
    String? phone,
    String? fullName,
    String? email,
    int? currentStep,
    List<FavoriteLocation>? favoriteLocations, // IGNORADO - não mais persistido
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
      
      if (uploadedPhotoUrl != null && uploadedPhotoUrl.isNotEmpty) {
        await prefs.setString(_keyUploadedPhotoUrl, uploadedPhotoUrl);
      }
      
      AppLogger.debug('Dados básicos de cadastro salvos (sem dados de aprovação)', tag: 'STEPPER_PERSISTENCE');
      
    } catch (e) {
      AppLogger.error('Erro ao salvar dados básicos do stepper', error: e);
    }
  }

  /// Recupera APENAS dados básicos de cadastro (não dados de aprovação)
  static Future<Map<String, dynamic>> loadStepperState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final userType = prefs.getString(_keyUserType);
      final phone = prefs.getString(_keyPhone);
      final fullName = prefs.getString(_keyFullName);
      final email = prefs.getString(_keyEmail);
      final currentStep = prefs.getInt(_keyCurrentStep) ?? 0;
      final uploadedPhotoUrl = prefs.getString(_keyUploadedPhotoUrl);
      
      AppLogger.debug('Dados básicos de cadastro recuperados (sem dados de aprovação)', tag: 'STEPPER_PERSISTENCE');
      
      return {
        'userType': userType,
        'phone': phone,
        'fullName': fullName,
        'email': email,
        'currentStep': currentStep,
        'favoriteLocations': <FavoriteLocation>[], // Sempre vazio - não mais persistido
        'uploadedPhotoUrl': uploadedPhotoUrl,
      };
    } catch (e) {
      AppLogger.error('Erro ao carregar dados básicos do stepper', error: e);
      return {
        'userType': null,
        'phone': null,
        'fullName': null,
        'email': null,
        'currentStep': 0,
        'favoriteLocations': <FavoriteLocation>[],
        'uploadedPhotoUrl': null,
      };
    }
  }

  /// Verifica se existe dados básicos de cadastro salvos
  static Future<bool> hasPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_keyUserType);
    } catch (e) {
      return false;
    }
  }

  /// Limpa dados básicos de cadastro (mantém dados críticos sempre frescos)
  static Future<void> clearStepperState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_keyUserType);
      await prefs.remove(_keyPhone);
      await prefs.remove(_keyFullName);
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyCurrentStep);
      await prefs.remove(_keyUploadedPhotoUrl);
      
      AppLogger.persistence('Dados básicos do stepper limpos (dados críticos sempre frescos)');
    } catch (e) {
      AppLogger.error('Erro ao limpar dados básicos do stepper', error: e);
    }
  }

  /// Salva apenas dados críticos básicos (performance otimizada)
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
      
      AppLogger.debug('Estado mínimo salvo (dados críticos sempre frescos)', tag: 'STEPPER_PERSISTENCE');
      
    } catch (e) {
      AppLogger.error('Erro ao salvar estado mínimo', error: e);
    }
  }
}