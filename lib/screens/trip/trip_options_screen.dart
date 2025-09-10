import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../models/vehicle_category.dart';
import '../../services/driver_service.dart';
import '../../services/individual_pricing_service.dart';
import '../../services/location_service.dart';
import '../../services/passenger_promo_service.dart';
import '../../services/promo_code_service.dart';
import '../../services/search_status_service.dart';
import '../../services/user_service.dart';

import '../../widgets/logo_branding.dart';
import '../../widgets/search_feedback_widget.dart';
import 'driver_selection_screen.dart';

class TripOptionsScreen extends StatefulWidget {

  const TripOptionsScreen({
    super.key,
    required this.origin,
    required this.destination,
  });

  factory TripOptionsScreen.fromArgs(Map<String, dynamic>? args) {
    print('🎯 TripOptionsScreen.fromArgs chamado');
    print('🎯 Args recebidos: $args');
    
    final originJson = (args?['origin'] as Map<String, dynamic>?) ?? {};
    final destinationJson = (args?['destination'] as Map<String, dynamic>?) ?? {};
    
    print('🎯 Origin JSON: $originJson');
    print('🎯 Destination JSON: $destinationJson');
    
    try {
      final origin = _parseLocationFromJson(originJson);
      final destination = _parseLocationFromJson(destinationJson);
      
      print('✅ Localizações criadas com sucesso');
      
      return TripOptionsScreen(
        origin: origin,
        destination: destination,
      );
    } catch (e) {
      print('❌ Erro ao criar localizações: $e');
      rethrow;
    }
  }
  static const String routeName = '/trip_options';

  final Map<String, dynamic> origin;
  final Map<String, dynamic> destination;

  static Map<String, dynamic> _parseLocationFromJson(Map<String, dynamic> json) {
    return {
      'id': json['id'],
      'name': json['name'],
      'address': json['address'],
      'latitude': json['latitude'],
      'longitude': json['longitude'],
      'placeId': json['placeId'],
    };
  }

  @override
  State<TripOptionsScreen> createState() => _TripOptionsScreenState();
}

