import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_clone/controllers/stepper_controller.dart';
import 'package:uber_clone/screens/stepper/step1_phone_screen.dart';
import 'package:uber_clone/screens/stepper/step2_photo_screen.dart';
import 'package:uber_clone/screens/stepper/step3_locations_screen.dart';

class StepperScreen extends StatefulWidget {
  const StepperScreen({super.key});

  @override
  State<StepperScreen> createState() => _StepperScreenState();
}

class _StepperScreenState extends State<StepperScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Adiciona listener para mudanças no stepper controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<StepperController>();
      controller.addListener(_onStepChanged);
    });
  }

  @override
  void dispose() {
    final controller = context.read<StepperController>();
    controller.removeListener(_onStepChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onStepChanged() {
    final controller = context.read<StepperController>();
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        controller.currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração do Perfil'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Indicador de progresso
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Consumer<StepperController>(
                builder: (context, controller, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == controller.currentStep ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index <= controller.currentStep
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            
            // Conteúdo das páginas
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  Step1PhoneScreen(),
                  Step2PhotoScreen(),
                  Step3LocationsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}