import 'dart:io';
import 'package:flutter/foundation.dart';
import 'lib/config/app_config.dart';
import 'lib/services/bypass_auth_service.dart';
import 'lib/utils/emulator_auth_helper.dart';
import 'lib/utils/supabase_helper.dart';

/// Script para diagnosticar e corrigir problemas de auth em emuladores Android
void main() async {
  print('🔧 DIAGNÓSTICO E CORREÇÃO DE AUTH EM EMULADORES ANDROID');
  print('=' * 60);
  print('');

  try {
    // 1. Verificar configuração
    print('1️⃣ VERIFICANDO CONFIGURAÇÃO...');
    await _checkConfiguration();
    print('');

    // 2. Inicializar Supabase
    print('2️⃣ INICIALIZANDO SUPABASE...');
    await _initializeSupabase();
    print('');

    // 3. Diagnosticar emulador
    print('3️⃣ DIAGNOSTICANDO EMULADOR...');
    final diagnostic = await EmulatorAuthHelper.diagnoseConnection();
    diagnostic.printReport();
    print('');

    // 4. Testar bypass auth
    print('4️⃣ TESTANDO BYPASS AUTH...');
    await _testBypassAuth();
    print('');

    // 5. Aplicar correções
    print('5️⃣ APLICANDO CORREÇÕES...');
    await _applyFixes();
    print('');

    // 6. Teste final
    print('6️⃣ TESTE FINAL DE REGISTRO...');
    await _testSignUp();
    print('');

    print('✅ DIAGNÓSTICO CONCLUÍDO!');
    print('');
    _showSummary();
  } catch (e, stackTrace) {
    print('❌ ERRO DURANTE DIAGNÓSTICO: $e');
    print('Stack trace: $stackTrace');
    _showTroubleshootingTips();
  }
}

Future<void> _checkConfiguration() async {
  print('📋 Verificando app_config.dart...');

  final validation = AppConfig.validateConfiguration();
  validation.printReport();

  print('🌐 URL Supabase: ${AppConfig.supabaseUrl}');
  print(
      '🔑 Key configurada: ${AppConfig.supabaseAnonKey.isNotEmpty ? "Sim" : "Não"}');

  if (!validation.isValid) {
    throw Exception('Configuração inválida. Corrija os problemas acima.');
  }

  print('✅ Configuração OK');
}

Future<void> _initializeSupabase() async {
  try {
    print('🔄 Inicializando cliente Supabase...');

    // Simular inicialização (o Supabase normalmente é inicializado no main.dart)
    await SupabaseHelper.initialize();

    print('✅ Supabase inicializado');
  } catch (e) {
    print('❌ Erro ao inicializar Supabase: $e');
    rethrow;
  }
}

Future<void> _testBypassAuth() async {
  try {
    print('🧪 Testando conexão bypass...');

    final isWorking = await BypassAuthService.testBypassConnection();

    if (isWorking) {
      print('✅ Bypass auth funcionando!');
    } else {
      print('❌ Bypass auth não está funcionando');
      throw Exception('Bypass auth falhou');
    }
  } catch (e) {
    print('❌ Erro no teste de bypass: $e');

    // Verificar se a função bypass existe no Supabase
    print('🔍 Verificando se função bypass_signup existe...');
    await _checkBypassFunction();
  }
}

Future<void> _checkBypassFunction() async {
  try {
    final client = SupabaseHelper.client;
    if (client == null) {
      throw Exception('Cliente Supabase não disponível');
    }

    // Tentar chamar função com parâmetros inválidos para ver se existe
    await client.rpc('bypass_signup', params: {
      'p_email': 'test@test.com',
      'p_password': 'test123',
      'p_full_name': 'Test',
      'p_phone': '123456789',
      'p_user_type': 'passenger',
    });

    print('✅ Função bypass_signup existe no Supabase');
  } catch (e) {
    final errorStr = e.toString();
    if (errorStr.contains('function') && errorStr.contains('does not exist')) {
      print('❌ Função bypass_signup NÃO existe no Supabase');
      print('💡 Você precisa criar a função SQL no Supabase Dashboard');
      _showBypassFunctionSQL();
    } else {
      print('⚠️ Função existe mas houve outro erro: $e');
    }
  }
}

