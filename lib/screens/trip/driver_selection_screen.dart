import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../models/supabase/driver.dart';
import '../../models/trip_request_data.dart';
import '../../models/trip_preferences.dart';
import '../../models/vehicle_category.dart';
import '../../services/driver_service.dart';
import '../../services/driver_matching_service.dart';
import '../../services/individual_pricing_service.dart';
import '../../services/trip_request_manager.dart';
import '../../services/driver_availability_service.dart';
import '../../widgets/app_card.dart';
import 'waiting_driver_screen.dart';

class DriverWithUserData {

  DriverWithUserData({
    required this.driver,
    required this.driverName,
    this.driverPhotoUrl,
    required this.distanceKm,
    required this.etaMinutes,
    this.estimatedFare,
  });
  final Driver driver;
  final String driverName;
  final String? driverPhotoUrl;
  final double distanceKm;
  final int etaMinutes;
  final double? estimatedFare;
}

class DriverSelectionScreen extends StatefulWidget {

  const DriverSelectionScreen({
    super.key,
    required this.tripRequestData,
    required this.userPosition,
  });
  static const String routeName = '/driver_selection';
  
  final TripRequestData tripRequestData;
  final Position userPosition;
  
  static DriverSelectionScreen fromArgs(Map<String, dynamic> args) {
    print('🎯 DriverSelectionScreen.fromArgs chamado');
    print('🎯 Args: $args');
    
    try {
      // Se os argumentos já contêm os objetos esperados (caso antigo)
      if (args.containsKey('tripRequestData') && args.containsKey('userPosition')) {
        return DriverSelectionScreen(
          tripRequestData: args['tripRequestData'] as TripRequestData,
          userPosition: args['userPosition'] as Position,
        );
      }
      
      // Caso novo: construir objetos a partir dos argumentos individuais
      final origin = args['origin'] as Map<String, dynamic>;
      final destination = args['destination'] as Map<String, dynamic>;
      
      // Criar TripRequestData a partir dos argumentos com conversão segura
      final tripRequestData = TripRequestData(
        originAddress: origin['address'] ?? 'Origem',
        originLatitude: _safeToDouble(origin['latitude']),
        originLongitude: _safeToDouble(origin['longitude']),
        destinationAddress: destination['address'] ?? 'Destino',
        destinationLatitude: _safeToDouble(destination['latitude']),
        destinationLongitude: _safeToDouble(destination['longitude']),
        vehicleCategory: args['vehicle_category'] ?? 'standard',
        needsPet: args['needsPet'] ?? false,
        needsGrocery: args['needsGrocery'] ?? false,
        needsCondo: args['needsCondo'] ?? false,
        needsAc: false,
        numberOfStops: 0,
        estimatedDistanceKm: 0.0, // Será calculado
        estimatedDurationMinutes: 0, // Será calculado
        estimatedFare: 0.0, // Será calculado
      );
      
      // Criar Position fictícia (será obtida em tempo real)
      final userPosition = Position(
        longitude: _safeToDouble(origin['longitude']),
        latitude: _safeToDouble(origin['latitude']),
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
      
      print('✅ Objetos criados com sucesso');
      
      return DriverSelectionScreen(
        tripRequestData: tripRequestData,
        userPosition: userPosition,
      );
      
    } catch (e) {
      print('❌ Erro ao criar DriverSelectionScreen: $e');
      rethrow;
    }
  }

  /// Converte qualquer tipo para double de forma segura
  static double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  @override
  State<DriverSelectionScreen> createState() => _DriverSelectionScreenState();
}

class _DriverSelectionScreenState extends State<DriverSelectionScreen> {
  final DriverService _driverService = DriverService(Supabase.instance.client);
  final DriverMatchingService _driverMatchingService = DriverMatchingService(Supabase.instance.client);
  final IndividualPricingService _individualPricingService = IndividualPricingService();
  final TripRequestManager _tripRequestManager = TripRequestManager(Supabase.instance.client);
  late final DriverAvailabilityService _availabilityService;

  List<DriverWithUserData> _driversWithUserData = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Listener em tempo real aprimorado
  StreamSubscription<Map<String, DriverAvailabilityStatus>>? _availabilitySubscription;
  Map<String, DriverAvailabilityStatus> _driverAvailability = {};

