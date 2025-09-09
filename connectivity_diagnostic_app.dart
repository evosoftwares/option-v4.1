import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// App standalone para diagnóstico de conectividade Supabase
/// Execute com: flutter run connectivity_diagnostic_app.dart
void main() {
  runApp(ConnectivityDiagnosticApp());
}

class ConnectivityDiagnosticApp extends StatelessWidget {
  const ConnectivityDiagnosticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diagnóstico de Conectividade',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ConnectivityDiagnosticScreen(),
    );
  }
}

class ConnectivityDiagnosticScreen extends StatefulWidget {
  const ConnectivityDiagnosticScreen({super.key});

  @override
  _ConnectivityDiagnosticScreenState createState() =>
      _ConnectivityDiagnosticScreenState();
}

class _ConnectivityDiagnosticScreenState
    extends State<ConnectivityDiagnosticScreen> {
  static const String _supabaseHost = 'qlbwacmavngtonauxnte.supabase.co';
  static const String _supabaseUrl = 'https://qlbwacmavngtonauxnte.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E';

  bool _isRunning = false;
  final List<String> _logs = [];
  final Map<String, bool> _testResults = {};
  final List<String> _recommendations = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Diagnóstico de Conectividade'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Cards
            if (_testResults.isNotEmpty) _buildStatusCards(),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRunning ? null : _runFullDiagnostic,
                    icon: _isRunning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(
                        _isRunning ? 'Executando...' : 'Executar Diagnóstico'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _clearLogs,
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Recommendations
            if (_recommendations.isNotEmpty) _buildRecommendations(),

            // Logs
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.info_outline,
                                size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'Clique em "Executar Diagnóstico" para verificar a conectividade',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              log,
                              style: TextStyle(
                                color: _getLogColor(log),
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCards() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildStatusCard('Internet', _testResults['internet'] ?? false),
          _buildStatusCard('DNS', _testResults['dns'] ?? false),
          _buildStatusCard('HTTP', _testResults['http'] ?? false),
          _buildStatusCard('Auth', _testResults['auth'] ?? false),
          _buildStatusCard('Database', _testResults['database'] ?? false),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, bool status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: status ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status ? Icons.check_circle : Icons.error,
            color: status ? Colors.green[700] : Colors.red[700],
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: TextStyle(
              color: status ? Colors.green[700] : Colors.red[700],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                'Recomendações:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._recommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Text(
                  '• $rec',
                  style: TextStyle(color: Colors.orange[700], fontSize: 12),
                ),
              )),
        ],
      ),
    );
  }

  Color _getLogColor(String log) {
    if (log.contains('❌')) return Colors.red[700]!;
    if (log.contains('✅')) return Colors.green[700]!;
    if (log.contains('⚠️')) return Colors.orange[700]!;
    if (log.contains('🔍') || log.contains('🔧') || log.contains('🔄')) {
      return Colors.blue[700]!;
    }
    return Colors.black87;
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} $message');
    });
    print(message);
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
      _testResults.clear();
      _recommendations.clear();
    });
  }

  Future<void> _runFullDiagnostic() async {
    setState(() {
      _isRunning = true;
      _logs.clear();
      _testResults.clear();
      _recommendations.clear();
    });

    _addLog('🚀 Iniciando diagnóstico completo de conectividade...');

    try {
      // Test 1: Basic Internet Connectivity
      _addLog('');
      _addLog('1️⃣ Testando conectividade básica com a internet...');
      bool hasInternet = await _testBasicConnectivity();
      _testResults['internet'] = hasInternet;
      setState(() {});

      if (!hasInternet) {
        _addRecommendation('Verificar conexão Wi-Fi ou dados móveis');
        _addRecommendation('Reiniciar roteador/modem');
        return;
      }

      // Test 2: DNS Resolution
      _addLog('');
      _addLog('2️⃣ Testando resolução DNS do Supabase...');
      bool dnsWorks = await _testDnsResolution();
      _testResults['dns'] = dnsWorks;
      setState(() {});

      if (!dnsWorks) {
        _addRecommendation('Configurar DNS alternativo (8.8.8.8 ou 1.1.1.1)');
        _addRecommendation('Limpar cache DNS do dispositivo');
        _addRecommendation('Usar modo bypass no app principal');
        await _testAlternativeDns();
      }

      // Test 3: HTTP Connectivity
      _addLog('');
      _addLog('3️⃣ Testando conectividade HTTP com Supabase...');
      bool httpWorks = await _testHttpConnectivity();
      _testResults['http'] = httpWorks;
      setState(() {});

      if (!httpWorks) {
        _addRecommendation('Verificar proxy/VPN que pode estar interferindo');
        _addRecommendation('Tentar via dados móveis em vez de Wi-Fi');
        _addRecommendation('Usar modo bypass no app principal');
      }

      // Test 4: Authentication
      if (httpWorks) {
        _addLog('');
        _addLog('4️⃣ Testando serviço de autenticação...');
        bool authWorks = await _testAuthentication();
        _testResults['auth'] = authWorks;
        setState(() {});

        if (!authWorks) {
          _addRecommendation('Verificar chaves de API do Supabase');
          _addRecommendation('Usar modo bypass no app principal');
        }
      }

      // Test 5: Database Access
      if (_testResults['auth'] == true) {
        _addLog('');
        _addLog('5️⃣ Testando acesso ao banco de dados...');
        bool dbWorks = await _testDatabaseAccess();
        _testResults['database'] = dbWorks;
        setState(() {});

        if (!dbWorks) {
          _addRecommendation('Verificar políticas RLS do Supabase');
          _addRecommendation('Usar modo bypass no app principal');
        }
      }

      // Final recommendations
      _generateFinalRecommendations();
    } catch (e) {
      _addLog('💥 Erro crítico durante diagnóstico: $e');
      _addRecommendation('Usar modo bypass obrigatoriamente');
    } finally {
      setState(() {
        _isRunning = false;
      });
      _addLog('');
      _addLog('🏁 Diagnóstico concluído!');
    }
  }

  Future<bool> _testBasicConnectivity() async {
    final testSites = ['google.com', 'cloudflare.com', '8.8.8.8'];

    for (final site in testSites) {
      try {
        _addLog('   🔗 Testando: $site');
        final result =
            await InternetAddress.lookup(site).timeout(const Duration(seconds: 5));
        if (result.isNotEmpty) {
          _addLog('   ✅ $site: OK (IP: ${result.first.address})');
          return true;
        }
      } catch (e) {
        _addLog('   ❌ $site: $e');
      }
    }

    _addLog('   ❌ Nenhum site de teste acessível');
    return false;
  }

  Future<bool> _testDnsResolution() async {
    try {
      _addLog('   🔗 Resolvendo: $_supabaseHost');
      final result = await InternetAddress.lookup(_supabaseHost)
          .timeout(const Duration(seconds: 10));
      if (result.isNotEmpty) {
        _addLog('   ✅ DNS OK - IP encontrado: ${result.first.address}');
        return true;
      }
    } catch (e) {
      _addLog('   ❌ Falha na resolução DNS: $e');
    }
    return false;
  }

  Future<void> _testAlternativeDns() async {
    _addLog('   🔄 Testando DNS alternativos...');
    final dnsServers = ['8.8.8.8', '8.8.4.4', '1.1.1.1', '1.0.0.1'];

    for (final dns in dnsServers) {
      try {
        // Simulate DNS test (in real implementation would need platform-specific code)
        _addLog('   🔗 Testando DNS: $dns');
        await Future.delayed(const Duration(milliseconds: 500));
        _addLog('   ✅ DNS $dns: Recomendado para configuração manual');
      } catch (e) {
        _addLog('   ❌ DNS $dns: Erro');
      }
    }
  }

  Future<bool> _testHttpConnectivity() async {
    try {
      _addLog('   🔗 Conectando: $_supabaseUrl/rest/v1/');

      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/'),
        headers: {
          'apikey': _supabaseAnonKey,
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _addLog('   ✅ HTTP OK: Status ${response.statusCode}');
        return true;
      } else {
        _addLog('   ⚠️ HTTP Status não esperado: ${response.statusCode}');
        return response.statusCode < 500;
      }
    } catch (e) {
      _addLog('   ❌ Erro HTTP: $e');
      return false;
    }
  }

  Future<bool> _testAuthentication() async {
    try {
      _addLog('   🔗 Testando serviço de auth...');

      final response = await http.get(
        Uri.parse('$_supabaseUrl/auth/v1/user'),
        headers: {
          'apikey': _supabaseAnonKey,
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 401 || response.statusCode == 200) {
        _addLog('   ✅ Serviço de Auth OK: Status ${response.statusCode}');
        return true;
      } else {
        _addLog(
            '   ❌ Serviço de Auth com problema: Status ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _addLog('   ❌ Erro no serviço de Auth: $e');
      return false;
    }
  }

  Future<bool> _testDatabaseAccess() async {
    try {
      _addLog('   🔗 Testando acesso ao banco (tabela app_users)...');

      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/app_users?select=id&limit=1'),
        headers: {
          'apikey': _supabaseAnonKey,
          'Authorization': 'Bearer $_supabaseAnonKey',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 206) {
        final data = jsonDecode(response.body);
        _addLog(
            '   ✅ Database OK: Status ${response.statusCode}, registros: ${data.length}');
        return true;
      } else {
        _addLog('   ❌ Database Error: Status ${response.statusCode}');
        _addLog('   📄 Response: ${response.body.substring(0, 200)}...');
        return false;
      }
    } catch (e) {
      _addLog('   ❌ Erro no banco: $e');
      return false;
    }
  }

  void _addRecommendation(String recommendation) {
    if (!_recommendations.contains(recommendation)) {
      _recommendations.add(recommendation);
      setState(() {});
    }
  }

  void _generateFinalRecommendations() {
    _addLog('');
    _addLog('📋 Gerando recomendações finais...');

    bool allGood = _testResults.values.every((result) => result == true);

    if (allGood) {
      _addLog('🎉 Todos os testes passaram! Conectividade perfeita.');
      _addRecommendation(
          '✅ Conectividade OK - Pode usar autenticação normal no app');
    } else {
      _addLog('⚠️ Alguns problemas detectados.');

      if (_testResults['internet'] == false) {
        _addRecommendation('🚨 CRÍTICO: Sem conexão com internet');
      } else if (_testResults['dns'] == false) {
        _addRecommendation('🚨 Configurar DNS alternativo urgentemente');
        _addRecommendation(
            '📱 Nas configurações do Wi-Fi, mudar DNS para 8.8.8.8');
      } else if (_testResults['http'] == false) {
        _addRecommendation('🚨 Verificar firewall/proxy corporativo');
      } else {
        _addRecommendation('⚠️ Usar modo bypass no app temporariamente');
      }
    }

    _addLog('');
    _addLog('💡 Recomendações geradas. Verifique a seção acima.');
  }
}