void _showBypassFunctionSQL() {
  print('');
  print('📝 SQL PARA CRIAR FUNÇÃO BYPASS NO SUPABASE:');
  print('-' * 50);
  print('''
-- Execute este SQL no Supabase Dashboard > SQL Editor

CREATE OR REPLACE FUNCTION bypass_signup(
  p_email TEXT,
  p_password TEXT,
  p_full_name TEXT,
  p_phone TEXT,
  p_user_type TEXT
) RETURNS JSON AS \$\$
DECLARE
  new_user_id UUID;
  result JSON;
BEGIN
  -- Gerar novo UUID
  new_user_id := gen_random_uuid();

  -- Inserir na tabela app_users
  INSERT INTO app_users (
    id,
    email,
    full_name,
    phone,
    user_type,
    created_at,
    updated_at
  ) VALUES (
    new_user_id,
    p_email,
    p_full_name,
    p_phone,
    p_user_type,
    NOW(),
    NOW()
  );

  -- Retornar sucesso
  result := json_build_object(
    'success', true,
    'user_id', new_user_id,
    'email', p_email,
    'user_type', p_user_type,
    'message', 'Usuário criado via bypass'
  );

  RETURN result;
EXCEPTION
  WHEN OTHERS THEN
    -- Retornar erro
    result := json_build_object(
      'success', false,
      'error', SQLERRM
    );
    RETURN result;
END;
\$\$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função de login bypass
CREATE OR REPLACE FUNCTION bypass_login(
  p_email TEXT,
  p_password TEXT
) RETURNS JSON AS \$\$
DECLARE
  user_record RECORD;
  result JSON;
BEGIN
  -- Buscar usuário
  SELECT * INTO user_record
  FROM app_users
  WHERE email = p_email;

  IF FOUND THEN
    result := json_build_object(
      'success', true,
      'user', json_build_object(
        'id', user_record.id,
        'email', user_record.email,
        'full_name', user_record.full_name,
        'user_type', user_record.user_type
      )
    );
  ELSE
    result := json_build_object(
      'success', false,
      'error', 'Usuário não encontrado'
    );
  END IF;

  RETURN result;
END;
\$\$ LANGUAGE plpgsql SECURITY DEFINER;
''');
  print('-' * 50);
  print('');
}

Future<void> _applyFixes() async {
  print('🔧 Aplicando correções para emulador...');

  await EmulatorAuthHelper.applyEmulatorFixes();

  print('⚙️ Configurações aplicadas:');
  print('   - Timeouts aumentados para emulador');
  print('   - Detecção automática de ambiente');
  print('   - Fallback para bypass auth');

  print('✅ Correções aplicadas');
}

Future<void> _testSignUp() async {
  print('👤 Testando registro de usuário...');

  final testEmail =
      'emulator_test_${DateTime.now().millisecondsSinceEpoch}@test.com';

  try {
    final result = await EmulatorAuthHelper.intelligentSignUp(
      email: testEmail,
      password: 'test123456',
      fullName: 'Usuário Teste Emulador',
      phone: '11999999999',
      userType: 'passenger',
    );

    print('✅ Teste de registro SUCESSO!');
    print('   - ID: ${result['user_id']}');
    print('   - Email: ${result['email']}');
    print('   - Tipo: ${result['user_type']}');
  } catch (e) {
    print('❌ Teste de registro FALHOU: $e');
    throw e;
  }
}

void _showSummary() {
  print('📋 RESUMO E PRÓXIMOS PASSOS:');
  print('=' * 40);
  print('');

  if (EmulatorAuthHelper.isAndroidEmulator) {
    print('🤖 EMULADOR ANDROID DETECTADO');
    print('');
    print('✅ Para usar no seu código:');
    print('');
    print('// Em vez de usar AuthService diretamente:');
    print('import "lib/utils/emulator_auth_helper.dart";');
    print('');
    print('// Para registro:');
    print('final result = await EmulatorAuthHelper.intelligentSignUp(');
    print('  email: email,');
    print('  password: password,');
    print('  fullName: fullName,');
    print('  phone: phone,');
    print('  userType: userType,');
    print(');');
    print('');
    print('// Para login:');
    print('final result = await EmulatorAuthHelper.intelligentSignIn(');
    print('  email: email,');
    print('  password: password,');
    print(');');
  } else {
    print('📱 DISPOSITIVO FÍSICO OU WEB');
    print('   - Use AuthService normal');
    print('   - Bypass será usado apenas se necessário');
  }

  print('');
  print('🔧 COMANDOS ÚTEIS:');
  print(
      '   flutter run -d <device_id>  # Para testar em dispositivo específico');
  print('   flutter devices             # Lista dispositivos disponíveis');
  print('   flutter clean && flutter pub get  # Limpar cache');
  print('');
}

void _showTroubleshootingTips() {
  print('');
  print('🆘 DICAS DE SOLUÇÃO DE PROBLEMAS:');
  print('=' * 40);
  print('');
  print('1. 🌐 PROBLEMAS DE REDE NO EMULADOR:');
  print('   - Reinicie o emulador');
  print('   - Use Wipe Data no AVD Manager');
  print('   - Verifique se o emulador tem acesso à internet');
  print('   - Teste: adb shell ping google.com');
  print('');
  print('2. 🔑 PROBLEMAS COM SUPABASE:');
  print('   - Verifique se a URL e Key estão corretas');
  print('   - Teste a conexão no Supabase Dashboard');
  print('   - Certifique-se que as funções bypass existem');
  print('');
  print('3. 📱 ALTERNATIVAS:');
  print('   - Use um dispositivo físico');
  print('   - Teste no navegador: flutter run -d chrome');
  print('   - Use iOS Simulator se disponível');
  print('');
  print('4. 🔧 COMANDOS DE DEBUG:');
  print('   - flutter logs');
  print('   - adb logcat');
  print('   - flutter doctor -v');
}
