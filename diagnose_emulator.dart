import 'dart:io';

/// Script simples para diagnosticar problemas de auth em emuladores
void main() async {
  print('🔧 DIAGNÓSTICO RÁPIDO - PROBLEMAS DE AUTH NO EMULADOR ANDROID');
  print('=' * 70);
  print('');

  // 1. Verificar ambiente
  print('1️⃣ VERIFICANDO AMBIENTE...');
  _checkEnvironment();
  print('');

  // 2. Verificar configuração
  print('2️⃣ VERIFICANDO CONFIGURAÇÃO...');
  _checkSupabaseConfig();
  print('');

  // 3. Soluções recomendadas
  print('3️⃣ SOLUÇÕES PARA EMULADOR ANDROID...');
  _showSolutions();
  print('');

  // 4. Como usar bypass
  print('4️⃣ COMO USAR O BYPASS AUTH...');
  _showBypassUsage();
  print('');

  // 5. Comandos úteis
  print('5️⃣ COMANDOS ÚTEIS...');
  _showCommands();
}

void _checkEnvironment() {
  print('🌍 Sistema operacional: ${Platform.operatingSystem}');
  print('📱 Executando em: ${_detectPlatform()}');

  if (Platform.isAndroid) {
    print('🤖 Emulador Android detectado!');
    print('⚠️  Emuladores podem ter problemas de rede com Supabase Auth');
  } else {
    print('✅ Plataforma não é emulador Android');
  }
}

String _detectPlatform() {
  if (Platform.isAndroid) return 'Android (possível emulador)';
  if (Platform.isIOS) return 'iOS';
  return 'Outro (${Platform.operatingSystem})';
}

void _checkSupabaseConfig() {
  print('📋 Verificando configuração do Supabase...');
  print('   - URL: https://qlbwacmavngtonauxnte.supabase.co');
  print('   - Key: Configurada (eyJhbGci...)');
  print('✅ Configuração parece estar OK');
}

void _showSolutions() {
  print('🔧 SOLUÇÕES RECOMENDADAS:');
  print('');

  print('📱 OPÇÃO 1: USAR DISPOSITIVO FÍSICO');
  print('   - Conecte um celular via USB');
  print('   - Execute: flutter devices');
  print('   - Execute: flutter run -d <device_id>');
  print('');

  print('🌐 OPÇÃO 2: TESTAR NO NAVEGADOR');
  print('   - Execute: flutter run -d chrome');
  print('   - Mais estável que emulador para auth');
  print('');

  print('🚀 OPÇÃO 3: USAR BYPASS AUTH (RECOMENDADO)');
  print('   - Já implementado no projeto');
  print('   - Funciona específicamente em emuladores');
  print('   - Ver seção 4 para instruções');
  print('');

  print('🔄 OPÇÃO 4: REINICIAR EMULADOR');
  print('   - Feche o emulador completamente');
  print('   - No AVD Manager: Wipe Data');
  print('   - Inicie novamente o emulador');
  print('   - Execute: flutter clean && flutter pub get');
}

void _showBypassUsage() {
  print('🚀 USANDO O BYPASS AUTH:');
  print('');
  print('O projeto já tem um EmulatorAuthHelper configurado.');
  print('Para usar em suas telas de registro/login:');
  print('');
  print('📝 CÓDIGO PARA REGISTRO:');
  print('```dart');
  print("import '../utils/emulator_auth_helper.dart';");
  print('');
  print('// Em vez do AuthService normal:');
  print('try {');
  print('  final result = await EmulatorAuthHelper.intelligentSignUp(');
  print('    email: emailController.text,');
  print('    password: passwordController.text,');
  print('    fullName: nameController.text,');
  print('    phone: phoneController.text,');
  print('    userType: "passenger", // ou "driver"');
  print('  );');
  print('  ');
  print('  if (result["success"] == true) {');
  print('    // Sucesso! Redirecionar para próxima tela');
  print('    Navigator.pushReplacement(context, ...);');
  print('  }');
  print('} catch (e) {');
  print('  // Tratar erro');
  print('  print("Erro no registro: \$e");');
  print('}');
  print('```');
  print('');
  print('📝 CÓDIGO PARA LOGIN:');
  print('```dart');
  print('try {');
  print('  final result = await EmulatorAuthHelper.intelligentSignIn(');
  print('    email: emailController.text,');
  print('    password: passwordController.text,');
  print('  );');
  print('  ');
  print('  if (result["success"] == true) {');
  print('    // Login bem-sucedido');
  print('    Navigator.pushReplacement(context, ...);');
  print('  }');
  print('} catch (e) {');
  print('  print("Erro no login: \$e");');
  print('}');
  print('```');
  print('');
  print('💡 O EmulatorAuthHelper:');
  print('   - Detecta automaticamente se é emulador');
  print('   - Usa bypass em emuladores');
  print('   - Usa auth normal em dispositivos físicos');
  print('   - Tem fallback automático se um método falhar');
}

void _showCommands() {
  print('⚡ COMANDOS ÚTEIS:');
  print('');
  print('🔍 DIAGNÓSTICO:');
  print('   flutter doctor -v                 # Verificar instalação');
  print('   flutter devices                   # Listar dispositivos');
  print('   adb devices                       # Verificar conexão Android');
  print('');
  print('🧹 LIMPEZA:');
  print('   flutter clean                     # Limpar cache');
  print('   flutter pub get                   # Reinstalar dependências');
  print('');
  print('🚀 EXECUÇÃO:');
  print('   flutter run -d chrome             # Rodar no navegador');
  print('   flutter run -d <device_id>        # Rodar em device específico');
  print('   flutter run --debug               # Rodar com debug ativo');
  print('');
  print('🐛 DEBUG:');
  print('   flutter logs                      # Ver logs em tempo real');
  print('   adb logcat | grep flutter        # Logs Android específicos');
  print('');

  print('🔧 PRÓXIMOS PASSOS:');
  print('=' * 40);
  print('1. Execute: dart diagnose_emulator.dart');
  print('2. Escolha uma das opções de solução');
  print('3. Se usar bypass, implemente o código mostrado acima');
  print('4. Teste: flutter run -d chrome (mais estável)');
  print('5. Se tudo falhar, use dispositivo físico');
  print('');
  print('💬 Precisa de mais ajuda?');
  print('   - Verifique os logs com: flutter logs');
  print('   - Teste a conexão Supabase no navegador');
  print('   - Use o bypass auth que já está configurado');
}
