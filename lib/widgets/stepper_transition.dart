import 'package:flutter/material.dart';

class StepperTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const StepperTransition({
    super.key,
    required this.child,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

class StepperPageRoute extends PageRouteBuilder {
  final Widget child;

  StepperPageRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return StepperTransition(
              animation: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}