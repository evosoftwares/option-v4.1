// Driver Registration Stepper - UI Demo
// This file demonstrates the UI structure of the driver registration stepper
// without requiring any backend services or Firebase configuration

import 'package:flutter/material.dart';

void main() {
  runApp(const DriverStepperUIDemo());
}

class DriverStepperUIDemo extends StatelessWidget {
  const DriverStepperUIDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Driver Registration Stepper UI Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const StepperDemoScreen(),
    );
  }
}

class StepperDemoScreen extends StatefulWidget {
  const StepperDemoScreen({super.key});

  @override
  State<StepperDemoScreen> createState() => _StepperDemoScreenState();
}

class _StepperDemoScreenState extends State<StepperDemoScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Motorista'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Etapa ${_currentStep + 1} de 3'),
                    Text('${((_currentStep + 1) / 3 * 100).round()}%'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_currentStep + 1) / 3,
                ),
              ],
            ),
          ),
          // Stepper content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildCodeOfConductStep(),
                _buildVehicleRegistrationStep(),
                _buildCompletionStep(),
              ],
            ),
          ),
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: const Text('Voltar'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed:
                        _currentStep < 2 ? _nextStep : _completeRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _currentStep == 2 ? Colors.green : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_currentStep == 2)
                          const Icon(Icons.check, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _currentStep < 2
                              ? 'Continuar'
                              : 'Finalizar Cadastro (IR)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeOfConductStep() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.policy,
            size: 64,
            color: Colors.blue,
          ),
          SizedBox(height: 20),
          Text(
            'Código de Conduta',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Como motorista da plataforma, você concorda em:\n\n'
            '• Manter um comportamento profissional e respeitoso\n'
            '• Dirigir com segurança e responsabilidade\n'
            '• Manter o veículo limpo e em boas condições\n'
            '• Respeitar as regras de trânsito\n'
            '• Proteger os dados dos passageiros\n\n'
            'Ao continuar, você declara que leu e concorda com todos os termos.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleRegistrationStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dados do Veículo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Informe os dados do seu veículo',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Marca do Veículo',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Modelo do Veículo',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: const TextField(
                  decoration: InputDecoration(
                    labelText: 'Ano',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: const TextField(
                  decoration: InputDecoration(
                    labelText: 'Cor',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Placa do Veículo',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Categoria do Veículo',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Comum', child: Text('Comum')),
              DropdownMenuItem(value: 'Acessível', child: Text('Acessível')),
              DropdownMenuItem(value: 'Luxo', child: Text('Luxo')),
            ],
            onChanged: null,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Finalizar Cadastro',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Revise suas informações antes de finalizar',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Código de Conduta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.check, color: Colors.green),
                      SizedBox(width: 10),
                      Text('Você concordou com o código de conduta'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dados do Veículo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  _VehicleInfoRow(label: 'Marca', value: 'Toyota'),
                  _VehicleInfoRow(label: 'Modelo', value: 'Corolla'),
                  _VehicleInfoRow(label: 'Ano', value: '2020'),
                  _VehicleInfoRow(label: 'Cor', value: 'Branco'),
                  _VehicleInfoRow(label: 'Placa', value: 'ABC1234'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Próximos Passos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '• Seu veículo será registrado em nosso sistema\n'
                    '• Você receberá uma notificação quando o cadastro for concluído\n'
                    '• O processo pode levar até 24 horas\n'
                    '• Após aprovação, você poderá começar a aceitar corridas',
                    style: TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _completeRegistration() {
    // Show success dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cadastro Finalizado!'),
        content: const Text(
          '🎉 Parabéns! Seu cadastro como motorista foi finalizado com sucesso.\n\n'
          'Você será redirecionado para a tela principal do motorista.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // In a real app, this would navigate to the driver home screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cadastro finalizado com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _VehicleInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _VehicleInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}
