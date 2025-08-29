import 'package:flutter_test/flutter_test.dart';
import 'package:option/services/driver_excluded_zones_service.dart';

import '../helpers/supabase_test_helper.dart';

/// Teste de debug para reproduzir o problema das zonas excluídas
void main() {
  group('Debug Excluded Zones', () {
    late DriverExcludedZonesService service;
    late String testDriverId;

    setUpAll(() async {
       print('🔍 Iniciando debug das zonas excluídas...');
       
       try {
          await SupabaseTestHelper.initialize();
          service = DriverExcludedZonesService(SupabaseTestHelper.client);
         
         // Criar um driver de teste ao invés de buscar um existente
         final seededDriver = await SupabaseTestHelper.seedDriver();
         testDriverId = seededDriver.driverId;
         print('✅ Driver criado para teste: $testDriverId');
       } catch (e) {
         print('❌ Erro na inicialização: $e');
         rethrow;
       }
     });

    setUp(() async {
      // Limpar zonas de teste antes de cada teste
      try {
        await service.removeAllExcludedZones(testDriverId);
        print('🧹 Limpeza concluída para driver: $testDriverId');
      } catch (e) {
        print('⚠️ Erro na limpeza (pode ser normal se não há dados): $e');
      }
    });

    test('Reproduzir problema: zona não aparece após salvar', () async {
      print('\n🚀 === INICIANDO TESTE DE REPRODUÇÃO ===');
      
      const testZone = {
        'neighborhood': 'Centro',
        'city': 'São Paulo',
        'state': 'SP',
      };
      
      // ETAPA 1: Verificar estado inicial
      print('\n📋 ETAPA 1: Verificando estado inicial...');
      final initialZones = await service.getDriverExcludedZones(testDriverId);
      print('   Zonas iniciais: ${initialZones.length}');
      expect(initialZones, isEmpty, reason: 'Deve começar sem zonas');
      
      // ETAPA 2: Adicionar zona
      print('\n➕ ETAPA 2: Adicionando zona...');
      print('   Zona: ${testZone['neighborhood']}, ${testZone['city']}, ${testZone['state']}');
      
      final addedZone = await service.addExcludedZone(
        driverId: testDriverId,
        neighborhoodName: testZone['neighborhood']!,
        city: testZone['city']!,
        state: testZone['state']!,
      );
      
      print('   ✅ Zona adicionada com ID: ${addedZone.id}');
      expect(addedZone.id, isNotNull);
      expect(addedZone.neighborhoodName, equals(testZone['neighborhood']));
      
      // ETAPA 3: Verificar imediatamente (simula UI)
      print('\n🔍 ETAPA 3: Verificando imediatamente após adicionar...');
      final zonesImmediate = await service.getDriverExcludedZones(testDriverId);
      print('   Zonas encontradas: ${zonesImmediate.length}');
      
      if (zonesImmediate.isEmpty) {
        print('   ❌ PROBLEMA REPRODUZIDO: Zona não aparece imediatamente!');
      } else {
        print('   ✅ Zona aparece imediatamente: ${zonesImmediate.first.neighborhoodName}');
      }
      
      // ETAPA 4: Aguardar e verificar novamente (simula delay da UI)
      print('\n⏱️ ETAPA 4: Aguardando 500ms e verificando novamente...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      final zonesAfterDelay = await service.getDriverExcludedZones(testDriverId);
      print('   Zonas após delay: ${zonesAfterDelay.length}');
      
      if (zonesAfterDelay.isEmpty) {
        print('   ❌ PROBLEMA PERSISTE: Zona não aparece mesmo após delay!');
      } else {
        print('   ✅ Zona aparece após delay: ${zonesAfterDelay.first.neighborhoodName}');
      }
      
      // ETAPA 5: Verificar com isZoneExcluded
      print('\n🔎 ETAPA 5: Verificando com isZoneExcluded...');
      final isExcluded = await service.isZoneExcluded(
        driverId: testDriverId,
        neighborhoodName: testZone['neighborhood']!,
        city: testZone['city']!,
        state: testZone['state']!,
      );
      
      print('   isZoneExcluded retorna: $isExcluded');
      
      // ETAPA 6: Múltiplas consultas consecutivas
      print('\n🔄 ETAPA 6: Testando múltiplas consultas consecutivas...');
      for (var i = 1; i <= 3; i++) {
        final zones = await service.getDriverExcludedZones(testDriverId);
        print('   Consulta $i: ${zones.length} zonas');
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // ETAPA 7: Consulta final para assertiva
      print('\n✅ ETAPA 7: Consulta final...');
      final finalZones = await service.getDriverExcludedZones(testDriverId);
      print('   Zonas finais: ${finalZones.length}');
      
      // RESULTADO
      print('\n📊 === RESULTADO DO TESTE ===');
      if (finalZones.isNotEmpty) {
        print('✅ SUCESSO: Zona foi encontrada na consulta final');
        print('   Detalhes: ${finalZones.first.neighborhoodName}, ${finalZones.first.city}');
        expect(finalZones, hasLength(1));
        expect(finalZones.first.neighborhoodName, equals(testZone['neighborhood']));
      } else {
        print('❌ FALHA: Zona não foi encontrada mesmo na consulta final');
        print('   Isso confirma o problema relatado pelo usuário!');
        fail('Zona não aparece mesmo após ser salva - problema reproduzido!');
      }
    });
    
    tearDown(() async {
      // Limpar após cada teste
      try {
        await service.removeAllExcludedZones(testDriverId);
        print('🧹 Limpeza final concluída');
      } catch (e) {
        print('⚠️ Erro na limpeza final: $e');
      }
    });
  });
}