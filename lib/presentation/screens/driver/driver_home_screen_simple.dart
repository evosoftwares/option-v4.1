import 'package:flutter/material.dart';

/// Versão simplificada temporária do DriverHomeScreen para teste
class DriverHomeScreenSimple extends StatelessWidget {
  const DriverHomeScreenSimple({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Motorista - Tela Principal'),
        backgroundColor: colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Navigator.pushNamed(context, '/driver_menu'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car,
              size: 100,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Tela do Motorista',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Esta é uma versão temporária simplificada',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Função de motorista em desenvolvimento'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Testar Funcionalidade'),
            ),
          ],
        ),
      ),
    );
  }
}