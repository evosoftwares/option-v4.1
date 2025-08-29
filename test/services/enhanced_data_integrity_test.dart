import 'package:flutter_test/flutter_test.dart';

import 'package:option/services/enhanced_data_integrity_service.dart';

void main() {
  group('EnhancedDataIntegrityService - Validação de Falsos Positivos', () {
    
    group('Nomes VÁLIDOS que NÃO devem ser marcados como corrompidos', () {
      test('nomes compostos normais', () {
        final validNames = [
          'João Silva',
          'Maria da Silva Santos',
          'José Carlos de Oliveira',
          'Ana Beatriz Ferreira',
          'Carlos Eduardo',
          'Maria José',
          'João Pedro dos Santos',
          'Antônio Carlos da Silva',
          'Luiz Felipe',
          'Ana Clara',
        ];

        for (final name in validNames) {
          expect(
            EnhancedDataIntegrityService.analyzeField('full_name', name).isCorrupted,
            false,
            reason: 'Nome válido "$name" foi marcado incorretamente como corrompido',
          );
        }
      });

      test('nomes com caracteres especiais válidos', () {
        final validNames = [
          'José María González',
          'François Dupont',
          'José da Silva Jr.',
          'Maria Santos Filho',
          'João & Maria',
          "O'Connor Silva",
          'Jean-Pierre Dubois',
          'Van Der Berg',
        ];

        for (final name in validNames) {
          expect(
            EnhancedDataIntegrityService.analyzeField('full_name', name).isCorrupted,
            false,
            reason: 'Nome com caracteres especiais "$name" foi marcado incorretamente como corrompido',
          );
        }
      });

      test('nomes curtos mas válidos', () {
        final validNames = [
          'Lu',
          'Jo',
          'Ana',
          'João',
          'Bia',
        ];

        for (final name in validNames) {
          final analysis = EnhancedDataIntegrityService.analyzeField('full_name', name);
          expect(
            analysis.isCorrupted,
            false,
            reason: 'Nome curto válido "$name" foi marcado incorretamente como corrompido',
          );
        }
      });
    });

    group('Nomes CORROMPIDOS que DEVEM ser detectados', () {
      test('dados JSON óbvios', () {
        final corruptedNames = [
          '{"count": 123}',
          '[error message]',
          '{name: corrupted}',
          '{"missing_passenger_records": true}',
          '[{"id": 123}]',
        ];

        for (final name in corruptedNames) {
          expect(
            EnhancedDataIntegrityService.analyzeField('full_name', name).isCorrupted,
            true,
            reason: 'Dados JSON corrompidos "$name" não foram detectados',
          );
        }
      });

      test('mensagens de erro específicas', () {
        final corruptedNames = [
          'missing_passenger_records',
          'database_error occurred',
          'sql_error in query',
          'exception_message: failed',
          'error_code_500',
          'failed_to_create_user',
          'unable_to_fetch_data',
          'connection_timeout_error',
          'query_failed_with_error',
        ];

        for (final name in corruptedNames) {
          expect(
            EnhancedDataIntegrityService.analyzeField('full_name', name).isCorrupted,
            true,
            reason: 'Mensagem de erro "$name" não foi detectada',
          );
        }
      });

      test('códigos suspeitos', () {
        final corruptedNames = [
          '200',
          '404',
          '500',
          '0x1234ABCD',
          'abc123-def456-ghi789-jkl012-mno345_error',
        ];

        for (final name in corruptedNames) {
          expect(
            EnhancedDataIntegrityService.analyzeField('full_name', name).isCorrupted,
            true,
            reason: 'Código suspeito "$name" não foi detectado',
          );
        }
      });

      test('padrões conhecidos do sistema', () {
        final corruptedNames = [
          'PENDENTE_CADASTRO',
          'count: 45',
          'issue #123',
          'error 404',
          'PENDENTE_VALIDACAO',
        ];

        for (final name in corruptedNames) {
          expect(
            EnhancedDataIntegrityService.analyzeField('full_name', name).isCorrupted,
            true,
            reason: 'Padrão conhecido "$name" não foi detectado',
          );
        }
      });
    });

    group('Telefones válidos vs corrompidos', () {
      test('telefones válidos', () {
        final validPhones = [
          '+5511999887766',
          '(11) 99988-7766',
          '11999887766',
          '21987654321',
          '+55 11 9 9988-7766',
        ];

        for (final phone in validPhones) {
          expect(
            EnhancedDataIntegrityService.analyzeField('phone', phone).isCorrupted,
            false,
            reason: 'Telefone válido "$phone" foi marcado incorretamente como corrompido',
          );
        }
      });

      test('telefones corrompidos', () {
        final corruptedPhones = [
          '11999887766-1640995123456',
          '11999887766-1641234567890',
          '11999887766-1642345678901',
          'phone_error',
          'missing_phone',
          'unable_to_validate',
        ];

        for (final phone in corruptedPhones) {
          expect(
            EnhancedDataIntegrityService.analyzeField('phone', phone).isCorrupted,
            true,
            reason: 'Telefone corrompido "$phone" não foi detectado',
          );
        }
      });
    });

    group('Validação de lote', () {
      test('lote misto - válidos e corrompidos', () async {
        final userData = [
          {
            'id': 'user1',
            'full_name': 'João Silva',
            'email': 'joao@email.com',
            'phone': '11999887766',
          },
          {
            'id': 'user2', 
            'full_name': 'missing_passenger_records',
            'email': 'test@email.com',
            'phone': '11999887766-1640995123456',
          },
          {
            'id': 'user3',
            'full_name': 'Maria Santos',
            'email': 'maria@email.com', 
            'phone': '+5511987654321',
          },
          {
            'id': 'user4',
            'full_name': '{"count": 123}',
            'email': 'corrupted@email.com',
            'phone': '11888777666',
          },
        ];

        final result = await EnhancedDataIntegrityService.validateUserDataBatch(userData);

        expect(result.totalUsers, 4);
        expect(result.corruptedUsers, 2);
        expect(result.corruptedUserIds, containsAll(['user2', 'user4']));
        expect(result.accuracy, greaterThan(0.9));
        
        // Verificar que usuários válidos não foram marcados como corrompidos
        expect(result.corruptedUserIds, isNot(contains('user1')));
        expect(result.corruptedUserIds, isNot(contains('user3')));
      });
    });

    group('Casos limítrofes', () {
      test('strings vazias e nulas', () {
        expect(
          EnhancedDataIntegrityService.analyzeField('full_name', '').isCorrupted,
          false,
        );
        
        expect(
          EnhancedDataIntegrityService.analyzeField('phone', '').isCorrupted,
          false,
        );
      });

      test('espaços em branco', () {
        expect(
          EnhancedDataIntegrityService.analyzeField('full_name', '   ').isCorrupted,
          false,
        );
        
        expect(
          EnhancedDataIntegrityService.analyzeField('full_name', '\t\n ').isCorrupted,
          false,
        );
      });

      test('nomes com números válidos', () {
        final validNames = [
          'João Silva 2',
          'Maria III',
          'José Jr 3',
        ];

        for (final name in validNames) {
          expect(
            EnhancedDataIntegrityService.analyzeField('full_name', name).isCorrupted,
            false,
            reason: 'Nome com número válido "$name" foi marcado incorretamente como corrompido',
          );
        }
      });
    });
  });

  group('Confiança e Precisão', () {
    test('níveis de confiança apropriados', () {
      // Alto nível de confiança para casos óbvios
      final obviousCorruption = EnhancedDataIntegrityService.analyzeField(
        'full_name', 
        'missing_passenger_records'
      );
      expect(obviousCorruption.confidence, greaterThan(0.8));
      
      // Baixo nível de confiança para casos duvidosos
      final shortName = EnhancedDataIntegrityService.analyzeField(
        'full_name',
        'Al'
      );
      expect(shortName.confidence, lessThan(0.5));
    });

    test('recomendações apropriadas', () {
      final analysis = EnhancedDataIntegrityService.analyzeField(
        'phone',
        '11999887766-1640995123456'
      );
      
      expect(analysis.isCorrupted, true);
      expect(analysis.recommendation, contains('timestamp'));
      expect(analysis.issues, isNotEmpty);
    });
  });
}