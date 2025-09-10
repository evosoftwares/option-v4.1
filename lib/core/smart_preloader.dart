import 'dart:async';
import 'dart:developer' as dev;

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/supabase/app_user.dart';
import '../domain/services/user_service.dart';
import 'module_loader.dart';

class UserProfile {

  const UserProfile({
    required this.userId,
    required this.userType,
    required this.locationHistory,
    required this.featureUsageCount,
    required this.usageTimePatterns,
    required this.createdAt,
    required this.isFirstTime,
    required this.behaviorScores,
  });

  factory UserProfile.fromAppUser(AppUser user) => UserProfile(
      userId: user.id,
      userType: user.userType,
      locationHistory: [],
      featureUsageCount: {},
      usageTimePatterns: [],
      createdAt: user.createdAt,
      isFirstTime: DateTime.now().difference(user.createdAt).inDays < 7,
      behaviorScores: {},
    );
  final String userId;
  final String userType;
  final List<String> locationHistory;
  final Map<String, int> featureUsageCount;
  final List<String> usageTimePatterns;
  final DateTime createdAt;
  final bool isFirstTime;
  final Map<String, double> behaviorScores;
}

class PredictionModel {
  static const double confidenceThreshold = 0.7;
  
  /// Prediz quais módulos o usuário provavelmente usará nos próximos 10 minutos
  static Future<Map<ModuleType, double>> predictNextFeatures(
    UserProfile profile
  ) async {
    final predictions = <ModuleType, double>{};
    
    // Análise baseada no tipo de usuário
    final userTypePredictions = _analyzeUserType(profile);
    predictions.addAll(userTypePredictions);
    
    // Análise temporal (horário do dia)
    final temporalPredictions = _analyzeTemporalPatterns(profile);
    _mergePredictions(predictions, temporalPredictions);
    
    // Análise de localização
    final locationPredictions = _analyzeLocationPatterns(profile);
    _mergePredictions(predictions, locationPredictions);
    
    // Análise de uso histórico
    final usagePredictions = _analyzeUsageHistory(profile);
    _mergePredictions(predictions, usagePredictions);
    
    // Filtrar apenas predições com alta confiança
    final highConfidencePredictions = <ModuleType, double>{};
    predictions.forEach((module, confidence) {
      if (confidence >= confidenceThreshold) {
        highConfidencePredictions[module] = confidence;
      }
    });
    
    dev.log('🧠 AI Prediction: ${highConfidencePredictions.keys.length} módulos com alta confiança', 
        name: 'PredictiveAI');
    
    return highConfidencePredictions;
  }
  
  static Map<ModuleType, double> _analyzeUserType(UserProfile profile) {
    final predictions = <ModuleType, double>{};
    
    switch (profile.userType.toLowerCase()) {
      case 'passenger':
        predictions[ModuleType.corePassenger] = 0.95;
        predictions[ModuleType.chatSystem] = 0.8;
        predictions[ModuleType.paymentSystem] = 0.85;
        predictions[ModuleType.safetyFeatures] = 0.75;
        break;
        
      case 'driver':
        predictions[ModuleType.coreDriver] = 0.95;
        predictions[ModuleType.advancedMaps] = 0.9;
        predictions[ModuleType.chatSystem] = 0.8;
        predictions[ModuleType.analytics] = 0.7;
        break;
        
      case 'admin':
        predictions[ModuleType.adminPanel] = 0.95;
        predictions[ModuleType.analytics] = 0.9;
        predictions[ModuleType.coreDriver] = 0.7;
        predictions[ModuleType.corePassenger] = 0.7;
        break;
    }
    
    return predictions;
  }
  
  static Map<ModuleType, double> _analyzeTemporalPatterns(UserProfile profile) {
    final predictions = <ModuleType, double>{};
    final hour = DateTime.now().hour;
    
    // Padrões matutinos (6-12h)
    if (hour >= 6 && hour <= 12) {
      predictions[ModuleType.corePassenger] = 0.8;
      predictions[ModuleType.paymentSystem] = 0.75;
    }
    
    // Padrões de almoço (11-14h)
    else if (hour >= 11 && hour <= 14) {
      predictions[ModuleType.advancedMaps] = 0.85;
      predictions[ModuleType.coreDriver] = 0.8;
    }
    
    // Padrões noturnos (18-23h)
    else if (hour >= 18 && hour <= 23) {
      predictions[ModuleType.safetyFeatures] = 0.9;
      predictions[ModuleType.chatSystem] = 0.8;
    }
    
    // Madrugada (0-6h)
    else if (hour >= 0 && hour <= 6) {
      predictions[ModuleType.safetyFeatures] = 0.95;
      predictions[ModuleType.coreDriver] = 0.85; // Motoristas noturnos
    }
    
    return predictions;
  }
  
