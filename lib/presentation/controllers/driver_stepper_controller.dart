import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/user.dart' as app_models;
import '../../data/models/vehicle_brand.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/models/supabase/platform_settings.dart';
import '../services/app_logger.dart';
import '../services/driver_service.dart';
import '../services/firebase_file_upload_service.dart';
import '../services/user_service.dart';
import '../services/vehicle_data_service.dart';
import '../services/platform_settings_service.dart';
import '../../core/utils/supabase_helper.dart';

class DriverStepperController extends ChangeNotifier {
  final PageController pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;
  
  // Constructor
  DriverStepperController() {
    loadAvailableCategories();
  }
  
  // Estados de upload por documento (mantidos para compatibilidade)
  File? _cnhPhoto;
  File? _crlvPhoto;
  String? _cnhUrl;
  String? _crlvUrl;
  bool _isUploadingCnh = false;
  bool _isUploadingCrlv = false;
  String? _cnhError;
  String? _crlvError;
  
  // Estados de retry para feedback visual (mantidos para compatibilidade)
  int _cnhRetryAttempt = 0;
  final int _crlvRetryAttempt = 0;
  bool _cnhIsRetrying = false;
  final bool _crlvIsRetrying = false;
  
  // Dados do veículo
  String _vehicleBrand = '';
  String _vehicleModel = '';
  String _vehicleYear = '';
  String _vehiclePlate = '';
  String _vehicleColor = '';
  String _vehicleCategory = '';
  
  // Text controllers for vehicle form
  final TextEditingController brandController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController plateController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  final VehicleDataService _vehicleDataService = VehicleDataService();
  final PlatformSettingsService _platformSettingsService = PlatformSettingsService(SupabaseHelper.client!);
  
  // Vehicle autocomplete data
  final List<VehicleBrand> _brands = [];
  final List<VehicleModel> _models = [];
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
  bool _categoryFieldTouched = false;
  
  // Platform settings data
  List<PlatformSettings> _availableCategories = [];
  PlatformSettings? _selectedCategory;
  bool _isCategoriesLoading = false;
  
  // Getters
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  File? get cnhPhoto => _cnhPhoto;
  File? get crlvPhoto => _crlvPhoto;
  
  // Getters de estado por documento (mantidos para compatibilidade)
  String? get cnhUrl => _cnhUrl;
  String? get crlvUrl => _crlvUrl;
  bool get isUploadingCnh => _isUploadingCnh;
  bool get isUploadingCrlv => _isUploadingCrlv;
  String? get cnhError => _cnhError;
  String? get crlvError => _crlvError;
  
  // Getters para estados de retry (mantidos para compatibilidade)
  int get cnhRetryAttempt => _cnhRetryAttempt;
  int get crlvRetryAttempt => _crlvRetryAttempt;
  bool get cnhIsRetrying => _cnhIsRetrying;
  bool get crlvIsRetrying => _crlvIsRetrying;
  
  String get vehicleBrand => _vehicleBrand;
  String get vehicleModel => _vehicleModel;
  String get vehicleYear => _vehicleYear;
  String get vehiclePlate => _vehiclePlate;
  String get vehicleColor => _vehicleColor;
  String get vehicleCategory => _vehicleCategory;
  
  // Vehicle autocomplete getters
  List<VehicleBrand> get brands => _brands;
  List<VehicleModel> get models => _models;
  VehicleBrand? get selectedBrand => _selectedBrand;
  VehicleModel? get selectedModel => _selectedModel;
  bool get isBrandLoading => _isBrandLoading;
  bool get isModelLoading => _isModelLoading;
  
  // Platform settings getters
  List<PlatformSettings> get availableCategories => _availableCategories;
  PlatformSettings? get selectedCategory => _selectedCategory;
  bool get isCategoriesLoading => _isCategoriesLoading;
  
