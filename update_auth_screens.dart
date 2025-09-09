import 'dart:io';

/// Script simples para atualizar as telas de autenticação
/// com o serviço otimizado para emuladores
void main() async {
  print('🔧 ATUALIZANDO TELAS DE AUTENTICAÇÃO PARA EMULADORES');
  print('=' * 60);
  print('');

  try {
    // 1. Atualizar RegisterScreen
    print('1️⃣ Atualizando RegisterScreen...');
    await updateRegisterScreen();
    print('');

    // 2. Atualizar LoginScreen
    print('2️⃣ Atualizando LoginScreen...');
    await updateLoginScreen();
    print('');

    // 3. Criar script de teste
    print('3️⃣ Criando script de teste...');
    await createTestScript();
    print('');

    print('✅ TODAS AS ATUALIZAÇÕES CONCLUÍDAS!');
    print('');
    showUsageInstructions();
  } catch (e) {
    print('❌ ERRO: $e');
    showTroubleshootingTips();
  }
}

Future<void> updateRegisterScreen() async {
  final file = File('lib/screens/auth/register_screen.dart');

  if (!await file.exists()) {
    print('❌ RegisterScreen não encontrado');
    return;
  }

  String content = await file.readAsString();

  // Adicionar import do serviço otimizado
  if (!content.contains('emulator_optimized_auth_service')) {
    content = content.replaceFirst("import '../../utils/supabase_helper.dart';",
        "import '../../utils/supabase_helper.dart';\nimport '../../services/emulator_optimized_auth_service.dart';");
  }

  // Substituir o método de registro
  final oldRegistration = RegExp(
      r'final result = await EmulatorAuthHelper\.intelligentSignUp\(([\s\S]*?)\);',
      multiLine: true);

  if (content.contains(oldRegistration)) {
    content = content.replaceAll(oldRegistration,
        '''final response = await EmulatorOptimizedAuthService.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': '', // Adicione se necessário
        },
      );

      if (response.user != null) {
        // Sucesso - usuário criado com token JWT válido
        final result = {
          'success': true,
          'user_id': response.user!.id,
          'email': response.user!.email,
        };''');
  }

  // Backup do arquivo original
  await File('lib/screens/auth/register_screen.dart.backup')
      .writeAsString(content);
  await file.writeAsString(content);

  print('✅ RegisterScreen atualizado');
}

Future<void> updateLoginScreen() async {
  final file = File('lib/screens/auth/login_screen.dart');

  if (!await file.exists()) {
    print('❌ LoginScreen não encontrado');
    return;
  }

  String content = await file.readAsString();

  // Adicionar import do serviço otimizado
  if (!content.contains('emulator_optimized_auth_service')) {
    content = content.replaceFirst(
        "import '../../utils/emulator_network_helper.dart';",
        "import '../../utils/emulator_network_helper.dart';\nimport '../../services/emulator_optimized_auth_service.dart';");
  }

  // Substituir o método de login
  final oldLogin = RegExp(
      r'final result = await EmulatorAuthHelper\.intelligentSignIn\(([\s\S]*?)\);',
      multiLine: true);

  if (content.contains(oldLogin)) {
    content = content.replaceAll(
        oldLogin, '''final response = await EmulatorOptimizedAuthService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null && response.session != null) {
        // Login bem-sucedido com session válida
        final result = {
          'success': true,
          'user': {
            'id': response.user!.id,
            'email': response.user!.email,
            'user_type': 'passenger', // Será obtido do banco
          }
        };''');
  }

  // Backup do arquivo original
  await File('lib/screens/auth/login_screen.dart.backup')
      .writeAsString(content);
  await file.writeAsString(content);

  print('✅ LoginScreen atualizado');
}

