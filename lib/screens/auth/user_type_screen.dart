import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uber_clone/widgets/logo_branding.dart';
import 'package:uber_clone/services/user_service.dart';
import 'package:uber_clone/exceptions/app_exceptions.dart';
import 'package:provider/provider.dart';
import 'package:uber_clone/controllers/stepper_controller.dart';

class UserTypeScreen extends StatefulWidget {
  const UserTypeScreen({super.key});

  @override
  State<UserTypeScreen> createState() => _UserTypeScreenState();
}

class _UserTypeScreenState extends State<UserTypeScreen> {
  String? _selectedType; // 'passenger' or 'driver'

  void _onSelect(String type) {
    setState(() => _selectedType = type);
  }

  void _onContinue() async {
    if (_selectedType == null) return;
    try {
      // Obter o usuário autenticado atual
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      // Dados passados do registro (nome e email)
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final String? fullName = (args?['fullName'] as String?)?.trim();
      final String? emailFromArgs = (args?['email'] as String?)?.trim();
      final String? email = emailFromArgs ?? currentUser.email;

      if (email == null || email.isEmpty) {
        throw Exception('E-mail do usuário não disponível.');
      }

      // Armazenar em App State (StepperController) e seguir para o stepper
      final controller = Provider.of<StepperController>(context, listen: false);
      controller.setUserType(_selectedType!);
      if (fullName != null && fullName.isNotEmpty) controller.setFullName(fullName);
      controller.setEmail(email);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        '/registration_stepper',
        arguments: {
          'userType': _selectedType,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao continuar: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const LogoAppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Como você quer usar o app?',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecione uma opção para continuar',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _OptionCard(
                    icon: Icons.person_outline,
                    title: 'Passageiro',
                    description: 'Peça corridas de forma rápida e segura.',
                    selected: _selectedType == 'passenger',
                    onTap: () => _onSelect('passenger'),
                  ),
                  const SizedBox(height: 12),
                  _OptionCard(
                    icon: Icons.drive_eta,
                    title: 'Motorista',
                    description: 'Dirija e ganhe dinheiro nas suas horas vagas.',
                    selected: _selectedType == 'driver',
                    onTap: () => _onSelect('driver'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _selectedType == null ? null : _onContinue,
                      child: const Text('Continuar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Color containerColor = selected
        ? colorScheme.primaryContainer
        : colorScheme.surface;
    final Color borderColor = selected
        ? colorScheme.primary
        : colorScheme.outlineVariant;
    final Color titleColor = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;
    final Color descColor = selected
        ? colorScheme.onPrimaryContainer.withOpacity(0.8)
        : colorScheme.onSurfaceVariant;
    final Color iconColor = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: colorScheme.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primary.withOpacity(0.12)
                      : colorScheme.tertiary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleLarge?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: textTheme.bodyMedium?.copyWith(
                        color: descColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}