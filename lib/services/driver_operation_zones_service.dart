import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/supabase/driver_operation_zone.dart';

class DriverOperationZonesService {
  DriverOperationZonesService(this._supabase);

  final SupabaseClient _supabase;

  /// Busca todas as áreas de atuação de um motorista
  Future<List<DriverOperationZone>> getDriverOperationZones(String driverId) async {
    try {
      final response = await _supabase
          .from('driver_operation_zones')
          .select('*')
          .eq('driver_id', driverId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((zone) => DriverOperationZone.fromJson(zone as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar áreas de atuação: $e');
    }
  }

  /// Busca apenas as áreas ativas de um motorista
  Future<List<DriverOperationZone>> getActiveDriverOperationZones(String driverId) async {
    try {
      final response = await _supabase
          .from('driver_operation_zones')
          .select('*')
          .eq('driver_id', driverId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((zone) => DriverOperationZone.fromJson(zone as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar áreas ativas: $e');
    }
  }

  /// Adiciona uma nova área de atuação
  Future<DriverOperationZone> addOperationZone({
    required String driverId,
    required String zoneName,
    required List<LatLng> polygonCoordinates,
    required double priceMultiplier,
    bool isActive = true,
  }) async {
    if (polygonCoordinates.length < 3) {
      throw Exception('A área deve ter pelo menos 3 pontos');
    }

    if (priceMultiplier < 0.1 || priceMultiplier > 10.0) {
      throw Exception('O multiplicador deve estar entre 0.1 e 10.0');
    }

    try {
      // Verificar se já existe uma zona com o mesmo nome
      final existingZones = await _supabase
          .from('driver_operation_zones')
          .select('zone_name')
          .eq('driver_id', driverId)
          .eq('zone_name', zoneName);

      if (existingZones.isNotEmpty) {
        throw Exception('Já existe uma área com este nome');
      }

      final zoneData = {
        'driver_id': driverId,
        'zone_name': zoneName,
        'polygon_coordinates': polygonCoordinates
            .map((coord) => {
                  'lat': coord.latitude,
                  'lng': coord.longitude,
                })
            .toList(),
        'price_multiplier': priceMultiplier,
        'is_active': isActive,
      };

      final response = await _supabase
          .from('driver_operation_zones')
          .insert(zoneData)
          .select()
          .single();

      return DriverOperationZone.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      if (e.toString().contains('Já existe')) {
        rethrow;
      }
      throw Exception('Erro ao adicionar área de atuação: $e');
    }
  }

  /// Atualiza uma área de atuação existente
  Future<DriverOperationZone> updateOperationZone({
    required String zoneId,
    String? zoneName,
    List<LatLng>? polygonCoordinates,
    double? priceMultiplier,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};

    if (zoneName != null) {
      updates['zone_name'] = zoneName;
    }

    if (polygonCoordinates != null) {
      if (polygonCoordinates.length < 3) {
        throw Exception('A área deve ter pelo menos 3 pontos');
      }
      updates['polygon_coordinates'] = polygonCoordinates
          .map((coord) => {
                'lat': coord.latitude,
                'lng': coord.longitude,
              })
          .toList();
    }

    if (priceMultiplier != null) {
      if (priceMultiplier < 0.1 || priceMultiplier > 10.0) {
        throw Exception('O multiplicador deve estar entre 0.1 e 10.0');
      }
      updates['price_multiplier'] = priceMultiplier;
    }

    if (isActive != null) {
      updates['is_active'] = isActive;
    }

    if (updates.isEmpty) {
      throw Exception('Nenhuma alteração foi fornecida');
    }

    try {
      final response = await _supabase
          .from('driver_operation_zones')
          .update(updates)
          .eq('id', zoneId)
          .select()
          .single();

      return DriverOperationZone.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erro ao atualizar área de atuação: $e');
    }
  }

  /// Remove uma área de atuação
  Future<void> removeOperationZone(String zoneId) async {
    try {
      await _supabase
          .from('driver_operation_zones')
          .delete()
          .eq('id', zoneId);
    } catch (e) {
      throw Exception('Erro ao remover área de atuação: $e');
    }
  }

  /// Ativa ou desativa uma área de atuação
  Future<DriverOperationZone> toggleZoneStatus(String zoneId, bool isActive) async {
    return updateOperationZone(zoneId: zoneId, isActive: isActive);
  }

  /// Verifica se um ponto está em alguma área ativa do motorista
  Future<DriverOperationZone?> findZoneContainingPoint(
    String driverId,
    LatLng point,
  ) async {
    try {
      final zones = await getActiveDriverOperationZones(driverId);
      
      for (final zone in zones) {
        if (zone.containsPoint(point)) {
          return zone;
        }
      }
      
      return null;
    } catch (e) {
      throw Exception('Erro ao verificar áreas: $e');
    }
  }

  /// Calcula o multiplicador de preço para um ponto específico
  Future<double> getPriceMultiplierForPoint(
    String driverId,
    LatLng point,
  ) async {
    try {
      final zone = await findZoneContainingPoint(driverId, point);
      return zone?.priceMultiplier ?? 1.0;
    } catch (e) {
      throw Exception('Erro ao calcular multiplicador: $e');
    }
  }

  /// Busca áreas que se sobrepõem com uma nova área (para validação)
  Future<List<DriverOperationZone>> findOverlappingZones(
    String driverId,
    List<LatLng> newPolygon, {
    String? excludeZoneId,
  }) async {
    try {
      final zones = await getDriverOperationZones(driverId);
      final overlappingZones = <DriverOperationZone>[];

      for (final zone in zones) {
        if (excludeZoneId != null && zone.id == excludeZoneId) {
          continue;
        }

        // Verifica se algum ponto da nova área está dentro de uma zona existente
        for (final point in newPolygon) {
          if (zone.containsPoint(point)) {
            overlappingZones.add(zone);
            break;
          }
        }

        // Verifica se algum ponto da zona existente está dentro da nova área
        if (!overlappingZones.contains(zone)) {
          for (final point in zone.polygonCoordinates) {
            if (_isPointInPolygon(point, newPolygon)) {
              overlappingZones.add(zone);
              break;
            }
          }
        }
      }

      return overlappingZones;
    } catch (e) {
      throw Exception('Erro ao verificar sobreposições: $e');
    }
  }

  /// Calcula estatísticas das áreas de um motorista
  Future<Map<String, dynamic>> getZoneStatistics(String driverId) async {
    try {
      final zones = await getDriverOperationZones(driverId);
      final activeZones = zones.where((z) => z.isActive).toList();

      double totalArea = 0.0;
      double averageMultiplier = 0.0;
      double maxMultiplier = 0.0;
      double minMultiplier = double.infinity;

      for (final zone in activeZones) {
        totalArea += zone.approximateAreaKm2;
        averageMultiplier += zone.priceMultiplier;
        
        if (zone.priceMultiplier > maxMultiplier) {
          maxMultiplier = zone.priceMultiplier;
        }
        
        if (zone.priceMultiplier < minMultiplier) {
          minMultiplier = zone.priceMultiplier;
        }
      }

      if (activeZones.isNotEmpty) {
        averageMultiplier /= activeZones.length;
      } else {
        minMultiplier = 0.0;
      }

      return {
        'total_zones': zones.length,
        'active_zones': activeZones.length,
        'total_area_km2': totalArea,
        'average_multiplier': averageMultiplier,
        'max_multiplier': maxMultiplier,
        'min_multiplier': minMultiplier == double.infinity ? 0.0 : minMultiplier,
      };
    } catch (e) {
      throw Exception('Erro ao calcular estatísticas: $e');
    }
  }

  /// Helper para verificar se um ponto está dentro de um polígono
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i].latitude;
      final yi = polygon[i].longitude;
      final xj = polygon[j].latitude;
      final yj = polygon[j].longitude;

      if (((yi > point.longitude) != (yj > point.longitude)) &&
          (point.latitude < (xj - xi) * (point.longitude - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }
}