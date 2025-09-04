import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/supabase/driver.dart';
import '../models/trip_preferences.dart';
import '../models/vehicle_category.dart';
import 'driver_operation_zones_service.dart';

/// Serviço para cálculo de preços individuais por motorista
/// Utiliza os campos custom_price_per_km e custom_price_per_minute
class IndividualPricingService {
  
  /// Calcula o preço individual para um motorista específico
  /// Implementa a fórmula exata conforme documento de negócio:
  /// PreçoTotal = (ComponenteDistancia + ComponenteTempo + TaxasAdicionais) * MultiplicadorZona
  /// 
  /// Parâmetros:
  /// - [driver]: Motorista para calcular o preço
  /// - [totalDistanceKm]: Distância total incluindo trajeto do motorista até passageiro + viagem
  /// - [totalDurationMinutes]: Tempo total incluindo trajeto do motorista + viagem
  /// - [categoryData]: Dados da categoria para fallback de preços
  /// - [preferences]: Preferências da viagem para cálculo de taxas adicionais
  /// - [numberOfStops]: Número de paradas adicionais
  /// - [originLocation]: Localização de origem da corrida (opcional)
  /// - [destinationLocation]: Localização de destino da corrida (opcional)
  /// - [operationZonesService]: Serviço para buscar áreas de atuação (opcional)
  /// 
  /// Retorna o preço total calculado para este motorista
  static Future<double> calculateDriverPrice({
    required Driver driver,
    required double totalDistanceKm,
    required int totalDurationMinutes,
    required VehicleCategoryData categoryData,
    TripPreferences? preferences,
    int numberOfStops = 0,
    LatLng? originLocation,
    LatLng? destinationLocation,
    DriverOperationZonesService? operationZonesService,
  }) async {
    // 1. COMPONENTE DISTÂNCIA: PreçoKM_Aplicado * DistânciaTotal
    final distanceComponent = calculateComponenteDistancia(
      driver: driver,
      totalDistanceKm: totalDistanceKm,
      categoryData: categoryData,
    );
    
    // 2. COMPONENTE TEMPO: PreçoMin_Aplicado * TempoTotal
    final timeComponent = calculateComponenteTempo(
      driver: driver,
      totalDurationMinutes: totalDurationMinutes,
      categoryData: categoryData,
    );
    
    // 3. TAXAS ADICIONAIS
    final additionalFees = _calculateDriverSpecificAdditionalFees(
      driver: driver,
      preferences: preferences ?? const TripPreferences(),
      numberOfStops: numberOfStops,
    );
    
    // 4. PREÇO BASE: ComponenteDistancia + ComponenteTempo + TaxasAdicionais
    final basePrice = distanceComponent + timeComponent + additionalFees;
    
    // 5. MULTIPLICADOR DE ZONA: Verifica se a corrida está em área de atuação do motorista
    double zoneMultiplier = 1.0;
    if (operationZonesService != null && (originLocation != null || destinationLocation != null)) {
      try {
        // Verificar origem primeiro
        if (originLocation != null) {
          final originMultiplier = await operationZonesService.getPriceMultiplierForPoint(
            driver.id,
            originLocation,
          );
          if (originMultiplier > 1.0) {
            zoneMultiplier = originMultiplier;
          }
        }
        
        // Se não achou na origem, verificar destino
        if (zoneMultiplier == 1.0 && destinationLocation != null) {
          final destinationMultiplier = await operationZonesService.getPriceMultiplierForPoint(
            driver.id,
            destinationLocation,
          );
          zoneMultiplier = destinationMultiplier;
        }
      } catch (e) {
        // Em caso de erro, usar multiplicador padrão (1.0)
        print('⚠️ Erro ao calcular multiplicador de zona para driver ${driver.id}: $e');
      }
    }
    
    // 6. PREÇO TOTAL: PreçoBase * MultiplicadorZona
    final totalPrice = basePrice * zoneMultiplier;
    
    // Garantir preço mínimo (configurável via platform_settings)
    return math.max(totalPrice, 8); // TODO: Usar PlatformSettingsService.getMinFare()
  }

  /// Versão síncrona para compatibilidade com código existente
  /// NÃO considera multiplicadores de zona - use a versão async para funcionalidade completa
  @Deprecated('Use calculateDriverPrice com parâmetros de localização para preços com zonas')
  static double calculateDriverPriceSync({
    required Driver driver,
    required double totalDistanceKm,
    required int totalDurationMinutes,
    required VehicleCategoryData categoryData,
    TripPreferences? preferences,
    int numberOfStops = 0,
  }) {
    // 1. COMPONENTE DISTÂNCIA: PreçoKM_Aplicado * DistânciaTotal
    final distanceComponent = calculateComponenteDistancia(
      driver: driver,
      totalDistanceKm: totalDistanceKm,
      categoryData: categoryData,
    );
    
    // 2. COMPONENTE TEMPO: PreçoMin_Aplicado * TempoTotal
    final timeComponent = calculateComponenteTempo(
      driver: driver,
      totalDurationMinutes: totalDurationMinutes,
      categoryData: categoryData,
    );
    
    // 3. TAXAS ADICIONAIS
    final additionalFees = _calculateDriverSpecificAdditionalFees(
      driver: driver,
      preferences: preferences ?? const TripPreferences(),
      numberOfStops: numberOfStops,
    );
    
    // 4. PREÇO TOTAL: ComponenteDistancia + ComponenteTempo + TaxasAdicionais
    final totalPrice = distanceComponent + timeComponent + additionalFees;
    
    // Garantir preço mínimo (configurável via platform_settings)
    return math.max(totalPrice, 8); // TODO: Usar PlatformSettingsService.getMinFare()
  }
  
