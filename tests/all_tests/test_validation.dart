import 'lib/validators/database_constraints_validator.dart';
import 'lib/exceptions/validation_exception.dart';

void main() {
  print('=== Testando Validações Individuais ===\n');
  
  // Teste 1: Nome válido
  try {
    DatabaseConstraintsValidator.validateFullNameField('João Silva');
    print('✅ Nome válido: João Silva');
  } catch (e) {
    print('❌ Nome válido falhou: $e');
  }
  
  // Teste 2: Nome com email
  try {
    DatabaseConstraintsValidator.validateFullNameField('joao@email.com');
    print('❌ Nome com email passou (ERRO!)');
  } catch (e) {
    print('✅ Nome com email rejeitado: ${e.toString().replaceAll('ValidationException: ', '')}');
  }
  
  // Teste 3: Email válido
  try {
    DatabaseConstraintsValidator.validateEmailField('joao@email.com');
    print('✅ Email válido: joao@email.com');
  } catch (e) {
    print('❌ Email válido falhou: $e');
  }
  
  // Teste 4: Email com nome
  try {
    DatabaseConstraintsValidator.validateEmailField('João Silva');
    print('❌ Email com nome passou (ERRO!)');
  } catch (e) {
    print('✅ Email com nome rejeitado: ${e.toString().replaceAll('ValidationException: ', '')}');
  }
  
  // Teste 5: Nome vazio
  try {
    DatabaseConstraintsValidator.validateFullNameField('');
    print('❌ Nome vazio passou (ERRO!)');
  } catch (e) {
    print('✅ Nome vazio rejeitado: ${e.toString().replaceAll('ValidationException: ', '')}');
  }
  
  // Teste 6: Email vazio
  try {
    DatabaseConstraintsValidator.validateEmailField('');
    print('❌ Email vazio passou (ERRO!)');
  } catch (e) {
    print('✅ Email vazio rejeitado: ${e.toString().replaceAll('ValidationException: ', '')}');
  }
  
  // Teste 7: Nome com caracteres especiais
  try {
    DatabaseConstraintsValidator.validateFullNameField('João123');
    print('❌ Nome com números passou (ERRO!)');
  } catch (e) {
    print('✅ Nome com números rejeitado: ${e.toString().replaceAll('ValidationException: ', '')}');
  }
  
  // Teste 8: Email inválido
  try {
    DatabaseConstraintsValidator.validateEmailField('email_invalido');
    print('❌ Email inválido passou (ERRO!)');
  } catch (e) {
    print('✅ Email inválido rejeitado: ${e.toString().replaceAll('ValidationException: ', '')}');
  }
}