  @override
  void initState() {
    super.initState();
    _availabilityService = DriverAvailabilityService(Supabase.instance.client);
    _loadDriversWithUserData();
  }

  @override
  void dispose() {
    _availabilitySubscription?.cancel();
    _availabilityService.dispose();
    super.dispose();
  }

  /// Configura o listener em tempo real para monitorar disponibilidade dos motoristas
  /// Conforme especificação do negócio: "observa o status dos Condutores em tempo real"
  void _setupRealtimeListener(List<String> driverIds) {
    // Cancelar subscrição anterior
    _availabilitySubscription?.cancel();
    
    // Configurar novo listener usando o serviço dedicado
    _availabilitySubscription = _availabilityService.availabilityStream.listen(
      _handleAvailabilityUpdate,
    );
    
    // Iniciar monitoramento dos motoristas
    _availabilityService.startMonitoring(driverIds);
  }
  
  /// Processa atualizações de disponibilidade em tempo real
  void _handleAvailabilityUpdate(Map<String, DriverAvailabilityStatus> availability) {
    if (!mounted) return;
    
    setState(() {
      _driverAvailability = availability;
    });
  }

  Future<void> _loadDriversWithUserData() async {
    try {
      print('🔍 _loadDriversWithUserData iniciado');
      print('🔍 Position: ${widget.userPosition.latitude}, ${widget.userPosition.longitude}');
      print('🔍 TripData: ${widget.tripRequestData.vehicleCategory}');
      
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Buscar motoristas disponíveis próximos
      final criteria = MatchingCriteria(
          passengerLatitude: widget.userPosition.latitude,
          passengerLongitude: widget.userPosition.longitude,
          vehicleCategory: widget.tripRequestData.vehicleCategory,
          needsPet: widget.tripRequestData.needsPet,
          needsAC: widget.tripRequestData.needsAc,
          needsGrocery: widget.tripRequestData.needsGrocery,
          needsCondo: widget.tripRequestData.needsCondo,
        );
        
      print('🔍 Criteria criado: $criteria');
        
        final driversWithDistance = await _driverMatchingService.findBestDrivers(criteria);

      if (driversWithDistance.isEmpty) {
        setState(() {
          _driversWithUserData = [];
          _isLoading = false;
        });
        return;
      }

      // Buscar dados dos usuários dos motoristas
      final driversWithUserData = <DriverWithUserData>[];
      
      for (final driverWithDistance in driversWithDistance) {
        try {
          final driverWithUser = await _driverService.getDriverWithUserData(driverWithDistance.driver.id);
          
          if (driverWithUser != null) {
            // Calcular preço individual para este motorista
            final estimatedFare = IndividualPricingService.calculateDriverPrice(
              driver: driverWithDistance.driver,
              totalDistanceKm: driverWithDistance.distanceKm + widget.tripRequestData.estimatedDistanceKm,
              totalDurationMinutes: driverWithDistance.estimatedArrivalMinutes + widget.tripRequestData.estimatedDurationMinutes,
              categoryData: VehicleCategoryData.defaultForCategory(
                 VehicleCategory.fromId(widget.tripRequestData.vehicleCategory) ?? VehicleCategory.economico,
               ),
              preferences: TripPreferences(
                needsPet: widget.tripRequestData.needsPet,
                needsGrocery: widget.tripRequestData.needsGrocery,
                needsCondo: widget.tripRequestData.needsCondo,
              ),
              numberOfStops: widget.tripRequestData.numberOfStops,
            );

            driversWithUserData.add(DriverWithUserData(
              driver: driverWithDistance.driver,
              driverName: driverWithUser['user_name'] ?? 'Motorista',
              driverPhotoUrl: driverWithUser['user_photo_url'],
              distanceKm: driverWithDistance.distanceKm,
              etaMinutes: driverWithDistance.estimatedArrivalMinutes,
              estimatedFare: estimatedFare,
            ));
          }
        } catch (e) {
          print('Erro ao buscar dados do motorista ${driverWithDistance.driver.id}: $e');
          // Continuar com o próximo motorista em caso de erro
        }
      }

      setState(() {
        _driversWithUserData = driversWithUserData;
        _isLoading = false;
      });
      
      // Configurar listener em tempo real após carregar os motoristas
      final driverIds = driversWithUserData.map((d) => d.driver.id).toList();
      if (driverIds.isNotEmpty) {
        _setupRealtimeListener(driverIds);
      }
    } catch (e, stackTrace) {
      print('❌ ERRO EM _loadDriversWithUserData: $e');
      print('❌ StackTrace: $stackTrace');
      
      setState(() {
        _errorMessage = 'Erro ao carregar motoristas: $e';
        _isLoading = false;
      });
    }
  }

