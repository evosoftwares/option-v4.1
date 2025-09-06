import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../services/onesignal_service.dart';
import 'notification_permission_dialog.dart';
import 'notification_status_card.dart';

class NotificationOnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  final bool isRequired;

  const NotificationOnboardingScreen({
    super.key,
    this.onComplete,
    this.isRequired = false,
  });

  @override
  State<NotificationOnboardingScreen> createState() => _NotificationOnboardingScreenState();
}

class _NotificationOnboardingScreenState extends State<NotificationOnboardingScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  NotificationPermissionStatus _permissionStatus = NotificationPermissionStatus.unknown;
  OneSignalConnectionStatus _connectionStatus = OneSignalConnectionStatus.disconnected;
  String? _errorMessage;
  bool _isInitializing = true;
  
  int _currentStep = 0;
  final PageController _pageController = PageController();
  
  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'Receba Notificações Importantes',
      subtitle: 'Nunca perca uma viagem ou mensagem importante',
      icon: Icons.notifications_active,
      color: Colors.blue,
      benefits: [
        'Avisos quando o motorista chegar',
        'Mensagens em tempo real',
        'Status da viagem atualizado',
        'Confirmações de pagamento',
      ],
    ),
    OnboardingStep(
      title: 'Som Personalizado',
      subtitle: 'Identifique facilmente notificações do Option',
      icon: Icons.volume_up,
      color: Colors.green,
      benefits: [
        'Som exclusivo para viagens',
        'Diferente de outras notificações',
        'Volume ajustável',
        'Funciona mesmo em modo silencioso',
      ],
    ),
    OnboardingStep(
      title: 'Segurança e Privacidade',
      subtitle: 'Seus dados estão protegidos conosco',
      icon: Icons.security,
      color: Colors.orange,
      benefits: [
        'Notificações criptografadas',
        'Sem compartilhamento de dados',
        'Controle total de privacidade',
        'Pode desativar a qualquer momento',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _initializeOneSignal();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeOneSignal() async {
    setState(() {
      _isInitializing = true;
      _connectionStatus = OneSignalConnectionStatus.connecting;
    });
    
    try {
      await OneSignalService().initialize();
      
      // Simular verificação de permissões
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _connectionStatus = OneSignalConnectionStatus.connected;
        _permissionStatus = NotificationPermissionStatus.unknown; // Será definido quando solicitar
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _connectionStatus = OneSignalConnectionStatus.error;
        _permissionStatus = NotificationPermissionStatus.error;
        _errorMessage = 'Erro ao inicializar: ${e.toString()}';
        _isInitializing = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _permissionStatus = NotificationPermissionStatus.requesting;
    });
    
    try {
      final granted = await _showPermissionDialog();
      
      setState(() {
        _permissionStatus = granted == true 
          ? NotificationPermissionStatus.granted 
          : NotificationPermissionStatus.denied;
      });
      
      if (granted == true) {
        await _finishOnboarding();
      }
    } catch (e) {
      setState(() {
        _permissionStatus = NotificationPermissionStatus.error;
        _errorMessage = 'Erro ao solicitar permissão: ${e.toString()}';
      });
    }
  }

  Future<bool?> _showPermissionDialog() async {
    return await NotificationPermissionDialog.show(
      context,
      reason: NotificationPermissionReason.firstTime,
      customMessage: 'Para completar a configuração, precisamos de sua permissão para enviar notificações importantes sobre suas viagens.',
    );
  }

  Future<void> _finishOnboarding() async {
    // Animação de sucesso
    await _animationController.reverse();
    
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).pop(true);
    }
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _requestPermission();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    if (!widget.isRequired) {
      Navigator.of(context).pop(false);
    } else {
      _requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    _buildHeader(colorScheme),
                    Expanded(child: _buildContent()),
                    _buildFooter(colorScheme),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuração de Notificações',
                style: AppTypography.headlineSmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Passo ${_currentStep + 1} de ${_steps.length}',
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (!widget.isRequired)
            TextButton(
              onPressed: _skipOnboarding,
              child: Text(
                'Pular',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isInitializing) {
      return _buildInitializingState();
    }

    return Column(
      children: [
        // Progress indicator
        Padding(
          padding: AppSpacing.paddingLg,
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _steps.length,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              _steps[_currentStep].color,
            ),
          ),
        ),
        
        // Status card (if there are errors)
        if (_errorMessage != null)
          NotificationStatusCard(
            permissionStatus: _permissionStatus,
            connectionStatus: _connectionStatus,
            errorMessage: _errorMessage,
            onRetry: _initializeOneSignal,
            showDetails: false,
          ),
        
        // Content pages
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentStep = index;
              });
            },
            itemCount: _steps.length,
            itemBuilder: (context, index) {
              return _buildStepContent(_steps[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInitializingState() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Inicializando sistema de notificações...',
            style: AppTypography.bodyLarge.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Isso pode levar alguns segundos',
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(OnboardingStep step) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: step.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              step.icon,
              size: 64,
              color: step.color,
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Title and subtitle
          Text(
            step.title,
            style: AppTypography.headlineMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          Text(
            step.subtitle,
            style: AppTypography.bodyLarge.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Benefits
          Card(
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Benefícios:',
                    style: AppTypography.titleMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...step.benefits.map((benefit) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: step.color,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            benefit,
                            style: AppTypography.bodyMedium.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ColorScheme colorScheme) {
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Anterior'),
              ),
            ),
          if (_currentStep > 0)
            const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _nextStep,
              icon: Icon(
                _currentStep < _steps.length - 1 
                  ? Icons.arrow_forward 
                  : Icons.notifications_active,
                size: 18,
              ),
              label: Text(
                _currentStep < _steps.length - 1 
                  ? 'Próximo' 
                  : 'Ativar Notificações',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _steps[_currentStep].color,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> benefits;

  const OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.benefits,
  });
}