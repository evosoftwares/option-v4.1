import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('🧪 [POSTGREST_TEST] Testando PostgREST API diretamente...');
  
  try {
    const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';
    
    // First, create a user in auth
    print('🔄 [STEP 1] Criando usuário no auth...');
    final authClient = HttpClient();
    final authRequest = await authClient.postUrl(
      Uri.parse('http://127.0.0.1:54321/auth/v1/signup'),
    );
    
    authRequest.headers.set('Content-Type', 'application/json');
    authRequest.headers.set('apikey', anonKey);
    
    const testEmail = 'postgrest.test@example.com';
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
    print('✅ [STEP 1] Auth criado - UserID: $userId');
    
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
      'full_name': 'PostgREST Test User',
      'phone': '+5511987654321',
      'user_type': 'passenger',
    };
    
    final restBody = jsonEncode(appUserData);
    restRequest.write(restBody);
    
    final restResponse = await restRequest.close();
    final restResponseBody = await restResponse.transform(utf8.decoder).join();
    
    print('📊 [STEP 2] PostgREST Status: ${restResponse.statusCode}');
    print('📊 [STEP 2] PostgREST Response: $restResponseBody');
    
    if (restResponse.statusCode == 201) {
      print('✅ [POSTGREST_TEST] SUCESSO! app_users criado via PostgREST');
    } else {
      print('❌ [POSTGREST_TEST] ERRO na criação do app_users');
      
      // Print response headers for debugging
      print('📋 [DEBUG] Response headers:');
      restResponse.headers.forEach((name, values) {
        print('  $name: ${values.join(', ')}');
      });
    }
    
    restClient.close();
    
  } catch (e) {
    print('❌ [POSTGREST_TEST] Erro: $e');
  }
}