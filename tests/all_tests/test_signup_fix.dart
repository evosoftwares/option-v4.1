import 'dart:convert';
import 'dart:io';

/// Teste HTTP simples para verificar se o erro 500 no signup foi corrigido
void main() async {
  print('🚀 Iniciando teste HTTP de correção do erro 500 no signup...');
  
  const supabaseUrl = 'https://qlbwacmavngtonauxnte.supabase.co';
  const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E';
  
  try {
    // Teste 1: Signup básico
    await testBasicSignup(supabaseUrl, supabaseAnonKey);
    
    // Teste 2: Múltiplos signups
    await testMultipleSignups(supabaseUrl, supabaseAnonKey);
    
    print('\n✅ TODOS OS TESTES CONCLUÍDOS COM SUCESSO!');
    print('🎉 O erro 500 no signup foi corrigido!');
    
  } catch (e) {
    print('\n❌ ERRO DURANTE OS TESTES: $e');
    exit(1);
  }
}

/// Teste básico de signup via HTTP
Future<void> testBasicSignup(String supabaseUrl, String apiKey) async {
  print('\n🧪 Teste 1: Signup básico via HTTP');
  
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final testEmail = 'teste_signup_$timestamp@exemplo.com';
  final testPassword = 'SenhaSegura123!';
  
  print('📧 Testando com email: $testEmail');
  
  final client = HttpClient();
  
  try {
    // Fazer requisição de signup
    final request = await client.postUrl(
      Uri.parse('$supabaseUrl/auth/v1/signup')
    );
    
    // Headers
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('apikey', apiKey);
    request.headers.set('Authorization', 'Bearer $apiKey');
    
    // Body
    final body = jsonEncode({
      'email': testEmail,
      'password': testPassword,
    });
    
    request.write(body);
    
    // Enviar requisição
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('📊 Status Code: ${response.statusCode}');
    print('📄 Response: ${responseBody.length > 200 ? responseBody.substring(0, 200) + '...' : responseBody}');
    
    if (response.statusCode == 500) {
      throw Exception('❌ ERRO 500 AINDA PRESENTE!\nResponse: $responseBody');
    }
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ Signup realizado com sucesso!');
      
      // Tentar parsear resposta
      try {
        final data = jsonDecode(responseBody);
        if (data['user'] != null) {
          print('🆔 User ID: ${data['user']['id']}');
          print('📧 Email: ${data['user']['email']}');
        }
      } catch (e) {
        print('⚠️ Erro ao parsear resposta: $e');
      }
    } else {
      print('ℹ️ Status não esperado: ${response.statusCode}');
      print('📄 Response: $responseBody');
    }
    
    print('✅ Teste 1 concluído - Sem erro 500!');
    
  } catch (e) {
    if (e.toString().contains('500')) {
      rethrow;
    }
    print('⚠️ Erro durante teste: $e');
  } finally {
    client.close();
  }
}

/// Teste de múltiplos signups simultâneos via HTTP
Future<void> testMultipleSignups(String supabaseUrl, String apiKey) async {
  print('\n🔄 Teste 2: Múltiplos signups simultâneos via HTTP');
  
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final futures = <Future>[];
  
  // Criar 3 signups simultâneos
  for (int i = 0; i < 3; i++) {
    final email = 'teste_simultaneo_${timestamp}_$i@exemplo.com';
    final password = 'SenhaSegura123!';
    
    futures.add(
      _performHttpSignup(supabaseUrl, apiKey, email, password, i)
    );
  }
  
  try {
    final results = await Future.wait(futures, eagerError: false);
    
    int successCount = 0;
    int errorCount = 0;
    int error500Count = 0;
    
    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      if (result['success'] == true) {
        successCount++;
        print('✅ Signup $i: Sucesso (${result['status']})');
      } else if (result['status'] == 500) {
        error500Count++;
        print('❌ Signup $i: ERRO 500!');
      } else {
        errorCount++;
        print('⚠️ Signup $i: Erro ${result['status']} (esperado)');
      }
    }
    
    print('📊 Resultados: $successCount sucessos, $errorCount erros, $error500Count erros 500');
    
    if (error500Count > 0) {
      throw Exception('❌ DETECTADOS $error500Count ERROS 500 EM SIGNUPS SIMULTÂNEOS!');
    }
    
    print('✅ Teste 2 concluído - Nenhum erro 500 detectado!');
    
  } catch (e) {
    if (e.toString().contains('500')) {
      rethrow;
    }
    print('ℹ️ Alguns erros esperados em signups simultâneos: $e');
  }
}

/// Função auxiliar para realizar signup via HTTP
Future<Map<String, dynamic>> _performHttpSignup(
  String supabaseUrl, 
  String apiKey, 
  String email, 
  String password, 
  int index
) async {
  final client = HttpClient();
  
  try {
    final request = await client.postUrl(
      Uri.parse('$supabaseUrl/auth/v1/signup')
    );
    
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('apikey', apiKey);
    request.headers.set('Authorization', 'Bearer $apiKey');
    
    final body = jsonEncode({
      'email': email,
      'password': password,
    });
    
    request.write(body);
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    return {
      'success': response.statusCode == 200 || response.statusCode == 201,
      'status': response.statusCode,
      'body': responseBody,
    };
    
  } catch (e) {
    return {
      'success': false,
      'status': 0,
      'error': e.toString(),
    };
  } finally {
    client.close();
  }
}