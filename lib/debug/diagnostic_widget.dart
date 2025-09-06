import 'package:flutter/material.dart';
import 'diagnostic_runner.dart';

class DiagnosticWidget extends StatefulWidget {
  const DiagnosticWidget({Key? key}) : super(key: key);

  @override
  State<DiagnosticWidget> createState() => _DiagnosticWidgetState();
}

class _DiagnosticWidgetState extends State<DiagnosticWidget> {
  bool _isRunning = false;
  Map<String, dynamic>? _results;
  String? _error;

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunning = true;
      _error = null;
      _results = null;
    });

    try {
      final results = await DiagnosticRunner.runDiagnostics();
      setState(() {
        _results = results;
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔧 Ferramenta de Diagnóstico',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Esta ferramenta irá diagnosticar problemas comuns no sistema:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text('• Configuração de ambiente (Supabase URL/Key)'),
            const Text('• Inicialização do Supabase'),
            const Text('• Conectividade com o banco de dados'),
            const Text('• Firebase Storage'),
            const Text('• Upload de arquivos'),
            const SizedBox(height: 16),
            
            if (_isRunning) ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Executando diagnóstico...'),
                  ],
                ),
              ),
            ] else if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '❌ Erro durante o diagnóstico:',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (_results != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 Resultados do Diagnóstico:',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._buildResultsList(_results!),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _runDiagnostics,
                icon: const Icon(Icons.bug_report),
                label: Text(_isRunning ? 'Diagnosticando...' : 'Executar Diagnóstico'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            if (_results != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _results = null;
                      _error = null;
                    });
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpar Resultados'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResultsList(Map<String, dynamic> results) {
    final widgets = <Widget>[];
    
    results.forEach((key, value) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '📋 $key:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
      
      if (value is Map) {
        value.forEach((subKey, subValue) {
          final status = subValue == true ? '✅' : (subValue == false ? '❌' : 'ℹ️');
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Text('   $status $subKey: $subValue'),
            ),
          );
        });
      } else {
        final status = value == true ? '✅' : (value == false ? '❌' : 'ℹ️');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 2),
            child: Text('   $status $value'),
          ),
        );
      }
    });
    
    return widgets;
  }
}

/// Widget de diagnóstico simplificado para debug rápido
class QuickDiagnosticButton extends StatelessWidget {
  final VoidCallback? onDiagnosticComplete;
  
  const QuickDiagnosticButton({Key? key, this.onDiagnosticComplete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        try {
          final results = await DiagnosticRunner.runDiagnostics();
          
          // Mostrar resultado em um dialog
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('🔍 Diagnóstico Rápido'),
                content: SingleChildScrollView(
                  child: _buildQuickResults(results),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            );
          }
          
          onDiagnosticComplete?.call();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Erro no diagnóstico: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      tooltip: 'Executar Diagnóstico',
      child: const Icon(Icons.bug_report),
    );
  }

  Widget _buildQuickResults(Map<String, dynamic> results) {
    final issues = <String>[];
    
    // Verificar problemas críticos
    final envResults = results['environment'] as Map<String, dynamic>?;
    if (envResults != null) {
      if (envResults['supabaseUrl_empty'] == true) {
        issues.add('❌ SUPABASE_URL vazia');
      }
      if (envResults['supabaseAnonKey_empty'] == true) {
        issues.add('❌ SUPABASE_ANON_KEY vazia');
      }
    }
    
    final supabaseResults = results['supabase'] as Map<String, dynamic>?;
    if (supabaseResults != null) {
      if (supabaseResults['helper_initialized'] == false) {
        issues.add('⚠️ Supabase não inicializado');
      }
      if (supabaseResults['helper_client_available'] == false) {
        issues.add('⚠️ Cliente Supabase indisponível');
      }
      if (supabaseResults['query_test_success'] == false) {
        issues.add('⚠️ Falha na conexão com banco');
      }
    }
    
    if (issues.isEmpty) {
      return const Text('✅ Todos os sistemas operacionais!');
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: issues.map((issue) => Text(issue)).toList(),
    );
  }
}