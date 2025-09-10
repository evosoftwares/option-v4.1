import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/vehicle_category.dart';
import '../../models/supabase/platform_settings.dart';
import '../../services/driver_service.dart';
import '../../services/platform_settings_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/plate_formatter.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _plateController = TextEditingController();
  
  int? _selectedYear;
  String? _selectedCategoryId; // ID da categoria selecionada do platform_settings
  List<PlatformSettings> _availableCategories = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
    _loadAvailableCategories();
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicleData() async {
    try {
      // Buscar dados do driver através do user_service para obter o user_id atual
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Usuário não logado');
      }

      // Buscar driver pelo user_id
      final response = await supabase
          .from('drivers')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _brandController.text = response['vehicle_brand'] ?? '';
          _modelController.text = response['vehicle_model'] ?? '';
          _colorController.text = response['vehicle_color'] ?? '';
          _plateController.text = response['vehicle_plate'] ?? '';
          _selectedYear = response['vehicle_year'];
          if (response['vehicle_category'] != null) {
            _selectedCategoryId = response['vehicle_category'];
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Erro ao carregar dados do veículo');
      }
    }
  }

  Future<void> _loadAvailableCategories() async {
    if (!mounted) return;
    
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    print('📦 [CATEGORIES-$sessionId] Iniciando carregamento de categorias disponíveis');
    
    setState(() => _isLoadingCategories = true);
    
    try {
      // Log do usuário atual
      final currentUser = Supabase.instance.client.auth.currentUser;
      print('👤 [CATEGORIES-$sessionId] Usuário: ${currentUser?.id}');
      print('📧 [CATEGORIES-$sessionId] Email: ${currentUser?.email}');
      
      // Verificar se a tabela platform_settings existe e tem dados
      print('🔍 [CATEGORIES-$sessionId] Verificando tabela platform_settings...');
      final directQuery = await Supabase.instance.client
          .from('platform_settings')
          .select('id, category, base_price_per_km, min_fare')
          .limit(10);
      
      print('📊 [CATEGORIES-$sessionId] Registros encontrados diretamente: ${directQuery.length}');
      for (int i = 0; i < directQuery.length; i++) {
        final record = directQuery[i];
        print('   📋 [$i] Category: ${record['category']}, Min Fare: ${record['min_fare']}');
      }
      
      // Usar o PlatformSettingsService
      print('🔧 [CATEGORIES-$sessionId] Usando PlatformSettingsService...');
      final platformSettingsService = PlatformSettingsService(Supabase.instance.client);
      final categories = await platformSettingsService.getAllSettings();
      
      print('📊 [CATEGORIES-$sessionId] Categorias carregadas via service: ${categories.length}');
      for (int i = 0; i < categories.length; i++) {
        final category = categories[i];
        print('   📋 [$i] ID: ${category.id}, Category: ${category.category}, MinFare: ${category.minFare}');
      }
      
      if (mounted) {
        setState(() {
          _availableCategories = categories;
          _isLoadingCategories = false;
        });
        print('✅ [CATEGORIES-$sessionId] Estado atualizado com ${categories.length} categorias');
      } else {
        print('⚠️ [CATEGORIES-$sessionId] Widget não montado - não atualizando estado');
      }
    } catch (e) {
      print('❌ [CATEGORIES-$sessionId] Erro ao carregar categorias: $e');
      print('❌ [CATEGORIES-$sessionId] Tipo do erro: ${e.runtimeType}');
      print('❌ [CATEGORIES-$sessionId] Stack trace: ${StackTrace.current}');
      
      if (mounted) {
        setState(() => _isLoadingCategories = false);
        _showErrorSnackBar('Erro ao carregar categorias disponíveis: ${e.toString()}');
      }
    }
  }

  Future<void> _saveVehicleData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Usuário não logado');
      }

      // Buscar driver_id
      final driverResponse = await supabase
          .from('drivers')
          .select('id')
          .eq('user_id', userId)
          .single();

      final driverId = driverResponse['id'] as String;

      // Usar o DriverService para atualizar
      final driverService = DriverService(supabase);
          
      await DriverService.updateDriver(
        driverId,
        brand: _brandController.text,
        model: _modelController.text,
        year: _selectedYear ?? 0,
        plate: _plateController.text,
        color: _colorController.text,
        category: _selectedCategoryId ?? '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Dados do veículo atualizados com sucesso!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao salvar dados do veículo');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Meu Veículo'),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveVehicleData,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: AppSpacing.paddingLg,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  _buildVehicleForm(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: cs.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: cs.primary,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Mantenha os dados do seu veículo sempre atualizados para que os passageiros possam identificá-lo facilmente.',
              style: AppTypography.bodyMedium.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleForm() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dados do Veículo',
          style: AppTypography.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        
        _buildTextField(
          controller: _brandController,
          label: 'Marca',
          hint: 'Ex: Toyota, Honda, Ford',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Marca é obrigatória';
            }
            
            final valueStr = value.trim();
            if (valueStr.length > 50) {
              return 'Marca não pode ter mais de 50 caracteres';
            }
            
            return null;
          },
        ),
        
        const SizedBox(height: AppSpacing.lg),
        _buildTextField(
          controller: _modelController,
          label: 'Modelo',
          hint: 'Ex: Corolla, Civic, Focus',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Modelo é obrigatório';
            }
            
            final valueStr = value.trim();
            if (valueStr.length > 50) {
              return 'Modelo não pode ter mais de 50 caracteres';
            }
            
            return null;
          },
        ),
        
        const SizedBox(height: AppSpacing.lg),
        _buildYearDropdown(),
        
        const SizedBox(height: AppSpacing.lg),
        _buildTextField(
          controller: _colorController,
          label: 'Cor',
          hint: 'Ex: Branco, Prata, Preto',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Cor é obrigatória';
            }
            
            final valueStr = value.trim();
            if (valueStr.length > 30) {
              return 'Cor não pode ter mais de 30 caracteres';
            }
            
            return null;
          },
        ),
        
        const SizedBox(height: AppSpacing.lg),
        _buildTextField(
          controller: _plateController,
          label: 'Placa',
          hint: 'Ex: ABC-1234',
          inputFormatters: [PlateInputFormatter()],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Placa é obrigatória';
            }
            
            // Usar PlateValidator para validação mais amigável
            if (!PlateValidator.isValidBrazilianPlate(value)) {
              return PlateValidator.getErrorMessage(value);
            }
            
            return null;
          },
          onChanged: (value) {
            if (value.isNotEmpty && !value.startsWith('PENDENTE')) {
              final cleanPlate = PlateValidator.cleanPlate(value);
              if (cleanPlate.length == 7) {
                _checkPlateUniqueness(cleanPlate);
              }
            }
          },
        ),
        
        const SizedBox(height: AppSpacing.lg),
        _buildCategoryDropdown(),
      ],
    );

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final cs = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          validator: validator,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: cs.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: cs.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: cs.error),
            ),
            filled: true,
            fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildYearDropdown() {
    final cs = Theme.of(context).colorScheme;
    final currentYear = DateTime.now().year;
    final years = List.generate(30, (index) => currentYear - index);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ano',
          style: AppTypography.labelLarge.copyWith(
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<int>(
          initialValue: _selectedYear,
          onChanged: (value) => setState(() => _selectedYear = value),
          validator: (value) {
            if (value == null) {
              return 'Ano é obrigatório';
            }
            
            final currentYear = DateTime.now().year;
            if (value < 1990 || value > currentYear + 1) {
              return 'Ano deve estar entre 1990 e ${currentYear + 1}';
            }
            
            return null;
          },
          decoration: InputDecoration(
            hintText: 'Selecione o ano',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: cs.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: cs.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
            filled: true,
            fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
          ),
          items: years.map((year) => DropdownMenuItem<int>(
              value: year,
              child: Text(year.toString()),
            ),).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    final cs = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Categoria',
              style: AppTypography.labelLarge.copyWith(
                color: cs.onSurface,
              ),
            ),
            if (_isLoadingCategories) ...[
              const SizedBox(width: AppSpacing.sm),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategoryId,
          onChanged: (value) {
            setState(() {
              _selectedCategoryId = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Categoria é obrigatória';
            }
            
            return null;
          },
          decoration: InputDecoration(
            hintText: _availableCategories.isEmpty 
                ? 'Carregando categorias...' 
                : 'Selecione a categoria',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: cs.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: cs.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          items: _availableCategories.map((platformSettings) {
            return DropdownMenuItem<String>(
              value: platformSettings.category,
              child: Text(
                platformSettings.category.toUpperCase(),
                style: AppTypography.bodyMedium,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _checkPlateUniqueness(String plate) async {
    if (plate.isEmpty || plate.startsWith('PENDENTE')) return;
    
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) return;
      
      final response = await supabase
          .from('drivers')
          .select('user_id')
          .eq('vehicle_plate', plate.toUpperCase())
          .neq('user_id', userId)
          .maybeSingle();
      
      if (response != null && mounted) {
        _showErrorSnackBar('Esta placa já está cadastrada por outro motorista');
        _plateController.clear();
      }
    } catch (e) {
      // Ignorar erros de rede/conexão
    }
  }
}