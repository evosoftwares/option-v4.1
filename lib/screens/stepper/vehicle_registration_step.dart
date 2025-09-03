import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';

import '../../controllers/driver_stepper_controller.dart';
import '../../models/vehicle_brand.dart';
import '../../models/vehicle_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_card.dart';

class VehicleRegistrationStep extends StatelessWidget {
  const VehicleRegistrationStep({super.key});

  @override
  Widget build(BuildContext context) => Consumer<DriverStepperController>(
      builder: (context, controller, child) => Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dados do Veículo',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.lightOnSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Informe os dados do seu veículo para completar o cadastro',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.lightOnSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Vehicle Brand
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
                                Expanded(
                                  child: Text(
                                    'Marca do Veículo',
                                    style: AppTypography.titleMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (controller.isBrandLoading)
                                  const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TypeAheadField<VehicleBrand>(
                              controller: controller.brandController,
                              suggestionsCallback: (pattern) async {
                                if (pattern.isEmpty) {
                                  return await controller.searchBrands('');
                                }
                                return await controller.searchBrands(pattern);
                              },
                              itemBuilder: (context, suggestion) {
                                return ListTile(
                                  leading: const Icon(Icons.business),
                                  title: Text(suggestion.name),
                                );
                              },
                              onSelected: (suggestion) {
                                controller.selectBrand(suggestion);
                              },
                              decorationBuilder: (context, child) {
                                return Material(
                                  type: MaterialType.card,
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(8),
                                  child: child,
                                );
                              },
                              offset: const Offset(0, 8),
                              constraints: const BoxConstraints(maxHeight: 200),
                              builder: (context, textController, focusNode) {
                                return Consumer<DriverStepperController>(
                                  builder: (context, driverController, _) {
                                    return TextFormField(
                                      controller: textController,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        labelText: 'Marca',
                                        hintText: 'Digite para buscar marcas...',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: driverController.brandHasError 
                                              ? Colors.red 
                                              : Colors.grey,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: driverController.brandHasError 
                                              ? Colors.red 
                                              : Colors.grey,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: driverController.brandHasError 
                                              ? Colors.red 
                                              : AppColors.lightPrimary,
                                            width: 2,
                                          ),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.business,
                                          color: driverController.brandHasError 
                                            ? Colors.red 
                                            : null,
                                        ),
                                        errorText: driverController.brandErrorMessage,
                                      ),
                                      textCapitalization: TextCapitalization.words,
                                      onChanged: (value) {
                                        driverController.setBrand(value);
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      // Vehicle Model
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.car_rental,
                                  color: AppColors.lightPrimary,
                                  size: 24,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Modelo do Veículo',
                                    style: AppTypography.titleMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (controller.isModelLoading)
                                  const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TypeAheadField<VehicleModel>(
                              controller: controller.modelController,
                              suggestionsCallback: (pattern) async {
                                if (controller.selectedBrand == null) {
                                  return <VehicleModel>[];
                                }
                                if (pattern.isEmpty) {
                                  return await controller.searchModels('');
                                }
                                return await controller.searchModels(pattern);
                              },
                              itemBuilder: (context, suggestion) {
                                return ListTile(
                                  leading: const Icon(Icons.directions_car_filled),
                                  title: Text(suggestion.name),
                                );
                              },
                              onSelected: (suggestion) {
                                controller.selectModel(suggestion);
                              },
                              decorationBuilder: (context, child) {
                                return Material(
                                  type: MaterialType.card,
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(8),
                                  child: child,
                                );
                              },
                              offset: const Offset(0, 8),
                              constraints: const BoxConstraints(maxHeight: 200),
                              builder: (context, textController, focusNode) {
                                return Consumer<DriverStepperController>(
                                  builder: (context, driverController, _) {
                                    return TextFormField(
                                      controller: textController,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        labelText: 'Modelo',
                                        hintText: driverController.selectedBrand == null 
                                            ? 'Selecione uma marca primeiro'
                                            : 'Digite para buscar modelos...',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: driverController.modelHasError 
                                              ? Colors.red 
                                              : Colors.grey,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: driverController.modelHasError 
                                              ? Colors.red 
                                              : Colors.grey,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: driverController.modelHasError 
                                              ? Colors.red 
                                              : AppColors.lightPrimary,
                                            width: 2,
                                          ),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.directions_car_filled,
                                          color: driverController.modelHasError 
                                            ? Colors.red 
                                            : null,
                                        ),
                                        errorText: driverController.modelErrorMessage,
                                      ),
                                      enabled: driverController.selectedBrand != null,
                                      textCapitalization: TextCapitalization.words,
                                      onChanged: (value) {
                                        driverController.setModel(value);
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      // Vehicle Year and Color Row
                      Row(
                        children: [
                          // Year
                          Expanded(
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        color: AppColors.lightPrimary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(
                                        'Ano',
                                        style: AppTypography.titleSmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  TextFormField(
                                    controller: controller.yearController,
                                    decoration: InputDecoration(
                                      labelText: 'Ano',
                                      hintText: '2020',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: controller.yearHasError 
                                            ? Colors.red 
                                            : Colors.grey,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: controller.yearHasError 
                                            ? Colors.red 
                                            : Colors.grey,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: controller.yearHasError 
                                            ? Colors.red 
                                            : AppColors.lightPrimary,
                                          width: 2,
                                        ),
                                      ),
                                      errorText: controller.yearErrorMessage,
                                    ),
                                    keyboardType: TextInputType.number,
                                    maxLength: 4,
                                    onChanged: (value) => controller.setYear(value),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: AppSpacing.sm),
                          
                          // Color
                          Expanded(
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.palette,
                                        color: AppColors.lightPrimary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(
                                        'Cor',
                                        style: AppTypography.titleSmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  TextFormField(
                                    controller: controller.colorController,
                                    decoration: InputDecoration(
                                      labelText: 'Cor',
                                      hintText: 'Branco',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: controller.colorHasError 
                                            ? Colors.red 
                                            : Colors.grey,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: controller.colorHasError 
                                            ? Colors.red 
                                            : Colors.grey,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: controller.colorHasError 
                                            ? Colors.red 
                                            : AppColors.lightPrimary,
                                          width: 2,
                                        ),
                                      ),
                                      errorText: controller.colorErrorMessage,
                                    ),
                                    textCapitalization: TextCapitalization.words,
                                    onChanged: (value) => controller.setColor(value),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      // Vehicle Plate
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.confirmation_number,
                                  color: AppColors.lightPrimary,
                                  size: 24,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Placa do Veículo',
                                    style: AppTypography.titleMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: controller.plateController,
                              decoration: InputDecoration(
                                labelText: 'Placa',
                                hintText: 'ABC-1234 ou ABC1D23',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: controller.plateHasError 
                                      ? Colors.red 
                                      : Colors.grey,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: controller.plateHasError 
                                      ? Colors.red 
                                      : Colors.grey,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: controller.plateHasError 
                                      ? Colors.red 
                                      : AppColors.lightPrimary,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.confirmation_number,
                                  color: controller.plateHasError 
                                    ? Colors.red 
                                    : null,
                                ),
                                errorText: controller.plateErrorMessage,
                              ),
                              textCapitalization: TextCapitalization.characters,
                              onChanged: (value) => controller.setPlate(value),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Informe a placa sem espaços ou traços',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.lightOnSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
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
                    color: Colors.red.withValues(alpha: 0.1),
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
              
              // Validation warning message
              if (!controller.canProceedFromVehicle && 
                  (controller.brandFieldTouched || 
                   controller.modelFieldTouched || 
                   controller.yearFieldTouched || 
                   controller.plateFieldTouched || 
                   controller.colorFieldTouched))
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_outlined,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Complete todos os campos obrigatórios para continuar',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.orange,
                          ),
                        ),
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
                      onPressed: () => controller.previousStep(),
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
                  
                  // Continue button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: controller.canProceedFromVehicle
                          ? () => controller.nextStep()
                          : () => controller.validateVehicleFields(),
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
            ],
          ),
        ),
    );
}