  // Field validation getters
  bool get brandFieldTouched => _brandFieldTouched;
  bool get modelFieldTouched => _modelFieldTouched;
  bool get yearFieldTouched => _yearFieldTouched;
  bool get plateFieldTouched => _plateFieldTouched;
  bool get colorFieldTouched => _colorFieldTouched;
  bool get categoryFieldTouched => _categoryFieldTouched;
  
  // Field error getters
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
  // Validation getters
  // No validation needed for code of conduct step - it's informational only
  bool get canProceedFromCodeOfConduct => true;
  
  bool get canProceedFromVehicle => 
      _vehicleBrand.isNotEmpty && 
      _vehicleModel.isNotEmpty && 
      _vehicleYear.isNotEmpty && 
      _vehiclePlate.isNotEmpty && 
      _vehicleColor.isNotEmpty &&
      _vehicleCategory.isNotEmpty;
      
  bool get canCompleteRegistration => 
      canProceedFromCodeOfConduct && canProceedFromVehicle;
      
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
  
  Future<void> setVehiclePlate(String plate) async {
    if (_disposed) return;
    _vehiclePlate = plate.toUpperCase();
    
    // Validação de placa única em tempo real
    if (plate.isNotEmpty && !plate.startsWith('PENDENTE')) {
      try {
        await _checkPlateUniqueness(plate);
      } catch (e) {
        // Se houver erro de duplicação, limpar o campo
        if (e.toString().contains('já está em uso')) {
          _vehiclePlate = 'PENDENTE';
          _errorMessage = 'Esta placa já está cadastrada por outro motorista';
        }
      }
    }
    
    notifyListeners();
  }
  
  void setVehicleColor(String color) {
    if (_disposed) return;
    _vehicleColor = color;
    notifyListeners();
  }
  
  void setVehicleCategory(String category) {
    if (_disposed) return;
    _vehicleCategory = category;
    notifyListeners();
  }
  
  void selectCategory(String categoryName) {
    if (_disposed) return;
    final platformSettings = _availableCategories.firstWhere(
      (settings) => settings.category == categoryName,
      orElse: () => _availableCategories.first,
    );
    _selectedCategory = platformSettings;
    _vehicleCategory = categoryName;
    notifyListeners();
  }
  
