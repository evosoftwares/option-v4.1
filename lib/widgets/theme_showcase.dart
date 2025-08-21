import 'package:flutter/material.dart';

class ThemeShowcase extends StatelessWidget {
  const ThemeShowcase({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demonstração do Tema',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),

          // Botões
          Text(
            'Botões',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {},
                child: const Text('Elevated Button'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {},
                child: const Text('Outlined Button'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {},
                child: const Text('Text Button'),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Campos de entrada
          Text(
            'Campos de Entrada',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Endereço de partida',
              hintText: 'Digite seu endereço',
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Destino',
              hintText: 'Para onde você vai?',
              prefixIcon: Icon(Icons.flag),
            ),
          ),
          const SizedBox(height: 32),

          // Cards
          Text(
            'Cards',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UberX',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chega em 3 minutos',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'R\$ 15-20',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Chips
          Text(
            'Chips',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              Chip(
                label: const Text('Econômico'),
                avatar: const Icon(Icons.directions_car, size: 16),
              ),
              Chip(
                label: const Text('Conforto'),
                avatar: const Icon(Icons.airline_seat_recline_normal, size: 16),
              ),
              Chip(
                label: const Text('Premium'),
                avatar: const Icon(Icons.star, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Navigation Bar
          Text(
            'Navigation Bar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          NavigationBar(
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
        ],
      ),
    );
}