import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/app_config.dart';
import '../../models/favorite_location.dart';
import '../../models/supabase/driver.dart';
import '../../services/driver_service.dart';
import '../../services/trip_service.dart';
import '../../services/user_service.dart';
import '../../services/location_service.dart';
import '../../widgets/logo_branding.dart';

class DriverSelectionScreen extends StatefulWidget {

  const DriverSelectionScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.category,
    required this.needsPet,
    required this.needsGrocery,
    required this.needsCondo,
    this.additionalStop,
    this.appliedPromoCode,
    this.promoDiscount,
  });

  factory DriverSelectionScreen.fromArgs(Map<String, dynamic>? args) {
    final originJson = (args?['origin'] as Map<String, dynamic>?) ?? {};
    final destinationJson = (args?['destination'] as Map<String, dynamic>?) ?? {};
    return DriverSelectionScreen(
      origin: FavoriteLocation.fromJson(originJson),
      destination: FavoriteLocation.fromJson(destinationJson),
      category: (args?['vehicle_category'] as String?) ?? 'standard',
      needsPet: (args?['needsPet'] as bool?) ?? false,
      needsGrocery: (args?['needsGrocery'] as bool?) ?? false,
      needsCondo: (args?['needsCondo'] as bool?) ?? false,
      additionalStop: args?['additionalStop'] as String?,
      appliedPromoCode: args?['appliedPromoCode'] as String?,
      promoDiscount: args?['promoDiscount'] as double?,
    );
  }
  static const String routeName = '/driver_selection';

  final FavoriteLocation origin;
  final FavoriteLocation destination;
  final String category;
  final bool needsPet;
  final bool needsGrocery;
  final bool needsCondo;
  final String? additionalStop;
  final String? appliedPromoCode;
  final double? promoDiscount;

  @override
  State<DriverSelectionScreen> createState() => _DriverSelectionScreenState();
}

