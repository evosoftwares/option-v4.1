import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/exceptions/app_exceptions.dart';
import '../../data/models/supabase/driver.dart';
import '../../data/models/supabase/passenger_request.dart';
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
    print('🎯 [DRIVER_MATCHING] [${DateTime.now()}] Iniciando matching com critérios:');
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
      print('🔍 [DRIVER_MATCHING] [${DateTime.now()}] Etapa 1: Buscando motoristas disponíveis na região...');
      final startTime = DateTime.now();
      final availableDrivers = await _getAvailableDriversInRegion(criteria);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      print('✅ [DRIVER_MATCHING] [${DateTime.now()}] Etapa 1 concluída em ${duration.inMilliseconds}ms - ${availableDrivers.length} motoristas encontrados na região');

      if (availableDrivers.isEmpty) {
        print('❌ [DRIVER_MATCHING] [${DateTime.now()}] Nenhum motorista disponível na região');
        return [];
      }

      // 2. Aplicar filtros de preferências
      print('🔍 [DRIVER_MATCHING] [${DateTime.now()}] Etapa 2: Aplicando filtros de preferências...');
      final filterStartTime = DateTime.now();
      final filteredByPreferences = await _filterByPreferences(availableDrivers, criteria);
      final filterEndTime = DateTime.now();
      final filterDuration = filterEndTime.difference(filterStartTime);
      print('✅ [DRIVER_MATCHING] [${DateTime.now()}] Etapa 2 concluída em ${filterDuration.inMilliseconds}ms - ${filteredByPreferences.length} motoristas após filtro de preferências');

      if (filteredByPreferences.isEmpty) {
        print('❌ [DRIVER_MATCHING] [${DateTime.now()}] Nenhum motorista atende às preferências');
        return [];
      }

      // 3. Filtrar por zonas de exclusão
      print('🔍 [DRIVER_MATCHING] [${DateTime.now()}] Etapa 3: Filtrando por zonas de exclusão...');
      final zoneFilterStartTime = DateTime.now();
      final filteredByZones = await _filterByExclusionZones(filteredByPreferences, criteria);
      final zoneFilterEndTime = DateTime.now();
      final zoneFilterDuration = zoneFilterEndTime.difference(zoneFilterStartTime);
      print('✅ [DRIVER_MATCHING] [${DateTime.now()}] Etapa 3 concluída em ${zoneFilterDuration.inMilliseconds}ms - ${filteredByZones.length} motoristas após filtro de zonas de exclusão');

      if (filteredByZones.isEmpty) {
        print('❌ [DRIVER_MATCHING] [${DateTime.now()}] Nenhum motorista disponível após filtro de zonas');
        return [];
      }

      // 4. Verificar disponibilidade em tempo real
      print('🔍 [DRIVER_MATCHING] [${DateTime.now()}] Etapa 4: Verificando disponibilidade em tempo real...');
      final availabilityStartTime = DateTime.now();
      final realTimeAvailable = await _verifyRealTimeAvailability(filteredByZones);
      final availabilityEndTime = DateTime.now();
      final availabilityDuration = availabilityEndTime.difference(availabilityStartTime);
      print('✅ [DRIVER_MATCHING] [${DateTime.now()}] Etapa 4 concluída em ${availabilityDuration.inMilliseconds}ms - ${realTimeAvailable.length} motoristas disponíveis em tempo real');

      // 5. Calcular scores e ordenar
      print('🔍 [DRIVER_MATCHING] [${DateTime.now()}] Etapa 5: Calculando scores e ordenando...');
      final scoreStartTime = DateTime.now();
      final matchResults = await _calculateMatchScores(realTimeAvailable, criteria);
      final scoreEndTime = DateTime.now();
      final scoreDuration = scoreEndTime.difference(scoreStartTime);
      print('✅ [DRIVER_MATCHING] [${DateTime.now()}] Etapa 5 concluída em ${scoreDuration.inMilliseconds}ms - Scores calculados para ${matchResults.length} motoristas');

      // 6. Ordenar por score e limitar resultado
      print('🔍 [DRIVER_MATCHING] [${DateTime.now()}] Etapa 6: Ordenando por score e limitando resultado...');
      final sortStartTime = DateTime.now();
      matchResults.sort((a, b) => b.matchScore.compareTo(a.matchScore));
      final finalResults = matchResults.take(criteria.maxDrivers).toList();
      final sortEndTime = DateTime.now();
      final sortDuration = sortEndTime.difference(sortStartTime);
      print('✅ [DRIVER_MATCHING] [${DateTime.now()}] Etapa 6 concluída em ${sortDuration.inMilliseconds}ms');

      print('🎉 [DRIVER_MATCHING] [${DateTime.now()}] Matching finalizado com ${finalResults.length} motoristas');
      if (finalResults.isNotEmpty) {
        print('📊 [DRIVER_MATCHING] Top 3 scores: ${finalResults.take(3).map((r) => r.matchScore.toStringAsFixed(1)).join(", ")}');
        for (int i = 0; i < finalResults.length && i < 3; i++) {
          final result = finalResults[i];
          print('   ${i+1}. Motorista ${result.driver.id}: ${result.matchScore.toStringAsFixed(1)} pontos, ${result.distanceKm.toStringAsFixed(2)}km, ${result.estimatedArrivalMinutes}min');
        }
      }

      return finalResults;
    } catch (e, stackTrace) {
      print('❌ [DRIVER_MATCHING] [${DateTime.now()}] Erro no matching: $e');
      print('📍 [DRIVER_MATCHING] Stack trace: $stackTrace');
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
  Future<List<Driver>> _filterByPreferences(List<Driver> drivers, MatchingCriteria criteria) async {
    print('🔍 [DRIVER_MATCHING] [${DateTime.now()}] Filtrando ${drivers.length} motoristas por preferências...');
    print('  🐕 Pet necessário: ${criteria.needsPet}');
    print('  ❄️ AC necessário: ${criteria.needsAC}');
    print('  🛒 Mercado necessário: ${criteria.needsGrocery}');
    print('  🏢 Condomínio necessário: ${criteria.needsCondo}');
    
    final filteredDrivers = drivers.where((driver) {
      // Filtro de Pet
      if (criteria.needsPet && !(driver.acceptsPet ?? false)) {
        print('  🚫 [DRIVER_MATCHING] Motorista ${driver.id} rejeitado - não aceita pet');
        return false;
      }

      // Filtro de Mercado/Grocery
      if (criteria.needsGrocery && !(driver.acceptsGrocery ?? false)) {
        print('  🚫 [DRIVER_MATCHING] Motorista ${driver.id} rejeitado - não aceita mercado');
        return false;
      }

      // Filtro de Condomínio
      if (criteria.needsCondo && !(driver.acceptsCondo ?? false)) {
        print('  🚫 [DRIVER_MATCHING] Motorista ${driver.id} rejeitado - não aceita condomínio');
        return false;
      }

      // Filtro de Ar Condicionado
      if (criteria.needsAC) {
        final acPolicy = driver.acPolicy?.toLowerCase();
        if (acPolicy == null || acPolicy == 'never' || acPolicy == 'nunca') {
          print('  🚫 [DRIVER_MATCHING] Motorista ${driver.id} rejeitado - não tem AC (${driver.acPolicy})');
          return false;
        }
      }

      print('  ✅ [DRIVER_MATCHING] Motorista ${driver.id} aprovado em todos os filtros');
      return true;
    }).toList();
    
    print('✅ [DRIVER_MATCHING] [${DateTime.now()}] ${filteredDrivers.length} motoristas passaram no filtro de preferências');
    return filteredDrivers;
  }

  /// Filtra motoristas baseado nas zonas excluídas (sistema otimizado)
  /// Verifica origem e destino em uma única chamada SQL
  Future<List<Driver>> _filterByExclusionZones(
    List<Driver> drivers,
    MatchingCriteria criteria,
  ) async {
    try {
      final driverIds = drivers.map((d) => d.id).toList();
      
      // Se não há motoristas, retorna lista vazia
      if (driverIds.isEmpty) {
        return drivers;
      }

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

      // Usar função SQL otimizada que verifica origem e destino em uma única chamada
      final excludedDriverIds = await _getExcludedDriversForTripOptimized(
        driverIds,
        originAddress,
        destinationAddress,
      );

      // Filtrar motoristas que não excluíram nem origem nem destino
      final filteredDrivers = drivers
          .where((driver) => !excludedDriverIds.contains(driver.id))
          .toList();

      print('✅ ${filteredDrivers.length}/${drivers.length} motoristas após filtro otimizado de zonas excluídas');
      return filteredDrivers;
    } catch (e) {
      // Em caso de erro, usa fallback para sistema legado
      print('⚠️ Erro no filtro otimizado, usando fallback: $e');
      return await _filterByExclusionZonesLegacy(drivers, criteria);
    }
  }

  /// Busca motoristas que excluíram origem e/ou destino (função SQL otimizada)
  Future<Set<String>> _getExcludedDriversForTripOptimized(
    List<String> driverIds,
    String originAddress,
    String destinationAddress,
  ) async {
    try {
      // Usar a nova função SQL otimizada que verifica origem e destino em uma única chamada
      final response = await _supabase
          .rpc('get_excluded_drivers_for_trip', params: {
            'origin_address': originAddress.isNotEmpty ? originAddress : null,
            'destination_address': destinationAddress.isNotEmpty ? destinationAddress : null,
            'driver_ids': driverIds,
          });

      final excludedDrivers = (response as List<dynamic>)
          .map((row) => row['driver_id'] as String)
          .toSet();

      // Log detalhado para debugging
      if (excludedDrivers.isNotEmpty) {
        final exclusionDetails = (response)
            .map((row) => '${row['driver_id']}: ${row['exclusion_type']} - ${row['exclusion_reason']}')
            .join(', ');
        print('🚫 ${excludedDrivers.length} motoristas excluídos: $exclusionDetails');
      }

      return excludedDrivers;
    } catch (e) {
      print('❌ Erro na função SQL otimizada: $e');
      // Fallback para função individual se a otimizada falhar
      return await _getExcludedDriversForAddressLegacy(driverIds, originAddress, destinationAddress);
    }
  }

  /// Busca motoristas que excluíram um endereço específico (função SQL otimizada individual)
  Future<Set<String>> _getExcludedDriversForAddress(
    List<String> driverIds,
    String fullAddress,
  ) async {
    try {
      // Usar a função SQL otimizada que aceita lista de driver_ids
      final response = await _supabase
          .rpc('get_excluded_drivers_for_address_optimized', params: {
            'full_address': fullAddress,
            'driver_ids': driverIds,
          });

      final excludedDrivers = (response as List<dynamic>)
          .map((row) => row['driver_id'] as String)
          .toSet();

      return excludedDrivers;
    } catch (e) {
      print('❌ Erro ao buscar motoristas excluídos para endereço "$fullAddress": $e');
      // Fallback para sistema legado se a função RPC falhar
      return await _getExcludedZonesForDriversLegacy(driverIds, fullAddress);
    }
  }

  /// Fallback para sistema legado usando chamadas individuais
  Future<Set<String>> _getExcludedDriversForAddressLegacy(
    List<String> driverIds,
    String originAddress,
    String destinationAddress,
  ) async {
    final excludedDriverIds = <String>{};
    
    try {
      // Verificar origem se disponível
      if (originAddress.isNotEmpty) {
        final originExcluded = await _getExcludedZonesForDriversLegacy(driverIds, originAddress);
        excludedDriverIds.addAll(originExcluded);
      }
      
      // Verificar destino se disponível
      if (destinationAddress.isNotEmpty) {
        final destinationExcluded = await _getExcludedZonesForDriversLegacy(driverIds, destinationAddress);
        excludedDriverIds.addAll(destinationExcluded);
      }
      
      return excludedDriverIds;
    } catch (e) {
      print('❌ Erro no fallback legado: $e');
      return <String>{};
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

  /// Fallback completo para sistema legado
  Future<List<Driver>> _filterByExclusionZonesLegacy(
    List<Driver> drivers,
    MatchingCriteria criteria,
  ) async {
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

      print('✅ ${filteredDrivers.length}/${drivers.length} motoristas após filtro legado de zonas excluídas');
      return filteredDrivers;
    } catch (e) {
      // Em caso de erro, retorna todos os motoristas para não impactar a funcionalidade
      print('⚠️ Erro ao verificar zonas excluídas no fallback: $e');
      return drivers;
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
    print('🔍 [DRIVER_MATCHING] [${DateTime.now()}] Verificando disponibilidade em tempo real de ${drivers.length} motoristas...');
    final availableDrivers = <Driver>[];
    int activeTripsCount = 0;
    int offlineCount = 0;
    int errorCount = 0;

    for (int i = 0; i < drivers.length; i++) {
      final driver = drivers[i];
      print('  🔍 [DRIVER_MATCHING] Verificando motorista ${i+1}/${drivers.length}: ${driver.id}');
      
      try {
        // Verificar se o motorista não está em viagem ativa
        final activeTrips = await _driverService.getDriverActiveTrips(driver.id);
        print('    🚗 [DRIVER_MATCHING] Viagens ativas para ${driver.id}: ${activeTrips.length}');
        
        if (activeTrips.isEmpty) {
          // Verificar se ainda está online (pode ter ficado offline recentemente)
          final currentDriver = await _driverService.getDriver(driver.id);
          print('    🟢 [DRIVER_MATCHING] Status online para ${driver.id}: ${currentDriver?.isOnline ?? false}');
          
          if (currentDriver?.isOnline ?? false) {
            availableDrivers.add(driver);
            print('    ✅ [DRIVER_MATCHING] Motorista ${driver.id} disponível');
          } else {
            offlineCount++;
            print('    ⚫ [DRIVER_MATCHING] Motorista ${driver.id} offline');
          }
        } else {
          activeTripsCount++;
          print('    🚫 [DRIVER_MATCHING] Motorista ${driver.id} em viagem ativa');
        }
      } catch (e) {
        // Em caso de erro, assume que está disponível para não impactar a funcionalidade
        print('⚠️ [DRIVER_MATCHING] Erro ao verificar disponibilidade do motorista ${driver.id}: $e');
        errorCount++;
        availableDrivers.add(driver); // Assume disponível em caso de erro
        print('    ✅ [DRIVER_MATCHING] Motorista ${driver.id} assumido como disponível (erro)');
      }
    }

    print('✅ [DRIVER_MATCHING] [${DateTime.now()}] Verificação concluída:');
    print('  - Disponíveis: ${availableDrivers.length}');
    print('  - Em viagem: $activeTripsCount');
    print('  - Offline: $offlineCount');
    print('  - Erros: $errorCount');
    
    return availableDrivers;
  }

  /// Calcula scores de matching para cada motorista
  Future<List<DriverMatchResult>> _calculateMatchScores(List<Driver> drivers, MatchingCriteria criteria) async {
    print('🔍 [DRIVER_MATCHING] [${DateTime.now()}] Calculando scores de matching para ${drivers.length} motoristas...');
    final results = <DriverMatchResult>[];

    for (int i = 0; i < drivers.length; i++) {
      final driver = drivers[i];
      print('  📊 [DRIVER_MATCHING] Calculando score para motorista ${i+1}/${drivers.length}: ${driver.id}');
      
      if (driver.currentLatitude == null || driver.currentLongitude == null) {
        print('    ⚠️ [DRIVER_MATCHING] Motorista ${driver.id} sem localização, pulando...');
        continue; // Pula motoristas sem localização
      }

      // Calcular distância
      print('    📍 [DRIVER_MATCHING] Calculando distância...');
      final distance = _calculateHaversineDistance(
        criteria.passengerLatitude,
        criteria.passengerLongitude,
        driver.currentLatitude!,
        driver.currentLongitude!,
      );
      print('    📏 [DRIVER_MATCHING] Distância: ${distance.toStringAsFixed(2)}km');

      // Calcular ETA estimado (baseado em 30km/h médio no trânsito urbano)
      print('    ⏱️ [DRIVER_MATCHING] Calculando ETA...');
      final etaMinutes = (distance * 2).round(); // 30km/h = 0.5km/min
      print('    ⏱️ [DRIVER_MATCHING] ETA estimado: ${etaMinutes}min');

      // Calcular score de matching
      print('    🎯 [DRIVER_MATCHING] Calculando score de matching...');
      final score = _calculateMatchScore(driver, distance, criteria);
      print('    🎯 [DRIVER_MATCHING] Score final: ${score.toStringAsFixed(1)}');

      final result = DriverMatchResult(
        driver: driver,
        distanceKm: distance,
        estimatedArrivalMinutes: etaMinutes,
        matchScore: score,
        isAvailable: true,
      );
      
      results.add(result);
      print('    ✅ [DRIVER_MATCHING] Resultado adicionado para motorista ${driver.id}');
    }

    print('✅ [DRIVER_MATCHING] [${DateTime.now()}] Scores calculados para ${results.length} motoristas');
    return results;
  }

  /// Calcula score de matching baseado em múltiplos critérios
  double _calculateMatchScore(Driver driver, double distance, MatchingCriteria criteria) {
    print('    🎯 [DRIVER_MATCHING] Calculando score detalhado para motorista ${driver.id}:');
    var score = 0.0;

    // 1. Score de distância (40% do peso total) - mais próximo = melhor
    if (criteria.prioritizeDistance) {
      final maxDistance = criteria.maxRadiusKm;
      final distanceScore = ((maxDistance - distance) / maxDistance) * 40;
      final finalDistanceScore = math.max(0.0, distanceScore);
      score += finalDistanceScore;
      print('      📍 Distância (${distance.toStringAsFixed(2)}km): ${finalDistanceScore.toStringAsFixed(1)}pts');
    }

    // 2. Score de rating (30% do peso total)
    if (criteria.prioritizeRating && driver.ratings > 0) {
      final ratingScore = (driver.ratings / 5.0) * 30;
      score += ratingScore;
      print('      ⭐ Rating (${driver.ratings.toStringAsFixed(1)}): ${ratingScore.toStringAsFixed(1)}pts');
    } else {
      // Motoristas sem rating recebem score neutro
      score += 15.0;
      print('      ⭐ Rating (N/A): 15.0pts (neutro)');
    }

    // 3. Score de experiência (20% do peso total)
    final totalTrips = driver.trips;
    final experienceScore = math.min(totalTrips / 100.0, 1) * 20; // Max 100 viagens para score máximo
    score += experienceScore;
    print('      🏆 Experiência ($totalTrips viagens): ${experienceScore.toStringAsFixed(1)}pts');

    // 4. Score de confiabilidade (10% do peso total)
    final cancellations = driver.cancellations;
    final reliabilityScore = math.max(0, (5 - cancellations) / 5.0) * 10;
    score += reliabilityScore;
    print('      🔒 Confiabilidade ($cancellations cancelamentos): ${reliabilityScore.toStringAsFixed(1)}pts');

    // Bônus por preferências atendidas
    double bonusScore = 0.0;
    if (criteria.needsPet && (driver.acceptsPet ?? false)) {
      bonusScore += 2.0;
      print('      🐕 Bônus pet: +2.0pts');
    }
    if (criteria.needsGrocery && (driver.acceptsGrocery ?? false)) {
      bonusScore += 2.0;
      print('      🛒 Bônus mercado: +2.0pts');
    }
    if (criteria.needsCondo && (driver.acceptsCondo ?? false)) {
      bonusScore += 2.0;
      print('      🏢 Bônus condomínio: +2.0pts');
    }
    if (criteria.needsAC && driver.acPolicy != null && 
        !['never', 'nunca'].contains(driver.acPolicy!.toLowerCase())) {
      bonusScore += 2.0;
      print('      ❄️ Bônus AC (${driver.acPolicy}): +2.0pts');
    }
    
    score += bonusScore;
    final finalScore = math.min(100.0, score); // Score máximo de 100
    print('      🎯 Score total: ${finalScore.toStringAsFixed(1)}pts (limite máximo: 100pts)');
    
    return finalScore.toDouble();
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