  // Carrega categorias disponíveis do platform_settings
  Future<void> loadAvailableCategories() async {
    if (_disposed) return;
    
    _isCategoriesLoading = true;
    notifyListeners();
    
    try {
      final allSettings = await _platformSettingsService.getAllSettings();
      _availableCategories = allSettings;
      
      // Se não há categoria selecionada, seleciona a primeira (padrão)
      if (_selectedCategory == null && _availableCategories.isNotEmpty) {
        final defaultCategoryName = _availableCategories.any(
          (category) => category.category == 'Comum'
        ) ? 'Comum' : _availableCategories.first.category;
        selectCategory(defaultCategoryName);
      }
    } catch (e) {
      _errorMessage = 'Erro ao carregar categorias de veículo';
    } finally {
      _isCategoriesLoading = false;
      notifyListeners();
    }
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
  
  // Captura de fotos (opcionais - para uploads voluntários de documentos)
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
  
  // Seleção de fotos da galeria (opcionais - para uploads voluntários de documentos)
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
  
  /// Upload de documento seguindo o mesmo padrão do upload de foto de perfil
  Future<String?> _uploadDocument(File file, String fileName, String documentType) async {
    try {
      final authUser = SupabaseHelper.client?.auth.currentUser;
      if (authUser == null) {
        throw Exception('Usuário não autenticado');
      }
      
      AppLogger.upload('Fazendo upload do documento $documentType');
      
      // Generate storage path seguindo o padrão das fotos de perfil
      final storagePath = FirebaseFileUploadService.generateDriverDocumentPath(
        userId: authUser.id,
        fileName: fileName,
        documentType: documentType,
      );
      
      // Upload to driver-documents folder no Firebase Storage
      final documentUrl = await FirebaseFileUploadService.uploadDriverDocument(
        file: file,
        folder: 'driver-documents',
        path: storagePath,
        compress: !fileName.toLowerCase().endsWith('.pdf'), // Não comprimir PDFs
      );
      
      AppLogger.success('Documento $documentType enviado com sucesso');
      
      return documentUrl;
    } on SocketException catch (e) {
      AppLogger.error('Erro de conexão ao fazer upload do documento: ${e.message}', error: e);
      throw Exception('Erro de conexão. Verifique sua internet e tente novamente.');
    } on TimeoutException catch (e) {
      AppLogger.error('Timeout ao fazer upload do documento: ${e.message}', error: e);
      throw Exception('Upload demorou muito. Verifique sua conexão e tente novamente.');
    } catch (e) {
      AppLogger.error('Erro inesperado ao fazer upload do documento: $e', error: e);
      throw Exception('Erro ao enviar documento. Tente novamente.');
    }
  }
  
  String _mapUploadError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('muito grande') || msg.contains('50mb') || msg.contains('10mb')) {
      return 'Arquivo excede o limite permitido.';
    }
    if (msg.contains('formato não suportado') || msg.contains('mime') || msg.contains('tipo de arquivo não permitido')) {
      return 'Formato inválido. Utilize JPG, PNG ou PDF.';
    }
    if (msg.contains('sessão expirada') || msg.contains('não foi possível renovar') || msg.contains('token expirado')) {
      return 'Sessão expirada. Faça login novamente.';
    }
    if (msg.contains('não autenticado') || msg.contains('auth') || msg.contains('usuário não autenticado')) {
      return 'Sessão expirada. Faça login novamente.';
    }
    if (msg.contains('permission denied') || msg.contains('unauthorized') || msg.contains('forbidden')) {
      return 'Permissão negada no Firebase Storage. Verifique a configuração.';
    }
    if (msg.contains('arquivo não encontrado') || msg.contains('no such file')) {
      return 'Arquivo não encontrado no dispositivo.';
    }
    if (msg.contains('network') || msg.contains('connection') || msg.contains('timeout')) {
      return 'Erro de conexão. Verifique sua internet e tente novamente.';
    }
    if (msg.contains('firebase') || msg.contains('storage')) {
      return 'Erro no Firebase Storage. Tente novamente em alguns minutos.';
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
      // Garantir que a sessão está válida
      await _ensureValidSession();
      final user = SupabaseHelper.client!.auth.currentUser!;
      
      // Upload dos documentos (opcional - não exigir mais)
      String? cnhUrl;
      String? crlvUrl;
      
      // Se documentos foram selecionados, fazer upload
      if (_cnhPhoto != null) {
        try {
          _isUploadingCnh = true;
          _cnhRetryAttempt = 0;
          _cnhIsRetrying = false;
          if (!_disposed) notifyListeners();
          
          cnhUrl = await _uploadDocumentWithRetryTracking(
            file: _cnhPhoto!,
            fileName: 'cnh_${DateTime.now().millisecondsSinceEpoch}.jpg',
            documentType: 'CNH_FRONT',
            onRetry: (attempt) {
              _cnhRetryAttempt = attempt;
              _cnhIsRetrying = true;
              if (!_disposed) notifyListeners();
            },
          );
          
          if (_disposed) return false;
          _cnhUrl = cnhUrl;
          _cnhError = null;
          _cnhIsRetrying = false;
        } catch (e) {
          if (_disposed) return false;
          _cnhError = _mapUploadError(e);
          _setError('❌ Não foi possível enviar a foto da CNH.\n\n$_cnhError\n\nVerifique sua conexão e tente novamente.');
          _isUploadingCnh = false;
          _cnhIsRetrying = false;
          _setLoading(false);
          if (!_disposed) notifyListeners();
          return false;
        } finally {
          _isUploadingCnh = false;
          _cnhIsRetrying = false;
          if (!_disposed) notifyListeners();
        }
      }
      
      if (_crlvPhoto != null) {
        try {
          _isUploadingCrlv = true;
          if (!_disposed) notifyListeners();
          crlvUrl = await _uploadDocument(_crlvPhoto!, 'crlv_${DateTime.now().millisecondsSinceEpoch}.jpg', 'CRLV');
          if (_disposed) return false;
          _crlvUrl = crlvUrl;
          _crlvError = null;
        } catch (e) {
          if (_disposed) return false;
          _crlvError = _mapUploadError(e);
          _setError('❌ Não foi possível enviar a foto do CRLV.\n\n$_crlvError\n\nVerifique sua conexão e tente novamente.');
          _isUploadingCrlv = false;
          _setLoading(false);
          if (!_disposed) notifyListeners();
          return false;
        } finally {
          _isUploadingCrlv = false;
          if (!_disposed) notifyListeners();
        }
      }
      
      // Garantir que existe registro de driver e obter ID
      String driverId;
      try {
        driverId = await _ensureDriverExists(user);
      } catch (e) {
        _setError('❌ Não foi possível verificar seus dados de motorista.\n\nTente fazer login novamente ou entre em contato com o suporte.');
        _setLoading(false);
        return false;
      }
      
      // Atualizar dados do motorista (sem CNH e CRLV que foram removidos do banco)
      try {
        await DriverService.updateDriver(
          driverId,
          brand: _vehicleBrand,
          model: _vehicleModel,
          year: int.tryParse(_vehicleYear) ?? 0,
          plate: _vehiclePlate,
          color: _vehicleColor,
          category: _vehicleCategory,
        );
        
        // Mark profile as complete for driver
        print('🔄 [DRIVER_STEPPER_CONTROLLER] Marcando perfil de motorista como completo...');
        await UserService.markProfileComplete(user.id);
        print('✅ [DRIVER_STEPPER_CONTROLLER] Perfil de motorista marcado como completo');
        
        _clearError();
        _setLoading(false);
        return true;
      } on PostgrestException catch (e) {
        final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
        print('❌ [DRIVER-UPDATE-$sessionId] Erro PostgreSQL: ${e.code} - ${e.message}');
        
        if (e.code == 'PGRST116') {
          _setError('❌ Registro de motorista não encontrado.\n\nTente fazer login novamente.');
        } else if ((e.code ?? '').startsWith('23505')) { // Duplicate key
          _setError('❌ Esta placa já está cadastrada!\n\nA placa $_vehiclePlate já está sendo usada por outro motorista. Verifique se digitou corretamente.');
        } else if ((e.code ?? '').startsWith('23')) { // Other constraint violations
          _setError('❌ Dados inválidos detectados.\n\nVerifique se todas as informações do veículo estão corretas e tente novamente.');
        } else {
          _setError('❌ Erro no sistema.\n\n${e.message}\n\nTente novamente em alguns instantes.');
        }
        _setLoading(false);
        return false;
      } catch (e) {
        _setError('❌ Não foi possível salvar seus dados.\n\nOcorreu um erro inesperado. Tente novamente ou entre em contato com o suporte.');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('❌ Erro inesperado no cadastro.\n\nAlgo deu errado durante o processo. Tente novamente ou reinicie o aplicativo.');
      _setLoading(false);
      return false;
    }
  }
  
