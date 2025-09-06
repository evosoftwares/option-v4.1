import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/driver_stepper_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_card.dart';

class DriverCodeOfConductStep extends StatelessWidget {
  const DriverCodeOfConductStep({super.key});

  @override
  Widget build(BuildContext context) => Consumer<DriverStepperController>(
      builder: (context, controller, child) => Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Código de Conduta',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.lightOnSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Regras e expectativas para uma excelente experiência',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.lightOnSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Code of conduct information in a scrollable container
              Expanded(
                child: SingleChildScrollView(
                  child: AppCard(
                    padding: AppSpacing.paddingMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.policy,
                              color: AppColors.lightPrimary,
                              size: 24,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Diretrizes para Motoristas',
                                style: AppTypography.titleLarge,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        
                        // Conduct rules
                        _buildConductRule(
                          icon: Icons.clean_hands,
                          title: 'Limpeza',
                          description: 'Mantenha o veículo limpo e organizado para o conforto dos passageiros.',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        
                        _buildConductRule(
                          icon: Icons.smoking_rooms,
                          title: 'Ambiente',
                          description: 'Não fume dentro do veículo e mantenha um ambiente familiar.',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        
                        _buildConductRule(
                          icon: Icons.phone_disabled,
                          title: 'Foco na direção',
                          description: 'Não utilize o celular enquanto dirige. Utilize o modo hands-free se necessário.',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        
                        _buildConductRule(
                          icon: Icons.volunteer_activism,
                          title: 'Cortesia',
                          description: 'Trate todos os passageiros com respeito e gentileza.',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        
                        _buildConductRule(
                          icon: Icons.security,
                          title: 'Segurança',
                          description: 'Siga todas as leis de trânsito e utilize sempre o cinto de segurança.',
                        ),
                        
                        // Add some spacing at the bottom to ensure content is not cut off
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Error message
              if (controller.errorMessage != null) 
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          controller.errorMessage!,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Continue button - always enabled since this is informational
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => controller.nextStep(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightPrimary,
                    foregroundColor: AppColors.lightOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Continuar',
                    style: AppTypography.labelLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  
  Widget _buildConductRule({
    required IconData icon,
    required String title,
    required String description,
  }) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.lightPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.lightPrimary,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.lightOnSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
}