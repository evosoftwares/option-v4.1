import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/config/app_config.dart';

void main() async {
  print('🔧 Testando conectividade do bucket user-photos...');
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
    
    // Teste 1: Verificar se consegue acessar storage
    print('\n🔍 Teste 1: Verificando acesso ao Storage...');
    try {
      final buckets = await client.storage.listBuckets();
      print('✅ Storage acessível! Buckets encontrados: ${buckets.length}');
      
      for (final bucket in buckets) {
        print('   📁 Bucket: ${bucket.id} (público: ${bucket.public})');
      }
      
      // Verificar se user-photos existe
      final userPhotosBucket = buckets.where((b) => b.id == 'user-photos').firstOrNull;
      if (userPhotosBucket != null) {
        print('✅ Bucket user-photos encontrado!');
        print('   📊 Público: ${userPhotosBucket.public}');
        print('   📏 Limite: ${userPhotosBucket.fileSizeLimit} bytes');
        print('   🎭 MIME types: ${userPhotosBucket.allowedMimeTypes}');
      } else {
        print('❌ Bucket user-photos NÃO encontrado!');
        print('💡 Solução: Execute setup_user_photos_bucket_no_rls.sql no Supabase');
      }
      
    } catch (e) {
      print('❌ Erro ao acessar Storage: $e');
      print('🔍 Tipo do erro: ${e.runtimeType}');
    }
    
    // Teste 2: Tentar listar objetos no bucket (se existir)
    print('\n🔍 Teste 2: Verificando objetos no bucket user-photos...');
    try {
      final objects = await client.storage
          .from('user-photos')
          .list();
      print('✅ Bucket user-photos acessível! Objetos: ${objects.length}');
    } catch (e) {
      print('❌ Erro ao acessar bucket user-photos: $e');
      if (e.toString().contains('Bucket not found')) {
        print('💡 Bucket não existe - execute setup_user_photos_bucket_no_rls.sql');
      } else if (e.toString().contains('permission denied')) {
        print('💡 Problema de permissão - verifique políticas RLS');
      }
    }
    
    // Teste 3: Verificar autenticação
    print('\n🔍 Teste 3: Verificando autenticação...');
    final session = client.auth.currentSession;
    if (session != null) {
      print('✅ Usuário autenticado: ${session.user.id}');
    } else {
      print('⚠️  Usuário não autenticado (normal para teste)');
      print('💡 Para upload real, usuário precisa estar logado');
    }
    
    // Teste 4: Simular upload (sem arquivo real)
    print('\n🔍 Teste 4: Simulando upload...');
    try {
      // Tentar obter URL pública (teste de conectividade)
      final publicUrl = client.storage
          .from('user-photos')
          .getPublicUrl('test/test.jpg');
      print('✅ URL pública gerada: ${publicUrl.substring(0, 50)}...');
    } catch (e) {
      print('❌ Erro ao gerar URL pública: $e');
    }
    
    print('\n📋 RESUMO DO DIAGNÓSTICO:');
    print('=' * 50);
    
  } catch (e) {
    print('❌ Erro crítico: $e');
    print('🔍 Tipo do erro: ${e.runtimeType}');
    
    if (e.toString().contains('Failed host lookup')) {
      print('🌐 Problema de DNS/Conectividade detectado');
      print('💡 Possíveis soluções:');
      print('   1. Verificar conexão com internet');
      print('   2. Verificar URL do Supabase em app_config.dart');
      print('   3. Limpar cache: flutter clean');
    } else if (e.toString().contains('Invalid API key')) {
      print('🔑 Problema com a chave de API');
      print('💡 Verificar supabaseAnonKey em app_config.dart');
    }
  }
  
  print('\n🏁 Teste concluído!');
}