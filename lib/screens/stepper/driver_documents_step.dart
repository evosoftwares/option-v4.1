import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/driver_stepper_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_card.dart';

class DriverDocumentsStep extends StatelessWidget {
  const DriverDocumentsStep({super.key});

  @override
  Widget build(BuildContext context) => Consumer<DriverStepperController>(
      builder: (context, controller, child) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Documentos do Motorista',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.lightOnSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Envie fotos dos seus documentos para validação',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.lightOnSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // CNH Card
              AppCard(
                padding: AppSpacing.paddingMd, // Reduzir padding para evitar overflow
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.credit_card,
                          color: AppColors.lightPrimary,
                          size: 20, // Reduzir tamanho do ícone
                        ),
                        const SizedBox(width: AppSpacing.xs), // Reduzir espaçamento
                        Expanded(
                          child: Text(
                            'CNH',
                            style: AppTypography.titleMedium,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    if (controller.cnhPhoto != null) 
                      _buildPhotoPreview(
                        context,
                        controller.cnhPhoto!,
                        'CNH capturada',
                        () => _showPhotoOptions(context, controller, true),
                      )
                    else
                      _buildPhotoCapture(
                        context,
                        'Capturar foto da CNH',
                        'Tire uma foto clara da frente da sua CNH',
                        () => _showPhotoOptions(context, controller, true),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // CRLV Card
              AppCard(
                padding: AppSpacing.paddingMd, // Reduzir padding para evitar overflow
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.description,
                          color: AppColors.lightPrimary,
                          size: 20, // Reduzir tamanho do ícone
                        ),
                        const SizedBox(width: AppSpacing.xs), // Reduzir espaçamento
                        Expanded(
                          child: Text(
                            'CRLV',
                            style: AppTypography.titleMedium,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    if (controller.crlvPhoto != null) 
                      _buildPhotoPreview(
                        context,
                        controller.crlvPhoto!,
                        'CRLV capturado',
                        () => _showPhotoOptions(context, controller, false),
                      )
                    else
                      _buildPhotoCapture(
                        context,
                        'Capturar foto do CRLV',
                        'Tire uma foto clara do seu CRLV',
                        () => _showPhotoOptions(context, controller, false),
                      ),
                  ],
                ),
              ),
              
              const Spacer(),
              
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
              
              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.canProceedFromDocuments
                      ? () => controller.nextStep()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightPrimary,
                    foregroundColor: AppColors.lightOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: controller.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.lightOnPrimary,
                            ),
                          ),
                        )
                      : Text(
                          'Continuar',
                          style: AppTypography.labelLarge,
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  
  Widget _buildPhotoPreview(
    BuildContext context,
    File photo,
    String title,
    VoidCallback onTap,
  ) => GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
          image: DecorationImage(
            image: FileImage(photo),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black.withOpacity(0.3),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 32,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Toque para alterar',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  
  Widget _buildPhotoCapture(
    BuildContext context,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.lightOutline,
            style: BorderStyle.solid,
          ),
          color: AppColors.lightSurfaceVariant.withOpacity(0.3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              color: AppColors.lightPrimary,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.lightPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.lightOnSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  
  void _showPhotoOptions(
    BuildContext context,
    DriverStepperController controller,
    bool isCnh,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isCnh ? 'Foto da CNH' : 'Foto do CRLV',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: AppColors.lightPrimary,
              ),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.pop(context);
                if (isCnh) {
                  controller.takeCnhPhoto();
                } else {
                  controller.takeCrlvPhoto();
                }
              },
            ),
            
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.lightPrimary,
              ),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(context);
                if (isCnh) {
                  controller.selectCnhFromGallery();
                } else {
                  controller.selectCrlvFromGallery();
                }
              },
            ),
            
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}