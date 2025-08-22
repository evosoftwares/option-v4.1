import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _driverStats = {};
  List<Map<String, dynamic>> _recentTrips = [];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Usuário não logado');
      }

      // Buscar driver_id
      final driverResponse = await supabase
          .from('drivers')
          .select('id, average_rating, total_trips, consecutive_cancellations')
          .eq('user_id', userId)
          .single();

      final driverId = driverResponse['id'] as String;

      // Buscar estatísticas das viagens
      final tripsResponse = await supabase
          .from('trips')
          .select('status, created_at, final_fare')
          .eq('driver_id', driverId)
          .order('created_at', ascending: false)
          .limit(50);

      // Calcular estatísticas
      final completedTrips = tripsResponse.where((trip) => trip['status'] == 'completed').toList();
      final cancelledTrips = tripsResponse.where((trip) => trip['status'] == 'cancelled').toList();
      
      double totalEarnings = 0;
      for (final trip in completedTrips) {
        if (trip['final_fare'] != null) {
          totalEarnings += (trip['final_fare'] as num).toDouble();
        }
      }

      // Estatísticas dos últimos 30 dias
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentTrips = tripsResponse.where((trip) {
        final tripDate = DateTime.parse(trip['created_at']);
        return tripDate.isAfter(thirtyDaysAgo);
      }).toList();

      final recentCompletedTrips = recentTrips.where((trip) => trip['status'] == 'completed').length;
      
      double recentEarnings = 0;
      for (final trip in recentTrips) {
        if (trip['status'] == 'completed' && trip['final_fare'] != null) {
          recentEarnings += (trip['final_fare'] as num).toDouble();
        }
      }

      if (mounted) {
        setState(() {
          _driverStats = {
            'average_rating': driverResponse['average_rating'] ?? 0.0,
            'total_trips': driverResponse['total_trips'] ?? 0,
            'consecutive_cancellations': driverResponse['consecutive_cancellations'] ?? 0,
            'completed_trips': completedTrips.length,
            'cancelled_trips': cancelledTrips.length,
            'total_earnings': totalEarnings,
            'recent_trips_30d': recentCompletedTrips,
            'recent_earnings_30d': recentEarnings,
            'completion_rate': completedTrips.length > 0 
                ? (completedTrips.length / (completedTrips.length + cancelledTrips.length) * 100)
                : 0.0,
          };
          
          _recentTrips = tripsResponse.take(10).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Erro ao carregar estatísticas');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Minhas Estatísticas'),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        actions: [
          IconButton(
            onPressed: _loadStatistics,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: ListView(
                padding: AppSpacing.paddingLg,
                children: [
                  _buildOverviewSection(),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  _buildPerformanceSection(),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  _buildEarningsSection(),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  _buildRecentTripsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visão Geral',
          style: AppTypography.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Avaliação',
                value: _driverStats['average_rating']?.toStringAsFixed(1) ?? '0.0',
                icon: Icons.star,
                color: Theme.of(context).colorScheme.onSurface,
                subtitle: '⭐',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                title: 'Total de Viagens',
                value: _driverStats['total_trips']?.toString() ?? '0',
                icon: Icons.local_taxi,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Concluídas',
                value: _driverStats['completed_trips']?.toString() ?? '0',
                icon: Icons.check_circle,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                title: 'Taxa de Conclusão',
                value: '${_driverStats['completion_rate']?.toStringAsFixed(1) ?? '0.0'}%',
                icon: Icons.trending_up,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Últimos 30 dias',
          style: AppTypography.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Viagens',
                value: _driverStats['recent_trips_30d']?.toString() ?? '0',
                icon: Icons.directions_car,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                title: 'Cancelamentos',
                value: _driverStats['consecutive_cancellations']?.toString() ?? '0',
                icon: Icons.cancel,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEarningsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ganhos',
          style: AppTypography.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Geral',
                value: 'R\$ ${_driverStats['total_earnings']?.toStringAsFixed(2) ?? '0.00'}',
                icon: Icons.account_balance_wallet,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                title: 'Últimos 30 dias',
                value: 'R\$ ${_driverStats['recent_earnings_30d']?.toStringAsFixed(2) ?? '0.00'}',
                icon: Icons.monetization_on,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentTripsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Viagens Recentes',
          style: AppTypography.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_recentTrips.isEmpty)
          _buildEmptyState()
        else
          ..._recentTrips.take(5).map(_buildTripItem),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const Spacer(),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: AppTypography.titleLarge,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripItem(Map<String, dynamic> trip) {
    final cs = Theme.of(context).colorScheme;
    final status = trip['status'] as String;
    final createdAt = DateTime.parse(trip['created_at']);
    final fare = trip['final_fare'] as double?;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (status) {
      case 'completed':
        statusColor = Theme.of(context).colorScheme.primary;
        statusIcon = Icons.check_circle;
        statusText = 'Concluída';
        break;
      case 'cancelled':
        statusColor = Theme.of(context).colorScheme.error;
        statusIcon = Icons.cancel;
        statusText = 'Cancelada';
        break;
      case 'in_progress':
        statusColor = Theme.of(context).colorScheme.secondary;
        statusIcon = Icons.directions_car;
        statusText = 'Em andamento';
        break;
      default:
        statusColor = Theme.of(context).colorScheme.onSurfaceVariant;
        statusIcon = Icons.help;
        statusText = status;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: AppTypography.bodyLarge.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${createdAt.day}/${createdAt.month}/${createdAt.year} - ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                  style: AppTypography.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (fare != null && status == 'completed')
            Text(
              'R\$ ${fare.toStringAsFixed(2)}',
              style: AppTypography.titleMedium.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingXl,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_taxi,
            size: 48,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nenhuma viagem ainda',
            style: AppTypography.titleLarge.copyWith(
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Suas viagens aparecerão aqui conforme você for realizando corridas.',
            style: AppTypography.bodyMedium.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}