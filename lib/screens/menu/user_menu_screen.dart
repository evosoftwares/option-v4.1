import 'package:flutter/material.dart';
import 'package:uber_clone/theme/app_spacing.dart';
import 'package:uber_clone/theme/app_typography.dart';
import 'package:uber_clone/services/user_service.dart';
import 'package:uber_clone/models/user.dart' as app_user;

class UserMenuScreen extends StatefulWidget {
  const UserMenuScreen({super.key});

  @override
  State<UserMenuScreen> createState() => _UserMenuScreenState();
}

class _UserMenuScreenState extends State<UserMenuScreen> {
  Future<app_user.User?>? _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = UserService.getCurrentUser();
  }

  void _showComingSoon(String label) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$label" em breve', style: AppTypography.bodyMedium.copyWith(color: theme.colorScheme.onInverseSurface)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Menu do Passageiro'),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
      ),
      body: FutureBuilder<app_user.User?>(
        future: _userFuture,
        builder: (context, snapshot) {
          final user = snapshot.data;
          return ListView(
            padding: AppSpacing.paddingLg,
            children: [
              _HeaderCard(
                name: user?.fullName ?? 'Passageiro',
                email: user?.email ?? '',
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),

              const _SectionTitle(title: 'Conta'),
              _MenuTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Carteira',
                onTap: () => Navigator.pushNamed(context, '/wallet'),
              ),
              _MenuTile(
                icon: Icons.person_outline,
                label: 'Perfil',
                onTap: () => _showComingSoon('Perfil'),
              ),
              _MenuTile(
                icon: Icons.payment_outlined,
                label: 'Pagamentos',
                onTap: () => _showComingSoon('Pagamentos'),
              ),
              _MenuTile(
                icon: Icons.place_outlined,
                label: 'Locais salvos',
                onTap: () => _showComingSoon('Locais salvos'),
              ),

              const SizedBox(height: AppSpacing.sectionSpacing),
              const _SectionTitle(title: 'Viagens'),
              _MenuTile(
                icon: Icons.history,
                label: 'Histórico de viagens',
                onTap: () => _showComingSoon('Histórico de viagens'),
              ),
              _MenuTile(
                icon: Icons.card_giftcard_outlined,
                label: 'Promoções',
                onTap: () => _showComingSoon('Promoções'),
              ),

              const SizedBox(height: AppSpacing.sectionSpacing),
              const _SectionTitle(title: 'Geral'),
              _MenuTile(
                icon: Icons.notifications_none,
                label: 'Notificações',
                onTap: () => _showComingSoon('Notificações'),
              ),
              _MenuTile(
                icon: Icons.security_outlined,
                label: 'Segurança',
                onTap: () => _showComingSoon('Segurança'),
              ),
              _MenuTile(
                icon: Icons.help_outline,
                label: 'Ajuda',
                onTap: () => _showComingSoon('Ajuda'),
              ),
              _MenuTile(
                icon: Icons.info_outline,
                label: 'Sobre o app',
                onTap: () => _showComingSoon('Sobre o app'),
              ),
              _MenuTile(
                icon: Icons.logout,
                label: 'Sair',
                onTap: () => _showComingSoon('Sair'),
              ),

              const SizedBox(height: AppSpacing.sectionSpacing),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String name;
  final String email;

  const _HeaderCard({
    required this.name,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: cs.outlineVariant, width: AppSpacing.borderThin),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: AppSpacing.avatarMd / 2,
            backgroundColor: cs.primaryContainer,
            child: Icon(Icons.person, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.titleLarge.copyWith(color: cs.onSurface)),
                if (email.isNotEmpty)
                  Text(email, style: AppTypography.bodySmall.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTypography.titleMedium.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        height: AppSpacing.listItemHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: cs.outlineVariant, width: AppSpacing.borderThin),
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.itemSpacing),
        child: Row(
          children: [
            Icon(icon, color: cs.onSurface),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyLarge.copyWith(color: cs.onSurface),
              ),
            ),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: AppSpacing.sm),
            ],
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}