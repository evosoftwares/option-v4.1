import 'package:flutter/material.dart';

class StepperNavigation extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback? onSkip;
  final bool showPrevious;
  final bool showSkip;
  final String nextLabel;
  final String? previousLabel;
  final String? skipLabel;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showSkip && onSkip != null) ...[
          TextButton(
            onPressed: onSkip,
            child: Text(
              skipLabel ?? 'Pular',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
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
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    previousLabel ?? 'Voltar',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                    ),
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
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  nextLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}