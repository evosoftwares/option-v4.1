import 'dart:async';
import 'dart:developer' as dev;
import 'package:shared_preferences/shared_preferences.dart';

enum ModuleType {
  corePassenger('core_passenger', 4, 'Funcionalidades básicas do passageiro'),
  coreDriver('core_driver', 5, 'Funcionalidades básicas do motorista'),
  advancedMaps('advanced_maps', 3, 'Recursos avançados do Google Maps'),
  chatSystem('chat_system', 2, 'Sistema de chat completo'),
  paymentSystem('payment_system', 3, 'Sistema de pagamentos'),
  adminPanel('admin_panel', 4, 'Painel administrativo'),
  safetyFeatures('safety_features', 2, 'Recursos de segurança'),
  analytics('analytics', 1, 'Métricas e relatórios');

  const ModuleType(this.id, this.sizeMB, this.description);
  
  final String id;
  final double sizeMB;
  final String description;
}

enum ModulePriority { low, medium, high, critical }

enum ModuleStatus { 
  notDownloaded, 
  downloading, 
  downloaded, 
  loaded, 
  error 
}

class ModuleInfo {

  const ModuleInfo({
    required this.type,
    required this.status,
    this.downloadProgress = 0.0,
    this.lastUsed,
    this.usageCount = 0,
    this.priority = ModulePriority.medium,
  });
  final ModuleType type;
  final ModuleStatus status;
  final double downloadProgress;
  final DateTime? lastUsed;
  final int usageCount;
  final ModulePriority priority;

  ModuleInfo copyWith({
    ModuleType? type,
    ModuleStatus? status,
    double? downloadProgress,
    DateTime? lastUsed,
    int? usageCount,
    ModulePriority? priority,
  }) => ModuleInfo(
    type: type ?? this.type,
    status: status ?? this.status,
    downloadProgress: downloadProgress ?? this.downloadProgress,
    lastUsed: lastUsed ?? this.lastUsed,
    usageCount: usageCount ?? this.usageCount,
    priority: priority ?? this.priority,
  );
}

class ModuleLoader {
  factory ModuleLoader() => _instance;
  ModuleLoader._internal();
  static final ModuleLoader _instance = ModuleLoader._internal();

  final Map<ModuleType, ModuleInfo> _modules = {};
  final Map<ModuleType, Completer<bool>> _downloadCompleters = {};
  final StreamController<ModuleInfo> _moduleStatusController = 
      StreamController<ModuleInfo>.broadcast();

  Stream<ModuleInfo> get moduleStatusStream => _moduleStatusController.stream;

  /// Inicializa o sistema de módulos
  Future<void> initialize() async {
    dev.log('🔧 Inicializando ModuleLoader...', name: 'ModuleLoader');
    
    // Inicializar todos os módulos como não baixados
    for (final moduleType in ModuleType.values) {
      _modules[moduleType] = ModuleInfo(
        type: moduleType,
        status: ModuleStatus.notDownloaded,
      );
    }
    
    // Restaurar estado dos módulos baixados
    await _restoreModuleStates();
    
    dev.log('✅ ModuleLoader inicializado', name: 'ModuleLoader');
  }

  /// Verifica se um módulo está disponível
  bool isModuleAvailable(ModuleType module) {
    final info = _modules[module];
    return info?.status == ModuleStatus.loaded || 
           info?.status == ModuleStatus.downloaded;
  }

