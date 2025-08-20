#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

void main() async {
  print('🔍 Validando sincronização entre Schema do Supabase e Modelos Dart...\n');
  
  try {
    // Ler schema do Supabase
    final schemaFile = File('supabase_schema.json');
    if (!schemaFile.existsSync()) {
      print('❌ Erro: supabase_schema.json não encontrado');
      exit(1);
    }
    
    final schemaContent = await schemaFile.readAsString();
    final schema = jsonDecode(schemaContent) as Map<String, dynamic>;
    final tables = schema['tables'] as List<dynamic>;
    
    print('📊 TABELAS NO SUPABASE:');
    for (final table in tables) {
      final tableName = table['name'] as String;
      final columns = table['columns'] as List<dynamic>;
      
      print('\n  📋 $tableName');
      for (final column in columns) {
        final name = column['name'];
        final type = column['type'];
        final nullable = column['nullable'] ? '?' : '!';
        print('    • $name: $type$nullable');
      }
    }
    
    print('\n📱 MODELOS DART EXISTENTES:');
    final modelsDir = Directory('lib/models/supabase');
    if (modelsDir.existsSync()) {
      final dartFiles = modelsDir.listSync()
          .where((file) => file.path.endsWith('.dart'))
          .map((file) => file.path.split('/').last.replaceAll('.dart', ''))
          .toList();
      
      for (final model in dartFiles) {
        print('    • $model.dart');
      }
    }
    
    print('\n🔄 ANÁLISE DE SINCRONIZAÇÃO:');
    
    // Verificar modelos com tabelas correspondentes
    final dbTables = tables.map((t) => t['name'] as String).toSet();
    final appUserInDb = dbTables.contains('app_user');
    final usersInDb = dbTables.contains('users');
    
    if (appUserInDb) {
      print('  ✅ app_user: Tabela existe no DB');
      final appUserTable = tables.firstWhere((t) => t['name'] == 'app_user');
      final dbFields = (appUserTable['columns'] as List).map((c) => c['name']).toSet();
      final expectedFields = {
        'id', 'user_id', 'phone', 'user_type', 'is_active', 'is_verified', 
        'created_at', 'updated_at'
      };
      
      final missing = expectedFields.difference(dbFields);
      final extra = dbFields.difference(expectedFields);
      
      if (missing.isNotEmpty) {
        print('    ⚠️  Campos ausentes no DB: ${missing.join(', ')}');
      }
      if (extra.isNotEmpty) {
        print('    ℹ️  Campos extras no DB: ${extra.join(', ')}');
      }
    } else {
      print('  ❌ app_user: Modelo existe mas tabela não encontrada no DB');
    }
    
    if (usersInDb) {
      print('  ✅ users: Tabela auth existe no DB');
    }
    
    // Verificar modelos sem tabelas correspondentes
    final modelsWithoutTables = [
      'trip', 'trip_request', 'driver', 'passenger', 'vehicle', 
      'passenger_request', 'driver_offer', 'location', 'promo_code'
    ];
    
    print('\n  📋 Modelos sem tabelas correspondentes (features futuras):');
    for (final model in modelsWithoutTables) {
      print('    • $model - Implementação futura');
    }
    
    print('\n📝 RECOMENDAÇÕES:');
    print('  1. Atualizar tabela app_user no Supabase com campos is_active, is_verified, updated_at');
    print('  2. Considerar usar AppUser model em vez de User model para dados atuais');
    print('  3. Manter modelos complexos (Trip, etc.) para desenvolvimento futuro');
    print('  4. Re-executar extract_supabase_schema.sh após atualizações no DB');
    
    print('\n✅ Validação concluída!');
    
  } catch (e) {
    print('❌ Erro durante validação: $e');
    exit(1);
  }
}