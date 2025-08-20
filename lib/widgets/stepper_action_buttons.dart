import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          if (onBack != null) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : onBack,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.uberWhite),
                  foregroundColor: AppTheme.uberWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(backLabel ?? 'Voltar'),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: onBack != null ? 1 : 2,
            child: ElevatedButton(
              onPressed: isLoading ? null : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.uberWhite,
                foregroundColor: AppTheme.uberBlack,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.uberBlack),
                      ),
                    )
                  : Text(nextLabel),
            ),
          ),
        ],
      ),
    );
  }
}