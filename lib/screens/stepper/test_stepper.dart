import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/stepper_controller.dart';
import 'step3_locations_screen.dart';

class TestStepper extends StatelessWidget {
  const TestStepper({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StepperController(),
      child: MaterialApp(
        title: 'Teste Stepper',
        theme: ThemeData(
          useMaterial3: true,
        ),
        home: const TestStepperScreen(),
      ),
    );
  }
}

class TestStepperScreen extends StatelessWidget {
  const TestStepperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste Step 3 - Locais'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
      body: const Step3LocationsScreen(),
    );
  }
}