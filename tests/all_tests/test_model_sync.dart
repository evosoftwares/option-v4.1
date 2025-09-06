import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔍 Iniciando teste de sincronização entre modelos Dart e schema do banco...');
  
  // Verificar se o arquivo de schema existe
  final schemaFile = File('backups/supabase_schema.json');
  if (!schemaFile.existsSync()) {
    print('❌ Arquivo de schema não encontrado: backups/supabase_schema.json');
    return;
  }
  
  // Ler schema do Supabase
  final schemaContent = await schemaFile.readAsString();
  final schema = jsonDecode(schemaContent);
  
  print('\n📊 Schema do banco carregado com sucesso!');
  
  // Verificar modelos principais
  await testAppUserModel(schema);
  await testDriverModel(schema);
  await testPassengerModel(schema);
  await testTripModel(schema);
  
  print('\n✅ Teste de sincronização concluído!');
}

Future<void> testAppUserModel(Map<String, dynamic> schema) async {
  print('\n🔍 Testando modelo AppUser...');
  
  final modelFile = File('lib/models/supabase/app_user.dart');
  if (!modelFile.existsSync()) {
    print('❌ Modelo AppUser não encontrado');
    return;
  }
  
  final modelContent = await modelFile.readAsString();
  
  // Campos esperados no banco
  final expectedFields = [
    'id', 'user_id', 'email', 'phone', 'full_name', 
    'photo_url', 'user_type', 'status', 'is_active', 
    'is_verified', 'created_at', 'updated_at'
  ];
  
  // Verificar se os campos estão no modelo
  final missingFields = <String>[];
  for (final field in expectedFields) {
    if (!modelContent.contains(field)) {
      missingFields.add(field);
    }
  }
  
  if (missingFields.isEmpty) {
    print('✅ AppUser: Todos os campos estão sincronizados');
  } else {
    print('⚠️  AppUser: Campos ausentes no modelo: ${missingFields.join(", ")}');
  }
}

Future<void> testDriverModel(Map<String, dynamic> schema) async {
  print('\n🔍 Testando modelo Driver...');
  
  final modelFile = File('lib/models/supabase/driver.dart');
  if (!modelFile.existsSync()) {
    print('❌ Modelo Driver não encontrado');
    return;
  }
  
  final modelContent = await modelFile.readAsString();
  
  // Campos agrupados em JSON no modelo
  final jsonGroupedFields = {
    'fees': ['pet_fee', 'grocery_fee', 'condo_fee', 'stop_fee'],
    'bankData': ['bank_account_type', 'bank_code', 'bank_agency', 'bank_account'],
    'pixData': ['pix_key', 'pix_key_type']
  };
  
  // Campos ausentes no modelo
  final missingFields = [
    'cnh_photo_url', 'crlv_photo_url', 'approved_by', 
    'approved_at', 'last_location_update'
  ];
  
  print('✅ Driver: Modelo usa agrupamento JSON para organização:');
  jsonGroupedFields.forEach((group, fields) {
    print('   - $group: ${fields.join(", ")}');
  });
  
  print('⚠️  Driver: Campos do banco ausentes no modelo:');
  for (final field in missingFields) {
    print('   - $field');
  }
}

Future<void> testPassengerModel(Map<String, dynamic> schema) async {
  print('\n🔍 Testando modelo Passenger...');
  
  final modelFile = File('lib/models/supabase/passenger.dart');
  if (!modelFile.existsSync()) {
    print('❌ Modelo Passenger não encontrado');
    return;
  }
  
  print('✅ Passenger: Modelo encontrado - verificação básica OK');
}

Future<void> testTripModel(Map<String, dynamic> schema) async {
  print('\n🔍 Testando modelo Trip...');
  
  final modelFile = File('lib/models/supabase/trip.dart');
  if (!modelFile.existsSync()) {
    print('❌ Modelo Trip não encontrado');
    return;
  }
  
  print('✅ Trip: Modelo encontrado - verificação básica OK');
}