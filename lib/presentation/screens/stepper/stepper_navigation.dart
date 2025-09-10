import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/stepper_controller.dart';
import 'phone_step.dart';
import 'photo_step.dart';

class StepperNavigation extends StatelessWidget {
  const StepperNavigation({super.key});

  @override
  Widget build(BuildContext context) => Consumer<StepperController>(
      builder: (context, controller, child) => Navigator(
          key: controller.navigatorKey,
          initialRoute: '/phone',
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/phone':
                return MaterialPageRoute(
                  builder: (_) => PhoneStep(onNext: () {}),
                  settings: settings,
                );
              case '/photo':
                return MaterialPageRoute(
                  builder: (_) => PhotoStep(onNext: () {}),
                  settings: settings,
                );
              default:
                return MaterialPageRoute(
                  builder: (_) => PhoneStep(onNext: () {}),
                  settings: settings,
                );
            }
          },
        ),
    );
}