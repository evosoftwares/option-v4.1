import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/supabase/trip_request.dart';
import '../../services/trip_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/supabase_helper.dart';
import '../../widgets/trip_request_card.dart';

class DriverRequestsScreen extends StatefulWidget {
  const DriverRequestsScreen({super.key});

  @override
  State<DriverRequestsScreen> createState() => _DriverRequestsScreenState();
}

class _DriverRequestsScreenState extends State<DriverRequestsScreen> {
  final TripService _tripService = TripService(Supabase.instance.client);
  
  List<TripRequest> _targetedRequests = [];
  final Map<String, Timer> _timers = {};
  final Map<String, int> _remainingSeconds = {};
  bool _isLoading = true;
  StreamSubscription? _requestsSubscription;

  @override
  void initState() {
    super.initState();
    _loadTargetedRequests();
    _subscribeToRequests();
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    for (final timer in _timers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  Future<void> _loadTargetedRequests() async {
    try {
      final supabase = SupabaseHelper.client;
      if (supabase == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      final driverId = supabase.auth.currentUser?.id;
      
      if (driverId == null) {
        return;
      }

      final requests = await _tripService.getTargetedRequestsForDriver(driverId);
      
      setState(() {
        _targetedRequests = requests.where((request) => 
          !request.hasExpired && request.isPending
        ).toList();
        _isLoading = false;
      });

      // Iniciar timers para cada solicitação
      for (final request in _targetedRequests) {
        _startTimer(request);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erro ao carregar solicitações: $e');
    }
  }

  void _subscribeToRequests() {
    final supabase = SupabaseHelper.client;
    if (supabase == null) {
      return;
    }
    
    final driverId = supabase.auth.currentUser?.id;
    
    if (driverId == null) {
      return;
    }

    _requestsSubscription = _tripService.subscribeToTargetedRequests(driverId)
        .listen((requests) {
      setState(() {
        _targetedRequests = requests.where((request) => 
          !request.hasExpired && request.isPending
        ).toList();
      });

      // Atualizar timers
      for (final timer in _timers.values) {
        timer.cancel();
      }
      _timers.clear();
      _remainingSeconds.clear();
      
      for (final request in _targetedRequests) {
        _startTimer(request);
      }
    });
  }

  void _startTimer(TripRequest request) {
    if (request.expiresAt == null) {
      return;
    }
    
    final now = DateTime.now();
    final expiresAt = request.expiresAt!;
    final remainingTime = expiresAt.difference(now).inSeconds;
    
    if (remainingTime <= 0) {
      _handleExpiredRequest(request);
      return;
    }
    
    _remainingSeconds[request.id] = remainingTime;
    
    _timers[request.id] = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _remainingSeconds[request.id]! - 1;
      
      if (remaining <= 0) {
        timer.cancel();
        _handleExpiredRequest(request);
      } else {
        setState(() {
          _remainingSeconds[request.id] = remaining;
        });
      }
    });
  }

  void _handleExpiredRequest(TripRequest request) {
    _timers[request.id]?.cancel();
    _timers.remove(request.id);
    _remainingSeconds.remove(request.id);
    
    setState(() {
      _targetedRequests.removeWhere((r) => r.id == request.id);
    });
  }

  Future<void> _acceptRequest(TripRequest request) async {
    try {
      final supabase = SupabaseHelper.client;
      if (supabase == null) {
        return;
      }
      
      final driverId = supabase.auth.currentUser?.id;
      
      if (driverId == null) {
        return;
      }

      await _tripService.acceptTripRequest(
        requestId: request.id,
        driverId: driverId,
      );
      
      _timers[request.id]?.cancel();
      _timers.remove(request.id);
      _remainingSeconds.remove(request.id);
      
      setState(() {
        _targetedRequests.removeWhere((r) => r.id == request.id);
      });
      
      if (mounted) {
        _showSuccessSnackBar('Solicitação aceita com sucesso!');
        
        // Navegar para tela de viagem
        await Navigator.pushReplacementNamed(context, '/driver-trip');
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao aceitar solicitação: $e');
    }
  }

  Future<void> _declineRequest(TripRequest request) async {
    try {
      final supabase = SupabaseHelper.client;
      if (supabase == null) {
        return;
      }
      
      final driverId = supabase.auth.currentUser?.id;
      
      if (driverId == null) {
        return;
      }

      await _tripService.declineTripRequest(
        requestId: request.id,
        driverId: driverId,
      );
      
      _timers[request.id]?.cancel();
      _timers.remove(request.id);
      _remainingSeconds.remove(request.id);
      
      setState(() {
        _targetedRequests.removeWhere((r) => r.id == request.id);
      });
      
      _showInfoSnackBar('Solicitação recusada');
    } catch (e) {
      _showErrorSnackBar('Erro ao recusar solicitação: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text(
          'Solicitações de Viagem',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _targetedRequests.isEmpty
              ? _buildEmptyState()
              : _buildRequestsList(),
    );

  Widget _buildEmptyState() => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma solicitação no momento',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Você será notificado quando receber\nnovas solicitações de viagem',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );

  Widget _buildRequestsList() => ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _targetedRequests.length,
      itemBuilder: (context, index) {
        final request = _targetedRequests[index];
        return _buildRequestCard(request);
      },
    );

  Widget _buildRequestCard(TripRequest request) {
    final remainingSeconds = _remainingSeconds[request.id] ?? 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TripRequestCard(
        request: request,
        remainingSeconds: remainingSeconds,
        onAccept: () => _acceptRequest(request),
        onDecline: () => _declineRequest(request),
      ),
    );
  }


}