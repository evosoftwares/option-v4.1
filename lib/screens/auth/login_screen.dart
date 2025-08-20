import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uber_clone/widgets/logo_branding.dart';
import 'package:uber_clone/services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true;
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
        throw AuthException('Falha ao obter usuário autenticado');
      }

      // Verificar se o app_user existe
      final exists = await UserService.userExists(user.id);

      if (!mounted) return;
      if (!exists) {
        // Redirecionar obrigatoriamente para seleção de tipo de usuário
        Navigator.of(context).pushReplacementNamed(
          '/select_user_type',
          arguments: {
            'email': user.email,
          },
        );
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
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
      appBar: null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: VerticalBrandLogo()),
                  const SizedBox(height: 24),
                   Text(
                     'Bem-vindo(a)',
                     style: textTheme.headlineSmall?.copyWith(
                       color: colorScheme.onSurface,
                       fontWeight: FontWeight.w700,
                     ),
                   ),
                   const SizedBox(height: 8),
                   Text(
                     'Acesse sua conta para continuar',
                     style: textTheme.bodyMedium?.copyWith(
                       color: colorScheme.onSurfaceVariant,
                     ),
                   ),
                   const SizedBox(height: 24),
                   Card(
                     child: Padding(
                       padding: const EdgeInsets.all(16),
                       child: Form(
                         key: _formKey,
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.stretch,
                           children: [
                             TextFormField(
                               controller: _emailController,
                               keyboardType: TextInputType.emailAddress,
                               textInputAction: TextInputAction.next,
                               decoration: const InputDecoration(
                                 labelText: 'E-mail',
                                 prefixIcon: Icon(Icons.email_outlined),
                               ),
                               validator: (value) {
                                 final v = value?.trim() ?? '';
                                 if (v.isEmpty) return 'Informe seu e-mail';
                                 final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                                 if (!emailRegex.hasMatch(v)) return 'E-mail inválido';
                                 return null;
                               },
                             ),
                             const SizedBox(height: 16),
                             TextFormField(
                               controller: _passwordController,
                               obscureText: _isObscure,
                               textInputAction: TextInputAction.done,
                               onFieldSubmitted: (_) => _onSubmit(),
                               decoration: InputDecoration(
                                 labelText: 'Senha',
                                 prefixIcon: const Icon(Icons.lock_outline),
                                 suffixIcon: IconButton(
                                   onPressed: () => setState(() => _isObscure = !_isObscure),
                                   icon: Icon(
                                     _isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                     color: colorScheme.onSurfaceVariant,
                                   ),
                                 ),
                               ),
                               validator: (value) {
                                 final v = value ?? '';
                                 if (v.isEmpty) return 'Informe sua senha';
                                 if (v.length < 6) return 'A senha deve ter ao menos 6 caracteres';
                                 return null;
                               },
                             ),
                             const SizedBox(height: 8),
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
                             const SizedBox(height: 16),
                             SizedBox(
                               width: double.infinity,
                               height: 48,
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
                             const SizedBox(height: 12),
                             SizedBox(
                               width: double.infinity,
                               height: 48,
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
                           ],
                         ),
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