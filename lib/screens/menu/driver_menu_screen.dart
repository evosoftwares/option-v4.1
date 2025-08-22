import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/user_service.dart';
import '../../models/user.dart' as app_user;

class DriverMenuScreen extends StatefulWidget {
  const DriverMenuScreen({super.key});

  @override
  State<DriverMenuScreen> createState() => _DriverMenuScreenState();
}

class _DriverMenuScreenState extends State<DriverMenuScreen> {
  bool _isOnline = false; // Local state for now (integration later)
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

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.auth.signOut();
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao sair. Tente novamente.'),
          ),
        );
      }
    }
  }

  Future<void> _openWhatsAppSupport() async {
    const phoneNumber = '556592577217';
    const message = 'Olá! Preciso de ajuda com o app Option - Sou motorista.';
    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = 'https://wa.me/$phoneNumber?text=$encodedMessage';
    
    final uri = Uri.parse(whatsappUrl);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o WhatsApp. Verifique se o app está instalado.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Menu do Motorista'),
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
                name: user?.fullName ?? 'Motorista',
                email: user?.email ?? '',
                isOnline: _isOnline,
                onToggleOnline: (val) => setState(() => _isOnline = val),
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),

              const _SectionTitle(title: 'Conta'),
              _MenuTile(
                icon: Icons.person_outline,
                label: 'Perfil',
                onTap: () => Navigator.pushNamed(context, '/profile_edit').then((result) {
                  if (result == true) {
                    setState(() {
                      _userFuture = UserService.getCurrentUser();
                    });
                  }
                }),
              ),
              _MenuTile(
                icon: Icons.directions_car_outlined,
                label: 'Veículo',
                onTap: () => _showComingSoon('Veículo'),
              ),
              _MenuTile(
                icon: Icons.assignment_turned_in_outlined,
                label: 'Documentos',
                onTap: () => _showComingSoon('Documentos'),
              ),

              const SizedBox(height: AppSpacing.sectionSpacing),
              const _SectionTitle(title: 'Trabalho'),
              _MenuTile(
                icon: Icons.schedule_outlined,
                label: 'Horários de trabalho',
                onTap: () => _showComingSoon('Horários de trabalho'),
              ),
              _MenuTile(
                icon: Icons.map_outlined,
                label: 'Zonas de atendimento',
                onTap: () => _showComingSoon('Zonas de atendimento'),
              ),
              _MenuTile(
                icon: Icons.remove_circle_outline,
                label: 'Zonas excluídas',
                onTap: () => Navigator.pushNamed(context, '/driver_excluded_zones'),
              ),
              _MenuTile(
                icon: Icons.price_change_outlined,
                label: 'Preços personalizados',
                onTap: () => _showComingSoon('Preços personalizados'),
              ),

              const SizedBox(height: AppSpacing.sectionSpacing),
              const _SectionTitle(title: 'Atividade'),
              _MenuTile(
                icon: Icons.history,
                label: 'Histórico de viagens',
                onTap: () => Navigator.pushNamed(context, '/trip_history'),
              ),
              _MenuTile(
                icon: Icons.stacked_line_chart_outlined,
                label: 'Estatísticas',
                onTap: () => _showComingSoon('Estatísticas'),
              ),
              _MenuTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Carteira',
                trailing: const _WalletPill(amountText: r'R$ 0,00'),
                onTap: () => Navigator.pushNamed(context, '/wallet'),
              ),

              const SizedBox(height: AppSpacing.sectionSpacing),
              const _SectionTitle(title: 'Geral'),
              _MenuTile(
                icon: Icons.notifications_none,
                label: 'Notificações',
                onTap: () => Navigator.pushNamed(context, '/notifications'),
              ),
              _MenuTile(
                icon: Icons.help_outline,
                label: 'Ajuda',
                onTap: _openWhatsAppSupport,
              ),
              _MenuTile(
                icon: Icons.info_outline,
                label: 'Sobre o app',
                onTap: () => Navigator.pushNamed(context, '/about'),
              ),
              _MenuTile(
                icon: Icons.logout,
                label: 'Sair',
                onTap: _logout,
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

  const _HeaderCard({
    required this.name,
    required this.email,
    required this.isOnline,
    required this.onToggleOnline,
  });
  final String name;
  final String email;
  final bool isOnline;
  final ValueChanged<bool> onToggleOnline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: AppSpacing.avatarMd / 2,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.black),
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
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isOnline ? cs.primaryContainer : cs.secondaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Row(
              children: [
                Icon(
                  isOnline ? Icons.check_circle : Icons.do_not_disturb_on_outlined,
                  color: isOnline ? cs.onPrimaryContainer : cs.onSecondaryContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    isOnline ? 'Você está Online' : 'Você está Offline',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isOnline ? cs.onPrimaryContainer : cs.onSecondaryContainer,
                    ),
                  ),
                ),
                Switch(
                  value: isOnline,
                  onChanged: onToggleOnline,
                  activeThumbColor: cs.onPrimary,
                  activeTrackColor: cs.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

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
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

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
          border: Border.all(color: cs.outlineVariant),
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

class _WalletPill extends StatelessWidget {
  const _WalletPill({required this.amountText});
  final String amountText;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Text(
        amountText,
        style: AppTypography.labelLarge.copyWith(color: cs.onTertiaryContainer),
      ),
    );
  }
}