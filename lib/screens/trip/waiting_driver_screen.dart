import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/supabase/driver.dart';
import '../../models/supabase/trip_request.dart';
import '../../services/cancellation_fee_service.dart';
import '../../services/driver_service.dart';
import '../../services/trip_request_manager.dart';
import '../../services/trip_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/logo_branding.dart';
import '../passenger/passenger_trip_screen.dart';

class WaitingDriverScreen extends StatefulWidget {

  const WaitingDriverScreen({
    super.key,
    required this.tripRequestId,
  });
  static const String routeName = '/waiting-driver';

  final String tripRequestId;

  static WaitingDriverScreen fromArgs(Object? args) {
    final map = args! as Map<String, dynamic>;
    return WaitingDriverScreen(
      tripRequestId: map['tripRequestId'] as String,
    );
  }

  @override
  State<WaitingDriverScreen> createState() => _WaitingDriverScreenState();
}

class _WaitingDriverScreenState extends State<WaitingDriverScreen>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late final TripService _tripService;
  late final TripRequestManager _tripRequestManager;
  late final AnimationController _pulseController;
  late final AnimationController _progressController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _progressAnimation;
  
  TripRequest? _tripRequest;
  bool _isLoading = true;
  String? _error;
  StreamSubscription<List<TripRequest>>? _tripRequestSubscription;
  Timer? _statusTimer;
  
  // Estados de busca
  String _currentStatus = 'searching';
  int _contactedDrivers = 0;
  int _totalDrivers = 5;
  DateTime? _searchStartTime;
  
  // Dados reais do fallback
  String? _currentTargetDriverId;
  List<String> _fallbackDrivers = [];
  int _currentFallbackIndex = 0;
  final int _timeoutCount = 0;
  StreamSubscription<TripRequest?>? _requestStatusSubscription;

  @override
  void initState() {
    super.initState();
    developer.log(
      'WaitingDriverScreen: Inicializando tela para tripRequestId: ${widget.tripRequestId}',
      name: 'WaitingDriverScreen',
      level: 800,
    );
    
    _tripService = TripService(_supabase);
    _tripRequestManager = TripRequestManager(_supabase);
    _searchStartTime = DateTime.now();
    
    developer.log(
      'WaitingDriverScreen: Serviços inicializados, iniciando busca às ${_searchStartTime?.toIso8601String()}',
      name: 'WaitingDriverScreen',
      level: 800,
    );
    
    _setupAnimations();
    _loadTripRequest();
    _startRequestMonitoring();
  }
  
  void _setupAnimations() {
    // Animação de pulso
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Animação de progresso
    _progressController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.linear,
    ));
    
    _pulseController.repeat(reverse: true);
  }
  
  void _startRealTimeMonitoring() {
    // Monitora mudanças em tempo real na solicitação
    _requestStatusSubscription = _tripRequestManager
        .monitorRequestStatus(widget.tripRequestId)
        .listen((request) {
      if (request != null && mounted) {
        _updateFallbackProgress(request);
      }
    });
  }
  
  void _updateFallbackProgress(TripRequest request) {
    developer.log(
      'WaitingDriverScreen: Atualizando progresso - Status: ${request.status}, TargetDriver: ${request.targetDriverId}',
      name: 'WaitingDriverScreen',
      level: 800,
    );
    
    setState(() {
      _tripRequest = request;
      
      // Atualizar dados do fallback
      _currentTargetDriverId = request.targetDriverId;
      _fallbackDrivers = request.fallbackDrivers ?? [];
      
      developer.log(
        'WaitingDriverScreen: Fallback drivers: ${_fallbackDrivers.length}, Current index: $_currentFallbackIndex',
        name: 'WaitingDriverScreen',
        level: 800,
      );
      
      // Calcular índice atual do fallback baseado no motorista alvo
      if (_currentTargetDriverId != null && _fallbackDrivers.isNotEmpty) {
        _currentFallbackIndex = _fallbackDrivers.indexOf(_currentTargetDriverId!);
        if (_currentFallbackIndex == -1) _currentFallbackIndex = 0;
      } else {
        _currentFallbackIndex = 0;
      }
      
      // Incrementar contador de timeout se necessário
      if (request.status == 'pending' && _currentTargetDriverId != null) {
        // Lógica para detectar timeout pode ser implementada aqui
        // Por enquanto, mantemos o valor atual
      }
      
      // Calcular progresso
      _totalDrivers = _fallbackDrivers.length + 1; // +1 para o motorista principal
      _contactedDrivers = _currentFallbackIndex + 1;
      
      // Determinar status baseado no estado real
      if (request.status == 'pending') {
        if (_currentTargetDriverId != null) {
          if (_currentFallbackIndex == 0) {
            _currentStatus = 'contacting';
            developer.log(
              'WaitingDriverScreen: Status alterado para CONTACTING - '
              'Driver: $_currentTargetDriverId, Fallback: $_currentFallbackIndex',
              name: 'WaitingDriverScreen',
              level: 800,
            );
          } else {
            _currentStatus = 'fallback';
            developer.log(
              'WaitingDriverScreen: Status alterado para FALLBACK - '
              'Driver: $_currentTargetDriverId, Fallback: $_currentFallbackIndex/$_totalDrivers',
              name: 'WaitingDriverScreen',
              level: 800,
            );
          }
          
          // Calcular tempo restante para timeout
          if (request.expiresAt != null) {
            final timeLeft = request.expiresAt!.difference(DateTime.now());
            if (timeLeft.inSeconds > 0) {
              _progressController.reset();
              _progressController.animateTo(
                1.0 - (timeLeft.inSeconds / 10.0),
                duration: Duration(seconds: timeLeft.inSeconds),
              );
            }
          }
        } else {
          _currentStatus = 'searching';
          developer.log(
            'WaitingDriverScreen: Status alterado para SEARCHING - Aguardando drivers',
            name: 'WaitingDriverScreen',
            level: 800,
          );
        }
      } else if (request.status == 'accepted') {
        _currentStatus = 'accepted';
        developer.log(
          'WaitingDriverScreen: Status alterado para ACCEPTED - Driver: $_currentTargetDriverId',
          name: 'WaitingDriverScreen',
          level: 800,
        );
      } else if (request.status == 'expired') {
        _currentStatus = 'expired';
        
        final searchDuration = _searchStartTime != null 
            ? DateTime.now().difference(_searchStartTime!)
            : Duration.zero;
            
        developer.log(
          'WaitingDriverScreen: STATUS EXPIRED DETECTADO! '
          'Duração da busca: ${searchDuration.inMinutes}min ${searchDuration.inSeconds % 60}s, '
          'Drivers contatados: $_contactedDrivers/$_totalDrivers, '
          'Fallback index: $_currentFallbackIndex',
          name: 'WaitingDriverScreen',
          level: 1000, // Nível alto para status crítico
        );
        
        // Exibir diálogo de nenhum motorista encontrado
        WidgetsBinding.instance.addPostFrameCallback((_) {
          developer.log(
            'WaitingDriverScreen: Exibindo diálogo de motorista não encontrado',
            name: 'WaitingDriverScreen',
            level: 900,
          );
          _handleRequestExpired();
        });
      }
    });
  }

  void _startRequestMonitoring() {
    // Inicia monitoramento em tempo real
    _startRealTimeMonitoring();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    _tripRequestSubscription?.cancel();
    _requestStatusSubscription?.cancel();
    _statusTimer?.cancel();
    _tripRequestManager.dispose();
    super.dispose();
  }

  Future<void> _loadTripRequest() async {
    try {
      final tripRequest = await _tripService.getTripRequest(widget.tripRequestId);
      if (mounted) {
        setState(() {
          _tripRequest = tripRequest;
          _isLoading = false;
        });
        _subscribeToTripRequestUpdates();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeToTripRequestUpdates() {
    _tripRequestSubscription?.cancel();
    _tripRequestSubscription = _tripService
        .subscribeToTripRequests()
        .where((requests) => requests.any((req) => req.id == widget.tripRequestId))
        .listen((requests) {
      final updatedRequest = requests.firstWhere(
        (req) => req.id == widget.tripRequestId,
        orElse: () => _tripRequest!,
      );
      
      if (mounted) {
        setState(() {
          _tripRequest = updatedRequest;
        });
        
        // Navegar para PassengerTripScreen quando motorista aceitar
        if (updatedRequest.isAccepted && updatedRequest.acceptedByDriverId != null) {
          _navigateToTripScreen(updatedRequest.acceptedByDriverId!);
        }
      }
    });
  }

  Future<void> _navigateToTripScreen(String driverId) async {
    try {
      // Buscar a viagem criada pelo motorista
      final trips = await _tripService.getTrips(
        passengerId: _tripRequest!.passengerId,
        status: 'accepted',
      );
      
      final trip = trips.firstWhere(
        (t) => t.driverId == driverId && t.tripRequestId == widget.tripRequestId,
        orElse: () => throw Exception('Viagem não encontrada'),
      );
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          PassengerTripScreen.routeName,
          arguments: {'tripId': trip.id},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao navegar para viagem: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _cancelTrip() async {
    developer.log(
      'WaitingDriverScreen: Iniciando cancelamento da viagem - '
      'TripRequest: ${widget.tripRequestId}, Status atual: $_currentStatus',
      name: 'WaitingDriverScreen',
      level: 900,
    );
    
    try {
      // Mostrar confirmação de cancelamento
      final shouldCancel = await _showCancellationConfirmation();
      if (!shouldCancel) {
        developer.log(
          'WaitingDriverScreen: Cancelamento abortado pelo usuário',
          name: 'WaitingDriverScreen',
          level: 800,
        );
        return;
      }

      developer.log(
        'WaitingDriverScreen: Usuário confirmou cancelamento, processando...',
        name: 'WaitingDriverScreen',
        level: 900,
      );

      // Cancela o monitoramento da solicitação direcionada
      _tripRequestManager.cancelMonitoring(widget.tripRequestId);
      
      // Processar cancelamento com possível taxa
      await _processCancellationWithFee();
      
      developer.log(
        'WaitingDriverScreen: Cancelamento processado com sucesso, navegando de volta',
        name: 'WaitingDriverScreen',
        level: 900,
      );
      
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      developer.log(
        'WaitingDriverScreen: Erro durante cancelamento: $e',
        name: 'WaitingDriverScreen',
        level: 1000,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cancelar viagem: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<bool> _showCancellationConfirmation() async {
    if (!mounted) return false;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar viagem?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tem certeza que deseja cancelar esta viagem?'),
            const SizedBox(height: 12),
            if (_tripRequest?.acceptedByDriverId != null) ...[
              const Text(
                'Atenção: Como o motorista já aceitou sua solicitação, poderá ser cobrada uma taxa de cancelamento.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text(
                'A taxa será calculada baseada na distância que o motorista já percorreu até você.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Manter viagem'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancelar mesmo assim'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  Future<void> _processCancellationWithFee() async {
    if (_tripRequest == null) {
      // Fallback para o método original se não tiver dados da solicitação
      await _tripService.updateTripRequestStatus(
        id: widget.tripRequestId,
        status: 'cancelled',
      );
      return;
    }

    // Usar o novo serviço de cancelamento com taxa
    final cancellationService = CancellationFeeService(Supabase.instance.client);
    
    // Buscar dados do motorista se disponível
    Driver? driver;
    if (_tripRequest!.acceptedByDriverId != null) {
      try {
        final driverService = DriverService(Supabase.instance.client);
        driver = await driverService.getDriver(_tripRequest!.acceptedByDriverId!);
      } catch (e) {
        print('Erro ao buscar dados do motorista: $e');
      }
    }

    // Criar contexto de cancelamento
    final cancellationContext = CancellationContext(
      tripRequest: _tripRequest!,
      cancelledBy: 'passenger',
      driver: driver,
    );

    // Processar cancelamento com possível cobrança de taxa
    await cancellationService.processCancellation(cancellationContext);
  }

  /// Exibe diálogo quando nenhum motorista é encontrado
  void _handleRequestExpired() {
    if (!mounted) {
      developer.log(
        'WaitingDriverScreen: _handleRequestExpired chamado mas widget não está montado',
        name: 'WaitingDriverScreen',
        level: 900,
      );
      return;
    }
    
    developer.log(
      'WaitingDriverScreen: Exibindo diálogo de expired - TripRequest: ${widget.tripRequestId}',
      name: 'WaitingDriverScreen',
      level: 900,
    );
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Nenhum motorista encontrado'),
        content: const Text(
          'Não conseguimos encontrar um motorista disponível no momento. '
          'Tente novamente em alguns minutos.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              developer.log(
                'WaitingDriverScreen: Usuário pressionou OK no diálogo de expired',
                name: 'WaitingDriverScreen',
                level: 800,
              );
              Navigator.of(context).pop(); // Fechar dialog
              Navigator.of(context).pop(); // Voltar para tela anterior
              
              developer.log(
                'WaitingDriverScreen: Navegação de volta concluída após expired',
                name: 'WaitingDriverScreen',
                level: 800,
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const StandardAppBar(title: 'Aguardando motorista'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(error: _error!, onRetry: _loadTripRequest)
              : _tripRequest != null
                  ? _WaitingContent(
                      tripRequest: _tripRequest!,
                      pulseAnimation: _pulseAnimation,
                      progressAnimation: _progressAnimation,
                      currentStatus: _currentStatus,
                      contactedDrivers: _contactedDrivers,
                      totalDrivers: _totalDrivers,
                      searchStartTime: _searchStartTime!,
                      onCancel: _cancelTrip,
                    )
                  : const Center(child: Text('Solicitação não encontrada')),
    );
  }
}

class _WaitingContent extends StatelessWidget {
  const _WaitingContent({
    required this.tripRequest,
    required this.pulseAnimation,
    required this.progressAnimation,
    required this.currentStatus,
    required this.contactedDrivers,
    required this.totalDrivers,
    required this.searchStartTime,
    required this.onCancel,
  });

  final TripRequest tripRequest;
  final Animation<double> pulseAnimation;
  final Animation<double> progressAnimation;
  final String currentStatus;
  final int contactedDrivers;
  final int totalDrivers;
  final DateTime searchStartTime;
  final VoidCallback onCancel;

  String get _statusTitle {
    switch (currentStatus) {
      case 'searching':
        return 'Procurando motorista';
      case 'contacting':
        return 'Contatando motorista';
      case 'waiting_response':
        return 'Aguardando resposta';
      case 'fallback':
        return 'Procurando outro motorista';
      case 'expanding_search':
        return 'Expandindo busca';
      case 'expired':
        return 'Nenhum motorista encontrado';
      default:
        return 'Procurando motorista';
    }
  }

  String get _statusSubtitle {
    switch (currentStatus) {
      case 'searching':
        return 'Analisando motoristas próximos...';
      case 'contacting':
        return 'Enviando solicitação para motorista $contactedDrivers de $totalDrivers';
      case 'waiting_response':
        return 'Aguardando confirmação do motorista...';
      case 'fallback':
        return 'Buscando alternativas para você...';
      case 'expanding_search':
        return 'Procurando em uma área maior...';
      case 'expired':
        return 'Não conseguimos encontrar um motorista disponível no momento';
      default:
        return 'Estamos encontrando o melhor motorista para você';
    }
  }

  Color _getStatusColor(BuildContext context) {
    switch (currentStatus) {
      case 'searching':
        return AppColors.blue;
      case 'contacting':
        return AppColors.info;
      case 'waiting_response':
        return AppColors.warning;
      case 'fallback':
        return AppColors.warning;
      case 'expanding_search':
        return AppColors.blue;
      case 'expired':
        return AppColors.error;
      default:
        return AppColors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final elapsedTime = DateTime.now().difference(searchStartTime);
    final minutes = elapsedTime.inMinutes;
    final seconds = elapsedTime.inSeconds % 60;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Header com status
            _StatusHeader(
              title: _statusTitle,
              subtitle: _statusSubtitle,
              elapsedTime: '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Indicador de status animado
                  _AnimatedStatusIndicator(
                    animation: pulseAnimation,
                    status: currentStatus,
                    statusColor: _getStatusColor(context),
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Indicador de progresso
                  _ProgressIndicator(
                    animation: progressAnimation,
                    contactedDrivers: contactedDrivers,
                    totalDrivers: totalDrivers,
                    currentStatus: currentStatus,
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Informações da viagem
                  _TripInfoCard(tripRequest: tripRequest),
                ],
              ),
            ),
            
            // Seção de ações
            _ActionSection(onCancel: onCancel),
          ],
        ),
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({
    required this.title,
    required this.subtitle,
    required this.elapsedTime,
  });

  final String title;
  final String subtitle;
  final String elapsedTime;

  @override
  Widget build(BuildContext context) => Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.lightOnSurface,
                fontWeight: AppTypography.semiBold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Text(
                elapsedTime,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.gray600,
                  fontWeight: AppTypography.medium,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.gray600,
            ),
          ),
        ),
      ],
    );
}

class _AnimatedStatusIndicator extends StatelessWidget {
  const _AnimatedStatusIndicator({
    required this.animation,
    required this.status,
    required this.statusColor,
  });

  final Animation<double> animation;
  final String status;
  final Color statusColor;

  IconData get _statusIcon {
    switch (status) {
      case 'searching':
        return Icons.search;
      case 'contacting':
        return Icons.phone;
      case 'waiting_response':
        return Icons.hourglass_empty;
      case 'fallback':
        return Icons.refresh;
      case 'expanding_search':
        return Icons.zoom_out_map;
      case 'expired':
        return Icons.error_outline;
      default:
        return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Transform.scale(
        scale: animation.value,
        child: Container(
          width: AppSpacing.iconXxl * 3,
          height: AppSpacing.iconXxl * 3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor.withOpacity(0.1),
            border: Border.all(
              color: statusColor.withOpacity(0.3),
              width: AppSpacing.borderMedium,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.2),
                blurRadius: AppSpacing.lg,
                spreadRadius: AppSpacing.sm,
              ),
            ],
          ),
          child: Icon(
            _statusIcon,
            size: AppSpacing.iconXl * 1.5,
            color: statusColor,
          ),
        ),
      ),
    );
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({
    required this.animation,
    required this.contactedDrivers,
    required this.totalDrivers,
    required this.currentStatus,
  });

  final Animation<double> animation;
  final int contactedDrivers;
  final int totalDrivers;
  final String currentStatus;

  @override
  Widget build(BuildContext context) {
    if (currentStatus == 'searching') {
      return Column(
        children: [
          const SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: AppColors.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Analisando motoristas...',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.gray600,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalDrivers, (index) {
            final isActive = index < contactedDrivers;
            final isCurrent = index == contactedDrivers - 1;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              width: AppSpacing.md,
              height: AppSpacing.md,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive 
                    ? (isCurrent ? AppColors.warning : AppColors.success)
                    : AppColors.gray300,
                border: isCurrent 
                    ? Border.all(color: AppColors.warning, width: 2)
                    : null,
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) => SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              value: currentStatus == 'waiting_response' ? null : animation.value,
              backgroundColor: AppColors.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(
                currentStatus == 'waiting_response' ? AppColors.warning : AppColors.info,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Motorista $contactedDrivers de $totalDrivers',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.gray600,
            fontWeight: AppTypography.medium,
          ),
        ),
      ],
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: AppSpacing.buttonHeight,
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              foregroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Text(
              'Cancelar viagem',
              style: AppTypography.buttonText.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Você pode cancelar a qualquer momento',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.gray500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
}

class _TripInfoCard extends StatelessWidget {
  const _TripInfoCard({required this.tripRequest});

  final TripRequest tripRequest;

  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: AppSpacing.md,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalhes da viagem',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.lightOnSurface,
              fontWeight: AppTypography.semiBold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Origem
          _InfoRow(
            icon: Icons.radio_button_checked,
            iconColor: AppColors.blue,
            title: 'Origem',
            subtitle: tripRequest.originAddress,
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Destino
          _InfoRow(
            icon: Icons.location_on,
            iconColor: AppColors.error,
            title: 'Destino',
            subtitle: tripRequest.destinationAddress,
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Categoria e preço em linha
          Row(
            children: [
              Expanded(
                child: _InfoRow(
                  icon: Icons.directions_car,
                  iconColor: AppColors.gray600,
                  title: 'Categoria',
                  subtitle: tripRequest.vehicleCategory.toUpperCase(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _InfoRow(
                  icon: Icons.attach_money,
                  iconColor: AppColors.success,
                  title: 'Preço estimado',
                  subtitle: 'R\$ ${tripRequest.estimatedFare.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: AppSpacing.iconSm,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.gray600,
                  fontWeight: AppTypography.medium,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.lightOnSurface,
                  fontWeight: AppTypography.semiBold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: const Icon(
                Icons.error_outline,
                size: AppSpacing.iconXl,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Ops! Algo deu errado',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.lightOnSurface,
                fontWeight: AppTypography.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: Text(
                'Tentar novamente',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}