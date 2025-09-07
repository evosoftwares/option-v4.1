import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('🎯 [COMPLETE_TEST] Testando cadastro completo (Auth + app_users)...');
  
  try {
    // Dados de teste
    const testEmail = 'complete.test@example.com';
    const testPassword = 'password123';
    const testName = 'Complete Test User';
    const testPhone = '+5511987654321';
    const testUserType = 'passenger';
    
    // Step 1: Register in Supabase Auth (like RegisterScreen)
    print('🔄 [STEP 1] Criando usuário no Supabase Auth...');
    final authClient = HttpClient();
    final authRequest = await authClient.postUrl(
      Uri.parse('http://127.0.0.1:54321/auth/v1/signup'),
    );
    
    authRequest.headers.set('Content-Type', 'application/json');
    authRequest.headers.set('apikey', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0');
    
    final authBody = jsonEncode({
      'email': testEmail,
      'password': testPassword,
    });
    
    authRequest.write(authBody);
    final authResponse = await authRequest.close();
    final authResponseBody = await authResponse.transform(utf8.decoder).join();
    
    print('✅ [STEP 1] Auth Status: ${authResponse.statusCode}');
    
    if (authResponse.statusCode != 200) {
      print('❌ [STEP 1] Falha no auth: $authResponseBody');
      return;
    }
    
    // Parse response to get user ID
    final authData = jsonDecode(authResponseBody);
    final userId = authData['user']['id'] as String;
    print('📋 [STEP 1] User ID criado: $userId');
    
    authClient.close();
    
    // Step 2: Create app_users record (like UserService.createUser)
    print('🔄 [STEP 2] Criando registro em app_users...');
    final dbResult = await Process.run('psql', [
      '-h', '127.0.0.1',
      '-p', '54322', 
      '-U', 'postgres',
      '-d', 'postgres',
      '-c', '''
        INSERT INTO app_users (
          id, 
          email, 
          full_name, 
          phone, 
          user_type,
          created_at
        ) VALUES (
          '$userId', 
          '$testEmail', 
          '$testName', 
          '$testPhone', 
          '$testUserType',
          NOW()
        ) RETURNING *;
      '''
    ], environment: {'PGPASSWORD': 'postgres'});
    
    print('✅ [STEP 2] DB Status: ${dbResult.exitCode}');
    if (dbResult.exitCode == 0) {
      print('📊 [STEP 2] app_users criado:');
      print(dbResult.stdout);
    } else {
      print('❌ [STEP 2] Erro no app_users:');
      print(dbResult.stderr);
      return;
    }
    
    // Step 3: Verify complete registration
    print('🔍 [VERIFICATION] Verificando cadastro completo...');
    final verifyResult = await Process.run('psql', [
      '-h', '127.0.0.1',
      '-p', '54322', 
      '-U', 'postgres',
      '-d', 'postgres',
      '-c', '''
        SELECT 
          au.id,
          au.email AS auth_email,
          au.email_confirmed_at,
          apu.full_name,
          apu.phone,
          apu.user_type,
          apu.status,
          apu.profile_complete
        FROM auth.users au 
        JOIN app_users apu ON au.id = apu.id
        WHERE au.email = '$testEmail';
      '''
    ], environment: {'PGPASSWORD': 'postgres'});
    
    print('🎯 [VERIFICATION] Resultado final:');
    print('Exit code: ${verifyResult.exitCode}');
    print('Data:');
    print(verifyResult.stdout);
    
    if (verifyResult.stderr.isNotEmpty) {
      print('Errors:');
      print(verifyResult.stderr);
    }
    
    print('✅ [COMPLETE_TEST] Cadastro completo testado com sucesso!');
    
  } catch (e) {
    print('❌ [COMPLETE_TEST] Erro: $e');
  }
}