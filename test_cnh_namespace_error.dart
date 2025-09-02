import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

// Script para testar e diagnosticar o erro "Operação não suportada no namespace CNH"
void main() async {
  // Configuração do Supabase
  const supabaseUrl = 'https://qlbwacmavngtonauxnte.supabase.co';
  const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E';

  try {
    // Inicializar Supabase
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    final supabase = Supabase.instance.client;
    
    print('✅ Supabase inicializado com sucesso');
    
    // Teste 1: Verificar se o bucket driver-documents existe
    print('\n🔍 Teste 1: Verificando bucket driver-documents...');
    try {
      final buckets = await supabase.storage.listBuckets();
      final driverDocsBucket = buckets.where((b) => b.id == 'driver-documents').firstOrNull;
      
      if (driverDocsBucket != null) {
        print('✅ Bucket driver-documents encontrado:');
        print('   - ID: ${driverDocsBucket.id}');
        print('   - Nome: ${driverDocsBucket.name}');
        print('   - Público: ${driverDocsBucket.public}');
        print('   - Limite de tamanho: ${driverDocsBucket.fileSizeLimit}');
        print('   - Tipos MIME: ${driverDocsBucket.allowedMimeTypes}');
      } else {
        print('❌ Bucket driver-documents NÃO encontrado!');
        print('📋 Buckets disponíveis:');
        for (final bucket in buckets) {
          print('   - ${bucket.id} (${bucket.name})');
        }
      }
    } catch (e) {
      print('❌ Erro ao listar buckets: $e');
    }
    
    // Teste 2: Tentar fazer upload de um arquivo de teste
    print('\n🔍 Teste 2: Testando upload no bucket driver-documents...');
    try {
      final testContent = 'Teste de upload - ${DateTime.now().toIso8601String()}';
      final testPath = 'test/cnh_test_${DateTime.now().millisecondsSinceEpoch}.txt';
      
      final result = await supabase.storage
          .from('driver-documents')
          .uploadBinary(testPath, testContent.codeUnits);
      
      print('✅ Upload de teste realizado com sucesso:');
      print('   - Path: $testPath');
      print('   - Result: $result');
      
      // Limpar arquivo de teste
      await supabase.storage.from('driver-documents').remove([testPath]);
      print('✅ Arquivo de teste removido');
      
    } catch (e) {
      print('❌ Erro no upload de teste: $e');
      print('   - Tipo do erro: ${e.runtimeType}');
      if (e is StorageException) {
        print('   - Código de status: ${e.statusCode}');
        print('   - Mensagem: ${e.message}');
        print('   - Erro: ${e.error}');
      }
    }
    
    // Teste 3: Verificar políticas RLS
    print('\n🔍 Teste 3: Verificando políticas RLS...');
    try {
      final policies = await supabase
          .from('pg_policies')
          .select('*')
          .eq('schemaname', 'storage')
          .eq('tablename', 'objects');
      
      if (policies.isEmpty) {
        print('✅ Nenhuma política RLS encontrada para storage.objects');
      } else {
        print('📋 Políticas RLS encontradas:');
        for (final policy in policies) {
          print('   - ${policy['policyname']}: ${policy['cmd']}');
        }
      }
    } catch (e) {
      print('❌ Erro ao verificar políticas RLS: $e');
    }
    
    // Teste 4: Verificar configuração de RLS
    print('\n🔍 Teste 4: Verificando status RLS...');
    try {
      final rlsStatus = await supabase.rpc('check_rls_status');
      print('📋 Status RLS: $rlsStatus');
    } catch (e) {
      print('⚠️ Não foi possível verificar status RLS: $e');
    }
    
  } catch (e) {
    print('❌ Erro geral: $e');
    print('   - Tipo do erro: ${e.runtimeType}');
  }
}

// Extensão para firstOrNull
extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}