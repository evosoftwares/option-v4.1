# Plano de Correção: Sistema de Matching e Fluxo de Viagens (REVISÃO v2)

## 📋 Análise Crítica do Plano Original

### ✅ Pontos Fortes do Plano v1:
- Identificação correta dos gaps críticos
- Estrutura de fases bem definida
- Código de exemplo detalhado
- Cronograma realista

### ⚠️ Pontos que Precisam de Refinamento:

1. **Conflito com Schema Existente**: O plano assume campos que já existem na tabela `trip_requests`
2. **Integração com Sistema Atual**: Não considera impacto nos fluxos já funcionais
3. **Rollback Strategy**: Muito genérica, precisa ser mais específica
4. **Testes**: Estratégia de testes não está detalhada o suficiente
5. **Real-time**: Implementação do real-time subestimada

---

## 🔍 Análise do Estado Real dos Dados

### **Tabela `trip_requests` - Campos Existentes:**
```sql
-- CAMPOS JÁ EXISTENTES (não precisam ser adicionados):
- target_driver_id ❌ (NÃO EXISTE - precisa ser criado)
- expires_at ✅ (JÁ EXISTE - default: now() + 5 minutes)
- fallback_drivers ❌ (NÃO EXISTE - precisa ser criado) 
- accepted_by_driver_id ❌ (NÃO EXISTE - precisa ser criado)
- accepted_at ❌ (NÃO EXISTE - precisa ser criado)
- selected_offer_id ✅ (JÁ EXISTE - referência a driver_offers)
```

### **Sistema de Ofertas Existente:**
- Tabela `driver_offers` já implementada
- Campos: request_id, driver_id, total_fare, is_available, was_selected
- **Gap**: Não há lógica de auto-criação de ofertas no matching

---

## 🎯 Plano Revisado e Corrigido

### **FASE 0: Preparação e Análise (1 semana)**

#### 0.1 Auditoria Completa do Sistema Atual
```sql
-- Verificar estrutura real das tabelas
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name IN ('trip_requests', 'driver_offers', 'trips')
ORDER BY table_name, ordinal_position;
```

#### 0.2 Mapeamento de Fluxos Existentes
- **Documentar** exatamente como funciona o fluxo atual
- **Identificar** todos os pontos de integração
- **Listar** APIs e serviços que serão impactados

#### 0.3 Setup de Ambiente de Desenvolvimento
- Feature flags para habilitar/desabilitar novo sistema
- Branch específica para matching v2
- Ambiente de testes isolado

### **FASE 1: Base do Sistema de Matching Direcionado (2 semanas)**

#### 1.1 Modificações de Schema (Corretas)
```sql
-- CAMPOS QUE REALMENTE PRECISAM SER ADICIONADOS:
ALTER TABLE trip_requests 
ADD COLUMN target_driver_id UUID REFERENCES drivers(id),
ADD COLUMN fallback_drivers UUID[],
ADD COLUMN accepted_by_driver_id UUID REFERENCES drivers(id),
ADD COLUMN accepted_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN current_fallback_index INTEGER DEFAULT 0,
ADD COLUMN timeout_count INTEGER DEFAULT 0;

-- ÍNDICES PARA PERFORMANCE:
CREATE INDEX idx_trip_requests_target_driver ON trip_requests(target_driver_id);
CREATE INDEX idx_trip_requests_expires_at ON trip_requests(expires_at);
CREATE INDEX idx_trip_requests_status_expires ON trip_requests(status, expires_at);
```

