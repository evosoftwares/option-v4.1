import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/stepper_controller.dart';
import 'step1_phone_screen.dart';

class StepperDemoScreen extends StatelessWidget {
  const StepperDemoScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<StepperController>(
      create: (_) => StepperController(),
      child: Scaffold(
        body: Navigator(
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => const Step1PhoneScreen(),
            );
          },
        ),
      ),
    );
}