class _DriverSelectionScreenState extends State<DriverSelectionScreen> {
  late final DriverService _driverService;
  late Future<List<Driver>> _futureDrivers;
  bool _isLoading = false;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _driverService = DriverService(Supabase.instance.client);
    _futureDrivers = _loadDrivers();
  }

  Future<List<Driver>> _loadDrivers() async {
    final lat = widget.origin.latitude;
    final lng = widget.origin.longitude;
    if (lat == null || lng == null) {
      return [];
    }
    
    // Extrair informações de localização do endereço de destino
    // Por enquanto, deixamos como null até implementarmos um parser de endereço
    // ou até que o modelo FavoriteLocation seja atualizado com esses campos
    String? destinationNeighborhood;
    String? destinationCity;
    String? destinationState;
    
    // TODO: Implementar parser de endereço ou atualizar modelo FavoriteLocation
    // para incluir campos neighborhood, city e state
    
    return _driverService.getAvailableDriversNearby(
      latitude: lat,
      longitude: lng,
      radiusKm: 8,
      category: widget.category,
      needsPet: widget.needsPet,
      needsGrocery: widget.needsGrocery,
      needsCondo: widget.needsCondo,
      destinationNeighborhood: destinationNeighborhood,
      destinationCity: destinationCity,
      destinationState: destinationState,
      limit: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const StandardAppBar(title: 'Selecionar motorista'),
      body: Stack(
        children: [
          Column(
            children: [
              if ((widget.additionalStop ?? '').trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _AdditionalStopInfo(stopLabel: widget.additionalStop!.trim()),
                ),
              Expanded(
                child: FutureBuilder<List<Driver>>(
                  future: _futureDrivers,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _ErrorState(onRetry: () => setState(() => _futureDrivers = _loadDrivers()));
                    }

                    final drivers = snapshot.data ?? [];
                    if (drivers.isEmpty) {
                      return _EmptyState(onRetry: () => setState(() => _futureDrivers = _loadDrivers()));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: drivers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final d = drivers[index];
                        final distanceKm = _distanceKm(
                          widget.origin.latitude ?? 0,
                          widget.origin.longitude ?? 0,
                          d.currentLatitude ?? 0,
                          d.currentLongitude ?? 0,
                        );
                        final etaMin = (distanceKm / 0.6).clamp(1, 120).round(); // ~36km/h
                        return _DriverCard(
                           driver: d,
                           distanceKm: distanceKm,
                           etaMinutes: etaMin,
                           onTap: () {
                             if (!_isLoading) {
                               _onSelect(d);
                             }
                           },
                         );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Criando solicitação...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
            math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) *
                math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (math.pi / 180.0);

  Future<void> _onSelect(Driver driver) async {
    setState(() => _isLoading = true);
    
    try {
      // Obter usuário atual
      final user = await UserService.getCurrentUser();
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Calcular rota e estimativa de preço
      final routeResult = await LocationService(apiKey: AppConfig.googleMapsApiKey).getDrivingRoute(
        originLat: widget.origin.latitude!,
        originLng: widget.origin.longitude!,
        destLat: widget.destination.latitude!,
        destLng: widget.destination.longitude!,
      );

      if (routeResult == null) {
        throw Exception('Não foi possível calcular a rota');
      }

      // Buscar categoria do veículo para cálculo de preço
      final categories = await DriverService(_supabase).getAvailableCategoriesInRegion(
        latitude: widget.origin.latitude!,
        longitude: widget.origin.longitude!,
        radiusKm: 10,
      );
      
      final selectedCategory = categories.firstWhere(
        (cat) => cat.category.id == widget.category,
        orElse: () => categories.first,
      );

      // Calcular preço estimado
      final baseFare = selectedCategory.calculateEstimatedPrice(
        routeResult.distanceMeters / 1000, // converter para km
        (routeResult.durationSeconds / 60).round(),   // converter para minutos
      );
      
      // Aplicar desconto promocional se disponível
      final estimatedFare = widget.promoDiscount != null 
          ? (baseFare - widget.promoDiscount!).clamp(0.0, baseFare)
          : baseFare;

      // Criar TripRequest
      final tripRequest = await TripService(_supabase).createTripRequest(
        passengerId: user.id,
        originAddress: widget.origin.address,
        originLatitude: widget.origin.latitude!,
        originLongitude: widget.origin.longitude!,
        originNeighborhood: widget.origin.type.name,
        destinationAddress: widget.destination.address,
        destinationLatitude: widget.destination.latitude!,
        destinationLongitude: widget.destination.longitude!,
        destinationNeighborhood: widget.destination.type.name,
        vehicleCategory: widget.category,
        needsPet: widget.needsPet,
        needsGrocerySpace: widget.needsGrocery,
        isCondoDestination: widget.needsCondo,
        isCondoOrigin: false,
        needsAc: false,
        numberOfStops: widget.additionalStop != null ? 1 : 0,
        estimatedDistanceKm: routeResult.distanceMeters / 1000,
        estimatedDurationMinutes: (routeResult.durationSeconds / 60).round(),
        estimatedFare: estimatedFare,
      );

      if (mounted) {
        // Navegar para tela de aguardando motorista
        Navigator.of(context).pushReplacementNamed(
          '/waiting-driver',
          arguments: {'tripRequestId': tripRequest.id},
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar solicitação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _DriverCard extends StatelessWidget {

  const _DriverCard({
    required this.driver,
    required this.distanceKm,
    required this.etaMinutes,
    required this.onTap,
  });
  final Driver driver;
  final double distanceKm;
  final int etaMinutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                (driver.brand.isNotEmpty ? driver.brand[0] : 'D').toUpperCase(),
                style: TextStyle(color: colorScheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${driver.brand} ${driver.model} · ${driver.color}',
                    style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Placa ${driver.plate} · ${driver.category.toUpperCase()}',
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: colorScheme.tertiary, size: 16),
                      const SizedBox(width: 4),
                      Text(driver.ratings.toStringAsFixed(1), style: textTheme.bodyMedium),
                      const SizedBox(width: 12),
                      Icon(Icons.place, color: colorScheme.secondary, size: 16),
                      const SizedBox(width: 4),
                      Text('${distanceKm.toStringAsFixed(1)} km', style: textTheme.bodyMedium),
                      const SizedBox(width: 12),
                      Icon(Icons.timer, color: colorScheme.primary, size: 16),
                      const SizedBox(width: 4),
                      Text('~$etaMinutes min', style: textTheme.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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