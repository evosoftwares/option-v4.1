import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/driver_status.dart';
import '../services/driver_service.dart';
import '../services/user_service.dart';
import '../services/wallet_service.dart';

class DriverStatusController extends ChangeNotifier {

  DriverStatusController() {
    _driverService = DriverService(Supabase.instance.client);
  }
  DriverStatus _status = DriverStatus.initial();
  Timer? _earningsTimer;
  Timer? _onlineTimer;
  DateTime? _onlineStartTime;
  String? _driverId;
  bool _isInitialized = false;
  late final DriverService _driverService;
  
  // Callback para notificar erros de elegibilidade à UI
  Function(Map<String, dynamic>)? onEligibilityError;

  DriverStatus get status => _status;

  bool get isOnline => _status.isOnline;
  bool get isOffline => _status.isOffline;
  bool get isTransitioning => _status.isTransitioning;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('🚀 [DriverStatusController] Inicializando DriverStatusController...');
    
    try {
      // Primeiro, garantir que temos o driverId
      if (await _safeInitializeDriverIdWithRetry()) {
        print('✅ [DriverStatusController] Driver ID carregado: $_driverId');
        
        // Agora carregar o status atual do banco de dados
        final currentStatus = await _loadDriverStatus(_driverId!);
        if (currentStatus != null) {
          _updateStatus(_status.copyWith(
            status: currentStatus ? DriverOnlineStatus.online : DriverOnlineStatus.offline,
            lastStatusChange: DateTime.now(),
          ));
          
          if (currentStatus) {
            _startOnlineTimer();
            _startEarningsSimulation();
          }
        }
        
        print('✅ [DriverStatusController] Inicialização concluída com sucesso');
      } else {
        print('❌ [DriverStatusController] Falha ao carregar driver ID durante inicialização');
        // Inicializar com status offline por padrão
        _updateStatus(_status.copyWith(
          status: DriverOnlineStatus.offline,
          lastStatusChange: DateTime.now(),
        ));
      }
      
      _isInitialized = true;
    } catch (e) {
      print('❌ [DriverStatusController] Erro durante inicialização: $e');
      // Inicializar com status offline em caso de erro
      _updateStatus(_status.copyWith(
        status: DriverOnlineStatus.offline,
        lastStatusChange: DateTime.now(),
      ));
      _isInitialized = true;
    }
  }

  Future<bool?> _loadDriverStatus(String driverId) async {
    try {
      final effectiveStatus = await _driverService.getDriverEffectiveStatus(driverId);
      return effectiveStatus?.effectiveOnline;
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _earningsTimer?.cancel();
    _onlineTimer?.cancel();
    super.dispose();
  }

  Future<void> toggleOnlineStatus() async {
    print('🔵 [DRIVER_STATUS_CONTROLLER] toggleOnlineStatus iniciado');
    print('   🔹 Status atual: ${_status.status}');
    print('   🔹 Is transitioning: ${_status.isTransitioning}');
    print('   🔹 Driver ID: $_driverId');
    
    if (_status.isTransitioning) {
      print('⚠️ [DRIVER_STATUS_CONTROLLER] Já está em transição, ignorando');
      return;
    }
    
    // Salvar o estado atual antes de mudar para transitioning
    final currentStatus = _status.status;
    print('💾 [DRIVER_STATUS_CONTROLLER] Estado anterior salvo: $currentStatus');
    
    print('⚡ [DRIVER_STATUS_CONTROLLER] Mudando status para TRANSITIONING...');
    _updateStatus(_status.copyWith(
      status: DriverOnlineStatus.transitioning,
      lastStatusChange: DateTime.now(),
    ));
    print('✅ [DRIVER_STATUS_CONTROLLER] Status alterado para transitioning');

    print('⏳ [DRIVER_STATUS_CONTROLLER] Aguardando 2 segundos...');
    await Future.delayed(const Duration(seconds: 2));

    // Usar o estado anterior para decidir a próxima ação
    print('🔀 [DRIVER_STATUS_CONTROLLER] Decidindo próxima ação baseada no status anterior: $currentStatus');
    try {
      if (currentStatus == DriverOnlineStatus.online) {
        print('📴 [DRIVER_STATUS_CONTROLLER] Estado anterior era ONLINE, indo para OFFLINE...');
        await _goOffline();
        print('✅ [DRIVER_STATUS_CONTROLLER] _goOffline concluído com sucesso');
      } else {
        print('📱 [DRIVER_STATUS_CONTROLLER] Estado anterior era OFFLINE, verificando elegibilidade...');
        
        // Verificar se pode ficar online (documentos aprovados, etc.)
        final eligibilityStatus = await _driverService.getOnlineEligibilityStatus(_driverId!);
        
        if (eligibilityStatus['canGoOnline'] == true) {
          print('✅ [DRIVER_STATUS_CONTROLLER] Elegível para ficar online');
          await _goOnline();
          print('✅ [DRIVER_STATUS_CONTROLLER] _goOnline concluído com sucesso');
        } else {
          print('❌ [DRIVER_STATUS_CONTROLLER] NÃO elegível para ficar online');
          print('   🔍 Motivo: ${eligibilityStatus['reason']}');
          print('   📝 Mensagem: ${eligibilityStatus['message']}');
          
          // Voltar para offline e notificar o usuário
          _updateStatus(_status.copyWith(
            status: DriverOnlineStatus.offline,
            lastStatusChange: DateTime.now(),
          ));
          
          // Aqui você pode mostrar um dialog ou snackbar com as informações
          // Por exemplo, usando um callback ou evento
          _notifyEligibilityError(eligibilityStatus);
          return;
        }
      }
      print('✅ [DRIVER_STATUS_CONTROLLER] toggleOnlineStatus concluído');
    } catch (e, stackTrace) {
      print('❌ [DRIVER_STATUS_CONTROLLER] Erro em toggleOnlineStatus: ${e.toString()}');
      print('❌ [DRIVER_STATUS_CONTROLLER] Tipo do erro: ${e.runtimeType}');
      print('❌ [DRIVER_STATUS_CONTROLLER] Stack trace: $stackTrace');
      // Garantir que volta para o status correto em caso de erro
      print('🔄 [DRIVER_STATUS_CONTROLLER] Garantindo que status volte para OFFLINE devido ao erro...');
      _updateStatus(_status.copyWith(
        status: DriverOnlineStatus.offline,
        lastStatusChange: DateTime.now(),
      ));
      print('✅ [DRIVER_STATUS_CONTROLLER] Status revertido para OFFLINE');
      rethrow; // Re-lançar para que a UI possa tratar
    }
  }




  Future<void> _goOnline() async {
    print('🔵 [DRIVER_STATUS_CONTROLLER] _goOnline iniciado');
    print('   🔹 Driver ID: $_driverId');
    print('   🔹 Driver ID é null: ${_driverId == null}');
    
    if (_driverId == null) {
      print('❌ [DRIVER_STATUS_CONTROLLER] Driver ID é nulo, voltando para offline');
      print('🔄 [DRIVER_STATUS_CONTROLLER] Atualizando status para OFFLINE devido a driver ID nulo');
      _updateStatus(_status.copyWith(
        status: DriverOnlineStatus.offline,
        lastStatusChange: DateTime.now(),
      ));
      print('✅ [DRIVER_STATUS_CONTROLLER] Status atualizado para OFFLINE');
      return;
    }

    print('🔵 [DRIVER_STATUS_CONTROLLER] Driver ID válido: $_driverId');
    print('   🔹 Tamanho do driverId: ${_driverId!.length}');
    print('   🔹 DriverId é vazio: ${_driverId!.isEmpty}');
    
    // Validação adicional
    if (_driverId!.isEmpty) {
      print('❌ [DRIVER_STATUS_CONTROLLER] Driver ID inválido (vazio), voltando para offline');
      print('🔄 [DRIVER_STATUS_CONTROLLER] Atualizando status para OFFLINE devido a driver ID vazio');
      _updateStatus(_status.copyWith(
        status: DriverOnlineStatus.offline,
        lastStatusChange: DateTime.now(),
      ));
      print('✅ [DRIVER_STATUS_CONTROLLER] Status atualizado para OFFLINE');
      return;
    }

    try {
      print('🔗 [DRIVER_STATUS_CONTROLLER] Atualizando driver no banco (isOnline: true)...');
      print('   🔹 Chamando _driverService.updateAvailability($_driverId!, true)');
      // Atualizar a intenção online no banco de dados
      await _driverService.updateAvailability(_driverId!, true);
      print('✅ [DRIVER_STATUS_CONTROLLER] Driver atualizado no banco com sucesso');
      
      _onlineStartTime = DateTime.now();
      print('⏰ [DRIVER_STATUS_CONTROLLER] Online start time definido: $_onlineStartTime');
      
      print('🔄 [DRIVER_STATUS_CONTROLLER] Atualizando status local para ONLINE...');
      _updateStatus(_status.copyWith(
        status: DriverOnlineStatus.online,
        lastStatusChange: DateTime.now(),
      ));
      print('✅ [DRIVER_STATUS_CONTROLLER] Status atualizado para ONLINE localmente');

      print('🔧 [DRIVER_STATUS_CONTROLLER] Iniciando timers...');
      _startOnlineTimer();
      _startEarningsSimulation();
      print('✅ [DRIVER_STATUS_CONTROLLER] Timers iniciados com sucesso');
      print('✅ [DRIVER_STATUS_CONTROLLER] _goOnline concluído com sucesso');
      
    } catch (e, stackTrace) {
      print('❌ [DRIVER_STATUS_CONTROLLER] Erro em _goOnline: $e');
      print('❌ [DRIVER_STATUS_CONTROLLER] Tipo do erro: ${e.runtimeType}');
      print('❌ [DRIVER_STATUS_CONTROLLER] Stack trace: $stackTrace');
      // Se falhar, voltar para offline e re-lançar a exceção para a UI
      print('🔄 [DRIVER_STATUS_CONTROLLER] Revertendo status para OFFLINE devido ao erro');
      _updateStatus(_status.copyWith(
        status: DriverOnlineStatus.offline,
        lastStatusChange: DateTime.now(),
      ));
      print('✅ [DRIVER_STATUS_CONTROLLER] Status revertido para OFFLINE');
      print('⚠️ [DRIVER_STATUS_CONTROLLER] Relançando exceção para a UI tratar');
      rethrow; // Re-lança a exceção para que a UI possa capturar
    }
  }

  Future<void> _goOffline() async {
    print('🔵 [DRIVER_STATUS_CONTROLLER] _goOffline iniciado');
    print('   🔹 Driver ID: $_driverId');
    print('   🔹 Driver ID é null: ${_driverId == null}');
    
    if (_driverId != null) {
      print('🔵 [DRIVER_STATUS_CONTROLLER] Driver ID válido: $_driverId');
      print('   🔹 Tamanho do driverId: ${_driverId!.length}');
      print('   🔹 DriverId é vazio: ${_driverId!.isEmpty}');
      
      // Validação adicional
      if (_driverId!.isEmpty) {
        print('❌ [DRIVER_STATUS_CONTROLLER] Driver ID inválido (vazio), pulando atualização no banco');
      } else {
        try {
          print('🔗 [DRIVER_STATUS_CONTROLLER] Atualizando driver no banco (isOnline: false)...');
          print('   🔹 Chamando _driverService.updateAvailability($_driverId!, false)');
          // Atualizar a intenção offline no banco de dados
          await _driverService.updateAvailability(_driverId!, false);
          print('✅ [DRIVER_STATUS_CONTROLLER] Driver atualizado no banco com sucesso');
        } catch (e, stackTrace) {
          print('⚠️ [DRIVER_STATUS_CONTROLLER] Erro ao atualizar no banco (continuando): $e');
          print('⚠️ [DRIVER_STATUS_CONTROLLER] Tipo do erro: ${e.runtimeType}');
          print('⚠️ [DRIVER_STATUS_CONTROLLER] Stack trace: $stackTrace');
          // Continue mesmo se falhar a atualização no banco
        }
      }
    } else {
      print('⚠️ [DRIVER_STATUS_CONTROLLER] Driver ID é nulo, pulando atualização no banco');
    }

    print('🧹 [DRIVER_STATUS_CONTROLLER] Limpando timers e variáveis...');
    _onlineStartTime = null;
    _earningsTimer?.cancel();
    _onlineTimer?.cancel();
    print('✅ [DRIVER_STATUS_CONTROLLER] Timers cancelados e variáveis limpas');

    print('🔄 [DRIVER_STATUS_CONTROLLER] Atualizando status local para OFFLINE...');
    _updateStatus(_status.copyWith(
      status: DriverOnlineStatus.offline,
      lastStatusChange: DateTime.now(),
    ));
    print('✅ [DRIVER_STATUS_CONTROLLER] Status local atualizado para OFFLINE');
    print('✅ [DRIVER_STATUS_CONTROLLER] _goOffline concluído');
  }

  void _startOnlineTimer() {
    _onlineTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_onlineStartTime != null) {
        final newOnlineTime = DateTime.now().difference(_onlineStartTime!) + _status.onlineTime;
        _updateStatus(_status.copyWith(onlineTime: newOnlineTime));
      }
    });
  }

  void _startEarningsSimulation() {
    _earningsTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final random = (DateTime.now().millisecondsSinceEpoch % 100) / 100;
      final increment = 5.0 + (random * 15.0);
      final newEarnings = _status.todayEarnings + increment;
      final newTrips = _status.tripsCompleted + (random > 0.7 ? 1 : 0);

      _updateStatus(_status.copyWith(
        todayEarnings: newEarnings,
        tripsCompleted: newTrips,
      ),);
    });
  }

  void _updateStatus(DriverStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  String get onlineTimeText {
    final duration = _status.onlineTime;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m online hoje';
    } else if (minutes > 0) {
      return '${minutes}m online hoje';
    } else {
      return 'Recém conectado';
    }
  }

  /// Notifica erro de elegibilidade à UI
  void _notifyEligibilityError(Map<String, dynamic> eligibilityStatus) {
    print('🔔 [DRIVER_STATUS_CONTROLLER] Notificando erro de elegibilidade à UI');
    
    if (onEligibilityError != null) {
      onEligibilityError!(eligibilityStatus);
    } else {
      print('⚠️ [DRIVER_STATUS_CONTROLLER] Nenhum callback de erro configurado');
    }
  }


  /// Tenta carregar o driverId com retry e backoff exponencial
  Future<bool> _loadDriverIdWithRetry({int maxRetries = 3, Duration initialDelay = const Duration(seconds: 1)}) async {
    print('🔵 [DRIVER_STATUS_CONTROLLER] _loadDriverIdWithRetry iniciado');
    print('   🔹 maxRetries: $maxRetries');
    print('   🔹 initialDelay: $initialDelay');
    
    int attempt = 0;
    Duration delay = initialDelay;
    
    while (attempt < maxRetries) {
      try {
        print('🔄 [DRIVER_STATUS_CONTROLLER] Tentativa ${attempt + 1}/$maxRetries para carregar driver ID');
        
        print('🔗 [DRIVER_STATUS_CONTROLLER] Buscando usuário atual...');
        final user = await UserService.getCurrentUser();
        print('📊 [DRIVER_STATUS_CONTROLLER] Usuário atual obtido: ${user?.id}');
        
        if (user != null) {
          print('🔗 [DRIVER_STATUS_CONTROLLER] Buscando driver ID para usuário ${user.id}...');
          _driverId = await WalletService().getDriverIdForUser(user.id);
          print('📊 [DRIVER_STATUS_CONTROLLER] Driver ID obtido: $_driverId');
          
          if (_driverId != null) {
            print('✅ [DRIVER_STATUS_CONTROLLER] Driver ID carregado com sucesso: $_driverId');
            return true;
          } else {
            print('⚠️ [DRIVER_STATUS_CONTROLLER] Driver ID é null para usuário ${user.id}');
          }
        } else {
          print('⚠️ [DRIVER_STATUS_CONTROLLER] Usuário atual é null');
        }
        
        print('⚠️ [DRIVER_STATUS_CONTROLLER] Tentativa ${attempt + 1} falhou, aguardando ${delay.inSeconds}s...');
        await Future.delayed(delay);
        delay *= 2; // Backoff exponencial
        attempt++;
        
      } catch (e, stackTrace) {
        print('❌ [DRIVER_STATUS_CONTROLLER] Erro na tentativa ${attempt + 1}: $e');
        print('❌ [DRIVER_STATUS_CONTROLLER] Stack trace: $stackTrace');
        if (attempt == maxRetries - 1) {
          print('❌ [DRIVER_STATUS_CONTROLLER] Todas as tentativas falharam');
          return false;
        }
        
        await Future.delayed(delay);
        delay *= 2;
        attempt++;
      }
    }
    
    print('⚠️ [DRIVER_STATUS_CONTROLLER] Todas as tentativas esgotadas sem sucesso');
    return false;
  }

  /// Versão melhorada do _safeInitializeDriverId com retry
  Future<bool> _safeInitializeDriverIdWithRetry() async {
    print('🔵 [DRIVER_STATUS_CONTROLLER] _safeInitializeDriverIdWithRetry iniciado');
    print('   🔹 _isInitialized: $_isInitialized');
    print('   🔹 _driverId: $_driverId');
    print('   🔹 _driverId é null: ${_driverId == null}');
    
    if (_isInitialized && _driverId != null) {
      print('✅ [DRIVER_STATUS_CONTROLLER] Driver ID já está inicializado: $_driverId');
      return true;
    }
    
    print('🔗 [DRIVER_STATUS_CONTROLLER] Driver ID não inicializado, chamando _loadDriverIdWithRetry...');
    final result = await _loadDriverIdWithRetry();
    print('📊 [DRIVER_STATUS_CONTROLLER] Resultado de _loadDriverIdWithRetry: $result');
    print('   🔹 _driverId após carga: $_driverId');
    
    if (result && _driverId != null) {
      print('✅ [DRIVER_STATUS_CONTROLLER] Driver ID carregado com sucesso: $_driverId');
    } else if (!result) {
      print('❌ [DRIVER_STATUS_CONTROLLER] Falha ao carregar Driver ID');
    } else if (_driverId == null) {
      print('⚠️ [DRIVER_STATUS_CONTROLLER] _loadDriverIdWithRetry retornou true mas _driverId ainda é null');
    }
    
    return result;
  }
}