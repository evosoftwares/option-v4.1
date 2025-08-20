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
          primarySwatch: Colors.blue,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste Step 3 - Locais'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: const Step3LocationsScreen(),
    );
  }
}