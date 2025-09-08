import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/user_service.dart';
import '../../services/driver_service.dart';
import '../../services/emulator_optimized_auth_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/supabase_helper.dart';
import '../../utils/emulator_auth_helper.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/logo_branding.dart';

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
      print('🔑 [LOGIN] Iniciando processo de login');
      print('🔑 [LOGIN] Email: ${_emailController.text.trim()}');

      print(
          '🔑 [LOGIN] Supabase inicializado: ${SupabaseHelper.isInitialized}');

      if (!SupabaseHelper.isInitialized) {
        throw Exception(
            'Supabase não foi inicializado. Verifique sua conexão.');
      }

      print('🔄 [LOGIN] Usando EmulatorOptimizedAuthService');
      final response = await EmulatorOptimizedAuthService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null && response.session != null) {
        // Login bem-sucedido com session válida
        final userInfo = {
          'id': response.user!.id,
          'email': response.user!.email,
          'user_type': 'passenger', // Será obtido do banco
        };

        print('✅ [LOGIN] Usuário autenticado: ${userInfo['id']}');

        if (!mounted) return;

        // Buscar dados completos do usuário para verificar o tipo e status do perfil
        final currentUser = await UserService.getCurrentUser();

        if (!mounted) return;
        if (currentUser == null) {
          // Se não conseguiu buscar o usuário, redirecionar para completar cadastro
          Navigator.of(context).pushReplacementNamed(
            '/select_user_type',
            arguments: {
              'email': userInfo['email'] as String,
              'userId': userInfo['id'] as String,
            },
          );
          return;
        }

        // Verificar se o perfil está completo
        if (!currentUser.profileComplete) {
          print(
              '🔄 [LOGIN] Usuário com perfil incompleto, redirecionando para stepper');
          // Perfil incompleto - redirecionar para o stepper apropriado
          if (currentUser.userType == 'driver') {
            Navigator.of(context).pushReplacementNamed('/driver_stepper');
          } else {
            Navigator.of(context).pushReplacementNamed('/registration_stepper');
          }
        } else {
          print('✅ [LOGIN] Usuário com perfil completo, verificando status...');

          // Para motoristas, verificar status de aprovação
          if (currentUser.userType == 'driver') {
            await _handleDriverLogin(currentUser.id);
          } else {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      } else {
        // Login falhou
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Falha no login. Verifique suas credenciais.')),
        );
      }
    } catch (e) {
      print('❌ [LOGIN] Erro durante login: $e');
      if (!mounted) return;

      String errorMessage =
          'Erro de autenticação. Por favor, verifique suas credenciais e tente novamente.';

      if (e.toString().contains('Invalid login credentials')) {
        errorMessage = 'Email ou senha incorretos.';
      } else if (e.toString().contains('Email not confirmed')) {
        errorMessage = 'Por favor, confirme seu email antes de fazer login.';
      } else if (e.toString().contains('Too many requests')) {
        errorMessage =
            'Muitas tentativas de login. Tente novamente em alguns minutos.';
      } else if (e.toString().contains('Network')) {
        errorMessage =
            'Erro de conexão. Verifique sua internet e tente novamente.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleDriverLogin(String userId) async {
    try {
      print('🚗 [LOGIN] Verificando status do motorista...');

      // Buscar dados do motorista
      final supabase = SupabaseHelper.client!;
      final driverService = DriverService(supabase);
      final driver = await driverService.getDriverByUserId(userId);

      if (!mounted) return;

      if (driver == null) {
        print(
            '❌ [LOGIN] Motorista não encontrado, redirecionando para stepper');
        Navigator.of(context).pushReplacementNamed('/driver_stepper');
        return;
      }

      print('📊 [LOGIN] Status da aprovação: ${driver.approvalStatus} (dados frescos do banco - sem cache)');

      // Verificar status de aprovação (dados sempre frescos)
      switch (driver.approvalStatus.toLowerCase()) {
        case 'pending':
        case 'under_review':
          print('⏳ [LOGIN] Motorista aguardando aprovação');
          Navigator.of(context)
              .pushReplacementNamed('/driver_approval_pending');
          break;

        case 'approved':
          print('✅ [LOGIN] Motorista aprovado, redirecionando para home');
          Navigator.of(context).pushReplacementNamed('/driver_home');
          break;

        case 'rejected':
        case 'denied':
          print('❌ [LOGIN] Motorista rejeitado');
          _showRejectionDialog();
          break;

        default:
          print('⚠️ [LOGIN] Status desconhecido: ${driver.approvalStatus}');
          Navigator.of(context)
              .pushReplacementNamed('/driver_approval_pending');
          break;
      }
    } catch (e) {
      print('❌ [LOGIN] Erro ao verificar status do motorista: $e');
      // Em caso de erro, redirecionar para home do motorista
      Navigator.of(context).pushReplacementNamed('/driver_home');
    }
  }

  void _showRejectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Cadastro Não Aprovado'),
        content: Text(
          'Infelizmente sua solicitação para se tornar motorista parceiro não foi aprovada.\n\n'
          'Você pode tentar novamente atualizando seus documentos ou entrar em contato com nosso suporte.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/driver_documents');
            },
            child: Text('Atualizar Documentos'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context)
                  .pushReplacementNamed('/driver_approval_pending');
            },
            child: Text('Ver Detalhes'),
          ),
        ],
      ),
    );
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
                              final emailRegex =
                                  RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                              if (!emailRegex.hasMatch(v))
                                return 'E-mail inválido';
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
                              if (v.length < 6)
                                return 'A senha deve ter ao menos 6 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => Navigator.pushNamed(
                                      context, '/forgot-password'),
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
                                  : () => Navigator.of(context)
                                      .pushReplacementNamed('/register'),
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
                          // Diagnóstico e debug options
                          Column(
                            children: [
                              // Botão de diagnóstico
                              SizedBox(height: AppSpacing.xs),
                            ],
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
