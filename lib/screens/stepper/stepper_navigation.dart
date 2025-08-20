import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/stepper_controller.dart';
import 'step1_phone_screen.dart';
import 'step2_photo_screen.dart';

class StepperNavigation extends StatelessWidget {
  const StepperNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StepperController>(
      builder: (context, controller, child) {
        return Navigator(
          key: controller.navigatorKey,
          initialRoute: '/phone',
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/phone':
                return MaterialPageRoute(
                  builder: (_) => const Step1PhoneScreen(),
                  settings: settings,
                );
              case '/photo':
                return MaterialPageRoute(
                  builder: (_) => const Step2PhotoScreen(),
                  settings: settings,
                );
              default:
                return MaterialPageRoute(
                  builder: (_) => const Step1PhoneScreen(),
                  settings: settings,
                );
            }
          },
        );
      },
    );
  }
}