import 'package:flutter/material.dart';
import '../models/supabase/working_hours.dart';
import '../controllers/driver_status_controller.dart';

class WorkingHoursDialog extends StatefulWidget {
  const WorkingHoursDialog({
    super.key,
    required this.statusController,
    required this.onWorkingHoursUpdated,
  });

  final DriverStatusController statusController;
  final VoidCallback onWorkingHoursUpdated;

  @override
  State<WorkingHoursDialog> createState() => _WorkingHoursDialogState();
}

class _WorkingHoursDialogState extends State<WorkingHoursDialog> {
  List<WorkingHours> _workingHours = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkingHours();
  }

  Future<void> _loadWorkingHours() async {
    try {
      final hours = await widget.statusController.getWorkingHours();
      setState(() {
        _workingHours = hours;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Horário de Trabalho'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Você está tentando ficar online fora do seu horário de trabalho configurado.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Horários configurados:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_workingHours.isEmpty)
                    const Text(
                      'Nenhum horário configurado',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    )
                  else
                    ..._workingHours.map((hours) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '${_getDayName(hours.dayOfWeek)}: ${hours.startTime} - ${hours.endTime}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        )),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Manter Offline'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _navigateToWorkingHoursScreen();
          },
          child: const Text('Ajustar Horário'),
        ),
      ],
    );
  }

  String _getDayName(int dayOfWeek) {
    const days = [
      'Domingo',
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
    ];
    return days[dayOfWeek % 7];
  }

  void _navigateToWorkingHoursScreen() {
    // TODO: Implementar navegação para tela de horários de trabalho
    // Navigator.of(context).pushNamed('/working-hours');
    widget.onWorkingHoursUpdated();
  }
}

/// Função utilitária para mostrar o diálogo
Future<void> showWorkingHoursDialog({
  required BuildContext context,
  required DriverStatusController statusController,
  required VoidCallback onWorkingHoursUpdated,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => WorkingHoursDialog(
      statusController: statusController,
      onWorkingHoursUpdated: onWorkingHoursUpdated,
    ),
  );
}