  /// Calcula o componente de distância da fórmula de precificação
  /// ComponenteDistancia = PreçoKM_Aplicado * DistânciaTotal
  /// 
  /// PreçoKM_Aplicado é o Preço por KM Personalizado do Condutor
  /// Se não definido, usa o ValorBaseKM da plataforma
  static double calculateComponenteDistancia({
    required Driver driver,
    required double totalDistanceKm,
    required VehicleCategoryData categoryData,
  }) {
    final pricePerKmApplied = driver.customPricePerKm != null && driver.customPricePerKm! > 0
        ? driver.customPricePerKm!
        : categoryData.basePricePerKm;
    
    return pricePerKmApplied * totalDistanceKm;
  }
  
  /// Calcula o componente de tempo da fórmula de precificação
  /// ComponenteTempo = PreçoMin_Aplicado * TempoTotal
  /// 
  /// PreçoMin_Aplicado é o Preço por Minuto Personalizado do Condutor
  /// Se não definido, usa o ValorBaseMin da plataforma
  static double calculateComponenteTempo({
    required Driver driver,
    required int totalDurationMinutes,
    required VehicleCategoryData categoryData,
  }) {
    final pricePerMinuteApplied = driver.customPricePerMinute != null && driver.customPricePerMinute! > 0
        ? driver.customPricePerMinute!
        : categoryData.basePricePerMinute;
    
    return pricePerMinuteApplied * totalDurationMinutes;
  }
  
  /// Calcula preços individuais para uma lista de motoristas
  /// Cada motorista pode ter preços e taxas diferentes
  /// 
  /// Parâmetros:
  /// - [drivers]: Lista de motoristas para calcular preços
  /// - [tripDistanceKm]: Distância da viagem (origem → destino)
  /// - [tripDurationMinutes]: Duração da viagem
  /// - [driverToPassengerDistances]: Distâncias de cada motorista até o passageiro
  /// - [driverETAs]: Tempos estimados de chegada de cada motorista
  /// - [categoryData]: Dados da categoria para fallback
  /// - [preferences]: Preferências da viagem
  /// - [numberOfStops]: Número de paradas adicionais
  static List<DriverPriceInfo> calculatePricesForDrivers({
    required List<Driver> drivers,
    required double tripDistanceKm,
    required int tripDurationMinutes,
    required Map<String, double> driverToPassengerDistances,
    required Map<String, int> driverETAs,
    required VehicleCategoryData categoryData,
    TripPreferences? preferences,
    int numberOfStops = 0,
  }) => drivers.map((driver) {
      // Distância total = trajeto do motorista até passageiro + viagem
      final driverToPassengerDistance = driverToPassengerDistances[driver.id] ?? 0.0;
      final totalDistanceKm = driverToPassengerDistance + tripDistanceKm;
      
      // Tempo total = ETA do motorista + duração da viagem
      final driverETA = driverETAs[driver.id] ?? 0;
      final totalDurationMinutes = driverETA + tripDurationMinutes;
      
      final price = calculateDriverPriceSync(
        driver: driver,
        totalDistanceKm: totalDistanceKm,
        totalDurationMinutes: totalDurationMinutes,
        categoryData: categoryData,
        preferences: preferences,
        numberOfStops: numberOfStops,
      );
      
      return DriverPriceInfo(
        driver: driver,
        calculatedPrice: price,
        usesCustomPricing: _hasCustomPricing(driver),
        distanceToPassenger: driverToPassengerDistance,
        estimatedArrivalMinutes: driverETA,
      );
    }).toList();
  
  /// Calcula taxas adicionais específicas do motorista
  /// Usa as taxas definidas pelo próprio motorista quando disponíveis
  static double _calculateDriverSpecificAdditionalFees({
    required Driver driver,
    required TripPreferences preferences,
    int numberOfStops = 0,
  }) {
    var totalFees = 0.0;
    
    // Taxa para Pet - usa taxa do motorista ou padrão
    if (preferences.needsPet && driver.acceptsPet) {
      totalFees += driver.petFee;
    }
    
    // Taxa para Mercado/Grocery - usa taxa do motorista ou padrão  
    if (preferences.needsGrocerySpace && driver.acceptsGrocery) {
      totalFees += driver.groceryFee;
    }
    
    // Taxa para Condomínio - usa taxa do motorista ou padrão
    if ((preferences.isCondoOrigin || preferences.isCondoDestination) && driver.acceptsCondo) {
      totalFees += driver.condoFee;
    }
    
    // Taxa por Parada - TaxaPorParada multiplicada pelo número de paradas
    if (numberOfStops > 0) {
      totalFees += driver.stopFee * numberOfStops;
    }
    
    return totalFees;
  }
  