  /// Carrega um módulo específico
  Future<bool> loadModule(
    ModuleType module, {
    ModulePriority priority = ModulePriority.medium,
    bool forceReload = false,
  }) async {
    final currentInfo = _modules[module]!;
    
    // Se já está carregado e não force reload
    if (currentInfo.status == ModuleStatus.loaded && !forceReload) {
      return true;
    }

    try {
      dev.log('📦 Carregando módulo: ${module.id}', name: 'ModuleLoader');
      
      // Atualizar status para downloading
      _updateModuleStatus(module, currentInfo.copyWith(
        status: ModuleStatus.downloading,
        priority: priority,
      ));

      // Se já existe um download em progresso, aguardar
      if (_downloadCompleters.containsKey(module)) {
        return await _downloadCompleters[module]!.future;
      }

      // Criar completer para este download
      final completer = Completer<bool>();
      _downloadCompleters[module] = completer;

      var success = false;
      
      // Simular download baseado no tipo de módulo
      switch (module) {
        case ModuleType.corePassenger:
          success = await _downloadCorePassenger();
          break;
        case ModuleType.coreDriver:
          success = await _downloadCoreDriver();
          break;
        case ModuleType.advancedMaps:
          success = await _downloadAdvancedMaps();
          break;
        case ModuleType.chatSystem:
          success = await _downloadChatSystem();
          break;
        case ModuleType.paymentSystem:
          success = await _downloadPaymentSystem();
          break;
        case ModuleType.adminPanel:
          success = await _downloadAdminPanel();
          break;
        case ModuleType.safetyFeatures:
          success = await _downloadSafetyFeatures();
          break;
        case ModuleType.analytics:
          success = await _downloadAnalytics();
          break;
      }

      // Atualizar status final
      final finalStatus = success ? ModuleStatus.loaded : ModuleStatus.error;
      _updateModuleStatus(module, currentInfo.copyWith(
        status: finalStatus,
        downloadProgress: success ? 1.0 : 0.0,
        lastUsed: DateTime.now(),
        usageCount: currentInfo.usageCount + 1,
      ));

      // Salvar estado
      await _saveModuleState(module);

      // Completar o download
      completer.complete(success);
      _downloadCompleters.remove(module);

      if (success) {
        dev.log('✅ Módulo carregado: ${module.id}', name: 'ModuleLoader');
      } else {
        dev.log('❌ Erro ao carregar módulo: ${module.id}', name: 'ModuleLoader');
      }

      return success;
    } catch (e) {
      dev.log('❌ Erro inesperado ao carregar módulo ${module.id}: $e', 
          name: 'ModuleLoader');
      
      _updateModuleStatus(module, currentInfo.copyWith(
        status: ModuleStatus.error,
      ));
      
      final completer = _downloadCompleters.remove(module);
      completer?.complete(false);
      
      return false;
    }
  }

  /// Carrega múltiplos módulos em paralelo
  Future<Map<ModuleType, bool>> loadModules(
    List<ModuleType> modules, {
    ModulePriority priority = ModulePriority.medium,
  }) async {
    dev.log('📦 Carregando ${modules.length} módulos em paralelo', 
        name: 'ModuleLoader');
    
    final futures = modules.map((module) => 
        loadModule(module, priority: priority));
    
    final results = await Future.wait(futures);
    
    final resultMap = <ModuleType, bool>{};
    for (var i = 0; i < modules.length; i++) {
      resultMap[modules[i]] = results[i];
    }
    
    return resultMap;
  }

  /// Obtém informações de um módulo
  ModuleInfo? getModuleInfo(ModuleType module) => _modules[module];

  /// Lista todos os módulos e seus status
  List<ModuleInfo> getAllModules() => _modules.values.toList();

  /// Obtém módulos por status
  List<ModuleInfo> getModulesByStatus(ModuleStatus status) =>
      _modules.values.where((info) => info.status == status).toList();

  /// Calcula o tamanho total dos módulos baixados
  double getTotalDownloadedSize() => _modules.values
        .where((info) => info.status == ModuleStatus.loaded || 
                        info.status == ModuleStatus.downloaded)
        .fold(0, (sum, info) => sum + info.type.sizeMB);