  /// Upload de documento com tracking de retry attempts para feedback visual
  Future<String> _uploadDocumentWithRetryTracking({
    required File file,
    required String fileName,
    required String documentType,
    required Function(int attempt) onRetry,
  }) async {
    return await FirebaseFileUploadService.uploadDriverDocument(
      file: file,
      folder: 'driver-documents',
      path: 'drivers/${SupabaseHelper.client!.auth.currentUser!.id}/documents/$fileName',
      compress: true,
    );
  }
  
  // Métodos auxiliares
  /// Garante que existe um registro de driver para o usuário e retorna o ID
  Future<String> _ensureDriverExists(User user) async {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    print('🔍 [DRIVER-$sessionId] Verificando se existe registro de motorista para usuário: ${user.id}');
    
    try {
      // Primeiro, tentar buscar driver existente
      final existingDriverResponse = await SupabaseHelper.client!
          .from('drivers')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (existingDriverResponse != null) {
        final driverId = existingDriverResponse['id'] as String;
        print('✅ [DRIVER-$sessionId] Registro de motorista encontrado: $driverId');
        return driverId;
      }
      
      // Se não existe, criar usando UserService
      print('⚠️ [DRIVER-$sessionId] Registro não encontrado, criando automaticamente...');
      // Converter User do Supabase para User do modelo
      final userModel = await _getUserModel(user.id);
      await UserService.createDriverRecord(userModel);
      
      // Buscar novamente o registro recém-criado
      final newDriverResponse = await SupabaseHelper.client!
          .from('drivers')
          .select('id')
          .eq('user_id', user.id)
          .single();
      
      final driverId = newDriverResponse['id'] as String;
      print('✅ [DRIVER-$sessionId] Registro de motorista criado com sucesso: $driverId');
      return driverId;
      
    } on PostgrestException catch (e) {
      print('❌ [DRIVER-$sessionId] Erro PostgreSQL: ${e.code} - ${e.message}');
      if (e.code == 'PGRST116') {
        throw Exception('Registro de motorista não encontrado após criação. Verifique as permissões do banco.');
      } else if ((e.code ?? '').startsWith('23')) { // Constraint violation
        throw Exception('Conflito de dados do motorista. Verifique se já existe um registro.');
      } else {
        throw Exception('Erro no banco de dados: ${e.message}');
      }
    } catch (e) {
      print('❌ [DRIVER-$sessionId] Erro inesperado: $e');
      throw Exception('Não foi possível acessar ou criar dados do motorista. Tente novamente.');
    }
  }
  
