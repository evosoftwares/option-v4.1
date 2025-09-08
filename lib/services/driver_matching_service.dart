import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import '../models/supabase/driver.dart';
import '../models/supabase/passenger_request.dart';
import 'driver_excluded_zones_service.dart';
import 'driver_service.dart';
import 'location_service.dart';

/// Resultado do matching com informações detalhadas do motorista
class DriverMatchResult {
  const DriverMatchResult({
    required this.driver,
    required this.distanceKm,
    required this.estimatedArrivalMinutes,
    required this.matchScore,
    required this.isAvailable,
    this.unavailabilityReason,
  });

  final Driver driver;
  final double distanceKm;
  final int estimatedArrivalMinutes;
  final double matchScore; // Score de 0-100 baseado em múltiplos critérios
  final bool isAvailable;
  final String? unavailabilityReason;

  @override
  String toString() => 'DriverMatchResult(driver: ${driver.id}, distance: ${distanceKm.toStringAsFixed(2)}km, '
        'eta: ${estimatedArrivalMinutes}min, score: ${matchScore.toStringAsFixed(1)}, available: $isAvailable)';
}

/// Critérios para matching de motoristas
class MatchingCriteria {
  const MatchingCriteria({
    required this.passengerLatitude,
    required this.passengerLongitude,
    this.originNeighborhood,
    this.originCity,
    this.originState,
    this.destinationLatitude,
    this.destinationLongitude,
    this.destinationNeighborhood,
    this.destinationCity,
    this.destinationState,
    this.maxRadiusKm = 10.0,
    this.vehicleCategory,
    this.needsPet = false,
    this.needsAC = false,
    this.needsGrocery = false,
    this.needsCondo = false,
    this.maxDrivers = 10,
    this.prioritizeRating = true,
    this.prioritizeDistance = true,
    this.prioritizeResponseTime = true,
  });

  final double passengerLatitude;
  final double passengerLongitude;
  final String? originNeighborhood;
  final String? originCity;
  final String? originState;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final String? destinationNeighborhood;
  final String? destinationCity;
  final String? destinationState;
  final double maxRadiusKm;
  final String? vehicleCategory;
  final bool needsPet;
  final bool needsAC;
  final bool needsGrocery;
  final bool needsCondo;
  final int maxDrivers;
  final bool prioritizeRating;
  final bool prioritizeDistance;
  final bool prioritizeResponseTime;

  @override
  String toString() => 'MatchingCriteria(lat: $passengerLatitude, lon: $passengerLongitude, '
        'category: $vehicleCategory, radius: ${maxRadiusKm}km, maxDrivers: $maxDrivers, '
        'needsPet: $needsPet, needsGrocery: $needsGrocery, needsCondo: $needsCondo, needsAC: $needsAC)';
}

/// Serviço avançado de matching de motoristas
class DriverMatchingService {
  DriverMatchingService(this._supabase) {
    _driverService = DriverService(_supabase);
    _excludedZonesService = DriverExcludedZonesService(_supabase);
  }

  final SupabaseClient _supabase;
  late final DriverService _driverService;
  late final DriverExcludedZonesService _excludedZonesService;

  /// Cache para otimizar consultas repetidas
  final Map<String, List<Driver>> _driversCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(minutes: 2);