  /// Limpa cache de um módulo
  Future<bool> clearModule(ModuleType module) async {
    try {
      final info = _modules[module];
      if (info?.status == ModuleStatus.loaded || 
          info?.status == ModuleStatus.downloaded) {
        
        _updateModuleStatus(module, info!.copyWith(
          status: ModuleStatus.notDownloaded,
          downloadProgress: 0,
        ));
        
        await _saveModuleState(module);
        
        dev.log('🧹 Módulo limpo: ${module.id}', name: 'ModuleLoader');
        return true;
      }
      return false;
    } catch (e) {
      dev.log('❌ Erro ao limpar módulo ${module.id}: $e', name: 'ModuleLoader');
      return false;
    }
  }

  void _updateModuleStatus(ModuleType module, ModuleInfo info) {
    _modules[module] = info;
    _moduleStatusController.add(info);
  }

  Future<void> _restoreModuleStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      for (final module in ModuleType.values) {
        final statusString = prefs.getString('module_${module.id}_status');
        final usageCount = prefs.getInt('module_${module.id}_usage') ?? 0;
        final lastUsedMillis = prefs.getInt('module_${module.id}_last_used');
        
        if (statusString != null) {
          final status = ModuleStatus.values.firstWhere(
            (s) => s.name == statusString,
            orElse: () => ModuleStatus.notDownloaded,
          );
          
          final lastUsed = lastUsedMillis != null 
              ? DateTime.fromMillisecondsSinceEpoch(lastUsedMillis)
              : null;
          
          _modules[module] = ModuleInfo(
            type: module,
            status: status,
            usageCount: usageCount,
            lastUsed: lastUsed,
          );
        }
      }
      
      dev.log('📂 Estados dos módulos restaurados', name: 'ModuleLoader');
    } catch (e) {
      dev.log('⚠️ Erro ao restaurar estados: $e', name: 'ModuleLoader');
    }
  }

  Future<void> _saveModuleState(ModuleType module) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final info = _modules[module]!;
      
      await prefs.setString('module_${module.id}_status', info.status.name);
      await prefs.setInt('module_${module.id}_usage', info.usageCount);
      
      if (info.lastUsed != null) {
        await prefs.setInt('module_${module.id}_last_used', 
            info.lastUsed!.millisecondsSinceEpoch);
      }
    } catch (e) {
      dev.log('⚠️ Erro ao salvar estado do módulo ${module.id}: $e', 
          name: 'ModuleLoader');
    }
  }

  // Simulação de downloads específicos dos módulos
  Future<bool> _downloadCorePassenger() async {
    await _simulateProgressiveDownload(4, 'Core Passenger');
    return true;
  }

  Future<bool> _downloadCoreDriver() async {
    await _simulateProgressiveDownload(5, 'Core Driver');
    return true;
  }

  Future<bool> _downloadAdvancedMaps() async {
    await _simulateProgressiveDownload(3, 'Advanced Maps');
    return true;
  }

  Future<bool> _downloadChatSystem() async {
    await _simulateProgressiveDownload(2, 'Chat System');
    return true;
  }

  Future<bool> _downloadPaymentSystem() async {
    await _simulateProgressiveDownload(3, 'Payment System');
    return true;
  }

  Future<bool> _downloadAdminPanel() async {
    await _simulateProgressiveDownload(4, 'Admin Panel');
    return true;
  }

  Future<bool> _downloadSafetyFeatures() async {
    await _simulateProgressiveDownload(2, 'Safety Features');
    return true;
  }

  Future<bool> _downloadAnalytics() async {
    await _simulateProgressiveDownload(1, 'Analytics');
    return true;
  }

  Future<void> _simulateProgressiveDownload(double sizeMB, String moduleName) async {
    dev.log('⬇️ Baixando $moduleName (${sizeMB}MB)...', name: 'ModuleLoader');
    
    // Simular download progressivo
    for (var i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      // Em implementação real, aqui faria o download real dos assets
    }
    
    dev.log('✅ Download concluído: $moduleName', name: 'ModuleLoader');
  }

  void dispose() {
    _moduleStatusController.close();
    _downloadCompleters.clear();
    dev.log('🧹 ModuleLoader disposed', name: 'ModuleLoader');
  }
}