  void _showDriverSelectionConfirmation(BuildContext context, DriverWithUserData driverWithUserData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar seleção'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Motorista: ${driverWithUserData.driverName}'),
            Text('Veículo: ${driverWithUserData.driver.brand} ${driverWithUserData.driver.model}'),
            Text('Placa: ${driverWithUserData.driver.plate}'),
            Text('Distância: ${driverWithUserData.distanceKm.toStringAsFixed(1)} km'),
            Text('Tempo estimado: ~${driverWithUserData.etaMinutes} min'),
            Text('Preço: R\$ ${driverWithUserData.estimatedFare?.toStringAsFixed(2) ?? "0.00"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _onDriverSelected(driverWithUserData.driver, driverWithUserData.estimatedFare);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _onDriverSelected(Driver driver, double? estimatedFare) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final prioritizedDrivers = [driver] + _driversWithUserData
            .where((d) => d.driver.id != driver.id)
            .map((d) => d.driver)
            .take(5)
            .toList();
        
        final tripRequest = await _tripRequestManager.createDirectedTripRequest(
          passengerId: Supabase.instance.client.auth.currentUser!.id,
          prioritizedDrivers: prioritizedDrivers,
          tripData: widget.tripRequestData,
        );

      Navigator.of(context).pop();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => WaitingDriverScreen(
              tripRequestId: tripRequest,
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar solicitação: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        title: const Text('Selecionar Motorista'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Informações da viagem
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.my_location, color: colorScheme.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.tripRequestData.originAddress,
                        style: textTheme.bodyMedium?.copyWith(color: AppColors.black),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, color: colorScheme.secondary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.tripRequestData.destinationAddress,
                        style: textTheme.bodyMedium?.copyWith(color: AppColors.black),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (widget.tripRequestData.numberOfStops > 0) ...[
                  const SizedBox(height: 12),
                  const _AdditionalStopInfo(
                    stopLabel: 'Parada adicional',
                  ),
                ],
              ],
            ),
          ),
          // Lista de motoristas
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.black),
                  )
                : _errorMessage != null
                    ? _ErrorState(onRetry: _loadDriversWithUserData)
                    : _driversWithUserData.isEmpty
                        ? _EmptyState(onRetry: _loadDriversWithUserData)
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _driversWithUserData.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final driverWithUserData = _driversWithUserData[index];
                              final availabilityStatus = _driverAvailability[driverWithUserData.driver.id];
                              final isAvailable = availabilityStatus?.isAvailable ?? true;
                              
                              return _DriverCard(
                                driverWithUserData: driverWithUserData,
                                availabilityStatus: availabilityStatus,
                                onTap: isAvailable && !_isLoading ? () {
                                  _showDriverSelectionConfirmation(context, driverWithUserData);
                                } : null,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.driverWithUserData,
    required this.onTap,
    this.availabilityStatus,
  });

  final DriverWithUserData driverWithUserData;
  final VoidCallback? onTap;
  final DriverAvailabilityStatus? availabilityStatus;
  
  bool get isAvailable => availabilityStatus?.isAvailable ?? true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAvailable ? AppColors.white : AppColors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAvailable ? colorScheme.outlineVariant : colorScheme.error,
            width: isAvailable ? 1 : 2,
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isAvailable ? colorScheme.primaryContainer : colorScheme.primaryContainer.withOpacity(0.5),
                  backgroundImage: driverWithUserData.driverPhotoUrl != null 
                      ? NetworkImage(driverWithUserData.driverPhotoUrl!) 
                      : null,
                  child: driverWithUserData.driverPhotoUrl == null 
                      ? Text(
                          driverWithUserData.driverName.isNotEmpty 
                              ? driverWithUserData.driverName[0].toUpperCase() 
                              : 'M',
                          style: TextStyle(
                            color: isAvailable ? colorScheme.onPrimaryContainer : colorScheme.onPrimaryContainer.withOpacity(0.5),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverWithUserData.driverName,
                        style: textTheme.titleMedium?.copyWith(
                          color: isAvailable ? AppColors.black : AppColors.black.withOpacity(0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${driverWithUserData.driver.brand} ${driverWithUserData.driver.model} ${driverWithUserData.driver.year ?? ''} · ${driverWithUserData.driver.color}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: isAvailable ? AppColors.black.withOpacity(0.7) : AppColors.black.withOpacity(0.4),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Placa ${driverWithUserData.driver.plate} · ${driverWithUserData.driver.category.toUpperCase()}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: isAvailable ? AppColors.black.withOpacity(0.6) : AppColors.black.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star, 
                            color: isAvailable ? colorScheme.tertiary : colorScheme.tertiary.withOpacity(0.5), 
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            driverWithUserData.driver.ratings.toStringAsFixed(1), 
                            style: textTheme.bodyMedium?.copyWith(
                              color: isAvailable ? AppColors.black : AppColors.black.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.place, 
                            color: isAvailable ? colorScheme.secondary : colorScheme.secondary.withOpacity(0.5), 
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${driverWithUserData.distanceKm.toStringAsFixed(1)} km', 
                            style: textTheme.bodyMedium?.copyWith(
                              color: isAvailable ? AppColors.black : AppColors.black.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.timer, 
                            color: isAvailable ? colorScheme.primary : colorScheme.primary.withOpacity(0.5), 
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '~${driverWithUserData.etaMinutes} min', 
                            style: textTheme.bodyMedium?.copyWith(
                              color: isAvailable ? AppColors.black : AppColors.black.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      if (driverWithUserData.driver.acPolicy != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.ac_unit, 
                              color: isAvailable ? colorScheme.primary : colorScheme.primary.withOpacity(0.5), 
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              driverWithUserData.driver.acPolicy!, 
                              style: textTheme.bodyMedium?.copyWith(
                                color: isAvailable ? AppColors.black : AppColors.black.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (driverWithUserData.estimatedFare != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.attach_money, 
                              color: isAvailable ? colorScheme.primary : colorScheme.primary.withOpacity(0.5), 
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'R\$ ${driverWithUserData.estimatedFare!.toStringAsFixed(2)}', 
                              style: textTheme.bodyMedium?.copyWith(
                                color: isAvailable ? AppColors.black : AppColors.black.withOpacity(0.5),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            // Indicador de disponibilidade aprimorado
            if (!isAvailable && availabilityStatus != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(colorScheme, availabilityStatus),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        availabilityStatus!.statusIcon,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        availabilityStatus!.unavailabilityReason,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onError,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  /// Retorna a cor apropriada baseada no status de disponibilidade
  Color _getStatusColor(ColorScheme colorScheme, DriverAvailabilityStatus? status) {
    if (status == null) return colorScheme.error;
    
    if (!status.isOnline) return colorScheme.error;
    if (!status.isApproved) return colorScheme.tertiary;
    if (!status.hasCurrentLocation) return colorScheme.secondary;
    if (status.isInActiveTrip) return colorScheme.primary;
    if (status.hasPendingRequest) return colorScheme.outline;
    
    return colorScheme.error;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car_filled, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('Nenhum motorista disponível por perto', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Tente ajustar as preferências ou tentar novamente em instantes.', textAlign: TextAlign.center, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 12),
            Text('Ocorreu um erro ao carregar motoristas', style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text('Verifique sua conexão e tente novamente.', textAlign: TextAlign.center, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Recarregar')),
          ],
        ),
      ),
    );
  }
}

class _AdditionalStopInfo extends StatelessWidget {
  const _AdditionalStopInfo({required this.stopLabel});
  final String stopLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.add_road_outlined, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parada adicional',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stopLabel,
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSecondaryContainer),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}