  /// Busca o modelo de usuário a partir do ID do usuário auth
  Future<app_models.User> _getUserModel(String userId) async {
    try {
      final userResponse = await SupabaseHelper.client!
          .from('app_users')
          .select()
          .eq('id', userId)
          .single();
      
      return app_models.User.fromMap(userResponse);
    } catch (e) {
      throw Exception('Não foi possível buscar dados do usuário: $e');
    }
  }
  
  /// Verifica e renova a sessão do usuário se necessário
  Future<void> _ensureValidSession() async {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    print('🔐 [SESSION-$sessionId] Verificando validade da sessão...');
    
    final client = SupabaseHelper.client;
    if (client == null) {
      print('❌ [SESSION-$sessionId] Erro: Cliente Supabase não disponível');
      throw Exception('Erro de configuração do Supabase');
    }
    
    final session = client.auth.currentSession;
    final user = client.auth.currentUser;
    
    print('🔍 [SESSION-$sessionId] Estado da sessão:');
    print('   - Usuário autenticado: ${user != null}');
    print('   - User ID: ${user?.id ?? "null"}');
    print('   - Session existe: ${session != null}');
    
    if (session?.expiresAt != null) {
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(session!.expiresAt! * 1000);
      final now = DateTime.now();
      final timeUntilExpiry = expiresAt.difference(now);
      
      print('   - Expira em: ${expiresAt.toIso8601String()}');
      print('   - Tempo restante: ${timeUntilExpiry.inMinutes} minutos');
      
      if (session.expiresAt! <= DateTime.now().millisecondsSinceEpoch ~/ 1000) {
        try {
          print('⚠️ [SESSION-$sessionId] Token expirado, renovando sessão...');
          await client.auth.refreshSession();
          final newSession = client.auth.currentSession;
          final newUser = client.auth.currentUser;
          
          print('✅ [SESSION-$sessionId] Sessão renovada com sucesso');
          print('   - Novo User ID: ${newUser?.id}');
          print('   - Nova expiração: ${newSession?.expiresAt != null ? DateTime.fromMillisecondsSinceEpoch(newSession!.expiresAt! * 1000).toIso8601String() : "null"}');
        } catch (e) {
          print('❌ [SESSION-$sessionId] Erro ao renovar sessão: $e');
          throw Exception('Sessão expirada. Faça login novamente.');
        }
      } else {
        print('✅ [SESSION-$sessionId] Sessão válida, não precisa renovar');
      }
    }
    
    final finalUser = client.auth.currentUser;
    if (finalUser == null) {
      print('❌ [SESSION-$sessionId] Usuário não autenticado após verificação');
      throw Exception('Usuário não autenticado');
    }
    
    print('✅ [SESSION-$sessionId] Sessão validada para usuário: ${finalUser.id}');
  }

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
  
