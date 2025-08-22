import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/driver_service.dart';
import '../../models/vehicle_category.dart';

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
  VehicleCategory? _selectedCategory;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
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
            _selectedCategory = VehicleCategory.fromId(response['vehicle_category']);
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
      await driverService.updateDriver(
        driverId,
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        year: _selectedYear!,
        color: _colorController.text.trim(),
        category: _selectedCategory!.id,
        plate: _plateController.text.trim(),
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

  Widget _buildVehicleForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
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
            return null;
          },
        ),
        
        const SizedBox(height: AppSpacing.lg),
        _buildTextField(
          controller: _plateController,
          label: 'Placa',
          hint: 'Ex: ABC-1234',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Placa é obrigatória';
            }
            return null;
          },
        ),
        
        const SizedBox(height: AppSpacing.lg),
        _buildCategoryDropdown(),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
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
          value: _selectedYear,
          onChanged: (value) => setState(() => _selectedYear = value),
          validator: (value) {
            if (value == null) {
              return 'Ano é obrigatório';
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
          items: years.map((year) {
            return DropdownMenuItem<int>(
              value: year,
              child: Text(year.toString()),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    final cs = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoria',
          style: AppTypography.labelLarge.copyWith(
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<VehicleCategory>(
          value: _selectedCategory,
          onChanged: (value) => setState(() => _selectedCategory = value),
          validator: (value) {
            if (value == null) {
              return 'Categoria é obrigatória';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'Selecione a categoria',
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
          items: VehicleCategory.values.map((category) {
            return DropdownMenuItem<VehicleCategory>(
              value: category,
              child: Text(category.displayName),
            );
          }).toList(),
        ),
      ],
    );
  }
}