import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../controllers/driver_status_controller.dart';
import '../../controllers/driver_status_manager.dart';
import '../../exceptions/app_exceptions.dart';
import '../../models/driver_status.dart';
import '../../models/supabase/trip.dart';
import '../../services/driver_service.dart';
// import '../../services/fcm_service.dart'; // Removido - usando OneSignal
import '../../services/driver_document_service.dart';
import '../../services/location_service.dart';
import '../../services/map_style_service.dart';
import '../../services/user_service.dart';
import '../../services/wallet_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/driver_earnings_widget.dart';
import '../../widgets/feedback/index.dart';

/// Production-ready main driver screen with enhanced UI and Uber-like design
class DriverHomeScreen extends StatefulWidget {
  /// Creates a new instance of [DriverHomeScreen]
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with TickerProviderStateMixin {
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  BitmapDescriptor? _carIcon;
  BitmapDescriptor? _blackCarIcon;

  late final LocationService _locationService;
  late final DriverStatusController _statusController;
  late final AnimationController _buttonController;
  late final Animation<double> _buttonScaleAnimation;

  // Estado para documentos pendentes
  bool _hasDocumentsPending = false;
  int _pendingDocsCount = 0;
  String? _driverId;

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<List<Trip>>? _tripSub;
  String? _currentTripId;
  Timer? _approvalStatusTimer;
  Timer? _bannerUpdateTimer;

  bool _revertingOnlineDueToPermission = false;
  bool _isProcessingStatusChange = false;

  DateTime? _lastLocationSentAt;
  LatLng? _lastSentLatLng;

  // UI States

  static const CameraPosition _initialPos = CameraPosition(
    target: LatLng(-23.5505, -46.6333),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    print('🚀 [DRIVER_HOME] Iniciando tela principal do motorista');
    
    _initControllers();
    _initServices();
    _loadCarIcon();
    _checkDocumentsStatus();
    
    // Iniciar timer automático para atualização do banner a cada 5 segundos
    _startBannerUpdateTimer();
    
    // Aguardar um frame para garantir que o widget está montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initActiveTrips();
      }
    });
  }

  /// Creates a custom marker icon from a Material icon
  Future<BitmapDescriptor> _createMarkerFromIcon(IconData icon,
      {Color color = Colors.blue, double size = 50}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    final Paint paint = Paint()..color = color;
    
    // Draw a circle background
    canvas.drawCircle(Offset(size/2, size/2), size/2, paint);
    
    // Draw the icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final iconStr = String.fromCharCode(icon.codePoint);
    final textStyle = TextStyle(
      fontFamily: icon.fontFamily,
      package: icon.fontPackage,
      color: Colors.white, // White icon on colored background
      fontSize: size * 0.6, // Make icon slightly smaller than the circle
    );
    
    textPainter.text = TextSpan(text: iconStr, style: textStyle);
    textPainter.layout();
    textPainter.paint(canvas, Offset(size * 0.2, size * 0.2));
    
    final ui.Image img = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  Future<void> _loadCarIcon() async {
    // Create a default attractive icon as fallback
    _blackCarIcon = await _createMarkerFromIcon(
      Icons.local_taxi, // Use taxi icon as fallback
      color: Colors.deepOrange, // Attractive orange color
      size: 50,
    );

    try {
      _carIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(50, 50)),
        'assets/images/car_marker.png',
      );
    } catch (e) {
      // Create a Material icon as fallback instead of black marker
      try {
        _carIcon = await _createMarkerFromIcon(
          Icons.directions_car, // Use car icon
          color: Colors.blue, // Blue color for the marker
          size: 50, // Size of the marker
        );
      } catch (e) {
        // Fallback to attractive taxi icon if car icon creation fails
        _carIcon = _blackCarIcon;
      }
    }
  }

  void _initControllers() {
    _statusController = DriverStatusManager().controller;
    _statusController.addListener(_onStatusChanged);

    // Configurar callback para erros de elegibilidade
    _statusController.onEligibilityError = _handleEligibilityError;

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _buttonScaleAnimation = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _initServices() {
    _locationService = LocationService(
      apiKey: AppConfig.googleMapsApiKey,
    );

    // Inicializar FCM Service para notificações push
    // FCMService().initialize().catchError((e) => {
    //   debugPrint('Erro ao inicializar FCMService: $e');
    // }); // Removido - usando OneSignal
  }

  @override
  void dispose() {
    _statusController.removeListener(_onStatusChanged);
    _buttonController.dispose();
    _positionSub?.cancel();
    _tripSub?.cancel();
    _approvalStatusTimer?.cancel();
    _bannerUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final current = await _locationService.getCurrentLocation();
      if (!mounted) return;
      
      if (current != null) {
        final controller = await _ensureController();
        final latLng = LatLng(
          (current['lat'] as num).toDouble(),
          (current['lng'] as num).toDouble(),
        );
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: latLng, zoom: 15),
          ),
        );
        _restartPositionStream();
      } else {
        // Fallback para São Paulo se não conseguir obter localização
        print('🗺️ [DRIVER_HOME] Usando localização padrão (São Paulo)');
        final controller = await _ensureController();
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(_initialPos),
        );
      }
    } catch (e) {
      print('⚠️ [DRIVER_HOME] Erro ao inicializar localização: $e');
      // Garantir que o mapa seja exibido mesmo com erro de localização
      if (mounted) {
        try {
          final controller = await _ensureController();
          await controller.animateCamera(
            CameraUpdate.newCameraPosition(_initialPos),
          );
        } catch (e2) {
          print('⚠️ [DRIVER_HOME] Erro ao aplicar posição inicial: $e2');
        }
      }
    }
  }

  Future<void> _initActiveTrips() async {
    try {
      final user = await UserService.getCurrentUser();
      if (!mounted || user == null) return;
      final driverId = await WalletService().getDriverIdForUser(user.id);
      if (!mounted || driverId == null) return;

      _driverId = driverId;

      _tripSub?.cancel();
      _tripSub = DriverService(Supabase.instance.client)
          .streamDriverActiveTrips(driverId)
          .listen((trips) async {
        if (!mounted) return;
        if (trips.isEmpty) {
          _currentTripId = null;
          _clearRoute();
          if (mounted) {
            setState(() {
              _markers.removeWhere(
                (m) =>
                    m.markerId.value == 'origin' ||
                    m.markerId.value == 'destination',
              );
            });
          }
          _restartPositionStream();
          return;
        }
        trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final trip = trips.first;
        if (_currentTripId == trip.id) return;
        _currentTripId = trip.id;
        await _buildTripRoute(trip);
        _restartPositionStream();
      });
    } on Exception {
      // Handle initialization errors silently
    }
  }

  Future<GoogleMapController> _ensureController() async {
    if (_mapController != null) {
      print('🗺️ [DRIVER_HOME] Usando controller existente');
      return _mapController!;
    }
    
    print('🗺️ [DRIVER_HOME] Aguardando controller do mapa...');
    try {
      final controller = await _mapControllerCompleter.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout aguardando controller do mapa');
        },
      );
      print('🗺️ [DRIVER_HOME] Controller do mapa obtido com sucesso');
      return controller;
    } catch (e) {
      print('⚠️ [DRIVER_HOME] Erro ao obter controller do mapa: $e');
      rethrow;
    }
  }

  void _restartPositionStream() {
    _positionSub?.cancel();
    _startPositionStream();
  }

  void _startPositionStream() {
    _positionSub?.cancel();
    final isOnline = _statusController.isOnline;

    int distanceFilter;
    int intervalSeconds;
    bool enableWakeLock;

    if (isOnline && _currentTripId != null) {
      distanceFilter = 5;
      intervalSeconds = 5;
      enableWakeLock = true;
    } else if (isOnline) {
      distanceFilter = 20;
      intervalSeconds = 10;
      enableWakeLock = false;
    } else {
      distanceFilter = 25;
      intervalSeconds = 15;
      enableWakeLock = false;
    }

    _positionSub = _locationService
        .positionStream(
      background: isOnline,
      distanceFilter: distanceFilter,
      intervalSeconds: intervalSeconds,
      enableWakeLock: enableWakeLock,
    )
        .listen((pos) async {
      final controller = await _ensureController();
      final here = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;

      if (mounted) {
        setState(() {
          _markers.removeWhere((m) => m.markerId.value == 'driver_location');
          _markers.add(
            Marker(
              markerId: const MarkerId('driver_location'),
              position: here,
              icon: _carIcon ?? _blackCarIcon ?? BitmapDescriptor.defaultMarker,
              infoWindow: const InfoWindow(title: 'Sua localização'),
            ),
          );
        });
      }

      if (_statusController.isOnline) {
        controller.animateCamera(CameraUpdate.newLatLng(here));
      }

      // Update location in Supabase when online
      if (_statusController.isOnline && _driverId != null) {
        final now = DateTime.now();
        final lastAt = _lastLocationSentAt;
        final lastPoint = _lastSentLatLng;

        var shouldSend = false;
        if (lastAt == null ||
            now.difference(lastAt) >= const Duration(seconds: 5)) {
          shouldSend = true;
        } else if (lastPoint != null) {
          final meters = Geolocator.distanceBetween(
            lastPoint.latitude,
            lastPoint.longitude,
            here.latitude,
            here.longitude,
          );
          if (meters >= 50) shouldSend = true;
        }

        if (shouldSend) {
          try {
            await DriverService(Supabase.instance.client)
                .updateLocation(_driverId!, pos.latitude, pos.longitude);
            _lastLocationSentAt = now;
            _lastSentLatLng = here;
          } catch (_) {
            // Silently ignore; will retry on next update
          }
        }
      }
    });
  }

  Future<void> _ensureDriverId() async {
    if (_driverId != null) return;
    final user = await UserService.getCurrentUser();
    if (user != null) {
      _driverId = await WalletService().getDriverIdForUser(user.id);
    }
  }

  Future<void> _onStatusChanged() async {
    if (!mounted || _isProcessingStatusChange) return;

    _isProcessingStatusChange = true;

    try {
      // Use post frame callback to avoid setState during build
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        await _ensureDriverId();

        if (_statusController.isOnline) {
          final ok = await _locationService.ensureLocationPermissions(
              background: true);
          if (!ok) {
            if (!_revertingOnlineDueToPermission) {
              _revertingOnlineDueToPermission = true;
              if (mounted) {
                await _showLocationPermissionDialog();
              }
              if (mounted) {
                _statusController.toggleOnlineStatus();
              }
              await Future.delayed(const Duration(milliseconds: 200));
              _revertingOnlineDueToPermission = false;
            }
            return;
          }

          // Mostrar notificação de sucesso apenas quando realmente online
          if (mounted) {
            _showSuccessOnlineNotification();
          }
        } else {
          // Pulse animation removed
        }

        if (_driverId != null && mounted) {
          try {
            await DriverService(Supabase.instance.client)
                .updateAvailability(_driverId!, _statusController.isOnline);
          } catch (_) {}
        }

        if (mounted) {
          _restartPositionStream();
        }
      });
    } finally {
      _isProcessingStatusChange = false;
    }
  }

  Future<void> _showLocationPermissionDialog() async {
    final perm = await Geolocator.checkPermission();
    final isForever = perm == LocationPermission.deniedForever;

    return showDialog<void>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          icon: Icon(
            Icons.location_off,
            size: 48,
            color: cs.error,
          ),
          title: const Text('Permissão de localização necessária'),
          content: Text(
            isForever
                ? 'Para ficar online e receber corridas, permita a localização em segundo plano nas configurações do app.'
                : 'Permissão de localização em segundo plano é necessária para ficar online.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            if (isForever) ...[
              TextButton(
                onPressed: () {
                  Geolocator.openLocationSettings();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Ajustes de localização'),
              ),
              FilledButton(
                onPressed: () {
                  ph.openAppSettings();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Ajustes do app'),
              ),
            ],
          ],
        );
      },
    );
  }

  void _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    if (!_mapControllerCompleter.isCompleted) {
      _mapControllerCompleter.complete(controller);
    }
    
    try {
      // Aplicar estilo do mapa
      if (mounted) {
        await MapStyleService.applyForContext(controller, context);
      }
      
      // Garantir que o mapa seja inicializado com a localização atual
      await _initLocation();
    } catch (e) {
      print('⚠️ [DRIVER_HOME] Erro ao configurar mapa: $e');
    }
  }

  Future<void> _buildTripRoute(Trip trip) async {
    final oLat = trip.originLatitude;
    final oLng = trip.originLongitude;
    final dLat = trip.destinationLatitude;
    final dLng = trip.destinationLongitude;

    if (oLat == 0.0 && oLng == 0.0) return;
    if (dLat == 0.0 && dLng == 0.0) return;

    _setMarker('origin', oLat, oLng, 0, title: 'Origem');
    _setMarker('destination', dLat, dLng, 0, title: 'Destino');

    _clearRoute();

    final route = await _locationService.getDrivingRoute(
      originLat: oLat,
      originLng: oLng,
      destLat: dLat,
      destLng: dLng,
    );
    if (!mounted || route == null) return;

    final colorScheme = Theme.of(context).colorScheme;

    if (mounted) {
      setState(() {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route_base'),
            points: route.points,
            color: colorScheme.primary,
            width: 6,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        );
      });
    }

    await _fitRouteBounds(route.points);
  }

  void _setMarker(
    String id,
    double lat,
    double lng,
    double hue, {
    String? title,
  }) {
    final pos = LatLng(lat, lng);
    if (mounted) {
      setState(() {
        _markers.removeWhere((m) => m.markerId.value == id);
        _markers.add(
          Marker(
            markerId: MarkerId(id),
            position: pos,
            icon: _carIcon ?? _blackCarIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow:
                title != null ? InfoWindow(title: title) : InfoWindow.noText,
          ),
        );
      });
    }
  }

  Future<void> _fitRouteBounds(List<LatLng> points) async {
    if (points.isEmpty) return;
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    final controller = await _ensureController();
    controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, AppSpacing.headerHeight));
  }

  void _clearRoute() {
    if (mounted) {
      setState(() {
        _polylines.removeWhere((p) => p.polylineId.value.startsWith('route'));
      });
    }
  }

  Future<void> _onGoButtonPressed() async {
    print('🔵 [DRIVER_HOME] _onGoButtonPressed iniciado');
    HapticFeedback.mediumImpact();

    _buttonController.forward().then((_) {
      _buttonController.reverse();
    });

    final status = _statusController.status;
    print(
        '🔵 [DRIVER_HOME] Status atual: ${status.status}, isOnline: ${status.isOnline}, isTransitioning: ${status.isTransitioning}');

    // Se está online, vai offline diretamente
    if (status.isOnline) {
      print(
          '🔵 [DRIVER_HOME] Motorista está online, chamando toggleOnlineStatus para ficar offline');
      await _statusController.toggleOnlineStatus();
      if (mounted) {
        print('🔵 [DRIVER_HOME] Exibindo notificação de offline');
        _showOfflineNotification();
      }
      print('🔵 [DRIVER_HOME] _onGoButtonPressed concluído (ficou offline)');
      return;
    }

    // Se está offline, tenta ficar online diretamente
    print('🔵 [DRIVER_HOME] Motorista está offline, tentando ficar online');
    try {
      print('🔵 [DRIVER_HOME] Chamando toggleOnlineStatus...');
      await _statusController.toggleOnlineStatus();
      print('🔵 [DRIVER_HOME] toggleOnlineStatus concluído com sucesso');

      // REMOVIDO: Não mostrar sucesso aqui - o callback onEligibilityError pode ainda ser chamado
      // A mensagem de sucesso deve ser mostrada apenas quando realmente aprovado
      print(
          '🔵 [DRIVER_HOME] _onGoButtonPressed concluído (aguardando validação)');
    } on DocumentationRequiredException catch (e) {
      print('🔵 [DRIVER_HOME] Erro de documentação necessária: ${e.message}');
      // Mostrar dialog visual para documentos
      if (mounted) {
        await _showDocumentationRequiredDialog(e.message);
      }
    } on ValidationException catch (e) {
      print('🔵 [DRIVER_HOME] Erro de validação: ${e.message}');
      // Mostrar dialog visual para erros de validação
      if (mounted) {
        await _showValidationErrorDialog(e.message);
      }
    } catch (e, stackTrace) {
      print('🔵 [DRIVER_HOME] Erro genérico: $e');
      print('🔵 [DRIVER_HOME] Stack trace: $stackTrace');
      // Mostrar dialog visual para erro genérico
      if (mounted) {
        await _showGenericErrorDialog(
            'Erro ao tentar ficar online. Verifique sua conexão e tente novamente.');
      }
    }
  }

  /// Verifica status dos documentos do motorista
  Future<void> _checkDocumentsStatus() async {
    try {
      print('🚀 [DRIVER_HOME] === INICIANDO VERIFICAÇÃO DE DOCUMENTOS ===');
      
      // Obter driver ID
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('❌ [DRIVER_HOME] Usuário não autenticado');
        return;
      }
      print('👤 [DRIVER_HOME] Usuário autenticado: ${user.id}');

      final driverId = await WalletService().getDriverIdForUser(user.id);
      if (driverId == null) {
        print('❌ [DRIVER_HOME] Driver ID não encontrado para usuário ${user.id}');
        return;
      }
      print('🚗 [DRIVER_HOME] Driver ID encontrado: $driverId');

      _driverId = driverId;

      // PRIMEIRO: Verificar se o motorista já está aprovado na tabela drivers
      print('🔍 [DRIVER_HOME] Verificando status geral do motorista...');
      await _checkGeneralDriverApproval(driverId);

      // Se já foi detectado como aprovado, não precisamos verificar documentos
      if (!_hasDocumentsPending) {
        print('✅ [DRIVER_HOME] Motorista já aprovado - pulando verificação de documentos');
        return;
      }

      // SEGUNDO: Verificar status individual dos documentos
      print('📋 [DRIVER_HOME] Verificando status individual dos documentos...');
      final documentsStatus =
          await DriverDocumentService.getDocumentationStatus(driverId);

      final isComplete = documentsStatus['isComplete'] as bool;
      final missingDocs = documentsStatus['missingDocuments'] as List;
      final pendingDocs = documentsStatus['pendingDocuments'] as List;
      final rejectedDocs = documentsStatus['rejectedDocuments'] as List;
      final approvedDocs = documentsStatus['approvedDocuments'] as List;

      final totalPending = missingDocs.length + pendingDocs.length + rejectedDocs.length;

      print('📊 [DRIVER_HOME] RESULTADO DA VERIFICAÇÃO:');
      print('   - isComplete: $isComplete');
      print('   - totalPending: $totalPending');
      print('   - missingDocs: $missingDocs');
      print('   - pendingDocs: $pendingDocs');
      print('   - rejectedDocs: $rejectedDocs');
      print('   - approvedDocs: $approvedDocs');

      if (mounted) {
        final wasDocumentsPending = _hasDocumentsPending;
        
        setState(() {
          _hasDocumentsPending = !isComplete;
          _pendingDocsCount = totalPending;
        });
        
        print('🔄 [DRIVER_HOME] Estado atualizado:');
        print('   - _hasDocumentsPending: $_hasDocumentsPending');
        print('   - _pendingDocsCount: $_pendingDocsCount');
        
        // Gerenciar estado do banner
        if (!_hasDocumentsPending && wasDocumentsPending) {
          // Banner foi removido - parar timer automático
          print('✅ [DRIVER_HOME] Banner removido - parando timer automático');
          _stopBannerUpdateTimer();
          _stopApprovalStatusTimer();
        }
      }
      
      print('🏁 [DRIVER_HOME] === VERIFICAÇÃO DE DOCUMENTOS CONCLUÍDA ===');
    } catch (e) {
      print('⚠️ [DRIVER_HOME] Erro ao verificar documentos: $e');
    }
  }

  /// Verifica o status geral do motorista na tabela drivers
  Future<void> _checkGeneralDriverApproval(String driverId) async {
    try {
      print('🔍 [DRIVER_HOME] Consultando tabela drivers...');
      
      // Consultar dados completos do motorista
      final response = await Supabase.instance.client
          .from('drivers')
          .select('id, approval_status, approved_by, approved_at')
          .eq('id', driverId)
          .single();

      print('📋 [DRIVER_HOME] Dados do motorista:');
      print('   - id: ${response['id']}');
      print('   - approval_status: ${response['approval_status']}');
      print('   - approved_by: ${response['approved_by']}');
      print('   - approved_at: ${response['approved_at']}');

      final approvalStatus = response['approval_status'] as String?;
      final approvedBy = response['approved_by'];
      final approvedAt = response['approved_at'];

      // Verificar múltiplas condições de aprovação
      bool isGenerallyApproved = false;
      String approvalReason = '';

      if (approvalStatus == 'approved') {
        isGenerallyApproved = true;
        approvalReason = 'approval_status = approved';
      } else if (approvedBy != null && approvedAt != null) {
        isGenerallyApproved = true;
        approvalReason = 'tem approved_by e approved_at preenchidos';
      }

      if (isGenerallyApproved) {
        print('✅ [DRIVER_HOME] MOTORISTA APROVADO GERALMENTE!');
        print('   - Razão: $approvalReason');
        
        if (mounted) {
          setState(() {
            _hasDocumentsPending = false;
            _pendingDocsCount = 0;
          });
          _stopApprovalStatusTimer();
          _stopBannerUpdateTimer(); // Parar timer automático também
          
          // Mostrar notificação de aprovação
          _showDriverApprovedNotification();
        }
      } else {
        print('⏳ [DRIVER_HOME] Motorista ainda não aprovado geralmente');
        print('   - approval_status: $approvalStatus');
        print('   - approved_by: $approvedBy');
        print('   - approved_at: $approvedAt');
      }
    } catch (e) {
      print('⚠️ [DRIVER_HOME] Erro ao verificar aprovação geral: $e');
      // Continuar com verificação de documentos
    }
  }

  /// Inicia o timer para atualização automática do banner a cada 5 segundos
  void _startBannerUpdateTimer() {
    _stopBannerUpdateTimer(); // Cancela timer anterior se existir
    
    print('🔄 [DRIVER_HOME] Iniciando timer automático de atualização do banner (5s)');
    _bannerUpdateTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) async {
        if (mounted) {
          print('⏰ [DRIVER_HOME] Timer automático - verificando status...');
          await _checkDocumentsStatus();
        }
      },
    );
  }

  /// Para o timer de atualização automática do banner
  void _stopBannerUpdateTimer() {
    if (_bannerUpdateTimer?.isActive == true) {
      print('⏹️ [DRIVER_HOME] Parando timer automático de atualização');
      _bannerUpdateTimer?.cancel();
      _bannerUpdateTimer = null;
    }
  }


  /// Para o timer de verificação de status
  void _stopApprovalStatusTimer() {
    if (_approvalStatusTimer?.isActive == true) {
      print('⏹️ [DRIVER_HOME] Parando timer de verificação de aprovação');
      _approvalStatusTimer?.cancel();
      _approvalStatusTimer = null;
    }
  }

  /// Verifica o status de aprovação do motorista no banco de dados
  Future<void> _checkDriverApprovalStatus() async {
    if (_driverId == null) return;
    
    try {
      print('🔍 [DRIVER_HOME] Verificando status de aprovação do motorista $_driverId');
      
      // Consultar todas as colunas relevantes da tabela drivers
      final response = await Supabase.instance.client
          .from('drivers')
          .select('id, approval_status, approved_by, approved_at')
          .eq('id', _driverId!)
          .single();

      print('📋 [DRIVER_HOME] Dados completos do driver: $response');
      
      final approvalStatus = response['approval_status'] as String?;
      final approvedBy = response['approved_by'];
      final approvedAt = response['approved_at'];
      
      print('📊 [DRIVER_HOME] Status detalhado:');
      print('   - approval_status: $approvalStatus');
      print('   - approved_by: $approvedBy');
      print('   - approved_at: $approvedAt');

      // Verificar se está aprovado (várias possibilidades)
      bool isApproved = false;
      
      if (approvalStatus == 'approved') {
        isApproved = true;
        print('✅ [DRIVER_HOME] Aprovado via approval_status');
      } else if (approvedBy != null) {
        isApproved = true;
        print('✅ [DRIVER_HOME] Aprovado via approved_by (não-nulo)');
      }

      if (isApproved) {
        print('🎉 [DRIVER_HOME] Motorista está aprovado! Ocultando banner');
        
        if (mounted) {
          setState(() {
            _hasDocumentsPending = false;
            _pendingDocsCount = 0;
          });
          _stopApprovalStatusTimer();
          _stopBannerUpdateTimer();
          
          // Mostrar uma notificação de sucesso
          _showDriverApprovedNotification();
        }
      } else {
        print('⏳ [DRIVER_HOME] Motorista ainda não aprovado - continuando verificação');
      }
    } catch (e) {
      print('⚠️ [DRIVER_HOME] Erro ao verificar status de aprovação: $e');
      print('🔧 [DRIVER_HOME] Tentativa alternativa...');
      
      // Tentativa alternativa: verificar se existe uma coluna 'status' simples
      try {
        final altResponse = await Supabase.instance.client
            .from('drivers')
            .select('id')
            .eq('id', _driverId!)
            .single();
        
        print('✅ [DRIVER_HOME] Driver existe no banco: ${altResponse['id']}');
        
        // Verificar documentos aprovados como alternativa
        await _checkDocumentationApprovalStatus();
        
      } catch (altError) {
        print('❌ [DRIVER_HOME] Erro na verificação alternativa: $altError');
      }
    }
  }

  /// Verifica se todos os documentos estão aprovados como alternativa
  Future<void> _checkDocumentationApprovalStatus() async {
    if (_driverId == null) return;
    
    try {
      print('📄 [DRIVER_HOME] Verificando status dos documentos como alternativa...');
      
      final docsResponse = await Supabase.instance.client
          .from('driver_documents')
          .select('document_type, status')
          .eq('driver_id', _driverId!)
          .eq('is_current', true);

      print('📑 [DRIVER_HOME] Documentos encontrados: $docsResponse');
      
      if (docsResponse.isEmpty) {
        print('📄 [DRIVER_HOME] Nenhum documento encontrado');
        return;
      }
      
      // Verificar se todos os documentos estão aprovados
      final allApproved = docsResponse.every((doc) => doc['status'] == 'approved');
      
      if (allApproved) {
        print('✅ [DRIVER_HOME] Todos os documentos estão aprovados!');
        
        if (mounted) {
          setState(() {
            _hasDocumentsPending = false;
            _pendingDocsCount = 0;
          });
          _stopApprovalStatusTimer();
          _stopBannerUpdateTimer();
          
          // Mostrar uma notificação de sucesso
          _showDriverApprovedNotification();
        }
      } else {
        print('⏳ [DRIVER_HOME] Nem todos os documentos estão aprovados ainda');
        for (final doc in docsResponse) {
          print('   - ${doc['document_type']}: ${doc['status']}');
        }
      }
      
    } catch (e) {
      print('⚠️ [DRIVER_HOME] Erro ao verificar documentos: $e');
    }
  }

  /// Mostra notificação visual quando o motorista é aprovado
  void _showDriverApprovedNotification() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aprovado!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Seus documentos foram aprovados!\nVocê já pode ficar online.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    // Auto close after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }

  /// Mostra notificação visual de sucesso ao ficar online
  void _showSuccessOnlineNotification() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Online!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Você está pronto para receber viagens!',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    // Auto close after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }

  /// Mostra notificação visual ao ficar offline
  void _showOfflineNotification() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.pause_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Offline',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Você não receberá novas viagens',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    // Auto close after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }

  /// Mostra dialog visual para documentos obrigatórios não aprovados
  Future<void> _showDocumentationRequiredDialog(String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            color: AppColors.lightSurface,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.upload_file_rounded,
                  size: AppSpacing.iconLg,
                  color: AppColors.warning,
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              Text(
                'Documentos Pendentes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightOnSurface,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.lightOnSurface,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        side: const BorderSide(color: AppColors.gray300),
                      ),
                      child: const Text('Entendi'),
                    ),
                  ),
                  
                  const SizedBox(width: AppSpacing.md),
                  
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushNamed(context, '/driver_documents');
                      },
                      icon: const Icon(Icons.upload_rounded, size: 18),
                      label: const Text('Enviar Documentos'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mostra dialog unificado para erros (substitui os métodos duplicados)
  Future<void> _showErrorDialog({
    required String message,
    String? title,
    IconData? icon,
    bool dismissible = true,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            color: AppColors.lightSurface,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon ?? Icons.warning_rounded,
                  size: AppSpacing.iconLg,
                  color: AppColors.error,
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              Text(
                title ?? 'Não é Possível Ficar Online',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightOnSurface,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.error,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.lightOnSurface,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                  child: const Text('Entendi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mostra dialog para erros de validação
  Future<void> _showValidationErrorDialog(String message) async {
    await _showErrorDialog(
      message: message,
      title: 'Erro de Validação',
      icon: Icons.error_outline,
    );
  }

  /// Mostra dialog para erros genéricos
  Future<void> _showGenericErrorDialog(String message) async {
    await _showErrorDialog(
      message: message,
      title: 'Erro',
      icon: Icons.error_outline_rounded,
    );
  }

  /// Handler para erros de elegibilidade reportados pelo DriverStatusController
  void _handleEligibilityError(Map<String, dynamic> eligibilityStatus) {
    print(
        '🚨 [DRIVER_HOME] Erro de elegibilidade recebido: $eligibilityStatus');

    if (!mounted) return;

    final reason =
        eligibilityStatus['reason'] as String? ?? 'Erro desconhecido';
    final message = eligibilityStatus['message'] as String? ??
        'Não foi possível ficar online';
    final actionRequired = eligibilityStatus['actionRequired'] as String?;

    switch (reason) {
      case 'Documentos não aprovados':
        _showDocumentationRequiredDialog(message);
        break;
      case 'Motorista não aprovado':
        _showErrorDialog(
          message: '$message\n\n${actionRequired ?? ''}',
          dismissible: false,
        );
        break;
      case 'Fora do horário de trabalho':
        _showErrorDialog(message: message);
        break;
      default:
        _showErrorDialog(
          message: message,
          title: 'Erro',
          icon: Icons.error_outline_rounded,
        );
        break;
    }
  }

  Widget _buildGoButton(DriverStatus status) {
    final colorScheme = Theme.of(context).colorScheme;

    Color buttonColor;
    Color textColor;
    String buttonText;
    IconData? icon;

    if (status.isTransitioning) {
      buttonColor = colorScheme.surfaceContainerHighest;
      textColor = colorScheme.onSurfaceVariant;
      buttonText = '';
      icon = null;
    } else if (status.isOnline) {
      buttonColor = colorScheme.error;
      textColor = colorScheme.onError;
      buttonText = 'PARAR';
      icon = Icons.stop;
    } else {
      buttonColor = colorScheme.primary;
      textColor = colorScheme.onPrimary;
      buttonText = 'IR';
      icon = Icons.play_arrow;
    }

    final Widget button = AnimatedBuilder(
      animation: _buttonScaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _buttonScaleAnimation.value,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: buttonColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: buttonColor.withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: 4,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: status.isTransitioning
              ? Center(
                  child: AppLoading(
                    type: AppLoadingType.circular,
                    size: AppLoadingSize.medium,
                    color: textColor,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        color: textColor,
                        size: AppSpacing.lg,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    Text(
                      buttonText,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: textColor,
                            fontWeight: AppTypography.bold,
                          ),
                    ),
                  ],
                ),
        ),
      ),
    );

    // Pulse animation removed as requested

    return GestureDetector(
      onTap: status.isTransitioning ? null : _onGoButtonPressed,
      child: button,
    );
  }

  void _navigateToDriverMenu() {
    Navigator.pushNamed(context, '/driver_menu');
  }

  void _navigateToWallet() {
    Navigator.pushNamed(context, '/wallet');
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ [DRIVER_HOME] BUILD CHAMADO:');
    print('   - _hasDocumentsPending: $_hasDocumentsPending');
    print('   - _pendingDocsCount: $_pendingDocsCount');
    print('   - Banner será exibido: $_hasDocumentsPending');
    
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Map
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: _initialPos,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              tiltGesturesEnabled: true,
              zoomGesturesEnabled: true,
              markers: _markers,
              polylines: _polylines,
              mapType: MapType.normal,
            ),
          ),

          // Top overlay with earnings
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.md,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Earnings widget
                ListenableBuilder(
                  listenable: _statusController,
                  builder: (context, _) => DriverEarningsWidget(
                    driverStatus: _statusController.status,
                    onTap: _navigateToWallet,
                  ),
                ),

                // Menu button (Emergência ocultado)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botão Emergência ocultado
                    // DecoratedBox(
                    //   decoration: BoxDecoration(
                    //     color: colorScheme.surface.withOpacity(0.95),
                    //     borderRadius: BorderRadius.circular(AppSpacing.lg + AppSpacing.xs),
                    //     boxShadow: [
                    //       BoxShadow(
                    //         color: AppColors.black.withOpacity(0.1),
                    //         blurRadius: AppSpacing.sm,
                    //         offset: const Offset(0, 2),
                    //       ),
                    //     ],
                    //   ),
                    //   child: const CompactEmergencyButton(),
                    // ),
                    // const SizedBox(width: AppSpacing.sm),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _navigateToDriverMenu,
                        icon: Icon(
                          Icons.menu,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Banner de documentos pendentes
          if (_hasDocumentsPending) ...[
            Builder(builder: (context) {
              print('🚨 [DRIVER_HOME] RENDERIZANDO BANNER!');
              print('   - _hasDocumentsPending: $_hasDocumentsPending');
              print('   - _pendingDocsCount: $_pendingDocsCount');
              print('   - _driverId: $_driverId');
              print('   - Timer ativo: ${_approvalStatusTimer?.isActive}');
              return Container(); // Widget vazio apenas para debug
            }),
            Positioned(
              bottom:
                  MediaQuery.of(context).padding.bottom + AppSpacing.xl + 140,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/driver_documents'),
                child: _buildDocumentsPendingBanner(),
              ),
            ),
          ],

          // Bottom "IR" button
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
            left: 0,
            right: 0,
            child: Center(
              child: ListenableBuilder(
                listenable: _statusController,
                builder: (context, _) =>
                    _buildGoButton(_statusController.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget do banner de documentos pendentes
  Widget _buildDocumentsPendingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade50,
            Colors.orange.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ação Necessária',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.orange.shade800,
                          ),
                    ),
                    Text(
                      'Você não pode ficar online ainda',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade700,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/driver_documents'),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(8),
                ),
                icon: const Icon(Icons.arrow_forward, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.upload_file,
                  color: Colors.orange.shade700,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$_pendingDocsCount documento(s) precisam ser enviados ou aprovados',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                Text(
                  'Enviar →',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
