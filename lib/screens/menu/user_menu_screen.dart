import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/user.dart' as app_user;
import '../../services/user_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/user_utils.dart';
import '../../widgets/feedback/index.dart';
import '../../utils/menu_logger.dart';

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
    MenuLogger.logMenuLoad('USER');
    _userFuture = UserService.getCurrentUser();
  }

  void _showComingSoon(String label) {
    MenuLogger.logComingSoonTap('USER', label);
    
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$label" em breve', style: AppTypography.bodyMedium.copyWith(color: theme.colorScheme.onInverseSurface)),
      ),
    );
  }

  Future<void> _logout() async {
    MenuLogger.logLogoutAttempt('USER');
    
    final confirm = await AppDialogUtils.showConfirmation(
      context,
      title: 'Sair',
      content: 'Tem certeza que deseja sair?',
      confirmLabel: 'Sair',
    );

    if (confirm ?? false) {
      try {
        MenuLogger.logLogoutSuccess('USER');
        await Supabase.instance.client.auth.signOut();
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      } catch (e) {
        MenuLogger.logLogoutError('USER', e);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao sair. Tente novamente.'),
          ),
        );
      }
    } else {
      MenuLogger.logLogoutConfirmation('USER', false);
    }
  }

  Future<void> _openWhatsAppSupport() async {
    MenuLogger.logHelpAccess('USER', 'WhatsApp Support');
    
    const phoneNumber = '556592577217';
    const message = 'Olá! Preciso de ajuda com o app Option.';
    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = 'https://wa.me/$phoneNumber?text=$encodedMessage';
    
    final uri = Uri.parse(whatsappUrl);
    
    if (await canLaunchUrl(uri)) {
      MenuLogger.logExternalAppLaunch('USER', 'WhatsApp', 'Open support chat');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      MenuLogger.logNavigationError('USER', 'WhatsApp Support', 'Cannot launch URL');
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
                name: UserUtils.getSafeName(user?.fullName, email: user?.email, fallback: 'Passageiro'),
                email: user?.email ?? '',
                photoUrl: user?.photoUrl,
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),

              const _SectionTitle(title: 'Conta'),
              _MenuTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Carteira',
                onTap: () {
                  MenuLogger.logScreenNavigation('USER', 'Carteira');
                  Navigator.pushNamed(context, '/wallet');
                },
              ),
              _MenuTile(
                icon: Icons.person_outline,
                label: 'Perfil',
                onTap: () {
                  MenuLogger.logScreenNavigation('USER', 'Perfil');
                  Navigator.pushNamed(context, '/profile_edit').then((result) {
                    if (result == true) {
                      MenuLogger.logProfileUpdateSuccess('USER');
                      setState(() {
                        _userFuture = UserService.getCurrentUser();
                      });
                    }
                  });
                },
              ),
              // Opção Pagamentos removida temporariamente
              // _MenuTile(
              //   icon: Icons.payment_outlined,
              //   label: 'Pagamentos',
              //   onTap: () {
              //     MenuLogger.logScreenNavigation('USER', 'Pagamentos');
              //     Navigator.pushNamed(context, '/payments');
              //   },
              // ),

              const SizedBox(height: AppSpacing.sectionSpacing),
              const _SectionTitle(title: 'Viagens'),
              _MenuTile(
                icon: Icons.history,
                label: 'Histórico de viagens',
                onTap: () {
                  MenuLogger.logScreenNavigation('USER', 'Histórico de viagens');
                  Navigator.pushNamed(context, '/trip_history');
                },
              ),

              const SizedBox(height: AppSpacing.sectionSpacing),
              const _SectionTitle(title: 'Geral'),
              // Botão Emergência ocultado
              // _MenuTile(
              //   icon: Icons.emergency,
              //   label: 'Emergência',
              //   onTap: () {
              //     MenuLogger.logScreenNavigation('USER', 'Emergência');
              //     Navigator.pushNamed(context, '/emergency');
              //   },
              // ),
              _MenuTile(
                icon: Icons.notifications_none,
                label: 'Notificações',
                onTap: () {
                  MenuLogger.logScreenNavigation('USER', 'Notificações');
                  Navigator.pushNamed(context, '/notifications');
                },
              ),
              _MenuTile(
                icon: Icons.help_outline,
                label: 'Ajuda',
                onTap: _openWhatsAppSupport,
              ),
              _MenuTile(
                icon: Icons.info_outline,
                label: 'Sobre o app',
                onTap: () {
                  MenuLogger.logScreenNavigation('USER', 'Sobre o app');
                  Navigator.pushNamed(context, '/about');
                },
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
    this.photoUrl,
  });
  final String name;
  final String email;
  final String? photoUrl;

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
      child: Row(
        children: [
          CircleAvatar(
            radius: AppSpacing.avatarMd / 2,
            backgroundColor: cs.surface,
            backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty) ? NetworkImage(photoUrl!) : null,
            child: (photoUrl == null || photoUrl!.isEmpty)
                ? Icon(Icons.person, color: cs.onSurface)
                : null,
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

class _SectionTitle extends StatefulWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  State<_SectionTitle> createState() => _SectionTitleState();
}

class _SectionTitleState extends State<_SectionTitle> {
  @override
  void initState() {
    super.initState();
    // Log section view when the section title is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        MenuLogger.logMenuSectionView('USER', widget.title);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        widget.title,
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
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

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
            
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}