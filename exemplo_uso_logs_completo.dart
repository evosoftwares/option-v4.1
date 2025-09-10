/// EXEMPLO DE USO DOS LOGS IMPLEMENTADOS
/// Este arquivo demonstra como os logs estruturados funcionam em todos os CRUDs principais
library;

import 'package:flutter/material.dart';
import 'lib/services/app_logger.dart';
import 'lib/services/auth_service.dart';
import 'lib/services/user_service.dart';
import 'lib/services/trip_service.dart';
import 'lib/services/payment_service.dart';

class LoggingExamplesDemo extends StatelessWidget {
  const LoggingExamplesDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logging System Demo - OPTION App'),
        backgroundColor: Colors.blue[600],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('🔐 Sistema de Logs Abrangente'),
            _buildDescription('Implementação completa de logs em todos os CRUDs principais da aplicação OPTION.'),
            
            const SizedBox(height: 24),
            _buildSectionTitle('📊 Categorias de Logs Implementadas'),
            
            _buildLogCategory('CRUD Operations', [
              '➕ CREATE - Logs de criação de registros',
              '👁️ READ - Logs de consultas e buscas',
              '✏️ UPDATE - Logs de atualizações',
              '🗑️ DELETE - Logs de exclusões',
              '🔍 QUERY - Logs de consultas múltiplas'
            ]),
            
            _buildLogCategory('Business Operations', [
              '💰 TRANSACTION - Logs de transações financeiras',
              '🚗 TRIP - Logs de operações de viagens',
              '📍 LOCATION - Logs de localização',
              '🔔 NOTIFICATION - Logs de notificações',
              '📤 UPLOAD - Logs de upload de arquivos'
            ]),
            
            _buildLogCategory('System Operations', [
              '🔐 SECURITY - Logs de eventos de segurança',
              '⚡ PERFORMANCE - Logs de métricas de performance',
              '🔍 VALIDATION - Logs de validações',
              '💾 CACHE - Logs de operações de cache',
              '🔄 SYNC - Logs de sincronização'
            ]),
            
            const SizedBox(height: 24),
            _buildSectionTitle('🏗️ Serviços com Logs Implementados'),
            
            _buildServiceCard('AuthService', '🔐', [
              'Login/Logout com logs de segurança',
              'Registro de usuário com rollback tracking',
              'Verificação de permissões',
              'Reset de senha com auditoria',
              'Atualização de perfil'
            ]),
            
            _buildServiceCard('UserService', '👥', [
              'CRUD completo de usuários',
              'Validação de dados com logs',
              'Busca por ID/Email com performance',
              'Criação de registros específicos',
              'Soft delete com auditoria'
            ]),
            
            _buildServiceCard('DriverService', '🚗', [
              'Busca de motoristas',
              'Gerenciamento de status',
              'Operações de localização',
              'Matching de viagens',
              'Validações de documentos'
            ]),
            
            _buildServiceCard('TripService', '🛣️', [
              'Criação de solicitações',
              'Matching motorista-passageiro',
              'Tracking de viagem em tempo real',
              'Cálculos de tarifa',
              'Finalização e avaliação'
            ]),
            
            _buildServiceCard('PaymentService', '💳', [
              'Métodos de pagamento',
              'Processamento de transações',
              'Logs de segurança financeira',
              'Auditoria de acessos',
              'Validações de pagamento'
            ]),
            
            _buildServiceCard('WalletService', '💰', [
              'Operações de carteira',
              'Transações financeiras',
              'Saldo e histórico',
              'Transferências',
              'Logs de movimentação'
            ]),
            
            _buildServiceCard('DriverDocumentService', '📄', [
              'Upload de documentos',
              'Validação de arquivos',
              'Controle de vencimento',
              'Aprovação/Rejeição',
              'Histórico de alterações'
            ]),
            
            const SizedBox(height: 24),
            _buildSectionTitle('🎯 Exemplos Práticos de Logs'),
            
            _buildCodeExample(),
            
            const SizedBox(height: 24),
            _buildSectionTitle('🔧 Configurações do Sistema'),
            
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Configurações Automáticas:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('• Mascaramento automático de dados sensíveis'),
                    Text('• Logs apenas em modo debug (produção segura)'),
                    Text('• Performance tracking integrado'),
                    Text('• Sanitização de dados para logs'),
                    Text('• Contexto detalhado para debugging'),
                    Text('• Emojis para identificação visual rápida'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            _buildSectionTitle('🎨 Como Usar'),
            
            Card(
              color: Colors.green[50],
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('O sistema de logs funciona automaticamente:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Text('1. Execute qualquer operação nos serviços'),
                    Text('2. Os logs aparecerão automaticamente no console'),
                    Text('3. Apenas em modo debug - produção permanece limpa'),
                    Text('4. Dados sensíveis são automaticamente mascarados'),
                    Text('5. Performance e segurança são trackadas automaticamente'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[700]),
      ),
    );
  }
  
