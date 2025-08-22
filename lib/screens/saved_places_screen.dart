import 'package:flutter/material.dart';
import '../widgets/logo_branding.dart';
import 'stepper/step3_locations_screen.dart';

class SavedPlacesScreen extends StatelessWidget {
  const SavedPlacesScreen({super.key});

  static const routeName = '/saved_places';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const StandardAppBar(
        title: 'Locais Favoritos',
        showMenuIcon: false,
        centerTitle: true,
      ),
      body: const SafeArea(
        child: Step3LocationsScreen(),
      ),
    );
  }
}