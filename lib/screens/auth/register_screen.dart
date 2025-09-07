import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_spacing.dart';
import '../../utils/supabase_helper.dart';
import '../../services/emulator_optimized_auth_service.dart';
import '../../utils/emulator_auth_helper.dart';
import '../../validators/database_constraints_validator.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/logo_branding.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final bool _isObscure = true;
  final bool _isConfirmObscure = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      // Force rebuild to show validation errors
      setState(() {});
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final email = _emailController.text.trim();
      final fullName = _nameController.text.trim();
      final password = _passwordController.text;

      final supabase = SupabaseHelper.client;
      if (supabase == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço indisponível. Tente novamente.'),
          ),
        );
        return;
      }

      // USAR EMULATOR OPTIMIZED AUTH SERVICE
      print('🚀 [REGISTER] Usando EmulatorOptimizedAuthService...');
      final response = await EmulatorOptimizedAuthService.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': '', // Adicione se necessário
        },
      );

      if (response.user != null) {
        // Sucesso - usuário criado com token JWT válido
        print('🚀 [REGISTER] Registro bem-sucedido!');
        print('🚀 [REGISTER] User ID: ${response.user!.id}');

        if (!mounted) return;

        // Registro bem-sucedido - navegar para seleção de tipo
        Navigator.of(context).pushReplacementNamed(
          '/select_user_type',
          arguments: {
            'fullName': fullName,
            'email': email,
            'userId': response.user!.id,
          },
        );
      } else {
        // Falha no registro
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro no registro. Tente novamente.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar conta: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: VerticalBrandLogo()),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Crie sua conta',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Preencha os dados abaixo para se cadastrar',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    padding: AppSpacing.paddingMd,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            controller: _nameController,
                            labelText: 'Nome completo',
                            hintText: 'Ex: João Silva',
                            prefixIcon: const Icon(Icons.person_outline),
                            validator: (value) {
                              final v = value?.trim() ?? '';
                              if (v.isEmpty) return 'Informe seu nome';
                              if (v.length < 3)
                                return 'O nome deve ter ao menos 3 caracteres';

                              // Verificar se o usuário digitou um email no campo de nome
                              final emailRegex =
                                  RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                              if (emailRegex.hasMatch(v)) {
                                return 'Você digitou um e-mail no campo de nome. Por favor, digite apenas seu nome completo.';
                              }

                              // Verificar se contém caracteres típicos de email
                              if (v.contains('@') ||
                                  v.contains('.com') ||
                                  v.contains('.br')) {
                                return 'O nome não deve conter @ ou domínios de email. Digite apenas seu nome completo.';
                              }

                              // Usar DatabaseConstraintsValidator para validação adicional
                              try {
                                DatabaseConstraintsValidator
                                    .validateFullNameField(v);
                              } catch (e) {
                                return e
                                    .toString()
                                    .replaceAll('ValidationException: ', '');
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppEmailField(
                            controller: _emailController,
                            hintText: 'Ex: joao@email.com',
                            validator: (value) {
                              final v = value?.trim() ?? '';
                              if (v.isEmpty) return 'Informe seu e-mail';

                              final emailRegex =
                                  RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                              if (!emailRegex.hasMatch(v)) {
                                // Verificar se o usuário digitou um nome no campo de email
                                if (!v.contains('@') && !v.contains('.')) {
                                  return 'Você digitou um nome no campo de e-mail. Por favor, digite um e-mail válido.';
                                }
                                return 'E-mail inválido. Use o formato: exemplo@email.com';
                              }

                              // Usar DatabaseConstraintsValidator para validação adicional
                              try {
                                DatabaseConstraintsValidator.validateEmailField(
                                    v);
                              } catch (e) {
                                return e
                                    .toString()
                                    .replaceAll('ValidationException: ', '');
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppPasswordField(
                            controller: _passwordController,
                            validator: (value) {
                              final v = value ?? '';
                              if (v.isEmpty) return 'Informe sua senha';
                              if (v.length < 6)
                                return 'A senha deve ter ao menos 6 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppPasswordField(
                            controller: _confirmPasswordController,
                            labelText: 'Confirmar senha',
                            onSubmitted: (_) => _onSubmit(),
                            validator: (value) {
                              final v = value ?? '';
                              if (v.isEmpty) return 'Confirme sua senha';
                              if (v != _passwordController.text)
                                return 'As senhas não coincidem';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Ao se cadastrar, você aceita nossos Termos de Uso e Política de Privacidade.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              onPressed: _isSubmitting ? null : _onSubmit,
                              child: _isSubmitting
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.onPrimary,
                                      ),
                                    )
                                  : const Text('Cadastrar'),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs * 3),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: TextButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => Navigator.of(context)
                                      .pushReplacementNamed('/login'),
                              child: Text(
                                'Já tem uma conta? Entrar',
                                style: textTheme.labelLarge
                                    ?.copyWith(color: colorScheme.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
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