  /// Encontra os melhores motoristas para uma solicitação
  Future<List<DriverMatchResult>> findBestDrivers(MatchingCriteria criteria) async {
    print('🎯 [${DateTime.now()}] Iniciando matching com critérios:');
    print('  📍 Origem: (${criteria.passengerLatitude}, ${criteria.passengerLongitude})');
    print('  🎯 Destino: ${criteria.destinationNeighborhood ?? "N/A"}, ${criteria.destinationCity ?? "N/A"}');
    print('  🚗 Categoria: ${criteria.vehicleCategory ?? "Qualquer"}');
      print('  🐕 Pet: ${criteria.needsPet}');
      print('  ❄️ AC: ${criteria.needsAC}');
      print('  🛒 Mercado: ${criteria.needsGrocery}');
      print('  🏢 Condomínio: ${criteria.needsCondo}');
      print('  📏 Raio máximo: ${criteria.maxRadiusKm}km');

    try {
      // 1. Buscar motoristas disponíveis na região
      final availableDrivers = await _getAvailableDriversInRegion(criteria);
      print('✅ [${DateTime.now()}] ${availableDrivers.length} motoristas encontrados na região');

      if (availableDrivers.isEmpty) {
        print('❌ [${DateTime.now()}] Nenhum motorista disponível na região');
        return [];
      }

      // 2. Aplicar filtros de preferências
      final filteredByPreferences = await _filterByPreferences(availableDrivers, criteria);
      print('✅ [${DateTime.now()}] ${filteredByPreferences.length} motoristas após filtro de preferências');

      if (filteredByPreferences.isEmpty) {
        print('❌ [${DateTime.now()}] Nenhum motorista atende às preferências');
        return [];
      }

      // 3. Filtrar por zonas de exclusão
      final filteredByZones = await _filterByExclusionZones(filteredByPreferences, criteria);
      print('✅ [${DateTime.now()}] ${filteredByZones.length} motoristas após filtro de zonas de exclusão');

      if (filteredByZones.isEmpty) {
        print('❌ [${DateTime.now()}] Nenhum motorista disponível após filtro de zonas');
        return [];
      }

      // 4. Verificar disponibilidade em tempo real
      final realTimeAvailable = await _verifyRealTimeAvailability(filteredByZones);
      print('✅ [${DateTime.now()}] ${realTimeAvailable.length} motoristas disponíveis em tempo real');

      // 5. Calcular scores e ordenar
      final matchResults = await _calculateMatchScores(realTimeAvailable, criteria);
      print('✅ [${DateTime.now()}] Scores calculados para ${matchResults.length} motoristas');

      // 6. Ordenar por score e limitar resultado
      matchResults.sort((a, b) => b.matchScore.compareTo(a.matchScore));
      final finalResults = matchResults.take(criteria.maxDrivers).toList();

      print('🎉 [${DateTime.now()}] Matching finalizado com ${finalResults.length} motoristas');
      if (finalResults.isNotEmpty) {
        print('📊 Top 3 scores: ${finalResults.take(3).map((r) => r.matchScore.toStringAsFixed(1)).join(", ")}');
      }

      return finalResults;
    } catch (e, stackTrace) {
      print('❌ [${DateTime.now()}] Erro no matching: $e');
      print('📍 Stack trace: $stackTrace');
      throw DatabaseException('Erro ao buscar motoristas: $e');
    }
  }

  /// Busca motoristas disponíveis na região com cache
  Future<List<Driver>> _getAvailableDriversInRegion(MatchingCriteria criteria) async {
    final cacheKey = '${criteria.passengerLatitude}_${criteria.passengerLongitude}_'
        '${criteria.maxRadiusKm}_${criteria.vehicleCategory ?? "any"}';

    // Verificar cache
    if (_driversCache.containsKey(cacheKey) && _cacheTimestamps.containsKey(cacheKey)) {
      final cacheTime = _cacheTimestamps[cacheKey]!;
      if (DateTime.now().difference(cacheTime) < _cacheValidDuration) {
        print('📦 [${DateTime.now()}] Usando cache para motoristas na região');
        return _driversCache[cacheKey]!;
      }
    }

    // Buscar motoristas
    final drivers = await _driverService.getAvailableDriversNearby(
      latitude: criteria.passengerLatitude,
      longitude: criteria.passengerLongitude,
      radiusKm: criteria.maxRadiusKm,
      category: criteria.vehicleCategory,
      needsPet: criteria.needsPet,
      needsGrocerySpace: criteria.needsGrocery,
      isCondoOrigin: criteria.needsCondo,
      isCondoDestination: criteria.needsCondo,
      needsAc: criteria.needsAC,
      destinationNeighborhood: criteria.destinationNeighborhood,
      destinationCity: criteria.destinationCity,
      destinationState: criteria.destinationState,
      limit: 50, // Buscar mais para ter opções após filtros
    );

    // Atualizar cache
    _driversCache[cacheKey] = drivers;
    _cacheTimestamps[cacheKey] = DateTime.now();

    return drivers;
  }

