import 'dart:convert';
import 'package:http/http.dart' as http;

/// Teste direto da API do Supabase Storage para verificar bucket user-photos
void main() async {
  // Credenciais do Supabase
  const String supabaseUrl = 'https://qlbwacmavngtonauxnte.supabase.co';
  const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E';
  const String supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk';

  print('🔍 Testando API do Supabase Storage diretamente...');
  print('=' * 60);

  // Teste 1: Verificar bucket específico user-photos com chave anônima
  print('\n📋 Teste 1: Verificar bucket user-photos (chave anônima)');
  try {
    final response1 = await http.get(
      Uri.parse('$supabaseUrl/storage/v1/bucket/user-photos'),
      headers: {
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $supabaseAnonKey',
      },
    );
    
    print('Status Code: ${response1.statusCode}');
    print('Response Body: ${response1.body}');
    print('Headers: ${response1.headers}');
    
    if (response1.statusCode == 200) {
      final bucketData = jsonDecode(response1.body);
      print('✅ Bucket encontrado!');
      print('   - ID: ${bucketData['id']}');
      print('   - Nome: ${bucketData['name']}');
      print('   - Público: ${bucketData['public']}');
      print('   - Criado em: ${bucketData['created_at']}');
    } else {
      print('❌ Erro ao buscar bucket: ${response1.statusCode}');
    }
  } catch (e) {
    print('❌ Exceção no Teste 1: $e');
  }

  // Teste 2: Listar todos os buckets com chave anônima
  print('\n📋 Teste 2: Listar todos os buckets (chave anônima)');
  try {
    final response2 = await http.get(
      Uri.parse('$supabaseUrl/storage/v1/bucket'),
      headers: {
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $supabaseAnonKey',
      },
    );
    
    print('Status Code: ${response2.statusCode}');
    print('Response Body: ${response2.body}');
    
    if (response2.statusCode == 200) {
      final buckets = jsonDecode(response2.body) as List;
      print('✅ Buckets encontrados: ${buckets.length}');
      for (var bucket in buckets) {
        print('   - ${bucket['name']} (público: ${bucket['public']})');
      }
      
      // Verificar se user-photos existe na lista
      final userPhotosBucket = buckets.firstWhere(
        (bucket) => bucket['name'] == 'user-photos',
        orElse: () => null,
      );
      
      if (userPhotosBucket != null) {
        print('✅ Bucket user-photos encontrado na lista!');
      } else {
        print('❌ Bucket user-photos NÃO encontrado na lista!');
      }
    } else {
      print('❌ Erro ao listar buckets: ${response2.statusCode}');
    }
  } catch (e) {
    print('❌ Exceção no Teste 2: $e');
  }

  // Teste 3: Verificar bucket com chave de serviço
  print('\n📋 Teste 3: Verificar bucket user-photos (chave de serviço)');
  try {
    final response3 = await http.get(
      Uri.parse('$supabaseUrl/storage/v1/bucket/user-photos'),
      headers: {
        'apikey': supabaseServiceKey,
        'Authorization': 'Bearer $supabaseServiceKey',
      },
    );
    
    print('Status Code: ${response3.statusCode}');
    print('Response Body: ${response3.body}');
    
    if (response3.statusCode == 200) {
      final bucketData = jsonDecode(response3.body);
      print('✅ Bucket encontrado com chave de serviço!');
      print('   - ID: ${bucketData['id']}');
      print('   - Nome: ${bucketData['name']}');
      print('   - Público: ${bucketData['public']}');
    } else {
      print('❌ Erro com chave de serviço: ${response3.statusCode}');
    }
  } catch (e) {
    print('❌ Exceção no Teste 3: $e');
  }

  // Teste 4: Listar todos os buckets com chave de serviço
  print('\n📋 Teste 4: Listar todos os buckets (chave de serviço)');
  try {
    final response4 = await http.get(
      Uri.parse('$supabaseUrl/storage/v1/bucket'),
      headers: {
        'apikey': supabaseServiceKey,
        'Authorization': 'Bearer $supabaseServiceKey',
      },
    );
    
    print('Status Code: ${response4.statusCode}');
    print('Response Body: ${response4.body}');
    
    if (response4.statusCode == 200) {
      final buckets = jsonDecode(response4.body) as List;
      print('✅ Buckets encontrados com service key: ${buckets.length}');
      for (var bucket in buckets) {
        print('   - ${bucket['name']} (público: ${bucket['public']})');
      }
    } else {
      print('❌ Erro ao listar buckets com service key: ${response4.statusCode}');
    }
  } catch (e) {
    print('❌ Exceção no Teste 4: $e');
  }

  // Teste 5: Tentar criar bucket user-photos
  print('\n📋 Teste 5: Tentar criar bucket user-photos');
  try {
    final createBucketBody = jsonEncode({
      'id': 'user-photos',
      'name': 'user-photos',
      'public': true,
      'file_size_limit': 52428800, // 50MB
      'allowed_mime_types': ['image/jpeg', 'image/png', 'image/webp']
    });
    
    final response5 = await http.post(
      Uri.parse('$supabaseUrl/storage/v1/bucket'),
      headers: {
        'apikey': supabaseServiceKey,
        'Authorization': 'Bearer $supabaseServiceKey',
        'Content-Type': 'application/json',
      },
      body: createBucketBody,
    );
    
    print('Status Code: ${response5.statusCode}');
    print('Response Body: ${response5.body}');
    
    if (response5.statusCode == 200 || response5.statusCode == 201) {
      print('✅ Bucket user-photos criado com sucesso!');
    } else if (response5.statusCode == 409) {
      print('ℹ️ Bucket user-photos já existe (conflito 409)');
    } else {
      print('❌ Erro ao criar bucket: ${response5.statusCode}');
    }
  } catch (e) {
    print('❌ Exceção no Teste 5: $e');
  }

  // Teste 6: Verificar novamente após tentativa de criação
  print('\n📋 Teste 6: Verificar bucket após tentativa de criação');
  try {
    final response6 = await http.get(
      Uri.parse('$supabaseUrl/storage/v1/bucket/user-photos'),
      headers: {
        'apikey': supabaseServiceKey,
        'Authorization': 'Bearer $supabaseServiceKey',
      },
    );
    
    print('Status Code: ${response6.statusCode}');
    print('Response Body: ${response6.body}');
    
    if (response6.statusCode == 200) {
      final bucketData = jsonDecode(response6.body);
      print('✅ Bucket user-photos confirmado!');
      print('   - ID: ${bucketData['id']}');
      print('   - Nome: ${bucketData['name']}');
      print('   - Público: ${bucketData['public']}');
      print('   - Tamanho máximo: ${bucketData['file_size_limit']}');
      print('   - Tipos permitidos: ${bucketData['allowed_mime_types']}');
    } else {
      print('❌ Bucket ainda não encontrado: ${response6.statusCode}');
    }
  } catch (e) {
    print('❌ Exceção no Teste 6: $e');
  }

  print('\n' + '=' * 60);
  print('🏁 Testes concluídos!');
  print('\n💡 Próximos passos:');
  print('   1. Se o bucket não existir, execute o script SQL setup_user_photos_bucket_no_rls.sql');
  print('   2. Se existir mas não for público, ajuste as configurações');
  print('   3. Teste upload de arquivo real');
}