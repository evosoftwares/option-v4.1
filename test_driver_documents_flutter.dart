import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/config/app_config.dart';

void main() async {
  print('🔧 Testando bucket driver-documents no Flutter...');
  print('🌐 URL: ${AppConfig.supabaseUrl}');
  print('🔑 Key: ${AppConfig.supabaseAnonKey.substring(0, 20)}...');
  
  try {
    // Inicializar Supabase
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    
    print('✅ Supabase inicializado com sucesso!');
    
    final client = Supabase.instance.client;
    
    // Teste 1: Listar todos os buckets
    print('\n🔍 Teste 1: Listando buckets disponíveis...');
    try {
      final buckets = await client.storage.listBuckets();
      print('✅ Storage acessível! Buckets encontrados: ${buckets.length}');
      
      for (final bucket in buckets) {
        print('   📁 Bucket: ${bucket.id} (público: ${bucket.public})');
        if (bucket.fileSizeLimit != null) {
          print('      📏 Limite: ${bucket.fileSizeLimit} bytes');
        }
        if (bucket.allowedMimeTypes != null && bucket.allowedMimeTypes!.isNotEmpty) {
          print('      🎭 MIME types: ${bucket.allowedMimeTypes}');
        }
      }
      
      // Verificar se driver-documents existe
      final driverDocsBucket = buckets.where((b) => b.id == 'driver-documents').firstOrNull;
      if (driverDocsBucket != null) {
        print('\n✅ Bucket driver-documents encontrado!');
        print('   📊 Público: ${driverDocsBucket.public}');
        print('   📏 Limite: ${driverDocsBucket.fileSizeLimit} bytes');
        print('   🎭 MIME types: ${driverDocsBucket.allowedMimeTypes}');
        
        // Teste 2: Tentar listar arquivos no bucket
        print('\n🔍 Teste 2: Tentando listar arquivos no bucket...');
        try {
          final files = await client.storage.from('driver-documents').list();
          print('✅ Bucket acessível! Arquivos encontrados: ${files.length}');
          
          if (files.isNotEmpty) {
            for (final file in files.take(5)) {
              print('   📄 Arquivo: ${file.name} (${file.metadata?['size'] ?? 'tamanho desconhecido'})');
            }
          } else {
            print('   📭 Bucket vazio (normal para novo bucket)');
          }
          
        } catch (e) {
          print('❌ Erro ao listar arquivos: $e');
          print('🔍 Tipo do erro: ${e.runtimeType}');
          
          if (e.toString().contains('Bucket not found')) {
            print('💡 O bucket existe na listagem mas não é acessível para listagem');
            print('   Isso pode indicar problema de permissões ou configuração RLS');
          }
        }
        
      } else {
        print('❌ Bucket driver-documents NÃO encontrado!');
        print('💡 Buckets disponíveis:');
        for (final bucket in buckets) {
          print('   - ${bucket.id}');
        }
      }
      
    } catch (e) {
      print('❌ Erro ao acessar storage: $e');
      print('🔍 Tipo do erro: ${e.runtimeType}');
    }
    
  } catch (e) {
    print('❌ Erro geral: $e');
    print('🔍 Tipo do erro: ${e.runtimeType}');
  }
}