  /// Filtra motoristas por preferências do passageiro
  Future<List<Driver>> _filterByPreferences(List<Driver> drivers, MatchingCriteria criteria) async => drivers.where((driver) {
      // Filtro de Pet
      if (criteria.needsPet && !(driver.acceptsPet ?? false)) {
        return false;
      }

      // Filtro de Mercado/Grocery
      if (criteria.needsGrocery && !(driver.acceptsGrocery ?? false)) {
        return false;
      }

      // Filtro de Condomínio
      if (criteria.needsCondo && !(driver.acceptsCondo ?? false)) {
        return false;
      }

      // Filtro de Ar Condicionado
      if (criteria.needsAC) {
        final acPolicy = driver.acPolicy?.toLowerCase();
        if (acPolicy == null || acPolicy == 'never' || acPolicy == 'nunca') {
          return false;
        }
      }

      return true;
    }).toList();

  /// Filtra motoristas por zonas de exclusão (sistema flexível com palavras-chave)
  /// Remove condutores que excluíram a origem OU destino da viagem
  Future<List<Driver>> _filterByExclusionZones(List<Driver> drivers, MatchingCriteria criteria) async {
    final filteredDrivers = <Driver>[];
    final driverIds = drivers.map((d) => d.id).toList();
    
    try {
      // Lista de IDs de motoristas que devem ser excluídos
      final excludedDriverIds = <String>{};

      // Construir endereços completos para verificação
      final originAddress = _buildFullAddress(
        neighborhood: criteria.originNeighborhood,
        city: criteria.originCity,
        state: criteria.originState,
      );
      
      final destinationAddress = _buildFullAddress(
        neighborhood: criteria.destinationNeighborhood,
        city: criteria.destinationCity,
        state: criteria.destinationState,
      );

      // Filtrar por endereço de ORIGEM (se disponível)
      if (originAddress.isNotEmpty) {
        final originExcludedDrivers = await _getExcludedDriversForAddress(
          driverIds,
          originAddress,
        );
        excludedDriverIds.addAll(originExcludedDrivers);
        print('🚫 ${originExcludedDrivers.length} motoristas excluíram origem: "$originAddress"');
      }

      // Filtrar por endereço de DESTINO (se disponível)
      if (destinationAddress.isNotEmpty) {
        final destinationExcludedDrivers = await _getExcludedDriversForAddress(
          driverIds,
          destinationAddress,
        );
        excludedDriverIds.addAll(destinationExcludedDrivers);
        print('🚫 ${destinationExcludedDrivers.length} motoristas excluíram destino: "$destinationAddress"');
      }

      // Filtrar motoristas que não excluíram nem origem nem destino
      for (final driver in drivers) {
        if (!excludedDriverIds.contains(driver.id)) {
          filteredDrivers.add(driver);
        }
      }

      print('✅ ${filteredDrivers.length}/${drivers.length} motoristas após filtro de zonas excluídas');
      return filteredDrivers;
    } catch (e) {
      // Em caso de erro, retorna todos os motoristas para não impactar a funcionalidade
      print('⚠️ Erro ao verificar zonas excluídas: $e');
      return drivers;
    }
  }

