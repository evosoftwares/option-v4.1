import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Mock controller to simulate the driver stepper controller functionality
class MockDriverStepperController extends ChangeNotifier {
  final PageController pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Vehicle data
  String _vehicleBrand = '';
  String _vehicleModel = '';
  String _vehicleYear = '';
  String _vehiclePlate = '';
  String _vehicleColor = '';
  String _vehicleCategory = '';
  
  // Text controllers
  final TextEditingController brandController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController plateController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  
  // Getters
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  String get vehicleBrand => _vehicleBrand;
  String get vehicleModel => _vehicleModel;
  String get vehicleYear => _vehicleYear;
  String get vehiclePlate => _vehiclePlate;
  String get vehicleColor => _vehicleColor;
  String get vehicleCategory => _vehicleCategory;
  
  // Validation getters
  bool get canProceedFromVehicle => 
      _vehicleBrand.isNotEmpty && 
      _vehicleModel.isNotEmpty && 
      _vehicleYear.isNotEmpty && 
      _vehiclePlate.isNotEmpty && 
      _vehicleColor.isNotEmpty &&
      _vehicleCategory.isNotEmpty;
      
  bool get canCompleteRegistration => canProceedFromVehicle;
  
  // Navigation methods
  void nextStep() {
    if (_currentStep < 2) {
      _currentStep++;
      pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }
  
  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }
  
  // Vehicle data setters
  void setVehicleBrand(String brand) {
    _vehicleBrand = brand;
    brandController.text = brand;
    notifyListeners();
  }
  
  void setVehicleModel(String model) {
    _vehicleModel = model;
    modelController.text = model;
    notifyListeners();
  }
  
  void setVehicleYear(String year) {
    _vehicleYear = year;
    yearController.text = year;
    notifyListeners();
  }
  
  void setVehiclePlate(String plate) {
    _vehiclePlate = plate.toUpperCase();
    plateController.text = _vehiclePlate;
    notifyListeners();
  }
  
  void setVehicleColor(String color) {
    _vehicleColor = color;
    colorController.text = color;
    notifyListeners();
  }
  
  void setVehicleCategory(String category) {
    _vehicleCategory = category;
    notifyListeners();
  }
  
  // Simulate completing registration
  Future<bool> completeDriverRegistration() async {
    _isLoading = true;
    notifyListeners();
    
    // Simulate network request
    await Future.delayed(const Duration(seconds: 2));
    
    _isLoading = false;
    notifyListeners();
    
    // Always succeed in demo
    return true;
  }
  
  @override
  void dispose() {
    pageController.dispose();
    brandController.dispose();
    modelController.dispose();
    yearController.dispose();
    plateController.dispose();
    colorController.dispose();
    super.dispose();
  }
}

// Demo screens
class CodeOfConductStep extends StatelessWidget {
  const CodeOfConductStep({super.key});

  @override
  Widget build(BuildContext context) {
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
}

class VehicleRegistrationStep extends StatelessWidget {
  const VehicleRegistrationStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MockDriverStepperController>(
      builder: (context, controller, child) {
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
              TextField(
                controller: controller.brandController,
                decoration: const InputDecoration(
                  labelText: 'Marca do Veículo',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => controller.setVehicleBrand(value),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.modelController,
                decoration: const InputDecoration(
                  labelText: 'Modelo do Veículo',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => controller.setVehicleModel(value),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.yearController,
                      decoration: const InputDecoration(
                        labelText: 'Ano',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => controller.setVehicleYear(value),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: controller.colorController,
                      decoration: const InputDecoration(
                        labelText: 'Cor',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => controller.setVehicleColor(value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.plateController,
                decoration: const InputDecoration(
                  labelText: 'Placa do Veículo',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => controller.setVehiclePlate(value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: controller.vehicleCategory.isEmpty ? null : controller.vehicleCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoria do Veículo',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Comum', child: Text('Comum')),
                  DropdownMenuItem(value: 'Acessível', child: Text('Acessível')),
                  DropdownMenuItem(value: 'Luxo', child: Text('Luxo')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    controller.setVehicleCategory(value);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class CompletionStep extends StatelessWidget {
  const CompletionStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MockDriverStepperController>(
      builder: (context, controller, child) {
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dados do Veículo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
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
      },
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

// Main stepper widget
class DriverStepperDemo extends StatefulWidget {
  const DriverStepperDemo({super.key});

  @override
  State<DriverStepperDemo> createState() => _DriverStepperDemoState();
}

class _DriverStepperDemoState extends State<DriverStepperDemo> {
  late MockDriverStepperController controller;

  @override
  void initState() {
    super.initState();
    controller = MockDriverStepperController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _completeRegistration() async {
    final success = await controller.completeDriverRegistration();
    if (success && mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro finalizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Wait a bit and then navigate
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MockDriverStepperController>.value(
      value: controller,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cadastro de Motorista'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: Consumer<MockDriverStepperController>(
          builder: (context, controller, child) {
            return Column(
              children: [
                // Progress indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Etapa ${controller.currentStep + 1} de 3'),
                          Text('${((controller.currentStep + 1) / 3 * 100).round()}%'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (controller.currentStep + 1) / 3,
                      ),
                    ],
                  ),
                ),
                // Stepper content
                Expanded(
                  child: PageView(
                    controller: controller.pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      CodeOfConductStep(),
                      VehicleRegistrationStep(),
                      CompletionStep(),
                    ],
                  ),
                ),
                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      if (controller.currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: controller.previousStep,
                            child: const Text('Voltar'),
                          ),
                        ),
                      if (controller.currentStep > 0)
                        const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: controller.currentStep < 2
                              ? controller.nextStep
                              : (controller.canCompleteRegistration && !controller.isLoading
                                  ? _completeRegistration
                                  : null),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: controller.currentStep == 2
                                ? Colors.green
                                : Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: controller.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (controller.currentStep == 2)
                                      const Icon(Icons.check, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      controller.currentStep < 2
                                          ? 'Continuar'
                                          : 'Finalizar Cadastro (IR)', // This is the "IR" button
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
            );
          },
        ),
      ),
    );
  }
}