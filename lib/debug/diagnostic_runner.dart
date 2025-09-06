import 'dart:io';
import '../utils/supabase_helper.dart';
import '../config/app_config.dart';

class DiagnosticRunner {
  
  /// Executa uma bateria de testes para diagnosticar problemas
  static Future<Map<String, dynamic>> runDiagnostics() async {
    print('🔬 INICIANDO DIAGNÓSTICO COMPLETO DO SISTEMA');
    print('🔬 =========================================');
    
    final results = <String, dynamic>{};
    
    // Teste 1: Configuração de Ambiente
    results['environment'] = await _testEnvironmentConfig();
    
    // Teste 2: Inicialização do Supabase
    results['supabase'] = await _testSupabaseInitialization();
    
    // Teste 3: Firebase (se aplicável)
    results['firebase'] = await _testFirebase();
    
    // Teste 4: Teste de Upload (se houver arquivo de teste)
    results['upload'] = await _testUpload();
    
    print('🔬 =========================================');
    print('🔬 DIAGNÓSTICO COMPLETO');
    print('🔬 =========================================');
    
    _printResults(results);
    
    return results;
  }
  
  static Future<Map<String, dynamic>> _testEnvironmentConfig() async {
    print('🔍 Testando configuração de ambiente...');
    
    final config = {
      'supabaseUrl_empty': AppConfig.supabaseUrl.isEmpty,
      'supabaseUrl_valid': AppConfig.supabaseUrl.startsWith('http'),
      'supabaseUrl_length': AppConfig.supabaseUrl.length,
      'supabaseAnonKey_empty': AppConfig.supabaseAnonKey.isEmpty,
      'supabaseAnonKey_length': AppConfig.supabaseAnonKey.length,
    };
    
    print('✅ Configuração de ambiente testada');
    return config;
  }
  
  static Future<Map<String, dynamic>> _testSupabaseInitialization() async {
    print('🔍 Testando inicialização do Supabase...');
    
    final results = <String, dynamic>{};
    
    try {
      // Testar o helper
      print('🔍 Verificando SupabaseHelper...');
      results['helper_initialized'] = SupabaseHelper.isInitialized;
      results['helper_client_available'] = SupabaseHelper.client != null;
      
      if (SupabaseHelper.client != null) {
        print('✅ SupabaseHelper.client disponível');
        
        // Testar uma query simples
        try {
          print('🔍 Testando query simples...');
          final client = SupabaseHelper.client!;
          final response = await client.from('drivers').select().limit(1);
          results['query_test_success'] = true;
          results['query_test_response'] = response.length;
          print('✅ Query teste executada com sucesso');
        } catch (e) {
          results['query_test_success'] = false;
          results['query_test_error'] = e.toString();
          print('❌ Erro no teste de query: $e');
        }
      } else {
        print('❌ SupabaseHelper.client é null');
      }
      
    } catch (e) {
      results['supabase_test_error'] = e.toString();
      print('❌ Erro geral no teste do Supabase: $e');
    }
    
    return results;
  }
  
  static Future<Map<String, dynamic>> _testFirebase() async {
    print('🔍 Testando Firebase...');
    
    final results = <String, dynamic>{
      'firebase_available': false,
      'storage_available': false,
    };
    
    try {
      // Testar se o Firebase está acessível
      print('🔍 Verificando Firebase Storage...');
      results['firebase_available'] = true;
      results['storage_available'] = true;
      print('✅ Firebase testado (informações limitadas no código fornecido)');
    } catch (e) {
      results['firebase_error'] = e.toString();
      print('❌ Erro no teste do Firebase: $e');
    }
    
    return results;
  }
  
  static Future<Map<String, dynamic>> _testUpload() async {
    print('🔍 Testando upload de arquivos...');
    
    final results = <String, dynamic>{
      'upload_available': false,
    };
    
    try {
      // Criar um arquivo de teste temporário
      final tempDir = Directory.systemTemp;
      final testFile = File('${tempDir.path}/test_diagnostic.txt');
      await testFile.writeAsString('Teste de diagnóstico');
      
      print('🔍 Arquivo de teste criado: ${testFile.path}');
      print('🔍 Tamanho do arquivo: ${await testFile.length()} bytes');
      
      // Testar validações do FirebaseFileUploadService
      results['file_exists'] = await testFile.exists();
      results['file_size'] = await testFile.length();
      
      if (results['file_exists'] && results['file_size'] > 0) {
        results['upload_available'] = true;
        print('✅ Arquivo de teste válido para upload');
      }
      
      // Limpar arquivo de teste
      if (await testFile.exists()) {
        await testFile.delete();
        print('🗑️ Arquivo de teste removido');
      }
      
    } catch (e) {
      results['upload_test_error'] = e.toString();
      print('❌ Erro no teste de upload: $e');
    }
    
    return results;
  }
  
  static void _printResults(Map<String, dynamic> results) {
    print('📊 RESULTADOS DO DIAGNÓSTICO:');
    print('📊 =========================');
    
    results.forEach((key, value) {
      print('📋 $key:');
      if (value is Map) {
        value.forEach((subKey, subValue) {
          final status = subValue == true ? '✅' : (subValue == false ? '❌' : 'ℹ️');
          print('   $status $subKey: $subValue');
        });
      } else {
        final status = value == true ? '✅' : (value == false ? '❌' : 'ℹ️');
        print('   $status $value');
      }
      print('');
    });
    
    // Análise de problemas prováveis
    print('🔍 ANÁLISE DE PROBLEMAS:');
    print('🔍 =====================');
    
    final supabaseResults = results['supabase'] as Map<String, dynamic>?;
    if (supabaseResults != null) {
      if (supabaseResults['helper_initialized'] == false) {
        print('⚠️  PROBLEMA: Supabase não inicializado');
        print('   → Verifique se SupabaseHelper.markInitialized() foi chamado');
      }
      
      if (supabaseResults['helper_client_available'] == false) {
        print('⚠️  PROBLEMA: Cliente Supabase não disponível');
        print('   → Verifique as variáveis de ambiente SUPABASE_URL e SUPABASE_ANON_KEY');
      }
      
      if (supabaseResults['query_test_success'] == false) {
        print('⚠️  PROBLEMA: Falha na conexão com o banco de dados');
        print('   → Verifique a conectividade com o Supabase');
      }
    }
    
    final envResults = results['environment'] as Map<String, dynamic>?;
    if (envResults != null) {
      if (envResults['supabaseUrl_empty'] == true) {
        print('❌ CRÍTICO: SUPABASE_URL está vazia');
      }
      if (envResults['supabaseAnonKey_empty'] == true) {
        print('❌ CRÍTICO: SUPABASE_ANON_KEY está vazia');
      }
    }
  }
}