import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/config/app_config.dart';
import 'lib/services/user_service.dart';
import 'lib/utils/supabase_helper.dart';
import 'lib/exceptions/app_exceptions.dart';

Future<void> main() async {
  print('🧪 [USER_SERVICE_TEST] Testando UserService.createUser...');
  
  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    SupabaseHelper.markInitialized();
    
    print('✅ [USER_SERVICE_TEST] Supabase inicializado');
    
    // First create an auth user
    const testEmail = 'userservice.test@example.com';
    const testPassword = 'password123';
    
    print('🔄 [USER_SERVICE_TEST] Criando usuário no auth...');
    final authResponse = await Supabase.instance.client.auth.signUp(
      email: testEmail,
      password: testPassword,
    );
    
    if (authResponse.user == null) {
      print('❌ [USER_SERVICE_TEST] Falha ao criar usuário no auth');
      return;
    }
    
    final userId = authResponse.user!.id;
    print('✅ [USER_SERVICE_TEST] Usuário criado no auth: $userId');
    
    // Now test UserService.createUser
    print('🔄 [USER_SERVICE_TEST] Testando UserService.createUser...');
    
    try {
      final user = await UserService.createUser(
        authUserId: userId,
        email: testEmail,
        fullName: 'User Service Test',
        phone: '+5511987654321',
        userType: 'passenger',
      );
      
      print('✅ [USER_SERVICE_TEST] UserService.createUser SUCESSO!');
      print('📊 [USER_SERVICE_TEST] Usuário criado:');
      print('  - ID: ${user.id}');
      print('  - Email: ${user.email}');
      print('  - Nome: ${user.fullName}');
      print('  - Telefone: ${user.phone}');
      print('  - Tipo: ${user.userType}');
      
    } catch (e) {
      print('❌ [USER_SERVICE_TEST] UserService.createUser ERRO: $e');
      print('❌ [USER_SERVICE_TEST] Tipo do erro: ${e.runtimeType}');
      if (e is DatabaseException) {
        print('❌ [USER_SERVICE_TEST] DatabaseException details: ${e.message}');
        print('❌ [USER_SERVICE_TEST] DatabaseException code: ${e.code}');
      }
      rethrow;
    }
    
  } catch (e) {
    print('❌ [USER_SERVICE_TEST] Erro geral: $e');
    print('❌ [USER_SERVICE_TEST] StackTrace: ${StackTrace.current}');
  }
}