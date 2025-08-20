import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/stepper_controller.dart';
import '../../theme/app_theme.dart';
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
    final controller = Provider.of<StepperController>(context, listen: false);
    controller.loadUserData();
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

  void _completeRegistration() {
    final controller = Provider.of<StepperController>(context, listen: false);
    controller.completeRegistration();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.uberBlackTheme,
      child: Scaffold(
        backgroundColor: AppTheme.uberBlack,
        appBar: AppBar(
          backgroundColor: AppTheme.uberBlack,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
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
              color: Colors.white,
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
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return GestureDetector(
            onTap: () => _jumpToStep(index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentStep == index ? 32 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentStep >= index 
                    ? AppTheme.uberWhite 
                    : AppTheme.uberMediumGray.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }
}