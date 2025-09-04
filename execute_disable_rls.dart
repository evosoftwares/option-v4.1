import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

void main() async {
  // Configurações do Supabase
  const supabaseUrl = 'https://qlbwacmavngtonauxnte.supabase.co';
  const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwODcxNjMzMiwiZXhwIjoyMDI0MjkyMzMyfQ.F9hqR7khKEprPzy72MoipXfrq5tympkIHYkiuf8efNk';
  
  print('🔒 [RLS] Iniciando desativação de todas as políticas RLS...');
  
  // Inicializar Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: serviceRoleKey, // Usando service role key como anon key para ter privilégios
  );
  
  final supabase = Supabase.instance.client;
  
  // Lista de tabelas para desabilitar RLS
  final tables = [
    'app_users',
    'drivers', 
    'passengers',
    'trips',
    'trip_requests',
    'driver_wallets',
    'passenger_wallets', 
    'wallet_transactions',
    'passenger_wallet_transactions',
    'payment_methods',
    'notifications',
    'favorite_locations',
    'driver_schedules',
    'working_hours',
    'driver_excluded_zones',
    'locations',
    'auth_sync_logs',
    'sync_control',
  ];
  
  print('\n📋 Tabelas a serem processadas: ${tables.length}');
  
  // Desabilitar RLS em cada tabela
  for (int i = 0; i < tables.length; i++) {
    final table = tables[i];
    print('\n📝 [${i + 1}/${tables.length}] Processando tabela: $table');
    
    try {
      // Tentar desabilitar RLS usando uma função RPC personalizada
      await supabase.rpc('disable_rls_for_table', params: {
        'table_name': table,
      });
      print('✅ RLS desabilitado para $table');
    } catch (e) {
      print('⚠️ Erro ao desabilitar RLS para $table: $e');
      // Continuar mesmo com erros, pois algumas tabelas podem não existir
    }
    
    // Pequena pausa entre comandos
    await Future.delayed(Duration(milliseconds: 100));
  }
  
  print('\n🔍 Verificando status das tabelas...');
  
  // Verificar quais tabelas existem
  for (final table in tables) {
    try {
      final response = await supabase
          .from(table)
          .select('*')
          .limit(1);
      print('✅ Tabela $table: Acessível');
    } catch (e) {
      if (e.toString().contains('relation') && e.toString().contains('does not exist')) {
        print('⚠️ Tabela $table: Não existe');
      } else if (e.toString().contains('RLS')) {
        print('🔒 Tabela $table: RLS ainda ativo');
      } else {
        print('❌ Tabela $table: Erro - $e');
      }
    }
  }
  
  print('\n✅ [RLS] Processo de verificação concluído!');
  print('\n⚠️ IMPORTANTE: Como não conseguimos desabilitar via API, você precisa:');
  print('1. Acessar o Dashboard do Supabase');
  print('2. Ir em SQL Editor');
  print('3. Executar o script disable_all_rls.sql manualmente');
  print('\n📋 Consulte o arquivo SECURITY_UPDATES_REQUIRED.md para próximos passos.');
  
  exit(0);
}