import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  try {
    // Lê variáveis de ambiente do arquivo .env
    final envFile = File('.env');
    if (!envFile.existsSync()) {
      print('❌ Arquivo .env não encontrado');
      exit(1);
    }
    
    final envContent = await envFile.readAsString();
    final envLines = envContent.split('\n');
    
    String? supabaseUrl;
    String? supabaseAnonKey;
    
    for (final line in envLines) {
      if (line.startsWith('SUPABASE_URL=')) {
        supabaseUrl = line.substring('SUPABASE_URL='.length).trim();
      } else if (line.startsWith('SUPABASE_ANON_KEY=')) {
        supabaseAnonKey = line.substring('SUPABASE_ANON_KEY='.length).trim();
      }
    }
    
    if (supabaseUrl == null || supabaseAnonKey == null) {
      print('❌ Variáveis SUPABASE_URL ou SUPABASE_ANON_KEY não encontradas no .env');
      exit(1);
    }
    
    print('🔧 Inicializando Supabase...');
    final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);
    print('✅ Supabase inicializado');
    
    // Teste 1: Verificar usuários na tabela app_users
    print('\n🔍 Teste 1: Verificando usuários na tabela app_users...');
    try {
      final appUsersResponse = await supabase
          .from('app_users')
          .select('id, email, full_name')
          .limit(5);
      print('✅ Usuários app encontrados: ${appUsersResponse.length}');
      if (appUsersResponse.isNotEmpty) {
        print('📋 Primeiro usuário app: ${appUsersResponse.first}');
        
        // Teste 2: Usar um ID real para testar notificações
        final realUserId = appUsersResponse.first['id'];
        print('\n🔍 Teste 2: Testando notificações com ID real: $realUserId');
        
        final notificationsResponse = await supabase
            .from('notifications')
            .select('*')
            .eq('user_id', realUserId)
            .limit(5);
        print('✅ Notificações encontradas: ${notificationsResponse.length}');
        if (notificationsResponse.isNotEmpty) {
          print('📋 Primeira notificação: ${notificationsResponse.first}');
        }
      } else {
        print('⚠️ Nenhum usuário encontrado na tabela app_users');
      }
    } catch (e) {
      print('❌ Erro ao acessar app_users: $e');
    }
    
    // Teste 3: Verificar estrutura da tabela notifications
    print('\n🔍 Teste 3: Verificando estrutura da tabela notifications...');
    try {
      final notificationsStructure = await supabase
          .from('notifications')
          .select('*')
          .limit(1);
      print('✅ Estrutura da tabela notifications acessível');
      if (notificationsStructure.isNotEmpty) {
        print('📋 Campos disponíveis: ${notificationsStructure.first.keys.toList()}');
      } else {
        print('⚠️ Tabela notifications está vazia');
      }
    } catch (e) {
      print('❌ Erro ao verificar estrutura notifications: $e');
    }
    
    // Teste 4: Verificar se há notificações em geral
    print('\n🔍 Teste 4: Verificando todas as notificações...');
    try {
      final allNotifications = await supabase
          .from('notifications')
          .select('id, user_id, title')
          .limit(10);
      print('✅ Total de notificações na base: ${allNotifications.length}');
      if (allNotifications.isNotEmpty) {
        print('📋 Primeiras notificações: $allNotifications');
      }
    } catch (e) {
      print('❌ Erro ao buscar todas as notificações: $e');
    }
    
    print('\n🎯 Teste concluído!');
    
  } catch (e) {
    print('❌ Erro geral: $e');
    exit(1);
  }
}