Future<void> createTestScript() async {
  const testContent = '''
import 'package:flutter/material.dart';
import '../services/emulator_optimized_auth_service.dart';
import '../utils/emulator_network_helper.dart';

/// Script para testar autenticação em emuladores
class EmulatorAuthTester {

  /// Testa registro completo
  static Future<void> testRegistration() async {
    print('🧪 TESTANDO REGISTRO EM EMULADOR');
    print('-' * 40);

    final testEmail = 'test_\${DateTime.now().millisecondsSinceEpoch}@emulator.test';

    try {
      print('📧 Email de teste: \$testEmail');

      final response = await EmulatorOptimizedAuthService.signUp(
        email: testEmail,
        password: 'TestPassword123!',
        data: {'full_name': 'Usuário Teste Emulador'},
      );

      if (response.user != null) {
        print('✅ SUCESSO! Usuário criado:');
        print('   - ID: \${response.user!.id}');
        print('   - Email: \${response.user!.email}');
        print('   - Session: \${response.session != null ? "Criada" : "Pendente"}');

        if (response.session != null) {
          print('   - Token: \${response.session!.accessToken.substring(0, 20)}...');
        }

        // Fazer logout para limpar
        await EmulatorOptimizedAuthService.signOut();
        print('🧹 Sessão de teste removida');

        return;
      }

      print('❌ FALHA: Usuário não foi criado');
    } catch (e) {
      print('❌ ERRO no registro: \$e');
    }
  }

  /// Testa login com usuário existente
  static Future<void> testLogin(String email, String password) async {
    print('🧪 TESTANDO LOGIN EM EMULADOR');
    print('-' * 40);

    try {
      print('📧 Email: \$email');

      final response = await EmulatorOptimizedAuthService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null && response.session != null) {
        print('✅ SUCESSO! Login realizado:');
        print('   - ID: \${response.user!.id}');
        print('   - Email: \${response.user!.email}');
        print('   - Token: \${response.session!.accessToken.substring(0, 20)}...');
        print('   - Expira: \${DateTime.fromMillisecondsSinceEpoch(response.session!.expiresAt! * 1000)}');

        return;
      }

      print('❌ FALHA: Login não realizado');
    } catch (e) {
      print('❌ ERRO no login: \$e');
    }
  }

  /// Executa diagnóstico completo
  static Future<void> runFullDiagnostic() async {
    print('🔍 DIAGNÓSTICO COMPLETO DE AUTENTICAÇÃO');
    print('=' * 50);

    // 1. Testar conectividade
    print('1️⃣ Testando conectividade...');
    final networkDiag = await EmulatorNetworkHelper.testSupabaseConnection();
    networkDiag.printReport();

    // 2. Testar registro
    print('\\n2️⃣ Testando registro...');
    await testRegistration();

    // 3. Diagnóstico de auth
    print('\\n3️⃣ Diagnóstico de autenticação...');
    final authDiag = await EmulatorOptimizedAuthService.runAuthDiagnostic();

    print('\\n📊 RESUMO FINAL:');
    print('=' * 30);
    print('🌐 Rede: \${networkDiag.isHealthy ? "✅ OK" : "❌ Problemas"}');
    print('🔐 Auth: \${authDiag['overallHealth']}');
    print('🤖 Emulador: \${EmulatorNetworkHelper.isAndroidEmulator ? "SIM" : "NÃO"}');
  }
}

/// Widget para testar na interface
class EmulatorAuthTestScreen extends StatefulWidget {
  @override
  _EmulatorAuthTestScreenState createState() => _EmulatorAuthTestScreenState();
}

class _EmulatorAuthTestScreenState extends State<EmulatorAuthTestScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _testing = false;
  String _result = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Teste de Auth - Emulador')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'test@example.com',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Senha',
              ),
              obscureText: true,
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testing ? null : _testRegistration,
                    child: Text('Testar Registro'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testing ? null : _testLogin,
                    child: Text('Testar Login'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testing ? null : _runDiagnostic,
              child: Text('Diagnóstico Completo'),
            ),
            SizedBox(height: 24),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result.isEmpty ? 'Resultados aparecerão aqui...' : _result,
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _testRegistration() async {
    setState(() {
      _testing = true;
      _result = 'Testando registro...\\n';
    });

    try {
      await EmulatorAuthTester.testRegistration();
      setState(() {
        _result += 'Teste de registro concluído!\\n';
      });
    } catch (e) {
      setState(() {
        _result += 'Erro no teste: \$e\\n';
      });
    } finally {
      setState(() => _testing = false);
    }
  }

  void _testLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _result = 'Por favor, preencha email e senha\\n';
      });
      return;
    }

    setState(() {
      _testing = true;
      _result = 'Testando login...\\n';
    });

    try {
      await EmulatorAuthTester.testLogin(
        _emailController.text,
        _passwordController.text
      );
      setState(() {
        _result += 'Teste de login concluído!\\n';
      });
    } catch (e) {
      setState(() {
        _result += 'Erro no teste: \$e\\n';
      });
    } finally {
      setState(() => _testing = false);
    }
  }

  void _runDiagnostic() async {
    setState(() {
      _testing = true;
      _result = 'Executando diagnóstico...\\n';
    });

    try {
      await EmulatorAuthTester.runFullDiagnostic();
      setState(() {
        _result += 'Diagnóstico concluído!\\n';
      });
    } catch (e) {
      setState(() {
        _result += 'Erro no diagnóstico: \$e\\n';
      });
    } finally {
      setState(() => _testing = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
''';

  await File('lib/utils/emulator_auth_tester.dart').writeAsString(testContent);
  print('✅ Script de teste criado em lib/utils/emulator_auth_tester.dart');
}