  Widget _buildDescription(String description) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(description, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
  
  Widget _buildLogCategory(String title, List<String> items) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: items.map((item) => ListTile(
          dense: true,
          title: Text(item),
          leading: const Icon(Icons.circle, size: 8),
        )).toList(),
      ),
    );
  }
  
  Widget _buildServiceCard(String service, String emoji, List<String> features) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(service, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        children: features.map((feature) => ListTile(
          dense: true,
          title: Text(feature),
          leading: const Icon(Icons.check_circle, color: Colors.green, size: 16),
        )).toList(),
      ),
    );
  }
  
  Widget _buildCodeExample() {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Exemplo de Logs Gerados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _logLine('🔄', '[AUTH] Tentando login'),
                  _logLine('🔐', '[SECURITY] login_attempt [User: jo***@email.com]'),
                  _logLine('✅', '[AUTH] Login realizado com sucesso'),
                  _logLine('👁️', '[AUTH] AppUser consultado [ID: abc1***]'),
                  _logLine('🚀', '[PERFORMANCE] user_login executado em 245ms'),
                  _logLine('🔐', '[SECURITY] login_success [User: abc1***]'),
                  const SizedBox(height: 8),
                  _logLine('➕', '[USER_SERVICE] User criado [ID: def2***]'),
                  _logLine('💾', '[CREATE] Dados: {full_name: true, email: true, phone: true}'),
                  _logLine('⚡', '[PERFORMANCE] user_creation executado em 156ms'),
                  const SizedBox(height: 8),
                  _logLine('🚗', '[TRIP] solicitation_created - Viagem: abc3*** [Passageiro: def4***]'),
                  _logLine('💰', '[TRANSACTION] fare_calculation - R\$ 15.50 [User: def4***]'),
                  _logLine('🔔', '[NOTIFICATION] ✅ trip_request enviado para abc1***'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _logLine(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          children: [
            TextSpan(text: emoji, style: const TextStyle(color: Colors.white)),
            TextSpan(text: ' $text', style: TextStyle(color: Colors.green[300])),
          ],
        ),
      ),
    );
  }
}

/// EXEMPLO PRÁTICO DE USO DOS LOGS EM OPERAÇÕES REAIS
class LoggingSystemDemo {
  
  /// Demonstra logs em uma operação de login completa
  static Future<void> demonstrarLoginComLogs() async {
    // Os logs são gerados automaticamente ao usar os serviços
    try {
      final result = await AuthService.signIn(
        email: 'usuario@exemplo.com',
        password: 'senha123'
      );
      
      // Logs gerados automaticamente:
      // 🔄 [AUTH] Tentando login
      // 🔐 [SECURITY] login_attempt [User: us***@exemplo.com]  
      // ✅ [AUTH] Login realizado com sucesso
      // 👁️ [AUTH] AppUser consultado [ID: abc1***]
      // 🚀 [PERFORMANCE] user_login executado em 245ms
      // 🔐 [SECURITY] login_success [User: abc1***]
      
    } catch (e) {
      // Em caso de erro, logs automáticos:
      // ❌ [AUTH] AuthException durante login
      // 🔐 [SECURITY] login_failed [Details: Invalid credentials]
    }
  }
  
  /// Demonstra logs em operação de criação de usuário
  static Future<void> demonstrarCriacaoUsuarioComLogs() async {
    try {
      final user = await UserService.createUser(
        authUserId: 'auth-uuid-123',
        email: 'novo@usuario.com',
        fullName: 'Novo Usuário',
        phone: '11999999999',
        userType: 'passenger'
      );
      
      // Logs gerados automaticamente:
      // 🔄 [USER_SERVICE] Iniciando criação de usuário
      // ➕ [CREATE] User Creation Attempt [ID: auth***] 
      // ✅ [VALIDATION] phone_required válido [User]
      // 🔍 [QUERY] app_users consultado - 0 registros (verificação email)
      // ➕ [USER_SERVICE] User criado [ID: auth***]
      // ✅ [CREATE] AppUser [ID: auth***]
      // 🚀 [PERFORMANCE] user_registration executado em 312ms
      // 🔐 [SECURITY] user_registration_success [User: auth***]
      
    } catch (e) {
      // Logs de erro automáticos com contexto detalhado
    }
  }
  
