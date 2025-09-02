import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vehicle_brand.dart';
import '../models/vehicle_model.dart';
import '../services/driver_service.dart';
import '../services/file_upload_service.dart';
import '../services/user_service.dart';
import '../services/vehicle_data_service.dart';
import '../utils/supabase_helper.dart';

class DriverStepperController extends ChangeNotifier {
  final PageController pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;
  
  // Documentos
  File? _cnhPhoto;
  File? _crlvPhoto;
  
  // Estados de upload por documento
  String? _cnhUrl;
  String? _crlvUrl;
  bool _isUploadingCnh = false;
  bool _isUploadingCrlv = false;
  String? _cnhError;
  String? _crlvError;
  
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
  final VehicleDataService _vehicleDataService = VehicleDataService();
  
  // Vehicle autocomplete data
  List<VehicleBrand> _brands = [];
  List<VehicleModel> _models = [];
  VehicleBrand? _selectedBrand;
  VehicleModel? _selectedModel;
  bool _isBrandLoading = false;
  bool _isModelLoading = false;
  
  // Field validation states
  bool _brandFieldTouched = false;
  bool _modelFieldTouched = false;
  bool _yearFieldTouched = false;
  bool _plateFieldTouched = false;
  bool _colorFieldTouched = false;
  
  // Getters
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  File? get cnhPhoto => _cnhPhoto;
  File? get crlvPhoto => _crlvPhoto;
  
  // Getters de estado por documento
  String? get cnhUrl => _cnhUrl;
  String? get crlvUrl => _crlvUrl;
  bool get isUploadingCnh => _isUploadingCnh;
  bool get isUploadingCrlv => _isUploadingCrlv;
  String? get cnhError => _cnhError;
  String? get crlvError => _crlvError;
  
  String get vehicleBrand => _vehicleBrand;
  String get vehicleModel => _vehicleModel;
  String get vehicleYear => _vehicleYear;
  String get vehiclePlate => _vehiclePlate;
  String get vehicleColor => _vehicleColor;
  
  // Vehicle autocomplete getters
  List<VehicleBrand> get brands => _brands;
  List<VehicleModel> get models => _models;
  VehicleBrand? get selectedBrand => _selectedBrand;
  VehicleModel? get selectedModel => _selectedModel;
  bool get isBrandLoading => _isBrandLoading;
  bool get isModelLoading => _isModelLoading;
  
  // Field validation getters
  bool get brandFieldTouched => _brandFieldTouched;
  bool get modelFieldTouched => _modelFieldTouched;
  bool get yearFieldTouched => _yearFieldTouched;
  bool get plateFieldTouched => _plateFieldTouched;
  bool get colorFieldTouched => _colorFieldTouched;
  
  // Field error getters
  bool get brandHasError => _brandFieldTouched && _vehicleBrand.isEmpty;
  bool get modelHasError => _modelFieldTouched && _vehicleModel.isEmpty;
  bool get yearHasError => _yearFieldTouched && _vehicleYear.isEmpty;
  bool get plateHasError => _plateFieldTouched && _vehiclePlate.isEmpty;
  bool get colorHasError => _colorFieldTouched && _vehicleColor.isEmpty;
  
