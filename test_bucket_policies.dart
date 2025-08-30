import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Configurações do Supabase
const String supabaseUrl = 'https://qlbwacmavngtonauxnte.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E';
const String bucketName = 'user-photos';

void main() async {
  print('🧪 Testando políticas do bucket user-photos...');
  print('=' * 50);
  
  await testBucketAccess();
  await testAnonymousUpload();
  await testPublicRead();
  
  print('\n' + '=' * 50);
  print('✅ Teste de políticas concluído!');
}

Future<void> testBucketAccess() async {
  print('\n📋 1. Testando acesso ao bucket...');
  
  try {
    final response = await http.get(
      Uri.parse('$supabaseUrl/storage/v1/bucket/$bucketName'),
      headers: {
        'Authorization': 'Bearer $supabaseAnonKey',
        'apikey': supabaseAnonKey,
      },
    );
    
    print('Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final bucket = json.decode(response.body);
      print('✅ Bucket encontrado: ${bucket['name']}');
      print('   Público: ${bucket['public']}');
      print('   Limite: ${bucket['file_size_limit']} bytes');
    } else {
      print('❌ Erro ao acessar bucket: ${response.body}');
    }
  } catch (e) {
    print('❌ Erro de conexão: $e');
  }
}

Future<void> testAnonymousUpload() async {
  print('\n📤 2. Testando upload anônimo...');
  
  // Criar um arquivo de teste simples
  final testData = Uint8List.fromList('Test image data for policies'.codeUnits);
  final fileName = 'test-policies-${DateTime.now().millisecondsSinceEpoch}.txt';
  
  try {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$supabaseUrl/storage/v1/object/$bucketName/$fileName'),
    );
    
    request.headers.addAll({
      'Authorization': 'Bearer $supabaseAnonKey',
      'apikey': supabaseAnonKey,
    });
    
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        testData,
        filename: fileName,
      ),
    );
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    print('Status: ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ Upload anônimo bem-sucedido!');
      print('   Arquivo: $fileName');
      
      // Testar URL pública
      await testPublicUrl(fileName);
      
      // Limpar arquivo de teste
      await deleteTestFile(fileName);
    } else {
      print('❌ Erro no upload: ${response.body}');
    }
  } catch (e) {
    print('❌ Erro de upload: $e');
  }
}

Future<void> testPublicUrl(String fileName) async {
  print('\n🌐 3. Testando URL pública...');
  
  final publicUrl = '$supabaseUrl/storage/v1/object/public/$bucketName/$fileName';
  print('URL: $publicUrl');
  
  try {
    final response = await http.get(Uri.parse(publicUrl));
    
    print('Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      print('✅ URL pública acessível!');
      print('   Conteúdo: ${response.body}');
    } else {
      print('❌ Erro ao acessar URL pública: ${response.body}');
    }
  } catch (e) {
    print('❌ Erro de acesso: $e');
  }
}

Future<void> testPublicRead() async {
  print('\n📖 4. Testando listagem pública...');
  
  try {
    final response = await http.get(
      Uri.parse('$supabaseUrl/storage/v1/object/list/$bucketName'),
      headers: {
        'Authorization': 'Bearer $supabaseAnonKey',
        'apikey': supabaseAnonKey,
      },
    );
    
    print('Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final files = json.decode(response.body);
      print('✅ Listagem bem-sucedida!');
      print('   Arquivos encontrados: ${files.length}');
      if (files.isNotEmpty) {
        print('   Primeiro arquivo: ${files[0]['name']}');
      }
    } else {
      print('❌ Erro na listagem: ${response.body}');
    }
  } catch (e) {
    print('❌ Erro de listagem: $e');
  }
}

Future<void> deleteTestFile(String fileName) async {
  print('\n🗑️ Limpando arquivo de teste...');
  
  try {
    final response = await http.delete(
      Uri.parse('$supabaseUrl/storage/v1/object/$bucketName/$fileName'),
      headers: {
        'Authorization': 'Bearer $supabaseAnonKey',
        'apikey': supabaseAnonKey,
      },
    );
    
    if (response.statusCode == 200) {
      print('✅ Arquivo de teste removido');
    } else {
      print('⚠️ Não foi possível remover arquivo de teste: ${response.body}');
    }
  } catch (e) {
    print('⚠️ Erro ao remover arquivo: $e');
  }
}