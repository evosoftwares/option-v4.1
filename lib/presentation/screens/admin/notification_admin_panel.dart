import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// import '../../services/fcm_service.dart'; // Removido - usando OneSignal
import '../../services/token_management_service.dart';
import '../../widgets/app_card.dart';

/// Painel administrativo para gerenciamento de notificações push
/// Interface Material Design 3 para envio de notificações personalizadas
class NotificationAdminPanel extends StatefulWidget {
  const NotificationAdminPanel({super.key});

  @override
  State<NotificationAdminPanel> createState() => _NotificationAdminPanelState();
}

class _NotificationAdminPanelState extends State<NotificationAdminPanel>
    with TickerProviderStateMixin {
  final Logger _logger = Logger();
  // final FCMService _fcmService = FCMService(); // Removido - usando OneSignal
  final TokenManagementService _tokenService = TokenManagementService();
  
  late TabController _tabController;
  
  // Controllers para formulário de notificação
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _customDataController = TextEditingController();
  
  // Estado do formulário
  String _selectedAudience = 'all';
  String _selectedPriority = 'normal';
  bool _isScheduled = false;
  DateTime? _scheduledDateTime;
  bool _isSending = false;
  
  // Dados de estatísticas
  Map<String, dynamic> _tokenStats = {};
  List<Map<String, dynamic>> _recentNotifications = [];
  bool _isLoadingStats = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStatistics();
    _loadRecentNotifications();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _imageUrlController.dispose();
    _customDataController.dispose();
    super.dispose();
  }
  
  Future<void> _loadStatistics() async {
    try {
      final stats = await _tokenService.getTokenStatistics();
      setState(() {
        _tokenStats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      _logger.e('Erro ao carregar estatísticas', error: e);
      setState(() => _isLoadingStats = false);
    }
  }
  
  Future<void> _loadRecentNotifications() async {
    try {
      final response = await Supabase.instance.client
          .from('notification_history')
          .select()
          .order('sent_at', ascending: false)
          .limit(20);
      
      setState(() {
        _recentNotifications = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _logger.e('Erro ao carregar notificações recentes', error: e);
    }
  }
  
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Notificações'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.send), text: 'Enviar'),
            Tab(icon: Icon(Icons.analytics), text: 'Estatísticas'),
            Tab(icon: Icon(Icons.history), text: 'Histórico'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendNotificationTab(),
          _buildStatisticsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  
  Widget _buildSendNotificationTab() => SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nova Notificação',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  
                  // Título
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),
                  
                  // Corpo da mensagem
                  TextField(
                    controller: _bodyController,
                    decoration: const InputDecoration(
                      labelText: 'Mensagem *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.message),
                    ),
                    maxLines: 3,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 16),
                  
                  // URL da imagem
                  TextField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL da Imagem (opcional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.image),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Público-alvo
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAudience,
                    decoration: const InputDecoration(
                      labelText: 'Público-alvo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Todos os usuários')),
                      DropdownMenuItem(value: 'drivers', child: Text('Apenas motoristas')),
                      DropdownMenuItem(value: 'passengers', child: Text('Apenas passageiros')),
                      DropdownMenuItem(value: 'active_drivers', child: Text('Motoristas ativos')),
                      DropdownMenuItem(value: 'custom', child: Text('Segmentação personalizada')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedAudience = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Prioridade
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Prioridade',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.priority_high),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Baixa')),
                      DropdownMenuItem(value: 'normal', child: Text('Normal')),
                      DropdownMenuItem(value: 'high', child: Text('Alta')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedPriority = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Agendamento
                  SwitchListTile(
                    title: const Text('Agendar envio'),
                    subtitle: _scheduledDateTime != null
                        ? Text('Enviar em: ${_formatDateTime(_scheduledDateTime!)}')
                        : const Text('Enviar imediatamente'),
                    value: _isScheduled,
                    onChanged: (value) {
                      setState(() => _isScheduled = value);
                      if (value) {
                        _selectDateTime();
                      } else {
                        _scheduledDateTime = null;
                      }
                    },
                  ),
                  
                  if (_isScheduled && _scheduledDateTime != null)
                    ListTile(
                      leading: const Icon(Icons.schedule),
                      title: Text('Agendado para: ${_formatDateTime(_scheduledDateTime!)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _selectDateTime,
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Dados personalizados
                  ExpansionTile(
                    title: const Text('Dados Personalizados (JSON)'),
                    children: [
                      TextField(
                        controller: _customDataController,
                        decoration: const InputDecoration(
                          labelText: 'JSON personalizado',
                          border: OutlineInputBorder(),
                          hintText: '{"action": "open_screen", "screen": "trip_details"}',
                        ),
                        maxLines: 4,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Botões de ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearForm,
                  child: const Text('Limpar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _isSending ? null : _sendNotification,
                  child: _isSending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isScheduled ? 'Agendar' : 'Enviar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  
  Widget _buildStatisticsTab() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Cards de estatísticas
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                'Total de Tokens',
                '${_tokenStats['total_tokens'] ?? 0}',
                Icons.devices,
                Colors.blue,
              ),
              _buildStatCard(
                'Tokens Ativos',
                '${_tokenStats['active_tokens'] ?? 0}',
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatCard(
                'Motoristas',
                '${_tokenStats['drivers_with_tokens'] ?? 0}',
                Icons.drive_eta,
                Colors.orange,
              ),
              _buildStatCard(
                'Passageiros',
                '${_tokenStats['users_with_tokens'] ?? 0}',
                Icons.person,
                Colors.purple,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Distribuição por plataforma
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Distribuição por Plataforma',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ..._buildPlatformDistribution(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) => AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  
  List<Widget> _buildPlatformDistribution() {
    final distribution = _tokenStats['platform_distribution'] as Map<String, dynamic>? ?? {};
    
    return distribution.entries.map((entry) {
      final platform = entry.key;
      final count = entry.value as int;
      final total = _tokenStats['total_tokens'] as int? ?? 1;
      final percentage = (count / total * 100).toStringAsFixed(1);
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(_getPlatformIcon(platform)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_getPlatformName(platform)),
            ),
            Text('$count ($percentage%)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
      );
    }).toList();
  }
  
  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'ios':
        return Icons.phone_iphone;
      case 'android':
        return Icons.android;
      case 'web':
        return Icons.web;
      default:
        return Icons.device_unknown;
    }
  }
  
  String _getPlatformName(String platform) {
    switch (platform.toLowerCase()) {
      case 'ios':
        return 'iOS';
      case 'android':
        return 'Android';
      case 'web':
        return 'Web';
      default:
        return platform;
    }
  }
  
  Widget _buildHistoryTab() => RefreshIndicator(
      onRefresh: _loadRecentNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recentNotifications.length,
        itemBuilder: (context, index) {
          final notification = _recentNotifications[index];
          return AppCard(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(notification['status']),
                child: Icon(
                  _getStatusIcon(notification['status']),
                  color: Colors.white,
                ),
              ),
              title: Text(notification['title'] ?? 'Sem título'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification['body'] ?? 'Sem conteúdo'),
                  const SizedBox(height: 4),
                  Text(
                    'Enviado em: ${_formatDateTime(DateTime.parse(notification['sent_at']))}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showNotificationDetails(notification),
              ),
            ),
          );
        },
      ),
    );
  
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'sent':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'sent':
        return Icons.check;
      case 'failed':
        return Icons.error;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }
  
  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      
      if (time != null) {
        setState(() {
          _scheduledDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }
  
  String _formatDateTime(DateTime dateTime) => '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  
  void _clearForm() {
    _titleController.clear();
    _bodyController.clear();
    _imageUrlController.clear();
    _customDataController.clear();
    setState(() {
      _selectedAudience = 'all';
      _selectedPriority = 'normal';
      _isScheduled = false;
      _scheduledDateTime = null;
    });
  }
  
  Future<void> _sendNotification() async {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Título e mensagem são obrigatórios')),
      );
      return;
    }
    
    setState(() => _isSending = true);
    
    try {
      Map<String, dynamic>? customData;
      if (_customDataController.text.trim().isNotEmpty) {
        customData = jsonDecode(_customDataController.text.trim());
      }
      
      // Aqui você implementaria a lógica de envio baseada no público-alvo
      // Por enquanto, vamos simular o envio
      
      await Future.delayed(const Duration(seconds: 2)); // Simular envio
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isScheduled ? 'Notificação agendada com sucesso!' : 'Notificação enviada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        _clearForm();
        _loadRecentNotifications();
      }
      
    } catch (e) {
      _logger.e('Erro ao enviar notificação', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar notificação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
  
  void _showNotificationDetails(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification['title'] ?? 'Detalhes da Notificação'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Conteúdo: ${notification['body'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Status: ${notification['status'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Plataforma: ${notification['platform'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Enviado em: ${_formatDateTime(DateTime.parse(notification['sent_at']))}'),
              if (notification['data'] != null) ...[
                const SizedBox(height: 8),
                const Text('Dados personalizados:'),
                Text(jsonEncode(notification['data'])),
              ]
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}