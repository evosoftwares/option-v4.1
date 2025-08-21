import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/favorite_location.dart';
import '../../models/supabase/driver.dart';
import '../../services/driver_service.dart';

class DriverSelectionScreen extends StatefulWidget {

  const DriverSelectionScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.category,
    required this.needsPet,
    required this.needsGrocery,
    required this.needsCondo,
  });

  factory DriverSelectionScreen.fromArgs(Map<String, dynamic>? args) {
    final originJson = (args?['origin'] as Map<String, dynamic>?) ?? {};
    final destinationJson = (args?['destination'] as Map<String, dynamic>?) ?? {};
    return DriverSelectionScreen(
      origin: FavoriteLocation.fromJson(originJson),
      destination: FavoriteLocation.fromJson(destinationJson),
      category: (args?['category'] as String?) ?? 'standard',
      needsPet: (args?['needsPet'] as bool?) ?? false,
      needsGrocery: (args?['needsGrocery'] as bool?) ?? false,
      needsCondo: (args?['needsCondo'] as bool?) ?? false,
    );
  }
  static const String routeName = '/driver_selection';

  final FavoriteLocation origin;
  final FavoriteLocation destination;
  final String category;
  final bool needsPet;
  final bool needsGrocery;
  final bool needsCondo;

  @override
  State<DriverSelectionScreen> createState() => _DriverSelectionScreenState();
}

class _DriverSelectionScreenState extends State<DriverSelectionScreen> {
  late final DriverService _driverService;
  late Future<List<Driver>> _futureDrivers;

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
    return _driverService.getAvailableDriversNearby(
      latitude: lat,
      longitude: lng,
      radiusKm: 8,
      category: widget.category,
      needsPet: widget.needsPet,
      needsGrocery: widget.needsGrocery,
      needsCondo: widget.needsCondo,
      limit: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Selecionar motorista'),
      ),
      body: FutureBuilder<List<Driver>>(
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
                onTap: () => _onSelect(d),
              );
            },
          );
        },
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

  void _onSelect(Driver d) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seleção de motorista em breve')),
    );
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