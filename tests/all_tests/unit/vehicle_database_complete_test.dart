import 'package:flutter_test/flutter_test.dart';
import 'package:option/services/vehicle_data_service.dart';

void main() {
  group('Teste Completo da Base de Dados de Veículos', () {
    late VehicleDataService service;

    setUp(() {
      service = VehicleDataService();
    });

    test('Deve ter pelo menos 50 marcas disponíveis', () async {
      final brands = await service.searchBrands('');
      expect(brands.length, greaterThanOrEqualTo(50));
      
      print('✅ Total de marcas disponíveis: ${brands.length}');
    });

    test('Deve incluir TOP 10 marcas mais vendidas no Brasil', () async {
      final brands = await service.searchBrands('');
      final brandNames = brands.map((b) => b.name.toLowerCase()).join(' ');
      
      // TOP 10 marcas mais vendidas no Brasil 2024
      final topBrands = [
        'volkswagen', 'fiat', 'chevrolet', 'hyundai', 
        'toyota', 'jeep', 'ford', 'honda', 'nissan', 'renault'
      ];
      
      for (final brand in topBrands) {
        expect(brandNames.contains(brand), isTrue, 
               reason: 'Marca $brand deveria estar na lista');
      }
      
      print('✅ TOP 10 marcas mais vendidas incluídas');
    });

    test('Deve incluir marcas chinesas em crescimento', () async {
      final brands = await service.searchBrands('');
      final brandNames = brands.map((b) => b.name.toLowerCase()).join(' ');
      
      final chineseBrands = ['byd', 'chery', 'gwm', 'jac', 'geely'];
      
      for (final brand in chineseBrands) {
        expect(brandNames.contains(brand), isTrue,
               reason: 'Marca chinesa $brand deveria estar na lista');
      }
      
      print('✅ Marcas chinesas em crescimento incluídas');
    });

    test('Deve incluir marcas premium', () async {
      final brands = await service.searchBrands('');
      final brandNames = brands.map((b) => b.name.toLowerCase()).join(' ');
      
      final premiumBrands = ['bmw', 'mercedes', 'audi', 'porsche', 'land rover'];
      
      for (final brand in premiumBrands) {
        expect(brandNames.contains(brand), isTrue,
               reason: 'Marca premium $brand deveria estar na lista');
      }
      
      print('✅ Marcas premium incluídas');
    });

    test('Deve ter modelos baseados no ranking de vendas 2024', () async {
      // Testar TOP 5 modelos mais vendidos
      
      // #1 - Fiat Strada
      final fiatModels = await service.getModels(21);
      final fiatNames = fiatModels.map((m) => m.name.toLowerCase()).join(' ');
      expect(fiatNames.contains('strada'), isTrue);
      
      // #2 - VW Polo  
      final vwModels = await service.getModels(59);
      final vwNames = vwModels.map((m) => m.name.toLowerCase()).join(' ');
      expect(vwNames.contains('polo'), isTrue);
      
      // #3 - Chevrolet Onix
      final chevyModels = await service.getModels(23);
      final chevyNames = chevyModels.map((m) => m.name.toLowerCase()).join(' ');
      expect(chevyNames.contains('onix'), isTrue);
      
      // #4 - Hyundai HB20
      final hyundaiModels = await service.getModels(26);
      final hyundaiNames = hyundaiModels.map((m) => m.name.toLowerCase()).join(' ');
      expect(hyundaiNames.contains('hb20'), isTrue);
      
      // #5 - Fiat Argo
      expect(fiatNames.contains('argo'), isTrue);
      
      print('✅ TOP 5 modelos mais vendidos 2024 incluídos');
    });

    test('Deve ter pelo menos 100 modelos únicos no total', () async {
      final brands = await service.searchBrands('');
      var totalModels = 0;
      final uniqueModels = <String>{};
      
      for (final brand in brands) {
        final models = await service.getModels(brand.id);
        for (final model in models) {
          uniqueModels.add('${brand.name}:${model.name}');
        }
        totalModels += models.length;
      }
      
      expect(uniqueModels.length, greaterThanOrEqualTo(100));
      print('✅ Total de modelos únicos: ${uniqueModels.length}');
      print('✅ Total de modelos (com variações): $totalModels');
    });

    test('Deve incluir SUVs populares do Brasil', () async {
      final suvs = <String>[];
      final brands = await service.searchBrands('');
      
      for (final brand in brands.take(15)) { // Top 15 marcas
        final models = await service.getModels(brand.id);
        for (final model in models) {
          final modelName = model.name.toLowerCase();
          if (modelName.contains('t-cross') || modelName.contains('tracker') || 
              modelName.contains('creta') || modelName.contains('hr-v') || 
              modelName.contains('kicks') || modelName.contains('renegade') ||
              modelName.contains('compass') || modelName.contains('corolla cross')) {
            suvs.add('${brand.name} ${model.name}');
          }
        }
      }
      
      expect(suvs.length, greaterThan(5));
      print('✅ SUVs populares encontrados: ${suvs.length}');
      for (final suv in suvs.take(10)) {
        print('  - $suv');
      }
    });

    test('Deve incluir picapes populares do Brasil', () async {
      final pickups = <String>[];
      final brands = await service.searchBrands('');
      
      for (final brand in brands.take(15)) { // Top 15 marcas
        final models = await service.getModels(brand.id);
        for (final model in models) {
          final modelName = model.name.toLowerCase();
          if (modelName.contains('strada') || modelName.contains('toro') || 
              modelName.contains('hilux') || modelName.contains('ranger') || 
              modelName.contains('amarok') || modelName.contains('s10') ||
              modelName.contains('frontier') || modelName.contains('l200')) {
            pickups.add('${brand.name} ${model.name}');
          }
        }
      }
      
      expect(pickups.length, greaterThan(5));
      print('✅ Picapes populares encontradas: ${pickups.length}');
      for (final pickup in pickups.take(8)) {
        print('  - $pickup');
      }
    });

    test('Deve incluir carros elétricos e híbridos', () async {
      final electricCars = <String>[];
      final brands = await service.searchBrands('');
      
      for (final brand in brands) {
        final models = await service.getModels(brand.id);
        for (final model in models) {
          final modelName = model.name.toLowerCase();
          final brandName = brand.name.toLowerCase();
          
          if (brandName.contains('byd') || brandName.contains('tesla') ||
              modelName.contains('prius') || modelName.contains('model') ||
              modelName.contains('e-js') || modelName.contains('dolphin') ||
              modelName.contains('song') || modelName.contains('yuan')) {
            electricCars.add('${brand.name} ${model.name}');
          }
        }
      }
      
      expect(electricCars.length, greaterThan(10));
      print('✅ Carros elétricos/híbridos encontrados: ${electricCars.length}');
      for (final car in electricCars.take(10)) {
        print('  - $car');
      }
    });

    test('Busca deve funcionar corretamente para diferentes marcas', () async {
      // Teste busca de marcas populares
      final testQueries = ['fiat', 'volkswagen', 'toyota', 'hyundai', 'byd'];
      
      for (final query in testQueries) {
        final results = await service.searchBrands(query);
        expect(results.isNotEmpty, isTrue, 
               reason: 'Busca por "$query" deveria retornar resultados');
        
        final hasMatch = results.any((brand) => 
          brand.name.toLowerCase().contains(query.toLowerCase()));
        expect(hasMatch, isTrue,
               reason: 'Busca por "$query" deveria encontrar marca correspondente');
      }
      
      print('✅ Busca de marcas funcionando corretamente');
    });

    test('Estatísticas finais da base de dados', () async {
      final brands = await service.searchBrands('');
      var totalModels = 0;
      var brandsWithModels = 0;
      
      final categories = {
        'Nacionais/Principais': 0,
        'Chinesas': 0, 
        'Premium': 0,
        'Outras': 0,
      };
      
      for (final brand in brands) {
        final models = await service.getModels(brand.id);
        totalModels += models.length;
        
        if (models.isNotEmpty) {
          brandsWithModels++;
          
          final name = brand.name.toLowerCase();
          if (name.contains('byd') || name.contains('chery') || 
              name.contains('gwm') || name.contains('jac')) {
            categories['Chinesas'] = categories['Chinesas']! + 1;
          } else if (name.contains('bmw') || name.contains('mercedes') || 
                     name.contains('audi') || name.contains('porsche')) {
            categories['Premium'] = categories['Premium']! + 1;
          } else if (name.contains('fiat') || name.contains('volkswagen') || 
                     name.contains('chevrolet') || name.contains('toyota')) {
            categories['Nacionais/Principais'] = categories['Nacionais/Principais']! + 1;
          } else {
            categories['Outras'] = categories['Outras']! + 1;
          }
        }
      }
      
      print('\n🎯 ESTATÍSTICAS FINAIS DA BASE DE DADOS:');
      print('📊 Total de marcas: ${brands.length}');
      print('📊 Marcas com modelos: $brandsWithModels');
      print('📊 Total de modelos: $totalModels');
      print('📊 Média de modelos por marca: ${(totalModels / brandsWithModels).toStringAsFixed(1)}');
      print('\n📈 DISTRIBUIÇÃO POR CATEGORIA:');
      categories.forEach((category, count) {
        print('  $category: $count marcas');
      });
      
      expect(brands.length, greaterThanOrEqualTo(50));
      expect(totalModels, greaterThanOrEqualTo(100));
    });
  });
}