import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class CustomPricingScreen extends StatefulWidget {
  const CustomPricingScreen({super.key});

  @override
  State<CustomPricingScreen> createState() => _CustomPricingScreenState();
}

class _CustomPricingScreenState extends State<CustomPricingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _petFeeController = TextEditingController();
  final _groceryFeeController = TextEditingController();
  final _condoFeeController = TextEditingController();
  final _stopFeeController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPricingData();
  }

  @override
  void dispose() {
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
          .select('pet_fee, grocery_fee, condo_fee, stop_fee')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
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

      // Taxas adicionais são sempre salvas
      final petFee = double.tryParse(_petFeeController.text);
      final groceryFee = double.tryParse(_groceryFeeController.text);
      final condoFee = double.tryParse(_condoFeeController.text);
      final stopFee = double.tryParse(_stopFeeController.text);

      await supabase
          .from('drivers')
          .update({
            'pet_fee': petFee,
            'grocery_fee': groceryFee,
            'condo_fee': condoFee,
            'stop_fee': stopFee,
          })
          .eq('id', driverId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Taxas adicionais salvas com sucesso!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao salvar taxas adicionais');
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
        title: const Text('Taxas Adicionais'),
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
              'Configure suas taxas adicionais para serviços especiais. Os preços base são definidos pela plataforma.',
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
    
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: cs.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outlined,
                color: cs.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Preços Base',
                  style: AppTypography.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Os preços base são definidos pela plataforma através das categorias do sistema e não podem ser alterados pelo motorista. Eles garantem consistência e transparência nas tarifas.',
            style: AppTypography.bodyMedium.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalFeesSection() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
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
          prefix: r'R$ ',
        ),
        const SizedBox(height: AppSpacing.lg),
        
        _buildPriceField(
          controller: _groceryFeeController,
          label: 'Taxa para Compras/Delivery',
          hint: 'Ex: 3.00',
          prefix: r'R$ ',
        ),
        const SizedBox(height: AppSpacing.lg),
        
        _buildPriceField(
          controller: _condoFeeController,
          label: 'Taxa para Condomínios',
          hint: 'Ex: 2.00',
          prefix: r'R$ ',
        ),
        const SizedBox(height: AppSpacing.lg),
        
        _buildPriceField(
          controller: _stopFeeController,
          label: 'Taxa por Parada Extra',
          hint: 'Ex: 1.50',
          prefix: r'R$ ',
        ),
      ],
    );

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