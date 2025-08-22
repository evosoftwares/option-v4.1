import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/driver_service.dart';

class CustomPricingScreen extends StatefulWidget {
  const CustomPricingScreen({super.key});

  @override
  State<CustomPricingScreen> createState() => _CustomPricingScreenState();
}

class _CustomPricingScreenState extends State<CustomPricingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pricePerKmController = TextEditingController();
  final _pricePerMinuteController = TextEditingController();
  final _petFeeController = TextEditingController();
  final _groceryFeeController = TextEditingController();
  final _condoFeeController = TextEditingController();
  final _stopFeeController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _useCustomPricing = false;

  @override
  void initState() {
    super.initState();
    _loadPricingData();
  }

  @override
  void dispose() {
    _pricePerKmController.dispose();
    _pricePerMinuteController.dispose();
    _petFeeController.dispose();
    _groceryFeeController.dispose();
    _condoFeeController.dispose();
    _stopFeeController.dispose();
    super.dispose();
  }

  Future<void> _loadPricingData() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Usuário não logado');
      }

      final response = await supabase
          .from('drivers')
          .select('custom_price_per_km, custom_price_per_minute, pet_fee, grocery_fee, condo_fee, stop_fee')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          final pricePerKm = response['custom_price_per_km'] as double?;
          final pricePerMinute = response['custom_price_per_minute'] as double?;
          
          _useCustomPricing = pricePerKm != null || pricePerMinute != null;
          
          _pricePerKmController.text = pricePerKm?.toStringAsFixed(2) ?? '1.50';
          _pricePerMinuteController.text = pricePerMinute?.toStringAsFixed(2) ?? '0.20';
          _petFeeController.text = (response['pet_fee'] as double?)?.toStringAsFixed(2) ?? '5.00';
          _groceryFeeController.text = (response['grocery_fee'] as double?)?.toStringAsFixed(2) ?? '3.00';
          _condoFeeController.text = (response['condo_fee'] as double?)?.toStringAsFixed(2) ?? '2.00';
          _stopFeeController.text = (response['stop_fee'] as double?)?.toStringAsFixed(2) ?? '1.50';
          
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Erro ao carregar dados de preços');
      }
    }
  }

  Future<void> _savePricingData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Usuário não logado');
      }

      final driverResponse = await supabase
          .from('drivers')
          .select('id')
          .eq('user_id', userId)
          .single();

      final driverId = driverResponse['id'] as String;
      final driverService = DriverService(supabase);

      // Preparar dados para atualização
      final updateData = <String, dynamic>{};
      
      if (_useCustomPricing) {
        updateData['custom_price_per_km'] = double.parse(_pricePerKmController.text);
        updateData['custom_price_per_minute'] = double.parse(_pricePerMinuteController.text);
      } else {
        updateData['custom_price_per_km'] = null;
        updateData['custom_price_per_minute'] = null;
      }

      // Taxas adicionais são sempre salvas
      final petFee = double.tryParse(_petFeeController.text);
      final groceryFee = double.tryParse(_groceryFeeController.text);
      final condoFee = double.tryParse(_condoFeeController.text);
      final stopFee = double.tryParse(_stopFeeController.text);

      await supabase
          .from('drivers')
          .update({
            ...updateData,
            'pet_fee': petFee,
            'grocery_fee': groceryFee,
            'condo_fee': condoFee,
            'stop_fee': stopFee,
          })
          .eq('id', driverId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Preços personalizados salvos com sucesso!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao salvar preços personalizados');
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
        title: const Text('Preços Personalizados'),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _savePricingData,
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
                  _buildBasePricingSection(),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  _buildAdditionalFeesSection(),
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
            Icons.price_change,
            color: cs.primary,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Configure seus preços personalizados para ter mais controle sobre seus ganhos. Os preços padrão da plataforma serão usados quando não definidos.',
              style: AppTypography.bodyMedium.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasePricingSection() {
    final cs = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Preços Base',
                style: AppTypography.headlineSmall,
              ),
            ),
            Switch(
              value: _useCustomPricing,
              onChanged: (value) {
                setState(() {
                  _useCustomPricing = value;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _useCustomPricing 
              ? 'Seus preços personalizados serão aplicados'
              : 'Preços padrão da plataforma serão usados',
          style: AppTypography.bodyMedium.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        
        if (_useCustomPricing) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildPriceField(
            controller: _pricePerKmController,
            label: 'Preço por Km',
            hint: 'Ex: 1.50',
            prefix: 'R\$ ',
            suffix: ' / km',
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildPriceField(
            controller: _pricePerMinuteController,
            label: 'Preço por Minuto',
            hint: 'Ex: 0.20',
            prefix: 'R\$ ',
            suffix: ' / min',
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalFeesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Taxas Adicionais',
          style: AppTypography.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Configure taxas para serviços especiais que você aceita realizar',
          style: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        
        _buildPriceField(
          controller: _petFeeController,
          label: 'Taxa para Pets',
          hint: 'Ex: 5.00',
          prefix: 'R\$ ',
        ),
        const SizedBox(height: AppSpacing.lg),
        
        _buildPriceField(
          controller: _groceryFeeController,
          label: 'Taxa para Compras/Delivery',
          hint: 'Ex: 3.00',
          prefix: 'R\$ ',
        ),
        const SizedBox(height: AppSpacing.lg),
        
        _buildPriceField(
          controller: _condoFeeController,
          label: 'Taxa para Condomínios',
          hint: 'Ex: 2.00',
          prefix: 'R\$ ',
        ),
        const SizedBox(height: AppSpacing.lg),
        
        _buildPriceField(
          controller: _stopFeeController,
          label: 'Taxa por Parada Extra',
          hint: 'Ex: 1.50',
          prefix: 'R\$ ',
        ),
      ],
    );
  }

  Widget _buildPriceField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? prefix,
    String? suffix,
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Campo obrigatório';
            }
            final price = double.tryParse(value);
            if (price == null || price < 0) {
              return 'Valor inválido';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            suffixText: suffix,
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
}