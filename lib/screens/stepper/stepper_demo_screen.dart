import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/stepper_controller.dart';
import 'phone_step.dart';

class StepperDemoScreen extends StatelessWidget {
  const StepperDemoScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<StepperController>(
      create: (_) => StepperController(),
      child: Scaffold(
        body: Navigator(
          onGenerateRoute: (settings) => MaterialPageRoute(
              builder: (context) => PhoneStep(onNext: () {}),
            ),
        ),
      ),
    );
}