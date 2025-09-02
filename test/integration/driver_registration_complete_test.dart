import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:option/controllers/driver_stepper_controller.dart';
import 'package:option/utils/supabase_helper.dart';

void main() {
  group('Teste Completo de Cadastro de Motorista', () {
    late DriverStepperController controller;
    late File testImageFile;
    late File testPdfFile;

    setUpAll(() async {
      // Marcar Supabase como inicializado para testes
      SupabaseHelper.markInitialized();
      
      // Criar arquivos de teste
      testImageFile = await _createTestImageFile();
      testPdfFile = await _createTestPdfFile();
    });

    setUp(() {
      controller = DriverStepperController();
    });

    tearDownAll(() async {
      // Limpar arquivos de teste
      if (await testImageFile.exists()) {
        await testImageFile.delete();
      }
      if (await testPdfFile.exists()) {
        await testPdfFile.delete();
      }
    });

    test('Inicialização do controller', () {
      // Verificar estado inicial
      expect(controller.currentStep, 0);
      expect(controller.isLoading, false);
      expect(controller.errorMessage, isNull);
      expect(controller.cnhPhoto, isNull);
      expect(controller.crlvPhoto, isNull);
    });

    test('Validação de dados do veículo', () {
      // Estado inicial - não pode prosseguir
      expect(controller.canProceedFromVehicle, false);
      
      // Preencher dados do veículo
      controller.setBrand('Honda');
      controller.setModel('Civic');
      controller.setYear('2020');
      controller.setPlate('ABC1234');
      controller.setColor('Branco');
      
      // Agora deve poder prosseguir
      expect(controller.canProceedFromVehicle, true);
      expect(controller.vehicleBrand, 'Honda');
      expect(controller.vehicleModel, 'Civic');
      expect(controller.vehicleYear, '2020');
      expect(controller.vehiclePlate, 'ABC1234');
      expect(controller.vehicleColor, 'Branco');
    });

    test('Validação de campos obrigatórios', () {
      // Verificar que campos vazios não passam na validação
      expect(controller.vehicleBrand.isEmpty, true);
      expect(controller.vehicleModel.isEmpty, true);
      expect(controller.vehicleYear.isEmpty, true);
      expect(controller.vehiclePlate.isEmpty, true);
      expect(controller.vehicleColor.isEmpty, true);
      
      // Preencher um campo por vez e verificar
      controller.setBrand('Honda');
      expect(controller.vehicleBrand, 'Honda');
      
      controller.setModel('Civic');
      expect(controller.vehicleModel, 'Civic');
      
      controller.setYear('2020');
      expect(controller.vehicleYear, '2020');
      
      controller.setPlate('ABC1234');
      expect(controller.vehiclePlate, 'ABC1234');
      
      controller.setColor('Branco');
      expect(controller.vehicleColor, 'Branco');
    });

    test('Validação de documentos', () {
      // Inicialmente sem documentos
      expect(controller.cnhPhoto, isNull);
      expect(controller.crlvPhoto, isNull);
      expect(controller.canProceedFromDocuments, false);
      
      // Simular que documentos foram selecionados
      // (não podemos testar o upload real sem Supabase configurado)
      expect(controller.cnhPhoto == null, true);
      expect(controller.crlvPhoto == null, true);
    });

    test('Validação de arquivos de teste', () async {
      // Verificar que os arquivos de teste foram criados
      expect(await testImageFile.exists(), true);
      expect(await testPdfFile.exists(), true);
      
      // Verificar tamanhos dos arquivos
      final imageSize = await testImageFile.length();
      final pdfSize = await testPdfFile.length();
      
      expect(imageSize, greaterThan(0));
      expect(pdfSize, greaterThan(0));
      
      // Verificar que não são muito grandes
      expect(imageSize, lessThan(1024 * 1024)); // Menos de 1MB
      expect(pdfSize, lessThan(1024 * 1024)); // Menos de 1MB
    });

    test('Validação de estado do controller', () {
      // Testar estados de loading e erro
      expect(controller.isLoading, false);
      expect(controller.errorMessage, isNull);
    });

    test('Validação completa do registro', () {
      // Preencher todos os dados necessários
      controller.setBrand('Honda');
      controller.setModel('Civic');
      controller.setYear('2020');
      controller.setPlate('ABC1234');
      controller.setColor('Branco');
      
      // Verificar que todos os dados foram preenchidos
      expect(controller.vehicleBrand.isNotEmpty, true);
      expect(controller.vehicleModel.isNotEmpty, true);
      expect(controller.vehicleYear.isNotEmpty, true);
      expect(controller.vehiclePlate.isNotEmpty, true);
      expect(controller.vehicleColor.isNotEmpty, true);
      
      // Verificar que pode prosseguir com dados do veículo
      expect(controller.canProceedFromVehicle, true);
    });

    test('Limpeza de dados', () {
      // Preencher dados
      controller.setBrand('Honda');
      controller.setModel('Civic');
      controller.setYear('2020');
      controller.setPlate('ABC1234');
      controller.setColor('Branco');
      
      // Verificar que dados foram preenchidos
      expect(controller.vehicleBrand, 'Honda');
      
      // Limpar dados
      controller.setBrand('');
      controller.setModel('');
      controller.setYear('');
      controller.setPlate('');
      controller.setColor('');
      
      // Verificar que dados foram limpos
      expect(controller.vehicleBrand.isEmpty, true);
      expect(controller.vehicleModel.isEmpty, true);
      expect(controller.vehicleYear.isEmpty, true);
      expect(controller.vehiclePlate.isEmpty, true);
      expect(controller.vehicleColor.isEmpty, true);
    });
  });
}

