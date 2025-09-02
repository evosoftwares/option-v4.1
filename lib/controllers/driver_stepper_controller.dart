import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/driver_service.dart';
import '../services/user_service.dart';
import '../utils/supabase_helper.dart';

class DriverStepperController extends ChangeNotifier {
  final PageController pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Documentos
  File? _cnhPhoto;
  File? _crlvPhoto;
  
  // Dados do veículo
  String _vehicleBrand = '';
  String _vehicleModel = '';
  String _vehicleYear = '';
  String _vehiclePlate = '';
  String _vehicleColor = '';
  
  // Text controllers for vehicle form
  final TextEditingController brandController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController plateController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  
  // Getters
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  File? get cnhPhoto => _cnhPhoto;
  File? get crlvPhoto => _crlvPhoto;
  String get vehicleBrand => _vehicleBrand;
  String get vehicleModel => _vehicleModel;
  String get vehicleYear => _vehicleYear;
  String get vehiclePlate => _vehiclePlate;
  String get vehicleColor => _vehicleColor;
// Validation getters
  bool get canProceedFromDocuments => cnhPhoto != null && crlvPhoto != null;
  
  bool get canProceedFromVehicle => 
      _vehicleBrand.isNotEmpty && 
      _vehicleModel.isNotEmpty && 
      _vehicleYear.isNotEmpty && 
      _vehiclePlate.isNotEmpty && 
      _vehicleColor.isNotEmpty;
      
  bool get canCompleteRegistration => 
      canProceedFromDocuments && canProceedFromVehicle;
      
  // Setters para dados do veículo
  void setVehicleBrand(String brand) {
    _vehicleBrand = brand;
    notifyListeners();
  }
  
  void setVehicleModel(String model) {
    _vehicleModel = model;
    notifyListeners();
  }
  
  void setVehicleYear(String year) {
    _vehicleYear = year;
    notifyListeners();
  }
  
  void setVehiclePlate(String plate) {
    _vehiclePlate = plate.toUpperCase();
    notifyListeners();
  }
  
  void setVehicleColor(String color) {
    _vehicleColor = color;
    notifyListeners();
  }
  
  // Navegação entre etapas
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
  
  void goToStep(int step) {
    if (step >= 0 && step <= 2) {
      _currentStep = step;
      pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }
  
  // Captura de fotos
  Future<void> takeCnhPhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        _cnhPhoto = File(image.path);
        notifyListeners();
      }
    } catch (e) {
      _setError('Erro ao capturar foto da CNH: $e');
    }
  }
  
  Future<void> takeCrlvPhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        _crlvPhoto = File(image.path);
        notifyListeners();
      }
    } catch (e) {
      _setError('Erro ao capturar foto do CRLV: $e');
    }
  }
  
  // Seleção de fotos da galeria
  Future<void> selectCnhFromGallery() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        _cnhPhoto = File(image.path);
        notifyListeners();
      }
    } catch (e) {
      _setError('Erro ao selecionar foto da CNH: $e');
    }
  }
  
  Future<void> selectCrlvFromGallery() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        _crlvPhoto = File(image.path);
        notifyListeners();
      }
    } catch (e) {
      _setError('Erro ao selecionar foto do CRLV: $e');
    }
  }
  
  // Upload de documentos
  Future<String?> _uploadDocument(File file, String fileName) async {
    try {
      final user = SupabaseHelper.client?.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');
      
      final path = 'driver_documents/${user.id}/$fileName';
      
      await SupabaseHelper.client!.storage
          .from('driver-documents')
          .upload(path, file);
      
      final url = SupabaseHelper.client!.storage
          .from('driver-documents')
          .getPublicUrl(path);
      
      return url;
    } catch (e) {
      print('Erro ao fazer upload do documento: $e');
      return null;
    }
  }
  
  // Finalizar cadastro
  Future<bool> completeDriverRegistration() async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = SupabaseHelper.client?.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }
      
      // Upload dos documentos
      String? cnhUrl;
      String? crlvUrl;
      
      if (_cnhPhoto != null) {
        cnhUrl = await _uploadDocument(_cnhPhoto!, 'cnh_${DateTime.now().millisecondsSinceEpoch}.jpg');
        if (cnhUrl == null) {
          throw Exception('Falha no upload da CNH');
        }
      }
      
      if (_crlvPhoto != null) {
        crlvUrl = await _uploadDocument(_crlvPhoto!, 'crlv_${DateTime.now().millisecondsSinceEpoch}.jpg');
        if (crlvUrl == null) {
          throw Exception('Falha no upload do CRLV');
        }
      }
      
      // Buscar o driver ID primeiro
      final driverResponse = await SupabaseHelper.client!
          .from('drivers')
          .select('id')
          .eq('user_id', user.id)
          .single();
      
      final driverId = driverResponse['id'] as String;
      
      // Atualizar dados do motorista
      final driverService = DriverService(SupabaseHelper.client!);
      await driverService.updateDriver(
        driverId,
        cnhPhotoUrl: cnhUrl,
        crlvPhotoUrl: crlvUrl,
        brand: _vehicleBrand,
        model: _vehicleModel,
        year: int.tryParse(_vehicleYear) ?? 0,
        plate: _vehiclePlate,
        color: _vehicleColor,
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Erro ao finalizar cadastro: $e');
      _setLoading(false);
      return false;
    }
  }
  
  // Métodos auxiliares
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Vehicle data setters
  void setBrand(String value) {
    _vehicleBrand = value;
    brandController.text = value;
    notifyListeners();
  }
  
  void setModel(String value) {
    _vehicleModel = value;
    modelController.text = value;
    notifyListeners();
  }
  
  void setYear(String value) {
    _vehicleYear = value;
    yearController.text = value;
    notifyListeners();
  }
  
  void setPlate(String value) {
    _vehiclePlate = value;
    plateController.text = value;
    notifyListeners();
  }
  
  void setColor(String value) {
    _vehicleColor = value;
    colorController.text = value;
    notifyListeners();
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