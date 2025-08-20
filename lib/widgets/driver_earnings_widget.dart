import 'package:flutter/material.dart';
import '../models/driver_status.dart';

class DriverEarningsWidget extends StatelessWidget {
  final DriverStatus driverStatus;
  final VoidCallback? onTap;

  const DriverEarningsWidget({
    super.key,
    required this.driverStatus,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  driverStatus.earningsDisplayText,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'hoje',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }
}