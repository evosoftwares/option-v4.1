import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/favorite_location.dart';
import '../../models/vehicle_category.dart';
import '../../services/driver_service.dart';
import '../../services/passenger_promo_service.dart';
import '../../services/promo_code_service.dart';
import '../../services/user_service.dart';
import '../../widgets/logo_branding.dart';
import 'driver_selection_screen.dart';
import 'additional_stop_screen.dart';
import '../../config/app_config.dart';
import '../../services/location_service.dart';

class TripOptionsScreen extends StatefulWidget {

  const TripOptionsScreen({
    super.key,
    required this.origin,
    required this.destination,
  });

  factory TripOptionsScreen.fromArgs(Map<String, dynamic>? args) {
    final originJson = (args?['origin'] as Map<String, dynamic>?) ?? {};
    final destinationJson = (args?['destination'] as Map<String, dynamic>?) ?? {};
    return TripOptionsScreen(
      origin: FavoriteLocation.fromJson(originJson),
      destination: FavoriteLocation.fromJson(destinationJson),
    );
  }
  static const String routeName = '/trip_options';

  final FavoriteLocation origin;
  final FavoriteLocation destination;

  @override
  State<TripOptionsScreen> createState() => _TripOptionsScreenState();
}

class _TripOptionsScreenState extends State<TripOptionsScreen> {
  VehicleCategory _selectedCategory = VehicleCategory.standard;
  bool _needsPet = false;
  bool _needsGrocery = false;
  bool _needsCondo = false;
  List<VehicleCategoryData> _categoryData = [];
  bool _isLoading = true;
  late final DriverService _driverService;
  late final LocationService _locationService;
  late final PassengerPromoService _passengerPromoService;
  late final PromoCodeService _promoCodeService;
  
  // Promo code state
  final TextEditingController _promoController = TextEditingController();
  String? _appliedPromoCode;
  double _promoDiscount = 0.0;
  bool _isValidatingPromo = false;

