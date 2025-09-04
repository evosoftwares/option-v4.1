import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/driver_stepper_controller.dart';
import 'driver_completion_step.dart';
import 'driver_documents_step.dart';
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

  void _completeDriverRegistration() {
    // Navegar para a tela principal do motorista
    Navigator.of(context).pushReplacementNamed('/driver_home');
  }

  @override
  Widget build(BuildContext context) => Consumer<DriverStepperController>(
      builder: (context, controller, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        return Scaffold(
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
            leading: controller.currentStep > 0
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _previousStep,
                  )
                : IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/driver_home');
                    },
                  ),
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
                    DriverDocumentsStep(),
                    VehicleRegistrationStep(),
                    DriverCompletionStep(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
}