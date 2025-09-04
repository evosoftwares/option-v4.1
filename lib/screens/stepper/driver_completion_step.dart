import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/driver_stepper_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_card.dart';

class DriverCompletionStep extends StatelessWidget {
  const DriverCompletionStep({super.key});

  @override
  Widget build(BuildContext context) => Consumer<DriverStepperController>(
      builder: (context, controller, child) => Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Finalizar Cadastro',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.lightOnSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Revise suas informações antes de finalizar',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.lightOnSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Documents Summary
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.description,
                                  color: AppColors.lightPrimary,
                                  size: 24,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Documentos',
                                  style: AppTypography.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            
                            _buildDocumentStatus(
                              title: 'CNH (Carteira Nacional de Habilitação)',
                              isUploaded: controller.cnhUrl != null,
                              isUploading: controller.isUploadingCnh,
                              error: controller.cnhError,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _buildDocumentStatus(
                              title: 'CRLV (Certificado de Registro e Licenciamento)',
                              isUploaded: controller.crlvUrl != null,
                              isUploading: controller.isUploadingCrlv,
                              error: controller.crlvError,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      // Vehicle Summary
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.directions_car,
                                  color: AppColors.lightPrimary,
                                  size: 24,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Dados do Veículo',
                                  style: AppTypography.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            
                            _buildVehicleInfo('Marca', controller.brandController.text),
                            _buildVehicleInfo('Modelo', controller.modelController.text),
                            _buildVehicleInfo('Ano', controller.yearController.text),
                            _buildVehicleInfo('Cor', controller.colorController.text),
                            _buildVehicleInfo('Placa', controller.plateController.text),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      // Status Information
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Próximos Passos',
                                  style: AppTypography.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            
                            Text(
                              '• Seus documentos serão analisados pela nossa equipe\n'
                              '• Você receberá uma notificação quando a análise for concluída\n'
                              '• O processo pode levar até 24 horas\n'
                              '• Após aprovação, você poderá começar a aceitar corridas',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.lightOnSurfaceVariant,
                                height: 1.5,
                              ),
                              overflow: TextOverflow.visible,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Error message
              if (controller.errorMessage != null) 
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Erro no Cadastro',
                              style: AppTypography.titleSmall.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        controller.errorMessage!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.red.shade700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'Verifique os dados e tente novamente',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.red.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              
              // Navigation buttons
              Row(
                children: [
                  // Back button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.isLoading 
                          ? null 
                          : () => controller.previousStep(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.lightPrimary,
                        side: BorderSide(color: AppColors.lightPrimary),
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Voltar',
                        style: AppTypography.labelLarge,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: AppSpacing.md),
                  
                  // Complete button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: controller.canCompleteRegistration && !controller.isLoading
                          ? () async {
                              // Limpar erro anterior
                              controller.clearError();
                              
                              // Tentar finalizar cadastro
                              final success = await controller.completeDriverRegistration();
                              
                              if (success && context.mounted) {
                                // Exibir mensagem de sucesso
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('🎉 Cadastro finalizado com sucesso!'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                
                                // Aguardar um momento para que a mensagem seja exibida
                                await Future.delayed(const Duration(milliseconds: 1500));
                                
                                if (context.mounted) {
                                  // Navegar para a tela principal do motorista
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/driver_home',
                                    (route) => false, // Remove todas as rotas anteriores
                                  );
                                }
                              }
                              // Em caso de erro, a mensagem já será exibida automaticamente
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: controller.canCompleteRegistration 
                            ? Colors.green 
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: controller.canCompleteRegistration ? 2 : 0,
                      ),
                      child: controller.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  controller.canCompleteRegistration 
                                      ? Icons.check_circle 
                                      : Icons.block,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Flexible(
                                  child: Text(
                                    controller.canCompleteRegistration 
                                        ? 'Finalizar Cadastro'
                                        : 'Complete os dados',
                                    style: AppTypography.labelLarge,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
  
  Widget _buildDocumentStatus({
    required String title,
    required bool isUploaded,
    required bool isUploading,
    String? error,
  }) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (isUploading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                isUploaded
                    ? Icons.check_circle
                    : (error != null ? Icons.error_outline : Icons.radio_button_unchecked),
                color: isUploaded
                    ? Colors.green
                    : (error != null ? Colors.red : Colors.grey),
                size: 20,
              ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: isUploaded
                      ? AppColors.lightOnSurface
                      : (error != null ? Colors.red : Colors.grey),
                ),
              ),
            ),
            if (isUploading)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Enviando...',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (isUploaded)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Enviado',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (error != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Falha',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            error,
            style: AppTypography.bodySmall.copyWith(color: Colors.red),
          ),
        ],
      ],
    );
  
  Widget _buildVehicleInfo(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              '$label:',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.lightOnSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : 'Não informado',
              style: AppTypography.bodyMedium.copyWith(
                color: value.isNotEmpty 
                    ? AppColors.lightOnSurface 
                    : Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
}