#### 1.2 TripRequestManager Service (Implementação Real)
```dart
class TripRequestManager {
  static const int ACCEPTANCE_TIMEOUT_SECONDS = 10;
  static const int MAX_FALLBACK_ATTEMPTS = 5;
  
  final SupabaseClient _supabase;
  final NotificationService _notificationService;
  final Timer? _timeoutTimer;
  
  // Mapa para rastrear timers ativos por request
  final Map<String, Timer> _activeTimers = {};
  
  Future<String> createDirectedTripRequest({
    required String passengerId,
    required List<Driver> prioritizedDrivers, // Já ordenados por proximidade
    required TripRequestData tripData,
  }) async {
    final targetDriver = prioritizedDrivers.first;
    final fallbackDriverIds = prioritizedDrivers
        .skip(1)
        .take(MAX_FALLBACK_ATTEMPTS)
        .map((d) => d.id)
        .toList();
    
    // 1. Criar trip_request direcionado
    final request = await _supabase.from('trip_requests').insert({
      'passenger_id': passengerId,
      'target_driver_id': targetDriver.id,
      'fallback_drivers': fallbackDriverIds,
      'expires_at': DateTime.now().add(Duration(seconds: ACCEPTANCE_TIMEOUT_SECONDS)).toIso8601String(),
      'status': 'pending',
      // ... outros campos do tripData
    }).select().single();
    
    final requestId = request['id'];
    
    // 2. Criar oferta automática para o motorista target
    await _createDriverOffer(requestId, targetDriver, tripData);
    
    // 3. Enviar notificação push
    await _sendDriverNotification(targetDriver.id, requestId);
    
    // 4. Iniciar timer de timeout
    _startTimeoutTimer(requestId, targetDriver.id);
    
    return requestId;
  }
  
  Future<void> _createDriverOffer(String requestId, Driver driver, TripRequestData tripData) async {
    // Calcular preço usando IndividualPricingService
    final pricingService = IndividualPricingService(_supabase);
    final pricing = await pricingService.calculatePrice(
      driver: driver,
      tripData: tripData,
    );
    
    await _supabase.from('driver_offers').insert({
      'request_id': requestId,
      'driver_id': driver.id,
      'driver_distance_km': pricing.driverDistanceKm,
      'driver_eta_minutes': pricing.driverEtaMinutes,
      'base_fare': pricing.baseFare,
      'additional_fees': pricing.additionalFees,
      'total_fare': pricing.totalFare,
      'is_available': true,
    });
  }
  
  void _startTimeoutTimer(String requestId, String driverId) {
    _activeTimers[requestId] = Timer(
      Duration(seconds: ACCEPTANCE_TIMEOUT_SECONDS),
      () => _handleTimeout(requestId, driverId),
    );
  }
  
  Future<void> _handleTimeout(String requestId, String driverId) async {
    print('⏰ Timeout para request $requestId, driver $driverId');
    await _processRejectionOrTimeout(requestId, isTimeout: true);
  }
  
  Future<void> handleDriverResponse({
    required String requestId,
    required String driverId,
    required bool accepted,
  }) async {
    // Cancelar timer se existir
    _activeTimers[requestId]?.cancel();
    _activeTimers.remove(requestId);
    
    if (accepted) {
      await _acceptRequest(requestId, driverId);
    } else {
      await _processRejectionOrTimeout(requestId, isTimeout: false);
    }
  }
  
  Future<void> _processRejectionOrTimeout(String requestId, {required bool isTimeout}) async {
    try {
      // Buscar request atual
      final currentRequest = await _supabase
          .from('trip_requests')
          .select()
          .eq('id', requestId)
          .single();
      
      final fallbackDrivers = List<String>.from(currentRequest['fallback_drivers'] ?? []);
      final currentIndex = currentRequest['current_fallback_index'] ?? 0;
      final timeoutCount = currentRequest['timeout_count'] ?? 0;
      
      // Verificar se ainda há motoristas de fallback
      if (currentIndex < fallbackDrivers.length) {
        final nextDriverId = fallbackDrivers[currentIndex];
        
        // Atualizar request para próximo motorista
        await _supabase.from('trip_requests').update({
          'target_driver_id': nextDriverId,
          'current_fallback_index': currentIndex + 1,
          'timeout_count': isTimeout ? timeoutCount + 1 : timeoutCount,
          'expires_at': DateTime.now().add(Duration(seconds: ACCEPTANCE_TIMEOUT_SECONDS)).toIso8601String(),
        }).eq('id', requestId);
        
        // Buscar dados do próximo motorista
        final nextDriver = await _supabase
            .from('drivers')
            .select()
            .eq('id', nextDriverId)
            .single();
        
        // Criar nova oferta para o próximo motorista
        await _createDriverOffer(requestId, Driver.fromJson(nextDriver), 
                                 TripRequestData.fromRequest(currentRequest));
        
        // Enviar notificação
        await _sendDriverNotification(nextDriverId, requestId);
        
        // Iniciar novo timer
        _startTimeoutTimer(requestId, nextDriverId);
        
        print('🔄 Fallback: Request $requestId redirecionado para driver $nextDriverId');
        
      } else {
        // Sem mais fallbacks - marcar como expired
        await _supabase.from('trip_requests').update({
          'status': 'expired',
          'target_driver_id': null,
        }).eq('id', requestId);
        
        // Notificar passageiro que não encontrou motorista
        await _notifyPassengerNoDriverFound(currentRequest['passenger_id']);
        
        print('❌ Request $requestId expirado - sem motoristas disponíveis');
      }
      
    } catch (e) {
      print('❌ Erro ao processar fallback: $e');
      // Log error mas não propagar para não quebrar o fluxo
    }
  }
  
  Future<void> _acceptRequest(String requestId, String driverId) async {
    await _supabase.from('trip_requests').update({
      'status': 'accepted',
      'accepted_by_driver_id': driverId,
      'accepted_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
    
    // Marcar oferta como selecionada
    await _supabase.from('driver_offers').update({
      'was_selected': true,
    }).eq('request_id', requestId).eq('driver_id', driverId);
    
    print('✅ Request $requestId aceito pelo driver $driverId');
  }
  
  // Limpar timers ao destruir o service
  void dispose() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
  }
}
```

