import 'package:flutter/material.dart';
import '../services/user_service.dart';

class VerticalBrandLogo extends StatelessWidget {
  const VerticalBrandLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/Logotipo Vertical Color.webp',
          fit: BoxFit.contain,
          height: 160,
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

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StandardAppBar({
    super.key,
    required this.title,
    this.onMenuPressed,
    this.showMenuIcon = true,
    this.showBackButton = true,
    this.automaticallyImplyLeading,
    this.actions,
    this.centerTitle,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
  });

  final String title;
  final VoidCallback? onMenuPressed;
  final bool showMenuIcon;
  final bool showBackButton;
  final bool? automaticallyImplyLeading;
  final List<Widget>? actions;
  final bool? centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Determina as ações do AppBar
    List<Widget>? appBarActions;
    if (actions != null) {
      // Se actions customizadas foram fornecidas, usa elas
      appBarActions = actions;
    } else if (showMenuIcon) {
      // Se deve mostrar menu e não há actions customizadas
      appBarActions = [
        IconButton(
          icon: const Icon(Icons.menu),
          onPressed: onMenuPressed ?? () => _navigateToMenu(context),
        ),
      ];
    }
    
    return AppBar(
      backgroundColor: backgroundColor ?? colorScheme.surface,
      foregroundColor: foregroundColor ?? colorScheme.onSurface,
      elevation: elevation ?? 0,
      title: Text(title),
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading ?? showBackButton,
      actions: appBarActions,
    );
  }

  Future<void> _navigateToMenu(BuildContext context) async {
    final user = await UserService.getCurrentUser();
    if (!context.mounted) {
      return;
    }
    
    if (user != null) {
      if (user.userType == 'driver') {
        await Navigator.pushNamed(context, '/driver_menu');
      } else {
        await Navigator.pushNamed(context, '/user_menu');
      }
    }
  }
}