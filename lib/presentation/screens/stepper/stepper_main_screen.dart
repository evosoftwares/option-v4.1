import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/stepper_controller.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/stepper_progress_indicator.dart';
import 'phone_step.dart';
import 'photo_step.dart';

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
              // Indicador de progresso melhorado
              LinearStepperProgressIndicator(
                currentStep: controller.currentStep,
                totalSteps: 2,
                showLabels: true,
                stepLabels: const ['Telefone', 'Foto'],
              ),
              // Conteúdo das etapas
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    PhoneStep(onNext: () {}),
                    PhotoStep(onNext: () {}),
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
  ) => Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xxxl + AppSpacing.xs, AppSpacing.md, AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Complete seu cadastro',
                style: textTheme.titleLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: AppTypography.bold,
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
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd - AppSpacing.xs),
            child: LinearProgressIndicator(
              value: (controller.currentStep + 1) / 2,
              minHeight: AppSpacing.xs + 2,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
}