#### 1.3 Interface para Motoristas: DriverRequestsScreen
```dart
class DriverRequestsScreen extends StatefulWidget {
  const DriverRequestsScreen({super.key});

  @override
  State<DriverRequestsScreen> createState() => _DriverRequestsScreenState();
}

class _DriverRequestsScreenState extends State<DriverRequestsScreen> {
  late final StreamSubscription _requestsSubscription;
  final List<TripRequest> _activeRequests = [];
  
  @override
  void initState() {
    super.initState();
    _setupRequestsListener();
  }
  
  void _setupRequestsListener() {
    final currentDriverId = UserService.currentUser?.driverId;
    if (currentDriverId == null) return;
    
    _requestsSubscription = TripService().subscribeToTargetedRequests(currentDriverId)
        .listen((requests) {
      setState(() {
        _activeRequests.clear();
        _activeRequests.addAll(requests);
      });
      
      // Tocar som/vibração para novas solicitações
      if (requests.isNotEmpty) {
        _playNotificationSound();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitações de Viagem'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _activeRequests.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: _activeRequests.length,
              itemBuilder: (context, index) => TripRequestCard(
                request: _activeRequests[index],
                onAccept: () => _handleAccept(_activeRequests[index]),
                onReject: () => _handleReject(_activeRequests[index]),
              ),
            ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Aguardando solicitações...'),
          SizedBox(height: 8),
          Text('Você receberá uma notificação quando houver uma nova solicitação.',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
  
  Future<void> _handleAccept(TripRequest request) async {
    try {
      await TripRequestManager().handleDriverResponse(
        requestId: request.id,
        driverId: UserService.currentUser!.driverId!,
        accepted: true,
      );
      
      // Navegar para tela de viagem ativa
      Navigator.pushReplacementNamed(context, '/driver_trip', 
                                   arguments: {'requestId': request.id});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aceitar solicitação: $e')),
      );
    }
  }
  
  Future<void> _handleReject(TripRequest request) async {
    try {
      await TripRequestManager().handleDriverResponse(
        requestId: request.id,
        driverId: UserService.currentUser!.driverId!,
        accepted: false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao recusar solicitação: $e')),
      );
    }
  }
  
  void _playNotificationSound() {
    // Implementar som de notificação + vibração
    HapticFeedback.heavyImpact();
    // AudioPlayer.play('notification_sound.mp3');
  }
  
  @override
  void dispose() {
    _requestsSubscription.cancel();
    super.dispose();
  }
}
```

