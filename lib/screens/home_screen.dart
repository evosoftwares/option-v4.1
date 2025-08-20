import 'package:flutter/material.dart';
import 'package:uber_clone/widgets/theme_showcase.dart';
import 'package:uber_clone/widgets/logo_branding.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LogoAppBar(
        actions: const [
          // Example action
        ],
      ),
      body: const ThemeShowcase(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.directions_car),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car),
            label: 'Corridas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        selectedIndex: 0,
      ),
    );
  }
}