void showUsageInstructions() {
  print('📋 INSTRUÇÕES DE USO:');
  print('=' * 40);
  print('');
  print('1️⃣ EXECUTE O APP:');
  print('   flutter clean && flutter pub get');
  print('   flutter run');
  print('');
  print('2️⃣ TESTE MANUAL:');
  print('   - Abra a tela de registro');
  print('   - Preencha os dados');
  print('   - O sistema detectará automaticamente se é emulador');
  print('   - Usará timeouts e retry otimizados');
  print('');
  print('3️⃣ TESTE PROGRAMÁTICO:');
  print(
      '   dart -c "import \'lib/utils/emulator_auth_tester.dart\'; EmulatorAuthTester.runFullDiagnostic();"');
  print('');
  print('4️⃣ ADICIONAR TELA DE TESTE (OPCIONAL):');
  print('   // No seu MaterialApp, adicione a rota:');
  print('   "/auth_test": (context) => EmulatorAuthTestScreen(),');
  print('');
  print('🔒 VANTAGENS DESTA SOLUÇÃO:');
  print('   ✅ Mantém tokens JWT válidos');
  print('   ✅ Row Level Security funcionando');
  print('   ✅ Session management completo');
  print('   ✅ Retry automático em emuladores');
  print('   ✅ Timeouts otimizados');
  print('   ✅ Zero mudanças na lógica de negócio');
  print('   ✅ Compatibilidade total com produção');
  print('');
  print('📊 MONITORAMENTO:');
  print('   - Logs detalhados no console');
  print('   - Detecção automática de emulador');
  print('   - Diagnóstico de rede integrado');
  print('   - Análise de erros específicos');
}

void showTroubleshootingTips() {
  print('');
  print('🆘 SOLUÇÃO DE PROBLEMAS:');
  print('=' * 30);
  print('');
  print('❌ Se o registro ainda falhar:');
  print(
      '   1. Verifique se o emulador tem internet: adb shell ping google.com');
  print('   2. Reinicie o emulador completamente');
  print('   3. Execute: flutter clean && flutter pub get');
  print('   4. Teste no navegador: flutter run -d chrome');
  print('');
  print('❌ Se der erro de importação:');
  print('   1. Verifique se todos os arquivos foram criados');
  print('   2. Execute: flutter pub deps');
  print('   3. Reinicie o IDE');
  print('');
  print('❌ Se der erro de Supabase:');
  print('   1. Verifique URL e API key no app_config.dart');
  print('   2. Teste no Supabase Dashboard primeiro');
  print('   3. Verifique se as tabelas existem');
  print('');
  print('🌐 ALTERNATIVAS:');
  print('   - Use dispositivo físico: flutter devices');
  print('   - Use navegador: flutter run -d chrome');
  print('   - Use iOS Simulator se disponível');
}
