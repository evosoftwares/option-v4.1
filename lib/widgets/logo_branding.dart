import 'package:flutter/material.dart';

class VerticalBrandLogo extends StatelessWidget {
  const VerticalBrandLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Image.asset(
            'assets/images/Logotipo Vertical Color.webp',
            fit: BoxFit.contain,
            height: 80,
          ),
        ),
      ],
    );
  }
}

class LogoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LogoAppBar({super.key, this.actions});

  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Image.asset(
              'assets/images/Logotipo Horizontal Color.webp',
              height: 28,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}