  /// Busca motoristas que excluíram um endereço específico (sistema flexível)
  Future<Set<String>> _getExcludedDriversForAddress(
    List<String> driverIds,
    String fullAddress,
  ) async {
    try {
      // Usar a função SQL get_excluded_drivers_for_address
      final response = await _supabase
          .rpc('get_excluded_drivers_for_address', params: {
            'full_address': fullAddress,
          });

      final excludedDrivers = (response as List<dynamic>)
          .map((row) => row['driver_id'] as String)
          .where((driverId) => driverIds.contains(driverId))
          .toSet();

      return excludedDrivers;
    } catch (e) {
      print('❌ Erro ao buscar motoristas excluídos para endereço "$fullAddress": $e');
      // Fallback para sistema legado se a função RPC falhar
      return await _getExcludedZonesForDriversLegacy(driverIds, fullAddress);
    }
  }

  /// Fallback para sistema legado de exclusão por bairro
  Future<Set<String>> _getExcludedZonesForDriversLegacy(
    List<String> driverIds,
    String fullAddress,
  ) async {
    try {
      // Busca por correspondência simples usando ILIKE
      final response = await _supabase
          .from('driver_excluded_zones')
          .select('driver_id')
          .inFilter('driver_id', driverIds)
          .or('neighborhood_name.ilike.%${_extractSearchTerms(fullAddress)}%');

      return (response as List<dynamic>)
          .map((row) => row['driver_id'] as String)
          .toSet();
    } catch (e) {
      print('❌ Erro no fallback legado: $e');
      return <String>{};
    }
  }

  /// Constrói endereço completo a partir dos componentes
  String _buildFullAddress({
    String? neighborhood,
    String? city,
    String? state,
  }) {
    final parts = <String>[];
    if (neighborhood != null && neighborhood.isNotEmpty) parts.add(neighborhood);
    if (city != null && city.isNotEmpty) parts.add(city);
    if (state != null && state.isNotEmpty) parts.add(state);
    return parts.join(' - ');
  }

  /// Extrai termos de busca do endereço para fallback
  String _extractSearchTerms(String address) {
    // Remove caracteres especiais e pega a primeira palavra significativa
    final cleaned = address.replaceAll(RegExp(r'[^\w\s]'), ' ').trim();
    final words = cleaned.split(RegExp(r'\s+'));
    return words.isNotEmpty ? words.first : '';
  }

  /// Verifica disponibilidade em tempo real dos motoristas
  Future<List<Driver>> _verifyRealTimeAvailability(List<Driver> drivers) async {
    final availableDrivers = <Driver>[];

    for (final driver in drivers) {
      try {
        // Verificar se o motorista não está em viagem ativa
        final activeTrips = await _driverService.getDriverActiveTrips(driver.id);
        
        if (activeTrips.isEmpty) {
          // Verificar se ainda está online (pode ter ficado offline recentemente)
          final currentDriver = await _driverService.getDriver(driver.id);
          if (currentDriver?.isOnline ?? false) {
            availableDrivers.add(driver);
          }
        }
      } catch (e) {
        // Em caso de erro, assume que está disponível para não impactar a funcionalidade
        print('⚠️ Erro ao verificar disponibilidade do motorista ${driver.id}: $e');
        availableDrivers.add(driver);
      }
    }

    return availableDrivers;
  }

  /// Calcula scores de matching para cada motorista
  Future<List<DriverMatchResult>> _calculateMatchScores(List<Driver> drivers, MatchingCriteria criteria) async {
    final results = <DriverMatchResult>[];

    for (final driver in drivers) {
      if (driver.currentLatitude == null || driver.currentLongitude == null) {
        continue; // Pula motoristas sem localização
      }

      // Calcular distância
      final distance = _calculateHaversineDistance(
        criteria.passengerLatitude,
        criteria.passengerLongitude,
        driver.currentLatitude!,
        driver.currentLongitude!,
      );

      // Calcular ETA estimado (baseado em 30km/h médio no trânsito urbano)
      final etaMinutes = (distance * 2).round(); // 30km/h = 0.5km/min

      // Calcular score de matching
      final score = _calculateMatchScore(driver, distance, criteria);

      results.add(DriverMatchResult(
        driver: driver,
        distanceKm: distance,
        estimatedArrivalMinutes: etaMinutes,
        matchScore: score,
        isAvailable: true,
      ));
    }

    return results;
  }