  // Public method to clear errors
  void clearError() {
    _clearError();
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
  
  Future<void> setPlate(String value) async {
    if (_disposed) return;
    _plateFieldTouched = true;
    _vehiclePlate = value;
    plateController.text = value;
    
    // Validação de placa única em tempo real
    if (value.isNotEmpty && !value.startsWith('PENDENTE')) {
      try {
        await _checkPlateUniqueness(value);
      } catch (e) {
        // Se houver erro de duplicação, limpar o campo
        if (e.toString().contains('já está em uso')) {
          _vehiclePlate = '';
          plateController.text = '';
          _errorMessage = 'Esta placa já está cadastrada por outro motorista';
        }
      }
    }
    
    notifyListeners();
  }
  
  Future<void> _checkPlateUniqueness(String plate) async {
    try {
      print('🔍 [PLATE-CHECK] Iniciando verificação de unicidade da placa: $plate');
      
      // Verificar disponibilidade do cliente Supabase
      final client = SupabaseHelper.client;
      if (client == null) {
        print('❌ [PLATE-CHECK] SupabaseHelper.client é nulo');
        throw Exception('Cliente Supabase não disponível');
      }
      
      final currentUserId = client.auth.currentUser?.id;
      print('🔍 [PLATE-CHECK] User ID atual: $currentUserId');
      
      if (currentUserId == null) {
        print('⚠️ [PLATE-CHECK] Usuário não autenticado, ignorando verificação');
        return;
      }
      
      print('🔍 [PLATE-CHECK] Consultando banco para placa: ${plate.toUpperCase()}');
      final response = await client
          .from('drivers')
          .select('user_id')
          .eq('vehicle_plate', plate.toUpperCase())
          .neq('user_id', currentUserId)
          .maybeSingle();
      
      print('✅ [PLATE-CHECK] Resposta do banco: $response');
      
      if (response != null) {
        print('❌ [PLATE-CHECK] Placa já está em uso por outro motorista');
        throw Exception('Placa já está em uso por outro motorista');
      }
      
      print('✅ [PLATE-CHECK] Placa disponível para uso');
    } catch (e) {
      print('❌ [PLATE-CHECK] Erro durante verificação: $e');
      if (e.toString().contains('já está em uso')) {
        rethrow;
      }
      // PROBLEMA IDENTIFICADO: Erros de rede estão sendo ignorados, potencialmente permitindo placas duplicadas
      print('⚠️ [PLATE-CHECK] CRÍTICO: Erro de rede/conexão sendo ignorado. Isso pode permitir cadastro de placas duplicadas!');
      print('⚠️ [PLATE-CHECK] Erro ignorado (possível problema de rede): $e');
      // Em vez de ignorar, devemos falhar gracefully ou tentar novamente
      throw Exception('Não foi possível verificar a disponibilidade da placa. Verifique sua conexão e tente novamente.');
    }
  }
  
  void setColor(String value) {
    if (_disposed) return;
    _colorFieldTouched = true;
    _vehicleColor = value;
    colorController.text = value;
    notifyListeners();
  }
  
  void setCategoryTouched() {
    if (_disposed) return;
    _categoryFieldTouched = true;
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
    _categoryFieldTouched = true;
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