  String? get brandErrorMessage => brandHasError ? 'Selecione uma marca' : null;
  String? get modelErrorMessage => modelHasError ? 'Selecione um modelo' : null;
  String? get yearErrorMessage => yearHasError ? 'Informe o ano' : null;
  String? get plateErrorMessage => plateHasError ? 'Informe a placa' : null;
  String? get colorErrorMessage => colorHasError ? 'Informe a cor' : null;
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
    if (_disposed) return;
    _vehicleBrand = brand;
    notifyListeners();
  }
  
  void setVehicleModel(String model) {
    if (_disposed) return;
    _vehicleModel = model;
    notifyListeners();
  }
  
  void setVehicleYear(String year) {
    if (_disposed) return;
    _vehicleYear = year;
    notifyListeners();
  }
  
  void setVehiclePlate(String plate) {
    if (_disposed) return;
    _vehiclePlate = plate.toUpperCase();
    notifyListeners();
  }
  
  void setVehicleColor(String color) {
    if (_disposed) return;
    _vehicleColor = color;
    notifyListeners();
  }
  
  // Navegação entre etapas
  void nextStep() {
    if (_disposed || _currentStep >= 2) return;
    _currentStep++;
    pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    notifyListeners();
  }
  
  void previousStep() {
    if (_disposed || _currentStep <= 0) return;
    _currentStep--;
    pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    notifyListeners();
  }
  
  void goToStep(int step) {
    if (_disposed || step < 0 || step > 2) return;
    _currentStep = step;
    pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    notifyListeners();
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
        // resetar estado anterior
        _cnhUrl = null;
        _cnhError = null;
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
        // resetar estado anterior
        _crlvUrl = null;
        _crlvError = null;
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
        _cnhUrl = null;
        _cnhError = null;
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
        _crlvUrl = null;
        _crlvError = null;
        notifyListeners();
      }
    } catch (e) {
      _setError('Erro ao selecionar foto do CRLV: $e');
    }
  }
  
  // Upload de documentos usando FileUploadService
  Future<String?> _uploadDocument(File file, String fileName) async {
    try {
      final user = SupabaseHelper.client?.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }
      
      // Validar arquivo antes do upload
      if (!await file.exists()) {
        throw Exception('Arquivo não encontrado');
      }
      
      // Verificar tamanho do arquivo (10MB máximo)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Arquivo muito grande. Máximo permitido: 10MB');
      }
      
      // Verificar extensão do arquivo
      final extension = fileName.toLowerCase().split('.').last;
      final allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
      if (!allowedExtensions.contains(extension)) {
        throw Exception('Formato não suportado. Use: JPG, PNG ou PDF');
      }
      
      // Usar FileUploadService para upload de documentos
      final path = 'driver_documents/${user.id}/$fileName';
      final url = await FileUploadService.uploadDriverDocument(
        file: file,
        bucket: 'user-photos',
        path: path,
        compress: extension != 'pdf', // Não comprimir PDFs
      );
      
      return url;
    } catch (e) {
      // Não transformar erro em mensagem global aqui; deixar quem chama decidir
      print('Erro ao fazer upload do documento: $e');
      rethrow;
    }
  }
  
  String _mapUploadError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('muito grande') || msg.contains('10mb')) {
      return 'Arquivo excede o limite de 10MB.';
    }
    if (msg.contains('formato não suportado') || msg.contains('mime')) {
      return 'Formato inválido. Utilize JPG, PNG ou PDF.';
    }
    if (msg.contains('não autenticado') || msg.contains('auth')) {
      return 'Sessão expirada. Faça login novamente.';
    }
    if (msg.contains('permission denied') || msg.contains('rls') || msg.contains('not allowed')) {
      return 'Permissão negada no Storage. Tente novamente em alguns minutos.';
    }
    if (msg.contains('arquivo não encontrado') || msg.contains('no such file')) {
      return 'Arquivo não encontrado no dispositivo.';
    }
    return 'Erro inesperado no upload. Detalhes: ${e.toString()}';
  }
  
  // Finalizar cadastro
  Future<bool> completeDriverRegistration() async {
    _setLoading(true);
    _clearError();
    _cnhError = null;
    _crlvError = null;
    if (!_disposed) notifyListeners();
    
    try {
      final user = SupabaseHelper.client?.auth.currentUser;
      if (user == null) {
        _setError('Sessão expirada. Faça login novamente.');
        return false;
      }
      
      // Validar se os documentos foram selecionados
      if (_cnhPhoto == null) {
        _setError('Por favor, tire uma foto da sua CNH.');
        return false;
      }
      
      if (_crlvPhoto == null) {
        _setError('Por favor, tire uma foto do seu CRLV.');
        return false;
      }
      
      // Upload dos documentos
      String? cnhUrl;
      String? crlvUrl;
      
      try {
        _isUploadingCnh = true;
        if (!_disposed) notifyListeners();
        cnhUrl = await _uploadDocument(_cnhPhoto!, 'cnh_${DateTime.now().millisecondsSinceEpoch}.jpg');
        if (_disposed) return false;
        _cnhUrl = cnhUrl;
        _cnhError = null;
      } catch (e) {
        if (_disposed) return false;
        _cnhError = _mapUploadError(e);
        _setError('Falha no upload da CNH. ${_cnhError}');
        _isUploadingCnh = false;
        _setLoading(false);
        if (!_disposed) notifyListeners();
        return false;
      } finally {
        _isUploadingCnh = false;
        if (!_disposed) notifyListeners();
      }
      
      try {
        _isUploadingCrlv = true;
        if (!_disposed) notifyListeners();
        crlvUrl = await _uploadDocument(_crlvPhoto!, 'crlv_${DateTime.now().millisecondsSinceEpoch}.jpg');
        if (_disposed) return false;
        _crlvUrl = crlvUrl;
        _crlvError = null;
      } catch (e) {
        if (_disposed) return false;
        _crlvError = _mapUploadError(e);
        _setError('Falha no upload do CRLV. ${_crlvError}');
        _isUploadingCrlv = false;
        _setLoading(false);
        if (!_disposed) notifyListeners();
        return false;
      } finally {
        _isUploadingCrlv = false;
        if (!_disposed) notifyListeners();
      }
      
      // Buscar o driver ID primeiro
      try {
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
        
        _clearError();
        _setLoading(false);
        return true;
      } catch (e) {
        _setError('Erro ao salvar dados do motorista: ${e.toString()}');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Erro inesperado: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
  
  // Métodos auxiliares
  void _setLoading(bool loading) {
    if (_disposed) return;
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    if (_disposed) return;
    _errorMessage = error;
    notifyListeners();
  }
  
  void _clearError() {
    if (_disposed) return;
    _errorMessage = null;
    notifyListeners();
  }
  
  // Vehicle data setters
  void setBrand(String value) {
    if (_disposed) return;
    _brandFieldTouched = true;
    _vehicleBrand = value;
    brandController.text = value;
    notifyListeners();
  }
  
  void setModel(String value) {
    if (_disposed) return;
    _modelFieldTouched = true;
    _vehicleModel = value;
    modelController.text = value;
    notifyListeners();
  }
  
  // Vehicle autocomplete methods
  Future<List<VehicleBrand>> searchBrands(String query) async {
    if (_disposed) return [];
    _isBrandLoading = true;
    notifyListeners();
    
    try {
      final results = await _vehicleDataService.searchBrands(query);
      if (_disposed) return [];
      _brands.clear();
      _brands.addAll(results);
      return results;
    } catch (e) {
      if (_disposed) return [];
      _setError('Erro ao carregar marcas: $e');
      return [];
    } finally {
      if (!_disposed) {
        _isBrandLoading = false;
        notifyListeners();
      }
    }
  }
  
  Future<List<VehicleModel>> searchModels(String query) async {
    if (_disposed || _selectedBrand == null) return [];
    
    _isModelLoading = true;
    notifyListeners();
    
    try {
      final results = await _vehicleDataService.searchModels(_selectedBrand!.id, query);
      if (_disposed) return [];
      _models.clear();
      _models.addAll(results);
      return results;
    } catch (e) {
      if (_disposed) return [];
      _setError('Erro ao carregar modelos: $e');
      return [];
    } finally {
      if (!_disposed) {
        _isModelLoading = false;
        notifyListeners();
      }
    }
  }
  
  void selectBrand(VehicleBrand brand) {
    if (_disposed) return;
    _selectedBrand = brand;
    _vehicleBrand = brand.name;
    brandController.text = brand.name;
    
    // Clear model when brand changes
    _selectedModel = null;
    _vehicleModel = '';
    modelController.clear();
    _models.clear();
    
    notifyListeners();
  }
  
  void selectModel(VehicleModel model) {
    if (_disposed) return;
    _selectedModel = model;
    _vehicleModel = model.name;
    modelController.text = model.name;
    notifyListeners();
  }
  
  void setYear(String value) {
    if (_disposed) return;
    _yearFieldTouched = true;
    _vehicleYear = value;
    yearController.text = value;
    notifyListeners();
  }
  
  void setPlate(String value) {
    if (_disposed) return;
    _plateFieldTouched = true;
    _vehiclePlate = value;
    plateController.text = value;
    notifyListeners();
  }
  
  void setColor(String value) {
    if (_disposed) return;
    _colorFieldTouched = true;
    _vehicleColor = value;
    colorController.text = value;
    notifyListeners();
  }
  
  // Method to trigger validation check (when user tries to proceed)
  void validateVehicleFields() {
    if (_disposed) return;
    _brandFieldTouched = true;
    _modelFieldTouched = true;
    _yearFieldTouched = true;
    _plateFieldTouched = true;
    _colorFieldTouched = true;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _disposed = true;
    pageController.dispose();
    brandController.dispose();
    modelController.dispose();
    yearController.dispose();
    plateController.dispose();
    colorController.dispose();
    super.dispose();
  }
}