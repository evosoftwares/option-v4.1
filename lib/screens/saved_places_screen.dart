import 'package:flutter/material.dart';
import 'stepper/step3_locations_screen.dart';

class SavedPlacesScreen extends StatelessWidget {
  const SavedPlacesScreen({super.key});

  static const routeName = '/saved_places';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Locais salvos'),
        backgroundColor: colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: const SafeArea(
        child: Step3LocationsScreen(),
      ),
    );
  }
}