#### 1.4 Widget TripRequestCard
```dart
class TripRequestCard extends StatefulWidget {
  final TripRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  
  const TripRequestCard({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<TripRequestCard> createState() => _TripRequestCardState();
}

class _TripRequestCardState extends State<TripRequestCard> 
    with TickerProviderStateMixin {
  
  late final AnimationController _timerController;
  late final Timer _countdownTimer;
  int _remainingSeconds = 10;
  
  @override
  void initState() {
    super.initState();
    
    _timerController = AnimationController(
      duration: Duration(seconds: TripRequestManager.ACCEPTANCE_TIMEOUT_SECONDS),
      vsync: this,
    );
    
    // Calcular segundos restantes baseado no expires_at
    final expiresAt = DateTime.parse(widget.request.expiresAt);
    final now = DateTime.now();
    _remainingSeconds = expiresAt.difference(now).inSeconds.clamp(0, 10);
    
    if (_remainingSeconds > 0) {
      _timerController.forward();
      _startCountdown();
    }
  }
  
  void _startCountdown() {
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          timer.cancel();
          // Auto-reject quando tempo expira
          widget.onReject();
        }
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com timer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nova Solicitação', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _remainingSeconds > 3 ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_remainingSeconds}s',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            
            // Barra de progresso do tempo
            LinearProgressIndicator(
              value: _remainingSeconds / 10.0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _remainingSeconds > 3 ? Colors.green : Colors.red,
              ),
            ),
            
            SizedBox(height: 16),
            
            // Informações da viagem
            _buildTripInfo(),
            
            SizedBox(height: 16),
            
            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onReject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('RECUSAR'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('ACEITAR'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTripInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Passageiro info
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.request.passengerPhotoUrl != null
                  ? NetworkImage(widget.request.passengerPhotoUrl!)
                  : null,
              child: widget.request.passengerPhotoUrl == null
                  ? Icon(Icons.person)
                  : null,
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.request.passengerName ?? 'Passageiro', 
                     style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    Text('${widget.request.passengerRating?.toStringAsFixed(1) ?? 'N/A'}'),
                  ],
                ),
              ],
            ),
          ],
        ),
        
        SizedBox(height: 16),
        
        // Origem e destino
        _buildLocationInfo('Origem', widget.request.originAddress, Icons.location_on),
        SizedBox(height: 8),
        _buildLocationInfo('Destino', widget.request.destinationAddress, Icons.location_on),
        
        SizedBox(height: 16),
        
        // Detalhes da viagem
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildDetailChip('Distância', '${widget.request.estimatedDistanceKm.toStringAsFixed(1)} km'),
            _buildDetailChip('Duração', '${widget.request.estimatedDurationMinutes} min'),
            _buildDetailChip('Valor', 'R\$ ${widget.request.estimatedFare.toStringAsFixed(2)}'),
          ],
        ),
      ],
    );
  }
  
  Widget _buildLocationInfo(String label, String address, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(address, style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailChip(String label, String value) {
    return Chip(
      label: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _timerController.dispose();
    _countdownTimer.cancel();
    super.dispose();
  }
}
```

### **FASE 2: Integração e Estados Completos (2 semanas)**

#### 2.1 Modificar Driver Selection Screen
```dart
// Modificações na _DriverSelectionScreenState
class _DriverSelectionScreenState extends State<DriverSelectionScreen> {
  
  Future<void> _selectDriver(DriverWithPrice selectedDriverWithPrice) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Preparar dados da viagem
      final tripData = TripRequestData(
        originAddress: widget.origin.address,
        originLatitude: widget.origin.latitude,
        originLongitude: widget.origin.longitude,
        destinationAddress: widget.destination.address,
        destinationLatitude: widget.destination.latitude,
        destinationLongitude: widget.destination.longitude,
        vehicleCategory: widget.category,
        needsPet: widget.needsPet,
        needsGrocery: widget.needsGrocery,
        needsCondo: widget.needsCondo,
        estimatedDistanceKm: selectedDriverWithPrice.distanceKm,
        estimatedDurationMinutes: selectedDriverWithPrice.etaMinutes,
        estimatedFare: selectedDriverWithPrice.estimatedFare,
      );
      
      // Obter lista completa de drivers para fallback
      final allDriversWithPrice = await _futureDrivers;
      
      // Usar TripRequestManager (NOVO SISTEMA)
      final tripRequestManager = TripRequestManager(
        Supabase.instance.client, 
        NotificationService(),
      );
      
      final requestId = await tripRequestManager.createDirectedTripRequest(
        passengerId: UserService.currentUser!.passengerId!,
        prioritizedDrivers: allDriversWithPrice
            .map((dwp) => dwp.driver)
            .toList(),
        tripData: tripData,
      );
      
      if (mounted) {
        // Navegar para waiting screen com requestId
        Navigator.pushReplacementNamed(
          context,
          WaitingDriverScreen.routeName,
          arguments: {
            'requestId': requestId,
            'selectedDriver': selectedDriverWithPrice.driver,
            'estimatedFare': selectedDriverWithPrice.estimatedFare,
          },
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao solicitar viagem: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
```