  static Map<ModuleType, double> _analyzeLocationPatterns(UserProfile profile) {
    final predictions = <ModuleType, double>{};
    
    // Analisar histórico de localizações
    for (final location in profile.locationHistory) {
      final locationLower = location.toLowerCase();
      
      // Áreas comerciais/empresariais
      if (locationLower.contains('centro') || 
          locationLower.contains('empresarial') ||
          locationLower.contains('comercial')) {
        predictions[ModuleType.coreDriver] = 0.85;
        predictions[ModuleType.advancedMaps] = 0.8;
      }
      
      // Áreas residenciais
      else if (locationLower.contains('residencial') ||
               locationLower.contains('bairro')) {
        predictions[ModuleType.corePassenger] = 0.8;
        predictions[ModuleType.safetyFeatures] = 0.75;
      }
      
      // Aeroportos/estações
      else if (locationLower.contains('aeroporto') ||
               locationLower.contains('estação') ||
               locationLower.contains('terminal')) {
        predictions[ModuleType.advancedMaps] = 0.9;
        predictions[ModuleType.paymentSystem] = 0.85;
      }
    }
    
    return predictions;
  }
  
  static Map<ModuleType, double> _analyzeUsageHistory(UserProfile profile) {
    final predictions = <ModuleType, double>{};
    
    // Analisar frequência de uso de features
    profile.featureUsageCount.forEach((feature, count) {
      final normalizedUsage = (count / 100).clamp(0.0, 1.0);
      
      switch (feature.toLowerCase()) {
        case 'chat':
          predictions[ModuleType.chatSystem] = 0.6 + (normalizedUsage * 0.4);
          break;
        case 'maps':
          predictions[ModuleType.advancedMaps] = 0.6 + (normalizedUsage * 0.4);
          break;
        case 'payment':
          predictions[ModuleType.paymentSystem] = 0.6 + (normalizedUsage * 0.4);
          break;
        case 'safety':
          predictions[ModuleType.safetyFeatures] = 0.6 + (normalizedUsage * 0.4);
          break;
        case 'analytics':
          predictions[ModuleType.analytics] = 0.6 + (normalizedUsage * 0.4);
          break;
      }
    });
    
    return predictions;
  }
  
  static void _mergePredictions(
    Map<ModuleType, double> base, 
    Map<ModuleType, double> additional
  ) {
    additional.forEach((module, confidence) {
      if (base.containsKey(module)) {
        // Combinar predições usando média ponderada
        base[module] = (base[module]! + confidence) / 2;
      } else {
        base[module] = confidence;
      }
    });
  }
}

class SmartPreloader {
  factory SmartPreloader() => _instance;
  SmartPreloader._internal();
  static final SmartPreloader _instance = SmartPreloader._internal();

  final ModuleLoader _moduleLoader = ModuleLoader();
  Timer? _predictionTimer;
  UserProfile? _currentProfile;

  /// Inicializa o sistema de preload inteligente
  Future<void> initialize() async {
    dev.log('🧠 Inicializando SmartPreloader...', name: 'SmartPreloader');
    
    await _moduleLoader.initialize();
    await _updateUserProfile();
    
    // Iniciar predições automáticas a cada 5 minutos
    _startAutomaticPredictions();
    
    dev.log('✅ SmartPreloader inicializado', name: 'SmartPreloader');
  }

  /// Executa predição e preload baseado no perfil atual
  Future<void> predictAndPreload([UserProfile? profile]) async {
    final userProfile = profile ?? _currentProfile;
    if (userProfile == null) {
      dev.log('⚠️ Perfil de usuário não disponível para predição', 
          name: 'SmartPreloader');
      return;
    }

    try {
      dev.log('🎯 Executando predição para usuário ${userProfile.userId}', 
          name: 'SmartPreloader');

      // Análises específicas por cenário
      await _analyzeNewUser(userProfile);
      await _analyzeBehaviorPatterns(userProfile);
      await _analyzeLocationContext(userProfile);

      // Predição via AI
      final predictions = await PredictionModel.predictNextFeatures(userProfile);
      
      if (predictions.isNotEmpty) {
        await _executeSmartPreload(predictions);
      }

    } catch (e) {
      dev.log('❌ Erro durante predição: $e', name: 'SmartPreloader');
    }
  }

