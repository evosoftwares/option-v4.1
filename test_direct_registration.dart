import 'dart:io';

Future<void> main() async {
  print('🧪 [DIRECT_TEST] Testando cadastro direto no Supabase local...');
  
  try {
    // Test direct SQL insertion
    final result = await Process.run('psql', [
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
          'direct-test-user-123', 
          'direct.test@example.com', 
          'Direct Test User', 
          '+5511987654321', 
          'passenger',
          NOW()
        ) RETURNING *;
      '''
    ], environment: {'PGPASSWORD': 'postgres'});
    
    print('✅ [DIRECT_TEST] Exit code: ${result.exitCode}');
    print('📊 [DIRECT_TEST] STDOUT:');
    print(result.stdout);
    
    if (result.stderr.isNotEmpty) {
      print('❌ [DIRECT_TEST] STDERR:');
      print(result.stderr);
    }
    
    // Test querying the inserted user
    final queryResult = await Process.run('psql', [
      '-h', '127.0.0.1',
      '-p', '54322', 
      '-U', 'postgres',
      '-d', 'postgres',
      '-c', "SELECT * FROM app_users WHERE email = 'direct.test@example.com';"
    ], environment: {'PGPASSWORD': 'postgres'});
    
    print('\n🔍 [DIRECT_TEST] Query result:');
    print('Exit code: ${queryResult.exitCode}');
    print('STDOUT:');
    print(queryResult.stdout);
    
  } catch (e) {
    print('❌ [DIRECT_TEST] Erro: $e');
  }
}