// Exemplo de uso do sistema de áreas de atuação
// Execute este arquivo para testar as funcionalidades

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'lib/services/driver_operation_zones_service.dart';

void main() async {
  // Exemplo de uso das áreas de atuação
  await demonstrateOperationZones();
}

Future<void> demonstrateOperationZones() async {
  print('🚗 Demonstração do Sistema de Áreas de Atuação\n');

  // Simular um cliente Supabase (na aplicação real, use o já inicializado)
  final mockSupabaseClient = _createMockClient();
  final service = DriverOperationZonesService(mockSupabaseClient);

  // ID do motorista de exemplo
  const driverId = 'driver-123-example';

  try {
    print('1. 📍 Criando área "Centro Expandido" com multiplicador 1.5x...');
    
    // Coordenadas do centro de São Paulo (exemplo)
    final centroPolygon = [
      const LatLng(-23.5505, -46.6333), // Centro
      const LatLng(-23.5400, -46.6200), // Nordeste
      const LatLng(-23.5600, -46.6200), // Sudeste
      const LatLng(-23.5600, -46.6500), // Sudoeste
      const LatLng(-23.5400, -46.6500), // Noroeste
    ];

    final centroZone = await service.addOperationZone(
      driverId: driverId,
      zoneName: 'Centro Expandido',
      polygonCoordinates: centroPolygon,
      priceMultiplier: 1.5,
    );

    print('   ✅ Área criada: ${centroZone.zoneName}');
    print('   📊 Multiplicador: ${centroZone.formattedMultiplier}');
    print('   📏 Pontos: ${centroZone.polygonCoordinates.length}');
    print('   🗺️ Área aproximada: ${centroZone.approximateAreaKm2.toStringAsFixed(1)} km²\n');

    print('2. 📍 Criando área "Zona Sul Premium" com multiplicador 2.0x...');
    
    // Coordenadas da zona sul (exemplo)
    final zonaSulPolygon = [
      const LatLng(-23.5800, -46.6500),
      const LatLng(-23.5700, -46.6300),
      const LatLng(-23.6000, -46.6200),
      const LatLng(-23.6100, -46.6600),
    ];

    final zonaSulZone = await service.addOperationZone(
      driverId: driverId,
      zoneName: 'Zona Sul Premium',
      polygonCoordinates: zonaSulPolygon,
      priceMultiplier: 2,
    );

    print('   ✅ Área criada: ${zonaSulZone.zoneName}');
    print('   📊 Multiplicador: ${zonaSulZone.formattedMultiplier}');
    print('   💰 Descrição: ${zonaSulZone.multiplierDescription}\n');

    print('3. 📋 Listando todas as áreas do motorista...');
    final allZones = await service.getDriverOperationZones(driverId);
    
    for (var i = 0; i < allZones.length; i++) {
      final zone = allZones[i];
      print('   ${i + 1}. ${zone.zoneName}');
      print('      - Multiplicador: ${zone.formattedMultiplier}');
      print('      - Status: ${zone.isActive ? "Ativa" : "Inativa"}');
      print('      - Centro: ${zone.center.latitude.toStringAsFixed(4)}, ${zone.center.longitude.toStringAsFixed(4)}');
    }
    print('');

    print('4. 🎯 Testando detecção de pontos...');
    
    // Testar ponto dentro do centro
    const pontoTeste1 = LatLng(-23.5500, -46.6400);
    final zone1 = await service.findZoneContainingPoint(driverId, pontoTeste1);
    
    if (zone1 != null) {
      print('   📍 Ponto (-23.5500, -46.6400) está em: ${zone1.zoneName}');
      print('   💲 Multiplicador aplicado: ${zone1.formattedMultiplier}');
    } else {
      print('   📍 Ponto (-23.5500, -46.6400) não está em nenhuma área');
    }

    // Testar ponto fora das áreas
    const pontoTeste2 = LatLng(-23.7000, -46.7000);
    final zone2 = await service.findZoneContainingPoint(driverId, pontoTeste2);
    
    if (zone2 != null) {
      print('   📍 Ponto (-23.7000, -46.7000) está em: ${zone2.zoneName}');
    } else {
      print('   📍 Ponto (-23.7000, -46.7000) não está em nenhuma área (multiplicador padrão 1.0x)');
    }
    print('');

    print('5. 📊 Calculando estatísticas...');
    final stats = await service.getZoneStatistics(driverId);
    
    print('   📈 Total de áreas: ${stats['total_zones']}');
    print('   ✅ Áreas ativas: ${stats['active_zones']}');
    print('   🗺️ Área total: ${(stats['total_area_km2'] as double).toStringAsFixed(1)} km²');
    print('   📊 Multiplicador médio: ${(stats['average_multiplier'] as double).toStringAsFixed(1)}x');
    print('   ⬆️ Multiplicador máximo: ${(stats['max_multiplier'] as double).toStringAsFixed(1)}x');
    print('   ⬇️ Multiplicador mínimo: ${(stats['min_multiplier'] as double).toStringAsFixed(1)}x\n');

    print('6. ⚙️ Testando alterações...');
    
    // Desativar uma área
    print('   🔄 Desativando área "Centro Expandido"...');
    await service.toggleZoneStatus(centroZone.id, false);
    print('   ✅ Área desativada\n');

    // Atualizar multiplicador
    print('   🔄 Atualizando multiplicador da "Zona Sul Premium" para 1.8x...');
    await service.updateOperationZone(
      zoneId: zonaSulZone.id,
      priceMultiplier: 1.8,
    );
    print('   ✅ Multiplicador atualizado\n');

    print('7. 🧹 Limpando dados de teste...');
    await service.removeOperationZone(centroZone.id);
    await service.removeOperationZone(zonaSulZone.id);
    print('   ✅ Áreas de teste removidas\n');

    print('🎉 Demonstração concluída com sucesso!');
    print('\n📝 Para usar na aplicação real:');
    print('   1. Execute o SQL em supabase_migration_operation_zones.sql no seu banco');
    print('   2. Acesse o app como motorista');
    print('   3. Vá em Menu > Áreas de atuação');
    print('   4. Desenhe suas áreas no mapa');
    print('   5. Configure os multiplicadores desejados');

  } catch (e) {
    print('❌ Erro durante a demonstração: $e');
  }
}

