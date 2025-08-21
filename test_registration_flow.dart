import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/services/user_service.dart';

/// Script para testar o fluxo de cadastro
void main() async {
  print('🧪 Iniciando teste do fluxo de cadastro...');
  
  try {
    // Simular dados de um usuário de teste
    final testUserId = 'test-user-id-123';
    final testEmail = 'teste@example.com';
    final testFullName = 'Usuário Teste';
    final testPhone = '(11) 99999-9999';
    final testUserType = 'passenger';
    
    print('📋 Dados de teste:');
    print('  - ID: $testUserId');
    print('  - Email: $testEmail');
    print('  - Nome: $testFullName');
    print('  - Telefone: $testPhone');
    print('  - Tipo: $testUserType');
    
    // Verificar se usuário já existe
    print('🔍 Verificando se usuário já existe...');
    final exists = await UserService.userExists(testUserId);
    print('Resultado: ${exists ? "Existe" : "Não existe"}');
    
    if (!exists) {
      print('🆕 Criando usuário de teste...');
      final user = await UserService.createUser(
        authUserId: testUserId,
        email: testEmail,
        fullName: testFullName,
        phone: testPhone,
        userType: testUserType,
      );
      print('✅ Usuário criado com sucesso: ${user.toString()}');
    } else {
      print('ℹ️ Usuário já existe, buscando dados...');
      final user = await UserService.getUserById(testUserId);
      print('📄 Dados do usuário: ${user?.toString()}');
    }
    
    print('✅ Teste concluído com sucesso!');
    
  } catch (e) {
    print('❌ Erro durante o teste: $e');
    print('Stack trace: ${StackTrace.current}');
  }
}