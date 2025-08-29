import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/supabase/driver.dart';
import '../../models/supabase/trip.dart';
import '../../screens/chat/chat_screen.dart';
import '../../services/driver_service.dart';
import '../../services/phone_service.dart';
import '../../services/trip_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_card.dart';


class PassengerTripScreen extends StatefulWidget {
  
  const PassengerTripScreen({
    super.key,
    required this.tripId,
  });
  static const String routeName = '/passenger-trip';

  final String tripId;

  static PassengerTripScreen fromArgs(Map<String, dynamic>? args) {
    final tripId = args?['tripId'] as String? ?? '';
    return PassengerTripScreen(tripId: tripId);
  }

  @override
  State<PassengerTripScreen> createState() => _PassengerTripScreenState();
}

class _PassengerTripScreenState extends State<PassengerTripScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final DriverService _driverService = DriverService(Supabase.instance.client);
  final TripService _tripService = TripService(Supabase.instance.client);

  Trip? _currentTrip;
  Driver? _currentDriver;
  StreamSubscription<Trip?>? _tripSubscription;
  StreamSubscription<Driver>? _driverSubscription;
  String? _lastNotificationStatus;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  BitmapDescriptor? _driverMarkerIcon;
  BitmapDescriptor? _originMarkerIcon;
  BitmapDescriptor? _destinationMarkerIcon;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _createDriverMarkerIcon();
  }

  @override
  void dispose() {
    _tripSubscription?.cancel();
    _driverSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    try {
      await _loadCustomMarkers();
      await _subscribeToTrip();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar dados da viagem: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCustomMarkers() async {
    _driverMarkerIcon = await _createCustomMarker(
      'assets/icons/driver_marker.png',
      size: 120,
    );
    _originMarkerIcon = await _createCustomMarker(
      'assets/icons/origin_marker.png',
    );
    _destinationMarkerIcon = await _createCustomMarker(
      'assets/icons/destination_marker.png',
    );
  }

  Future<BitmapDescriptor> _createCustomMarker(
    String assetPath, {
    int size = 100,
  }) async {
    try {
      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: size,
        targetHeight: size,
      );
      final frameInfo = await codec.getNextFrame();
      final byteData = await frameInfo.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
    } catch (e) {
      // Fallback para marcador padrão se não conseguir carregar o ícone personalizado
      return BitmapDescriptor.defaultMarker;
    }
  }

  Future<void> _subscribeToTrip() async {
    _tripSubscription = _tripService.subscribeToTrip(widget.tripId).listen(
      (trip) {
        if (trip != null) {
          final previousStatus = _currentTrip?.status;
          setState(() {
            _currentTrip = trip;
            _isLoading = false;
          });
          _subscribeToDriver(trip.driverId);
          _updateTripMarkers();
          
          // Verificar mudanças de status para notificações
          if (previousStatus != null && previousStatus != trip.status) {
            _handleTripStatusChange(previousStatus, trip.status);
          }
        } else {
          setState(() {
            _errorMessage = 'Viagem não encontrada';
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        setState(() {
          _errorMessage = 'Erro ao monitorar viagem: $error';
          _isLoading = false;
        });
      },
    );
  }

  void _subscribeToDriver(String driverId) {
    _driverSubscription?.cancel();
    _driverSubscription = _driverService.streamDriver(driverId).listen(
      (driver) {
        setState(() {
          _currentDriver = driver;
        });
        _updateDriverMarker();
      },
      onError: (error) {
        debugPrint('Erro ao monitorar motorista: $error');
      },
    );
  }

  void _updateTripMarkers() {
    if (_currentTrip == null) return;

    final newMarkers = <Marker>{};

    // Marcador de origem
    newMarkers.add(
      Marker(
        markerId: const MarkerId('origin'),
        position: LatLng(
          _currentTrip!.originLatitude,
          _currentTrip!.originLongitude,
        ),
        icon: _originMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Origem',
          snippet: _currentTrip!.originAddress,
        ),
      ),
    );

    // Marcador de destino
    newMarkers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(
          _currentTrip!.destinationLatitude,
          _currentTrip!.destinationLongitude,
        ),
        icon: _destinationMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Destino',
          snippet: _currentTrip!.destinationAddress,
        ),
      ),
    );

    setState(() {
      _markers.removeWhere((marker) => 
        marker.markerId.value == 'origin' || 
        marker.markerId.value == 'destination'
      );
      _markers.addAll(newMarkers);
    });
  }

  Future<void> _createDriverMarkerIcon() async {
    final markerIcon = await _createCustomMarkerIcon();
    setState(() {
      _driverMarkerIcon = markerIcon;
    });
  }

  Future<BitmapDescriptor> _createCustomMarkerIcon() async {
    const size = 120.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Desenhar sombra
    final shadowPaint = Paint()
      ..color = AppColors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(
      const Offset(size / 2, size / 2 + 2),
      size / 2 - 8,
      shadowPaint,
    );
    
    // Desenhar círculo principal
    final circlePaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(size, size),
        [AppColors.lightPrimary, AppColors.lightPrimary.withOpacity(0.8)],
      );
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 8,
      circlePaint,
    );
    
    // Desenhar borda
    final borderPaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 8,
      borderPaint,
    );
    
    // Desenhar ícone do carro
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.directions_car.codePoint),
        style: TextStyle(
          fontSize: AppSpacing.xl,
          fontFamily: Icons.directions_car.fontFamily,
          color: AppColors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        (size - iconPainter.width) / 2,
        (size - iconPainter.height) / 2,
      ),
    );
    
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  void _updateDriverMarker() {
    if (_currentDriver?.currentLatitude == null || 
        _currentDriver?.currentLongitude == null) {
      return;
    }

    final driverMarker = Marker(
      markerId: const MarkerId('driver'),
      position: LatLng(
        _currentDriver!.currentLatitude!,
        _currentDriver!.currentLongitude!,
      ),
      icon: _driverMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(
        title: 'Seu motorista',
        snippet: '${_currentDriver!.brand} ${_currentDriver!.model} - ${_currentDriver!.plate}',
      ),
    );

    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == 'driver');
      _markers.add(driverMarker);
    });

    _animateCameraToDriver();
  }

  Future<void> _animateCameraToDriver() async {
    if (_currentDriver?.currentLatitude == null || 
        _currentDriver?.currentLongitude == null) {
      return;
    }

    final controller = await _mapController.future;
    await controller.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(
          _currentDriver!.currentLatitude!,
          _currentDriver!.currentLongitude!,
        ),
      ),
    );
  }

  Future<void> _callDriver() async {
    if (_currentDriver == null) {
      _showErrorSnackBar('Informações do motorista não disponíveis');
      return;
    }

    try {
      final phoneService = PhoneService();
      
      // Obter telefone do motorista através da tabela app_users
      final driverPhone = await phoneService.getUserPhone(_currentDriver!.userId);
      
      if (driverPhone == null) {
        _showErrorSnackBar('Telefone do motorista não disponível');
        return;
      }

      final success = await phoneService.makePhoneCall(driverPhone);
      
      if (!success) {
        _showErrorSnackBar('Não foi possível fazer a ligação');
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao tentar ligar: $e');
    }
  }

  Future<void> _chatWithDriver() async {
    if (_currentDriver == null) {
      _showErrorSnackBar('Informações do motorista não disponíveis');
      return;
    }

    try {
      // Obter o ID do usuário atual (passageiro)
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar('Usuário não autenticado');
        return;
      }

      // Navegar para a tela de chat
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            tripId: widget.tripId,
            currentUserId: currentUser.id,
            otherUserName: 'Motorista',
            isPassenger: true,
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Erro ao abrir chat: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleTripStatusChange(String previousStatus, String newStatus) {
    // Evitar notificações duplicadas
    if (_lastNotificationStatus == newStatus) return;
    
    _lastNotificationStatus = newStatus;
    
    String? notificationMessage;
    Color? backgroundColor;
    
    switch (newStatus.toLowerCase()) {
      case 'accepted':
        notificationMessage = '🚗 Motorista a caminho! Prepare-se para o embarque.';
        backgroundColor = Theme.of(context).colorScheme.primary;
        break;
      case 'driver_arrived':
        notificationMessage = '📍 Motorista chegou! Dirija-se ao local de embarque.';
        backgroundColor = AppColors.success;
        break;
      case 'in_progress':
      case 'ongoing':
        notificationMessage = '🛣️ Viagem iniciada! Tenha uma boa viagem.';
        backgroundColor = AppColors.blue;
        break;
      case 'completed':
        notificationMessage = '✅ Viagem concluída! Obrigado por usar nosso serviço.';
        backgroundColor = AppColors.success;
        break;
      case 'cancelled':
        notificationMessage = '❌ Viagem cancelada.';
        backgroundColor = Theme.of(context).colorScheme.error;
        break;
    }
    
    if (notificationMessage != null) {
      _showTripNotification(notificationMessage, backgroundColor);
    }
  }
  
  void _showTripNotification(String message, Color? backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.notifications,
              color: AppColors.white,
              size: AppSpacing.lg,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: AppTypography.medium,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        margin: AppSpacing.paddingMd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
      ),
    );
  }

  String _getTripStatusText() {
    if (_currentTrip == null) return 'Carregando...';
    
    switch (_currentTrip!.status.toLowerCase()) {
      case 'accepted':
        return 'Motorista a caminho';
      case 'in_progress':
        return 'Em viagem';
      case 'completed':
        return 'Viagem concluída';
      case 'cancelled':
        return 'Viagem cancelada';
      default:
        return 'Status: ${_currentTrip!.status}';
    }
  }

  Color _getTripStatusColor() {
    if (_currentTrip == null) return AppColors.gray500;
    
    switch (_currentTrip!.status.toLowerCase()) {
      case 'accepted':
        return AppColors.warning;
      case 'in_progress':
        return AppColors.success;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.gray500;
    }
  }

  Widget _buildRouteInfo({
    required IconData icon,
    required String label,
    required String address,
    required Color color,
  }) => Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.xs * 3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: AppTypography.medium,
                ),
              ),
              Text(
                address,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: AppTypography.medium,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sua Viagem'),
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.lightOnPrimary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sua Viagem'),
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.lightOnPrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: AppSpacing.avatarXl,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _errorMessage!,
                style: AppTypography.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initializeScreen();
                },
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sua Viagem'),
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: AppColors.lightOnPrimary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Mapa
          GoogleMap(
            onMapCreated: _mapController.complete,
            initialCameraPosition: CameraPosition(
              target: _currentTrip != null
                  ? LatLng(
                      _currentTrip!.originLatitude,
                      _currentTrip!.originLongitude,
                    )
                  : const LatLng(-23.5505, -46.6333),
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          
          // Card de informações da viagem
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: _buildTripInfoCard(),
          ),
        ],
      ),
    );
  }

  String _getEstimatedArrival() {
    if (_currentDriver?.currentLatitude == null || 
        _currentDriver?.currentLongitude == null || 
        _currentTrip == null) {
      return '5-8 min'; // Estimativa padrão quando não há dados
    }

    // Determinar destino baseado no status da viagem
    double targetLat, targetLng;
    if (_currentTrip!.status.toLowerCase() == 'accepted') {
      // Motorista indo para origem (pickup)
      targetLat = _currentTrip!.originLatitude;
      targetLng = _currentTrip!.originLongitude;
    } else {
      // Motorista em viagem para destino
      targetLat = _currentTrip!.destinationLatitude;
      targetLng = _currentTrip!.destinationLongitude;
    }

    // Calcular distância
    final distanceKm = _calculateDistanceInKm(
      _currentDriver!.currentLatitude!,
      _currentDriver!.currentLongitude!,
      targetLat,
      targetLng,
    );

    // Estimar tempo (velocidade média urbana: 25 km/h)
    final estimatedHours = distanceKm / 25.0;
    var estimatedMinutes = (estimatedHours * 60).round();

    // Adicionar buffer mínimo de 2 minutos para semáforos/trânsito
    estimatedMinutes = max(2, estimatedMinutes);

    if (estimatedMinutes <= 1) {
      return 'Chegando agora';
    } else if (estimatedMinutes <= 60) {
      return '$estimatedMinutes min';
    } else {
      final hours = estimatedMinutes ~/ 60;
      final minutes = estimatedMinutes % 60;
      return '${hours}h ${minutes}min';
    }
  }

  double _calculateDistanceInKm(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Raio da Terra em km
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * pi / 180;

  Widget _buildTripInfoCard() => AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status da viagem
            Row(
              children: [
                Container(
                  width: AppSpacing.xs * 3,
                  height: AppSpacing.xs * 3,
                  decoration: BoxDecoration(
                    color: _getTripStatusColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _getTripStatusText(),
                    style: AppTypography.titleMedium.copyWith(
                      color: _getTripStatusColor(),
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                ),
                if (_currentTrip != null)
                  Text(
                    'R\$ ${_currentTrip!.finalFare.toStringAsFixed(2)}',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                  ),
              ],
            ),
            
            if (_currentTrip != null) ...[
              const SizedBox(height: AppSpacing.md),
              
              // Informações da rota
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: AppSpacing.sm,
                          height: AppSpacing.sm,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _currentTrip!.originAddress,
                            style: AppTypography.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          Container(
                          width: 2,
                          height: AppSpacing.lg,
                            color: AppColors.gray300,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Container(
                          width: AppSpacing.sm,
                          height: AppSpacing.sm,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _currentTrip!.destinationAddress,
                            style: AppTypography.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            
            if (_currentDriver != null) ...[
              const SizedBox(height: AppSpacing.lg),
              
              // Informações do motorista
              Row(
                children: [
                  const CircleAvatar(
                    radius: AppSpacing.lg,
                    backgroundColor: AppColors.lightPrimary,
                    child: Icon(
                      Icons.person,
                      color: AppColors.lightOnPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Motorista',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.gray500,
                          ),
                        ),
                        Text(
                          'Motorista ${_currentDriver!.id.substring(0, 8)}',
                          style: AppTypography.titleSmall,
                        ),
                      ],
                    ),
                  ),
                  // Avaliação do motorista
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: AppSpacing.md,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _currentDriver!.ratings.toStringAsFixed(1),
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Informações do veículo
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.directions_car,
                      color: AppColors.lightPrimary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${_currentDriver!.brand} ${_currentDriver!.model} ${_currentDriver!.color}',
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                    Text(
                      _currentDriver!.plate,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Tempo estimado de chegada
              if (_currentTrip!.status.toLowerCase() == 'accepted')
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: AppSpacing.md,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Chegada estimada: ${_getEstimatedArrival()}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.warning,
                          fontWeight: AppTypography.medium,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Botões de ação (Chat e Ligar) - apenas quando motorista está a caminho ou em viagem
              if (_currentTrip != null && 
                  (_currentTrip!.status.toLowerCase() == 'accepted' || 
                   _currentTrip!.status.toLowerCase() == 'in_progress')) ...[
                const SizedBox(height: AppSpacing.lg),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _callDriver,
                        icon: const Icon(Icons.phone),
                        label: const Text('Ligar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.lightPrimary,
                          side: const BorderSide(),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _chatWithDriver,
                        icon: const Icon(Icons.chat),
                        label: const Text('Chat'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.lightPrimary,
                          side: const BorderSide(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
}