  /// Calcula taxas adicionais genéricas (para uso geral sem motorista específico)
  static double calculateGenericAdditionalFees({
    bool needsPet = false,
    bool needsGrocerySpace = false,
    bool isCondoOrigin = false,
    bool isCondoDestination = false,
    int numberOfStops = 0,
  }) {
    var fees = 0.0;
    
    if (needsPet) {
      fees += 3;
    }
    if (needsGrocerySpace) {
      fees += 2;
    }
    if (isCondoOrigin || isCondoDestination) {
      fees += 2.5;
    }
    if (numberOfStops > 0) {
      fees += numberOfStops * 2;
    }
    
    return fees;
  }
  
  /// Verifica se o motorista tem preços personalizados
  static bool _hasCustomPricing(Driver driver) => (driver.customPricePerKm != null && driver.customPricePerKm! > 0) ||
           (driver.customPricePerMinute != null && driver.customPricePerMinute! > 0);
  
  /// Ordena motoristas por preço (menor para maior)
  static List<DriverPriceInfo> sortByPrice(List<DriverPriceInfo> driverPrices) =>
      List<DriverPriceInfo>.from(driverPrices)
        ..sort((a, b) => a.calculatedPrice.compareTo(b.calculatedPrice));
  
  /// Ordena motoristas por distância (mais próximo primeiro)
  static List<DriverPriceInfo> sortByDistance(List<DriverPriceInfo> driverPrices, {
    required double originLat,
    required double originLng,
  }) => List<DriverPriceInfo>.from(driverPrices)
      ..sort((a, b) {
        final distanceA = _calculateDistance(
          originLat, originLng,
          a.driver.currentLatitude ?? 0,
          a.driver.currentLongitude ?? 0,
        );
        final distanceB = _calculateDistance(
          originLat, originLng,
          b.driver.currentLatitude ?? 0,
          b.driver.currentLongitude ?? 0,
        );
        return distanceA.compareTo(distanceB);
      });
  
  /// Calcula distância entre dois pontos usando fórmula de Haversine
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Raio da Terra em km
    
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
}

/// Classe que combina informações do motorista com seu preço calculado
class DriverPriceInfo {
  const DriverPriceInfo({
    required this.driver,
    required this.calculatedPrice,
    required this.usesCustomPricing,
    this.distanceToPassenger,
    this.estimatedArrivalMinutes,
  });
  
  /// Motorista
  final Driver driver;
  
  /// Preço calculado para este motorista
  final double calculatedPrice;
  
  /// Se o motorista usa preços personalizados
  final bool usesCustomPricing;
  
  /// Distância do motorista até o passageiro em KM
  final double? distanceToPassenger;
  
  /// Tempo estimado de chegada em minutos
  final int? estimatedArrivalMinutes;
  
  /// Preço formatado para exibição
  String get formattedPrice => 'R\$ ${calculatedPrice.toStringAsFixed(2)}';
  
  /// Indica se é uma opção econômica (preço personalizado menor)
  bool get isEconomical => usesCustomPricing;
  
  @override
  String toString() => 'DriverPriceInfo(${driver.brand} ${driver.model}, $formattedPrice)';
}

/// Resultado do cálculo de preços para múltiplos motoristas
class PricingResult {
  const PricingResult({
    required this.driverPrices,
    required this.averagePrice,
    required this.lowestPrice,
    required this.highestPrice,
  });
  
  /// Cria resultado a partir de lista de preços
  factory PricingResult.fromDriverPrices(List<DriverPriceInfo> driverPrices) {
    if (driverPrices.isEmpty) {
      return const PricingResult(
        driverPrices: [],
        averagePrice: 0,
        lowestPrice: 0,
        highestPrice: 0,
      );
    }
    
    final prices = driverPrices.map((dp) => dp.calculatedPrice).toList();
    final averagePrice = prices.reduce((a, b) => a + b) / prices.length;
    final lowestPrice = prices.reduce(math.min);
    final highestPrice = prices.reduce(math.max);
    
    return PricingResult(
      driverPrices: driverPrices,
      averagePrice: averagePrice,
      lowestPrice: lowestPrice,
      highestPrice: highestPrice,
    );
  }
  
  /// Lista de motoristas com preços
  final List<DriverPriceInfo> driverPrices;
  
  /// Preço médio
  final double averagePrice;
  
  /// Menor preço
  final double lowestPrice;
  
  /// Maior preço
  final double highestPrice;
  
  /// Diferença entre maior e menor preço
  double get priceRange => highestPrice - lowestPrice;
  
  /// Motoristas ordenados por preço
  List<DriverPriceInfo> get sortedByPrice => 
      IndividualPricingService.sortByPrice(driverPrices);
}