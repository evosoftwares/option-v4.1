import 'package:flutter/material.dart';

class StepperActionButtons extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final String nextLabel;
  final String? backLabel;
  final bool isLoading;
  final bool canSkip;

  const StepperActionButtons({
    super.key,
    this.onBack,
    required this.onNext,
    this.nextLabel = 'Continuar',
    this.backLabel,
    this.isLoading = false,
    this.canSkip = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          if (onBack != null) ...[
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: isLoading ? null : onBack,
                  child: Text(backLabel ?? 'Voltar'),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: onBack != null ? 1 : 2,
            child: SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: isLoading ? null : onNext,
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                        ),
                      )
                    : Text(nextLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}