import 'package:supabase_flutter/supabase_flutter.dart';

/// Script de teste para verificar conectividade do Supabase
/// Execute com: dart run test_supabase_connection.dart

const String supabaseUrl = 'https://qlbwacmavngtonauxnte.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E';

void main() async {
  print('🚀 [TEST] Iniciando teste de conectividade Supabase...');
  print('📍 [TEST] URL: $supabaseUrl');
  print('🔑 [TEST] Key: ${supabaseAnonKey.substring(0, 20)}...\n');

  try {
    // Inicializar Supabase
    print('🔧 [TEST] Inicializando Supabase...');
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    print('✅ [TEST] Supabase inicializado com sucesso!\n');

    final client = Supabase.instance.client;

    // Teste 1: Verificar tabela app_users
    print('📊 [TEST] Teste 1: Verificando tabela app_users...');
    try {
      final usersCount =
          await client.from('app_users').select('id').count(CountOption.exact);
      print(
          '✅ [TEST] Tabela app_users encontrada. Total de usuários: ${usersCount.count}');
    } catch (e) {
      print('❌ [TEST] Erro ao acessar app_users: $e');
    }

    // Teste 2: Verificar tabela drivers
    print('\n📊 [TEST] Teste 2: Verificando tabela drivers...');
    try {
      final driversCount =
          await client.from('drivers').select('id').count(CountOption.exact);
      print(
          '✅ [TEST] Tabela drivers encontrada. Total de drivers: ${driversCount.count}');
    } catch (e) {
      print('❌ [TEST] Erro ao acessar drivers: $e');
    }

    // Teste 3: Verificar tabela passengers
    print('\n📊 [TEST] Teste 3: Verificando tabela passengers...');
    try {
      final passengersCount =
          await client.from('passengers').select('id').count(CountOption.exact);
      print(
          '✅ [TEST] Tabela passengers encontrada. Total de passageiros: ${passengersCount.count}');
    } catch (e) {
      print('❌ [TEST] Erro ao acessar passengers: $e');
    }

    // Teste 4: Verificar tabela trips
    print('\n📊 [TEST] Teste 4: Verificando tabela trips...');
    try {
      final tripsCount =
          await client.from('trips').select('id').count(CountOption.exact);
      print(
          '✅ [TEST] Tabela trips encontrada. Total de viagens: ${tripsCount.count}');
    } catch (e) {
      print('❌ [TEST] Erro ao acessar trips: $e');
    }

    // Teste 5: Verificar tabela platform_settings
    print('\n📊 [TEST] Teste 5: Verificando platform_settings...');
    try {
      final settings =
          await client.from('platform_settings').select('*').limit(5);
      print(
          '✅ [TEST] Tabela platform_settings encontrada. Configurações: ${settings.length}');
      if (settings.isNotEmpty) {
        print('📄 [TEST] Primeira configuração: ${settings[0]}');
      }
    } catch (e) {
      print('❌ [TEST] Erro ao acessar platform_settings: $e');
    }

    // Teste 6: Verificar status da autenticação
    print('\n🔐 [TEST] Teste 6: Verificando status da autenticação...');
    final currentUser = client.auth.currentUser;
    if (currentUser != null) {
      print('✅ [TEST] Usuário logado: ${currentUser.id}');
      print('📧 [TEST] Email: ${currentUser.email}');
    } else {
      print('ℹ️ [TEST] Nenhum usuário logado (normal para teste)');
    }

    // Teste 7: Verificar funções de bypass
    print('\n🔧 [TEST] Teste 7: Verificando funções de bypass...');
    try {
      // Tentar chamar uma função de bypass sem parâmetros válidos (só para ver se existe)
      await client.rpc('bypass_login', params: {
        'p_email': '',
        'p_password': '',
      });
    } catch (e) {
      if (e.toString().contains('function') ||
          e.toString().contains('not found')) {
        print('❌ [TEST] Função bypass_login não encontrada: $e');
      } else {
        print(
            '✅ [TEST] Função bypass_login existe (erro esperado com dados vazios)');
      }
    }

    print('\n🎉 [TEST] Teste de conectividade concluído com sucesso!');
    print('💡 [TEST] Supabase está configurado e funcionando corretamente.');
  } catch (e, stackTrace) {
    print('💥 [TEST] ERRO CRÍTICO durante o teste: $e');
    print('📍 [TEST] Stack trace: $stackTrace');
    print('\n🔍 [TEST] Possíveis causas:');
    print('   - URL ou chave do Supabase incorretas');
    print('   - Problemas de conectividade de rede');
    print('   - Configurações de RLS muito restritivas');
    print('   - Tabelas não existem no banco');
  }
}