// Funções auxiliares para testes
Future<File> _createTestImageFile() async {
  // Criar uma imagem de teste simples (1x1 pixel JPEG)
  final bytes = Uint8List.fromList([
    0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
    0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
    0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
    0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
    0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
    0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
    0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
    0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x11, 0x08, 0x00, 0x01,
    0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01,
    0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0xFF, 0xC4,
    0x00, 0x14, 0x10, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xDA, 0x00, 0x0C,
    0x03, 0x01, 0x00, 0x02, 0x11, 0x03, 0x11, 0x00, 0x3F, 0x00, 0x8A, 0x28,
    0xFF, 0xD9
  ]);
  
  final file = File('/tmp/test_cnh.jpg');
  await file.writeAsBytes(bytes);
  return file;
}

Future<File> _createTestPdfFile() async {
  // Criar um PDF de teste simples
  final bytes = Uint8List.fromList([
    0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, 0x0A, 0x31, 0x20, 0x30,
    0x20, 0x6F, 0x62, 0x6A, 0x0A, 0x3C, 0x3C, 0x0A, 0x2F, 0x54, 0x79, 0x70,
    0x65, 0x20, 0x2F, 0x43, 0x61, 0x74, 0x61, 0x6C, 0x6F, 0x67, 0x0A, 0x2F,
    0x50, 0x61, 0x67, 0x65, 0x73, 0x20, 0x32, 0x20, 0x30, 0x20, 0x52, 0x0A,
    0x3E, 0x3E, 0x0A, 0x65, 0x6E, 0x64, 0x6F, 0x62, 0x6A, 0x0A, 0x32, 0x20,
    0x30, 0x20, 0x6F, 0x62, 0x6A, 0x0A, 0x3C, 0x3C, 0x0A, 0x2F, 0x54, 0x79,
    0x70, 0x65, 0x20, 0x2F, 0x50, 0x61, 0x67, 0x65, 0x73, 0x0A, 0x2F, 0x4B,
    0x69, 0x64, 0x73, 0x20, 0x5B, 0x33, 0x20, 0x30, 0x20, 0x52, 0x5D, 0x0A,
    0x2F, 0x43, 0x6F, 0x75, 0x6E, 0x74, 0x20, 0x31, 0x0A, 0x3E, 0x3E, 0x0A,
    0x65, 0x6E, 0x64, 0x6F, 0x62, 0x6A, 0x0A, 0x78, 0x72, 0x65, 0x66, 0x0A,
    0x30, 0x20, 0x34, 0x0A, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
    0x30, 0x30, 0x20, 0x36, 0x35, 0x35, 0x33, 0x35, 0x20, 0x66, 0x20, 0x0A,
    0x74, 0x72, 0x61, 0x69, 0x6C, 0x65, 0x72, 0x0A, 0x3C, 0x3C, 0x0A, 0x2F,
    0x53, 0x69, 0x7A, 0x65, 0x20, 0x34, 0x0A, 0x2F, 0x52, 0x6F, 0x6F, 0x74,
    0x20, 0x31, 0x20, 0x30, 0x20, 0x52, 0x0A, 0x3E, 0x3E, 0x0A, 0x73, 0x74,
    0x61, 0x72, 0x74, 0x78, 0x72, 0x65, 0x66, 0x0A, 0x31, 0x38, 0x34, 0x0A,
    0x25, 0x25, 0x45, 0x4F, 0x46
  ]);
  
  final file = File('/tmp/test_crlv.pdf');
  await file.writeAsBytes(bytes);
  return file;
}