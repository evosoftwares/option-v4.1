import 'package:flutter_test/flutter_test.dart';
import 'package:option/exceptions/validation_exception.dart';
import 'package:option/validators/database_constraints_validator.dart';

void main() {
  group('DatabaseConstraintsValidator', () {
    
    // =============================================================================
    // TESTES PARA APP_USER
    // =============================================================================
    
    group('validateAppUser', () {
      test('deve validar app_user válido', () {
        final validData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'email': 'test@example.com',
          'full_name': 'João Silva',
          'phone': '(11) 99999-9999',
          'user_type': 'passenger',
          'status': 'active',
          'photo_url': 'https://example.com/photo.jpg',
          'is_active': true,
          'is_verified': false,
        };
        
        expect(() => DatabaseConstraintsValidator.validateAppUser(validData), returnsNormally);
      });
      
      test('deve falhar com user_id nulo', () {
        final invalidData = {
          'user_id': null,
          'email': 'test@example.com',
          'full_name': 'João Silva',
          'user_type': 'passenger',
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateAppUser(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('user_id é obrigatório'),
          )),
        );
      });
      
      test('deve falhar com user_id inválido', () {
        final invalidData = {
          'user_id': 'invalid-uuid',
          'email': 'test@example.com',
          'full_name': 'João Silva',
          'user_type': 'passenger',
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateAppUser(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('UUID válido'),
          )),
        );
      });
      
      test('deve falhar com email nulo', () {
        final invalidData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'email': null,
          'full_name': 'João Silva',
          'user_type': 'passenger',
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateAppUser(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('email é obrigatório'),
          )),
        );
      });
      
      test('deve falhar com email inválido', () {
        final invalidData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'email': 'email-inválido',
          'full_name': 'João Silva',
          'user_type': 'passenger',
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateAppUser(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('formato de email inválido'),
          )),
        );
      });
      
      test('deve falhar com email muito longo', () {
        final invalidData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'email': '${'a' * 250}@example.com', // > 255 caracteres
          'full_name': 'João Silva',
          'user_type': 'passenger',
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateAppUser(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('255 caracteres'),
          )),
        );
      });
      
      test('deve falhar com full_name nulo', () {
        final invalidData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'email': 'test@example.com',
          'full_name': null,
          'user_type': 'passenger',
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateAppUser(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('full_name é obrigatório'),
          )),
        );
      });
      
      test('deve falhar com full_name muito longo', () {
        final invalidData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'email': 'test@example.com',
          'full_name': 'a' * 101, // > 100 caracteres
          'user_type': 'passenger',
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateAppUser(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('100 caracteres'),
          )),
        );
      });
      
      test('deve falhar com full_name com caracteres inválidos', () {
        final invalidData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'email': 'test@example.com',
          'full_name': 'João123Silva',
          'user_type': 'passenger',
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateAppUser(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('caracteres inválidos'),
          )),
        );
      });
      
      test('deve aceitar phone nulo', () {
        final validData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'email': 'test@example.com',
          'full_name': 'João Silva',
          'phone': null,
          'user_type': 'passenger',
        };
        
        expect(() => DatabaseConstraintsValidator.validateAppUser(validData), returnsNormally);
      });
      
      test('deve falhar com phone muito longo', () {
        final invalidData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'email': 'test@example.com',
          'full_name': 'João Silva',
          'phone': '1' * 21, // > 20 caracteres
          'user_type': 'passenger',
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateAppUser(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('20 caracteres'),
          )),
        );
      });
      
      test('deve falhar com user_type inválido', () {
        final invalidData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'email': 'test@example.com',
          'full_name': 'João Silva',
          'user_type': 'invalid_type',
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateAppUser(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('user_type inválido'),
          )),
        );
      });
      
      test('deve aceitar status nulo', () {
        final validData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'email': 'test@example.com',
          'full_name': 'João Silva',
          'user_type': 'passenger',
          'status': null,
        };
        
        expect(() => DatabaseConstraintsValidator.validateAppUser(validData), returnsNormally);
      });
      
      test('deve falhar com status inválido', () {
        final invalidData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'email': 'test@example.com',
          'full_name': 'João Silva',
          'user_type': 'passenger',
          'status': 'invalid_status',
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateAppUser(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('status inválido'),
          )),
        );
      });
      
      test('deve aceitar photo_url nulo', () {
        final validData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'email': 'test@example.com',
          'full_name': 'João Silva',
          'user_type': 'passenger',
          'photo_url': null,
        };
        
        expect(() => DatabaseConstraintsValidator.validateAppUser(validData), returnsNormally);
      });
      
      test('deve falhar com photo_url inválida', () {
        final invalidData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'email': 'test@example.com',
          'full_name': 'João Silva',
          'user_type': 'passenger',
          'photo_url': 'invalid-url',
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateAppUser(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('URL válida'),
          )),
        );
      });
    });
    
    // =============================================================================
    // TESTES PARA DRIVER
    // =============================================================================
    
    group('validateDriver', () {
      test('deve validar driver válido', () {
        final validData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'cnh_number': '12345678901',
          'cnh_expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'vehicle_brand': 'Toyota',
          'vehicle_model': 'Corolla',
          'vehicle_year': 2020,
          'vehicle_color': 'Branco',
          'vehicle_plate': 'ABC1234',
          'vehicle_category': 'economy',
          'approval_status': 'approved',
          'is_online': false,
          'accepts_pet': true,
          'accepts_grocery': false,
          'accepts_condo': true,
          'pet_fee': 5.00,
          'grocery_fee': 3.50,
          'condo_fee': 2.00,
          'stop_fee': 1.50,
          'custom_price_per_km': 2.50,
          'custom_price_per_minute': 0.30,
          'bank_code': '001',
          'bank_agency': '1234',
          'bank_account': '12345-6',
          'bank_account_type': 'corrente',
          'pix_key': '12345678901',
          'pix_key_type': 'cpf',
          'current_latitude': -23.5505,
          'current_longitude': -46.6333,
          'consecutive_cancellations': 0,
          'total_trips': 100,
          'average_rating': 4.8,
        };
        
        expect(() => DatabaseConstraintsValidator.validateDriver(validData), returnsNormally);
      });
      
      test('deve falhar com cnh_number nulo', () {
        final invalidData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'cnh_number': null,
          'cnh_expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'vehicle_brand': 'Toyota',
          'vehicle_model': 'Corolla',
          'vehicle_year': 2020,
          'vehicle_color': 'Branco',
          'vehicle_plate': 'ABC1234',
          'vehicle_category': 'economy',
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateDriver(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('cnh_number é obrigatório'),
          )),
        );
      });
      
      test('deve falhar com cnh_number inválido', () {
        final invalidData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'cnh_number': '123456789', // Apenas 9 dígitos
          'cnh_expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'vehicle_brand': 'Toyota',
          'vehicle_model': 'Corolla',
          'vehicle_year': 2020,
          'vehicle_color': 'Branco',
          'vehicle_plate': 'ABC1234',
          'vehicle_category': 'economy',
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateDriver(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('11 dígitos'),
          )),
        );
      });
      
      test('deve falhar com cnh_expiry_date vencida', () {
        final invalidData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'cnh_number': '12345678901',
          'cnh_expiry_date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'vehicle_brand': 'Toyota',
          'vehicle_model': 'Corolla',
          'vehicle_year': 2020,
          'vehicle_color': 'Branco',
          'vehicle_plate': 'ABC1234',
          'vehicle_category': 'economy',
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateDriver(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('vencida'),
          )),
        );
      });
      
      test('deve falhar com vehicle_year inválido', () {
        final invalidData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'cnh_number': '12345678901',
          'cnh_expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'vehicle_brand': 'Toyota',
          'vehicle_model': 'Corolla',
          'vehicle_year': 1980, // Muito antigo
          'vehicle_color': 'Branco',
          'vehicle_plate': 'ABC1234',
          'vehicle_category': 'economy',
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateDriver(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('1990'),
          )),
        );
      });
      
      test('deve falhar com vehicle_plate inválida', () {
        final invalidData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'cnh_number': '12345678901',
          'cnh_expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'vehicle_brand': 'Toyota',
          'vehicle_model': 'Corolla',
          'vehicle_year': 2020,
          'vehicle_color': 'Branco',
          'vehicle_plate': '123ABCD', // Formato inválido
          'vehicle_category': 'economy',
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateDriver(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('formato brasileiro'),
          )),
        );
      });
      
      test('deve falhar com vehicle_category inválida', () {
        final invalidData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'cnh_number': '12345678901',
          'cnh_expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'vehicle_brand': 'Toyota',
          'vehicle_model': 'Corolla',
          'vehicle_year': 2020,
          'vehicle_color': 'Branco',
          'vehicle_plate': 'ABC1234',
          'vehicle_category': 'luxury', // Categoria inválida
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateDriver(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('vehicle_category inválido'),
          )),
        );
      });
      
      test('deve falhar com taxa negativa', () {
        final invalidData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'cnh_number': '12345678901',
          'cnh_expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'vehicle_brand': 'Toyota',
          'vehicle_model': 'Corolla',
          'vehicle_year': 2020,
          'vehicle_color': 'Branco',
          'vehicle_plate': 'ABC1234',
          'vehicle_category': 'economy',
          'pet_fee': -5.00, // Taxa negativa
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateDriver(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('negativo'),
          )),
        );
      });
      
      test('deve falhar com taxa muito alta', () {
        final invalidData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'cnh_number': '12345678901',
          'cnh_expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'vehicle_brand': 'Toyota',
          'vehicle_model': 'Corolla',
          'vehicle_year': 2020,
          'vehicle_color': 'Branco',
          'vehicle_plate': 'ABC1234',
          'vehicle_category': 'economy',
          'pet_fee': 1000.00, // Taxa muito alta
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateDriver(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('999,99'),
          )),
        );
      });
      
      test('deve validar dados bancários completos', () {
        final validData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'cnh_number': '12345678901',
          'cnh_expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'vehicle_brand': 'Toyota',
          'vehicle_model': 'Corolla',
          'vehicle_year': 2020,
          'vehicle_color': 'Branco',
          'vehicle_plate': 'ABC1234',
          'vehicle_category': 'economy',
          'bank_code': '001',
          'bank_agency': '1234',
          'bank_account': '12345-6',
          'bank_account_type': 'corrente',
        };
        
        expect(() => DatabaseConstraintsValidator.validateDriver(validData), returnsNormally);
      });
      
      test('deve falhar com dados bancários incompletos', () {
        final invalidData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'cnh_number': '12345678901',
          'cnh_expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'vehicle_brand': 'Toyota',
          'vehicle_model': 'Corolla',
          'vehicle_year': 2020,
          'vehicle_color': 'Branco',
          'vehicle_plate': 'ABC1234',
          'vehicle_category': 'economy',
          'bank_code': '001', // Apenas código do banco, faltam outros campos
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateDriver(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('obrigatório quando dados bancários'),
          )),
        );
      });
      
      test('deve validar chave PIX válida', () {
        final validData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'cnh_number': '12345678901',
          'cnh_expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'vehicle_brand': 'Toyota',
          'vehicle_model': 'Corolla',
          'vehicle_year': 2020,
          'vehicle_color': 'Branco',
          'vehicle_plate': 'ABC1234',
          'vehicle_category': 'economy',
          'pix_key': 'test@example.com',
          'pix_key_type': 'email',
        };
        
        expect(() => DatabaseConstraintsValidator.validateDriver(validData), returnsNormally);
      });
      
      test('deve falhar com chave PIX sem tipo', () {
        final invalidData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'cnh_number': '12345678901',
          'cnh_expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'vehicle_brand': 'Toyota',
          'vehicle_model': 'Corolla',
          'vehicle_year': 2020,
          'vehicle_color': 'Branco',
          'vehicle_plate': 'ABC1234',
          'vehicle_category': 'economy',
          'pix_key': 'test@example.com',
          // pix_key_type ausente
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateDriver(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('pix_key_type é obrigatório'),
          )),
        );
      });
      
      test('deve falhar com latitude inválida', () {
        final invalidData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'cnh_number': '12345678901',
          'cnh_expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'vehicle_brand': 'Toyota',
          'vehicle_model': 'Corolla',
          'vehicle_year': 2020,
          'vehicle_color': 'Branco',
          'vehicle_plate': 'ABC1234',
          'vehicle_category': 'economy',
          'current_latitude': 95.0, // > 90
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateDriver(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('entre -90 e 90'),
          )),
        );
      });
      
      test('deve falhar com longitude inválida', () {
        final invalidData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'cnh_number': '12345678901',
          'cnh_expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'vehicle_brand': 'Toyota',
          'vehicle_model': 'Corolla',
          'vehicle_year': 2020,
          'vehicle_color': 'Branco',
          'vehicle_plate': 'ABC1234',
          'vehicle_category': 'economy',
          'current_longitude': 185.0, // > 180
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateDriver(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('entre -180 e 180'),
          )),
        );
      });
      
      test('deve falhar com avaliação inválida', () {
        final invalidData = {
          'user_id': '123e4567-e89b-12d3-a456-426614174000',
          'cnh_number': '12345678901',
          'cnh_expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'vehicle_brand': 'Toyota',
          'vehicle_model': 'Corolla',
          'vehicle_year': 2020,
          'vehicle_color': 'Branco',
          'vehicle_plate': 'ABC1234',
          'vehicle_category': 'economy',
          'average_rating': 6.0, // > 5
        };
        
        expect(
          () => DatabaseConstraintsValidator.validateDriver(invalidData),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('entre 0 e 5'),
          )),
        );
      });
    });
  });
}