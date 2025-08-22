import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class WorkingHoursScreen extends StatefulWidget {
  const WorkingHoursScreen({super.key});

  @override
  State<WorkingHoursScreen> createState() => _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends State<WorkingHoursScreen> {
  final Map<String, bool> _enabledDays = {
    'monday': false,
    'tuesday': false,
    'wednesday': false,
    'thursday': false,
    'friday': false,
    'saturday': false,
    'sunday': false,
  };

  final Map<String, TimeOfDay> _startTimes = {
    'monday': const TimeOfDay(hour: 8, minute: 0),
    'tuesday': const TimeOfDay(hour: 8, minute: 0),
    'wednesday': const TimeOfDay(hour: 8, minute: 0),
    'thursday': const TimeOfDay(hour: 8, minute: 0),
    'friday': const TimeOfDay(hour: 8, minute: 0),
    'saturday': const TimeOfDay(hour: 8, minute: 0),
    'sunday': const TimeOfDay(hour: 8, minute: 0),
  };

  final Map<String, TimeOfDay> _endTimes = {
    'monday': const TimeOfDay(hour: 18, minute: 0),
    'tuesday': const TimeOfDay(hour: 18, minute: 0),
    'wednesday': const TimeOfDay(hour: 18, minute: 0),
    'thursday': const TimeOfDay(hour: 18, minute: 0),
    'friday': const TimeOfDay(hour: 18, minute: 0),
    'saturday': const TimeOfDay(hour: 18, minute: 0),
    'sunday': const TimeOfDay(hour: 18, minute: 0),
  };

  final Map<String, String> _dayNames = {
    'monday': 'Segunda-feira',
    'tuesday': 'Terça-feira',
    'wednesday': 'Quarta-feira',
    'thursday': 'Quinta-feira',
    'friday': 'Sexta-feira',
    'saturday': 'Sábado',
    'sunday': 'Domingo',
  };

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadWorkingHours();
  }

  Future<void> _loadWorkingHours() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Usuário não logado');
      }

      // Buscar driver
      final driverResponse = await supabase
          .from('drivers')
          .select('working_hours')
          .eq('user_id', userId)
          .maybeSingle();

      if (driverResponse != null && driverResponse['working_hours'] != null) {
        final workingHours = driverResponse['working_hours'] as Map<String, dynamic>;
        
        if (mounted) {
          setState(() {
            _loadScheduleFromData(workingHours);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Erro ao carregar horários de trabalho');
      }
    }
  }

  void _loadScheduleFromData(Map<String, dynamic> workingHours) {
    for (final dayKey in _enabledDays.keys) {
      final dayData = workingHours[dayKey] as Map<String, dynamic>?;
      if (dayData != null) {
        _enabledDays[dayKey] = dayData['enabled'] == true;
        
        if (dayData['start_time'] != null) {
          final startParts = dayData['start_time'].toString().split(':');
          _startTimes[dayKey] = TimeOfDay(
            hour: int.parse(startParts[0]),
            minute: int.parse(startParts[1]),
          );
        }
        
        if (dayData['end_time'] != null) {
          final endParts = dayData['end_time'].toString().split(':');
          _endTimes[dayKey] = TimeOfDay(
            hour: int.parse(endParts[0]),
            minute: int.parse(endParts[1]),
          );
        }
      }
    }
  }

  Future<void> _saveWorkingHours() async {
    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Usuário não logado');
      }

      final workingHoursData = <String, dynamic>{};
      
      for (final dayKey in _enabledDays.keys) {
        workingHoursData[dayKey] = {
          'enabled': _enabledDays[dayKey],
          'start_time': '${_startTimes[dayKey]!.hour.toString().padLeft(2, '0')}:${_startTimes[dayKey]!.minute.toString().padLeft(2, '0')}',
          'end_time': '${_endTimes[dayKey]!.hour.toString().padLeft(2, '0')}:${_endTimes[dayKey]!.minute.toString().padLeft(2, '0')}',
        };
      }

      await supabase
          .from('drivers')
          .update({'working_hours': workingHoursData})
          .eq('user_id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Horários de trabalho salvos com sucesso!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao salvar horários de trabalho');
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

  Future<void> _selectTime(String dayKey, bool isStartTime) async {
    final currentTime = isStartTime ? _startTimes[dayKey]! : _endTimes[dayKey]!;
    
    final time = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (time != null) {
      setState(() {
        if (isStartTime) {
          _startTimes[dayKey] = time;
        } else {
          _endTimes[dayKey] = time;
        }
      });
    }
  }

  void _setAllDays(bool enabled) {
    setState(() {
      for (final dayKey in _enabledDays.keys) {
        _enabledDays[dayKey] = enabled;
      }
    });
  }

  void _copyToAllDays(String sourceDayKey) {
    final sourceStart = _startTimes[sourceDayKey]!;
    final sourceEnd = _endTimes[sourceDayKey]!;
    
    setState(() {
      for (final dayKey in _enabledDays.keys) {
        _startTimes[dayKey] = sourceStart;
        _endTimes[dayKey] = sourceEnd;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Horários de Trabalho'),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveWorkingHours,
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
                _buildQuickActions(),
                const SizedBox(height: AppSpacing.sectionSpacing),
                _buildScheduleForm(),
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
            Icons.schedule,
            color: cs.primary,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Configure seus horários de trabalho para que o sistema saiba quando você está disponível para receber viagens.',
              style: AppTypography.bodyMedium.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: AppTypography.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _setAllDays(true),
                icon: const Icon(Icons.check_circle),
                label: const Text('Ativar Todos'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _setAllDays(false),
                icon: const Icon(Icons.cancel),
                label: const Text('Desativar Todos'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Horários por Dia da Semana',
          style: AppTypography.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        
        ..._enabledDays.keys.map((dayKey) => _buildDayCard(dayKey)),
      ],
    );
  }

  Widget _buildDayCard(String dayKey) {
    final cs = Theme.of(context).colorScheme;
    final isEnabled = _enabledDays[dayKey]!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isEnabled ? cs.primary.withOpacity(0.3) : cs.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _dayNames[dayKey]!,
                  style: AppTypography.titleMedium.copyWith(
                    color: isEnabled ? cs.onSurface : cs.onSurfaceVariant,
                  ),
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: (value) {
                  setState(() {
                    _enabledDays[dayKey] = value;
                  });
                },
              ),
            ],
          ),
          
          if (isEnabled) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _buildTimeButton(
                    label: 'Início',
                    time: _startTimes[dayKey]!,
                    onPressed: () => _selectTime(dayKey, true),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildTimeButton(
                    label: 'Fim',
                    time: _endTimes[dayKey]!,
                    onPressed: () => _selectTime(dayKey, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _copyToAllDays(dayKey),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copiar para todos os dias'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeButton({
    required String label,
    required TimeOfDay time,
    required VoidCallback onPressed,
  }) {
    final cs = Theme.of(context).colorScheme;
    final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outline),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  timeString,
                  style: AppTypography.bodyLarge.copyWith(
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}