  @override
  void initState() {
    super.initState();
    _driverService = DriverService(Supabase.instance.client);
    _locationService = LocationService(apiKey: AppConfig.googleMapsApiKey);
    _passengerPromoService = PassengerPromoService();
    _promoCodeService = PromoCodeService();
    _loadCategoryData();
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoryData() async {
    try {
      setState(() => _isLoading = true);
      
      // Garante coordenadas válidas para a origem
      double? lat = widget.origin.latitude;
      double? lng = widget.origin.longitude;

      if ((lat == null || lng == null) && widget.origin.placeId != null) {
        final details = await _locationService.getPlaceDetails(widget.origin.placeId!);
        lat = (details?['lat'] as num?)?.toDouble();
        lng = (details?['lng'] as num?)?.toDouble();
      }

      if (lat == null || lng == null) {
        final current = await _locationService.getCurrentLocation();
        lat = (current?['lat'] as num?)?.toDouble();
        lng = (current?['lng'] as num?)?.toDouble();
      }

      if (lat == null || lng == null) {
        // Fallback para dados padrão se ainda não for possível obter coordenadas
        if (mounted) {
          setState(() {
            _categoryData = VehicleCategory.popularCategories
                .map((cat) => VehicleCategoryData.defaultForCategory(cat))
                .toList();
            _isLoading = false;
          });
        }
        return;
      }
      
      // Usa coordenadas do local de origem para buscar motoristas próximos
      final categories = await _driverService.getAvailableCategoriesInRegion(
        latitude: lat,
        longitude: lng,
        radiusKm: 15.0,
      );
      
      if (mounted) {
        setState(() {
          _categoryData = categories;
          _isLoading = false;
        });
      }
    } on Exception catch (e) {
      // Em caso de erro, usa dados padrão
      if (mounted) {
        setState(() {
          _categoryData = VehicleCategory.popularCategories
              .map((cat) => VehicleCategoryData.defaultForCategory(cat))
              .toList();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const StandardAppBar(title: 'Opções da viagem'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LocationsSummary(origin: widget.origin, destination: widget.destination),
              const SizedBox(height: 16),
              const _SectionTitle(title: 'Categoria do veículo'),
              const SizedBox(height: 8),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categoryData
                      .map((data) => _categoryChip(data.category, data))
                      .toList(),
                ),
              const SizedBox(height: 16),
              const _SectionTitle(title: 'Preferências'),
              const SizedBox(height: 8),
              _prefTile(
                title: 'Levo pet',
                value: _needsPet,
                onChanged: (v) => setState(() => _needsPet = v),
              ),
              _prefTile(
                title: 'Espaço para compras',
                value: _needsGrocery,
                onChanged: (v) => setState(() => _needsGrocery = v),
              ),
              _prefTile(
                title: 'Condomínio (acesso facilitado)',
                value: _needsCondo,
                onChanged: (v) => setState(() => _needsCondo = v),
              ),
              const SizedBox(height: 16),
              const _SectionTitle(title: 'Código promocional'),
              const SizedBox(height: 8),
              _promoCodeSection(),
              const Spacer(),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _continue,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar motoristas'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(VehicleCategory category, VehicleCategoryData data) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = _selectedCategory == category;
    return ChoiceChip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category.displayName),
          if (data.availableDrivers > 0)
            Text(
              '${data.availableDrivers} motoristas',
              style: TextStyle(
                fontSize: 10,
                color: selected ? colorScheme.onPrimaryContainer.withOpacity(0.7) : colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          if (data.estimatedArrival != null)
            Text(
              data.estimatedArrival!,
              style: TextStyle(
                fontSize: 10,
                color: selected ? colorScheme.onPrimaryContainer.withOpacity(0.7) : colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      selected: selected,
      onSelected: (_) => setState(() => _selectedCategory = category),
    );
  }

  Widget _prefTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: colorScheme.primary,
    );
  }

  Future<void> _validatePromoCode() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isValidatingPromo = true);

    try {
      final user = await UserService.getCurrentUser();
      if (user == null) {
        throw Exception('Usuário não encontrado');
      }

      // Tenta validar como código de passageiro primeiro
      final passengerPromo = await _passengerPromoService.validatePromoCode(
        code,
        user.id,
        tripAmount: 0, // Será calculado na próxima tela
      );

      if (passengerPromo != null) {
        setState(() {
          _appliedPromoCode = code;
          _promoDiscount = passengerPromo.value;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Código aplicado! Desconto: R\$ ${_promoDiscount.toStringAsFixed(2)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      // Se não for código de passageiro, tenta como código geral
      final generalPromo = await _promoCodeService.getPromoCodeByCode(code);
      if (generalPromo != null && generalPromo.isActive) {
        setState(() {
          _appliedPromoCode = code;
          _promoDiscount = generalPromo.discountValue;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Código aplicado! Desconto: R\$ ${_promoDiscount.toStringAsFixed(2)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      // Código inválido
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código promocional inválido'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao validar código: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isValidatingPromo = false);
      }
    }
  }

  Widget _promoCodeSection() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_appliedPromoCode != null) ...
            [
              Row(
                children: [
                  Icon(Icons.check_circle, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Código $_appliedPromoCode aplicado',
                      style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    'R\$ ${_promoDiscount.toStringAsFixed(2)}',
                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _appliedPromoCode = null;
                        _promoDiscount = 0.0;
                        _promoController.clear();
                      });
                    },
                    icon: Icon(Icons.close, size: 20, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ] else ...
            [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoController,
                      decoration: InputDecoration(
                        hintText: 'Digite o código promocional',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colorScheme.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colorScheme.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colorScheme.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isValidatingPromo ? null : _validatePromoCode,
                    child: _isValidatingPromo
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Aplicar'),
                  ),
                ],
              ),
            ],
        ],
      ),
    );
  }

  void _continue() {
    Navigator.pushNamed(
      context,
      DriverSelectionScreen.routeName,
      arguments: {
        'origin': widget.origin.toJson(),
        'destination': widget.destination.toJson(),
        'vehicle_category': _selectedCategory.id,
        'needsPet': _needsPet,
        'needsGrocery': _needsGrocery,
        'needsCondo': _needsCondo,
        'additionalStop': false,
        'appliedPromoCode': _appliedPromoCode,
        'promoDiscount': _promoDiscount,
      },
    );
  }
}

class _LocationsSummary extends StatelessWidget {
  const _LocationsSummary({required this.origin, required this.destination});
  final FavoriteLocation origin;
  final FavoriteLocation destination;
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.my_location, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  origin.address,
                  style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, color: colorScheme.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  destination.address,
                  style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Text(
      title,
      style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
    );
  }
}