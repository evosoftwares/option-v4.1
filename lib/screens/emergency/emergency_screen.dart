import 'package:flutter/material.dart';
import '../../models/emergency.dart';
import '../../services/emergency_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/emergency_button.dart';
import '../../utils/snackbar_utils.dart';
import 'emergency_contacts_screen.dart';

/// Tela principal de emergência
class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  List<Emergency> _emergencies = [];
  bool _isLoading = true;
  bool _isLocationSharingActive = false;
  String? _currentSharingId;

  @override
  void initState() {
    super.initState();
    _loadEmergencies();
  }

  Future<void> _loadEmergencies() async {
    try {
      setState(() => _isLoading = true);
      
      final user = await UserService.getCurrentUser();
      if (user != null) {
        final emergencies = await EmergencyService.getUserEmergencies(user.id);
        if (mounted) {
          setState(() {
            _emergencies = emergencies;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarUtils.showError(context, 'Erro ao carregar emergências: $e');
      }
    }
  }

  Future<void> _startLocationSharing() async {
    try {
      final user = await UserService.getCurrentUser();
      if (user == null) {
        SnackBarUtils.showError(context, 'Usuário não autenticado');
        return;
      }

      final sharingId = await EmergencyService.startLocationSharing(
        userId: user.id,
        duration: const Duration(hours: 2),
      );

      setState(() {
        _isLocationSharingActive = true;
        _currentSharingId = sharingId;
      });

      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          'Compartilhamento de localização ativado por 2 horas',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'Erro ao iniciar compartilhamento: $e',
        );
      }
    }
  }

  Future<void> _stopLocationSharing() async {
    if (_currentSharingId == null) return;

    try {
      await EmergencyService.stopLocationSharing(_currentSharingId!);
      
      setState(() {
        _isLocationSharingActive = false;
        _currentSharingId = null;
      });

      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          'Compartilhamento de localização desativado',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'Erro ao parar compartilhamento: $e',
        );
      }
    }
  }

  void _showLocationSharingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.location_on,
              color: AppColors.blue,
              size: 24,
            ),
            SizedBox(width: AppSpacing.sm),
            Text('Compartilhar Localização'),
          ],
        ),
        content: const Text(
          'Deseja compartilhar sua localização em tempo real? '
          'Isso permitirá que seus contatos de emergência vejam onde você está.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startLocationSharing();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Compartilhar'),
          ),
        ],
      ),
    );
  }

  String _getEmergencyTypeText(EmergencyType type) {
    switch (type) {
      case EmergencyType.panic:
        return 'Pânico';
      case EmergencyType.medical:
        return 'Médica';
      case EmergencyType.accident:
        return 'Acidente';
      case EmergencyType.security:
        return 'Segurança';
      case EmergencyType.other:
        return 'Outro';
    }
  }

  Color _getEmergencyTypeColor(EmergencyType type) {
    switch (type) {
      case EmergencyType.panic:
        return AppColors.error;
      case EmergencyType.medical:
        return AppColors.warning;
      case EmergencyType.accident:
        return AppColors.error;
      case EmergencyType.security:
        return AppColors.warning;
      case EmergencyType.other:
        return AppColors.gray600;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Emergência'),
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightOnSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.contacts),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmergencyContactsScreen(),
                ),
              );
            },
            tooltip: 'Contatos de Emergência',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Botão de emergência principal
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Botão de Emergência',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Pressione em caso de emergência para notificar seus contatos',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.gray600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const EmergencyButton(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Compartilhamento de localização
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: _isLocationSharingActive
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: _isLocationSharingActive
                            ? AppColors.success.withOpacity(0.3)
                            : AppColors.blue.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isLocationSharingActive
                                  ? Icons.location_on
                                  : Icons.location_off,
                              color: _isLocationSharingActive
                                  ? AppColors.success
                                  : AppColors.blue,
                              size: 24,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Compartilhamento de Localização',
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _isLocationSharingActive
                                      ? AppColors.success
                                      : AppColors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _isLocationSharingActive
                              ? 'Sua localização está sendo compartilhada em tempo real'
                              : 'Compartilhe sua localização com contatos de emergência',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.gray600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLocationSharingActive
                                ? _stopLocationSharing
                                : _showLocationSharingDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isLocationSharingActive
                                  ? AppColors.error
                                  : AppColors.blue,
                              foregroundColor: AppColors.white,
                            ),
                            child: Text(
                              _isLocationSharingActive
                                  ? 'Parar Compartilhamento'
                                  : 'Iniciar Compartilhamento',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Histórico de emergências
                  Text(
                    'Histórico de Emergências',
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  if (_emergencies.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            size: 48,
                            color: AppColors.gray400,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Nenhuma emergência registrada',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _emergencies.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final emergency = _emergencies[index];
                        return AppCard(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _getEmergencyTypeColor(emergency.type)
                                      .withOpacity(0.2),
                              child: Icon(
                                Icons.emergency,
                                color: _getEmergencyTypeColor(emergency.type),
                              ),
                            ),
                            title: Text(
                              _getEmergencyTypeText(emergency.type),
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (emergency.description?.isNotEmpty == true)
                                  Text(
                                    emergency.description!,
                                    style: AppTypography.bodyMedium,
                                  ),
                                Text(
                                  emergency.address,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.gray600,
                                  ),
                                ),
                                Text(
                                  '${emergency.timestamp.day}/${emergency.timestamp.month}/${emergency.timestamp.year} às ${emergency.timestamp.hour.toString().padLeft(2, '0')}:${emergency.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.gray500,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Icon(
                              emergency.isResolved
                                  ? Icons.check_circle
                                  : Icons.warning,
                              color: emergency.isResolved
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
}