  /// Analisa usuários novos e faz preload adequado
  Future<void> _analyzeNewUser(UserProfile profile) async {
    if (!profile.isFirstTime) return;

    dev.log('👋 Usuário novo detectado - preload de onboarding', 
        name: 'SmartPreloader');

    // Preload básico para novos usuários
    final modulesToLoad = <ModuleType>[];
    
    switch (profile.userType.toLowerCase()) {
      case 'passenger':
        modulesToLoad.addAll([
          ModuleType.corePassenger,
          ModuleType.safetyFeatures,
        ]);
        break;
      case 'driver':
        modulesToLoad.addAll([
          ModuleType.coreDriver,
          ModuleType.advancedMaps,
        ]);
        break;
    }

    await _moduleLoader.loadModules(modulesToLoad, 
        priority: ModulePriority.high);
  }

  /// Analisa padrões comportamentais
  Future<void> _analyzeBehaviorPatterns(UserProfile profile) async {
    // Usuários que usam muito o chat
    final chatUsage = profile.featureUsageCount['chat'] ?? 0;
    if (chatUsage > 10) {
      dev.log('💬 Alto uso de chat detectado', name: 'SmartPreloader');
      await _moduleLoader.loadModule(ModuleType.chatSystem, 
          priority: ModulePriority.high);
    }

    // Usuários power (muitas funcionalidades)
    final totalFeatureUsage = profile.featureUsageCount.values
        .fold(0, (sum, count) => sum + count);
    
    if (totalFeatureUsage > 50) {
      dev.log('⚡ Usuário power detectado', name: 'SmartPreloader');
      await _moduleLoader.loadModule(ModuleType.analytics);
    }
  }

  /// Analisa contexto de localização
  Future<void> _analyzeLocationContext(UserProfile profile) async {
    final businessKeywords = ['centro', 'empresarial', 'comercial'];
    final hasBusinessLocation = profile.locationHistory
        .any((location) => businessKeywords
            .any((keyword) => location.toLowerCase().contains(keyword)));

    if (hasBusinessLocation) {
      dev.log('🏢 Contexto empresarial detectado', name: 'SmartPreloader');
      await _moduleLoader.loadModule(ModuleType.coreDriver);
    }
  }

  /// Executa preload baseado nas predições
  Future<void> _executeSmartPreload(
    Map<ModuleType, double> predictions
  ) async {
    dev.log('🚀 Executando preload de ${predictions.length} módulos', 
        name: 'SmartPreloader');

    // Ordenar por confiança (maior primeiro)
    final sortedPredictions = predictions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Definir prioridades baseadas na confiança
    for (final entry in sortedPredictions) {
      final module = entry.key;
      final confidence = entry.value;
      
      ModulePriority priority;
      if (confidence >= 0.9) {
        priority = ModulePriority.critical;
      } else if (confidence >= 0.8) {
        priority = ModulePriority.high;
      } else {
        priority = ModulePriority.medium;
      }

      // Preload em background (não bloquear UI)
      unawaited(_moduleLoader.loadModule(module, priority: priority));
      
      dev.log('📦 Preload agendado: ${module.id} (confiança: ${confidence.toStringAsFixed(2)})', 
          name: 'SmartPreloader');
    }
  }

  /// Atualiza perfil do usuário atual
  Future<void> _updateUserProfile() async {
    try {
      final currentUser = await UserService.getCurrentUser();
      if (currentUser != null) {
        // Em implementação real, carregar dados completos do perfil
        final appUser = AppUser(
          id: currentUser.id,
          userType: currentUser.userType,
          email: currentUser.email,
          fullName: currentUser.fullName,
          phone: currentUser.phone ?? '',
          status: 'active',
          createdAt: currentUser.createdAt,
          updatedAt: DateTime.now(),
        );
        _currentProfile = UserProfile.fromAppUser(appUser);
        
        dev.log('👤 Perfil atualizado: ${currentUser.userType}', 
            name: 'SmartPreloader');
      }
    } catch (e) {
      dev.log('⚠️ Erro ao atualizar perfil: $e', name: 'SmartPreloader');
    }
  }

  /// Inicia predições automáticas em background
  void _startAutomaticPredictions() {
    _predictionTimer?.cancel();
    _predictionTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => predictAndPreload(),
    );
    
    dev.log('⏰ Predições automáticas iniciadas (5min)', name: 'SmartPreloader');
  }

  /// Registra uso de funcionalidade para melhorar predições futuras
  Future<void> recordFeatureUsage(String featureName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'feature_usage_$featureName';
      final currentCount = prefs.getInt(key) ?? 0;
      await prefs.setInt(key, currentCount + 1);
      
      dev.log('📊 Uso registrado: $featureName (${currentCount + 1}x)', 
          name: 'SmartPreloader');
    } catch (e) {
      dev.log('⚠️ Erro ao registrar uso: $e', name: 'SmartPreloader');
    }
  }

  void dispose() {
    _predictionTimer?.cancel();
    _moduleLoader.dispose();
    dev.log('🧹 SmartPreloader disposed', name: 'SmartPreloader');
  }
}