class _TripOptionsScreenState extends State<TripOptionsScreen>
    with TickerProviderStateMixin {
  String? _selectedCategoryId;
  bool _needsPet = false;
  bool _needsGrocerySpace = false;
  bool _isCondoOrigin = false;
  bool _isCondoDestination = false;
  List<VehicleCategoryData> _categoryData = [];
  bool _isLoading = true;
  late final DriverService _driverService;
  late final LocationService _locationService;
  late final PassengerPromoService _passengerPromoService;
  late final PromoCodeService _promoCodeService;
  late final SearchStatusService _searchStatusService;
  late final AnimationController _buttonController;
  late final Animation<double> _buttonScaleAnimation;
  
  // Pricing state
  double? _estimatedPrice;
  double? _distanceComponent;
  double? _timeComponent;
  double? _additionalFees;
  bool _isCalculatingPrice = false;
  
  // Promo code state
  final TextEditingController _promoController = TextEditingController();
  String? _appliedPromoCode;
  double _promoDiscount = 0;
  bool _isValidatingPromo = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _driverService = DriverService(Supabase.instance.client);
    _locationService = LocationService(apiKey: AppConfig.googleMapsApiKey);
    _passengerPromoService = PassengerPromoService();
    _promoCodeService = PromoCodeService();
    _searchStatusService = SearchStatusService();
    
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _buttonScaleAnimation = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ),);
    
    _loadCategoryData();
    _calculatePrice(); // Calculate initial price
  }

  @override
  void dispose() {
    _promoController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoryData() async {
    try {
      setState(() => _isLoading = true);
      
      // Garante coordenadas válidas para a origem
      var lat = (widget.origin['latitude'] as num?)?.toDouble();
      var lng = (widget.origin['longitude'] as num?)?.toDouble();

      if ((lat == null || lng == null) && widget.origin['placeId'] != null) {
        final details = await _locationService.getPlaceDetails(widget.origin['placeId'] as String);
        lat = (details?['lat'] as num?)?.toDouble() ?? lat;
        lng = (details?['lng'] as num?)?.toDouble() ?? lng;
      }

      if (lat == null || lng == null) {
        final current = await _locationService.getCurrentLocation();
        lat = (current?['lat'] as num?)?.toDouble() ?? lat;
        lng = (current?['lng'] as num?)?.toDouble() ?? lng;
      }

      if (lat == null || lng == null) {
        // Fallback para dados padrão se ainda não for possível obter coordenadas
        if (mounted) {
          setState(() {
            _categoryData = VehicleCategory.popularCategories
                .map(VehicleCategoryData.defaultForCategory)
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
        // Removido parâmetro inválido radiusKm
      );
      
      if (mounted) {
        setState(() {
          _categoryData = categories;
          // Define a primeira categoria disponível como selecionada se ainda não houver seleção
          if (_selectedCategoryId == null && categories.isNotEmpty) {
            _selectedCategoryId = categories.first.categoryId;
          }
          _isLoading = false;
        });
      }
    } on Exception {
      // Em caso de erro, usa dados padrão
      if (mounted) {
        setState(() {
          _categoryData = VehicleCategory.popularCategories
              .map(VehicleCategoryData.defaultForCategory)
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categoryData.length,
                          itemBuilder: (context, index) {
                            final data = _categoryData[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                right: index < _categoryData.length - 1 ? 12 : 0,
                              ),
                              child: _categoryCard(data),
                            );
                          },
                        ),
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
                      value: _needsGrocerySpace,
                          onChanged: (v) => setState(() => _needsGrocerySpace = v),
                    ),
                    _prefTile(
                      title: 'Condomínio (acesso facilitado)',
                      value: _isCondoOrigin || _isCondoDestination,
                          onChanged: (v) => setState(() {
                            _isCondoOrigin = v;
                            _isCondoDestination = v;
                          }),
                    ),
                    const SizedBox(height: 16),
                    const _SectionTitle(title: 'Código promocional'),
                    const SizedBox(height: 8),
                    _promoCodeSection(),
                    const SizedBox(height: 16),
                    
                    // Widget de feedback visual para busca
                    const SearchFeedbackWidget(
                      showOnlyWhenActive: true,
                      compact: true,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // Botão fixo na parte inferior
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 56,
                child: AnimatedBuilder(
                  animation: _buttonScaleAnimation,
                  builder: (context, child) => Transform.scale(
                    scale: _buttonScaleAnimation.value,
                    child: FilledButton.icon(
                      onPressed: _isNavigating ? null : _continue,
                      icon: _isNavigating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.search),
                      label: Text(_isNavigating ? 'Buscando...' : 'Buscar motoristas'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIconByName(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'comum':
      case 'common_car':
      case 'carro comum':
        return Icons.directions_car;
      case 'freight':
      case 'frete':
      case 'carga':
        return Icons.local_shipping;
      case 'tow_truck':
      case 'guincho':
        return Icons.build;
      default:
        return Icons.directions_car; // Ícone padrão
    }
  }

  Widget _categoryCard(VehicleCategoryData data) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selected = _selectedCategoryId == data.categoryId;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = data.categoryId),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primaryContainer : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCategoryIconByName(data.categoryName),
              size: 24,
              color: selected ? colorScheme.onPrimaryContainer : colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              data.categoryName,
              style: textTheme.titleSmall?.copyWith(
                color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            if (data.availableDrivers > 0) ...[
              const SizedBox(height: 1),
              Text(
                '${data.availableDrivers} ${data.availableDrivers == 1 ? 'motorista' : 'motoristas'}',
                style: textTheme.bodySmall?.copyWith(
                  color: selected ? colorScheme.onPrimaryContainer : colorScheme.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const SizedBox(height: 1),
              Text(
                'Indisponível',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
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
      onChanged: (v) {
        onChanged(v);
        _calculatePrice(); // Recalculate price when preference changes
      },
      activeThumbColor: colorScheme.primary,
    );
  }

  Future<void> _validatePromoCode() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isValidatingPromo = true);

    try {
      debugPrint('🎯 Validating promo code: $code');
      
      final user = await UserService.getCurrentUser();
      if (user == null) {
        throw Exception('Usuário não encontrado');
      }

      debugPrint('✅ User found: ${user.id}');

      // Tenta validar como código de passageiro primeiro
      try {
        final passengerPromo = await _passengerPromoService.validatePromoCode(
          code,
          user.id,
          tripAmount: 0, // Será calculado na próxima tela
        );

        if (passengerPromo != null) {
          debugPrint('✅ Passenger promo found: ${passengerPromo.value}');
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
        debugPrint('❌ No passenger promo found');
      } catch (e) {
        debugPrint('❌ Error checking passenger promo: $e');
      }

      // Se não for código de passageiro, tenta como código geral
      try {
        final generalPromo = await _promoCodeService.getPromoCodeByCode(code);
        debugPrint('🔍 General promo result: $generalPromo');
        
        if (generalPromo != null && generalPromo.isActive) {
          debugPrint('✅ General promo found: ${generalPromo.discountValue}');
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
        debugPrint('❌ General promo not found or inactive');
      } catch (e) {
        debugPrint('❌ Error checking general promo: $e');
      }

      // Código inválido
      debugPrint('❌ Invalid promo code: $code');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código promocional inválido ou expirado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ General error validating promo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao validar código. Tente novamente.'),
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
        color: Colors.white,
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
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colorScheme.error),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 20,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                      onChanged: (value) {
                        // Remove espaços e converte para maiúsculo
                        final cleaned = value.replaceAll(' ', '').toUpperCase();
                        if (cleaned != value) {
                          _promoController.value = TextEditingValue(
                            text: cleaned,
                            selection: TextSelection.collapsed(offset: cleaned.length),
                          );
                        }
                      },
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

  Future<void> _calculatePrice() async {
    if (_isCalculatingPrice) return;
    
    setState(() => _isCalculatingPrice = true);
    
    try {
      // Get coordinates from origin and destination
      final originLat = (widget.origin['latitude'] as num?)?.toDouble();
      final originLng = (widget.origin['longitude'] as num?)?.toDouble();
      final destLat = (widget.destination['latitude'] as num?)?.toDouble();
      final destLng = (widget.destination['longitude'] as num?)?.toDouble();
      
      if (originLat == null || originLng == null || destLat == null || destLng == null) {
        // Cannot calculate price without coordinates
        _resetPriceState();
        return;
      }
      
      // Calculate distance and duration using Google Maps API
      final distanceKm = await _calculateDistance(originLat, originLng, destLat, destLng);
      final durationMinutes = await _calculateDuration(originLat, originLng, destLat, destLng);
      
      if (distanceKm == null || durationMinutes == null) {
        _resetPriceState();
        return;
      }
      
      // Calculate price components using generic pricing formula
      if (_selectedCategoryId == null) return;
      
      final categoryData = _categoryData.firstWhere(
        (data) => data.categoryId == _selectedCategoryId,
        orElse: () => _categoryData.first, // fallback para primeira categoria disponível
      );
      
      // Calculate components using platform base prices
      final distanceComponent = categoryData.basePricePerKm * distanceKm;
      final timeComponent = categoryData.basePricePerMinute * durationMinutes;
      final additionalFees = IndividualPricingService.calculateGenericAdditionalFees(
        needsPet: _needsPet,
        needsGrocerySpace: _needsGrocerySpace,
        isCondoOrigin: _isCondoOrigin,
        isCondoDestination: _isCondoDestination,
      );
      
      // Total price
      final totalPrice = distanceComponent + timeComponent + additionalFees;
      
      if (mounted) {
        setState(() {
          _estimatedPrice = totalPrice;
          _distanceComponent = distanceComponent;
          _timeComponent = timeComponent;
          _additionalFees = additionalFees;
        });
      }
    } catch (e) {
      debugPrint('❌ Error calculating price: $e');
      _resetPriceState();
    } finally {
      if (mounted) {
        setState(() => _isCalculatingPrice = false);
      }
    }
  }
  
  void _resetPriceState() {
    if (mounted) {
      setState(() {
        _estimatedPrice = null;
        _distanceComponent = null;
        _timeComponent = null;
        _additionalFees = null;
      });
    }
  }
  
  Future<double?> _calculateDistance(double originLat, double originLng, double destLat, double destLng) async {
    try {
      // Simple distance calculation using Haversine formula
      const double earthRadius = 6371; // Earth radius in km
      
      final dLat = (destLat - originLat) * 3.141592653589793 / 180;
      final dLon = (destLng - originLng) * 3.141592653589793 / 180;
      
      final a = sin(dLat / 2) * sin(dLat / 2) +
          cos(originLat * pi / 180) *
          cos(destLat * pi / 180) *
          sin(dLon / 2) * sin(dLon / 2);
      
      final c = 2 * atan2(sqrt(a), sqrt(1 - a));
      
      return earthRadius * c;
    } catch (e) {
      debugPrint('❌ Error calculating distance: $e');
      return null;
    }
  }
  
  Future<int?> _calculateDuration(double originLat, double originLng, double destLat, double destLng) async {
    try {
      // Estimate duration based on distance (average speed of 30 km/h)
      final distance = await _calculateDistance(originLat, originLng, destLat, destLng);
      if (distance == null) return null;
      
      // Average speed: 30 km/h = 0.5 km/min
      final minutes = (distance / 0.5).ceil();
      return minutes.clamp(1, 180); // Cap at 3 hours
    } catch (e) {
      debugPrint('❌ Error calculating duration: $e');
      return null;
    }
  }

  Future<void> _continue() async {
    if (_isNavigating) return;
    
    // Feedback tátil
    HapticFeedback.mediumImpact();
    
    // Animação de pressão
    _buttonController.forward().then((_) {
      _buttonController.reverse();
    });
    
    // Iniciar busca com feedback visual
    _searchStatusService.startSearch(
      message: 'Preparando busca por motoristas...',
    );
    
    // Estado de loading
    setState(() {
      _isNavigating = true;
    });
    
    try {
      print('🚀 [TRIP_OPTIONS] Botão "Buscar Motoristas" pressionado');
      print('🚀 [TRIP_OPTIONS] Iniciando navegação para DriverSelectionScreen');
      print('🚀 [TRIP_OPTIONS] Argumentos de origem: ${widget.origin}');
      print('🚀 [TRIP_OPTIONS] Argumentos de destino: ${widget.destination}');
      print('🚀 [TRIP_OPTIONS] Categoria selecionada: ${_selectedCategoryId ?? (_categoryData.isNotEmpty ? _categoryData.first.categoryId : 'Comum')}');
      print('🚀 [TRIP_OPTIONS] Preferências: pet=$_needsPet, grocery=$_needsGrocerySpace, condo=$_isCondoOrigin/$_isCondoDestination');
      print('🚀 [TRIP_OPTIONS] Código promocional: $_appliedPromoCode (desconto: $_promoDiscount)');
      
      await Navigator.pushNamed(
        context,
        DriverSelectionScreen.routeName,
        arguments: {
          'origin': widget.origin,
          'destination': widget.destination,
          'vehicle_category': _selectedCategoryId ?? (_categoryData.isNotEmpty ? _categoryData.first.categoryId : 'Comum'),
          'needsPet': _needsPet,
          'needsGrocerySpace': _needsGrocerySpace,
          'isCondoOrigin': _isCondoOrigin,
          'isCondoDestination': _isCondoDestination,
          // Removed invalid 'additionalStop': false (expects String?)
          'appliedPromoCode': _appliedPromoCode,
          'promoDiscount': _promoDiscount,
        },
      );
      
      print('✅ [TRIP_OPTIONS] Navegação para DriverSelectionScreen concluída com sucesso');
      
      // Reset do estado após navegação bem-sucedida
      _searchStatusService.reset();
      print('🔄 [TRIP_OPTIONS] Estado de busca resetado');
    } catch (e, stackTrace) {
      print('❌ [TRIP_OPTIONS] Erro ao navegar para busca de motoristas: $e');
      print('📍 [TRIP_OPTIONS] Stack trace: $stackTrace');
      
      // Tratar erro de navegação
      _searchStatusService.markError(
        message: 'Erro ao navegar para busca de motoristas',
        errorDetails: e.toString(),
      );
      print('🚨 [TRIP_OPTIONS] Estado de erro marcado no SearchStatusService');
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
        print('🔄 [TRIP_OPTIONS] Estado de navegação resetado: $_isNavigating');
      }
    }
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