import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'module_loader.dart';
import 'smart_preloader.dart';

class ShellApp {
  factory ShellApp() => _instance;
  ShellApp._internal();
  static final ShellApp _instance = ShellApp._internal();

  final ModuleLoader _moduleLoader = ModuleLoader();
  final SmartPreloader _smartPreloader = SmartPreloader();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    dev.log('🚀 Inicializando Shell App...', name: 'ShellApp');

    await _moduleLoader.initialize();
    await _smartPreloader.initialize();

    _isInitialized = true;
    dev.log('✅ Shell App inicializado', name: 'ShellApp');
  }

  Future<bool> ensureModuleLoaded(ModuleType module, {
    ModulePriority priority = ModulePriority.high,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_moduleLoader.isModuleAvailable(module)) {
      return true;
    }

    dev.log('⏳ Carregando módulo sob demanda: ${module.id}', name: 'ShellApp');
    return _moduleLoader.loadModule(module, priority: priority);
  }

  Future<Widget> loadScreenWidget(String screenName, {
    Map<String, dynamic>? arguments,
  }) async {
    dev.log('📱 Carregando tela: $screenName', name: 'ShellApp');

    final requiredModule = _getRequiredModule(screenName);
    if (requiredModule != null) {
      final success = await ensureModuleLoaded(requiredModule);
      if (!success) {
        return _buildErrorScreen('Erro ao carregar módulo ${requiredModule.id}');
      }
    }

    return _buildScreen(screenName, arguments);
  }

  ModuleType? _getRequiredModule(String screenName) {
    switch (screenName) {
      case 'passenger_home':
      case 'trip_request':
      case 'waiting_driver':
        return ModuleType.corePassenger;
      
      case 'driver_home':
      case 'driver_trip':
      case 'driver_earnings':
        return ModuleType.coreDriver;
      
      case 'maps':
      case 'navigation':
      case 'route_planning':
        return ModuleType.advancedMaps;
      
      case 'chat':
      case 'support_chat':
        return ModuleType.chatSystem;
      
      case 'payments':
      case 'wallet':
      case 'payment_methods':
        return ModuleType.paymentSystem;
      
      case 'admin_dashboard':
      case 'admin_users':
        return ModuleType.adminPanel;
      
      case 'safety_center':
      case 'emergency':
        return ModuleType.safetyFeatures;
      
      case 'analytics':
      case 'reports':
        return ModuleType.analytics;
      
      default:
        return null;
    }
  }

  Widget _buildScreen(String screenName, Map<String, dynamic>? arguments) {
    switch (screenName) {
      case 'passenger_home':
        return _buildPassengerHome(arguments);
      case 'driver_home':
        return _buildDriverHome(arguments);
      case 'maps':
        return _buildMapsScreen(arguments);
      case 'chat':
        return _buildChatScreen(arguments);
      case 'payments':
        return _buildPaymentsScreen(arguments);
      default:
        return _buildPlaceholderScreen(screenName);
    }
  }

  Widget _buildPassengerHome(Map<String, dynamic>? arguments) => Scaffold(
      appBar: AppBar(title: const Text('Passageiro')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car, size: 64),
            SizedBox(height: 16),
            Text('Módulo Passageiro Carregado'),
            Text('Shell App - Otimizado'),
          ],
        ),
      ),
    );

  Widget _buildDriverHome(Map<String, dynamic>? arguments) => Scaffold(
      appBar: AppBar(title: const Text('Motorista')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_taxi, size: 64),
            SizedBox(height: 16),
            Text('Módulo Motorista Carregado'),
            Text('Shell App - Otimizado'),
          ],
        ),
      ),
    );

  Widget _buildMapsScreen(Map<String, dynamic>? arguments) => Scaffold(
      appBar: AppBar(title: const Text('Mapas')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64),
            SizedBox(height: 16),
            Text('Módulo Maps Carregado'),
            Text('Google Maps Lazy Loading'),
          ],
        ),
      ),
    );

  Widget _buildChatScreen(Map<String, dynamic>? arguments) => Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat, size: 64),
            SizedBox(height: 16),
            Text('Módulo Chat Carregado'),
            Text('Sistema de Mensagens'),
          ],
        ),
      ),
    );

  Widget _buildPaymentsScreen(Map<String, dynamic>? arguments) => Scaffold(
      appBar: AppBar(title: const Text('Pagamentos')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64),
            SizedBox(height: 16),
            Text('Módulo Pagamentos Carregado'),
            Text('Sistema de Transações'),
          ],
        ),
      ),
    );

  Widget _buildPlaceholderScreen(String screenName) => Scaffold(
      appBar: AppBar(title: Text(screenName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings, size: 64),
            const SizedBox(height: 16),
            Text('Tela: $screenName'),
            const Text('Shell App - Módulo Básico'),
          ],
        ),
      ),
    );

  Widget _buildErrorScreen(String error) => Scaffold(
      appBar: AppBar(title: const Text('Erro')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erro: $error'),
            const Text('Shell App'),
          ],
        ),
      ),
    );

  void dispose() {
    _moduleLoader.dispose();
    _smartPreloader.dispose();
    dev.log('🧹 Shell App disposed', name: 'ShellApp');
  }
}