// Mock para demonstração (na aplicação real, use o Supabase.instance.client)
SupabaseClient _createMockClient() {
  // Esta é apenas uma demonstração - na aplicação real você usaria o cliente real
  throw UnimplementedError('Esta é apenas uma demonstração. Use o Supabase.instance.client real.');
}

// Exemplo de como integrar no cálculo de preços
class PriceCalculator {
  
  PriceCalculator(this._zonesService);
  final DriverOperationZonesService _zonesService;

  Future<double> calculateTripPrice({
    required String driverId,
    required LatLng pickupLocation,
    required LatLng dropoffLocation,
    required double basePrice,
  }) async {
    try {
      // Verificar multiplicador para o local de partida
      final pickupMultiplier = await _zonesService.getPriceMultiplierForPoint(
        driverId,
        pickupLocation,
      );

      // Verificar multiplicador para o local de destino
      final dropoffMultiplier = await _zonesService.getPriceMultiplierForPoint(
        driverId,
        dropoffLocation,
      );

      // Usar o maior multiplicador (mais conservador)
      final finalMultiplier = pickupMultiplier > dropoffMultiplier 
          ? pickupMultiplier 
          : dropoffMultiplier;

      final finalPrice = basePrice * finalMultiplier;

      if (kDebugMode) {
        print('💰 Cálculo de Preço:');
        print('   Base: R\$ ${basePrice.toStringAsFixed(2)}');
        print('   Multiplicador partida: ${pickupMultiplier.toStringAsFixed(1)}x');
        print('   Multiplicador destino: ${dropoffMultiplier.toStringAsFixed(1)}x');
        print('   Multiplicador final: ${finalMultiplier.toStringAsFixed(1)}x');
        print('   Preço final: R\$ ${finalPrice.toStringAsFixed(2)}');
      }

      return finalPrice;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro no cálculo de preço: $e');
      }
      // Em caso de erro, retornar preço base
      return basePrice;
    }
  }
}