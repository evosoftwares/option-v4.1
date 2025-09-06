import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Iniciando diagnóstico do travamento do botão IR...');
  
  final supabaseUrl = Platform.environment['SUPABASE_URL'];
  final supabaseKey = Platform.environment['SUPABASE_ANON_KEY'];
  
  if (supabaseUrl == null || supabaseKey == null) {
    print('❌ Variáveis de ambiente não configuradas');
    print('SUPABASE_URL: $supabaseUrl');
    print('SUPABASE_ANON_KEY: ${supabaseKey?.substring(0, 20)}...');
    return;
  }
  
  print('✅ Variáveis de ambiente configuradas');
  print('URL: $supabaseUrl');
  print('Key: ${supabaseKey.substring(0, 20)}...');
  
  // Teste 1: Conectividade básica com Supabase
  await testSupabaseConnection(supabaseUrl, supabaseKey);
  
  // Teste 2: Verificar tabelas críticas
  await testCriticalTables(supabaseUrl, supabaseKey);
  
  // Teste 3: Simular consultas do botão IR
  await simulateGoButtonQueries(supabaseUrl, supabaseKey);
}

Future<void> testSupabaseConnection(String url, String key) async {
  print('\n🔗 Testando conectividade com Supabase...');
  
  try {
    final response = await http.get(
      Uri.parse('$url/rest/v1/'),
      headers: {
        'apikey': key,
        'Authorization': 'Bearer $key',
      },
    ).timeout(Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      print('✅ Conexão com Supabase OK');
    } else {
      print('❌ Erro na conexão: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Erro de conectividade: $e');
  }
}

Future<void> testCriticalTables(String url, String key) async {
  print('\n📊 Verificando tabelas críticas...');
  
  final tables = ['drivers', 'driver_documents', 'working_hours', 'app_users'];
  
  for (final table in tables) {
    try {
      print('Testando tabela: $table');
      
      final response = await http.get(
        Uri.parse('$url/rest/v1/$table?select=count'),
        headers: {
          'apikey': key,
          'Authorization': 'Bearer $key',
          'Prefer': 'count=exact',
        },
      ).timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final count = response.headers['content-range']?.split('/').last ?? 'unknown';
        print('✅ $table: $count registros');
      } else {
        print('❌ $table: Erro ${response.statusCode}');
      }
    } catch (e) {
      print('❌ $table: Timeout ou erro - $e');
    }
  }
}

Future<void> simulateGoButtonQueries(String url, String key) async {
  print('\n🎯 Simulando consultas do botão IR...');
  
  // Simular busca de motorista (substitua por um ID real se disponível)
  await testDriverQuery(url, key);
  
  // Simular verificação de documentos
  await testDocumentQuery(url, key);
  
  // Simular verificação de horários
  await testWorkingHoursQuery(url, key);
}

Future<void> testDriverQuery(String url, String key) async {
  print('\n👤 Testando consulta de motoristas...');
  
  try {
    final response = await http.get(
      Uri.parse('$url/rest/v1/drivers?select=id,is_online,approval_status&limit=5'),
      headers: {
        'apikey': key,
        'Authorization': 'Bearer $key',
      },
    ).timeout(Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      print('✅ Consulta de motoristas OK - ${data.length} registros');
      
      if (data.isNotEmpty) {
        final driver = data.first;
        print('Exemplo: ID=${driver['id']}, Online=${driver['is_online']}, Status=${driver['approval_status']}');
      }
    } else {
      print('❌ Erro na consulta de motoristas: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Timeout na consulta de motoristas: $e');
  }
}

Future<void> testDocumentQuery(String url, String key) async {
  print('\n📄 Testando consulta de documentos...');
  
  try {
    final response = await http.get(
      Uri.parse('$url/rest/v1/driver_documents?select=id,driver_id,document_type,status&limit=5'),
      headers: {
        'apikey': key,
        'Authorization': 'Bearer $key',
      },
    ).timeout(Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      print('✅ Consulta de documentos OK - ${data.length} registros');
    } else {
      print('❌ Erro na consulta de documentos: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Timeout na consulta de documentos: $e');
  }
}

Future<void> testWorkingHoursQuery(String url, String key) async {
  print('\n⏰ Testando consulta de horários...');
  
  try {
    final response = await http.get(
      Uri.parse('$url/rest/v1/working_hours?select=id,driver_id,day_of_week,start_time,end_time&limit=5'),
      headers: {
        'apikey': key,
        'Authorization': 'Bearer $key',
      },
    ).timeout(Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      print('✅ Consulta de horários OK - ${data.length} registros');
    } else {
      print('❌ Erro na consulta de horários: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Timeout na consulta de horários: $e');
  }
}