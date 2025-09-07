#!/usr/bin/env dart
// Driver Registration Flow Simulation
// This script simulates the driver registration flow until the \"IR\" button is pressed

import 'dart:io';

class DriverStepperController {
  // Vehicle data
  String _vehicleBrand = '';
  String _vehicleModel = '';
  String _vehicleYear = '';
  String _vehiclePlate = '';
  String _vehicleColor = '';
  String _vehicleCategory = '';
  
  // Validation states
  bool _brandFieldTouched = false;
  bool _modelFieldTouched = false;
  bool _yearFieldTouched = false;
  bool _plateFieldTouched = false;
  bool _colorFieldTouched = false;
  bool _categoryFieldTouched = false;
  
  // Error messages
  String? _errorMessage;
  
  // Getters
  String get vehicleBrand => _vehicleBrand;
  String get vehicleModel => _vehicleModel;
  String get vehicleYear => _vehicleYear;
  String get vehiclePlate => _vehiclePlate;
  String get vehicleColor => _vehicleColor;
  String get vehicleCategory => _vehicleCategory;
  String? get errorMessage => _errorMessage;
  
  // Validation getters
  bool get brandHasError => _brandFieldTouched && _vehicleBrand.isEmpty;
  bool get modelHasError => _modelFieldTouched && _vehicleModel.isEmpty;
  bool get yearHasError => _yearFieldTouched && _vehicleYear.isEmpty;
  bool get plateHasError => _plateFieldTouched && _vehiclePlate.isEmpty;
  bool get colorHasError => _colorFieldTouched && _vehicleColor.isEmpty;
  bool get categoryHasError => _categoryFieldTouched && _vehicleCategory.isEmpty;
  
  String? get brandErrorMessage => brandHasError ? 'Selecione uma marca' : null;
  String? get modelErrorMessage => modelHasError ? 'Selecione um modelo' : null;
  String? get yearErrorMessage => yearHasError ? 'Informe o ano' : null;
  String? get plateErrorMessage => plateHasError ? 'Informe a placa' : null;
  String? get colorErrorMessage => colorHasError ? 'Informe a cor' : null;
  String? get categoryErrorMessage => categoryHasError ? 'Selecione uma categoria' : null;
  
  bool get canProceedFromVehicle => 
      _vehicleBrand.isNotEmpty && 
      _vehicleModel.isNotEmpty && 
      _vehicleYear.isNotEmpty && 
      _vehiclePlate.isNotEmpty && 
      _vehicleColor.isNotEmpty &&
      _vehicleCategory.isNotEmpty;
      
  bool get canCompleteRegistration => canProceedFromVehicle;
  
  // Setters for vehicle data
  void setVehicleBrand(String brand) {
    _vehicleBrand = brand;
    _brandFieldTouched = true;
  }
  
  void setVehicleModel(String model) {
    _vehicleModel = model;
    _modelFieldTouched = true;
  }
  
  void setVehicleYear(String year) {
    _vehicleYear = year;
    _yearFieldTouched = true;
  }
  
  void setVehiclePlate(String plate) {
    _vehiclePlate = plate.toUpperCase();
    _plateFieldTouched = true;
  }
  
  void setVehicleColor(String color) {
    _vehicleColor = color;
    _colorFieldTouched = true;
  }
  
  void setVehicleCategory(String category) {
    _vehicleCategory = category;
    _categoryFieldTouched = true;
  }
  
  // Method to trigger validation check
  void validateVehicleFields() {
    _brandFieldTouched = true;
    _modelFieldTouched = true;
    _yearFieldTouched = true;
    _plateFieldTouched = true;
    _colorFieldTouched = true;
    _categoryFieldTouched = true;
  }
  
  // Clear error message
  void clearError() {
    _errorMessage = null;
  }
  