  /// Calcula score de matching baseado em múltiplos critérios
  double _calculateMatchScore(Driver driver, double distance, MatchingCriteria criteria) {
    var score = 0.0;

    // 1. Score de distância (40% do peso total) - mais próximo = melhor
    if (criteria.prioritizeDistance) {
      final maxDistance = criteria.maxRadiusKm;
      final distanceScore = ((maxDistance - distance) / maxDistance) * 40;
      score += math.max(0.0, distanceScore);
    }

    // 2. Score de rating (30% do peso total)
    if (criteria.prioritizeRating && driver.ratings > 0) {
      final ratingScore = (driver.ratings / 5.0) * 30;
      score += ratingScore;
    } else {
      // Motoristas sem rating recebem score neutro
      score += 15.0;
    }

    // 3. Score de experiência (20% do peso total)
    final totalTrips = driver.trips;
    final experienceScore = math.min(totalTrips / 100.0, 1) * 20; // Max 100 viagens para score máximo
    score += experienceScore;

    // 4. Score de confiabilidade (10% do peso total)
    final cancellations = driver.cancellations;
    final reliabilityScore = math.max(0, (5 - cancellations) / 5.0) * 10;
    score += reliabilityScore;

    // Bônus por preferências atendidas
    if (criteria.needsPet && (driver.acceptsPet ?? false)) score += 2.0;
    if (criteria.needsGrocery && (driver.acceptsGrocery ?? false)) score += 2.0;
    if (criteria.needsCondo && (driver.acceptsCondo ?? false)) score += 2.0;
    if (criteria.needsAC && driver.acPolicy != null && 
        !['never', 'nunca'].contains(driver.acPolicy!.toLowerCase())) {
      score += 2.0;
    }

    return math.min(100, score); // Score máximo de 100
  }

  /// Calcula a distância entre dois pontos usando a fórmula de Haversine
  double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
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

  /// Limpa o cache de motoristas
  void clearCache() {
    _driversCache.clear();
    _cacheTimestamps.clear();
    print('🧹 [${DateTime.now()}] Cache de motoristas limpo');
  }

  /// Cria critérios de matching a partir de uma solicitação de passageiro
  static MatchingCriteria fromPassengerRequest(PassengerRequest request, {
    double maxRadiusKm = 10.0,
    int maxDrivers = 10,
  }) {
    // Tentar extrair informações de bairro dos endereços existentes
    final originInfo = LocationService.parseAddressString(request.originAddress);
    final destinationInfo = LocationService.parseAddressString(request.destinationAddress);
    
    print('🔍 Extraindo bairros dos endereços:');
    print('   📍 Origem: "${request.originAddress}" → Bairro: ${originInfo['neighborhood'] ?? 'N/A'}');
    print('   🎯 Destino: "${request.destinationAddress}" → Bairro: ${destinationInfo['neighborhood'] ?? 'N/A'}');
    
    return MatchingCriteria(
      passengerLatitude: request.originLat,
      passengerLongitude: request.originLng,
      destinationLatitude: request.destinationLat,
      destinationLongitude: request.destinationLng,
      maxRadiusKm: maxRadiusKm,
      maxDrivers: maxDrivers,
      // Popula campos de bairro que estavam sempre nulos
      originNeighborhood: originInfo['neighborhood'],
      originCity: originInfo['city'],
      originState: originInfo['state'],
      destinationNeighborhood: destinationInfo['neighborhood'],
      destinationCity: destinationInfo['city'], 
      destinationState: destinationInfo['state'],
    );
  }
}