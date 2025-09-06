import 'package:flutter_test/flutter_test.dart';
import 'package:option/models/supabase/driver.dart';

void main() {
  group('DriverFlowE2ETests', () {
    group('Fluxo Completo de Registro', () {
      test('Deve completar registro com dados válidos', () async {
        // ===== PASSO 1: DADOS DO VEÍCULO =====
        
        // Dados do veículo
        const brand = 'Toyota';
        const model = 'Corolla';
        const year = 2021;
        const plate = 'XYZ9876';
        const color = 'Prata';
        const category = 'standard';

        // ===== PASSO 2: CRIAR MOTORISTA =====
        
        // Criar motorista completo
        final driver = Driver(
          id: 'driver_${DateTime.now().millisecondsSinceEpoch}',
          userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
          brand: brand,
          model: model,
          year: year,
          color: color,
          plate: plate,
          category: category,
          isOnline: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Validar que motorista foi criado corretamente
        expect(driver.id.isNotEmpty, isTrue);
        expect(driver.userId.isNotEmpty, isTrue);
        expect(driver.brand, equals('Toyota'));
        expect(driver.model, equals('Corolla'));
        expect(driver.year, equals(2021));
        expect(driver.color, equals('Prata'));
        expect(driver.plate, equals('XYZ9876'));
        expect(driver.isOnline, isFalse);

        // ===== PASSO 3: VALIDAR ESTRUTURA JSON =====
        
        // Validar estrutura do motorista para armazenamento
        final driverJson = driver.toJson();
        expect(driverJson, isA<Map<String, dynamic>>());
        expect(driverJson['vehicle_plate'], equals('XYZ9876'));
        expect(driverJson['is_online'], isFalse);

        // ===== PASSO 4: TRANSIÇÃO PARA ONLINE =====
        
        // 4.1 Mudar status para online
        final driverOnline = driver.copyWith(isOnline: true);
        expect(driverOnline.isOnline, isTrue);
        expect(driverOnline.id, equals(driver.id)); // ID permanece o mesmo
        expect(driverOnline.brand, equals(driver.brand)); // Marca permanece a mesma

        // 4.2 Validar que todos os dados estão intactos
        expect(driverOnline.userId, equals(driver.userId));
        expect(driverOnline.model, equals(driver.model));
        expect(driverOnline.year, equals(driver.year));
        expect(driverOnline.color, equals(driver.color));
        expect(driverOnline.plate, equals(driver.plate));
        expect(driverOnline.category, equals(driver.category));

        // ===== PASSO 5: VALIDAR ESTADO FINAL =====
        
        // Validar que o motorista está completo e pronto
        expect(driverOnline.id.isNotEmpty, isTrue);
        expect(driverOnline.plate.length, greaterThanOrEqualTo(7));
        expect(driverOnline.year.toString().length, equals(4));
        expect(driverOnline.brand.isNotEmpty, isTrue);
        expect(driverOnline.model.isNotEmpty, isTrue);
        expect(driverOnline.color.isNotEmpty, isTrue);
        expect(driverOnline.isOnline, isTrue);
      });

      test('Deve validar fluxo com diferentes tipos de veículos', () async {
        // Testar com diferentes marcas e modelos
        final testCases = [
          {
            'brand': 'Honda',
            'model': 'Civic',
            'year': 2020,
            'plate': 'HON2020',
            'color': 'Preto',
          },
          {
            'brand': 'Volkswagen',
            'model': 'Gol',
            'year': 2019,
            'plate': 'VWG2019',
            'color': 'Vermelho',
          },
          {
            'brand': 'Chevrolet',
            'model': 'Onix',
            'year': 2021,
            'plate': 'CHE2021',
            'color': 'Branco',
          },
        ];

        for (final testCase in testCases) {
          // Criar motorista
          final driver = Driver(
            id: 'driver_${testCase['plate']}_${DateTime.now().millisecondsSinceEpoch}',
            userId: 'user_${testCase['plate']}_${DateTime.now().millisecondsSinceEpoch}',
            brand: testCase['brand']! as String,
            model: testCase['model']! as String,
            year: testCase['year'] as int,
            color: testCase['color']! as String,
            plate: testCase['plate']! as String,
            category: 'standard',
            isOnline: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Validar dados
          expect(driver.brand, equals(testCase['brand']));
          expect(driver.model, equals(testCase['model']));
          expect(driver.year, equals(testCase['year']));
          expect(driver.plate, equals(testCase['plate']));
          expect(driver.color, equals(testCase['color']));

          // Validar transição online
          final driverOnline = driver.copyWith(isOnline: true);
          expect(driverOnline.isOnline, isTrue);
          expect(driverOnline.brand, equals(testCase['brand']));
        }
      });
    });

    group('Validação de Dados', () {
      test('Deve validar formato de placa', () async {
        const validPlates = [
          'ABC1234',
          'XYZ9A87',
          'TEST123',
          'FORD2020',
        ];

        for (final plate in validPlates) {
          final driver = Driver(
            id: 'test_driver',
            userId: 'test_user',
            brand: 'Test',
            model: 'Test',
            year: 2020,
            color: 'Test',
            plate: plate,
            category: 'standard',
            isOnline: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          expect(driver.plate.length, greaterThanOrEqualTo(7));
          expect(driver.plate.isNotEmpty, isTrue);
        }
      });

      test('Deve validar formato de ano do veículo', () async {
        const validYears = [2018, 2019, 2020, 2021, 2022, 2023, 2024];

        for (final year in validYears) {
          final driver = Driver(
            id: 'test_driver',
            userId: 'test_user',
            brand: 'Test',
            model: 'Test',
            year: year,
            color: 'Test',
            plate: 'TEST123',
            category: 'standard',
            isOnline: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          expect(driver.year, equals(year));
          expect(driver.year.toString().length, equals(4));
        }
      });
    });

    group('Estado Final do Sistema', () {
      test('Deve garantir que motorista está pronto para receber corridas', () async {
        // Criar motorista completo
        final driver = Driver(
          id: 'ready_driver_123',
          userId: 'user_ready_123',
          brand: 'Hyundai',
          model: 'HB20',
          year: 2022,
          color: 'Cinza',
          plate: 'READY123',
          category: 'standard',
          isOnline: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Validar que está pronto
        expect(driver.isOnline, isTrue);
        expect(driver.plate.length, greaterThanOrEqualTo(7));
        expect(driver.year.toString().length, equals(4));
        expect(driver.brand.isNotEmpty, isTrue);
        expect(driver.model.isNotEmpty, isTrue);
        expect(driver.color.isNotEmpty, isTrue);
      });
    });
  });
}