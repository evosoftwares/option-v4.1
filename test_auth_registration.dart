import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('🧪 [AUTH_TEST] Testando registro via Supabase Auth API...');
  
  try {
    // Test Supabase Auth signup directly via REST API
    final client = HttpClient();
    final request = await client.postUrl(
      Uri.parse('http://127.0.0.1:54321/auth/v1/signup'),
    );
    
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('apikey', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0');
    
    final body = jsonEncode({
      'email': 'test@example.com',
      'password': 'password123',
    });
    
    request.write(body);
    final response = await request.close();
    
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('✅ [AUTH_TEST] Status: ${response.statusCode}');
    print('📊 [AUTH_TEST] Response:');
    print(responseBody);
    
    client.close();
    
    // Now check if user was created in auth.users
    final result = await Process.run('psql', [
      '-h', '127.0.0.1',
      '-p', '54322', 
      '-U', 'postgres',
      '-d', 'postgres',
      '-c', "SELECT id, email, email_confirmed_at, created_at FROM auth.users ORDER BY created_at DESC LIMIT 1;"
    ], environment: {'PGPASSWORD': 'postgres'});
    
    print('\n🔍 [AUTH_TEST] Auth user check:');
    print('Exit code: ${result.exitCode}');
    print('STDOUT:');
    print(result.stdout);
    
    if (result.stderr.isNotEmpty) {
      print('STDERR:');
      print(result.stderr);
    }
    
  } catch (e) {
    print('❌ [AUTH_TEST] Erro: $e');
  }
}