import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/user_service.dart';
import '../../models/user.dart' as app;
import '../../theme/app_spacing.dart';
import '../../utils/phone_mask.dart';
import '../../utils/phone_validator.dart';
import '../../widgets/logo_branding.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  String? _selectedType; // 'passenger' | 'driver'

  bool _loading = true;
  bool _saving = false;
  app.User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      final user = await UserService.getUserById(authUser.id);
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Usuário não encontrado'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      _currentUser = user;
      _nameController.text = user.fullName;
      _phoneController.text = user.phone != null && user.phone!.isNotEmpty
          ? PhoneValidator.format(user.phone!)
          : '';
      _selectedType = user.userType;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erro ao carregar dados. Por favor, tente novamente mais tarde.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onSave() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    if (_currentUser == null) return;

    setState(() => _saving = true);
    try {
      final unformattedPhone = _phoneController.text.isNotEmpty
          ? PhoneValidator.unformat(_phoneController.text)
          : null;

      final updated = await UserService.updateUser(
        userId: _currentUser!.id,
        fullName: _nameController.text.trim(),
        phone: unformattedPhone,
        userType: _selectedType,
      );

      if (!mounted) return;
      setState(() => _currentUser = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Perfil atualizado com sucesso'),
          backgroundColor: Theme.of(context).colorScheme.inverseSurface,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erro ao salvar. Por favor, verifique os dados e tente novamente.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const StandardAppBar(title: 'Editar perfil'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              minimum: AppSpacing.screenMargin,
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Container surface for user info
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Informações da conta', style: textTheme.titleLarge),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              _currentUser?.email ?? '-',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Full name field
                    Text('Nome completo', style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.name,
                      decoration: const InputDecoration(
                        hintText: 'Seu nome e sobrenome',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe seu nome completo';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Phone field
                    Text('Telefone', style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        PhoneInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        hintText: '(11) 9 1234-5678',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return null; // opcional
                        }
                        return PhoneValidator.validate(value);
                      },
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // User type selection
                    Text('Tipo de usuário', style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        _TypeChip(
                          label: 'Passageiro',
                          value: 'passenger',
                          groupValue: _selectedType,
                          onSelected: (v) => setState(() => _selectedType = v),
                        ),
                        _TypeChip(
                          label: 'Motorista',
                          value: 'driver',
                          groupValue: _selectedType,
                          onSelected: (v) => setState(() => _selectedType = v),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                    FilledButton(
                      onPressed: _saving ? null : _onSave,
                      child: _saving
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Text('Salvar alterações'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _TypeChip extends StatelessWidget {

  const _TypeChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });
  final String label;
  final String value;
  final String? groupValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = value == groupValue;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
      selectedColor: colorScheme.secondaryContainer,
      backgroundColor: colorScheme.surface,
      labelStyle: TextStyle(
        color: selected ? colorScheme.onSecondaryContainer : colorScheme.onSurface,
      ),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? colorScheme.secondary : colorScheme.outlineVariant,
        ),
      ),
    );
  }
}