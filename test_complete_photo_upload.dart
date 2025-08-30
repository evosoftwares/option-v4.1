import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Configurações do Supabase
const String supabaseUrl = 'https://qlbwacmavngtonauxnte.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E';
const String supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk';

void main() async {
  print('🧪 TESTE COMPLETO DE UPLOAD DE FOTO DE USUÁRIO');
  print('=' * 60);
  
  // Criar dados de teste
  final testData = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final fileName = 'profile_photos/test_complete_$timestamp.png';
  
  // Teste 1: Verificar se bucket existe
  print('\n📋 Teste 1: Verificando existência do bucket...');
  await testBucketExists();
  
  // Teste 2: Upload com chave anônima
  print('\n📋 Teste 2: Upload com chave anônima...');
  final anonResult = await testUpload(fileName, testData, supabaseAnonKey, 'anônima');
  
  // Teste 3: Upload com chave de serviço
  print('\n📋 Teste 3: Upload com chave de serviço...');
  final serviceResult = await testUpload('${fileName}_service', testData, supabaseServiceKey, 'serviço');
  
  // Teste 4: Testar URLs públicas
  print('\n📋 Teste 4: Testando URLs públicas...');
  if (anonResult != null) {
    await testPublicUrl(anonResult);
  }
  if (serviceResult != null) {
    await testPublicUrl(serviceResult);
  }
  
  // Teste 5: Listar arquivos
  print('\n📋 Teste 5: Listando arquivos no bucket...');
  await testListFiles();
  
  // Teste 6: Testar diferentes tipos MIME
  print('\n📋 Teste 6: Testando tipos MIME suportados...');
  await testMimeTypes();
  
  // Resumo final
  print('\n' + '=' * 60);
  print('🏁 TESTE COMPLETO CONCLUÍDO!');
  print('=' * 60);
}

Future<void> testBucketExists() async {
  try {
    final response = await http.get(
      Uri.parse('$supabaseUrl/storage/v1/bucket/user-photos'),
      headers: {
        'Authorization': 'Bearer $supabaseAnonKey',
        'apikey': supabaseAnonKey,
      },
    );
    
    print('   Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      print('   ✅ Bucket user-photos existe!');
      final data = json.decode(response.body);
      print('   📊 Configurações: ${data}');
    } else {
      print('   ❌ Bucket não encontrado ou inacessível');
      print('   📄 Response: ${response.body}');
    }
  } catch (e) {
    print('   ❌ Erro ao verificar bucket: $e');
  }
}

Future<String?> testUpload(String fileName, Uint8List data, String apiKey, String keyType) async {
  try {
    final response = await http.post(
      Uri.parse('$supabaseUrl/storage/v1/object/user-photos/$fileName'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'apikey': apiKey,
        'Content-Type': 'image/png',
        'x-upsert': 'true',
      },
      body: data,
    );
    
    print('   🔄 Upload com chave $keyType:');
    print('   - Arquivo: $fileName');
    print('   - Tamanho: ${data.length} bytes');
    print('   - Status: ${response.statusCode}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('   ✅ Upload realizado com sucesso!');
      final publicUrl = '$supabaseUrl/storage/v1/object/public/user-photos/$fileName';
      print('   🔗 URL Pública: $publicUrl');
      return publicUrl;
    } else {
      print('   ❌ Falha no upload');
      print('   📄 Response: ${response.body}');
      return null;
    }
  } catch (e) {
    print('   ❌ Erro no upload: $e');
    return null;
  }
}

Future<void> testPublicUrl(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    print('   🔗 Testando URL: $url');
    print('   - Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      print('   ✅ URL pública acessível!');
      print('   📊 Content-Type: ${response.headers['content-type']}');
      print('   📊 Content-Length: ${response.headers['content-length']}');
    } else {
      print('   ❌ URL não acessível');
      print('   📄 Response: ${response.body}');
    }
  } catch (e) {
    print('   ❌ Erro ao acessar URL: $e');
  }
}

Future<void> testListFiles() async {
  try {
    final response = await http.get(
      Uri.parse('$supabaseUrl/storage/v1/object/list/user-photos'),
      headers: {
        'Authorization': 'Bearer $supabaseAnonKey',
        'apikey': supabaseAnonKey,
      },
    );
    
    print('   🔄 Listando arquivos...');
    print('   - Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final files = json.decode(response.body);
      print('   ✅ Listagem realizada com sucesso!');
      print('   📊 Arquivos encontrados: ${files.length}');
      if (files.isNotEmpty) {
        print('   📁 Primeiros arquivos:');
        for (int i = 0; i < (files.length > 3 ? 3 : files.length); i++) {
          print('      - ${files[i]['name']}');
        }
      }
    } else {
      print('   ❌ Falha na listagem');
      print('   📄 Response: ${response.body}');
    }
  } catch (e) {
    print('   ❌ Erro na listagem: $e');
  }
}

Future<void> testMimeTypes() async {
  final mimeTypes = {
    'image/jpeg': [255, 216, 255, 224], // JPEG header
    'image/png': [137, 80, 78, 71], // PNG header
    'image/webp': [82, 73, 70, 70], // WEBP header
  };
  
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  
  for (final entry in mimeTypes.entries) {
    final mimeType = entry.key;
    final header = entry.value;
    final extension = mimeType.split('/')[1];
    final fileName = 'mime_test/test_$timestamp.$extension';
    
    try {
      final response = await http.post(
        Uri.parse('$supabaseUrl/storage/v1/object/user-photos/$fileName'),
        headers: {
          'Authorization': 'Bearer $supabaseAnonKey',
          'apikey': supabaseAnonKey,
          'Content-Type': mimeType,
          'x-upsert': 'true',
        },
        body: Uint8List.fromList(header + [0, 0, 0, 0]), // Adicionar alguns bytes
      );
      
      print('   🧪 Testando $mimeType:');
      print('   - Arquivo: $fileName');
      print('   - Status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('   ✅ MIME type suportado!');
      } else {
        print('   ❌ MIME type rejeitado');
        print('   📄 Response: ${response.body}');
      }
    } catch (e) {
      print('   ❌ Erro ao testar $mimeType: $e');
    }
  }
}