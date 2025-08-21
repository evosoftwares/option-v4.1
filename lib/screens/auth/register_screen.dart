import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool _isObscure = true;
  bool _isConfirmObscure = true;
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
    if (!isValid) return;

    setState(() => _isSubmitting = true);

    try {
      print('📝 Iniciando registro...');
      print('📧 Email: ${_emailController.text.trim()}');
      print('👤 Nome: ${_nameController.text.trim()}');
      
      final supabase = Supabase.instance.client;
      final res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      print('🔐 Resposta do signUp:');
      print('  - Session: ${res.session != null ? "✅ Criada" : "❌ Null"}');
      print('  - User: ${res.user?.id ?? "❌ Null"}');

      if (!mounted) return;

      if (res.session != null) {
        print('✅ Sessão criada diretamente - navegando para seleção de tipo');
        // Sessão criada diretamente (sem confirmação por e-mail)
        // Não criar app_users aqui. Levar usuário para a seleção de tipo.
        Navigator.of(context).pushReplacementNamed(
          '/select_user_type',
          arguments: {
            'fullName': _nameController.text.trim(),
            'email': _emailController.text.trim(),
          },
        );
      } else {
        print('📧 Confirmação por e-mail necessária');
        // Confirmação por e-mail necessária
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verifique seu e-mail para confirmar a conta.')),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } on AuthException catch (e) {
      print('❌ AuthException: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de autenticação: ${e.message}')),
      );
    } catch (e) {
      print('❌ Erro geral no registro: $e');
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: VerticalBrandLogo()),
                  const SizedBox(height: 24),
                  Text(
                    'Crie sua conta',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preencha os dados abaixo para se cadastrar',
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
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Nome completo',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (v.isEmpty) return 'Informe seu nome';
                                if (v.length < 3) return 'O nome deve ter ao menos 3 caracteres';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
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
                              textInputAction: TextInputAction.next,
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
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _isConfirmObscure,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _onSubmit(),
                              decoration: InputDecoration(
                                labelText: 'Confirmar senha',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _isConfirmObscure = !_isConfirmObscure),
                                  icon: Icon(
                                    _isConfirmObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                final v = value ?? '';
                                if (v.isEmpty) return 'Confirme sua senha';
                                if (v != _passwordController.text) return 'As senhas não coincidem';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
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
                                    : const Text('Cadastrar'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: TextButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () => Navigator.of(context).pushReplacementNamed('/login'),
                                child: Text(
                                  'Já tem uma conta? Entrar',
                                  style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
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