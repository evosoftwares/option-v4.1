import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/stepper_controller.dart';
import '../../exceptions/user_registration_exception.dart';
import '../../models/favorite_location.dart';
import 'phone_step.dart';
import 'photo_step.dart';
import 'places_step.dart';

class UserRegistrationStepper extends StatefulWidget {
  const UserRegistrationStepper({super.key});

  @override
  State<UserRegistrationStepper> createState() => _UserRegistrationStepperState();
}

class _UserRegistrationStepperState extends State<UserRegistrationStepper> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isCompletingRegistration = false;
  String? _registrationError;
  UserRegistrationException? _registrationException;

  @override
  void initState() {
    super.initState();
    print('🔄 Iniciando UserRegistrationStepper...');
    final controller = Provider.of<StepperController>(context, listen: false);
    print('📋 Estado atual do controller:');
    print('  - userType: ${controller.userType}');
    print('  - fullName: ${controller.fullName}');
    print('  - email: ${controller.email}');
    print('  - phone: ${controller.phone}');
    
    // Delay loadUserData until after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadUserData();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Após o PlacesStep, finalizar cadastro
      _completeRegistration();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _jumpToStep(int step) {
    if (step >= 0 && step <= 2) {
      setState(() {
        _currentStep = step;
      });
      _pageController.jumpToPage(step);
    }
  }

  Future<void> _saveFavoriteLocations(List<FavoriteLocation> locations) async {
    final controller = Provider.of<StepperController>(context, listen: false);
    
    try {
      // Salvar locais favoritos usando o RealSavedPlacesService
      await controller.saveFavoriteLocations(locations);
      print('✅ Locais favoritos salvos com sucesso: ${locations.length} locais');
    } catch (e) {
      print('❌ Erro ao salvar locais favoritos: $e');
      rethrow;
    }
  }

  Future<void> _completeRegistration() async {
    if (_isCompletingRegistration) return;
    
    final timestamp = DateTime.now().toIso8601String();
    
    setState(() {
      _isCompletingRegistration = true;
      _registrationError = null;
    });
    
    print('🏁 [$timestamp] [REGISTRATION] Finalizando cadastro...');
    final controller = Provider.of<StepperController>(context, listen: false);
    
    // Validar estado antes de tentar completar
    print('📋 [$timestamp] [REGISTRATION] Validando dados antes da finalização:');
    print('  - userType: ${controller.userType}');
    print('  - fullName: ${controller.fullName}');
    print('  - email: ${controller.email}');
    print('  - phone: ${controller.phone}');
    
    try {
      print('🔄 [$timestamp] [REGISTRATION] Chamando controller.completeRegistration()...');
      final ok = await controller.completeRegistration();
      
      print('📊 [$timestamp] [REGISTRATION] Resultado do completeRegistration: $ok');
      
      if (!mounted) {
        print('⚠️ [$timestamp] [REGISTRATION] Widget não está mais montado, cancelando navegação');
        return;
      }
      
      if (ok) {
        print('✅ [$timestamp] [REGISTRATION] Cadastro finalizado com sucesso!');
        // Redirecionar baseado no tipo de usuário
        if (controller.userType == 'driver') {
          print('🚗 [$timestamp] [REGISTRATION] Navegando para /driver_home (motorista)');
          Navigator.of(context).pushReplacementNamed('/driver_home');
        } else {
          print('🚶 [$timestamp] [REGISTRATION] Navegando para /home (passageiro)');
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        print('❌ [$timestamp] [REGISTRATION] Falha na finalização do cadastro (retorno false)');
        throw Exception('Falha na finalização do cadastro');
      }
    } catch (e) {
      print('❌ [$timestamp] [REGISTRATION] Erro ao finalizar cadastro: $e');
      print('❌ [$timestamp] [REGISTRATION] Tipo do erro: ${e.runtimeType}');
      print('❌ [$timestamp] [REGISTRATION] Stack trace: ${StackTrace.current}');
      
      if (!mounted) {
        print('⚠️ [$timestamp] [REGISTRATION] Widget não está mais montado, não atualizando estado');
        return;
      }
      
      // Mapear exceção para melhor feedback
      UserRegistrationException mappedException;
      if (e is UserRegistrationException) {
        mappedException = e;
      } else {
        mappedException = UserRegistrationExceptionMapper.mapException(e.toString());
      }
      
      setState(() {
        _isCompletingRegistration = false;
        _registrationError = _getErrorMessage(mappedException);
        _registrationException = mappedException;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep == 0) {
              Navigator.of(context).pop();
            } else {
              _previousStep();
            }
          },
        ),
        title: const Text('Complete seu cadastro'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  PhoneStep(
                    onNext: _nextStep,
                  ),
                  PhotoStep(
                    onNext: _nextStep,
                  ),
                  PlacesStep(
                    onNext: _nextStep,
                    onSave: _saveFavoriteLocations,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) => GestureDetector(
            onTap: () => _jumpToStep(index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentStep == index ? 32 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentStep >= index 
                    ? colorScheme.primary 
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),),
      ),
    );
  }

  Widget _buildDriverCompletionScreen() {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_registrationError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getErrorIcon(),
                size: 64,
                color: _getErrorColor(colorScheme),
              ),
              const SizedBox(height: 24),
              Text(
                _getErrorTitle(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _registrationError!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_shouldShowBackButton())
                    OutlinedButton(
                      onPressed: () {
                        Future.microtask(() {
                          if (mounted) {
                            setState(() {
                              _registrationError = null;
                              _registrationException = null;
                            });
                            _previousStep();
                          }
                        });
                      },
                      child: const Text('Voltar'),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      Future.microtask(() {
                        if (mounted) {
                          setState(() {
                            _registrationError = null;
                            _registrationException = null;
                          });
                          _completeRegistration();
                        }
                      });
                    },
                    child: Text(_getRetryButtonText()),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Finalizando seu cadastro...',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Aguarde enquanto configuramos sua conta de motorista',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getErrorMessage(UserRegistrationException exception) {
    switch (exception.type) {
      case UserRegistrationExceptionType.networkError:
        return 'Verifique sua conexão com a internet e tente novamente.';
      case UserRegistrationExceptionType.serverError:
        return 'Nossos servidores estão temporariamente indisponíveis. Tente novamente em alguns minutos.';
      case UserRegistrationExceptionType.validationError:
        return 'Alguns dados precisam ser corrigidos. Verifique as informações e tente novamente.';
      case UserRegistrationExceptionType.authenticationError:
        return 'Erro de autenticação. Faça login novamente e tente completar o cadastro.';
      case UserRegistrationExceptionType.permissionError:
        return 'Você não tem permissão para realizar esta ação. Entre em contato com o suporte.';
      case UserRegistrationExceptionType.rateLimitError:
        return 'Muitas tentativas. Aguarde alguns minutos antes de tentar novamente.';
      default:
        return exception.message ?? 'Ocorreu um erro inesperado. Tente novamente ou entre em contato com o suporte.';
    }
  }

  IconData _getErrorIcon() {
    if (_registrationException == null) return Icons.error_outline;
    
    switch (_registrationException!.type) {
      case UserRegistrationExceptionType.networkError:
        return Icons.wifi_off;
      case UserRegistrationExceptionType.serverError:
        return Icons.cloud_off;
      case UserRegistrationExceptionType.validationError:
        return Icons.warning;
      case UserRegistrationExceptionType.authenticationError:
        return Icons.lock_outline;
      case UserRegistrationExceptionType.permissionError:
        return Icons.block;
      case UserRegistrationExceptionType.rateLimitError:
        return Icons.timer_off;
      default:
        return Icons.error_outline;
    }
  }

  Color _getErrorColor(ColorScheme colorScheme) {
    if (_registrationException == null) return colorScheme.error;
    
    switch (_registrationException!.type) {
      case UserRegistrationExceptionType.networkError:
      case UserRegistrationExceptionType.serverError:
        return colorScheme.primary;
      case UserRegistrationExceptionType.validationError:
        return Colors.orange;
      case UserRegistrationExceptionType.authenticationError:
      case UserRegistrationExceptionType.permissionError:
        return colorScheme.error;
      case UserRegistrationExceptionType.rateLimitError:
        return Colors.blue;
      default:
        return colorScheme.error;
    }
  }

  String _getErrorTitle() {
    if (_registrationException == null) return 'Erro ao finalizar cadastro';
    
    switch (_registrationException!.type) {
      case UserRegistrationExceptionType.networkError:
        return 'Problema de conexão';
      case UserRegistrationExceptionType.serverError:
        return 'Serviço temporariamente indisponível';
      case UserRegistrationExceptionType.validationError:
        return 'Dados inválidos';
      case UserRegistrationExceptionType.authenticationError:
        return 'Erro de autenticação';
      case UserRegistrationExceptionType.permissionError:
        return 'Acesso negado';
      case UserRegistrationExceptionType.rateLimitError:
        return 'Muitas tentativas';
      default:
        return 'Erro ao finalizar cadastro';
    }
  }

  bool _shouldShowBackButton() {
    if (_registrationException == null) return true;
    
    // Não mostrar botão voltar para erros que não podem ser resolvidos voltando
    switch (_registrationException!.type) {
      case UserRegistrationExceptionType.authenticationError:
      case UserRegistrationExceptionType.permissionError:
        return false;
      default:
        return true;
    }
  }

  String _getRetryButtonText() {
    if (_registrationException == null) return 'Tentar novamente';
    
    switch (_registrationException!.type) {
      case UserRegistrationExceptionType.authenticationError:
        return 'Fazer login novamente';
      case UserRegistrationExceptionType.rateLimitError:
        return 'Aguardar e tentar';
      default:
        return 'Tentar novamente';
    }
  }
}