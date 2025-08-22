import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/supabase/driver_excluded_zone.dart';
import '../../services/driver_excluded_zones_service.dart';
import '../../services/user_service.dart';
import '../../widgets/logo_branding.dart';
import '../../theme/app_spacing.dart';

class DriverExcludedZonesScreen extends StatefulWidget {
  const DriverExcludedZonesScreen({super.key});

  static const routeName = '/driver_excluded_zones';

  @override
  State<DriverExcludedZonesScreen> createState() => _DriverExcludedZonesScreenState();
}

class _DriverExcludedZonesScreenState extends State<DriverExcludedZonesScreen> {
  late final DriverExcludedZonesService _service;
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  List<DriverExcludedZone> _excludedZones = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _driverId;

  @override
  void initState() {
    super.initState();
    _service = DriverExcludedZonesService(Supabase.instance.client);
    _loadDriverData();
  }

  @override
  void dispose() {
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverData() async {
    try {
      final user = await UserService.getCurrentUser();
      if (user?.userType == 'driver') {
        _driverId = user!.id;
        await _loadExcludedZones();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao carregar dados do motorista: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadExcludedZones() async {
    if (_driverId == null) return;
    
    try {
      final zones = await _service.getDriverExcludedZones(_driverId!);
      if (mounted) {
        setState(() {
          _excludedZones = zones;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao carregar zonas excluídas: $e');
      }
    }
  }

  Future<void> _addExcludedZone() async {
    if (!_formKey.currentState!.validate() || _driverId == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _service.addExcludedZone(
        driverId: _driverId!,
        neighborhoodName: _neighborhoodController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
      );
      
      // Clear form
      _neighborhoodController.clear();
      _cityController.clear();
      _stateController.clear();
      
      // Reload zones
      await _loadExcludedZones();
      
      if (mounted) {
        _showSuccessSnackBar('Zona excluída adicionada com sucesso!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao adicionar zona excluída: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _removeExcludedZone(DriverExcludedZone zone) async {
    try {
      await _service.removeExcludedZone(zone.id);
      await _loadExcludedZones();
      
      if (mounted) {
        _showSuccessSnackBar('Zona excluída removida com sucesso!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao remover zona excluída: $e');
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAddZoneDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Zona Excluída'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _neighborhoodController,
                decoration: const InputDecoration(
                  labelText: 'Bairro',
                  hintText: 'Ex: Centro, Copacabana',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe o bairro';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Cidade',
                  hintText: 'Ex: Rio de Janeiro, São Paulo',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe a cidade';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  hintText: 'Ex: RJ, SP, MG',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe o estado';
                  }
                  if (value.trim().length != 2) {
                    return 'Use a sigla do estado (ex: RJ, SP)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _neighborhoodController.clear();
              _cityController.clear();
              _stateController.clear();
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    Navigator.of(context).pop();
                    _addExcludedZone();
                  },
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _showRemoveConfirmation(DriverExcludedZone zone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Zona Excluída'),
        content: Text(
          'Deseja remover "${zone.neighborhoodName}, ${zone.city} - ${zone.state}" das suas zonas excluídas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeExcludedZone(zone);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const StandardAppBar(
        title: 'Zonas Excluídas',
        showMenuIcon: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header com informações
                Container(
                  width: double.infinity,
                  margin: AppSpacing.screenMargin,
                  padding: AppSpacing.paddingLg,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_off,
                            color: colorScheme.onPrimaryContainer,
                            size: AppSpacing.iconMd,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Zonas de Exclusão',
                            style: textTheme.titleLarge?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Defina os bairros onde você não deseja realizar atendimentos. Você não receberá solicitações de corridas nessas áreas.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Lista de zonas excluídas
                Expanded(
                  child: _excludedZones.isEmpty
                      ? _buildEmptyState(colorScheme, textTheme)
                      : _buildZonesList(colorScheme, textTheme),
                ),
              ],
            ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddZoneDialog,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Adicionar Zona'),
            ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nenhuma zona excluída',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Você ainda não definiu nenhuma zona de exclusão. Toque no botão "+" para adicionar.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZonesList(ColorScheme colorScheme, TextTheme textTheme) {
    return ListView.builder(
      padding: AppSpacing.screenMargin,
      itemCount: _excludedZones.length,
      itemBuilder: (context, index) {
        final zone = _excludedZones[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.errorContainer,
              child: Icon(
                Icons.location_off,
                color: colorScheme.onErrorContainer,
                size: AppSpacing.iconSm,
              ),
            ),
            title: Text(
              zone.neighborhoodName,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${zone.city} - ${zone.state}',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: colorScheme.error,
              ),
              onPressed: () => _showRemoveConfirmation(zone),
              tooltip: 'Remover zona excluída',
            ),
          ),
        );
      },
    );
  }
}