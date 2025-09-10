import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/driver_stepper_controller.dart';
import '../../services/user_service.dart';
import '../../utils/supabase_helper.dart';
import 'driver_code_of_conduct_step.dart';
import 'driver_completion_step.dart';
import 'vehicle_registration_step.dart';

class DriverStepper extends StatefulWidget {
  const DriverStepper({super.key});

  @override
  State<DriverStepper> createState() => _DriverStepperState();
}

class _DriverStepperState extends State<DriverStepper> {
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
      create: (_) => DriverStepperController(),
      child: const _DriverStepperContent(),
    );
}

class _DriverStepperContent extends StatefulWidget {
  const _DriverStepperContent();

  @override
  State<_DriverStepperContent> createState() => _DriverStepperContentState();
}

class _DriverStepperContentState extends State<_DriverStepperContent> {
  final int _totalSteps = 3;

  void _nextStep() {
    final controller = Provider.of<DriverStepperController>(context, listen: false);
    controller.nextStep();
  }

  void _previousStep() {
    final controller = Provider.of<DriverStepperController>(context, listen: false);
    controller.previousStep();
  }

  Future<void> _completeDriverRegistration() async {
    final timestamp = DateTime.now().toIso8601String();
    print('🏁 [$timestamp] [DRIVER_STEPPER] Finalizando cadastro de motorista...');
    
    try {
      // Marcar o perfil do motorista como completo
      final authUser = SupabaseHelper.client?.auth.currentUser;
      if (authUser != null) {
        print('🔄 [$timestamp] [DRIVER_STEPPER] Marcando perfil de motorista como completo...');
        await UserService.markProfileComplete(authUser.id);
        print('✅ [$timestamp] [DRIVER_STEPPER] Perfil de motorista marcado como completo');
      }
      
      // Navegar para a tela principal do motorista
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/driver_home');
      
    } catch (e) {
      print('❌ [$timestamp] [DRIVER_STEPPER] Erro ao finalizar cadastro de motorista: $e');
      
      if (!mounted) return;
      // Mostrar erro mas ainda navegar (o usuário completou o stepper)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro concluído, mas houve um erro interno. Entre em contato conosco se tiver problemas.'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.of(context).pushReplacementNamed('/driver_home');
    }
  }

  @override
  Widget build(BuildContext context) => Consumer<DriverStepperController>(
      builder: (context, controller, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        return PopScope(
          canPop: false, // Prevent back navigation
          onPopInvokedWithResult: (didPop, result) {
            // This prevents the user from going back
            if (didPop) return;
            
            // Show a dialog explaining they can't skip driver registration
            showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cadastro de Motorista Obrigatório'),
                content: const Text('Você precisa completar o cadastro de motorista para usar o aplicativo.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
          child: Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: const Text(
                'Cadastro de Motorista',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              automaticallyImplyLeading: false, // Remove the back button completely
              elevation: 0,
            ),
          body: Column(
            children: [
              // Progress indicator
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Etapa ${controller.currentStep + 1} de $_totalSteps',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${((controller.currentStep + 1) / _totalSteps * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (controller.currentStep + 1) / _totalSteps,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  ],
                ),
              ),
              // Stepper content
              Expanded(
                child: PageView(
                  controller: controller.pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    DriverCodeOfConductStep(),
                    VehicleRegistrationStep(),
                    DriverCompletionStep(),
                  ],
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
}