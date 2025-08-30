import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Teste real de upload para o bucket user-photos
void main() async {
  // Credenciais do Supabase
  const String supabaseUrl = 'https://qlbwacmavngtonauxnte.supabase.co';
  const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E';
  const String supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk';

  print('🔍 Testando upload real para bucket user-photos...');
  print('=' * 60);

  // Criar uma imagem de teste simples (1x1 pixel PNG)
  final testImageBytes = _createTestPngImage();
  final fileName = 'test_upload_${DateTime.now().millisecondsSinceEpoch}.png';
  final filePath = 'profile_photos/$fileName';

  print('\n📋 Teste 1: Upload com chave anônima');
  await _testUpload(
    supabaseUrl,
    supabaseAnonKey,
    'user-photos',
    filePath,
    testImageBytes,
    'Chave Anônima',
  );

  print('\n📋 Teste 2: Upload com chave de serviço');
  await _testUpload(
    supabaseUrl,
    supabaseServiceKey,
    'user-photos',
    filePath + '_service',
    testImageBytes,
    'Chave de Serviço',
  );

  print('\n📋 Teste 3: Listar arquivos no bucket');
  await _listFiles(supabaseUrl, supabaseServiceKey, 'user-photos');

  print('\n📋 Teste 4: Obter URL pública');
  await _getPublicUrl(supabaseUrl, supabaseAnonKey, 'user-photos', filePath);

  print('\n' + '=' * 60);
  print('🏁 Testes de upload concluídos!');
}

/// Cria uma imagem PNG de teste (1x1 pixel transparente)
Uint8List _createTestPngImage() {
  // PNG de 1x1 pixel transparente (67 bytes)
  return Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 dimensions
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, // RGBA, no compression
    0x89, 0x00, 0x00, 0x00, 0x0B, 0x49, 0x44, 0x41, // IDAT chunk
    0x54, 0x78, 0x9C, 0x62, 0x00, 0x02, 0x00, 0x00, // compressed data
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, // end of IDAT
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, // IEND chunk
    0x42, 0x60, 0x82
  ]);
}

/// Testa upload de arquivo
Future<void> _testUpload(
  String supabaseUrl,
  String apiKey,
  String bucketName,
  String filePath,
  Uint8List fileBytes,
  String keyType,
) async {
  try {
    print('\n🔄 Fazendo upload com $keyType...');
    print('   - Arquivo: $filePath');
    print('   - Tamanho: ${fileBytes.length} bytes');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$supabaseUrl/storage/v1/object/$bucketName/$filePath'),
    );

    request.headers.addAll({
      'apikey': apiKey,
      'Authorization': 'Bearer $apiKey',
    });

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: filePath.split('/').last,
        contentType: MediaType('image', 'png'),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('   - Status Code: ${response.statusCode}');
    print('   - Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('   ✅ Upload realizado com sucesso!');
      
      // Tentar obter a URL pública
      final publicUrl = '$supabaseUrl/storage/v1/object/public/$bucketName/$filePath';
      print('   - URL Pública: $publicUrl');
      
      // Verificar se a URL pública funciona
      final urlTest = await http.get(Uri.parse(publicUrl));
      print('   - Teste URL Pública: ${urlTest.statusCode}');
      
      if (urlTest.statusCode == 200) {
        print('   ✅ URL pública acessível!');
      } else {
        print('   ❌ URL pública não acessível');
      }
    } else {
      print('   ❌ Erro no upload: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        try {
          final errorData = jsonDecode(response.body);
          print('   - Erro: ${errorData['message'] ?? errorData['error'] ?? 'Desconhecido'}');
        } catch (e) {
          print('   - Erro raw: ${response.body}');
        }
      }
    }
  } catch (e) {
    print('   ❌ Exceção durante upload: $e');
  }
}

/// Lista arquivos no bucket
Future<void> _listFiles(
  String supabaseUrl,
  String apiKey,
  String bucketName,
) async {
  try {
    print('\n🔄 Listando arquivos no bucket $bucketName...');

    final response = await http.get(
      Uri.parse('$supabaseUrl/storage/v1/object/list/$bucketName'),
      headers: {
        'apikey': apiKey,
        'Authorization': 'Bearer $apiKey',
      },
    );

    print('   - Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final files = jsonDecode(response.body) as List;
      print('   ✅ Arquivos encontrados: ${files.length}');
      
      for (var file in files.take(10)) { // Mostrar apenas os primeiros 10
        print('     - ${file['name']} (${file['metadata']?['size'] ?? 'N/A'} bytes)');
      }
      
      if (files.length > 10) {
        print('     ... e mais ${files.length - 10} arquivos');
      }
    } else {
      print('   ❌ Erro ao listar arquivos: ${response.statusCode}');
      print('   - Response: ${response.body}');
    }
  } catch (e) {
    print('   ❌ Exceção ao listar arquivos: $e');
  }
}

/// Testa obtenção de URL pública
Future<void> _getPublicUrl(
  String supabaseUrl,
  String apiKey,
  String bucketName,
  String filePath,
) async {
  try {
    print('\n🔄 Testando URL pública...');
    
    final publicUrl = '$supabaseUrl/storage/v1/object/public/$bucketName/$filePath';
    print('   - URL: $publicUrl');
    
    final response = await http.get(Uri.parse(publicUrl));
    print('   - Status Code: ${response.statusCode}');
    print('   - Content-Type: ${response.headers['content-type']}');
    print('   - Content-Length: ${response.headers['content-length']}');
    
    if (response.statusCode == 200) {
      print('   ✅ URL pública funcionando!');
    } else {
      print('   ❌ URL pública não acessível');
      print('   - Response: ${response.body}');
    }
  } catch (e) {
    print('   ❌ Exceção ao testar URL pública: $e');
  }
}