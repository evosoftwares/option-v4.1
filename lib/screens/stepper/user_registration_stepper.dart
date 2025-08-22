import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/stepper_controller.dart';
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

  Future<void> _completeRegistration() async {
    print('🏁 Finalizando cadastro...');
    final controller = Provider.of<StepperController>(context, listen: false);
    
    // Validar estado antes de tentar completar
    print('📋 Validando dados antes da finalização:');
    print('  - userType: ${controller.userType}');
    print('  - fullName: ${controller.fullName}');
    print('  - email: ${controller.email}');
    print('  - phone: ${controller.phone}');
    
    try {
      final ok = await controller.completeRegistration();
      if (!mounted) return;
      if (ok) {
        print('✅ Cadastro finalizado com sucesso! Navegando para /home');
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        print('❌ Falha na finalização do cadastro');
        throw Exception('Falha na finalização do cadastro');
      }
    } catch (e) {
      print('❌ Erro ao finalizar cadastro: $e');
      if (!mounted) return;
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao finalizar cadastro: ${e.toString()}'),
          backgroundColor: colorScheme.error,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () {
            if (_currentStep == 0) {
              Navigator.of(context).pop();
            } else {
              _previousStep();
            }
          },
        ),
        title: Text(
          'Complete seu cadastro',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
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
                    onSave: (photoUrl) {
                      Provider.of<StepperController>(context, listen: false)
                          .updatePhotoUrl(photoUrl);
                    },
                  ),
                  PlacesStep(
                    onNext: _completeRegistration,
                    onSave: (locations) {
                      Provider.of<StepperController>(context, listen: false)
                          .updateLocations(locations);
                    },
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
                    : colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )),
      ),
    );
  }
}