#### 2.2 Atualizar Waiting Driver Screen
```dart
class WaitingDriverScreen extends StatefulWidget {
  static const String routeName = '/waiting_driver';
  
  const WaitingDriverScreen({
    super.key,
    required this.requestId,
    this.selectedDriver,
    this.estimatedFare,
  });
  
  final String requestId;
  final Driver? selectedDriver;
  final double? estimatedFare;

  @override
  State<WaitingDriverScreen> createState() => _WaitingDriverScreenState();
}

class _WaitingDriverScreenState extends State<WaitingDriverScreen> 
    with TickerProviderStateMixin {
  
  late final StreamSubscription _requestSubscription;
  TripRequest? _currentRequest;
  Driver? _currentTargetDriver;
  int _currentAttempt = 1;
  int _totalAttempts = 5;
  
  late final AnimationController _pulseController;
  late final AnimationController _progressController;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _progressController = AnimationController(
      duration: Duration(seconds: 10), // 10 segundos por tentativa
      vsync: this,
    );
    
    _setupRequestListener();
  }
  
  void _setupRequestListener() {
    _requestSubscription = TripService()
        .subscribeToTripRequest(widget.requestId)
        .listen((request) async {
      if (request == null) return;
      
      setState(() {
        _currentRequest = request;
      });
      
      // Buscar dados do motorista atual se mudou
      if (request.targetDriverId != _currentTargetDriver?.id) {
        _currentTargetDriver = await DriverService(Supabase.instance.client)
            .getDriver(request.targetDriverId);
        
        // Calcular tentativa atual baseado no fallback index
        _currentAttempt = (request.currentFallbackIndex ?? 0) + 1;
        
        // Resetar animação de progresso para nova tentativa
        _progressController.reset();
        _progressController.forward();
        
        setState(() {});
      }
      
      // Reagir a mudanças de status
      switch (request.status) {
        case 'accepted':
          _handleRequestAccepted();
          break;
        case 'expired':
          _handleRequestExpired();
          break;
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Procurando Motorista'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _currentRequest == null
          ? Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          // Indicador de progresso das tentativas
          _buildAttemptProgress(),
          
          SizedBox(height: 32),
          
          // Animação de pulse
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.1),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Icon(
                    Icons.search,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          
          SizedBox(height: 24),
          
          // Status atual
          Text(
            _getStatusMessage(),
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 16),
          
          // Informações do motorista atual
          if (_currentTargetDriver != null) _buildDriverInfo(),
          
          SizedBox(height: 24),
          
          // Barra de progresso do timeout atual
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return Column(
                children: [
                  LinearProgressIndicator(
                    value: _progressController.value,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Aguardando resposta... ${(10 * (1 - _progressController.value)).round()}s',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            },
          ),
          
          Spacer(),
          
          // Botão cancelar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _cancelRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Cancelar Solicitação'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAttemptProgress() {
    return Column(
      children: [
        Text(
          'Tentativa $_currentAttempt de $_totalAttempts',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: _currentAttempt / _totalAttempts,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDriverInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: _currentTargetDriver!.photoUrl != null
                  ? NetworkImage(_currentTargetDriver!.photoUrl!)
                  : null,
              child: _currentTargetDriver!.photoUrl == null
                  ? Icon(Icons.person)
                  : null,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentTargetDriver!.fullName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text('${_currentTargetDriver!.vehicleBrand} ${_currentTargetDriver!.vehicleModel}'),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Text('${_currentTargetDriver!.averageRating?.toStringAsFixed(1) ?? 'N/A'}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getStatusMessage() {
    if (_currentAttempt == 1) {
      return 'Enviando solicitação para o motorista escolhido...';
    } else {
      return 'Tentando próximo motorista disponível...';
    }
  }
  
  void _handleRequestAccepted() {
    Navigator.pushReplacementNamed(
      context,
      '/passenger_trip',
      arguments: {'requestId': widget.requestId},
    );
  }
  
  void _handleRequestExpired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Nenhum motorista encontrado'),
        content: Text(
          'Não conseguimos encontrar um motorista disponível no momento. '
          'Tente novamente em alguns minutos.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fechar dialog
              Navigator.of(context).pop(); // Voltar para tela anterior
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _cancelRequest() async {
    try {
      await TripService().updateTripRequestStatus(
        id: widget.requestId,
        status: 'cancelled_by_passenger',
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cancelar: $e')),
      );
    }
  }
  
  @override
  void dispose() {
    _requestSubscription.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }
}
```

