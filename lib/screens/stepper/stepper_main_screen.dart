import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/stepper_controller.dart';
import 'step1_phone_screen.dart';
import 'step2_photo_screen.dart';

class StepperMainScreen extends StatefulWidget {
  const StepperMainScreen({super.key});

  @override
  State<StepperMainScreen> createState() => _StepperMainScreenState();
}

class _StepperMainScreenState extends State<StepperMainScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Consumer<StepperController>(
        builder: (context, controller, child) {
          // Sincroniza o PageView com o step atual
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients && 
                _pageController.page?.round() != controller.currentStep) {
              _pageController.animateToPage(
                controller.currentStep,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });

          return Column(
            children: [
              // Barra de progresso
              _buildProgressBar(controller, colors, textTheme),
              // Conteúdo das etapas
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    Step1PhoneScreen(),
                    Step2PhotoScreen(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(
    StepperController controller,
    ColorScheme colors,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Complete seu cadastro',
                style: textTheme.titleLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${controller.currentStep + 1} de 2',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (controller.currentStep + 1) / 2,
              minHeight: 6,
              backgroundColor: colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}