  /// Demonstra logs em operação de viagem
  static Future<void> demonstrarViagemComLogs() async {
    final tripService = TripService(/* supabase client */);
    
    try {
      final tripRequest = await tripService.createTripRequest(
        passengerId: 'passenger-123',
        originAddress: 'Rua A, 123',
        originLatitude: -23.5505,
        originLongitude: -46.6333,
        destinationAddress: 'Rua B, 456',
        destinationLatitude: -23.5515,
        destinationLongitude: -46.6343,
        vehicleCategory: 'comum',
        needsPet: false,
        needsGrocerySpace: false,
        isCondoDestination: false,
        isCondoOrigin: false,
        needsAc: true,
        numberOfStops: 0,
        estimatedDistanceKm: 5.2,
        estimatedDurationMinutes: 15,
        estimatedFare: 12.50,
      );
      
      // Logs gerados automaticamente:
      // 🔄 [TRIP_SERVICE] Iniciando criação de solicitação de viagem
      // ➕ [CREATE] TripRequest [ID: passenger-123]
      // 🔐 [SECURITY] trip_request_auth_validated [User: pass***]
      // 🚗 [TRIP] solicitation_created - Viagem: GENERATING [Passageiro: pass***]
      // 💰 [TRANSACTION] fare_calculation - R$ 12.50 [User: pass***]
      // 🚀 [PERFORMANCE] create_trip_request executado em 189ms
      
    } catch (e) {
      // Logs de erro com contexto completo da operação
    }
  }
  
  /// Demonstra logs em operações de pagamento
  static Future<void> demonstrarPagamentoComLogs() async {
    try {
      final paymentMethods = await PaymentService.getPaymentMethods();
      
      // Logs gerados automaticamente:
      // 🔄 [PAYMENT_SERVICE] Iniciando busca de métodos de pagamento
      // 🔍 [QUERY] payment_methods - filtros: {user_id: usr***, is_active: true}
      // 🚀 [PERFORMANCE] get_payment_methods executado em 95ms
      // ✅ [PAYMENT_SERVICE] Métodos de pagamento carregados
      // 🔍 [QUERY] payment_methods retornou 3 registros
      // 💰 [TRANSACTION] payment_methods_access - R$ 0 [User: usr***]
      
    } catch (e) {
      // Logs de erro em operações financeiras
    }
  }
  
  /// Demonstra logs personalizados adicionais
  static void demonstrarLogsPersonalizados() {
    // Logs manuais para operações específicas
    AppLogger.debug('Iniciando processo customizado', tag: 'CUSTOM');
    AppLogger.info('Processando dados do usuário', tag: 'CUSTOM');
    AppLogger.success('Operação customizada concluída', tag: 'CUSTOM');
    
    // Logs com dados estruturados
    AppLogger.create('CustomEntity', 'entity-123', tag: 'CUSTOM', data: {
      'operation': 'custom_process',
      'timestamp': DateTime.now().toIso8601String(),
      'user_agent': 'Flutter Mobile'
    });
    
    // Logs de performance personalizados
    final startTime = DateTime.now();
    // ... operação ...
    final duration = DateTime.now().difference(startTime);
    AppLogger.performance('custom_operation', duration, tag: 'CUSTOM', metrics: {
      'records_processed': 150,
      'cache_hits': 12,
      'api_calls': 3
    });
    
    // Logs de cache
    AppLogger.cache('HIT', 'user_profile_123', tag: 'CUSTOM');
    AppLogger.cache('MISS', 'user_settings_456', tag: 'CUSTOM');
    
    // Logs de validação
    AppLogger.validation('email_format', true, entity: 'User');
    AppLogger.validation('phone_number', false, entity: 'User', error: 'Invalid format');
    
    // Logs de localização
    AppLogger.location('location_updated', userId: 'user-123', coordinates: {
      'latitude': -23.5505,
      'longitude': -46.6333,
      'accuracy': 10.5
    });
    
    // Logs de notificação
    AppLogger.notification('push_notification', 'user-123', title: 'Nova viagem disponível', success: true);
    
    // Logs de sincronização
    AppLogger.sync('user_data', 'uploaded', count: 5, direction: 'client_to_server');
    AppLogger.sync('trip_history', 'downloaded', count: 20, direction: 'server_to_client');
  }
}

/// CONFIGURAÇÃO PARA ATIVAR/DESATIVAR LOGS EM TESTE
class LoggingConfiguration {
  
  static void configurarLogsParaTeste() {
    // Forçar logs mesmo em release mode para testes
    AppLogger.enableDebugMode();
    
    print('🔧 Sistema de logs ativado para demonstração');
    print('📊 Todos os CRUDs principais possuem logs estruturados');
    print('🔒 Dados sensíveis são automaticamente mascarados');
    print('⚡ Performance é trackada em todas as operações');
    print('🔐 Eventos de segurança são registrados automaticamente');
  }
  
  static void desativarLogsAposTeste() {
    // Desativar logs forçados
    AppLogger.disableDebugMode();
    
    print('✅ Sistema de logs retornou ao modo produção');
  }
}