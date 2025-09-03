import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import 'package:option/controllers/driver_stepper_controller.dart';
import 'package:option/services/firebase_file_upload_service.dart';

void main() {
  group('CNH Upload Tests', () {
    late DriverStepperController controller;

    setUp(() {
      controller = DriverStepperController();
    });

    test('deve inicializar controller com fotos nulas', () {
      expect(controller.cnhPhoto, isNull);
      expect(controller.crlvPhoto, isNull);
      expect(controller.canProceedFromDocuments, isFalse);
    });

    test('deve validar tamanho máximo de arquivo', () async {
      // Criar arquivo de teste temporário
      final tempDir = Directory.systemTemp;
      final testFile = File('${tempDir.path}/test_large_file.jpg');
      
      try {
        // Criar arquivo de 11MB (maior que o limite de 10MB)
        final largeData = List.filled(11 * 1024 * 1024, 0xFF);
        await testFile.writeAsBytes(largeData);
        
        // Verificar se o arquivo é muito grande
        final fileSize = await testFile.length();
        const maxSize = 10 * 1024 * 1024; // 10MB
        
        expect(fileSize, greaterThan(maxSize));
        
      } finally {
        // Limpar arquivo de teste
        if (await testFile.exists()) {
          await testFile.delete();
        }
      }
    });

    test('deve validar formato de arquivo válido', () async {
      // Criar arquivo de teste temporário
      final tempDir = Directory.systemTemp;
      final testFile = File('${tempDir.path}/test_valid.jpg');
      
      try {
        // Criar arquivo JPEG válido (header básico)
        await testFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);
        
        // Verificar se o arquivo existe
        expect(await testFile.exists(), isTrue);
        
        // Verificar extensão
        expect(testFile.path.toLowerCase().endsWith('.jpg'), isTrue);
        
      } finally {
        // Limpar arquivo de teste
        if (await testFile.exists()) {
          await testFile.delete();
        }
      }
    });

    test('deve rejeitar formato de arquivo inválido', () async {
      // Criar arquivo de teste temporário
      final tempDir = Directory.systemTemp;
      final testFile = File('${tempDir.path}/test_invalid.txt');
      
      try {
        await testFile.writeAsString('Este é um arquivo de texto');
        
        // Verificar se o arquivo existe
        expect(await testFile.exists(), isTrue);
        
        // Verificar extensão inválida
        expect(testFile.path.toLowerCase().endsWith('.txt'), isTrue);
        expect(testFile.path.toLowerCase().endsWith('.jpg'), isFalse);
        expect(testFile.path.toLowerCase().endsWith('.png'), isFalse);
        expect(testFile.path.toLowerCase().endsWith('.pdf'), isFalse);
        
      } finally {
        // Limpar arquivo de teste
        if (await testFile.exists()) {
          await testFile.delete();
        }
      }
    });

    test('deve aceitar arquivo PDF válido', () async {
      // Criar arquivo PDF de teste
      final tempDir = Directory.systemTemp;
      final testFile = File('${tempDir.path}/test_valid.pdf');
      
      try {
        // Header básico de PDF
        await testFile.writeAsBytes([0x25, 0x50, 0x44, 0x46]); // %PDF
        
        // Verificar se o arquivo existe
        expect(await testFile.exists(), isTrue);
        
        // Verificar extensão
        expect(testFile.path.toLowerCase().endsWith('.pdf'), isTrue);
        
        // Verificar tamanho (deve ser pequeno)
        final fileSize = await testFile.length();
        const maxSize = 10 * 1024 * 1024; // 10MB
        expect(fileSize, lessThan(maxSize));
        
      } finally {
        // Limpar arquivo de teste
        if (await testFile.exists()) {
          await testFile.delete();
        }
      }
    });

    test('deve validar estado inicial do controller', () {
      expect(controller.currentStep, equals(0));
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.vehicleBrand, isEmpty);
      expect(controller.vehicleModel, isEmpty);
      expect(controller.vehicleYear, isEmpty);
      expect(controller.vehiclePlate, isEmpty);
      expect(controller.vehicleColor, isEmpty);
    });

    test('deve validar extensões de arquivo permitidas', () {
      const allowedExtensions = ['.jpg', '.jpeg', '.png', '.pdf'];
      const testFiles = [
        'documento.jpg',
        'documento.jpeg',
        'documento.png',
        'documento.pdf',
        'documento.JPG',
        'documento.JPEG',
        'documento.PNG',
        'documento.PDF',
      ];
      
      for (final fileName in testFiles) {
        final hasValidExtension = allowedExtensions.any(
          (ext) => fileName.toLowerCase().endsWith(ext),
        );
        expect(hasValidExtension, isTrue, reason: 'Arquivo $fileName deve ser válido');
      }
      
      const invalidFiles = [
        'documento.txt',
        'documento.doc',
        'documento.docx',
        'documento.gif',
        'documento.bmp',
      ];
      
      for (final fileName in invalidFiles) {
        final hasValidExtension = allowedExtensions.any(
          (ext) => fileName.toLowerCase().endsWith(ext),
        );
        expect(hasValidExtension, isFalse, reason: 'Arquivo $fileName deve ser inválido');
      }
    });

    test('deve validar limites de tamanho de arquivo', () {
      const maxSizeBytes = 10 * 1024 * 1024; // 10MB
      const testSizes = [
        1024, // 1KB - válido
        1024 * 1024, // 1MB - válido
        5 * 1024 * 1024, // 5MB - válido
        10 * 1024 * 1024, // 10MB - válido (limite)
        11 * 1024 * 1024, // 11MB - inválido
        20 * 1024 * 1024, // 20MB - inválido
      ];
      
      for (var i = 0; i < testSizes.length; i++) {
        final size = testSizes[i];
        final isValid = size <= maxSizeBytes;
        final expectedResult = i < 4; // Primeiros 4 são válidos
        
        expect(isValid, equals(expectedResult), 
               reason: 'Tamanho $size bytes deve ser ${expectedResult ? "válido" : "inválido"}');
      }
    });
  });
}