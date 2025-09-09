import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/driver_status_manager.dart';
import '../../models/user.dart' as app_user;
import '../../services/driver_wallet_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/user_utils.dart';
import '../../utils/menu_logger.dart';

class DriverMenuScreen extends StatefulWidget {
  const DriverMenuScreen({super.key});

  @override
  State<DriverMenuScreen> createState() => _DriverMenuScreenState();
}

class _DriverMenuScreenState extends State<DriverMenuScreen> {
  Future<app_user.User?>? _userFuture;
  Future<Map<String, dynamic>>? _walletStatsFuture;

  @override
  void initState() {
    super.initState();
    MenuLogger.logMenuLoad('DRIVER');
    _userFuture = UserService.getCurrentUser();
    _loadWalletStats();
  }

  void _loadWalletStats() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      _walletStatsFuture = DriverWalletService.getDriverWalletStats(currentUser.id)
          .catchError((e) {
        // Return default stats if driver doesn't exist yet
        return {
          'available_balance': 0.0,
          'pending_earnings': 0.0,
          'total_earnings': 0.0,
        };
      });
    }
  }

  Future<void> _logout() async {
    MenuLogger.logLogoutAttempt('DRIVER');
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () {
              MenuLogger.logLogoutConfirmation('DRIVER', false);
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              MenuLogger.logLogoutConfirmation('DRIVER', true);
              Navigator.of(context).pop(true);
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      try {
        MenuLogger.logLogoutSuccess('DRIVER');
        await Supabase.instance.client.auth.signOut();
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      } catch (e) {
        MenuLogger.logLogoutError('DRIVER', e);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao sair. Tente novamente.'),
          ),
        );
      }
    }
  }

  /// Verifica se o cadastro do motorista está completo antes de navegar para áreas
  Future<void> _navigateToOperationZones() async {
    MenuLogger.logScreenNavigation('DRIVER', 'Áreas de Atuação', navigationData: {'verification': 'required'});
    
    try {
      final user = await UserService.getCurrentUser();
      if (user == null) {
        MenuLogger.logNavigationError('DRIVER', 'Áreas de Atuação', 'User not found');
        _showRegistrationIncompleteDialog('Usuário não encontrado. Faça login novamente.');
        return;
      }

      // Verificar se existe driver na tabela drivers
      final supabase = Supabase.instance.client;
      final driverResponse = await supabase
          .from('drivers')
          .select('brand, model, plate, color')
          .eq('user_id', user.id)
          .maybeSingle();

      if (driverResponse == null) {
        MenuLogger.logNavigationError('DRIVER', 'Áreas de Atuação', 'Driver record not found');
        _showRegistrationIncompleteDialog(
          'Cadastro de motorista não encontrado.\n\n'
          'Complete seu cadastro primeiro através do botão "Finalizar Cadastro" no menu principal.'
        );
        return;
      }

      // Verificar se os dados não são "PENDENTE" (indicando cadastro incompleto)
      final brand = driverResponse['brand'] as String?;
      final model = driverResponse['model'] as String?;
      final plate = driverResponse['plate'] as String?;
      final color = driverResponse['color'] as String?;

      if (brand?.startsWith('PENDENTE') == true || 
          model?.startsWith('PENDENTE') == true || 
          plate?.startsWith('PENDENTE') == true || 
          color?.startsWith('PENDENTE') == true) {
        MenuLogger.logNavigationError('DRIVER', 'Áreas de Atuação', 'Incomplete driver registration');
        _showRegistrationIncompleteDialog(
          'Cadastro incompleto detectado.\n\n'
          'Você precisa finalizar seu cadastro de motorista antes de configurar áreas de atuação.\n\n'
          '• Complete os dados do veículo\n'
          '• Envie os documentos obrigatórios\n'
          '• Finalize o processo de cadastro\n\n'
          'Acesse o menu "Meu Veículo" para completar.'
        );
        return;
      }

      // Se chegou até aqui, o cadastro está completo - navegar normalmente
      MenuLogger.logScreenNavigation('DRIVER', 'Áreas de Atuação');
      if (mounted) {
        Navigator.pushNamed(context, '/driver_operation_zones');
      }
    } catch (e) {
      MenuLogger.logNavigationError('DRIVER', 'Áreas de Atuação', e);
      _showRegistrationIncompleteDialog(
        'Erro ao verificar cadastro: $e\n\n'
        'Tente novamente em alguns instantes.'
      );
    }
  }

  /// Exibe diálogo informando que o cadastro precisa ser completado
  void _showRegistrationIncompleteDialog(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('Cadastro Incompleto'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          if (message.contains('Meu Veículo'))
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/vehicle');
              },
              child: const Text('Ir para Meu Veículo'),
            ),
        ],
      ),
    );
  }

  Future<void> _openWhatsAppSupport() async {
    MenuLogger.logHelpAccess('DRIVER', 'WhatsApp Support');
    
    const phoneNumber = '556592577217';
    const message = 'Olá! Preciso de ajuda com o app Option - Sou motorista.';
    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = 'https://wa.me/$phoneNumber?text=$encodedMessage';
    
    final uri = Uri.parse(whatsappUrl);
    
    if (await canLaunchUrl(uri)) {
      MenuLogger.logExternalAppLaunch('DRIVER', 'WhatsApp', 'Open support chat');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      MenuLogger.logNavigationError('DRIVER', 'WhatsApp Support', 'Cannot launch URL');
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
              ListenableBuilder(
                listenable: DriverStatusManager().controller,
                builder: (context, _) => _HeaderCard(
                  name: UserUtils.getSafeName(user?.fullName, email: user?.email, fallback: 'Motorista'),
                  email: user?.email ?? '',
                  isOnline: DriverStatusManager().controller.isOnline,
                  onToggleOnline: (val) => DriverStatusManager().controller.toggleOnlineStatus(),
                  photoUrl: user?.photoUrl,
                ),
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),

              const _SectionTitle(title: 'Conta'),
              _MenuTile(
                icon: Icons.person_outline,
                label: 'Perfil',
                onTap: () {
                  MenuLogger.logScreenNavigation('DRIVER', 'Perfil');
                  Navigator.pushNamed(context, '/profile_edit').then((result) {
                    if (result == true) {
                      MenuLogger.logProfileUpdateSuccess('DRIVER');
                      setState(() {
                        _userFuture = UserService.getCurrentUser();
                      });
                    }
                  });
                },
              ),
              _MenuTile(
                icon: Icons.directions_car_outlined,
                label: 'Veículo',
                onTap: () {
                  MenuLogger.logScreenNavigation('DRIVER', 'Veículo');
                  Navigator.pushNamed(context, '/vehicle');
                },
              ),
              _MenuTile(
                icon: Icons.assignment_turned_in_outlined,
                label: 'Documentos',
                onTap: () {
                  MenuLogger.logScreenNavigation('DRIVER', 'Documentos');
                  Navigator.pushNamed(context, '/driver_documents');
                },
              ),

              const SizedBox(height: AppSpacing.sectionSpacing),
              const _SectionTitle(title: 'Trabalho'),
              _MenuTile(
                icon: Icons.remove_circle_outline,
                label: 'Zonas excluídas',
                onTap: () {
                  MenuLogger.logScreenNavigation('DRIVER', 'Zonas excluídas');
                  Navigator.pushNamed(context, '/driver_excluded_zones');
                },
              ),
              _MenuTile(
                icon: Icons.ac_unit_outlined,
                label: 'Política de ar-condicionado',
                onTap: () {
                  MenuLogger.logScreenNavigation('DRIVER', 'Política de ar-condicionado');
                  Navigator.pushNamed(context, '/ac_policy');
                },
              ),

              const SizedBox(height: AppSpacing.sectionSpacing),
              const _SectionTitle(title: 'Atividade'),
              _MenuTile(
                icon: Icons.history,
                label: 'Histórico de viagens',
                onTap: () {
                  MenuLogger.logScreenNavigation('DRIVER', 'Histórico de viagens');
                  Navigator.pushNamed(context, '/trip_history');
                },
              ),

              _MenuTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Carteira',
                trailing: FutureBuilder<Map<String, dynamic>>(
                  future: _walletStatsFuture,
                  builder: (context, walletSnapshot) {
                    final stats = walletSnapshot.data;
                    final availableBalance = stats?['available_balance'] as double? ?? 0.0;
                    if (stats != null) {
                      MenuLogger.logWalletBalanceDisplay('DRIVER', availableBalance);
                    }
                    return _WalletPill(
                      amountText: 'R\$ ${availableBalance.toStringAsFixed(2).replaceAll('.', ',')}',
                    );
                  },
                ),
                onTap: () {
                  MenuLogger.logScreenNavigation('DRIVER', 'Carteira');
                  Navigator.pushNamed(context, '/wallet');
                },
              ),

              const SizedBox(height: AppSpacing.sectionSpacing),
              const _SectionTitle(title: 'Geral'),
              // Botão Emergência ocultado
              // _MenuTile(
              //   icon: Icons.emergency,
              //   label: 'Emergência',
              //   onTap: () {
              //     MenuLogger.logScreenNavigation('DRIVER', 'Emergência');
              //     Navigator.pushNamed(context, '/emergency');
              //   },
              // ),
              _MenuTile(
                icon: Icons.notifications_none,
                label: 'Notificações',
                onTap: () {
                  MenuLogger.logScreenNavigation('DRIVER', 'Notificações');
                  Navigator.pushNamed(context, '/notifications');
                },
              ),
              _MenuTile(
                icon: Icons.help_outline,
                label: 'Ajuda',
                onTap: _openWhatsAppSupport,
              ),
              _MenuTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Política de Privacidade',
                onTap: () {
                  MenuLogger.logScreenNavigation('DRIVER', 'Política de Privacidade');
                  Navigator.pushNamed(context, '/privacy-policy');
                },
              ),
              _MenuTile(
                icon: Icons.info_outline,
                label: 'Sobre o app',
                onTap: () {
                  MenuLogger.logScreenNavigation('DRIVER', 'Sobre o app');
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
    required this.isOnline,
    required this.onToggleOnline,
    this.photoUrl,
  });
  final String name;
  final String email;
  final bool isOnline;
  final Future<void> Function(bool) onToggleOnline;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isOnline ? Colors.green.withOpacity(0.15) : cs.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: isOnline ? Colors.green : cs.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(
                  isOnline ? Icons.toggle_on : Icons.toggle_off,
                  color: isOnline ? Colors.green : cs.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    isOnline ? 'Você está online' : 'Você está offline',
                    style: AppTypography.bodyMedium.copyWith(color: cs.onSurface),
                  ),
                ),
                Switch(
                  value: isOnline,
                  onChanged: onToggleOnline,
                ),
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
        MenuLogger.logMenuSectionView('DRIVER', widget.title);
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