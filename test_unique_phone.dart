import 'dart:convert';
import 'dart:io';
import 'dart:math';

Future<void> main() async {
  print('🧪 [UNIQUE_PHONE_TEST] Testando com telefone único...');
  
  try {
    const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';
    
    // Generate unique data
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final testEmail = 'unique.test.$timestamp@example.com';
    final testPhone = '+551198${random.nextInt(900000) + 100000}${random.nextInt(99) + 10}';
    
    // First, create a user in auth
    print('🔄 [STEP 1] Criando usuário no auth...');
    final authClient = HttpClient();
    final authRequest = await authClient.postUrl(
      Uri.parse('http://127.0.0.1:54321/auth/v1/signup'),
    );
    
    authRequest.headers.set('Content-Type', 'application/json');
    authRequest.headers.set('apikey', anonKey);
    
    final authBody = jsonEncode({
      'email': testEmail,
      'password': 'password123',
    });
    
    authRequest.write(authBody);
    final authResponse = await authRequest.close();
    final authResponseBody = await authResponse.transform(utf8.decoder).join();
    
    if (authResponse.statusCode != 200) {
      print('❌ [STEP 1] Falha no auth: $authResponseBody');
      return;
    }
    
    final authData = jsonDecode(authResponseBody);
    final userId = authData['user']['id'] as String;
    final accessToken = authData['access_token'] as String;
    print('✅ [STEP 1] Auth criado:');
    print('  - UserID: $userId');
    print('  - Email: $testEmail');
    print('  - Phone: $testPhone');
    
    authClient.close();
    
    // Now test PostgREST insert into app_users
    print('🔄 [STEP 2] Inserindo em app_users via PostgREST...');
    final restClient = HttpClient();
    final restRequest = await restClient.postUrl(
      Uri.parse('http://127.0.0.1:54321/rest/v1/app_users'),
    );
    
    restRequest.headers.set('Content-Type', 'application/json');
    restRequest.headers.set('apikey', anonKey);
    restRequest.headers.set('Authorization', 'Bearer $accessToken');
    restRequest.headers.set('Prefer', 'return=representation');
    
    final appUserData = {
      'id': userId,
      'email': testEmail,
      'full_name': 'Unique Phone Test User',
      'phone': testPhone,
      'user_type': 'passenger',
    };
    
    final restBody = jsonEncode(appUserData);
    restRequest.write(restBody);
    
    final restResponse = await restRequest.close();
    final restResponseBody = await restResponse.transform(utf8.decoder).join();
    
    print('📊 [STEP 2] PostgREST Status: ${restResponse.statusCode}');
    print('📊 [STEP 2] PostgREST Response: $restResponseBody');
    
    if (restResponse.statusCode == 201) {
      print('✅ [UNIQUE_PHONE_TEST] SUCESSO COMPLETO!');
      print('🎯 [RESULT] Cadastro completo funcionando perfeitamente!');
      
      // Parse response to show created user
      final createdUser = jsonDecode(restResponseBody);
      if (createdUser is List && createdUser.isNotEmpty) {
        final user = createdUser[0];
        print('👤 [CREATED_USER]:');
        print('  - ID: ${user['id']}');
        print('  - Email: ${user['email']}');
        print('  - Nome: ${user['full_name']}');
        print('  - Telefone: ${user['phone']}');
        print('  - Tipo: ${user['user_type']}');
        print('  - Status: ${user['status']}');
      }
    } else {
      print('❌ [UNIQUE_PHONE_TEST] AINDA EXISTE ERRO');
      print('📋 [ERROR_DETAILS]: $restResponseBody');
    }
    
    restClient.close();
    
  } catch (e) {
    print('❌ [UNIQUE_PHONE_TEST] Erro: $e');
  }
}