  // Simulate completing driver registration
  Future<bool> completeDriverRegistration() async {
    print('🔄 Completing driver registration...');
    
    // Clear previous errors
    clearError();
    
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 1000));
    
    try {
      // Validate required fields
      validateVehicleFields();
      
      if (!canProceedFromVehicle) {
        _errorMessage = 'Por favor, preencha todos os campos obrigatórios';
        print('❌ Registration failed: Missing required fields');
        return false;
      }
      
      // Simulate validation
      if (_vehicleYear.length != 4 || int.tryParse(_vehicleYear) == null) {
        _errorMessage = 'Ano inválido. Informe um ano com 4 dígitos.';
        print('❌ Registration failed: Invalid year');
        return false;
      }
      
      if (_vehiclePlate.length < 7) {
        _errorMessage = 'Placa inválida. Informe uma placa válida.';
        print('❌ Registration failed: Invalid plate');
        return false;
      }
      
      // Simulate successful registration
      print('✅ Driver registration completed successfully!');
      print('📋 Registration details:');
      print('   Brand: $_vehicleBrand');
      print('   Model: $_vehicleModel');
      print('   Year: $_vehicleYear');
      print('   Plate: $_vehiclePlate');
      print('   Color: $_vehicleColor');
      print('   Category: $_vehicleCategory');
      
      // Simulate saving to database
      await Future.delayed(Duration(milliseconds: 500));
      print('💾 Driver data saved to database');
      
      // Simulate document upload (optional in this new flow)
      print('📄 Document upload is optional in this flow');
      
      return true;
    } catch (e) {
      _errorMessage = 'Erro inesperado: $e';
      print('❌ Registration failed with error: $e');
      return false;
    }
  }
}

void main() async {
  print('🚗 Driver Registration Flow Simulation');
  print('=====================================');
  
  // Create controller
  final controller = DriverStepperController();
  
  print('\n📝 Step 1: Filling vehicle information...');
  
  // Simulate filling vehicle data
  controller.setVehicleBrand('Toyota');
  controller.setVehicleModel('Corolla');
  controller.setVehicleYear('2020');
  controller.setVehiclePlate('ABC1234');
  controller.setVehicleColor('Branco');
  controller.setVehicleCategory('Comum');
  
  print('✅ Vehicle information filled');
  print('📋 Data:');
  print('   Brand: ${controller.vehicleBrand}');
  print('   Model: ${controller.vehicleModel}');
  print('   Year: ${controller.vehicleYear}');
  print('   Plate: ${controller.vehiclePlate}');
  print('   Color: ${controller.vehicleColor}');
  print('   Category: ${controller.vehicleCategory}');
  
  print('\n🏁 Step 2: Pressing IR (Finish Registration) button...');
  
  // Validate fields
  controller.validateVehicleFields();
  
  if (controller.canProceedFromVehicle) {
    print('✅ All required fields are filled');
    
    // Attempt to complete registration
    final success = await controller.completeDriverRegistration();
    
    if (success) {
      print('\n🎉 SUCCESS: Driver registration completed!');
      print('📲 Driver can now proceed to the main app');
    } else {
      print('\n❌ FAILURE: Driver registration failed');
      if (controller.errorMessage != null) {
        print('📝 Error: ${controller.errorMessage}');
      }
      
      // Show field-specific errors
      if (controller.brandErrorMessage != null) {
        print('📝 Brand error: ${controller.brandErrorMessage}');
      }
      if (controller.modelErrorMessage != null) {
        print('📝 Model error: ${controller.modelErrorMessage}');
      }
      if (controller.yearErrorMessage != null) {
        print('📝 Year error: ${controller.yearErrorMessage}');
      }
      if (controller.plateErrorMessage != null) {
        print('📝 Plate error: ${controller.plateErrorMessage}');
      }
      if (controller.colorErrorMessage != null) {
        print('📝 Color error: ${controller.colorErrorMessage}');
      }
      if (controller.categoryErrorMessage != null) {
        print('📝 Category error: ${controller.categoryErrorMessage}');
      }
    }
  } else {
    print('❌ Cannot proceed - missing required fields');
    print('📝 Brand error: ${controller.brandErrorMessage}');
    print('📝 Model error: ${controller.modelErrorMessage}');
    print('📝 Year error: ${controller.yearErrorMessage}');
    print('📝 Plate error: ${controller.plateErrorMessage}');
    print('📝 Color error: ${controller.colorErrorMessage}');
    print('📝 Category error: ${controller.categoryErrorMessage}');
  }
  
  print('\n🏁 Driver registration flow simulation completed');
}