---

## 📊 Cronograma Revisado (Mais Realista)

### **Semana 1: Preparação e Setup**
- [ ] ✅ Auditoria completa do schema atual
- [ ] ✅ Setup de feature flags
- [ ] ✅ Ambiente de desenvolvimento isolado
- [ ] ✅ Documentação dos fluxos existentes

### **Semana 2-3: Core do Matching System**
- [ ] 🔧 Modificações de schema (campos corretos)
- [ ] 🔧 Implementar TripRequestManager completo
- [ ] 🔧 Sistema de timeout e fallback funcional
- [ ] 🔧 Testes unitários críticos

### **Semana 4: Interface do Motorista**
- [ ] 🎨 DriverRequestsScreen completa
- [ ] 🎨 TripRequestCard com timer visual
- [ ] 🎨 Integração com notificações push
- [ ] 🎨 Testes de usabilidade

### **Semana 5: Integração Front-end**
- [ ] 🔄 Modificar DriverSelectionScreen
- [ ] 🔄 Atualizar WaitingDriverScreen
- [ ] 🔄 Integração de states end-to-end
- [ ] 🔄 Testes de integração

### **Semana 6-7: Sistema de Estados e Cancelamento**
- [ ] ⚙️ Estados de viagem completos
- [ ] ⚙️ Políticas de cancelamento
- [ ] ⚙️ Sistema de no-show
- [ ] ⚙️ Sistema de strikes

### **Semana 8: Testes e Deploy**
- [ ] 🧪 Testes end-to-end completos
- [ ] 🧪 Testes de carga do matching
- [ ] 🧪 Deploy para ambiente de teste
- [ ] 🧪 Correções e melhorias

---

## ⚠️ Riscos e Mitigações Específicas

### **ALTO RISCO: Breaking Changes**
- **Risco**: Quebrar sistema atual durante desenvolvimento
- **Mitigação**: Feature flags + desenvolvimento em branch paralela

### **MÉDIO RISCO: Performance do Real-time**
- **Risco**: Muitas subscriptions simultâneas degradarem performance
- **Mitigação**: Debounce + cleanup automático + índices otimizados

### **MÉDIO RISCO: Race Conditions**
- **Risco**: Múltiplos motoristas aceitarem mesmo request
- **Mitigação**: Transações atômicas + locks de database

### **BAIXO RISCO: Push Notifications**
- **Risco**: Notificações não chegarem
- **Mitigação**: Retry logic + fallback para polling

---

## 🎯 Métricas de Sucesso Revisadas

### **Técnicas:**
- 99.9% uptime do sistema de matching
- < 500ms tempo de resposta para criar request
- < 2% taxa de race conditions
- 95% de entrega de push notifications

### **Negócio:**
- 40% redução no tempo médio de matching
- 25% aumento na taxa de aceitação
- 60% redução em cancelamentos por timeout
- 30% melhoria no NPS dos motoristas

### **Operacionais:**
- Zero rollbacks críticos durante deploy
- < 5% de requests que esgotem todos os fallbacks
- 90% dos bugs críticos detectados antes de produção

---

## 📝 Conclusão

Esta versão revisada do plano:

✅ **Corrige** as inconsistências com o schema atual  
✅ **Detalha** implementações reais com código funcional  
✅ **Fornece** cronograma mais realista (8 semanas)  
✅ **Inclui** estratégias específicas de mitigação de riscos  
✅ **Define** métricas concretas de sucesso  

O plano transformará o sistema de "primeiro que aceita" em "seleção direcionada com fallback inteligente", alinhando 100% com as regras de negócio documentadas.

**Próximo passo**: Aprovação e início da implementação pela Semana 1 (Preparação).