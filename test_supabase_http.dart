import 'dart:convert';
import 'dart:io';

/// Teste simples de HTTP para verificar conectividade Supabase
/// Execute com: dart run test_supabase_http.dart

const String supabaseUrl = 'https://qlbwacmavngtonauxnte.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E';

void main() async {
  print('🚀 [HTTP_TEST] Iniciando teste HTTP do Supabase...');
  print('📍 [HTTP_TEST] URL: $supabaseUrl');
  print('🔑 [HTTP_TEST] Key: ${supabaseAnonKey.substring(0, 20)}...\n');

  final httpClient = HttpClient();

  try {
    // Teste 1: Verificar se o endpoint está respondendo
    print('🌐 [HTTP_TEST] Teste 1: Verificando endpoint base...');
    await testEndpoint(httpClient, '$supabaseUrl/rest/v1/', 'GET');

    // Teste 2: Verificar tabela app_users
    print('\n📊 [HTTP_TEST] Teste 2: Verificando tabela app_users...');
    await testTable(httpClient, 'app_users');

    // Teste 3: Verificar tabela drivers
    print('\n📊 [HTTP_TEST] Teste 3: Verificando tabela drivers...');
    await testTable(httpClient, 'drivers');

    // Teste 4: Verificar tabela passengers
    print('\n📊 [HTTP_TEST] Teste 4: Verificando tabela passengers...');
    await testTable(httpClient, 'passengers');

    // Teste 5: Verificar tabela trips
    print('\n📊 [HTTP_TEST] Teste 5: Verificando tabela trips...');
    await testTable(httpClient, 'trips');

    // Teste 6: Verificar tabela platform_settings
    print('\n📊 [HTTP_TEST] Teste 6: Verificando platform_settings...');
    await testTable(httpClient, 'platform_settings');

    print('\n🎉 [HTTP_TEST] Todos os testes concluídos!');
  } catch (e) {
    print('💥 [HTTP_TEST] ERRO durante os testes: $e');
  } finally {
    httpClient.close();
  }
}

Future<void> testEndpoint(HttpClient client, String url, String method) async {
  try {
    final uri = Uri.parse(url);
    final request = await client.openUrl(method, uri);

    // Headers do Supabase
    request.headers.add('apikey', supabaseAnonKey);
    request.headers.add('Authorization', 'Bearer $supabaseAnonKey');
    request.headers.add('Content-Type', 'application/json');

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    print('✅ [HTTP_TEST] Endpoint respondeu: ${response.statusCode}');
    if (response.statusCode == 200) {
      print(
          '📄 [HTTP_TEST] Resposta (primeiros 200 chars): ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}');
    } else {
      print('⚠️ [HTTP_TEST] Status não esperado: ${response.statusCode}');
      print(
          '📄 [HTTP_TEST] Resposta: ${responseBody.substring(0, responseBody.length > 500 ? 500 : responseBody.length)}');
    }
  } catch (e) {
    print('❌ [HTTP_TEST] Erro ao testar endpoint: $e');
  }
}

Future<void> testTable(HttpClient client, String tableName) async {
  try {
    final url = '$supabaseUrl/rest/v1/$tableName?select=*&limit=1';
    final uri = Uri.parse(url);
    final request = await client.getUrl(uri);

    // Headers do Supabase
    request.headers.add('apikey', supabaseAnonKey);
    request.headers.add('Authorization', 'Bearer $supabaseAnonKey');
    request.headers.add('Content-Type', 'application/json');
    request.headers.add('Prefer', 'count=exact');

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      final countHeader = response.headers.value('content-range');

      print('✅ [HTTP_TEST] Tabela $tableName acessível');
      print('📊 [HTTP_TEST] Registros encontrados: ${data.length}');

      if (countHeader != null) {
        print('📊 [HTTP_TEST] Content-Range: $countHeader');
      }

      if (data.isNotEmpty && data is List) {
        print(
            '📄 [HTTP_TEST] Primeiro registro: ${data[0].toString().substring(0, data[0].toString().length > 200 ? 200 : data[0].toString().length)}');
      }
    } else {
      print('❌ [HTTP_TEST] Erro ao acessar $tableName: ${response.statusCode}');
      print(
          '📄 [HTTP_TEST] Resposta: ${responseBody.substring(0, responseBody.length > 500 ? 500 : responseBody.length)}');

      if (response.statusCode == 401) {
        print('🔒 [HTTP_TEST] Erro de autorização - verificar chaves ou RLS');
      } else if (response.statusCode == 404) {
        print('❓ [HTTP_TEST] Tabela não encontrada');
      }
    }
  } catch (e) {
    print('❌ [HTTP_TEST] Exceção ao testar $tableName: $e');
  }
}
