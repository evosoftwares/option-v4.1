import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class StepperProgressIndicator extends StatelessWidget {

  const StepperProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabels,
    this.showLabels = false,
    this.height = 8.0,
    this.padding,
  });
  final int currentStep;
  final int totalSteps;
  final List<String>? stepLabels;
  final bool showLabels;
  final double height;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Column(
        children: [
          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalSteps, (index) {
              final isActive = index == currentStep;
              final isCompleted = index < currentStep;
              final isUpcoming = index > currentStep;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                width: isActive ? AppSpacing.xl : AppSpacing.xs * 3,
                height: height,
                decoration: BoxDecoration(
                  color: isCompleted || isActive
                      ? colors.primary
                      : colors.surfaceContainerHighest.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              );
            }),
          ),
          
          // Step counter
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${currentStep + 1} de $totalSteps',
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: AppTypography.medium,
            ),
          ),
          
          // Optional step labels
          if (showLabels && stepLabels != null && stepLabels!.length == totalSteps) ...[
            const SizedBox(height: AppSpacing.xs * 3),
            Text(
              stepLabels![currentStep],
              style: textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: AppTypography.semiBold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class LinearStepperProgressIndicator extends StatelessWidget {

  const LinearStepperProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabels,
    this.showLabels = false,
    this.height = 6.0,
    this.padding,
  });
  final int currentStep;
  final int totalSteps;
  final List<String>? stepLabels;
  final bool showLabels;
  final double height;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: padding ?? const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xxxl + AppSpacing.xs, AppSpacing.md, AppSpacing.md),
      child: Column(
        children: [
          // Header with title and counter
          if (showLabels) ...[
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
                  '${currentStep + 1} de $totalSteps',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          
          // Linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / totalSteps,
              minHeight: height,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
          
          // Optional step label
          if (showLabels && stepLabels != null && stepLabels!.length == totalSteps) ...[
            const SizedBox(height: AppSpacing.xs * 3),
            Text(
              stepLabels![currentStep],
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: AppTypography.medium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class CircularStepperProgressIndicator extends StatelessWidget {

  const CircularStepperProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.size = AppSpacing.iconXxl,
    this.strokeWidth = AppSpacing.xs + 2,
    this.backgroundColor,
    this.progressColor,
  });
  final int currentStep;
  final int totalSteps;
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? progressColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = (currentStep + 1) / totalSteps;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(
                backgroundColor ?? colors.surfaceContainerHighest,
              ),
            ),
          ),
          // Progress circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(
                progressColor ?? colors.primary,
              ),
            ),
          ),
          // Center text
          Text(
            '${currentStep + 1}/$totalSteps',
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurface,
              fontWeight: AppTypography.bold,
            ),
          ),
        ],
      ),
    );
  }
}