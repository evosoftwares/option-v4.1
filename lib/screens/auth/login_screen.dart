import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/user_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/logo_branding.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final bool _isObscure = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isSubmitting = true);

    try {
      final supabase = Supabase.instance.client;
      final authResponse = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = authResponse.user ?? Supabase.instance.client.auth.currentUser;

      if (user == null) {
        throw const AuthException('Falha ao obter usuário autenticado');
      }

      // Verificar se o app_user existe
      final exists = await UserService.userExists(user.id);

      if (!mounted) return;
      if (!exists) {
        // App_users não existe - redirecionar para completar o cadastro
        Navigator.of(context).pushReplacementNamed(
          '/select_user_type',
          arguments: {
            'email': user.email,
          },
        );
      } else {
        // Buscar dados completos do usuário para verificar o tipo
        final currentUser = await UserService.getCurrentUser();
        
        // Dados do usuário validados - prosseguir normalmente
        
        if (!mounted) return;
        if (currentUser != null && currentUser.userType == 'driver') {
          Navigator.of(context).pushReplacementNamed('/driver_home');
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de autenticação. Por favor, verifique suas credenciais e tente novamente.')),
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: VerticalBrandLogo()),
                  const SizedBox(height: AppSpacing.lg),
                   Text(
                     'Bem-vindo(a)',
                     style: textTheme.headlineSmall?.copyWith(
                       color: colorScheme.onSurface,
                       fontWeight: FontWeight.w700,
                     ),
                   ),
                   const SizedBox(height: AppSpacing.sm),
                   Text(
                     'Acesse sua conta para continuar',
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
                           AppEmailField(
                              controller: _emailController,
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (v.isEmpty) return 'Informe seu e-mail';
                                final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                                if (!emailRegex.hasMatch(v)) return 'E-mail inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppPasswordField(
                              controller: _passwordController,
                              onSubmitted: (_) => _onSubmit(),
                              validator: (value) {
                                final v = value ?? '';
                                if (v.isEmpty) return 'Informe sua senha';
                                if (v.length < 6) return 'A senha deve ter ao menos 6 caracteres';
                                return null;
                              },
                            ),
                             const SizedBox(height: AppSpacing.sm),
                             Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isSubmitting ? null : () => Navigator.pushNamed(context, '/forgot-password'),
                                child: Text(
                                  'Esqueceu sua senha?',
                                  style: textTheme.labelLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                             const SizedBox(height: AppSpacing.md),
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
                                     : const Text('Entrar'),
                               ),
                             ),
                             const SizedBox(height: AppSpacing.xs * 3),
                             SizedBox(
                               width: double.infinity,
                               height: 56,
                               child: TextButton(
                                 onPressed: _isSubmitting
                                     ? null
                                     : () => Navigator.of(context).pushReplacementNamed('/register'),
                                 child: Text(
                                   'Criar uma conta',
                                   style: textTheme.labelLarge?.copyWith(
                                     color: colorScheme.primary,
                                     fontWeight: FontWeight.w600,
                                   ),
                                 ),
                               ),
                             ),
                             const SizedBox(height: AppSpacing.sm),
                             // Botão temporário para debug do Supabase
                             SizedBox(
                               width: double.infinity,
                               height: 40,
                               child: OutlinedButton(
                                 onPressed: () => Navigator.of(context).pushNamed('/debug_supabase'),
                                 style: OutlinedButton.styleFrom(
                                   foregroundColor: colorScheme.secondary,
                                   side: BorderSide(color: colorScheme.secondary),
                                 ),
                                 child: Text(
                                   '🔧 Debug Supabase',
                                   style: textTheme.labelSmall?.copyWith(
                                     color: colorScheme.secondary,
                                   ),
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