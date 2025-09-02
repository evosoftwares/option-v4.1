import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/supabase/working_hours.dart';
import '../../services/working_hours_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class WorkingHoursScreen extends StatefulWidget {
  const WorkingHoursScreen({super.key});

  @override
  State<WorkingHoursScreen> createState() => _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends State<WorkingHoursScreen> {
  late final WorkingHoursService _workingHoursService;
  String? _driverId;
  List<WorkingHours> _workingHours = [];
  
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

  final Map<String, int> _dayToInt = {
    'monday': 1,
    'tuesday': 2,
    'wednesday': 3,
    'thursday': 4,
    'friday': 5,
    'saturday': 6,
    'sunday': 0,
  };

  final Map<int, String> _intToDay = {
    0: 'sunday',
    1: 'monday',
    2: 'tuesday',
    3: 'wednesday',
    4: 'thursday',
    5: 'friday',
    6: 'saturday',
  };

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }
  
  Future<void> _initializeService() async {
    final supabase = Supabase.instance.client;
    
    _workingHoursService = WorkingHoursService(supabase);
    await _loadDriverId();
    await _loadWorkingHours();
  }
  
  Future<void> _loadDriverId() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Usuário não logado');
      }

      // Buscar driver ID
      final driverResponse = await supabase
          .from('drivers')
          .select('id')
          .eq('user_id', userId)
          .single();

      _driverId = driverResponse['id'] as String;
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao buscar dados do motorista');
      }
    }
  }

  Future<void> _loadWorkingHours() async {
    try {
      if (_driverId == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      // Buscar horários usando o WorkingHoursService
      _workingHours = await _workingHoursService.getWorkingHours(_driverId!);
      
      if (mounted) {
        setState(() {
          _loadScheduleFromWorkingHours(_workingHours);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Erro ao carregar horários de trabalho');
      }
    }
  }

  void _loadScheduleFromWorkingHours(List<WorkingHours> workingHours) {
    // Primeiro, resetar todos os dias para false
    for (final dayKey in _enabledDays.keys) {
      _enabledDays[dayKey] = false;
    }
    
    // Mapear os working hours para os dias da semana
     for (final hours in workingHours) {
       final dayKey = _intToDay[hours.dayOfWeek];
       if (dayKey != null) {
         _enabledDays[dayKey] = true;
         _startTimes[dayKey] = hours.parseStartTime();
         _endTimes[dayKey] = hours.parseEndTime();
       }
     }
  }

  Future<void> _saveWorkingHours() async {
    setState(() => _isSaving = true);

    try {
      if (_driverId == null) {
        throw Exception('Driver ID não encontrado');
      }

      // Validar horários antes de salvar
      for (final entry in _enabledDays.entries) {
        if (entry.value) {
          final dayKey = entry.key;
          final startTime = _startTimes[dayKey]!;
          final endTime = _endTimes[dayKey]!;
          
          if (startTime.hour * 60 + startTime.minute >= endTime.hour * 60 + endTime.minute) {
            throw Exception('Horário de início deve ser anterior ao horário de fim para ${_dayNames[dayKey]}');
          }
        }
      }

      // Primeiro, desativar todos os horários existentes
      await _workingHoursService.deactivateAllWorkingHours(_driverId!);

      // Criar novos horários para dias habilitados
      final newWorkingHours = <WorkingHours>[];
      for (final entry in _enabledDays.entries) {
        if (entry.value) { // Se o dia está habilitado
          final dayKey = entry.key;
          final dayOfWeek = _dayToInt[dayKey]!;
          
          final workingHour = await _workingHoursService.createWorkingHours(
            driverId: _driverId!,
            dayOfWeek: dayOfWeek,
            startTime: _startTimes[dayKey]!,
            endTime: _endTimes[dayKey]!,
          );
          
          newWorkingHours.add(workingHour);
        }
      }

      // Atualizar a lista local
      _workingHours = newWorkingHours;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Horários de trabalho salvos com sucesso!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao salvar horários de trabalho: ${e.toString()}');
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
      helpText: isStartTime ? 'Selecionar horário de início' : 'Selecionar horário de fim',
    );

    if (time != null) {
      setState(() {
        if (isStartTime) {
          _startTimes[dayKey] = time;
          // Se o horário de início for maior que o de fim, ajustar o fim
          final endTime = _endTimes[dayKey]!;
          if (time.hour * 60 + time.minute >= endTime.hour * 60 + endTime.minute) {
            _endTimes[dayKey] = TimeOfDay(
              hour: time.hour < 23 ? time.hour + 1 : 23,
              minute: time.minute,
            );
          }
        } else {
          _endTimes[dayKey] = time;
          // Se o horário de fim for menor que o de início, ajustar o início
          final startTime = _startTimes[dayKey]!;
          if (startTime.hour * 60 + startTime.minute >= time.hour * 60 + time.minute) {
            _startTimes[dayKey] = TimeOfDay(
              hour: time.hour > 0 ? time.hour - 1 : 0,
              minute: time.minute,
            );
          }
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
    
    // Mostrar feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Horários de ${_dayNames[sourceDayKey]} copiados para todos os dias'),
        duration: const Duration(seconds: 1),
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
        color: cs.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
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

  Widget _buildQuickActions() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
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

  Widget _buildScheduleForm() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Horários por Dia da Semana',
          style: AppTypography.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        
        ..._enabledDays.keys.map(_buildDayCard),
      ],
    );

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
          color: isEnabled ? cs.primary.withValues(alpha: 0.3) : cs.outlineVariant,
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