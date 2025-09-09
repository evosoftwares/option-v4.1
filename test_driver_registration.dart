import 'package:flutter/material.dart';

// Import the driver stepper controller
import 'lib/controllers/driver_stepper_controller.dart';

void main() {
  runApp(const DriverRegistrationTestApp());
}

class DriverRegistrationTestApp extends StatelessWidget {
  const DriverRegistrationTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Driver Registration Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const DriverRegistrationTestScreen(),
    );
  }
}

class DriverRegistrationTestScreen extends StatefulWidget {
  const DriverRegistrationTestScreen({super.key});

  @override
  State<DriverRegistrationTestScreen> createState() =>
      _DriverRegistrationTestScreenState();
}

class _DriverRegistrationTestScreenState
    extends State<DriverRegistrationTestScreen> {
  late DriverStepperController controller;

  @override
  void initState() {
    super.initState();
    controller = DriverStepperController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // Simulate filling vehicle information
  void simulateVehicleDataInput() {
    controller.setVehicleBrand('Toyota');
    controller.setVehicleModel('Corolla');
    controller.setVehicleYear('2020');
    controller.setVehiclePlate('ABC1234');
    controller.setVehicleColor('Branco');
    controller.setVehicleCategory('Comum');
    
    print('✅ Vehicle data filled successfully');
  }

  // Simulate pressing the "IR" (Finish Registration) button
  Future<void> simulatePressingIrButton() async {
    print('🏁 Simulating pressing the IR (Finish Registration) button...');
    
    // Validate vehicle fields first
    controller.validateVehicleFields();
    
    if (controller.canProceedFromVehicle) {
      print('✅ Vehicle data is valid');
      
      // Try to complete driver registration
      print('🔄 Attempting to complete driver registration...');
      final success = await controller.completeDriverRegistration();
      
      if (success) {
        print('🎉 Driver registration completed successfully!');
        print('🚗 Driver can now proceed to the main app');
      } else {
        print('❌ Driver registration failed');
        if (controller.errorMessage != null) {
          print('📝 Error: ${controller.errorMessage}');
        }
      }
    } else {
      print('❌ Vehicle data is not valid');
      print('📝 Brand error: ${controller.brandErrorMessage}');
      print('📝 Model error: ${controller.modelErrorMessage}');
      print('📝 Year error: ${controller.yearErrorMessage}');
      print('📝 Plate error: ${controller.plateErrorMessage}');
      print('📝 Color error: ${controller.colorErrorMessage}');
      print('📝 Category error: ${controller.categoryErrorMessage}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Registration Test'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Driver Registration Flow Simulation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'This simulation will demonstrate the driver registration flow '
              'and execute until the point where the "IR" (Finish Registration) button is pressed.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                print('🚗 Starting driver registration flow...');
                simulateVehicleDataInput();
              },
              child: const Text('1. Fill Vehicle Information'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await simulatePressingIrButton();
              },
              child: const Text('2. Press IR (Finish Registration) Button'),
            ),
            const SizedBox(height: 30),
            const Text(
              'Console Output:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: const SingleChildScrollView(
                  child: Text(
                    'Run in terminal to see console output:\n\nflutter run test_driver_registration.dart',
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}