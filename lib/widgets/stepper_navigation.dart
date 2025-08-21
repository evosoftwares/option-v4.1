import 'package:flutter/material.dart';

class StepperNavigation extends StatelessWidget {

  const StepperNavigation({
    super.key,
    required this.onNext,
    required this.onPrevious,
    this.onSkip,
    this.showPrevious = true,
    this.showSkip = false,
    this.nextLabel = 'Próximo',
    this.previousLabel,
    this.skipLabel,
  });
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback? onSkip;
  final bool showPrevious;
  final bool showSkip;
  final String nextLabel;
  final String? previousLabel;
  final String? skipLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        if (showSkip && onSkip != null) ...[
          TextButton(
            onPressed: onSkip,
            child: Text(
              skipLabel ?? 'Pular',
              style: textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            if (showPrevious)
              Expanded(
                child: OutlinedButton(
                  onPressed: onPrevious,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    previousLabel ?? 'Voltar',
                  ),
                ),
              ),
            if (showPrevious) const SizedBox(width: 16),
            Expanded(
              flex: showPrevious ? 2 : 1,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  nextLabel,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}