import 'package:flutter/material.dart';
import '../services/emulator_optimized_auth_service.dart';
import '../utils/emulator_network_helper.dart';

/// Script para testar autenticação em emuladores
class EmulatorAuthTester {

  /// Testa registro completo
  static Future<void> testRegistration() async {
    print('🧪 TESTANDO REGISTRO EM EMULADOR');
    print('-' * 40);

    final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@emulator.test';

    try {
      print('📧 Email de teste: $testEmail');

      final response = await EmulatorOptimizedAuthService.signUp(
        email: testEmail,
        password: 'TestPassword123!',
        data: {'full_name': 'Usuário Teste Emulador'},
      );

      if (response.user != null) {
        print('✅ SUCESSO! Usuário criado:');
        print('   - ID: ${response.user!.id}');
        print('   - Email: ${response.user!.email}');
        print('   - Session: ${response.session != null ? "Criada" : "Pendente"}');

        if (response.session != null) {
          print('   - Token: ${response.session!.accessToken.substring(0, 20)}...');
        }

        // Fazer logout para limpar
        await EmulatorOptimizedAuthService.signOut();
        print('🧹 Sessão de teste removida');

        return;
      }

      print('❌ FALHA: Usuário não foi criado');
    } catch (e) {
      print('❌ ERRO no registro: $e');
    }
  }

  /// Testa login com usuário existente
  static Future<void> testLogin(String email, String password) async {
    print('🧪 TESTANDO LOGIN EM EMULADOR');
    print('-' * 40);

    try {
      print('📧 Email: $email');

      final response = await EmulatorOptimizedAuthService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null && response.session != null) {
        print('✅ SUCESSO! Login realizado:');
        print('   - ID: ${response.user!.id}');
        print('   - Email: ${response.user!.email}');
        print('   - Token: ${response.session!.accessToken.substring(0, 20)}...');
        print('   - Expira: ${DateTime.fromMillisecondsSinceEpoch(response.session!.expiresAt! * 1000)}');

        return;
      }

      print('❌ FALHA: Login não realizado');
    } catch (e) {
      print('❌ ERRO no login: $e');
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
    print('\n2️⃣ Testando registro...');
    await testRegistration();

    // 3. Diagnóstico de auth
    print('\n3️⃣ Diagnóstico de autenticação...');
    final authDiag = await EmulatorOptimizedAuthService.runAuthDiagnostic();

    print('\n📊 RESUMO FINAL:');
    print('=' * 30);
    print('🌐 Rede: ${networkDiag.isHealthy ? "✅ OK" : "❌ Problemas"}');
    print('🔐 Auth: ${authDiag['overallHealth']}');
    print('🤖 Emulador: ${EmulatorNetworkHelper.isAndroidEmulator ? "SIM" : "NÃO"}');
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
      _result = 'Testando registro...\n';
    });

    try {
      await EmulatorAuthTester.testRegistration();
      setState(() {
        _result += 'Teste de registro concluído!\n';
      });
    } catch (e) {
      setState(() {
        _result += 'Erro no teste: $e\n';
      });
    } finally {
      setState(() => _testing = false);
    }
  }

  void _testLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _result = 'Por favor, preencha email e senha\n';
      });
      return;
    }

    setState(() {
      _testing = true;
      _result = 'Testando login...\n';
    });

    try {
      await EmulatorAuthTester.testLogin(
        _emailController.text,
        _passwordController.text
      );
      setState(() {
        _result += 'Teste de login concluído!\n';
      });
    } catch (e) {
      setState(() {
        _result += 'Erro no teste: $e\n';
      });
    } finally {
      setState(() => _testing = false);
    }
  }

  void _runDiagnostic() async {
    setState(() {
      _testing = true;
      _result = 'Executando diagnóstico...\n';
    });

    try {
      await EmulatorAuthTester.runFullDiagnostic();
      setState(() {
        _result += 'Diagnóstico concluído!\n';
      });
    } catch (e) {
      setState(() {
        _result += 'Erro no diagnóstico: $e\n';
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
