import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_config.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class SupabaseDebugScreen extends StatefulWidget {
  const SupabaseDebugScreen({super.key});

  @override
  State<SupabaseDebugScreen> createState() => _SupabaseDebugScreenState();
}

class _SupabaseDebugScreenState extends State<SupabaseDebugScreen> {
  final List<String> _logs = [];
  bool _isLoading = false;
  final SupabaseClient _supabase = Supabase.instance.client;

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String()}: $message');
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    try {
      _addLog('🔄 Iniciando teste de conectividade...');
      
      // Test 1: Basic connection
      _addLog('✅ Cliente Supabase inicializado');
      _addLog('📍 URL: ${AppConfig.supabaseUrl}');
      
      // Test 2: Auth status
      final user = _supabase.auth.currentUser;
      _addLog('👤 Usuário atual: ${user?.email ?? "Não autenticado"}');
      
      // Test 3: Simple query to trip_requests table
      _addLog('🔍 Testando consulta na tabela trip_requests...');
      final response = await _supabase
          .from('trip_requests')
          .select('id, status, created_at')
          .limit(5);
      
      _addLog('✅ Consulta realizada com sucesso!');
      _addLog('📊 Registros encontrados: ${response.length}');
      
      if (response.isNotEmpty) {
        _addLog('📝 Primeiro registro: ${response.first}');
      }
      
      // Test 4: Test drivers table
      _addLog('🔍 Testando consulta na tabela drivers...');
      final driversResponse = await _supabase
          .from('drivers')
          .select('id, approval_status, is_online')
          .limit(3);
      
      _addLog('✅ Consulta drivers realizada com sucesso!');
      _addLog('🚗 Motoristas encontrados: ${driversResponse.length}');
      
      // Test 5: Test real-time subscription
      _addLog('🔄 Testando subscription em tempo real...');
      final subscription = _supabase
          .from('trip_requests')
          .stream(primaryKey: ['id'])
          .listen((data) {
            _addLog('📡 Real-time update recebido: ${data.length} registros');
          });
      
      // Cancel subscription after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      subscription.cancel();
      _addLog('✅ Subscription testada e cancelada');
      
      _addLog('🎉 Todos os testes de conectividade passaram!');
      
    } catch (e) {
      _addLog('❌ Erro durante o teste: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: Text(
          'Debug Supabase',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.lightOnSurface,
          ),
        ),
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightPrimary,
                foregroundColor: AppColors.lightOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Testar Conectividade',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.lightOnPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.lightOutline),
                ),
                child: _logs.isEmpty
                    ? Center(
                        child: Text(
                          'Clique no botão acima para testar a conectividade',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.lightOnSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
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
                              style: AppTypography.bodySmall.copyWith(
                                color: log.contains('❌')
                                    ? AppColors.error
                                    : log.contains('✅')
                                        ? AppColors.success
                                        : AppColors.lightOnSurface,
                                fontFamily: 'monospace',
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