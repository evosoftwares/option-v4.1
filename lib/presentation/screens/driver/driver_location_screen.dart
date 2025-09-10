import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/driver/driver_location_controller.dart';
import '../../widgets/driver/location_status_widget.dart';

/// Tela para gerenciar a localização do motorista
class DriverLocationScreen extends StatefulWidget {
  const DriverLocationScreen({super.key});

  @override
  State<DriverLocationScreen> createState() => _DriverLocationScreenState();
}

class _DriverLocationScreenState extends State<DriverLocationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Localização do Motorista'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Widget de status da localização
            const LocationStatusWidget(),
            
            // Informações sobre o serviço
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Como funciona',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• A localização é atualizada automaticamente a cada 5 minutos\n'
                      '• Funciona mesmo quando o app está em segundo plano\n'
                      '• Necessário para receber chamadas de corridas\n'
                      '• Consome pouca bateria com otimizações inteligentes',
                      style: TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            
            // Configurações de privacidade
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Privacidade e Segurança',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Sua localização é compartilhada apenas quando você está online\n'
                      '• Os dados são criptografados e seguros\n'
                      '• Você pode parar o tracking a qualquer momento\n'
                      '• Localização é usada apenas para conectar com passageiros',
                      style: TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Exemplo de como usar o DriverLocationController em um app
class DriverLocationApp extends StatelessWidget {
  const DriverLocationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Driver Location Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ChangeNotifierProvider(
        create: (context) => DriverLocationController(),
        child: const DriverLocationScreen(),
      ),
    );
  }
}