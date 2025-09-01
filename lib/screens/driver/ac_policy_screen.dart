import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/driver_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class AcPolicyScreen extends StatefulWidget {
  const AcPolicyScreen({super.key});

  @override
  State<AcPolicyScreen> createState() => _AcPolicyScreenState();
}

class _AcPolicyScreenState extends State<AcPolicyScreen> {
  String? _selectedPolicy;
  bool _isLoading = true;
  bool _isSaving = false;

  final Map<String, String> _policyOptions = {
    'always_on': 'Sempre Ligado',
    'on_request': 'Conforme Solicitação',
    'never': 'Sempre Desligado',
  };

  final Map<String, String> _policyDescriptions = {
    'always_on': 'Ar-condicionado sempre ligado durante as viagens. Ideal para maior conforto dos passageiros.',
    'on_request': 'Ar-condicionado ligado apenas quando solicitado pelo passageiro. Você escolhe a cada viagem.',
    'never': 'Ar-condicionado não disponível. Viagens apenas com janelas abertas ou ventilação natural.',
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentPolicy();
  }

  Future<void> _loadCurrentPolicy() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Usuário não logado');
      }

      final response = await supabase
          .from('drivers')
          .select('ac_policy')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _selectedPolicy = response['ac_policy'] as String? ?? 'on_request';
          _isLoading = false;
        });
      } else {
        setState(() {
          _selectedPolicy = 'on_request'; // Default policy
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Erro ao carregar política de ar-condicionado');
      }
    }
  }

  Future<void> _savePolicy() async {
    if (_selectedPolicy == null) return;

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Usuário não logado');
      }

      final driverResponse = await supabase
          .from('drivers')
          .select('id')
          .eq('user_id', userId)
          .single();

      final driverId = driverResponse['id'] as String;
      final driverService = DriverService(supabase);

      await driverService.updateDriver(
        driverId,
        acPolicy: _selectedPolicy,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Política de ar-condicionado salva com sucesso!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao salvar política de ar-condicionado');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
        title: const Text('Política de Ar-Condicionado'),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _savePolicy,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppSpacing.paddingLg,
              children: [
                _buildInfoCard(),
                const SizedBox(height: AppSpacing.sectionSpacing),
                _buildPolicyOptions(),
              ],
            ),
    );
  }

  Widget _buildInfoCard() {
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: cs.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.ac_unit,
            color: cs.primary,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Configure sua política de ar-condicionado. Esta configuração afetará quais solicitações de viagem você receberá.',
              style: AppTypography.bodyMedium.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Escolha sua Política',
          style: AppTypography.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        
        ..._policyOptions.entries.map((entry) => _buildPolicyOption(
          value: entry.key,
          title: entry.value,
          description: _policyDescriptions[entry.key]!,
        )),
      ],
    );
  }

  Widget _buildPolicyOption({
    required String value,
    required String title,
    required String description,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = _selectedPolicy == value;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? cs.primary : cs.outline,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        color: isSelected 
            ? cs.primaryContainer.withOpacity(0.3) 
            : cs.surfaceContainerHighest.withOpacity(0.3),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: _selectedPolicy,
        onChanged: (String? newValue) {
          setState(() {
            _selectedPolicy = newValue;
          });
        },
        title: Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: cs.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            description,
            style: AppTypography.bodyMedium.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        activeColor: cs.primary,
        contentPadding: AppSpacing.paddingLg,
      ),
    );
  }
}